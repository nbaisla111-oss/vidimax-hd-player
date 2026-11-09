import React, { useState } from 'react';
import { Film, Lock, Wrench, ChevronRight, Check } from 'lucide-react';

interface OnboardingScreenProps {
  onComplete: () => void;
}

const ONBOARDING_STEPS = [
  {
    icon: Film,
    title: 'Offline HD Video Player',
    tagline: 'Smooth 4K & 1080p Playback',
    description:
      'Watch your local camera, movie, and WhatsApp videos with intuitive swipe gestures for volume, brightness, 10s skip, and screen lock.',
    gradient: 'from-violet-600 to-indigo-600',
    color: 'text-violet-400',
  },
  {
    icon: Lock,
    title: 'Encrypted Private Vault',
    tagline: 'Military-Grade Secret Locker',
    description:
      'Hide and protect sensitive personal videos behind a secure 4-digit PIN. Locked files are encrypted and hidden from external gallery apps.',
    gradient: 'from-fuchsia-600 to-violet-600',
    color: 'text-fuchsia-400',
  },
  {
    icon: Wrench,
    title: 'Smart Media Utilities',
    tagline: 'Video to MP3 & Status Saver',
    description:
      'Extract studio-quality MP3 audio from any video in seconds, and view, save, or share cached WhatsApp and WA Business statuses.',
    gradient: 'from-cyan-600 to-emerald-600',
    color: 'text-cyan-400',
  },
];

export const OnboardingScreen: React.FC<OnboardingScreenProps> = ({ onComplete }) => {
  const [currentStep, setCurrentStep] = useState(0);

  const handleNext = () => {
    if (currentStep < ONBOARDING_STEPS.length - 1) {
      setCurrentStep(currentStep + 1);
    } else {
      onComplete();
    }
  };

  const step = ONBOARDING_STEPS[currentStep];
  const IconComponent = step.icon;

  return (
    <div className="relative w-full h-full min-h-[580px] bg-slate-950 flex flex-col justify-between p-6 sm:p-8 text-white select-none">
      {/* Top Bar */}
      <div className="flex items-center justify-between pt-2">
        <span className="text-sm font-bold tracking-tight text-slate-300">VidiMax HD</span>
        <button
          onClick={onComplete}
          className="text-xs font-semibold text-slate-400 hover:text-white px-3 py-1.5 rounded-lg transition-colors"
        >
          Skip
        </button>
      </div>

      {/* Main Content Carousel */}
      <div className="flex flex-col items-center text-center my-auto py-6">
        {/* Dynamic Card Icon Container */}
        <div className="relative mb-8">
          <div
            className={`w-28 h-28 rounded-3xl bg-gradient-to-br ${step.gradient} flex items-center justify-center shadow-2xl shadow-violet-900/40 border border-white/10 transition-all duration-300`}
          >
            <IconComponent className="w-14 h-14 text-white" />
          </div>
        </div>

        <span className={`text-xs font-bold tracking-widest uppercase mb-2 ${step.color}`}>
          {step.tagline}
        </span>
        <h2 className="text-2xl font-extrabold text-white tracking-tight mb-3">
          {step.title}
        </h2>
        <p className="text-xs sm:text-sm text-slate-400 leading-relaxed max-w-xs">
          {step.description}
        </p>
      </div>

      {/* Bottom Controls: Indicators + Action Button */}
      <div className="w-full pb-4">
        {/* Dot Indicators */}
        <div className="flex justify-center items-center gap-2 mb-6">
          {ONBOARDING_STEPS.map((_, idx) => (
            <button
              key={idx}
              onClick={() => setCurrentStep(idx)}
              className={`h-2 rounded-full transition-all duration-300 ${
                currentStep === idx ? 'w-8 bg-violet-500' : 'w-2 bg-slate-800'
              }`}
              aria-label={`Go to slide ${idx + 1}`}
            />
          ))}
        </div>

        {/* Next / Get Started Button */}
        <button
          onClick={handleNext}
          className="w-full h-12 rounded-xl bg-gradient-to-r from-violet-600 to-indigo-600 hover:from-violet-500 hover:to-indigo-500 text-white font-bold text-sm flex items-center justify-center gap-2 shadow-lg shadow-violet-600/25 active:scale-[0.99] transition-all"
        >
          {currentStep === ONBOARDING_STEPS.length - 1 ? (
            <>
              Get Started <Check className="w-4 h-4" />
            </>
          ) : (
            <>
              Continue <ChevronRight className="w-4 h-4" />
            </>
          )}
        </button>
      </div>
    </div>
  );
};
