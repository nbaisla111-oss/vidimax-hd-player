import React, { useState, useEffect } from 'react';
import {
  Shield,
  Lock,
  Unlock,
  KeyRound,
  Fingerprint,
  Plus,
  Play,
  RotateCcw,
  Check,
  AlertCircle,
  HelpCircle,
} from 'lucide-react';
import { VideoItem, VaultSecret } from '../../types';
import { formatDuration, formatFileSize } from '../../data/mockVideos';

interface VaultScreenProps {
  vaultVideos: VideoItem[];
  allVideos: VideoItem[];
  onPlayVideo: (video: VideoItem) => void;
  onHideVideo: (video: VideoItem) => void;
  onUnhideVideo: (video: VideoItem) => void;
  onShowToast: (msg: string, type?: 'success' | 'error' | 'info') => void;
}

const VAULT_STORAGE_KEY = 'vidimax_vault_pin_config';

export const VaultScreen: React.FC<VaultScreenProps> = ({
  vaultVideos,
  allVideos,
  onPlayVideo,
  onHideVideo,
  onUnhideVideo,
  onShowToast,
}) => {
  const [vaultConfig, setVaultConfig] = useState<VaultSecret | null>(null);
  const [isUnlocked, setIsUnlocked] = useState(false);
  const [enteredPin, setEnteredPin] = useState('');
  const [setupStep, setSetupStep] = useState<'initial' | 'confirm' | 'recovery'>('initial');
  const [tempPin, setTempPin] = useState('');
  const [secQuestion, setSecQuestion] = useState('What was your first pet name?');
  const [secAnswer, setSecAnswer] = useState('');
  const [isError, setIsError] = useState(false);
  const [showHidePicker, setShowHidePicker] = useState(false);
  const [showForgotModal, setShowForgotModal] = useState(false);
  const [forgotAnswerInput, setForgotAnswerInput] = useState('');

  // Load vault config from localStorage
  useEffect(() => {
    const saved = localStorage.getItem(VAULT_STORAGE_KEY);
    if (saved) {
      try {
        setVaultConfig(JSON.parse(saved));
      } catch (_) {}
    }
  }, []);

  // Save vault config
  const saveVaultConfig = (cfg: VaultSecret) => {
    setVaultConfig(cfg);
    localStorage.setItem(VAULT_STORAGE_KEY, JSON.stringify(cfg));
  };

  const handleDigit = (digit: string) => {
    if (enteredPin.length < 4) {
      const next = enteredPin + digit;
      setEnteredPin(next);
      if (next.length === 4) {
        processPin(next);
      }
    }
  };

  const handleDelete = () => {
    if (enteredPin.length > 0) {
      setEnteredPin(enteredPin.slice(0, -1));
      setIsError(false);
    }
  };

  const processPin = (pin: string) => {
    if (!vaultConfig) {
      // Setup Flow
      if (setupStep === 'initial') {
        setTempPin(pin);
        setSetupStep('confirm');
        setEnteredPin('');
      } else if (setupStep === 'confirm') {
        if (pin === tempPin) {
          setSetupStep('recovery');
          setEnteredPin('');
        } else {
          setIsError(true);
          onShowToast('PIN does not match. Please restart PIN setup.', 'error');
          setTimeout(() => {
            setSetupStep('initial');
            setTempPin('');
            setEnteredPin('');
            setIsError(false);
          }, 800);
        }
      }
    } else {
      // Normal Unlock Flow
      if (pin === vaultConfig.pin) {
        setIsUnlocked(true);
        setEnteredPin('');
        setIsError(false);
        onShowToast('Vault unlocked successfully!', 'success');
      } else {
        setIsError(true);
        onShowToast('Incorrect PIN. Please try again.', 'error');
        setTimeout(() => {
          setEnteredPin('');
          setIsError(false);
        }, 600);
      }
    }
  };

  const handleCompleteSetup = () => {
    if (!secAnswer.trim()) {
      onShowToast('Please provide an answer for recovery.', 'error');
      return;
    }
    const newConfig: VaultSecret = {
      pin: tempPin,
      isConfigured: true,
      securityQuestion: secQuestion,
      securityAnswer: secAnswer.trim().toLowerCase(),
    };
    saveVaultConfig(newConfig);
    setIsUnlocked(true);
    onShowToast('Vault PIN created successfully! Safe & encrypted.', 'success');
  };

  const handleBiometricUnlock = () => {
    if (!vaultConfig) return;
    setIsUnlocked(true);
    onShowToast('Biometric fingerprint authenticated', 'success');
  };

  const handleResetPin = () => {
    if (!vaultConfig) return;
    if (forgotAnswerInput.trim().toLowerCase() === vaultConfig.securityAnswer.toLowerCase()) {
      setShowForgotModal(false);
      setVaultConfig(null);
      localStorage.removeItem(VAULT_STORAGE_KEY);
      setSetupStep('initial');
      setEnteredPin('');
      onShowToast('Identity verified. Please create a new 4-digit PIN.', 'info');
    } else {
      onShowToast('Incorrect recovery answer.', 'error');
    }
  };

  // If Vault is unlocked, show the locked content manager
  if (isUnlocked) {
    return (
      <div className="flex-1 flex flex-col h-full bg-slate-950 text-slate-100 overflow-hidden">
        {/* Top Unlocked Header */}
        <div className="p-4 bg-slate-900/90 border-b border-slate-800 flex items-center justify-between shrink-0">
          <div className="flex items-center gap-2.5">
            <div className="p-2 rounded-xl bg-violet-600/20 text-violet-400 border border-violet-500/30">
              <Shield className="w-5 h-5 text-violet-400" />
            </div>
            <div>
              <h2 className="text-sm font-bold text-white flex items-center gap-1.5">
                Secret Vault <span className="text-[10px] text-emerald-400 font-semibold px-2 py-0.5 rounded-full bg-emerald-950/60 border border-emerald-800/60">Unlocked</span>
              </h2>
              <p className="text-[11px] text-slate-400">
                {vaultVideos.length} encrypted {vaultVideos.length === 1 ? 'file' : 'files'} · AES-256
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={() => setShowHidePicker(true)}
              className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-violet-600 hover:bg-violet-500 text-white text-xs font-semibold shadow-md active:scale-95 transition-all"
            >
              <Plus className="w-4 h-4" />
              <span>Hide Video</span>
            </button>
            <button
              onClick={() => {
                setIsUnlocked(false);
                onShowToast('Secret Vault locked.', 'info');
              }}
              className="p-2 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-300 hover:text-white transition-colors"
              title="Lock Vault now"
            >
              <Lock className="w-4 h-4 text-amber-300" />
            </button>
          </div>
        </div>

        {/* Vault Video List */}
        <div className="flex-1 overflow-y-auto p-4 space-y-3">
          {vaultVideos.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-20 text-center">
              <div className="w-16 h-16 rounded-2xl bg-violet-950/50 border border-violet-800/40 flex items-center justify-center mb-4">
                <Shield className="w-8 h-8 text-violet-400" />
              </div>
              <h3 className="text-base font-bold text-white mb-1">Your Vault is Empty</h3>
              <p className="text-xs text-slate-400 max-w-xs mb-5">
                Protect sensitive personal media. Tap "Hide Video" to move and encrypt files from your gallery into this locker.
              </p>
              <button
                onClick={() => setShowHidePicker(true)}
                className="px-4 py-2 rounded-xl bg-violet-600 hover:bg-violet-500 text-white text-xs font-bold transition-all shadow-lg shadow-violet-900/30"
              >
                Hide Videos Now
              </button>
            </div>
          ) : (
            vaultVideos.map((video) => (
              <div
                key={video.id}
                className="flex items-center gap-3 p-3 rounded-2xl bg-slate-900/80 border border-slate-800/80 hover:border-violet-500/40 transition-all"
              >
                <div
                  onClick={() => onPlayVideo(video)}
                  className="relative w-24 h-16 rounded-xl overflow-hidden bg-slate-800 shrink-0 cursor-pointer"
                >
                  <img
                    src={video.thumbnailUrl}
                    alt={video.title}
                    referrerPolicy="no-referrer"
                    className="w-full h-full object-cover"
                  />
                  <div className="absolute inset-0 bg-black/40 flex items-center justify-center">
                    <Play className="w-5 h-5 text-white fill-white" />
                  </div>
                  <span className="absolute bottom-1 right-1 px-1 py-0.2 rounded bg-black/80 text-[9px] font-mono font-bold text-white">
                    {formatDuration(video.duration)}
                  </span>
                </div>

                <div className="flex-1 min-w-0">
                  <h4 className="text-xs font-bold text-white truncate mb-1">{video.title}</h4>
                  <div className="flex items-center gap-2 text-[10px] text-slate-400">
                    <span>{formatFileSize(video.size)}</span>
                    <span>·</span>
                    <span className="text-emerald-400 font-medium">AES Encrypted</span>
                  </div>
                </div>

                {/* Actions: Play or Unhide */}
                <div className="flex items-center gap-1.5 shrink-0">
                  <button
                    onClick={() => onPlayVideo(video)}
                    className="p-2 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-200 transition-colors"
                    title="Play encrypted video"
                  >
                    <Play className="w-4 h-4" />
                  </button>
                  <button
                    onClick={() => onUnhideVideo(video)}
                    className="p-2 rounded-xl bg-violet-950/60 hover:bg-violet-900 text-violet-300 border border-violet-800/50 transition-colors"
                    title="Unhide & restore to public gallery"
                  >
                    <Unlock className="w-4 h-4" />
                  </button>
                </div>
              </div>
            ))
          )}
        </div>

        {/* Modal: Pick Video from Gallery to Hide */}
        {showHidePicker && (
          <div
            onClick={() => setShowHidePicker(false)}
            className="fixed inset-0 bg-black/75 backdrop-blur-sm z-50 flex items-center justify-center p-4"
          >
            <div
              onClick={(e) => e.stopPropagation()}
              className="w-full max-w-md rounded-2xl bg-slate-900 border border-slate-700 p-5 shadow-2xl max-h-[85vh] flex flex-col"
            >
              <div className="flex items-center justify-between pb-3 border-b border-slate-800 mb-3">
                <h3 className="text-sm font-bold text-white flex items-center gap-2">
                  <Lock className="w-4 h-4 text-violet-400" /> Select Video to Encrypt & Hide
                </h3>
                <button
                  onClick={() => setShowHidePicker(false)}
                  className="p-1 rounded-lg text-slate-400 hover:text-white"
                >
                  ✕
                </button>
              </div>

              <div className="flex-1 overflow-y-auto space-y-2 py-2">
                {allVideos.length === 0 ? (
                  <p className="text-xs text-slate-400 text-center py-6">
                    All videos are already in the vault or no videos available.
                  </p>
                ) : (
                  allVideos.map((video) => (
                    <div
                      key={video.id}
                      onClick={() => {
                        onHideVideo(video);
                        setShowHidePicker(false);
                      }}
                      className="flex items-center gap-3 p-2.5 rounded-xl bg-slate-950 hover:bg-violet-950/40 border border-slate-800 hover:border-violet-600/50 cursor-pointer transition-all"
                    >
                      <img
                        src={video.thumbnailUrl}
                        alt=""
                        className="w-12 h-10 rounded-lg object-cover bg-slate-800 shrink-0"
                      />
                      <div className="flex-1 min-w-0">
                        <p className="text-xs font-bold text-white truncate">{video.title}</p>
                        <p className="text-[10px] text-slate-400">
                          {formatFileSize(video.size)} · {video.folder}
                        </p>
                      </div>
                      <span className="text-xs text-violet-400 font-semibold px-2 py-1 rounded bg-violet-600/20">
                        Hide
                      </span>
                    </div>
                  ))
                )}
              </div>
            </div>
          </div>
        )}
      </div>
    );
  }

  // First-time Security Question Step
  if (!vaultConfig && setupStep === 'recovery') {
    return (
      <div className="flex-1 flex flex-col justify-center p-6 bg-slate-950 text-white max-w-sm mx-auto w-full">
        <div className="text-center mb-6">
          <div className="w-14 h-14 rounded-2xl bg-violet-600/20 border border-violet-500/30 flex items-center justify-center mx-auto mb-3">
            <KeyRound className="w-7 h-7 text-violet-400" />
          </div>
          <h2 className="text-xl font-bold">Password Recovery Setup</h2>
          <p className="text-xs text-slate-400 mt-1">
            In case you forget your 4-digit PIN, this question will allow you to securely reset it.
          </p>
        </div>

        <div className="space-y-4 mb-6">
          <div>
            <label className="text-xs font-semibold text-slate-300 block mb-1.5">
              Select Security Question
            </label>
            <select
              value={secQuestion}
              onChange={(e) => setSecQuestion(e.target.value)}
              className="w-full bg-slate-900 border border-slate-800 rounded-xl px-3 py-2.5 text-xs text-white focus:outline-none focus:border-violet-500"
            >
              <option value="What was your first pet name?">What was your first pet name?</option>
              <option value="What was the name of your primary school?">
                What was the name of your primary school?
              </option>
              <option value="What city were you born in?">What city were you born in?</option>
              <option value="What is your favorite movie?">What is your favorite movie?</option>
            </select>
          </div>

          <div>
            <label className="text-xs font-semibold text-slate-300 block mb-1.5">
              Your Secret Answer
            </label>
            <input
              type="text"
              placeholder="e.g. Leo or Delhi"
              value={secAnswer}
              onChange={(e) => setSecAnswer(e.target.value)}
              className="w-full bg-slate-900 border border-slate-800 rounded-xl px-3 py-2.5 text-xs text-white focus:outline-none focus:border-violet-500"
            />
          </div>
        </div>

        <button
          onClick={handleCompleteSetup}
          className="w-full h-11 rounded-xl bg-violet-600 hover:bg-violet-500 text-white text-xs font-bold transition-all shadow-lg shadow-violet-600/30"
        >
          Confirm & Save Vault
        </button>
      </div>
    );
  }

  // 4-Digit PIN Keypad Screen (for Setup or Unlock)
  const isSetup = !vaultConfig;
  const title = isSetup
    ? setupStep === 'initial'
      ? 'Create Secret Vault PIN'
      : 'Confirm Your PIN'
    : 'Secret Private Vault';

  const subtitle = isSetup
    ? setupStep === 'initial'
      ? 'Set a 4-digit master PIN to protect hidden media'
      : 'Re-enter your 4-digit PIN to verify'
    : 'Enter 4-digit PIN to access encrypted files';

  return (
    <div className="flex-1 flex flex-col justify-between items-center p-6 bg-slate-950 text-white select-none overflow-y-auto">
      {/* Top Header */}
      <div className="flex flex-col items-center text-center mt-4">
        <div className="w-16 h-16 rounded-3xl bg-gradient-to-br from-violet-600 to-indigo-600 flex items-center justify-center shadow-xl shadow-violet-900/40 mb-3 border border-white/10">
          <Shield className="w-8 h-8 text-white" />
        </div>
        <h2 className="text-lg font-bold text-white mb-1">{title}</h2>
        <p className="text-xs text-slate-400 max-w-xs">{subtitle}</p>

        {/* 4 Dots PIN Display */}
        <div
          className={`flex items-center gap-4 mt-6 transition-transform ${
            isError ? 'animate-shake' : ''
          }`}
        >
          {[0, 1, 2, 3].map((idx) => {
            const filled = idx < enteredPin.length;
            return (
              <div
                key={idx}
                className={`w-3.5 h-3.5 rounded-full transition-all duration-200 ${
                  filled
                    ? 'bg-violet-500 scale-125 shadow-md shadow-violet-500/50'
                    : 'bg-slate-800 border border-slate-700'
                }`}
              />
            );
          })}
        </div>
      </div>

      {/* Numeric Keypad */}
      <div className="w-full max-w-xs my-auto py-4">
        <div className="grid grid-cols-3 gap-3 sm:gap-4">
          {['1', '2', '3', '4', '5', '6', '7', '8', '9'].map((digit) => (
            <button
              key={digit}
              onClick={() => handleDigit(digit)}
              className="h-14 sm:h-16 rounded-2xl bg-slate-900/90 hover:bg-slate-800 border border-slate-800 text-xl font-bold text-white flex items-center justify-center active:scale-95 transition-all shadow-sm"
            >
              {digit}
            </button>
          ))}

          {/* Bottom Row: Biometric / Recovery, 0, Backspace */}
          <button
            onClick={() => {
              if (vaultConfig) handleBiometricUnlock();
            }}
            className="h-14 sm:h-16 rounded-2xl bg-slate-900/50 hover:bg-slate-800/80 border border-slate-800/60 text-slate-300 flex items-center justify-center active:scale-95 transition-all"
            title="Biometric Fingerprint"
          >
            <Fingerprint className="w-6 h-6 text-cyan-400" />
          </button>

          <button
            onClick={() => handleDigit('0')}
            className="h-14 sm:h-16 rounded-2xl bg-slate-900/90 hover:bg-slate-800 border border-slate-800 text-xl font-bold text-white flex items-center justify-center active:scale-95 transition-all shadow-sm"
          >
            0
          </button>

          <button
            onClick={handleDelete}
            className="h-14 sm:h-16 rounded-2xl bg-slate-900/50 hover:bg-slate-800/80 border border-slate-800/60 text-slate-300 flex items-center justify-center active:scale-95 transition-all"
            title="Delete digit"
          >
            <RotateCcw className="w-5 h-5 text-slate-400" />
          </button>
        </div>
      </div>

      {/* Footer link for Forgot PIN */}
      {vaultConfig && (
        <div className="pb-2">
          <button
            onClick={() => setShowForgotModal(true)}
            className="text-xs text-slate-400 hover:text-violet-400 underline"
          >
            Forgot PIN?
          </button>
        </div>
      )}

      {/* Forgot PIN Recovery Modal */}
      {showForgotModal && vaultConfig && (
        <div
          onClick={() => setShowForgotModal(false)}
          className="fixed inset-0 bg-black/75 backdrop-blur-sm z-50 flex items-center justify-center p-4"
        >
          <div
            onClick={(e) => e.stopPropagation()}
            className="w-full max-w-sm rounded-2xl bg-slate-900 border border-slate-700 p-5 shadow-2xl text-slate-100"
          >
            <h3 className="text-sm font-bold text-white mb-2 flex items-center gap-2">
              <HelpCircle className="w-4 h-4 text-violet-400" /> Security Verification
            </h3>
            <p className="text-xs text-slate-300 mb-3">{vaultConfig.securityQuestion}</p>
            <input
              type="text"
              placeholder="Your answer"
              value={forgotAnswerInput}
              onChange={(e) => setForgotAnswerInput(e.target.value)}
              className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-xs text-white mb-4 focus:outline-none focus:border-violet-500"
            />
            <div className="flex justify-end gap-2">
              <button
                onClick={() => setShowForgotModal(false)}
                className="px-3 py-1.5 rounded-lg text-xs text-slate-400 hover:text-white"
              >
                Cancel
              </button>
              <button
                onClick={handleResetPin}
                className="px-4 py-1.5 rounded-lg bg-violet-600 hover:bg-violet-500 text-white text-xs font-bold"
              >
                Verify & Reset
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
