import React from 'react';
import { Camera, Layers } from 'lucide-react';
import { FormatConfig } from '../types';
import { DEFAULT_FORMATS } from '../data/carriers';
import { triggerHaptic } from '../utils/haptics';

interface NavigationControlBarProps {
  activeTab: 'scanner' | 'batch';
  setActiveTab: (tab: 'scanner' | 'batch') => void;
  batchCount: number;
  currentFormat: FormatConfig;
  onSelectFormat: (format: FormatConfig) => void;
}

export const NavigationControlBar: React.FC<NavigationControlBarProps> = ({
  activeTab,
  setActiveTab,
  batchCount,
  currentFormat,
  onSelectFormat
}) => {
  return (
    <nav
      aria-label="App Navigation Controls"
      className="w-full bg-[#181920] border border-[#272832] rounded-xl p-2 sm:p-2.5 flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-2"
    >
      {/* Tab Mode Control (Scan vs Batch) as Radio Buttons */}
      <fieldset className="flex items-center bg-[#111215] p-1 rounded-lg border border-[#272832] flex-1 sm:flex-initial gap-1 border-0 m-0">
        <legend className="sr-only">App view mode</legend>
        
        <label
          className={`flex-1 sm:flex-initial px-3.5 py-2 rounded-md font-semibold text-xs transition-colors cursor-pointer min-h-[38px] flex items-center justify-center gap-1.5 select-none ${
            activeTab === 'scanner'
              ? 'bg-[#22232c] text-[#7dd3fc] shadow-xs'
              : 'text-[#9ca3af] hover:text-[#f4f4f5]'
          }`}
        >
          <input
            type="radio"
            name="viewModeRadio"
            value="scanner"
            checked={activeTab === 'scanner'}
            onChange={() => {
              triggerHaptic('light');
              setActiveTab('scanner');
            }}
            className="sr-only"
          />
          <span
            className={`w-3.5 h-3.5 rounded-full border flex items-center justify-center transition-colors shrink-0 ${
              activeTab === 'scanner' ? 'border-[#7dd3fc]' : 'border-[#52525b]'
            }`}
          >
            {activeTab === 'scanner' && (
              <span className="w-1.5 h-1.5 rounded-full bg-[#7dd3fc]" />
            )}
          </span>
          <Camera className="w-3.5 h-3.5" />
          <span>Scan</span>
        </label>

        <label
          className={`flex-1 sm:flex-initial px-3.5 py-2 rounded-md font-semibold text-xs transition-colors cursor-pointer min-h-[38px] flex items-center justify-center gap-1.5 select-none ${
            activeTab === 'batch'
              ? 'bg-[#22232c] text-[#7dd3fc] shadow-xs'
              : 'text-[#9ca3af] hover:text-[#f4f4f5]'
          }`}
        >
          <input
            type="radio"
            name="viewModeRadio"
            value="batch"
            checked={activeTab === 'batch'}
            onChange={() => {
              triggerHaptic('light');
              setActiveTab('batch');
            }}
            className="sr-only"
          />
          <span
            className={`w-3.5 h-3.5 rounded-full border flex items-center justify-center transition-colors shrink-0 ${
              activeTab === 'batch' ? 'border-[#7dd3fc]' : 'border-[#52525b]'
            }`}
          >
            {activeTab === 'batch' && (
              <span className="w-1.5 h-1.5 rounded-full bg-[#7dd3fc]" />
            )}
          </span>
          <Layers className="w-3.5 h-3.5" />
          <span>Batch</span>
          {batchCount > 0 && (
            <span
              className={`px-1.5 py-0.5 rounded text-[10px] font-bold ${
                activeTab === 'batch'
                  ? 'bg-[#7dd3fc] text-[#111215]'
                  : 'bg-[#272832] text-[#9ca3af]'
              }`}
            >
              {batchCount}
            </span>
          )}
        </label>
      </fieldset>

      {/* Carrier Switcher Control (NetOne vs Econet) as Radio Buttons */}
      <fieldset className="flex items-center bg-[#111215] p-1 rounded-lg border border-[#272832] flex-1 sm:flex-initial gap-1 border-0 m-0">
        <legend className="sr-only">Carrier format</legend>
        {DEFAULT_FORMATS.map((fmt) => {
          const isSelected = currentFormat.id === fmt.id;
          return (
            <label
              key={fmt.id}
              className={`flex-1 sm:flex-initial px-3.5 py-2 rounded-md font-semibold text-xs transition-colors cursor-pointer min-h-[38px] flex items-center justify-center gap-1.5 select-none ${
                isSelected
                  ? 'bg-[#22232c] text-[#7dd3fc] border border-[#353644] shadow-xs'
                  : 'text-[#9ca3af] hover:text-[#f4f4f5]'
              }`}
            >
              <input
                type="radio"
                name="carrierRadio"
                value={fmt.id}
                checked={isSelected}
                onChange={() => {
                  triggerHaptic('light');
                  onSelectFormat(fmt);
                }}
                className="sr-only"
              />
              <span
                className={`w-3.5 h-3.5 rounded-full border flex items-center justify-center transition-colors shrink-0 ${
                  isSelected ? 'border-[#7dd3fc]' : 'border-[#52525b]'
                }`}
              >
                {isSelected && (
                  <span className="w-1.5 h-1.5 rounded-full bg-[#7dd3fc]" />
                )}
              </span>
              <span>{fmt.name}</span>
              <span className="text-[10px] text-[#71717a] font-mono">
                {fmt.prefix}
              </span>
            </label>
          );
        })}
      </fieldset>
    </nav>
  );
};
