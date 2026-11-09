import React, { useState, useMemo, useRef } from 'react';
import {
  Search,
  Folder,
  ArrowUpDown,
  MoreVertical,
  Play,
  Lock,
  Music,
  Info,
  Trash2,
  Upload,
  RefreshCw,
  FolderOpen,
  X,
  FileVideo,
} from 'lucide-react';
import { VideoItem, FolderItem, VideoFilter, SortOption } from '../../types';
import { formatDuration, formatFileSize } from '../../data/mockVideos';

interface HomeScreenProps {
  videos: VideoItem[];
  onPlayVideo: (video: VideoItem) => void;
  onMoveToVault: (video: VideoItem) => void;
  onConvertToMp3: (video: VideoItem) => void;
  onDeleteVideo: (id: string) => void;
  onAddCustomVideo: (video: VideoItem) => void;
  onRefreshLibrary: () => void;
}

export const HomeScreen: React.FC<HomeScreenProps> = ({
  videos,
  onPlayVideo,
  onMoveToVault,
  onConvertToMp3,
  onDeleteVideo,
  onAddCustomVideo,
  onRefreshLibrary,
}) => {
  const [filterMode, setFilterMode] = useState<VideoFilter>('all');
  const [activeFolder, setActiveFolder] = useState<string | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [sortOption, setSortOption] = useState<SortOption>('date_desc');
  const [selectedVideoInfo, setSelectedVideoInfo] = useState<VideoItem | null>(null);
  const [activeMenuId, setActiveMenuId] = useState<string | null>(null);

  const fileInputRef = useRef<HTMLInputElement>(null);

  // Derive folders list from videos
  const folders = useMemo(() => {
    const map = new Map<string, { count: number; totalSize: number; sampleThumb: string }>();

    videos.forEach((v) => {
      const existing = map.get(v.folder) || { count: 0, totalSize: 0, sampleThumb: v.thumbnailUrl };
      map.set(v.folder, {
        count: existing.count + 1,
        totalSize: existing.totalSize + v.size,
        sampleThumb: existing.sampleThumb || v.thumbnailUrl,
      });
    });

    const result: FolderItem[] = [];
    map.forEach((val, name) => {
      result.push({
        name,
        path: `/storage/emulated/0/${name}`,
        videoCount: val.count,
        totalSize: val.totalSize,
        thumbnailUrl: val.sampleThumb,
      });
    });

    return result.sort((a, b) => b.videoCount - a.videoCount);
  }, [videos]);

  // Filtered and sorted videos
  const filteredVideos = useMemo(() => {
    let result = [...videos];

    if (activeFolder) {
      result = result.filter((v) => v.folder === activeFolder);
    }

    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      result = result.filter(
        (v) => v.title.toLowerCase().includes(q) || v.folder.toLowerCase().includes(q)
      );
    }

    switch (sortOption) {
      case 'date_desc':
        result.sort((a, b) => b.dateAdded - a.dateAdded);
        break;
      case 'date_asc':
        result.sort((a, b) => a.dateAdded - b.dateAdded);
        break;
      case 'name_asc':
        result.sort((a, b) => a.title.localeCompare(b.title));
        break;
      case 'size_desc':
        result.sort((a, b) => b.size - a.size);
        break;
      case 'duration_desc':
        result.sort((a, b) => b.duration - a.duration);
        break;
    }

    return result;
  }, [videos, activeFolder, searchQuery, sortOption]);

  // Handle local video file upload / import from PC/Phone
  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const videoUrl = URL.createObjectURL(file);
    const tempVideo = document.createElement('video');
    tempVideo.preload = 'metadata';
    tempVideo.src = videoUrl;

    tempVideo.onloadedmetadata = () => {
      // Generate Canvas Thumbnail
      tempVideo.currentTime = Math.min(1.0, tempVideo.duration / 2);
      tempVideo.onseeked = () => {
        const canvas = document.createElement('canvas');
        canvas.width = 320;
        canvas.height = 180;
        const ctx = canvas.getContext('2d');
        let thumbUrl = 'https://images.unsplash.com/photo-1536240478700-b869070f9279?w=600&auto=format&fit=crop&q=80';
        if (ctx) {
          ctx.drawImage(tempVideo, 0, 0, canvas.width, canvas.height);
          thumbUrl = canvas.toDataURL('image/jpeg', 0.7);
        }

        const newVideoItem: VideoItem = {
          id: `custom-${Date.now()}`,
          title: file.name.replace(/\.[^/.]+$/, ''),
          fileName: file.name,
          filePath: `/storage/emulated/0/Download/${file.name}`,
          folder: 'Downloads',
          duration: Math.round(tempVideo.duration) || 60,
          size: file.size,
          resolution: `${tempVideo.videoWidth || 1920}x${tempVideo.videoHeight || 1080}`,
          dateAdded: Date.now(),
          thumbnailUrl: thumbUrl,
          videoUrl: videoUrl,
          fileBlob: file,
        };

        onAddCustomVideo(newVideoItem);
      };
    };

    // Reset input
    e.target.value = '';
  };

  return (
    <div className="flex-1 flex flex-col h-full bg-slate-950 text-slate-100 overflow-hidden">
      {/* Hidden file input for picking local device videos */}
      <input
        type="file"
        ref={fileInputRef}
        onChange={handleFileChange}
        accept="video/*"
        className="hidden"
      />

      {/* Top Search & Filter Bar */}
      <div className="p-4 bg-slate-950/80 backdrop-blur-md border-b border-slate-800/80 shrink-0">
        <div className="flex items-center gap-2 mb-3">
          <div className="relative flex-1">
            <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              placeholder="Search offline videos..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-9 pr-8 py-2 rounded-xl bg-slate-900 border border-slate-800 text-xs text-white placeholder-slate-400 focus:outline-none focus:border-violet-500 transition-colors"
            />
            {searchQuery && (
              <button
                onClick={() => setSearchQuery('')}
                className="absolute right-2.5 top-1/2 -translate-y-1/2 text-slate-400 hover:text-white"
              >
                <X className="w-3.5 h-3.5" />
              </button>
            )}
          </div>

          {/* Import / Scan Device Video Button */}
          <button
            onClick={() => fileInputRef.current?.click()}
            className="flex items-center gap-1.5 px-3 py-2 rounded-xl bg-violet-600 hover:bg-violet-500 text-white text-xs font-semibold shadow-md shadow-violet-700/20 active:scale-95 transition-all shrink-0"
            title="Import video from your device storage"
          >
            <Upload className="w-3.5 h-3.5" />
            <span className="hidden sm:inline">Import Video</span>
          </button>

          {/* Refresh Scan Button */}
          <button
            onClick={onRefreshLibrary}
            className="p-2 rounded-xl bg-slate-900 hover:bg-slate-800 border border-slate-800 text-slate-300 hover:text-white transition-colors"
            title="Rescan device storage"
          >
            <RefreshCw className="w-4 h-4" />
          </button>
        </div>

        {/* View Segmented Tabs & Sort Selector */}
        <div className="flex items-center justify-between gap-2">
          {/* Tabs: All Videos vs Folders */}
          <div className="flex items-center p-1 bg-slate-900 rounded-xl border border-slate-800/80">
            <button
              onClick={() => {
                setFilterMode('all');
                setActiveFolder(null);
              }}
              className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-all ${
                filterMode === 'all' && !activeFolder
                  ? 'bg-violet-600 text-white shadow-sm'
                  : 'text-slate-400 hover:text-white'
              }`}
            >
              All Videos ({videos.length})
            </button>
            <button
              onClick={() => {
                setFilterMode('folders');
                setActiveFolder(null);
              }}
              className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-all ${
                filterMode === 'folders' || activeFolder
                  ? 'bg-violet-600 text-white shadow-sm'
                  : 'text-slate-400 hover:text-white'
              }`}
            >
              Folders ({folders.length})
            </button>
          </div>

          {/* Sort Selector Dropdown */}
          <div className="flex items-center gap-1.5 text-xs text-slate-400">
            <ArrowUpDown className="w-3.5 h-3.5 text-slate-400" />
            <select
              value={sortOption}
              onChange={(e) => setSortOption(e.target.value as SortOption)}
              className="bg-slate-900 border border-slate-800 text-slate-300 text-xs rounded-lg px-2 py-1.5 focus:outline-none focus:border-violet-500 cursor-pointer"
            >
              <option value="date_desc">Newest First</option>
              <option value="date_asc">Oldest First</option>
              <option value="name_asc">Name (A-Z)</option>
              <option value="size_desc">Largest Size</option>
              <option value="duration_desc">Longest Duration</option>
            </select>
          </div>
        </div>

        {/* Active Folder Breadcrumb Filter */}
        {activeFolder && (
          <div className="flex items-center gap-2 mt-2 pt-2 border-t border-slate-900">
            <FolderOpen className="w-4 h-4 text-violet-400" />
            <span className="text-xs font-semibold text-violet-300 truncate">
              Folder: {activeFolder}
            </span>
            <button
              onClick={() => setActiveFolder(null)}
              className="ml-auto text-[11px] text-slate-400 hover:text-white underline cursor-pointer"
            >
              Show all folders
            </button>
          </div>
        )}
      </div>

      {/* Main Content Area: Folders View OR Videos View */}
      <div className="flex-1 overflow-y-auto p-4 space-y-3">
        {filterMode === 'folders' && !activeFolder ? (
          /* Folders Grid */
          <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
            {folders.map((folder) => (
              <div
                key={folder.name}
                onClick={() => {
                  setActiveFolder(folder.name);
                  setFilterMode('all');
                }}
                className="group p-3.5 rounded-2xl bg-slate-900/70 hover:bg-slate-900 border border-slate-800/80 hover:border-violet-500/40 cursor-pointer transition-all duration-200 flex flex-col justify-between"
              >
                <div className="flex items-center justify-between mb-3">
                  <div className="w-10 h-10 rounded-xl bg-violet-600/15 border border-violet-500/20 flex items-center justify-center text-violet-400 group-hover:scale-105 transition-transform">
                    <Folder className="w-5 h-5 fill-violet-400/20" />
                  </div>
                  <span className="text-[10px] font-bold text-slate-400 px-2 py-0.5 rounded-md bg-slate-800">
                    {folder.videoCount}
                  </span>
                </div>

                <div>
                  <h4 className="text-xs font-bold text-white truncate mb-1 group-hover:text-violet-300 transition-colors">
                    {folder.name}
                  </h4>
                  <p className="text-[10px] text-slate-400 font-medium">
                    {formatFileSize(folder.totalSize)}
                  </p>
                </div>
              </div>
            ))}
          </div>
        ) : (
          /* Videos List */
          <div className="space-y-2.5">
            {filteredVideos.length === 0 ? (
              <div className="flex flex-col items-center justify-center py-16 text-center text-slate-400">
                <FileVideo className="w-12 h-12 text-slate-600 mb-3 stroke-1" />
                <h4 className="text-sm font-bold text-slate-300 mb-1">No videos found</h4>
                <p className="text-xs text-slate-500 max-w-xs mb-4">
                  No video files match your filter or search query. You can import any offline video.
                </p>
                <button
                  onClick={() => fileInputRef.current?.click()}
                  className="px-4 py-2 rounded-xl bg-violet-600 text-white text-xs font-bold shadow-md hover:bg-violet-500 transition-colors"
                >
                  Import Video File
                </button>
              </div>
            ) : (
              filteredVideos.map((video) => (
                <div
                  key={video.id}
                  className="group relative flex items-center gap-3 p-2.5 rounded-2xl bg-slate-900/60 hover:bg-slate-900 border border-slate-800/70 hover:border-slate-700/80 transition-all duration-150"
                >
                  {/* Thumbnail with duration badge and play hover */}
                  <div
                    onClick={() => onPlayVideo(video)}
                    className="relative w-28 h-18 sm:w-32 sm:h-20 rounded-xl overflow-hidden bg-slate-800 shrink-0 cursor-pointer shadow-md"
                  >
                    <img
                      src={video.thumbnailUrl}
                      alt={video.title}
                      referrerPolicy="no-referrer"
                      className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                    />
                    <div className="absolute inset-0 bg-black/25 group-hover:bg-black/10 flex items-center justify-center transition-colors">
                      <div className="w-8 h-8 rounded-full bg-violet-600/90 text-white flex items-center justify-center shadow-lg opacity-90 group-hover:scale-110 transition-transform">
                        <Play className="w-4 h-4 fill-white translate-x-0.5" />
                      </div>
                    </div>
                    {/* Duration badge */}
                    <span className="absolute bottom-1 right-1 px-1.5 py-0.5 rounded bg-black/80 font-mono text-[10px] font-bold text-white tracking-tight">
                      {formatDuration(video.duration)}
                    </span>
                  </div>

                  {/* Video Details Column */}
                  <div
                    onClick={() => onPlayVideo(video)}
                    className="flex-1 min-w-0 cursor-pointer pr-1"
                  >
                    <h3 className="text-xs sm:text-sm font-bold text-slate-100 group-hover:text-violet-300 transition-colors truncate mb-1">
                      {video.title}
                    </h3>
                    <div className="flex flex-wrap items-center gap-1.5 text-[11px] text-slate-400">
                      <span>{formatFileSize(video.size)}</span>
                      <span aria-hidden="true">·</span>
                      <span className="text-violet-400 font-medium">{video.folder}</span>
                      <span aria-hidden="true">·</span>
                      <span className="text-slate-400 font-mono text-[10px]">{video.resolution}</span>
                    </div>
                  </div>

                  {/* Context Action Menu (3-dots) */}
                  <div className="relative shrink-0">
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        setActiveMenuId(activeMenuId === video.id ? null : video.id);
                      }}
                      className="p-2 rounded-xl text-slate-400 hover:text-white hover:bg-slate-800 transition-colors"
                      title="More options"
                    >
                      <MoreVertical className="w-4 h-4" />
                    </button>

                    {/* Dropdown Menu */}
                    {activeMenuId === video.id && (
                      <div
                        onClick={(e) => e.stopPropagation()}
                        className="absolute right-0 top-8 w-44 rounded-xl bg-slate-900 border border-slate-700 shadow-2xl p-1 z-30 animate-in fade-in zoom-in-95 duration-100 text-xs"
                      >
                        <button
                          onClick={() => {
                            setActiveMenuId(null);
                            onPlayVideo(video);
                          }}
                          className="w-full flex items-center gap-2.5 px-3 py-2 rounded-lg text-slate-200 hover:bg-slate-800 text-left font-medium"
                        >
                          <Play className="w-3.5 h-3.5 text-emerald-400" />
                          <span>Play Video</span>
                        </button>

                        <button
                          onClick={() => {
                            setActiveMenuId(null);
                            onMoveToVault(video);
                          }}
                          className="w-full flex items-center gap-2.5 px-3 py-2 rounded-lg text-violet-300 hover:bg-violet-950/40 text-left font-medium"
                        >
                          <Lock className="w-3.5 h-3.5 text-violet-400" />
                          <span>Hide in Vault</span>
                        </button>

                        <button
                          onClick={() => {
                            setActiveMenuId(null);
                            onConvertToMp3(video);
                          }}
                          className="w-full flex items-center gap-2.5 px-3 py-2 rounded-lg text-slate-200 hover:bg-slate-800 text-left font-medium"
                        >
                          <Music className="w-3.5 h-3.5 text-cyan-400" />
                          <span>Extract to MP3</span>
                        </button>

                        <button
                          onClick={() => {
                            setActiveMenuId(null);
                            setSelectedVideoInfo(video);
                          }}
                          className="w-full flex items-center gap-2.5 px-3 py-2 rounded-lg text-slate-200 hover:bg-slate-800 text-left font-medium"
                        >
                          <Info className="w-3.5 h-3.5 text-amber-400" />
                          <span>Video Properties</span>
                        </button>

                        <div className="h-px bg-slate-800 my-1" />

                        <button
                          onClick={() => {
                            setActiveMenuId(null);
                            onDeleteVideo(video.id);
                          }}
                          className="w-full flex items-center gap-2.5 px-3 py-2 rounded-lg text-rose-400 hover:bg-rose-950/30 text-left font-medium"
                        >
                          <Trash2 className="w-3.5 h-3.5" />
                          <span>Delete Video</span>
                        </button>
                      </div>
                    )}
                  </div>
                </div>
              ))
            )}
          </div>
        )}
      </div>

      {/* Video Properties Modal */}
      {selectedVideoInfo && (
        <div
          onClick={() => setSelectedVideoInfo(null)}
          className="fixed inset-0 bg-black/70 backdrop-blur-sm z-50 flex items-center justify-center p-4"
        >
          <div
            onClick={(e) => e.stopPropagation()}
            className="w-full max-w-md rounded-2xl bg-slate-900 border border-slate-700 p-5 shadow-2xl text-slate-100"
          >
            <div className="flex items-center justify-between pb-3 border-b border-slate-800 mb-4">
              <h3 className="text-sm font-bold text-white flex items-center gap-2">
                <Info className="w-4 h-4 text-violet-400" /> Video Details
              </h3>
              <button
                onClick={() => setSelectedVideoInfo(null)}
                className="p-1 rounded-lg text-slate-400 hover:text-white"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="space-y-3 text-xs">
              <div>
                <span className="text-slate-400 block mb-0.5">Title</span>
                <span className="font-semibold text-white break-words">
                  {selectedVideoInfo.title}
                </span>
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <span className="text-slate-400 block mb-0.5">Duration</span>
                  <span className="font-mono text-white">
                    {formatDuration(selectedVideoInfo.duration)}
                  </span>
                </div>
                <div>
                  <span className="text-slate-400 block mb-0.5">File Size</span>
                  <span className="font-mono text-white">
                    {formatFileSize(selectedVideoInfo.size)}
                  </span>
                </div>
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <span className="text-slate-400 block mb-0.5">Resolution</span>
                  <span className="text-white">{selectedVideoInfo.resolution}</span>
                </div>
                <div>
                  <span className="text-slate-400 block mb-0.5">Storage Folder</span>
                  <span className="text-white">{selectedVideoInfo.folder}</span>
                </div>
              </div>
              <div>
                <span className="text-slate-400 block mb-0.5">Local Storage Path</span>
                <span className="font-mono text-[11px] text-slate-300 break-all bg-slate-950 p-2 rounded-lg block">
                  {selectedVideoInfo.filePath}
                </span>
              </div>
            </div>

            <div className="mt-5 pt-3 border-t border-slate-800 flex justify-end">
              <button
                onClick={() => setSelectedVideoInfo(null)}
                className="px-4 py-2 rounded-xl bg-violet-600 hover:bg-violet-500 text-white text-xs font-bold transition-colors"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
