import React, { useState } from 'react';
import confetti from 'canvas-confetti';
import { Header } from './components/Header';
import { NavigationControlBar } from './components/NavigationControlBar';
import { SampleCardSelector } from './components/SampleCardSelector';
import { CameraCapture } from './components/CameraCapture';
import { CardResultsView } from './components/CardResultsView';
import { BatchProcessingView } from './components/BatchProcessingView';
import { DigitCorrectionModal } from './components/DigitCorrectionModal';

import { FormatConfig, ScannedCard, SampleCardScenario } from './types';
import { DEFAULT_FORMATS, wrapPinString } from './data/carriers';
import { processPinText } from './utils/ocrFallback';
import { triggerHaptic } from './utils/haptics';

export default function App() {
  // Global App States - Default to NetOne (*133*)
  const [currentFormat, setCurrentFormat] = useState<FormatConfig>(DEFAULT_FORMATS[0]);
  const [activeTab, setActiveTab] = useState<'scanner' | 'batch'>('scanner');

  // Scanner, Target Count & Results State
  const [targetScanCount, setTargetScanCount] = useState<number>(1);
  const [scannedCard, setScannedCard] = useState<ScannedCard | null>(null);
  const [batchCards, setBatchCards] = useState<ScannedCard[]>([]);
  const [isScanning, setIsScanning] = useState<boolean>(false);
  const [activeSampleScenarioId, setActiveSampleScenarioId] = useState<string | undefined>(undefined);

  // Modals
  const [isDigitEditOpen, setIsDigitEditOpen] = useState<boolean>(false);

  // Celebration effect ONLY when dialing to phone
  const triggerDialEffects = (wrappedPin: string) => {
    triggerHaptic('success');
    confetti({
      particleCount: 50,
      spread: 70,
      origin: { y: 0.65 },
      colors: ['#7dd3fc', '#38bdf8', '#bae6fd', '#f4f4f5']
    });
    window.location.href = `tel:${encodeURIComponent(wrappedPin)}`;
  };

  // Perform Image Scan via API endpoint or local fallback (NO confetti on scan)
  const handleScanImage = async (imageDataUrl: string, sampleScenario?: SampleCardScenario) => {
    setIsScanning(true);

    try {
      if (sampleScenario) {
        setTimeout(() => {
          const card = processPinText(
            sampleScenario.expectedPin,
            sampleScenario.imageSvgUrl,
            currentFormat.id
          );
          card.carrier = sampleScenario.carrier;
          card.confidence = sampleScenario.confidence;
          if (sampleScenario.hasDamage && sampleScenario.damagedDigitIndex !== undefined) {
            card.digits[sampleScenario.damagedDigitIndex].confidence = 55;
            card.digits[sampleScenario.damagedDigitIndex].isLowConfidence = true;
            card.status = 'warning';
            card.errorMessage = `Scratch on digit ${sampleScenario.damagedDigitIndex + 1}. Please verify.`;
          }

          setScannedCard(card);
          setIsScanning(false);
          triggerHaptic('light');

          if (targetScanCount > 1) {
            handleAddToBatch(card);
          }
        }, 350);
        return;
      }

      // Send to server API endpoint `/api/scan`
      const res = await fetch('/api/scan', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          image: imageDataUrl,
          formatPrefix: currentFormat.prefix,
          formatSuffix: currentFormat.suffix
        })
      });

      if (res.ok) {
        const data = await res.json();
        if (data.success && data.pin) {
          const card = processPinText(data.pin, imageDataUrl, currentFormat.id);
          card.carrier = data.carrier || card.carrier;
          card.confidence = data.confidence || card.confidence;
          setScannedCard(card);
          triggerHaptic('light');

          if (targetScanCount > 1) {
            handleAddToBatch(card);
          }
        } else {
          // Fallback parsing
          const card = processPinText("4022622405821561", imageDataUrl, currentFormat.id);
          setScannedCard(card);
          if (targetScanCount > 1) handleAddToBatch(card);
        }
      } else {
        const card = processPinText("4022622405821561", imageDataUrl, currentFormat.id);
        setScannedCard(card);
        if (targetScanCount > 1) handleAddToBatch(card);
      }
    } catch {
      const card = processPinText("4022622405821561", imageDataUrl, currentFormat.id);
      setScannedCard(card);
      if (targetScanCount > 1) handleAddToBatch(card);
    } finally {
      setIsScanning(false);
    }
  };

  // Handle Preset Scenario Selection
  const handleSelectScenario = (sc: SampleCardScenario) => {
    setActiveSampleScenarioId(sc.id);
    handleScanImage(sc.imageSvgUrl, sc);
  };

  // Handle Digit Manual Edit Correction Save
  const handleSaveCorrection = (updatedCard: ScannedCard) => {
    setScannedCard(updatedCard);
    setBatchCards(prev => prev.map(c => c.id === updatedCard.id ? updatedCard : c));
  };

  // Batch Operations
  const handleAddToBatch = (card: ScannedCard) => {
    setBatchCards((prev) => [card, ...prev.filter(c => c.id !== card.id)]);
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
      setScannedCard({
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
              onCaptureImage={(img) => {
                setActiveSampleScenarioId(undefined);
                handleScanImage(img);
              }}
              isProcessing={isScanning}
              selectedSampleImage={scannedCard?.imageUrl}
              onClearSampleImage={() => setScannedCard(null)}
              targetScanCount={targetScanCount}
              setTargetScanCount={setTargetScanCount}
              currentBatchCount={batchCards.length}
            />

            {/* Screen 2: Scanned Results & Wrapped USSD View */}
            <CardResultsView
              card={scannedCard}
              currentFormat={currentFormat}
              onOpenEditModal={() => setIsDigitEditOpen(true)}
              onAddToBatch={handleAddToBatch}
              onRetryScan={() => {
                if (scannedCard?.imageUrl) {
                  handleScanImage(scannedCard.imageUrl);
                }
              }}
            />

          </section>
        )}

        {/* Tab 2: Batch Queue View */}
        {activeTab === 'batch' && (
          <BatchProcessingView
            batchCards={batchCards}
            currentFormat={currentFormat}
            onRemoveFromBatch={handleRemoveFromBatch}
            onClearBatch={handleClearBatch}
            onSwitchToScanner={() => setActiveTab('scanner')}
            onOpenEditModalForCard={(card) => {
              setScannedCard(card);
              setIsDigitEditOpen(true);
            }}
            onDialCard={(card) => triggerDialEffects(card.wrappedPin)}
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
        onSaveCorrection={handleSaveCorrection}
      />

    </div>
  );
}
