import React, { useState, useEffect } from 'react';
import { ScannedCard, FormatConfig } from '../types';
import { wrapPinString } from '../data/carriers';
import { triggerHaptic } from '../utils/haptics';

interface DigitCorrectionModalProps {
  card: ScannedCard | null;
  currentFormat: FormatConfig;
  isOpen: boolean;
  onClose: () => void;
  onSaveCorrection: (updatedCard: ScannedCard) => void;
}

export const DigitCorrectionModal: React.FC<DigitCorrectionModalProps> = ({
  card,
  currentFormat,
  isOpen,
  onClose,
  onSaveCorrection
}) => {
  const [digits, setDigits] = useState<string[]>([]);
  const [selectedIndex, setSelectedIndex] = useState<number>(0);

  useEffect(() => {
    if (card) {
      const pinChars = card.rawPin.split('');
      while (pinChars.length < 16) pinChars.push('0');
      setDigits(pinChars.slice(0, 16));

      if (card.damagedDigitIndex !== undefined && card.damagedDigitIndex >= 0) {
        setSelectedIndex(card.damagedDigitIndex);
      } else {
        const lowestConfIdx = card.digits.reduce(
          (minIdx, cur, idx, arr) => (cur.confidence < arr[minIdx].confidence ? idx : minIdx),
          0
        );
        setSelectedIndex(lowestConfIdx >= 0 ? lowestConfIdx : 0);
      }
    }
  }, [card]);

  if (!isOpen || !card) return null;

  const handleKeypadPress = (num: string) => {
    triggerHaptic('light');
    const updated = [...digits];
    updated[selectedIndex] = num;
    setDigits(updated);

    if (selectedIndex < 15) {
      setSelectedIndex(selectedIndex + 1);
    }
  };

  const handleBackspace = () => {
    triggerHaptic('light');
    const updated = [...digits];
    updated[selectedIndex] = '0';
    setDigits(updated);
    if (selectedIndex > 0) {
      setSelectedIndex(selectedIndex - 1);
    }
  };

  const handleClear = () => {
    triggerHaptic('light');
    const updated = [...digits];
    updated[selectedIndex] = '0';
    setDigits(updated);
  };

  const handleSave = () => {
    triggerHaptic('light');
    const newRawPin = digits.join('');
    const newWrapped = wrapPinString(newRawPin, currentFormat);

    const updatedCard: ScannedCard = {
      ...card,
      rawPin: newRawPin,
      formattedPin: newRawPin.match(/.{1,4}/g)?.join(' ') || newRawPin,
      wrappedPin: newWrapped,
      status: 'success',
      confidence: 100,
      digits: digits.map((char) => ({
        char,
        confidence: 100
      }))
    };

    onSaveCorrection(updatedCard);
    onClose();
  };

  return (
    <aside className="fixed inset-0 z-50 flex items-center justify-center p-3 bg-black/75 backdrop-blur-xs text-[#e4e4e7] overflow-y-auto">
      <article className="bg-[#181920] border border-[#272832] rounded-xl w-full max-w-sm overflow-hidden flex flex-col shadow-2xl my-auto">
        
        {/* Simplified Header */}
        <header className="px-4 py-3 border-b border-[#24252e] flex items-center justify-between">
          <h2 className="text-sm font-semibold text-[#f4f4f5]">Edit PIN</h2>
          <button
            onClick={() => {
              triggerHaptic('light');
              onClose();
            }}
            className="text-xs text-[#9ca3af] hover:text-[#f4f4f5] p-1 cursor-pointer"
            aria-label="Close"
          >
            ✕
          </button>
        </header>

        {/* 16 Digit Display */}
        <section className="p-3.5 space-y-3">
          <nav className="grid grid-cols-4 gap-1.5">
            {[0, 1, 2, 3].map((blockIdx) => (
              <section
                key={blockIdx}
                className="flex gap-0.5 justify-center bg-[#111215] p-1 rounded-md border border-[#272832]"
              >
                {[0, 1, 2, 3].map((subIdx) => {
                  const digitIndex = blockIdx * 4 + subIdx;
                  const isSelected = selectedIndex === digitIndex;

                  return (
                    <button
                      key={digitIndex}
                      type="button"
                      onClick={() => {
                        triggerHaptic('light');
                        setSelectedIndex(digitIndex);
                      }}
                      className={`flex-1 h-9 rounded text-sm font-bold flex items-center justify-center transition-colors cursor-pointer tabular-pin ${
                        isSelected
                          ? 'bg-[#7dd3fc] text-[#111215]'
                          : 'bg-[#22232c] text-[#f4f4f5] hover:bg-[#2b2c37]'
                      }`}
                    >
                      {digits[digitIndex] || '0'}
                    </button>
                  );
                })}
              </section>
            ))}
          </nav>

          {/* Clean Numeric Keypad */}
          <section className="bg-[#111215] p-2 rounded-lg border border-[#272832]">
            <nav className="grid grid-cols-3 gap-1.5">
              {['1', '2', '3', '4', '5', '6', '7', '8', '9'].map((digit) => (
                <button
                  key={digit}
                  type="button"
                  onClick={() => handleKeypadPress(digit)}
                  className="py-2.5 bg-[#22232c] hover:bg-[#2b2c37] active:bg-[#7dd3fc] active:text-[#111215] text-[#f4f4f5] font-semibold text-base rounded-md transition-colors min-h-[44px] cursor-pointer tabular-pin flex items-center justify-center"
                >
                  {digit}
                </button>
              ))}

              <button
                type="button"
                onClick={handleClear}
                className="py-2.5 bg-[#22232c] hover:bg-[#2b2c37] text-[#9ca3af] font-semibold text-xs rounded-md flex items-center justify-center min-h-[44px] cursor-pointer"
              >
                C
              </button>

              <button
                type="button"
                onClick={() => handleKeypadPress('0')}
                className="py-2.5 bg-[#22232c] hover:bg-[#2b2c37] active:bg-[#7dd3fc] active:text-[#111215] text-[#f4f4f5] font-semibold text-base rounded-md transition-colors min-h-[44px] cursor-pointer tabular-pin flex items-center justify-center"
              >
                0
              </button>

              <button
                type="button"
                onClick={handleBackspace}
                className="py-2.5 bg-[#22232c] hover:bg-[#2b2c37] text-[#7dd3fc] font-bold text-base rounded-md flex items-center justify-center min-h-[44px] cursor-pointer"
              >
                ⌫
              </button>
            </nav>
          </section>
        </section>

        {/* Clean Footer Actions */}
        <footer className="px-4 py-3 border-t border-[#24252e] bg-[#111215] flex items-center justify-end gap-2">
          <button
            type="button"
            onClick={() => {
              triggerHaptic('light');
              onClose();
            }}
            className="flex-1 px-4 py-2 rounded-lg bg-[#22232c] hover:bg-[#2b2c37] text-[#f4f4f5] font-medium text-xs border border-[#272832] transition-colors min-h-[42px] cursor-pointer flex items-center justify-center"
          >
            Cancel
          </button>
          
          <button
            type="button"
            onClick={handleSave}
            className="flex-1 px-5 py-2 rounded-lg bg-[#7dd3fc] hover:bg-[#38bdf8] text-[#111215] font-bold text-xs transition-colors min-h-[42px] flex items-center justify-center cursor-pointer shadow-xs"
          >
            Save
          </button>
        </footer>

      </article>
    </aside>
  );
};
