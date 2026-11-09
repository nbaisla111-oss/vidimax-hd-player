import React, { useState } from 'react';
import { Smartphone, Monitor, Wifi, Battery, Signal, Code2 } from 'lucide-react';

interface PhoneFrameProps {
  children: React.ReactNode;
  onOpenCodeExplorer: () => void;
}

export const PhoneFrame: React.FC<PhoneFrameProps> = ({ children, onOpenCodeExplorer }) => {
  const [isPhoneMode, setIsPhoneMode] = useState(true);

  // Current formatted time for Android status bar
  const currentTime = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', hour12: false });

  return (
    <div className="w-full min-h-screen bg-slate-950 flex flex-col items-center justify-start text-slate-100">
      {/* Top Application Header Bar */}
      <header className="w-full h-14 bg-slate-900/90 border-b border-slate-800/80 px-4 sm:px-8 flex items-center justify-between shrink-0 z-40 backdrop-blur-md">
        {/* Brand */}
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-xl bg-gradient-to-tr from-violet-600 to-cyan-400 flex items-center justify-center font-black text-white text-sm shadow-md">
            V
          </div>
          <div>
            <h1 className="text-sm font-bold text-white tracking-tight leading-tight">
              VidiMax HD Player
            </h1>
            <p className="text-[10px] text-slate-400">Offline Android Media Suite</p>
          </div>
        </div>

        {/* View Mode & Code Explorer Actions */}
        <div className="flex items-center gap-2">
          {/* Mode Switcher: Phone Frame vs Full Screen */}
          <div className="flex items-center p-1 bg-slate-950 rounded-xl border border-slate-800">
            <button
              onClick={() => setIsPhoneMode(true)}
              className={`flex items-center gap-1.5 px-3 py-1 rounded-lg text-xs font-semibold transition-all ${
                isPhoneMode ? 'bg-violet-600 text-white shadow-sm' : 'text-slate-400 hover:text-white'
              }`}
              title="Android Phone Mockup View"
            >
              <Smartphone className="w-3.5 h-3.5" />
              <span className="hidden sm:inline">Phone View</span>
            </button>
            <button
              onClick={() => setIsPhoneMode(false)}
              className={`flex items-center gap-1.5 px-3 py-1 rounded-lg text-xs font-semibold transition-all ${
                !isPhoneMode ? 'bg-violet-600 text-white shadow-sm' : 'text-slate-400 hover:text-white'
              }`}
              title="Expanded Responsive View"
            >
              <Monitor className="w-3.5 h-3.5" />
              <span className="hidden sm:inline">Expanded</span>
            </button>
          </div>

          {/* Flutter Codebase button */}
          <button
            onClick={onOpenCodeExplorer}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-cyan-300 text-xs font-semibold border border-slate-700 transition-colors"
            title="Inspect Flutter Dart Codebase"
          >
            <Code2 className="w-4 h-4 text-cyan-400" />
            <span className="hidden md:inline">Flutter Code</span>
          </button>
        </div>
      </header>

      {/* Main Content Area */}
      <main className="w-full flex-1 flex items-center justify-center p-2 sm:p-6 overflow-hidden">
        {isPhoneMode ? (
          /* Realistic Android Smartphone Shell */
          <div className="relative w-full max-w-[400px] h-[820px] max-h-[92vh] bg-black rounded-[48px] p-3 shadow-2xl shadow-violet-950/40 border-[8px] border-slate-800 flex flex-col overflow-hidden">
            {/* Screen Bezel Inset */}
            <div className="relative w-full h-full bg-slate-950 rounded-[38px] overflow-hidden flex flex-col">
              {/* Android Status Bar */}
              <div className="h-7 bg-slate-950 text-white px-6 flex items-center justify-between text-[11px] font-semibold shrink-0 z-30 select-none">
                <span>{currentTime}</span>
                {/* Center Camera Punch-hole */}
                <div className="w-3.5 h-3.5 rounded-full bg-black border border-slate-800 shrink-0 mx-auto" />
                <div className="flex items-center gap-1.5">
                  <Signal className="w-3 h-3 text-white" />
                  <Wifi className="w-3 h-3 text-white" />
                  <Battery className="w-3.5 h-3.5 text-white" />
                </div>
              </div>

              {/* App Internal Body */}
              <div className="flex-1 flex flex-col overflow-hidden relative">
                {children}
              </div>

              {/* Android Bottom Navigation Gesture Bar */}
              <div className="h-4 bg-slate-950 flex items-center justify-center shrink-0">
                <div className="w-28 h-1 rounded-full bg-slate-600/60" />
              </div>
            </div>
          </div>
        ) : (
          /* Expanded Responsive View for Desktop */
          <div className="w-full max-w-6xl h-[86vh] bg-slate-950 rounded-2xl border border-slate-800/80 shadow-2xl overflow-hidden flex flex-col">
            {children}
          </div>
        )}
      </main>
    </div>
  );
};
