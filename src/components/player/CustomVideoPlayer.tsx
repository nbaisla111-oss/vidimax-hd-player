import React, { useState, useRef, useEffect } from 'react';
import {
  Play,
  Pause,
  RotateCcw,
  RotateCw,
  Sun,
  Volume2,
  VolumeX,
  Lock,
  Unlock,
  Maximize2,
  Minimize2,
  ArrowLeft,
  Settings as SettingsIcon,
  PictureInPicture,
  Ratio,
} from 'lucide-react';
import { VideoItem } from '../../types';
import { formatDuration } from '../../data/mockVideos';

interface CustomVideoPlayerProps {
  video: VideoItem;
  onClose: () => void;
  onMoveToVault?: (video: VideoItem) => void;
}

export const CustomVideoPlayer: React.FC<CustomVideoPlayerProps> = ({
  video,
  onClose,
}) => {
  const videoRef = useRef<HTMLVideoElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);

  const [isPlaying, setIsPlaying] = useState(true);
  const [currentTime, setCurrentTime] = useState(0);
  const [duration, setDuration] = useState(video.duration || 120);
  const [volume, setVolume] = useState(1);
  const [isMuted, setIsMuted] = useState(false);
  const [brightness, setBrightness] = useState(1);
  const [isLocked, setIsLocked] = useState(false);
  const [aspectRatio, setAspectRatio] = useState<'fit' | 'fill' | 'stretch' | '16-9'>('fit');
  const [playbackSpeed, setPlaybackSpeed] = useState(1);
  const [showControls, setShowControls] = useState(true);
  const [isFullscreen, setIsFullscreen] = useState(false);
  const [showSpeedMenu, setShowSpeedMenu] = useState(false);

  // Gesture indicators
  const [gestureFeedback, setGestureFeedback] = useState<{
    type: 'brightness' | 'volume' | 'seek-forward' | 'seek-backward' | null;
    value?: string | number;
  }>({ type: null });

  const controlsTimeoutRef = useRef<NodeJS.Timeout | null>(null);

  const resetControlsTimeout = () => {
    if (controlsTimeoutRef.current) clearTimeout(controlsTimeoutRef.current);
    if (!isLocked && isPlaying) {
      controlsTimeoutRef.current = setTimeout(() => {
        setShowControls(false);
        setShowSpeedMenu(false);
      }, 3500);
    }
  };

  useEffect(() => {
    resetControlsTimeout();
    return () => {
      if (controlsTimeoutRef.current) clearTimeout(controlsTimeoutRef.current);
    };
  }, [isPlaying, isLocked]);

  // Video event handlers
  const handleTimeUpdate = () => {
    if (videoRef.current) {
      setCurrentTime(videoRef.current.currentTime);
      if (!isNaN(videoRef.current.duration) && videoRef.current.duration > 0) {
        setDuration(videoRef.current.duration);
      }
    }
  };

  const togglePlay = () => {
    if (!videoRef.current) return;
    if (isPlaying) {
      videoRef.current.pause();
      setIsPlaying(false);
      setShowControls(true);
    } else {
      videoRef.current.play();
      setIsPlaying(true);
      resetControlsTimeout();
    }
  };

  const skipSeconds = (seconds: number) => {
    if (!videoRef.current) return;
    const newTime = Math.min(Math.max(videoRef.current.currentTime + seconds, 0), duration);
    videoRef.current.currentTime = newTime;
    setCurrentTime(newTime);

    setGestureFeedback({
      type: seconds > 0 ? 'seek-forward' : 'seek-backward',
      value: `${Math.abs(seconds)}s`,
    });
    setTimeout(() => setGestureFeedback({ type: null }), 800);
    resetControlsTimeout();
  };

  const handleSeek = (e: React.ChangeEvent<HTMLInputElement>) => {
    const time = parseFloat(e.target.value);
    setCurrentTime(time);
    if (videoRef.current) {
      videoRef.current.currentTime = time;
    }
    resetControlsTimeout();
  };

  const handleVolumeChange = (newVol: number) => {
    const clamped = Math.max(0, Math.min(1, newVol));
    setVolume(clamped);
    if (videoRef.current) {
      videoRef.current.volume = clamped;
      videoRef.current.muted = clamped === 0;
    }
    setIsMuted(clamped === 0);
    setGestureFeedback({ type: 'volume', value: Math.round(clamped * 100) });
    setTimeout(() => setGestureFeedback({ type: null }), 1000);
  };

  const handleBrightnessChange = (newBri: number) => {
    const clamped = Math.max(0.2, Math.min(1.8, newBri));
    setBrightness(clamped);
    setGestureFeedback({ type: 'brightness', value: Math.round(clamped * 100) });
    setTimeout(() => setGestureFeedback({ type: null }), 1000);
  };

  const toggleMute = () => {
    if (!videoRef.current) return;
    if (isMuted) {
      videoRef.current.muted = false;
      setIsMuted(false);
      videoRef.current.volume = volume || 0.5;
    } else {
      videoRef.current.muted = true;
      setIsMuted(true);
    }
  };

  const toggleFullscreen = () => {
    if (!containerRef.current) return;
    if (!document.fullscreenElement) {
      containerRef.current.requestFullscreen().catch(() => {});
      setIsFullscreen(true);
    } else {
      document.exitFullscreen().catch(() => {});
      setIsFullscreen(false);
    }
  };

  const togglePiP = async () => {
    if (!videoRef.current) return;
    try {
      if (document.pictureInPictureElement) {
        await document.exitPictureInPicture();
      } else if (document.pictureInPictureEnabled) {
        await videoRef.current.requestPictureInPicture();
      }
    } catch (err) {
      console.warn('PiP not available:', err);
    }
  };

  const cycleAspectRatio = () => {
    const modes: ('fit' | 'fill' | 'stretch' | '16-9')[] = ['fit', 'fill', 'stretch', '16-9'];
    const nextIdx = (modes.indexOf(aspectRatio) + 1) % modes.length;
    setAspectRatio(modes[nextIdx]);
    resetControlsTimeout();
  };

  const changeSpeed = (speed: number) => {
    setPlaybackSpeed(speed);
    if (videoRef.current) {
      videoRef.current.playbackRate = speed;
    }
    setShowSpeedMenu(false);
    resetControlsTimeout();
  };

  // Vertical Touch / Mouse Drag Simulation for Brightness & Volume
  const dragStartRef = useRef<{ x: number; y: number; initialVal: number; side: 'left' | 'right' } | null>(null);

  const handlePointerDown = (e: React.PointerEvent) => {
    if (isLocked) return;
    const rect = containerRef.current?.getBoundingClientRect();
    if (!rect) return;
    const x = e.clientX - rect.left;
    const isLeft = x < rect.width / 2;

    dragStartRef.current = {
      x: e.clientX,
      y: e.clientY,
      initialVal: isLeft ? brightness : volume,
      side: isLeft ? 'left' : 'right',
    };
  };

  const handlePointerMove = (e: React.PointerEvent) => {
    if (!dragStartRef.current || isLocked) return;
    const deltaY = dragStartRef.current.y - e.clientY;
    const sensitivity = 0.005;

    if (dragStartRef.current.side === 'left') {
      handleBrightnessChange(dragStartRef.current.initialVal + deltaY * sensitivity);
    } else {
      handleVolumeChange(dragStartRef.current.initialVal + deltaY * sensitivity);
    }
  };

  const handlePointerUp = () => {
    dragStartRef.current = null;
  };

  // Aspect ratio class helper
  const getObjectFitClass = () => {
    switch (aspectRatio) {
      case 'fill':
        return 'object-cover w-full h-full';
      case 'stretch':
        return 'object-fill w-full h-full';
      case '16-9':
        return 'aspect-video w-full h-auto object-contain';
      case 'fit':
      default:
        return 'object-contain w-full h-full';
    }
  };

  return (
    <div
      ref={containerRef}
      onMouseMove={() => {
        if (!isLocked) setShowControls(true);
        resetControlsTimeout();
      }}
      onPointerDown={handlePointerDown}
      onPointerMove={handlePointerMove}
      onPointerUp={handlePointerUp}
      className="relative w-full h-full min-h-[500px] bg-black flex items-center justify-center overflow-hidden select-none"
    >
      {/* Video Element with Brightness Filter */}
      <video
        ref={videoRef}
        src={video.videoUrl}
        poster={video.thumbnailUrl}
        autoPlay
        playsInline
        onTimeUpdate={handleTimeUpdate}
        onEnded={() => setIsPlaying(false)}
        style={{ filter: `brightness(${brightness})` }}
        className={`transition-all duration-150 ${getObjectFitClass()}`}
      />

      {/* Screen Lock Overlay Indicator (Only button visible when locked) */}
      {isLocked && (
        <div className="absolute top-6 left-6 z-40">
          <button
            onClick={() => {
              setIsLocked(false);
              setShowControls(true);
            }}
            className="flex items-center gap-2 px-3 py-2 rounded-xl bg-violet-600/90 text-white text-xs font-bold shadow-lg shadow-violet-900/40 backdrop-blur-md active:scale-95 transition-all"
          >
            <Lock className="w-4 h-4 text-amber-300" />
            <span>Tap to Unlock Screen</span>
          </button>
        </div>
      )}

      {/* Center Gesture Feedback HUD (Brightness, Volume, Skip) */}
      {gestureFeedback.type && (
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 z-30 pointer-events-none animate-in fade-in zoom-in-95 duration-150">
          <div className="flex flex-col items-center justify-center p-4 rounded-2xl bg-slate-900/85 border border-slate-700/80 backdrop-blur-md text-white min-w-28 shadow-2xl">
            {gestureFeedback.type === 'brightness' && (
              <>
                <Sun className="w-7 h-7 text-amber-400 mb-2" />
                <span className="text-xs font-semibold text-slate-300">Brightness</span>
                <span className="text-base font-extrabold font-mono">{gestureFeedback.value}%</span>
              </>
            )}
            {gestureFeedback.type === 'volume' && (
              <>
                {volume === 0 ? (
                  <VolumeX className="w-7 h-7 text-rose-400 mb-2" />
                ) : (
                  <Volume2 className="w-7 h-7 text-cyan-400 mb-2" />
                )}
                <span className="text-xs font-semibold text-slate-300">Volume</span>
                <span className="text-base font-extrabold font-mono">{gestureFeedback.value}%</span>
              </>
            )}
            {gestureFeedback.type === 'seek-forward' && (
              <>
                <RotateCw className="w-7 h-7 text-emerald-400 mb-2" />
                <span className="text-sm font-bold text-emerald-400">+{gestureFeedback.value}</span>
              </>
            )}
            {gestureFeedback.type === 'seek-backward' && (
              <>
                <RotateCcw className="w-7 h-7 text-amber-400 mb-2" />
                <span className="text-sm font-bold text-amber-400">-{gestureFeedback.value}</span>
              </>
            )}
          </div>
        </div>
      )}

      {/* Main Touch & Tap Layer (Toggles controls or double-tap skip) */}
      <div
        onClick={() => {
          if (!isLocked) setShowControls(!showControls);
        }}
        onDoubleClick={(e) => {
          if (isLocked) return;
          const rect = containerRef.current?.getBoundingClientRect();
          if (!rect) return;
          if (e.clientX < rect.left + rect.width / 2) {
            skipSeconds(-10);
          } else {
            skipSeconds(10);
          }
        }}
        className="absolute inset-0 z-10"
      />

      {/* Custom Control Panels (Top Bar & Bottom Bar) */}
      {!isLocked && showControls && (
        <div className="absolute inset-0 z-20 flex flex-col justify-between p-4 pointer-events-none bg-gradient-to-b from-black/80 via-transparent to-black/85 transition-opacity duration-200">
          {/* Top Bar */}
          <div className="flex items-center justify-between gap-3 pointer-events-auto">
            <div className="flex items-center gap-2 min-w-0">
              <button
                onClick={onClose}
                className="p-2 rounded-xl bg-slate-900/60 hover:bg-slate-800 text-white transition-colors"
                title="Back to library"
              >
                <ArrowLeft className="w-5 h-5" />
              </button>
              <div className="truncate">
                <h3 className="text-sm font-bold text-white truncate max-w-[220px] sm:max-w-md">
                  {video.title}
                </h3>
                <p className="text-[10px] text-slate-300 font-medium">
                  {video.resolution} · {video.folder}
                </p>
              </div>
            </div>

            {/* Quick Actions Right */}
            <div className="flex items-center gap-1.5 shrink-0">
              {/* Aspect Ratio Button */}
              <button
                onClick={cycleAspectRatio}
                className="flex items-center gap-1 px-2.5 py-1.5 rounded-lg bg-slate-900/70 hover:bg-slate-800 text-xs font-semibold text-slate-200 border border-slate-700/60 transition-colors"
                title={`Aspect ratio: ${aspectRatio.toUpperCase()}`}
              >
                <Ratio className="w-3.5 h-3.5 text-cyan-400" />
                <span className="uppercase text-[10px]">{aspectRatio}</span>
              </button>

              {/* Playback Speed Menu Button */}
              <div className="relative">
                <button
                  onClick={() => setShowSpeedMenu(!showSpeedMenu)}
                  className="px-2 py-1.5 rounded-lg bg-slate-900/70 hover:bg-slate-800 text-xs font-bold text-slate-200 border border-slate-700/60 transition-colors"
                  title="Playback speed"
                >
                  {playbackSpeed}x
                </button>
                {showSpeedMenu && (
                  <div className="absolute right-0 top-9 w-28 bg-slate-900/95 border border-slate-700 rounded-xl shadow-2xl p-1 z-30 flex flex-col">
                    {[0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((s) => (
                      <button
                        key={s}
                        onClick={() => changeSpeed(s)}
                        className={`text-left text-xs px-2.5 py-1.5 rounded-md font-medium transition-colors ${
                          playbackSpeed === s
                            ? 'bg-violet-600 text-white font-bold'
                            : 'text-slate-300 hover:bg-slate-800'
                        }`}
                      >
                        {s}x Normal
                      </button>
                    ))}
                  </div>
                )}
              </div>

              {/* PiP Button */}
              <button
                onClick={togglePiP}
                className="p-1.5 rounded-lg bg-slate-900/70 hover:bg-slate-800 text-slate-200 border border-slate-700/60 transition-colors hidden sm:flex"
                title="Picture in Picture"
              >
                <PictureInPicture className="w-4 h-4" />
              </button>

              {/* Screen Lock Button */}
              <button
                onClick={() => {
                  setIsLocked(true);
                  setShowControls(false);
                }}
                className="p-1.5 rounded-lg bg-slate-900/70 hover:bg-slate-800 text-amber-300 border border-slate-700/60 transition-colors"
                title="Lock controls"
              >
                <Unlock className="w-4 h-4" />
              </button>
            </div>
          </div>

          {/* Center Playback Controls */}
          <div className="flex items-center justify-center gap-8 pointer-events-auto my-auto">
            <button
              onClick={() => skipSeconds(-10)}
              className="p-3 rounded-full bg-slate-900/60 hover:bg-slate-800/80 text-white active:scale-90 transition-all"
              title="Backward 10 seconds"
            >
              <RotateCcw className="w-6 h-6" />
            </button>

            <button
              onClick={togglePlay}
              className="w-16 h-16 rounded-full bg-violet-600 hover:bg-violet-500 text-white flex items-center justify-center shadow-xl shadow-violet-600/40 active:scale-95 transition-all"
              title={isPlaying ? 'Pause' : 'Play'}
            >
              {isPlaying ? (
                <Pause className="w-8 h-8 fill-white" />
              ) : (
                <Play className="w-8 h-8 fill-white translate-x-0.5" />
              )}
            </button>

            <button
              onClick={() => skipSeconds(10)}
              className="p-3 rounded-full bg-slate-900/60 hover:bg-slate-800/80 text-white active:scale-90 transition-all"
              title="Forward 10 seconds"
            >
              <RotateCw className="w-6 h-6" />
            </button>
          </div>

          {/* Bottom Bar: Seek Slider, Timestamps & Controls */}
          <div className="flex flex-col gap-2 pointer-events-auto">
            {/* Seek Slider with progress indicator */}
            <div className="flex items-center gap-3">
              <span className="text-[11px] font-mono font-medium text-slate-300 shrink-0">
                {formatDuration(currentTime)}
              </span>

              <div className="relative flex-1 flex items-center">
                <input
                  type="range"
                  min={0}
                  max={duration || 100}
                  step={0.1}
                  value={currentTime}
                  onChange={handleSeek}
                  className="w-full h-1.5 bg-slate-700/80 rounded-lg appearance-none cursor-pointer accent-violet-500 hover:h-2 transition-all"
                />
              </div>

              <span className="text-[11px] font-mono font-medium text-slate-400 shrink-0">
                {formatDuration(duration)}
              </span>
            </div>

            {/* Bottom Row controls */}
            <div className="flex items-center justify-between pt-1">
              {/* Volume & Brightness sliders */}
              <div className="flex items-center gap-4">
                {/* Volume icon & mini slider */}
                <div className="flex items-center gap-1.5">
                  <button onClick={toggleMute} className="text-slate-300 hover:text-white p-1">
                    {isMuted || volume === 0 ? (
                      <VolumeX className="w-4 h-4 text-rose-400" />
                    ) : (
                      <Volume2 className="w-4 h-4 text-cyan-400" />
                    )}
                  </button>
                  <input
                    type="range"
                    min={0}
                    max={1}
                    step={0.05}
                    value={isMuted ? 0 : volume}
                    onChange={(e) => handleVolumeChange(parseFloat(e.target.value))}
                    className="w-16 h-1 bg-slate-700 rounded-lg appearance-none cursor-pointer accent-cyan-400"
                    title="Volume"
                  />
                </div>

                {/* Brightness icon & mini slider */}
                <div className="hidden sm:flex items-center gap-1.5">
                  <Sun className="w-4 h-4 text-amber-400" />
                  <input
                    type="range"
                    min={0.2}
                    max={1.8}
                    step={0.05}
                    value={brightness}
                    onChange={(e) => handleBrightnessChange(parseFloat(e.target.value))}
                    className="w-16 h-1 bg-slate-700 rounded-lg appearance-none cursor-pointer accent-amber-400"
                    title="Brightness"
                  />
                </div>
              </div>

              {/* Fullscreen Button */}
              <div className="flex items-center gap-2">
                <button
                  onClick={toggleFullscreen}
                  className="p-1.5 rounded-lg text-slate-300 hover:text-white transition-colors"
                  title="Toggle Fullscreen"
                >
                  {isFullscreen ? (
                    <Minimize2 className="w-4 h-4" />
                  ) : (
                    <Maximize2 className="w-4 h-4" />
                  )}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
