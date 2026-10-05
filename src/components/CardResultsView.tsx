import React, { useState } from 'react';
import confetti from 'canvas-confetti';
import { Copy, Edit3, PhoneCall, Plus, Check } from 'lucide-react';
import { ScannedCard, FormatConfig } from '../types';
import { triggerHaptic } from '../utils/haptics';

interface CardResultsViewProps {
  card: ScannedCard | null;
  currentFormat: FormatConfig;
  onOpenEditModal: () => void;
  onAddToBatch: (card: ScannedCard) => void;
  onRetryScan: () => void;
}

export const CardResultsView: React.FC<CardResultsViewProps> = ({
  card,
  currentFormat,
  onOpenEditModal,
  onAddToBatch
}) => {
  const [copied, setCopied] = useState<boolean>(false);
  const [addedToBatch, setAddedToBatch] = useState<boolean>(false);
  const [dialedNotice, setDialedNotice] = useState<boolean>(false);

  // Celebration effects ONLY when dialed to the phone
  const handleDialToPhone = () => {
    triggerHaptic('success');
    confetti({
      particleCount: 50,
      spread: 70,
      origin: { y: 0.65 },
      colors: ['#7dd3fc', '#38bdf8', '#bae6fd', '#f4f4f5']
    });
    setDialedNotice(true);
    setTimeout(() => setDialedNotice(false), 3500);
  };

  if (!card) {
    return (
      <section className="w-full bg-[#181920] border border-[#272832] rounded-xl p-6 sm:p-8 text-center flex flex-col items-center justify-center min-h-[300px] sm:min-h-[340px]">
        <span className="w-12 h-12 rounded-xl bg-[#22232c] border border-[#272832] flex items-center justify-center text-[#7dd3fc] mb-3">
          <Edit3 className="w-5 h-5 text-[#7dd3fc]" />
        </span>
        <h3 className="text-sm font-semibold text-[#f4f4f5] mb-1">
          Awaiting Voucher Card
        </h3>
        <p className="text-xs text-[#71717a] max-w-xs leading-relaxed">
          Position a NetOne or Econet card in frame, upload a photo, or tap a preset above.
        </p>
      </section>
    );
  }

  const handleCopyWrapped = () => {
    navigator.clipboard.writeText(card.wrappedPin);
    triggerHaptic('light');
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const handleAddBatchClick = () => {
    onAddToBatch(card);
    triggerHaptic('light');
    setAddedToBatch(true);
    setTimeout(() => setAddedToBatch(false), 2000);
  };

  return (
    <section className="w-full bg-[#181920] border border-[#272832] rounded-xl p-3.5 sm:p-5 flex flex-col justify-between">
      
      {/* Top Header Bar */}
      <header className="flex items-center justify-between pb-3 mb-3 border-b border-[#24252e]">
        <span className="flex items-center gap-2">
          <span className="text-xs sm:text-sm font-semibold text-[#f4f4f5]">Scanned Card</span>
          <span className="px-2.5 py-0.5 rounded-md bg-[#22232c] border border-[#272832] text-[#7dd3fc] text-xs font-semibold">
            {card.carrier}
          </span>
        </span>

        {card.status === 'warning' ? (
          <span className="text-xs text-[#7dd3fc] bg-[#7dd3fc]/10 border border-[#7dd3fc]/20 px-2.5 py-0.5 rounded-md font-medium">
            Review Needed
          </span>
        ) : (
          <span className="text-xs text-[#7dd3fc] bg-[#7dd3fc]/10 border border-[#7dd3fc]/20 px-2.5 py-0.5 rounded-md font-medium">
            Verified
          </span>
        )}
      </header>

      {/* Main Extracted Outputs */}
      <article className="space-y-3 mb-3.5">
        
        {/* USSD Wrapped Code Output */}
        <section className="bg-[#111215] p-3.5 sm:p-5 rounded-lg border border-[#272832] text-[#f4f4f5]">
          <header className="flex items-center justify-between mb-1.5">
            <span className="text-[10px] sm:text-[11px] text-[#71717a] font-medium tracking-wider uppercase">
              USSD Recharge Code ({currentFormat.name})
            </span>
            <span className="text-[10px] text-[#71717a]">
              {currentFormat.prefix}PIN{currentFormat.suffix}
            </span>
          </header>
          <p className="text-lg sm:text-2xl font-bold text-[#7dd3fc] tracking-wider tabular-pin break-all py-1">
            {card.wrappedPin}
          </p>
        </section>

        {/* 16-Digit Voucher PIN Section */}
        <section className="bg-[#111215] p-3.5 rounded-lg flex items-center justify-between gap-2 border border-[#272832]">
          <span className="min-w-0">
            <span className="text-[10px] text-[#71717a] font-medium uppercase tracking-wider block mb-0.5">
              16-Digit Voucher PIN
            </span>
            <span className="text-xs sm:text-base font-semibold text-[#f4f4f5] tabular-pin tracking-wider block truncate">
              {card.rawPin.match(/.{1,4}/g)?.join(' ') || card.rawPin}
            </span>
          </span>

          <button
            onClick={() => {
              triggerHaptic('light');
              onOpenEditModal();
            }}
            className="px-3 py-2 rounded-md bg-[#22232c] hover:bg-[#2b2c37] text-[#7dd3fc] text-xs font-medium border border-[#272832] flex items-center gap-1.5 cursor-pointer min-h-[38px] shrink-0 transition-colors"
          >
            <Edit3 className="w-3.5 h-3.5 text-[#7dd3fc]" />
            <span>Edit</span>
          </button>
        </section>

        {/* Dialed Confirmation Notice */}
        {dialedNotice && (
          <aside className="p-2.5 rounded-lg bg-[#7dd3fc]/15 border border-[#7dd3fc]/30 text-xs text-[#7dd3fc] flex items-center gap-2">
            <Check className="w-4 h-4 text-[#7dd3fc] shrink-0" />
            <span>Successfully dialed to phone! Check your phone dialer.</span>
          </aside>
        )}
      </article>

      {/* Action Buttons - Mobile First Full Width Layout */}
      <footer className="space-y-2 pt-1">
        
        {/* Dial Code Button (Primary Action, Full Width on Mobile, Celebratory Effect) */}
        <a
          href={`tel:${encodeURIComponent(card.wrappedPin)}`}
          onClick={handleDialToPhone}
          className="w-full py-3 px-4 rounded-lg bg-[#7dd3fc] hover:bg-[#38bdf8] text-[#111215] font-bold text-sm flex items-center justify-center gap-2 transition-colors min-h-[44px] cursor-pointer shadow-xs"
        >
          <PhoneCall className="w-4 h-4 text-[#111215]" />
          <span>Dial Code ({currentFormat.name})</span>
        </a>

        {/* Secondary Row: Copy & Add to Batch */}
        <nav className="grid grid-cols-2 gap-2">
          <button
            onClick={handleCopyWrapped}
            className={`py-2.5 px-3 rounded-lg font-semibold text-xs flex items-center justify-center gap-1.5 transition-colors min-h-[44px] cursor-pointer border ${
              copied
                ? 'bg-[#22232c] border-[#7dd3fc] text-[#7dd3fc]'
                : 'bg-[#22232c] hover:bg-[#2b2c37] border-[#272832] text-[#f4f4f5]'
            }`}
          >
            {copied ? <Check className="w-4 h-4 text-[#7dd3fc]" /> : <Copy className="w-4 h-4 text-[#9ca3af]" />}
            <span>{copied ? 'Copied' : 'Copy Code'}</span>
          </button>

          <button
            onClick={handleAddBatchClick}
            className={`py-2.5 px-3 rounded-lg font-medium text-xs flex items-center justify-center gap-1.5 transition-colors min-h-[44px] cursor-pointer border ${
              addedToBatch
                ? 'bg-[#7dd3fc]/15 border-[#7dd3fc]/30 text-[#7dd3fc]'
                : 'bg-[#111215] hover:bg-[#22232c] border-[#272832] text-[#9ca3af] hover:text-[#f4f4f5]'
            }`}
          >
            {addedToBatch ? <Check className="w-3.5 h-3.5 text-[#7dd3fc]" /> : <Plus className="w-3.5 h-3.5 text-[#71717a]" />}
            <span className="truncate">{addedToBatch ? 'Added' : 'Batch Queue'}</span>
          </button>
        </nav>

      </footer>

    </section>
  );
};
