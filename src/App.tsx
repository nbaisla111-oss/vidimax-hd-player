/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState, useEffect } from 'react';
import { VideoItem, ActiveTab } from './types';
import { INITIAL_VIDEOS } from './data/mockVideos';
import { PhoneFrame } from './components/phone/PhoneFrame';
import { SplashScreen } from './components/splash/SplashScreen';
import { OnboardingScreen } from './components/onboarding/OnboardingScreen';
import { BottomTabBar } from './components/navigation/BottomTabBar';
import { HomeScreen } from './components/home/HomeScreen';
import { CustomVideoPlayer } from './components/player/CustomVideoPlayer';
import { VaultScreen } from './components/vault/VaultScreen';
import { ToolsScreen } from './components/tools/ToolsScreen';
import { SettingsScreen } from './components/settings/SettingsScreen';
import { CodeExplorerModal } from './components/code/CodeExplorerModal';
import { Toast, ToastMessage } from './components/common/Toast';

export default function App() {
  const [appStage, setAppStage] = useState<'splash' | 'onboarding' | 'main'>('splash');
  const [activeTab, setActiveTab] = useState<ActiveTab>('videos');
  const [videos, setVideos] = useState<VideoItem[]>(INITIAL_VIDEOS);
  const [vaultVideos, setVaultVideos] = useState<VideoItem[]>([]);
  const [activePlayingVideo, setActivePlayingVideo] = useState<VideoItem | null>(null);
  const [showCodeExplorer, setShowCodeExplorer] = useState(false);
  const [themeMode, setThemeMode] = useState<'dark' | 'light'>('dark');
  const [toasts, setToasts] = useState<ToastMessage[]>([]);

  // Check if onboarding was already seen
  useEffect(() => {
    const seen = localStorage.getItem('vidimax_seen_onboarding');
    if (seen === 'true' && appStage === 'splash') {
      // Keep splash for 1.8s then go straight to main
      const t = setTimeout(() => setAppStage('main'), 2000);
      return () => clearTimeout(t);
    }
  }, []);

  // Sync theme with html class
  useEffect(() => {
    if (themeMode === 'dark') {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
  }, [themeMode]);

  const showToast = (message: string, type: 'success' | 'error' | 'info' = 'info') => {
    const id = `${Date.now()}-${Math.random()}`;
    setToasts((prev) => [...prev, { id, type, message }]);
    setTimeout(() => {
      setToasts((prev) => prev.filter((t) => t.id !== id));
    }, 3500);
  };

  const dismissToast = (id: string) => {
    setToasts((prev) => prev.filter((t) => t.id !== id));
  };

  const handleFinishSplash = () => {
    const seen = localStorage.getItem('vidimax_seen_onboarding');
    if (seen === 'true') {
      setAppStage('main');
    } else {
      setAppStage('onboarding');
    }
  };

  const handleCompleteOnboarding = () => {
    localStorage.setItem('vidimax_seen_onboarding', 'true');
    setAppStage('main');
    showToast('Welcome to VidiMax HD Player! Local storage scanned.', 'success');
  };

  // Video Actions
  const handlePlayVideo = (video: VideoItem) => {
    setActivePlayingVideo(video);
  };

  const handleClosePlayer = () => {
    setActivePlayingVideo(null);
  };

  const handleMoveToVault = (video: VideoItem) => {
    setVideos((prev) => prev.filter((v) => v.id !== video.id));
    setVaultVideos((prev) => [...prev, { ...video, isVault: true }]);
    showToast(`"${video.title}" encrypted and moved to Secret Vault`, 'success');
  };

  const handleUnhideVideo = (video: VideoItem) => {
    setVaultVideos((prev) => prev.filter((v) => v.id !== video.id));
    setVideos((prev) => [{ ...video, isVault: false }, ...prev]);
    showToast(`"${video.title}" decrypted and restored to Gallery`, 'success');
  };

  const handleConvertToMp3 = (video: VideoItem) => {
    setActiveTab('tools');
    showToast(`Selected "${video.title}" for MP3 extraction`, 'info');
  };

  const handleDeleteVideo = (id: string) => {
    setVideos((prev) => prev.filter((v) => v.id !== id));
    showToast('Video removed from device list', 'info');
  };

  const handleAddCustomVideo = (newVideo: VideoItem) => {
    setVideos((prev) => [newVideo, ...prev]);
    showToast(`Imported "${newVideo.title}" into library!`, 'success');
  };

  const handleRefreshLibrary = () => {
    showToast('Rescanning device directories (/DCIM, /Movies, /Download)...', 'info');
    setTimeout(() => {
      showToast(`Scan complete! ${videos.length} videos verified.`, 'success');
    }, 600);
  };

  return (
    <PhoneFrame onOpenCodeExplorer={() => setShowCodeExplorer(true)}>
      {/* Toast Notifications */}
      <Toast toasts={toasts} onDismiss={dismissToast} />

      {/* Code Explorer Modal */}
      {showCodeExplorer && (
        <CodeExplorerModal
          onClose={() => setShowCodeExplorer(false)}
          onShowToast={showToast}
        />
      )}

      {/* Screen Routing */}
      {appStage === 'splash' && <SplashScreen onFinish={handleFinishSplash} />}

      {appStage === 'onboarding' && (
        <OnboardingScreen onComplete={handleCompleteOnboarding} />
      )}

      {appStage === 'main' && (
        <div className="w-full h-full flex flex-col relative overflow-hidden bg-slate-950">
          {/* Active Video Player Screen Overlay */}
          {activePlayingVideo ? (
            <CustomVideoPlayer
              video={activePlayingVideo}
              onClose={handleClosePlayer}
              onMoveToVault={handleMoveToVault}
            />
          ) : (
            <>
              {/* Main Tab Screen Content */}
              <div className="flex-1 flex flex-col overflow-hidden">
                {activeTab === 'videos' && (
                  <HomeScreen
                    videos={videos}
                    onPlayVideo={handlePlayVideo}
                    onMoveToVault={handleMoveToVault}
                    onConvertToMp3={handleConvertToMp3}
                    onDeleteVideo={handleDeleteVideo}
                    onAddCustomVideo={handleAddCustomVideo}
                    onRefreshLibrary={handleRefreshLibrary}
                  />
                )}

                {activeTab === 'vault' && (
                  <VaultScreen
                    vaultVideos={vaultVideos}
                    allVideos={videos}
                    onPlayVideo={handlePlayVideo}
                    onHideVideo={handleMoveToVault}
                    onUnhideVideo={handleUnhideVideo}
                    onShowToast={showToast}
                  />
                )}

                {activeTab === 'tools' && (
                  <ToolsScreen videos={videos} onShowToast={showToast} />
                )}

                {activeTab === 'settings' && (
                  <SettingsScreen
                    videos={videos}
                    vaultVideos={vaultVideos}
                    themeMode={themeMode}
                    onToggleTheme={() =>
                      setThemeMode((prev) => (prev === 'dark' ? 'light' : 'dark'))
                    }
                    onOpenCodeExplorer={() => setShowCodeExplorer(true)}
                    onShowToast={showToast}
                  />
                )}
              </div>

              {/* Material 3 Bottom Navigation Tab Bar */}
              <BottomTabBar
                activeTab={activeTab}
                onTabChange={setActiveTab}
                vaultCount={vaultVideos.length}
              />
            </>
          )}
        </div>
      )}
    </PhoneFrame>
  );
}
