import React, { useState } from 'react';
import { Copy, Download, Trash2, Check, Plus, Edit3, PhoneCall } from 'lucide-react';
import { ScannedCard, FormatConfig } from '../types';
import { triggerHaptic } from '../utils/haptics';

interface BatchProcessingViewProps {
  batchCards: ScannedCard[];
  currentFormat: FormatConfig;
  onRemoveFromBatch: (id: string) => void;
  onClearBatch: () => void;
  onSwitchToScanner: () => void;
  onOpenEditModalForCard: (card: ScannedCard) => void;
  onDialCard?: (card: ScannedCard) => void;
}

export const BatchProcessingView: React.FC<BatchProcessingViewProps> = ({
  batchCards,
  currentFormat,
  onRemoveFromBatch,
  onClearBatch,
  onSwitchToScanner,
  onOpenEditModalForCard,
  onDialCard
}) => {
  const [exportFormat, setExportFormat] = useState<'csv' | 'json' | 'txt'>('csv');
  const [copiedAll, setCopiedAll] = useState<boolean>(false);

  const handleCopyAll = () => {
    if (batchCards.length === 0) return;
    const allWrapped = batchCards.map(c => c.wrappedPin).join('\n');
    navigator.clipboard.writeText(allWrapped);
    triggerHaptic('light');
    setCopiedAll(true);
    setTimeout(() => setCopiedAll(false), 2000);
  };

  const handleExportDownload = () => {
    if (batchCards.length === 0) return;
    triggerHaptic('medium');

    let content = '';
    let fileName = `iscanna1.0-batch-${new Date().toISOString().slice(0, 10)}`;
    let mimeType = 'text/plain';

    if (exportFormat === 'csv') {
      content = 'Index,RAW_PIN,WRAPPED_PIN,CARRIER\n' +
        batchCards.map((c, i) => `${i + 1},"${c.rawPin}","${c.wrappedPin}","${c.carrier}"`).join('\n');
      fileName += '.csv';
      mimeType = 'text/csv';
    } else if (exportFormat === 'json') {
      content = JSON.stringify(batchCards.map(c => ({
        pin: c.rawPin,
        wrapped: c.wrappedPin,
        carrier: c.carrier
      })), null, 2);
      fileName += '.json';
      mimeType = 'application/json';
    } else {
      content = batchCards.map(c => c.wrappedPin).join('\n');
      fileName += '.txt';
      mimeType = 'text/plain';
    }

    const blob = new Blob([content], { type: mimeType });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = fileName;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  };

  return (
    <section className="w-full bg-[#181920] border border-[#272832] rounded-xl p-3.5 sm:p-5 flex flex-col justify-between">
      
      {/* Header */}
      <header className="flex items-center justify-between pb-3 mb-3 border-b border-[#24252e] gap-2">
        <span className="flex items-center gap-2">
          <span className="text-xs sm:text-sm font-semibold text-[#f4f4f5]">Batch Queue</span>
          <span className="px-2 py-0.5 rounded-md bg-[#22232c] border border-[#272832] text-[#7dd3fc] text-xs font-semibold">
            {batchCards.length}
          </span>
        </span>

        {batchCards.length > 0 && (
          <button
            onClick={() => {
              triggerHaptic('medium');
              onClearBatch();
            }}
            className="px-2.5 sm:px-3 py-1.5 rounded-md bg-[#111215] hover:bg-[#22232c] text-[#9ca3af] hover:text-[#7dd3fc] text-xs font-medium border border-[#272832] flex items-center gap-1.5 cursor-pointer transition-colors min-h-[36px]"
          >
            <Trash2 className="w-3.5 h-3.5" />
            <span className="hidden sm:inline">Clear Queue</span>
            <span className="sm:hidden">Clear</span>
          </button>
        )}
      </header>

      {/* Cards List or Empty State */}
      {batchCards.length === 0 ? (
        <section className="bg-[#111215] border border-[#272832] rounded-lg p-6 sm:p-8 text-center my-2 flex flex-col items-center justify-center">
          <h3 className="text-sm font-semibold text-[#f4f4f5] mb-1">Queue Empty</h3>
          <p className="text-xs text-[#71717a] mb-4 max-w-xs leading-relaxed">
            Scan recharge vouchers to queue them for batch copying or spreadsheet export.
          </p>
          <button
            onClick={() => {
              triggerHaptic('light');
              onSwitchToScanner();
            }}
            className="px-4 py-2.5 rounded-lg bg-[#7dd3fc] hover:bg-[#38bdf8] text-[#111215] font-bold text-xs flex items-center gap-1.5 min-h-[44px] cursor-pointer transition-colors shadow-xs"
          >
            <Plus className="w-4 h-4" />
            <span>Scan Cards</span>
          </button>
        </section>
      ) : (
        <article className="bg-[#111215] border border-[#272832] rounded-lg overflow-hidden mb-3">
          <ul className="divide-y divide-[#24252e] max-h-[320px] sm:max-h-[360px] overflow-y-auto">
            {batchCards.map((c, index) => (
              <li
                key={c.id}
                className="p-3 flex items-center justify-between gap-2 hover:bg-[#181920]/80 transition-colors"
              >
                <span className="flex items-center gap-2.5 min-w-0">
                  <span className="text-[#71717a] font-medium text-xs w-5 shrink-0 text-center">
                    {index + 1}
                  </span>
                  <span className="min-w-0 flex flex-col">
                    <span className="font-semibold text-xs sm:text-sm text-[#f4f4f5] truncate tabular-pin">
                      {c.wrappedPin}
                    </span>
                    <span className="text-[10px] sm:text-[11px] text-[#71717a] truncate">
                      {c.carrier} • {c.rawPin.match(/.{1,4}/g)?.join(' ')}
                    </span>
                  </span>
                </span>

                <nav className="flex items-center gap-1 shrink-0">
                  {onDialCard && (
                    <button
                      onClick={() => onDialCard(c)}
                      className="p-2 rounded-md hover:bg-[#22232c] text-[#7dd3fc] cursor-pointer min-h-[40px] min-w-[40px] flex items-center justify-center transition-colors"
                      title="Dial Voucher"
                    >
                      <PhoneCall className="w-4 h-4" />
                    </button>
                  )}

                  <button
                    onClick={() => {
                      triggerHaptic('light');
                      onOpenEditModalForCard(c);
                    }}
                    className="p-2 rounded-md hover:bg-[#22232c] text-[#9ca3af] hover:text-[#f4f4f5] cursor-pointer min-h-[40px] min-w-[40px] flex items-center justify-center transition-colors"
                    title="Edit Digits"
                  >
                    <Edit3 className="w-4 h-4" />
                  </button>

                  <button
                    onClick={() => {
                      triggerHaptic('light');
                      onRemoveFromBatch(c.id);
                    }}
                    className="p-2 rounded-md hover:bg-[#22232c] text-[#71717a] hover:text-[#7dd3fc] cursor-pointer min-h-[40px] min-w-[40px] flex items-center justify-center transition-colors"
                    title="Remove"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </nav>
              </li>
            ))}
          </ul>
        </article>
      )}

      {/* Export & Actions */}
      {batchCards.length > 0 && (
        <footer className="space-y-2 pt-1">
          {/* Format Selector Radio Group */}
          <nav className="flex items-center justify-between bg-[#111215] p-1.5 rounded-lg border border-[#272832]">
            <span className="text-[#71717a] pl-1.5 text-[11px] uppercase tracking-wider">Format:</span>
            <fieldset className="flex items-center gap-1 border-0 m-0 p-0">
              <legend className="sr-only">Export format</legend>
              {(['csv', 'json', 'txt'] as const).map((fmt) => {
                const isSelected = exportFormat === fmt;
                return (
                  <label
                    key={fmt}
                    className={`px-3 py-1 rounded-md text-xs font-semibold uppercase transition-colors cursor-pointer min-h-[32px] flex items-center gap-1.5 select-none ${
                      isSelected
                        ? 'bg-[#22232c] text-[#7dd3fc] border border-[#353644]'
                        : 'text-[#71717a] hover:text-[#f4f4f5]'
                    }`}
                  >
                    <input
                      type="radio"
                      name="exportFormatRadio"
                      value={fmt}
                      checked={isSelected}
                      onChange={() => {
                        triggerHaptic('light');
                        setExportFormat(fmt);
                      }}
                      className="sr-only"
                    />
                    <span
                      className={`w-2.5 h-2.5 rounded-full border flex items-center justify-center transition-colors shrink-0 ${
                        isSelected ? 'border-[#7dd3fc]' : 'border-[#52525b]'
                      }`}
                    >
                      {isSelected && (
                        <span className="w-1 h-1 rounded-full bg-[#7dd3fc]" />
                      )}
                    </span>
                    <span>{fmt}</span>
                  </label>
                );
              })}
            </fieldset>
          </nav>

          <nav className="grid grid-cols-1 sm:grid-cols-2 gap-2">
            <button
              onClick={handleCopyAll}
              className={`py-2.5 px-3 rounded-lg font-semibold text-xs flex items-center justify-center gap-1.5 transition-colors min-h-[44px] cursor-pointer border ${
                copiedAll
                  ? 'bg-[#22232c] border-[#7dd3fc] text-[#7dd3fc]'
                  : 'bg-[#22232c] hover:bg-[#2b2c37] border-[#272832] text-[#f4f4f5]'
              }`}
            >
              {copiedAll ? <Check className="w-4 h-4 text-[#7dd3fc]" /> : <Copy className="w-4 h-4 text-[#9ca3af]" />}
              <span>{copiedAll ? 'Copied All' : 'Copy All'}</span>
            </button>

            <button
              onClick={handleExportDownload}
              className="py-2.5 px-3 rounded-lg bg-[#7dd3fc] hover:bg-[#38bdf8] text-[#111215] font-bold text-xs flex items-center justify-center gap-1.5 transition-colors min-h-[44px] cursor-pointer"
            >
              <Download className="w-4 h-4 text-[#111215]" />
              <span>Export {exportFormat.toUpperCase()}</span>
            </button>
          </nav>
        </footer>
      )}

    </section>
  );
};
