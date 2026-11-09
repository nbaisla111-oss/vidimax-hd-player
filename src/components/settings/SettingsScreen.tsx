import React, { useState } from 'react';
import {
  Moon,
  Sun,
  HardDrive,
  Trash2,
  Cpu,
  Headphones,
  History,
  Star,
  ShieldCheck,
  Code2,
  GitBranch,
  ChevronRight,
  ExternalLink,
  Info,
  Check,
  X,
} from 'lucide-react';
import { VideoItem } from '../../types';
import { formatFileSize } from '../../data/mockVideos';

interface SettingsScreenProps {
  videos: VideoItem[];
  vaultVideos: VideoItem[];
  themeMode: 'dark' | 'light';
  onToggleTheme: () => void;
  onOpenCodeExplorer: () => void;
  onShowToast: (msg: string, type?: 'success' | 'error' | 'info') => void;
}

export const SettingsScreen: React.FC<SettingsScreenProps> = ({
  videos,
  vaultVideos,
  themeMode,
  onToggleTheme,
  onOpenCodeExplorer,
  onShowToast,
}) => {
  const [hwAcceleration, setHwAcceleration] = useState(true);
  const [backgroundAudio, setBackgroundAudio] = useState(true);
  const [resumePlayback, setResumePlayback] = useState(true);
  const [cacheSize, setCacheSize] = useState(48.6 * 1024 * 1024); // ~48.6 MB
  const [showRatingModal, setShowRatingModal] = useState(false);
  const [selectedRating, setSelectedRating] = useState(5);
  const [showPrivacyModal, setShowPrivacyModal] = useState(false);
  const [showGithubModal, setShowGithubModal] = useState(false);

  // Storage calculations
  const totalVideoSize = videos.reduce((acc, v) => acc + v.size, 0);
  const totalVaultSize = vaultVideos.reduce((acc, v) => acc + v.size, 0);
  const totalStorage = 64 * 1024 * 1024 * 1024; // 64 GB
  const freeStorage = totalStorage - (totalVideoSize + totalVaultSize + cacheSize);

  const handleClearCache = () => {
    setCacheSize(0);
    onShowToast('Thumbnail & temp cache cleared! Freed up 48.6 MB.', 'success');
  };

  const handleRateSubmit = () => {
    setShowRatingModal(false);
    onShowToast(`Thank you for rating VidiMax HD ${selectedRating} stars!`, 'success');
  };

  return (
    <div className="flex-1 flex flex-col h-full bg-slate-950 text-slate-100 overflow-y-auto p-4 sm:p-6 space-y-5">
      {/* Top Header */}
      <div className="flex items-center justify-between pb-2 border-b border-slate-800/80">
        <div>
          <h2 className="text-base font-bold text-white">Settings & Code</h2>
          <p className="text-xs text-slate-400">VidiMax HD Player v1.0.0 (Production)</p>
        </div>

        {/* GitHub Codebase Button */}
        <button
          onClick={onOpenCodeExplorer}
          className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-violet-600 hover:bg-violet-500 text-white text-xs font-bold shadow-md shadow-violet-700/20 active:scale-95 transition-all"
        >
          <Code2 className="w-4 h-4" />
          <span>Flutter Source</span>
        </button>
      </div>

      {/* Internal Storage Card */}
      <div className="p-4 rounded-2xl bg-slate-900 border border-slate-800 space-y-3">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <HardDrive className="w-4 h-4 text-cyan-400" />
            <span className="text-xs font-bold text-white">Device Internal Storage</span>
          </div>
          <span className="text-[11px] font-mono text-slate-400">
            {formatFileSize(totalStorage - freeStorage)} / {formatFileSize(totalStorage)}
          </span>
        </div>

        {/* Multi-colored Storage Bar */}
        <div className="w-full h-2.5 rounded-full bg-slate-800 overflow-hidden flex">
          <div
            className="bg-violet-500 h-full transition-all"
            style={{ width: `${Math.max(5, (totalVideoSize / totalStorage) * 100 * 5)}%` }}
            title="Videos"
          />
          <div
            className="bg-cyan-400 h-full transition-all"
            style={{ width: `${Math.max(3, (totalVaultSize / totalStorage) * 100 * 5)}%` }}
            title="Secret Vault"
          />
          <div
            className="bg-emerald-400 h-full transition-all"
            style={{ width: `${cacheSize > 0 ? 3 : 0}%` }}
            title="Cache"
          />
        </div>

        {/* Storage Legend */}
        <div className="flex flex-wrap items-center justify-between gap-2 pt-1 text-[11px] text-slate-400">
          <div className="flex items-center gap-1.5">
            <span className="w-2 h-2 rounded-full bg-violet-500" />
            <span>Videos ({formatFileSize(totalVideoSize)})</span>
          </div>
          <div className="flex items-center gap-1.5">
            <span className="w-2 h-2 rounded-full bg-cyan-400" />
            <span>Vault ({formatFileSize(totalVaultSize)})</span>
          </div>
          <div className="flex items-center gap-1.5">
            <span className="w-2 h-2 rounded-full bg-emerald-400" />
            <span>Cache ({formatFileSize(cacheSize)})</span>
          </div>
        </div>
      </div>

      {/* Appearance & Theme Section */}
      <div className="space-y-2">
        <h3 className="text-xs font-bold uppercase tracking-wider text-slate-400 px-1">
          Appearance & Theme
        </h3>
        <div className="p-3.5 rounded-2xl bg-slate-900 border border-slate-800 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-xl bg-violet-600/20 text-violet-400 flex items-center justify-center">
              {themeMode === 'dark' ? <Moon className="w-5 h-5" /> : <Sun className="w-5 h-5" />}
            </div>
            <div>
              <p className="text-xs font-bold text-white">App Theme</p>
              <p className="text-[11px] text-slate-400">
                {themeMode === 'dark' ? 'AMOLED Dark Theme' : 'Clean Light Mode'}
              </p>
            </div>
          </div>
          <button
            onClick={onToggleTheme}
            className={`w-11 h-6 rounded-full transition-colors relative p-0.5 ${
              themeMode === 'dark' ? 'bg-violet-600' : 'bg-slate-700'
            }`}
          >
            <div
              className={`w-5 h-5 rounded-full bg-white transition-transform ${
                themeMode === 'dark' ? 'translate-x-5' : 'translate-x-0'
              }`}
            />
          </button>
        </div>
      </div>

      {/* Playback Preferences */}
      <div className="space-y-2">
        <h3 className="text-xs font-bold uppercase tracking-wider text-slate-400 px-1">
          Playback Preferences
        </h3>
        <div className="rounded-2xl bg-slate-900 border border-slate-800 divide-y divide-slate-800">
          {/* Hardware Acceleration */}
          <div className="p-3.5 flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-xl bg-cyan-600/20 text-cyan-400 flex items-center justify-center">
                <Cpu className="w-5 h-5" />
              </div>
              <div>
                <p className="text-xs font-bold text-white">Hardware Acceleration</p>
                <p className="text-[11px] text-slate-400">GPU decoded 4K 60FPS video playback</p>
              </div>
            </div>
            <button
              onClick={() => setHwAcceleration(!hwAcceleration)}
              className={`w-11 h-6 rounded-full transition-colors relative p-0.5 ${
                hwAcceleration ? 'bg-violet-600' : 'bg-slate-700'
              }`}
            >
              <div
                className={`w-5 h-5 rounded-full bg-white transition-transform ${
                  hwAcceleration ? 'translate-x-5' : 'translate-x-0'
                }`}
              />
            </button>
          </div>

          {/* Background Audio Play */}
          <div className="p-3.5 flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-xl bg-emerald-600/20 text-emerald-400 flex items-center justify-center">
                <Headphones className="w-5 h-5" />
              </div>
              <div>
                <p className="text-xs font-bold text-white">Background Audio Play</p>
                <p className="text-[11px] text-slate-400">Keep audio playing when switching apps</p>
              </div>
            </div>
            <button
              onClick={() => setBackgroundAudio(!backgroundAudio)}
              className={`w-11 h-6 rounded-full transition-colors relative p-0.5 ${
                backgroundAudio ? 'bg-violet-600' : 'bg-slate-700'
              }`}
            >
              <div
                className={`w-5 h-5 rounded-full bg-white transition-transform ${
                  backgroundAudio ? 'translate-x-5' : 'translate-x-0'
                }`}
              />
            </button>
          </div>

          {/* Resume Playback */}
          <div className="p-3.5 flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-xl bg-amber-600/20 text-amber-400 flex items-center justify-center">
                <History className="w-5 h-5" />
              </div>
              <div>
                <p className="text-xs font-bold text-white">Auto-Resume Playback</p>
                <p className="text-[11px] text-slate-400">Remember last watched position</p>
              </div>
            </div>
            <button
              onClick={() => setResumePlayback(!resumePlayback)}
              className={`w-11 h-6 rounded-full transition-colors relative p-0.5 ${
                resumePlayback ? 'bg-violet-600' : 'bg-slate-700'
              }`}
            >
              <div
                className={`w-5 h-5 rounded-full bg-white transition-transform ${
                  resumePlayback ? 'translate-x-5' : 'translate-x-0'
                }`}
              />
            </button>
          </div>
        </div>
      </div>

      {/* Storage Maintenance & Clear Cache */}
      <div className="space-y-2">
        <h3 className="text-xs font-bold uppercase tracking-wider text-slate-400 px-1">
          Storage Maintenance
        </h3>
        <div className="p-3.5 rounded-2xl bg-slate-900 border border-slate-800 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-xl bg-orange-600/20 text-orange-400 flex items-center justify-center">
              <Trash2 className="w-5 h-5" />
            </div>
            <div>
              <p className="text-xs font-bold text-white">Clear Thumbnail Cache</p>
              <p className="text-[11px] text-slate-400">
                Temporary cache: {formatFileSize(cacheSize)}
              </p>
            </div>
          </div>
          <button
            onClick={handleClearCache}
            disabled={cacheSize === 0}
            className="px-3 py-1.5 rounded-xl bg-orange-600/20 hover:bg-orange-600/30 text-orange-400 text-xs font-bold disabled:opacity-40 transition-colors"
          >
            {cacheSize === 0 ? 'Clean' : 'Clear Now'}
          </button>
        </div>
      </div>

      {/* GitHub Repository Push Details Card */}
      <div className="p-4 rounded-2xl bg-gradient-to-br from-violet-950/60 to-slate-900 border border-violet-800/50 space-y-3">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <GitBranch className="w-5 h-5 text-violet-400" />
            <h4 className="text-xs font-bold text-white">GitHub Repo Ready</h4>
          </div>
          <button
            onClick={() => setShowGithubModal(true)}
            className="text-[11px] text-cyan-400 font-semibold underline flex items-center gap-1"
          >
            Push Details <ChevronRight className="w-3.5 h-3.5" />
          </button>
        </div>
        <p className="text-xs text-slate-300">
          The full Flutter project (models, controllers, services, views, AndroidManifest, pubspec) is written and ready to push to your repository.
        </p>
        <button
          onClick={onOpenCodeExplorer}
          className="w-full py-2.5 rounded-xl bg-violet-600 hover:bg-violet-500 text-white text-xs font-bold flex items-center justify-center gap-2 shadow-md transition-colors"
        >
          <Code2 className="w-4 h-4" />
          <span>Browse Flutter Code Files</span>
        </button>
      </div>

      {/* Support & About Links */}
      <div className="space-y-2">
        <h3 className="text-xs font-bold uppercase tracking-wider text-slate-400 px-1">
          Support & About
        </h3>
        <div className="rounded-2xl bg-slate-900 border border-slate-800 divide-y divide-slate-800">
          <div
            onClick={() => setShowRatingModal(true)}
            className="p-3.5 flex items-center justify-between hover:bg-slate-800/50 cursor-pointer transition-colors"
          >
            <div className="flex items-center gap-3">
              <Star className="w-5 h-5 text-amber-400" />
              <div>
                <p className="text-xs font-bold text-white">Rate Us 5 Stars</p>
                <p className="text-[11px] text-slate-400">Support development & give feedback</p>
              </div>
            </div>
            <ChevronRight className="w-4 h-4 text-slate-500" />
          </div>

          <div
            onClick={() => setShowPrivacyModal(true)}
            className="p-3.5 flex items-center justify-between hover:bg-slate-800/50 cursor-pointer transition-colors"
          >
            <div className="flex items-center gap-3">
              <ShieldCheck className="w-5 h-5 text-emerald-400" />
              <div>
                <p className="text-xs font-bold text-white">100% Offline Privacy Policy</p>
                <p className="text-[11px] text-slate-400">Zero cloud uploads, local AES encryption</p>
              </div>
            </div>
            <ChevronRight className="w-4 h-4 text-slate-500" />
          </div>
        </div>
      </div>

      {/* Rate Us Modal */}
      {showRatingModal && (
        <div
          onClick={() => setShowRatingModal(false)}
          className="fixed inset-0 bg-black/75 backdrop-blur-sm z-50 flex items-center justify-center p-4"
        >
          <div
            onClick={(e) => e.stopPropagation()}
            className="w-full max-w-sm rounded-2xl bg-slate-900 border border-slate-700 p-5 shadow-2xl text-center"
          >
            <div className="w-12 h-12 rounded-2xl bg-amber-500/20 text-amber-400 flex items-center justify-center mx-auto mb-3">
              <Star className="w-6 h-6 fill-amber-400" />
            </div>
            <h3 className="text-sm font-bold text-white mb-1">Rate VidiMax HD Player</h3>
            <p className="text-xs text-slate-400 mb-4">
              How was your experience with offline playback and private vault?
            </p>

            <div className="flex justify-center gap-2 mb-6">
              {[1, 2, 3, 4, 5].map((star) => (
                <button
                  key={star}
                  onClick={() => setSelectedRating(star)}
                  className="p-1 hover:scale-110 transition-transform"
                >
                  <Star
                    className={`w-7 h-7 ${
                      star <= selectedRating
                        ? 'text-amber-400 fill-amber-400'
                        : 'text-slate-600'
                    }`}
                  />
                </button>
              ))}
            </div>

            <div className="flex gap-2">
              <button
                onClick={() => setShowRatingModal(false)}
                className="flex-1 py-2 rounded-xl bg-slate-800 text-slate-300 text-xs font-bold"
              >
                Cancel
              </button>
              <button
                onClick={handleRateSubmit}
                className="flex-1 py-2 rounded-xl bg-violet-600 hover:bg-violet-500 text-white text-xs font-bold shadow-md"
              >
                Submit Review
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Privacy Policy Modal */}
      {showPrivacyModal && (
        <div
          onClick={() => setShowPrivacyModal(false)}
          className="fixed inset-0 bg-black/75 backdrop-blur-sm z-50 flex items-center justify-center p-4"
        >
          <div
            onClick={(e) => e.stopPropagation()}
            className="w-full max-w-md rounded-2xl bg-slate-900 border border-slate-700 p-5 shadow-2xl text-slate-100 max-h-[80vh] flex flex-col"
          >
            <div className="flex items-center justify-between pb-3 border-b border-slate-800 mb-3">
              <h3 className="text-sm font-bold text-white flex items-center gap-2">
                <ShieldCheck className="w-5 h-5 text-emerald-400" /> 100% Offline Privacy Guarantee
              </h3>
              <button onClick={() => setShowPrivacyModal(false)} className="text-slate-400 hover:text-white">
                <X className="w-4 h-4" />
              </button>
            </div>
            <div className="flex-1 overflow-y-auto space-y-3 text-xs text-slate-300 leading-relaxed pr-1">
              <p>
                <strong>1. Zero Cloud Uploads:</strong> VidiMax HD Player is engineered to operate 100% offline. No video files, metadata, search queries, or user telemetry are sent to any remote servers.
              </p>
              <p>
                <strong>2. Secret Locker Military Encryption:</strong> Media placed in the Private Vault is encrypted on-device using local AES-256 with keys derived from your 4-digit PIN. Locked files are relocated to app-internal sandboxed storage.
              </p>
              <p>
                <strong>3. WhatsApp Status Saver:</strong> Status viewing and saving reads solely from local Android cached paths (<code className="text-emerald-400 font-mono text-[10px]">/.Statuses</code>) without requiring WhatsApp login credentials.
              </p>
            </div>
            <div className="mt-4 pt-3 border-t border-slate-800 flex justify-end">
              <button
                onClick={() => setShowPrivacyModal(false)}
                className="px-4 py-2 rounded-xl bg-violet-600 hover:bg-violet-500 text-white text-xs font-bold"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}

      {/* GitHub Push Details Modal */}
      {showGithubModal && (
        <div
          onClick={() => setShowGithubModal(false)}
          className="fixed inset-0 bg-black/75 backdrop-blur-sm z-50 flex items-center justify-center p-4"
        >
          <div
            onClick={(e) => e.stopPropagation()}
            className="w-full max-w-md rounded-2xl bg-slate-900 border border-slate-700 p-5 shadow-2xl text-slate-100"
          >
            <div className="flex items-center justify-between pb-3 border-b border-slate-800 mb-3">
              <h3 className="text-sm font-bold text-white flex items-center gap-2">
                <GitBranch className="w-5 h-5 text-violet-400" /> GitHub Repository Push Details
              </h3>
              <button onClick={() => setShowGithubModal(false)} className="text-slate-400 hover:text-white">
                <X className="w-4 h-4" />
              </button>
            </div>

            <p className="text-xs text-slate-300 mb-3">
              To push the full Flutter codebase into your GitHub repository, send me these details:
            </p>

            <ul className="text-xs text-slate-300 space-y-2 mb-4 bg-slate-950 p-3 rounded-xl border border-slate-800">
              <li className="flex items-start gap-2">
                <span className="w-1.5 h-1.5 rounded-full bg-violet-400 mt-1.5 shrink-0" />
                <span><strong>GitHub Personal Access Token (PAT):</strong> with <code className="text-violet-300">repo</code> scope</span>
              </li>
              <li className="flex items-start gap-2">
                <span className="w-1.5 h-1.5 rounded-full bg-violet-400 mt-1.5 shrink-0" />
                <span><strong>GitHub Username:</strong> e.g. <code className="text-violet-300">nbaisla111</code></span>
              </li>
              <li className="flex items-start gap-2">
                <span className="w-1.5 h-1.5 rounded-full bg-violet-400 mt-1.5 shrink-0" />
                <span><strong>Repository Name:</strong> e.g. <code className="text-violet-300">vidimax-hd-player</code></span>
              </li>
            </ul>

            <div className="flex justify-end">
              <button
                onClick={() => setShowGithubModal(false)}
                className="px-4 py-2 rounded-xl bg-violet-600 text-white text-xs font-bold"
              >
                Got It
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
