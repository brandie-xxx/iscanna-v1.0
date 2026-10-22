import React, { useRef, useState } from 'react';
import { Header } from './components/Header';
import { NavigationControlBar } from './components/NavigationControlBar';
import { SampleCardSelector } from './components/SampleCardSelector';
import { CameraCapture } from './components/CameraCapture';
import { CardResultsView } from './components/CardResultsView';
import { BatchProcessingView } from './components/BatchProcessingView';
import { DigitCorrectionModal } from './components/DigitCorrectionModal';

import { FormatConfig, ScannedCard, SampleCardScenario } from './types';
import { DEFAULT_FORMATS, SAMPLE_SCENARIOS, wrapPinString } from './data/carriers';
import { processPinText } from './utils/ocrFallback';
import { triggerHaptic } from './utils/haptics';
import { dialUssd } from './utils/dial';

export default function App() {
  // Global App States - Default to NetOne (*133*)
  const [currentFormat, setCurrentFormat] = useState<FormatConfig>(DEFAULT_FORMATS[0]);
  const [activeTab, setActiveTab] = useState<'scanner' | 'batch'>('scanner');

  // Scanner, Target Count & Results State
  const [targetScanCount, setTargetScanCount] = useState<number>(1);
  const [scannedCard, setScannedCard] = useState<ScannedCard | null>(null);
  const [scanError, setScanError] = useState<string | null>(null);
  const [batchCards, setBatchCards] = useState<ScannedCard[]>([]);
  const [isScanning, setIsScanning] = useState<boolean>(false);
  const [activeSampleScenarioId, setActiveSampleScenarioId] = useState<string | undefined>(undefined);

  // Only the latest scan may update state; older in-flight responses are dropped
  const scanSeq = useRef(0);

  // Modals
  const [isDigitEditOpen, setIsDigitEditOpen] = useState<boolean>(false);

  // Batch Operations (a re-scan of the same PIN replaces the earlier entry)
  const handleAddToBatch = (card: ScannedCard) => {
    setBatchCards((prev) => [card, ...prev.filter(c => c.id !== card.id && c.rawPin !== card.rawPin)]);
  };

  const showScannedCard = (card: ScannedCard) => {
    setScanError(null);
    setScannedCard(card);
    triggerHaptic(card.status === 'success' ? 'light' : 'warning');
    // Only verified reads are queued automatically; others need review first
    if (targetScanCount > 1 && card.status === 'success') {
      handleAddToBatch(card);
    }
  };

  // Perform Image Scan via API endpoint (NO confetti on scan)
  const handleScanImage = async (imageDataUrl: string, sampleScenario?: SampleCardScenario) => {
    const seq = ++scanSeq.current;
    setIsScanning(true);
    setScanError(null);

    try {
      if (sampleScenario) {
        await new Promise(resolve => setTimeout(resolve, 350));
        if (seq !== scanSeq.current) return;

        const card = processPinText(sampleScenario.expectedPin, currentFormat, sampleScenario.imageSvgUrl, {
          confidence: sampleScenario.confidence
        });
        if (sampleScenario.hasDamage && sampleScenario.damagedDigitIndex !== undefined) {
          card.digits[sampleScenario.damagedDigitIndex].confidence = 55;
          card.digits[sampleScenario.damagedDigitIndex].isLowConfidence = true;
          card.status = 'warning';
          card.errorMessage = `Scratch on digit ${sampleScenario.damagedDigitIndex + 1}. Please verify.`;
        }
        showScannedCard(card);
        return;
      }

      const res = await fetch('/api/scan', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ image: imageDataUrl })
      });
      const data = await res.json().catch(() => ({}));
      if (seq !== scanSeq.current) return;

      if (res.ok && data.success && typeof data.pin === 'string') {
        showScannedCard(processPinText(data.pin, currentFormat, imageDataUrl, {
          confidence: data.confidence,
          qualityCheck: data.quality
        }));
      } else {
        setScannedCard(null);
        setScanError(data.error || `Scan failed (HTTP ${res.status}).`);
        triggerHaptic('error');
      }
    } catch {
      if (seq !== scanSeq.current) return;
      setScannedCard(null);
      setScanError('Could not reach the scan server. Check your connection and try again.');
      triggerHaptic('error');
    } finally {
      if (seq === scanSeq.current) setIsScanning(false);
    }
  };

  // Handle Preset Scenario Selection
  const handleSelectScenario = (sc: SampleCardScenario) => {
    setActiveSampleScenarioId(sc.id);
    handleScanImage(sc.imageSvgUrl, sc);
  };

  const handleCaptureImage = (img: string) => {
    // Re-scanning a preset image replays the preset instead of sending an SVG to OCR
    const sample = SAMPLE_SCENARIOS.find(sc => sc.imageSvgUrl === img);
    if (sample) {
      handleSelectScenario(sample);
      return;
    }
    setActiveSampleScenarioId(undefined);
    handleScanImage(img);
  };

  // Keep the result view and its batch copy in sync
  const updateCard = (updatedCard: ScannedCard) => {
    setScannedCard(updatedCard);
    setBatchCards(prev => prev.map(c => c.id === updatedCard.id ? updatedCard : c));
  };

  const handleRemoveFromBatch = (cardId: string) => {
    setBatchCards((prev) => prev.filter(c => c.id !== cardId));
  };

  const handleClearBatch = () => {
    setBatchCards([]);
  };

  // Format Selection (NetOne or Econet)
  const handleSelectFormat = (fmt: FormatConfig) => {
    setCurrentFormat(fmt);
    if (scannedCard) {
      updateCard({
        ...scannedCard,
        carrier: fmt.name,
        wrappedPin: wrapPinString(scannedCard.rawPin, fmt),
        carrierId: fmt.id
      });
    }
  };

  return (
    <div className="min-h-screen w-full bg-[#111215] text-[#e4e4e7] antialiased flex flex-col overflow-x-hidden selection:bg-[#7dd3fc]/20 selection:text-[#7dd3fc]">

      {/* Minimal Header */}
      <Header />

      {/* Main Container - Mobile First Responsive */}
      <main className="flex-1 w-full max-w-5xl mx-auto px-3 sm:px-6 py-3.5 sm:py-5 space-y-3.5 sm:space-y-4">

        {/* Strategic Navigable Control Bar (Mode & Carrier Selection) */}
        <NavigationControlBar
          activeTab={activeTab}
          setActiveTab={setActiveTab}
          batchCount={batchCards.length}
          currentFormat={currentFormat}
          onSelectFormat={handleSelectFormat}
        />

        {/* Radio Button Scenario Presets */}
        <SampleCardSelector
          onSelectScenario={handleSelectScenario}
          activeScenarioId={activeSampleScenarioId}
        />

        {/* Tab 1: Scanner View */}
        {activeTab === 'scanner' && (
          <section className="grid grid-cols-1 lg:grid-cols-2 gap-3.5 sm:gap-4 items-start w-full">

            {/* Screen 1: Camera & Scanner Module */}
            <CameraCapture
              onCaptureImage={handleCaptureImage}
              isProcessing={isScanning}
              selectedSampleImage={scannedCard?.imageUrl}
              selectedCardId={scannedCard?.id}
              targetScanCount={targetScanCount}
              setTargetScanCount={setTargetScanCount}
              currentBatchCount={batchCards.length}
            />

            {/* Screen 2: Scanned Results & Wrapped USSD View */}
            <CardResultsView
              key={scannedCard?.id ?? 'empty'}
              card={scannedCard}
              scanError={scanError}
              onOpenEditModal={() => setIsDigitEditOpen(true)}
              onAddToBatch={handleAddToBatch}
              onDial={(card) => dialUssd(card.wrappedPin)}
            />

          </section>
        )}

        {/* Tab 2: Batch Queue View */}
        {activeTab === 'batch' && (
          <BatchProcessingView
            batchCards={batchCards}
            onRemoveFromBatch={handleRemoveFromBatch}
            onClearBatch={handleClearBatch}
            onSwitchToScanner={() => setActiveTab('scanner')}
            onOpenEditModalForCard={(card) => {
              setScannedCard(card);
              setIsDigitEditOpen(true);
            }}
            onDialCard={(card) => dialUssd(card.wrappedPin)}
          />
        )}

      </main>

      {/* Simple Minimalist Footer: *exxstatix under iscanna1.0 */}
      <footer className="border-t border-[#24252e] bg-[#111215] py-5 text-center text-xs text-[#71717a] flex flex-col items-center justify-center gap-1 px-4">
        <span className="font-semibold text-[#a1a1aa] tracking-tight">iscanna1.0</span>
        <a
          href="https://x.com/exxstatix"
          target="_blank"
          rel="noopener noreferrer"
          className="text-[#7dd3fc] hover:text-[#38bdf8] transition-colors"
        >
          *exxstatix
        </a>
      </footer>

      {/* Modals */}
      <DigitCorrectionModal
        card={scannedCard}
        currentFormat={currentFormat}
        isOpen={isDigitEditOpen}
        onClose={() => setIsDigitEditOpen(false)}
        onSaveCorrection={updateCard}
      />

    </div>
  );
}
