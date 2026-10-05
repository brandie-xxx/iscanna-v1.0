import React from 'react';
import { SAMPLE_SCENARIOS } from '../data/carriers';
import { SampleCardScenario } from '../types';
import { triggerHaptic } from '../utils/haptics';

interface SampleCardSelectorProps {
  onSelectScenario: (scenario: SampleCardScenario) => void;
  activeScenarioId?: string;
}

export const SampleCardSelector: React.FC<SampleCardSelectorProps> = ({
  onSelectScenario,
  activeScenarioId
}) => {
  return (
    <fieldset className="w-full flex items-center gap-2 overflow-x-auto no-scrollbar py-1 border-0 m-0 p-0">
      <legend className="sr-only">Sample card voucher scenarios</legend>
      <nav className="flex items-center gap-2 flex-nowrap sm:flex-wrap">
        {SAMPLE_SCENARIOS.map((sc) => {
          const isSelected = activeScenarioId === sc.id;
          return (
            <label
              key={sc.id}
              onClick={() => {
                triggerHaptic('light');
                onSelectScenario(sc);
              }}
              className={`px-3 py-2 rounded-lg border transition-colors cursor-pointer min-h-[38px] text-xs font-medium shrink-0 flex items-center gap-2 whitespace-nowrap select-none ${
                isSelected
                  ? 'bg-[#22232c] text-[#f4f4f5] border-[#7dd3fc]'
                  : 'bg-[#181920] text-[#9ca3af] border-[#272832] hover:border-[#353644] hover:text-[#f4f4f5]'
              }`}
            >
              <input
                type="radio"
                name="sampleScenarioPreset"
                value={sc.id}
                checked={isSelected}
                onChange={() => {
                  triggerHaptic('light');
                  onSelectScenario(sc);
                }}
                className="sr-only"
              />

              {/* Radio Indicator */}
              <span
                className={`w-3.5 h-3.5 rounded-full border flex items-center justify-center transition-colors shrink-0 ${
                  isSelected ? 'border-[#7dd3fc]' : 'border-[#52525b]'
                }`}
              >
                {isSelected && (
                  <span className="w-1.5 h-1.5 rounded-full bg-[#7dd3fc]" />
                )}
              </span>

              <span>{sc.title}</span>
            </label>
          );
        })}
      </nav>
    </fieldset>
  );
};
