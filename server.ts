import express from "express";
import path from "path";
import { GoogleGenAI, Type } from "@google/genai";
import dotenv from "dotenv";
import { DEFAULT_FORMATS, wrapPinString } from "./src/data/carriers";

dotenv.config();

const app = express();
const PORT = Number(process.env.PORT) || 3000;
const GEMINI_MODEL = process.env.GEMINI_MODEL || "gemini-3.6-flash";

// Behind a load balancer, set TRUST_PROXY_HOPS so rate limiting sees real client IPs
const trustProxyHops = Number(process.env.TRUST_PROXY_HOPS);
if (trustProxyHops > 0) {
  app.set("trust proxy", trustProxyHops);
}

// Client downscales photos to ~1600px JPEG, so a few MB is ample headroom
app.use(express.json({ limit: '6mb' }));

// Shared Gemini AI client initialization (Server-side only)
function getGeminiClient() {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey || apiKey === "MY_GEMINI_API_KEY") {
    return null;
  }
  return new GoogleGenAI({ apiKey });
}

// Simple fixed-window per-IP limiter so the Gemini quota can't be drained by one client
function rateLimit(maxRequests: number, windowMs: number): express.RequestHandler {
  const hits = new Map<string, { count: number; resetAt: number }>();
  return (req, res, next) => {
    const now = Date.now();
    if (hits.size > 10_000) {
      for (const [key, entry] of hits) {
        if (entry.resetAt <= now) hits.delete(key);
      }
    }
    const key = req.ip || "unknown";
    const entry = hits.get(key);
    if (!entry || entry.resetAt <= now) {
      hits.set(key, { count: 1, resetAt: now + windowMs });
      return next();
    }
    if (entry.count >= maxRequests) {
      res.setHeader("Retry-After", Math.ceil((entry.resetAt - now) / 1000));
      return res.status(429).json({ error: "Too many scans. Please wait a moment and try again." });
    }
    entry.count++;
    next();
  };
}

const USSD_PART = /^[*#0-9]{1,10}$/;
const IMAGE_DATA_URL = /^data:(image\/(?:jpeg|png|webp|heic|heif));base64,([A-Za-z0-9+/=]+)$/;

function clampPercent(value: unknown): number {
  return typeof value === "number" && Number.isFinite(value)
    ? Math.round(Math.min(100, Math.max(0, value)))
    : 0;
}

// ---------------- API ENDPOINTS ----------------

// Health check
app.get("/api/health", (_req, res) => {
  res.json({ status: "ok", service: "iscanna1.0 API", ocrConfigured: getGeminiClient() !== null, timestamp: Date.now() });
});

// Format configuration list (NetOne & Econet only)
app.get("/api/formats", (_req, res) => {
  res.json({
    formats: DEFAULT_FORMATS.map(({ id, name, prefix, suffix }) => ({ id, name, prefix, suffix }))
  });
});

// Wrap single PIN endpoint
app.post("/api/format", (req, res) => {
  const { pin, prefix, suffix } = req.body ?? {};
  if (typeof pin !== "string" || !/\d/.test(pin)) {
    return res.status(400).json({ error: "pin must be a string containing digits" });
  }
  if ((prefix !== undefined && (typeof prefix !== "string" || !USSD_PART.test(prefix))) ||
      (suffix !== undefined && (typeof suffix !== "string" || !USSD_PART.test(suffix)))) {
    return res.status(400).json({ error: "prefix and suffix may only contain digits, * and #" });
  }

  const format = DEFAULT_FORMATS.find(f => f.prefix === prefix && f.suffix === (suffix ?? f.suffix))
    ?? (prefix ? { id: 'custom', name: 'Custom', prefix, suffix: suffix ?? '#' } : DEFAULT_FORMATS[0]);
  res.json({ pin, wrapped: wrapPinString(pin, format), carrier: format.name });
});

// Single image scan endpoint (Gemini Vision OCR). Never fabricates a PIN on failure.
app.post("/api/scan", rateLimit(20, 60_000), async (req, res) => {
  const { image } = req.body ?? {};
  const match = typeof image === "string" ? image.match(IMAGE_DATA_URL) : null;
  if (!match) {
    return res.status(400).json({ error: "image must be a base64 JPEG, PNG, WebP or HEIC data URL" });
  }
  const [, mimeType, base64Data] = match;

  const ai = getGeminiClient();
  if (!ai) {
    return res.status(503).json({ error: "OCR is not configured on the server (missing GEMINI_API_KEY)." });
  }

  try {
    const prompt = `Analyze this recharge voucher card photo.
Extract the 16-digit voucher PIN number exactly as printed.
Look for a continuous 16-digit number or 4 groups of 4 digits (e.g., 4022 6224 0582 1561).
Never guess digits you cannot read: return only the digits you can actually see, in order.
Return a JSON object containing:
- pin: the digits read (string, digits only)
- confidence: integer percentage 0-100 of how certain you are every digit is correct
- blurDetected: boolean
- lightingOk: boolean
- resolutionOk: boolean`;

    const response = await ai.models.generateContent({
      model: GEMINI_MODEL,
      contents: {
        parts: [
          { inlineData: { mimeType, data: base64Data } },
          { text: prompt }
        ]
      },
      config: {
        responseMimeType: "application/json",
        responseSchema: {
          type: Type.OBJECT,
          properties: {
            pin: { type: Type.STRING, description: "Digits of the voucher PIN" },
            confidence: { type: Type.INTEGER, description: "Confidence score 0 to 100" },
            blurDetected: { type: Type.BOOLEAN },
            lightingOk: { type: Type.BOOLEAN },
            resolutionOk: { type: Type.BOOLEAN }
          },
          required: ["pin", "confidence"]
        }
      }
    });

    const parsed = JSON.parse(response.text?.trim() || "{}");
    const pinDigits = String(parsed.pin ?? "").replace(/\D/g, '').slice(0, 16);

    if (pinDigits.length === 0) {
      return res.status(422).json({ error: "No PIN digits could be read from this photo." });
    }

    return res.json({
      success: true,
      pin: pinDigits,
      confidence: clampPercent(parsed.confidence),
      quality: {
        resolutionOk: parsed.resolutionOk !== false,
        lightingOk: parsed.lightingOk !== false,
        blurDetected: parsed.blurDetected === true
      }
    });
  } catch (err) {
    console.error("Gemini OCR failed:", err);
    return res.status(502).json({ error: "The OCR service failed to read this photo. Please try again." });
  }
});

// ---------------- VITE & SERVER LAUNCH ----------------

async function startServer() {
  if (process.env.NODE_ENV !== "production") {
    const { createServer: createViteServer } = await import("vite");
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: "spa",
    });
    app.use(vite.middlewares);
  } else {
    const distPath = path.join(process.cwd(), 'dist');
    app.use(express.static(distPath));
    app.get('*', (_req, res) => {
      res.sendFile(path.join(distPath, 'index.html'));
    });
  }

  app.listen(PORT, "0.0.0.0", () => {
    console.log(`iscanna1.0 server running on http://0.0.0.0:${PORT}`);
  });
}

startServer();
