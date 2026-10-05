import React from 'react';

export const Header: React.FC = () => {
  return (
    <header className="sticky top-0 z-40 w-full bg-[#111215]/95 backdrop-blur-md border-b border-[#24252e] text-[#e4e4e7]">
      <section className="w-full max-w-5xl mx-auto px-4 sm:px-6 h-12 sm:h-14 flex items-center justify-between">
        <span className="flex items-center gap-1.5 text-base font-bold tracking-tight text-[#f4f4f5]">
          <span className="w-2 h-2 rounded-full bg-[#7dd3fc] shrink-0" />
          <span>iscanna</span>
          <span className="text-[#7dd3fc]">1.0</span>
        </span>
      </section>
    </header>
  );
};
