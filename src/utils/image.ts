// Max long edge sent for OCR; plenty for a 16-digit PIN and keeps uploads small
const MAX_DIMENSION = 1600;

function drawScaled(source: CanvasImageSource, width: number, height: number): string {
  const scale = Math.min(1, MAX_DIMENSION / Math.max(width, height));
  const canvas = document.createElement('canvas');
  canvas.width = Math.round(width * scale);
  canvas.height = Math.round(height * scale);
  const ctx = canvas.getContext('2d');
  if (!ctx) throw new Error('Canvas unavailable');
  ctx.drawImage(source, 0, 0, canvas.width, canvas.height);
  return canvas.toDataURL('image/jpeg', 0.88);
}

export function captureVideoFrame(video: HTMLVideoElement): string {
  return drawScaled(video, video.videoWidth || 1280, video.videoHeight || 720);
}

// Decodes an uploaded image and re-encodes it as a downscaled JPEG data URL
export function downscaleImageFile(file: File): Promise<string> {
  return new Promise((resolve, reject) => {
    const url = URL.createObjectURL(file);
    const img = new Image();
    img.onload = () => {
      try {
        resolve(drawScaled(img, img.naturalWidth, img.naturalHeight));
      } catch (err) {
        reject(err);
      } finally {
        URL.revokeObjectURL(url);
      }
    };
    img.onerror = () => {
      URL.revokeObjectURL(url);
      reject(new Error('Unsupported image format'));
    };
    img.src = url;
  });
}
