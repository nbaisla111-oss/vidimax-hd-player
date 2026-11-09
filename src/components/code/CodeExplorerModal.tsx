import React, { useState } from 'react';
import { X, Copy, Check, FileCode, Folder, Terminal, Download } from 'lucide-react';
import { FLUTTER_CODEBASE, FlutterFile } from '../../data/flutterFiles';

interface CodeExplorerModalProps {
  onClose: () => void;
  onShowToast: (msg: string, type?: 'success' | 'error' | 'info') => void;
}

export const CodeExplorerModal: React.FC<CodeExplorerModalProps> = ({ onClose, onShowToast }) => {
  const [selectedFile, setSelectedFile] = useState<FlutterFile>(FLUTTER_CODEBASE[0]);
  const [copied, setCopied] = useState(false);
  const [activeTab, setActiveTab] = useState<'code' | 'git'>('code');

  const handleCopy = () => {
    navigator.clipboard.writeText(selectedFile.code);
    setCopied(true);
    onShowToast(`Copied ${selectedFile.name} to clipboard!`, 'success');
    setTimeout(() => setCopied(false), 2000);
  };

  const handleDownloadFile = () => {
    const blob = new Blob([selectedFile.code], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = selectedFile.name;
    a.click();
    URL.revokeObjectURL(url);
    onShowToast(`Downloaded ${selectedFile.name}`, 'info');
  };

  return (
    <div
      onClick={onClose}
      className="fixed inset-0 bg-black/80 backdrop-blur-md z-50 flex items-center justify-center p-3 sm:p-6"
    >
      <div
        onClick={(e) => e.stopPropagation()}
        className="w-full max-w-4xl h-[85vh] bg-slate-900 border border-slate-700/80 rounded-2xl shadow-2xl flex flex-col overflow-hidden text-slate-100"
      >
        {/* Top Header */}
        <div className="px-5 py-3.5 bg-slate-950 border-b border-slate-800 flex items-center justify-between shrink-0">
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-xl bg-violet-600/20 text-violet-400 border border-violet-500/30">
              <FileCode className="w-5 h-5" />
            </div>
            <div>
              <h3 className="text-sm font-bold text-white flex items-center gap-2">
                Flutter Production Codebase
                <span className="text-[10px] font-mono text-cyan-400 px-2 py-0.5 rounded-full bg-cyan-950/60 border border-cyan-800/60">
                  Ready to Push
                </span>
              </h3>
              <p className="text-[11px] text-slate-400">
                Clean Architecture · Provider · Material 3 · Android 14 Granular Permissions
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={() => setActiveTab(activeTab === 'code' ? 'git' : 'code')}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-bold border transition-colors ${
                activeTab === 'git'
                  ? 'bg-violet-600 text-white border-violet-500'
                  : 'bg-slate-800 text-slate-300 border-slate-700 hover:text-white'
              }`}
            >
              <Terminal className="w-3.5 h-3.5" />
              <span>Git Push Guide</span>
            </button>

            <button
              onClick={onClose}
              className="p-1.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-400 hover:text-white"
            >
              <X className="w-4 h-4" />
            </button>
          </div>
        </div>

        {/* Modal Body */}
        {activeTab === 'code' ? (
          <div className="flex-1 flex flex-col sm:flex-row overflow-hidden">
            {/* Left File Tree Sidebar */}
            <div className="w-full sm:w-64 bg-slate-950/70 border-r border-slate-800 p-3 overflow-y-auto shrink-0 space-y-1">
              <div className="text-[11px] font-bold uppercase tracking-wider text-slate-500 px-2 py-1 flex items-center gap-1">
                <Folder className="w-3.5 h-3.5" /> Project Files
              </div>
              {FLUTTER_CODEBASE.map((file) => {
                const isSelected = selectedFile.path === file.path;
                return (
                  <button
                    key={file.path}
                    onClick={() => setSelectedFile(file)}
                    className={`w-full text-left px-2.5 py-1.5 rounded-lg text-xs font-mono flex items-center justify-between transition-colors ${
                      isSelected
                        ? 'bg-violet-600 text-white font-bold'
                        : 'text-slate-300 hover:bg-slate-800/60 hover:text-white'
                    }`}
                  >
                    <span className="truncate pr-1">{file.name}</span>
                    <span
                      className={`text-[9px] px-1.5 py-0.2 rounded font-sans uppercase ${
                        isSelected
                          ? 'bg-violet-800 text-white'
                          : 'bg-slate-800 text-slate-400'
                      }`}
                    >
                      {file.category}
                    </span>
                  </button>
                );
              })}
            </div>

            {/* Right Code Display */}
            <div className="flex-1 flex flex-col bg-slate-900 overflow-hidden">
              {/* Code Sub-header */}
              <div className="px-4 py-2 bg-slate-900/90 border-b border-slate-800 flex items-center justify-between shrink-0">
                <span className="text-xs font-mono text-violet-300">{selectedFile.path}</span>
                <div className="flex items-center gap-2">
                  <button
                    onClick={handleDownloadFile}
                    className="flex items-center gap-1 px-2.5 py-1 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 hover:text-white text-xs font-medium transition-colors"
                    title="Download file"
                  >
                    <Download className="w-3.5 h-3.5" />
                    <span>Download</span>
                  </button>
                  <button
                    onClick={handleCopy}
                    className="flex items-center gap-1 px-2.5 py-1 rounded-lg bg-violet-600 hover:bg-violet-500 text-white text-xs font-bold transition-colors"
                  >
                    {copied ? <Check className="w-3.5 h-3.5" /> : <Copy className="w-3.5 h-3.5" />}
                    <span>{copied ? 'Copied' : 'Copy'}</span>
                  </button>
                </div>
              </div>

              {/* Code Pre Container */}
              <div className="flex-1 p-4 overflow-auto font-mono text-xs leading-relaxed text-slate-200 bg-slate-950/90 selection:bg-violet-700 selection:text-white">
                <pre>{selectedFile.code}</pre>
              </div>
            </div>
          </div>
        ) : (
          /* Git Push Guide Tab */
          <div className="flex-1 p-6 overflow-y-auto space-y-6">
            <div className="p-4 rounded-xl bg-violet-950/40 border border-violet-800/50 space-y-2">
              <h4 className="text-sm font-bold text-white flex items-center gap-2">
                <Terminal className="w-4 h-4 text-violet-400" /> GitHub Repository Push Instruction
              </h4>
              <p className="text-xs text-slate-300 leading-relaxed">
                Provide your GitHub Personal Access Token (PAT) and repository name, and I will push the entire complete Flutter project directly into your GitHub account!
              </p>
            </div>

            <div className="space-y-3">
              <h5 className="text-xs font-bold uppercase tracking-wider text-slate-400">
                What you need to provide:
              </h5>
              <div className="space-y-2 text-xs">
                <div className="p-3 rounded-xl bg-slate-950 border border-slate-800 flex items-start gap-3">
                  <div className="w-6 h-6 rounded-full bg-violet-600 text-white font-bold flex items-center justify-center shrink-0 text-xs">
                    1
                  </div>
                  <div>
                    <strong className="text-white block">GitHub Personal Access Token (PAT)</strong>
                    <span className="text-slate-400">
                      Generated from GitHub Settings → Developer Settings → Personal Access Tokens with <code className="text-violet-300">repo</code> scope checked.
                    </span>
                  </div>
                </div>

                <div className="p-3 rounded-xl bg-slate-950 border border-slate-800 flex items-start gap-3">
                  <div className="w-6 h-6 rounded-full bg-violet-600 text-white font-bold flex items-center justify-center shrink-0 text-xs">
                    2
                  </div>
                  <div>
                    <strong className="text-white block">GitHub Username & Repo URL</strong>
                    <span className="text-slate-400">
                      e.g., <code className="text-violet-300">nbaisla111</code> and <code className="text-violet-300">https://github.com/nbaisla111/vidimax-hd-player.git</code>
                    </span>
                  </div>
                </div>
              </div>
            </div>

            <div className="space-y-2">
              <h5 className="text-xs font-bold uppercase tracking-wider text-slate-400">
                Exact Git Terminal Command Used for Pushing:
              </h5>
              <div className="p-3.5 rounded-xl bg-black border border-slate-800 font-mono text-xs text-emerald-400 overflow-x-auto">
                git init<br />
                git add .<br />
                git commit -m "feat: complete VidiMax HD Player Flutter production app"<br />
                git branch -M main<br />
                git remote add origin https://&lt;TOKEN&gt;@github.com/&lt;USERNAME&gt;/&lt;REPO&gt;.git<br />
                git push -u origin main
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
