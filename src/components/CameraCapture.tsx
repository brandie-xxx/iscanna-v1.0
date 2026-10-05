import React, { useRef, useState, useEffect } from 'react';
import { Camera, Upload, RefreshCw, AlertCircle, Plus } from 'lucide-react';
import { triggerHaptic } from '../utils/haptics';

interface CameraCaptureProps {
  onCaptureImage: (imageDataUrl: string) => void;
  isProcessing: boolean;
  selectedSampleImage?: string;
  onClearSampleImage?: () => void;
  targetScanCount: number;
  setTargetScanCount: (count: number) => void;
  currentBatchCount?: number;
}

export const CameraCapture: React.FC<CameraCaptureProps> = ({
  onCaptureImage,
  isProcessing,
  selectedSampleImage,
  onClearSampleImage,
  targetScanCount,
  setTargetScanCount,
  currentBatchCount = 0
}) => {
  const videoRef = useRef<HTMLVideoElement | null>(null);
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  
  const [cameraActive, setCameraActive] = useState<boolean>(false);
  const [cameraError, setCameraError] = useState<string | null>(null);
  const [dragActive, setDragActive] = useState<boolean>(false);
  const [previewImage, setPreviewImage] = useState<string | null>(null);

  const handleIncrementCount = () => {
    triggerHaptic('light');
    setTargetScanCount(targetScanCount + 1);
  };

  useEffect(() => {
    if (selectedSampleImage) {
      setPreviewImage(selectedSampleImage);
      stopCamera();
    }
  }, [selectedSampleImage]);

  const startCamera = async () => {
    triggerHaptic('medium');
    try {
      setCameraError(null);
      if (onClearSampleImage) onClearSampleImage();
      setPreviewImage(null);

      const stream = await navigator.mediaDevices.getUserMedia({
        video: {
          facingMode: { ideal: 'environment' },
          width: { ideal: 1920 },
          height: { ideal: 1080 }
        }
      });

      if (videoRef.current) {
        videoRef.current.srcObject = stream;
        videoRef.current.play();
        setCameraActive(true);
      }
    } catch (err: unknown) {
      console.warn("Camera access warning:", err);
      setCameraError("Camera unavailable. Upload a photo.");
      setCameraActive(false);
    }
  };

  const stopCamera = () => {
    if (videoRef.current && videoRef.current.srcObject) {
      const stream = videoRef.current.srcObject as MediaStream;
      stream.getTracks().forEach(track => track.stop());
      videoRef.current.srcObject = null;
    }
    setCameraActive(false);
  };

  useEffect(() => {
    return () => {
      stopCamera();
    };
  }, []);

  const takeSnapshot = () => {
    if (!videoRef.current || !canvasRef.current) return;
    triggerHaptic('heavy');

    const video = videoRef.current;
    const canvas = canvasRef.current;
    canvas.width = video.videoWidth || 1280;
    canvas.height = video.videoHeight || 720;

    const ctx = canvas.getContext('2d');
    if (ctx) {
      ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
      const dataUrl = canvas.toDataURL('image/jpeg', 0.92);
      setPreviewImage(dataUrl);
      stopCamera();
      onCaptureImage(dataUrl);
    }
  };

  const handleFileChange = (file: File) => {
    if (!file.type.startsWith('image/')) return;
    triggerHaptic('light');
    const reader = new FileReader();
    reader.onload = (e) => {
      const result = e.target?.result as string;
      if (result) {
        if (onClearSampleImage) onClearSampleImage();
        setPreviewImage(result);
        stopCamera();
        onCaptureImage(result);
      }
    };
    reader.readAsDataURL(file);
  };

  return (
    <section className="w-full bg-[#181920] border border-[#272832] rounded-xl p-3.5 sm:p-5 flex flex-col justify-between">
      <canvas ref={canvasRef} className="hidden" />

      {/* Header & Target Count */}
      <header className="flex items-center justify-between pb-3 mb-3 border-b border-[#24252e] flex-wrap gap-2 text-xs">
        <span className="flex items-center gap-2">
          <span className="text-xs sm:text-sm font-semibold text-[#f4f4f5]">Camera & Scanner</span>
          {isProcessing && (
            <span className="text-[11px] font-medium text-[#7dd3fc] bg-[#7dd3fc]/10 px-2 py-0.5 rounded flex items-center gap-1.5 border border-[#7dd3fc]/20">
              <RefreshCw className="w-3 h-3 animate-spin" /> Scanning
            </span>
          )}
        </span>

        {/* Target Count Switcher (Single Radio Button with Incrementable Mention) */}
        <fieldset className="flex items-center gap-1 bg-[#111215] p-1 rounded-lg border border-[#272832] text-xs m-0">
          <legend className="sr-only">Target scan count</legend>
          <label
            onClick={() => {
              if (targetScanCount > 1) {
                triggerHaptic('light');
                setTargetScanCount(1);
              }
            }}
            className="px-2.5 py-1 rounded-md transition-colors cursor-pointer min-h-[32px] sm:min-h-[28px] text-xs font-medium flex items-center gap-1.5 select-none bg-[#22232c] text-[#7dd3fc] font-semibold border border-[#353644]"
            title={targetScanCount > 1 ? "Click to reset to 1" : "Target count"}
          >
            <input
              type="radio"
              name="targetScanCountRadio"
              value={targetScanCount}
              checked={true}
              readOnly
              className="sr-only"
            />
            <span className="w-3 h-3 rounded-full border border-[#7dd3fc] flex items-center justify-center transition-colors shrink-0">
              <span className="w-1.5 h-1.5 rounded-full bg-[#7dd3fc]" />
            </span>
            <span className="tabular-nums font-semibold">{targetScanCount}</span>
          </label>

          <button
            type="button"
            onClick={handleIncrementCount}
            className="p-1 px-1.5 rounded-md bg-[#181920] hover:bg-[#22232c] text-[#7dd3fc] hover:text-[#38bdf8] border border-[#272832] hover:border-[#7dd3fc]/50 cursor-pointer min-h-[32px] sm:min-h-[28px] flex items-center justify-center transition-colors"
            title="Increment count"
            aria-label="Increment count"
          >
            <Plus className="w-3.5 h-3.5" />
          </button>
        </fieldset>
      </header>

      {/* Target Batch Progress */}
      {targetScanCount > 1 && (
        <aside className="mb-3 bg-[#111215] border border-[#272832] text-[#9ca3af] rounded-lg px-3 py-2 flex items-center justify-between text-xs">
          <span>Target: {currentBatchCount} of {targetScanCount} cards</span>
          <span className="text-[#7dd3fc] font-semibold">{Math.round((currentBatchCount / targetScanCount) * 100)}%</span>
        </aside>
      )}

      {/* Viewport Area */}
      <section 
        onDragOver={(e) => { e.preventDefault(); setDragActive(true); }}
        onDragLeave={() => setDragActive(false)}
        onDrop={(e) => {
          e.preventDefault();
          setDragActive(false);
          if (e.dataTransfer.files?.[0]) handleFileChange(e.dataTransfer.files[0]);
        }}
        className={`relative w-full aspect-[4/3] sm:aspect-[16/9] bg-[#111215] rounded-lg overflow-hidden flex items-center justify-center transition-colors border ${
          dragActive ? 'border-[#7dd3fc]' : 'border-[#272832]'
        }`}
      >
        {/* Live Camera Feed */}
        <video
          ref={videoRef}
          playsInline
          muted
          className={`w-full h-full object-cover ${cameraActive ? 'opacity-100' : 'opacity-0 absolute pointer-events-none'}`}
        />

        {/* Minimalist Camera Frame Guides */}
        {cameraActive && (
          <aside className="absolute inset-0 pointer-events-none p-6 sm:p-8 flex flex-col justify-between">
            <span className="flex justify-between">
              <span className="w-4 h-4 border-t-2 border-l-2 border-[#7dd3fc]" />
              <span className="w-4 h-4 border-t-2 border-r-2 border-[#7dd3fc]" />
            </span>
            <span className="flex justify-between">
              <span className="w-4 h-4 border-b-2 border-l-2 border-[#7dd3fc]" />
              <span className="w-4 h-4 border-b-2 border-r-2 border-[#7dd3fc]" />
            </span>
          </aside>
        )}

        {/* Preview Image */}
        {!cameraActive && previewImage && (
          <figure className="relative w-full h-full flex items-center justify-center p-2.5 sm:p-3 bg-[#111215]">
            <img
              src={previewImage}
              alt="Voucher card"
              className="max-w-full max-h-full object-contain rounded"
            />
            {isProcessing && (
              <span className="absolute inset-0 bg-[#111215]/80 flex items-center justify-center">
                <span className="text-xs font-semibold text-[#111215] bg-[#7dd3fc] px-3.5 py-2 rounded-md flex items-center gap-1.5 shadow-sm">
                  <RefreshCw className="w-3.5 h-3.5 animate-spin" />
                  Reading PIN...
                </span>
              </span>
            )}
          </figure>
        )}

        {/* Empty State / Dropzone */}
        {!cameraActive && !previewImage && (
          <section className="flex flex-col items-center justify-center p-4 sm:p-6 text-center w-full h-full">
            <p className="text-xs text-[#71717a] mb-3 max-w-xs leading-relaxed">
              Place NetOne or Econet card in frame or upload photo
            </p>
            <label className="cursor-pointer px-4 py-2.5 rounded-lg bg-[#22232c] hover:bg-[#2b2c37] text-[#7dd3fc] border border-[#272832] font-medium text-xs transition-colors min-h-[44px] flex items-center gap-2">
              <Upload className="w-4 h-4 text-[#7dd3fc]" />
              <span>Select Card Photo</span>
              <input
                type="file"
                accept="image/*"
                className="hidden"
                onChange={(e) => e.target.files?.[0] && handleFileChange(e.target.files[0])}
              />
            </label>
          </section>
        )}

        {cameraError && (
          <aside className="absolute bottom-2.5 inset-x-2.5 bg-[#1e1f27] text-[#9ca3af] px-3 py-2 rounded-lg text-xs flex items-center gap-2 border border-[#353644]">
            <AlertCircle className="w-3.5 h-3.5 text-[#7dd3fc] shrink-0" />
            <span className="truncate">{cameraError}</span>
          </aside>
        )}
      </section>

      {/* Bottom Controls */}
      <footer className="mt-3.5 pt-3 border-t border-[#24252e] flex items-center justify-between gap-2">
        {!cameraActive ? (
          <button
            onClick={startCamera}
            className="flex-1 sm:flex-initial px-4 py-2.5 rounded-lg bg-[#22232c] hover:bg-[#2b2c37] border border-[#272832] text-[#f4f4f5] font-medium text-xs flex items-center justify-center gap-2 min-h-[44px] cursor-pointer transition-colors"
          >
            <Camera className="w-4 h-4 text-[#7dd3fc]" />
            <span>Open Camera</span>
          </button>
        ) : (
          <nav className="flex items-center gap-2 w-full">
            <button
              onClick={takeSnapshot}
              disabled={isProcessing}
              className="flex-1 py-2.5 rounded-lg bg-[#7dd3fc] hover:bg-[#38bdf8] text-[#111215] font-bold text-xs min-h-[44px] cursor-pointer transition-colors flex items-center justify-center gap-1.5"
            >
              Capture Card
            </button>
            <button
              onClick={() => {
                triggerHaptic('light');
                stopCamera();
              }}
              className="px-4 py-2.5 rounded-lg bg-[#22232c] hover:bg-[#2b2c37] text-[#9ca3af] font-medium text-xs min-h-[44px] cursor-pointer transition-colors"
            >
              Cancel
            </button>
          </nav>
        )}

        {!cameraActive && previewImage && (
          <button
            onClick={() => {
              triggerHaptic('medium');
              onCaptureImage(previewImage);
            }}
            disabled={isProcessing}
            className="px-4 py-2.5 rounded-lg bg-[#7dd3fc] hover:bg-[#38bdf8] text-[#111215] font-bold text-xs flex items-center justify-center gap-1.5 min-h-[44px] cursor-pointer transition-colors"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${isProcessing ? 'animate-spin' : ''}`} />
            <span>Re-Scan</span>
          </button>
        )}
      </footer>
    </section>
  );
};
