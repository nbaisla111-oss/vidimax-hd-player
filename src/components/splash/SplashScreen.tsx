import React, { useEffect, useState } from 'react';
import { Play, Sparkles } from 'lucide-react';

interface SplashScreenProps {
  onFinish: () => void;
}

export const SplashScreen: React.FC<SplashScreenProps> = ({ onFinish }) => {
  const [pulse, setPulse] = useState(false);

  useEffect(() => {
    setPulse(true);
    const timer = setTimeout(() => {
      onFinish();
    }, 2400);
    return () => clearTimeout(timer);
  }, [onFinish]);

  return (
    <div className="relative w-full h-full min-h-[580px] bg-slate-950 flex flex-col items-center justify-between p-8 text-white select-none overflow-hidden">
      {/* Ambient background glow */}
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-80 h-80 rounded-full bg-violet-600/20 blur-[100px] pointer-events-none" />
      <div className="absolute top-1/3 left-1/2 -translate-x-1/2 -translate-y-1/2 w-48 h-48 rounded-full bg-cyan-500/15 blur-[80px] pointer-events-none" />

      {/* Top skip link */}
      <div className="w-full flex justify-end z-10">
        <button
          onClick={onFinish}
          className="text-xs text-slate-400 hover:text-white px-3 py-1.5 rounded-full bg-slate-900/60 border border-slate-800 transition-colors"
        >
          Skip Intro
        </button>
      </div>

      {/* Center Logo & Brand Name */}
      <div className="flex flex-col items-center text-center z-10 transition-all duration-700 transform scale-100">
        <div className="relative mb-6">
          <div
            className={`w-24 h-24 rounded-3xl bg-gradient-to-tr from-violet-600 via-indigo-600 to-cyan-400 flex items-center justify-center shadow-2xl shadow-violet-600/40 transition-transform duration-1000 ${
              pulse ? 'scale-100 rotate-0' : 'scale-75 -rotate-6'
            }`}
          >
            <Play className="w-12 h-12 text-white fill-white translate-x-0.5" />
          </div>
          <div className="absolute -bottom-2 -right-2 p-1.5 rounded-xl bg-slate-900/90 border border-slate-700 shadow-lg">
            <Sparkles className="w-4 h-4 text-cyan-400" />
          </div>
        </div>

        <h1 className="text-3xl font-extrabold tracking-tight text-white mb-2">
          VidiMax <span className="text-transparent bg-clip-text bg-gradient-to-r from-violet-400 to-cyan-400">HD</span>
        </h1>
        <p className="text-xs font-semibold tracking-[0.2em] text-cyan-400/90 uppercase mb-8">
          All-in-One Offline Player
        </p>

        {/* Audio Waveform Bars Animation */}
        <div className="flex items-center gap-1 h-6">
          <span className="w-1 bg-violet-500 rounded-full animate-bounce [animation-delay:-0.3s] h-4" />
          <span className="w-1 bg-cyan-400 rounded-full animate-bounce [animation-delay:-0.15s] h-6" />
          <span className="w-1 bg-violet-400 rounded-full animate-bounce [animation-delay:-0.45s] h-3" />
          <span className="w-1 bg-indigo-400 rounded-full animate-bounce [animation-delay:-0.2s] h-5" />
          <span className="w-1 bg-cyan-300 rounded-full animate-bounce [animation-delay:-0.35s] h-4" />
        </div>
      </div>

      {/* Footer Info */}
      <div className="text-center z-10">
        <p className="text-[11px] text-slate-500 font-medium">
          Encrypted Secret Vault · Video to MP3 · Status Saver
        </p>
      </div>
    </div>
  );
};
