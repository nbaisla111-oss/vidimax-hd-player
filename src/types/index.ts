export interface VideoItem {
  id: string;
  title: string;
  fileName: string;
  filePath: string;
  folder: string;
  duration: number; // in seconds
  size: number; // in bytes
  resolution: string; // e.g. "1920x1080 (1080p FHD)"
  fps?: number;
  dateAdded: number; // timestamp
  thumbnailUrl: string;
  videoUrl: string;
  isVault?: boolean;
  fileBlob?: Blob;
  lastPlayedPosition?: number;
}

export interface FolderItem {
  name: string;
  path: string;
  videoCount: number;
  totalSize: number;
  thumbnailUrl: string;
}

export interface VaultSecret {
  pin: string;
  isConfigured: boolean;
  securityQuestion: string;
  securityAnswer: string;
}

export interface StatusItem {
  id: string;
  type: 'video' | 'image';
  source: 'whatsapp' | 'whatsapp_business';
  title: string;
  url: string;
  thumbnailUrl: string;
  date: string;
  size: string;
  isSaved: boolean;
}

export interface ConversionTask {
  id: string;
  videoTitle: string;
  videoUrl: string;
  status: 'idle' | 'converting' | 'completed' | 'failed';
  progress: number;
  bitrate: '128' | '192' | '320';
  audioBlobUrl?: string;
  audioDuration?: number;
  outputFileName?: string;
}

export type ActiveTab = 'videos' | 'vault' | 'tools' | 'settings';
export type VideoFilter = 'all' | 'folders';
export type SortOption = 'date_desc' | 'date_asc' | 'name_asc' | 'size_desc' | 'duration_desc';
