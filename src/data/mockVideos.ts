import { VideoItem, StatusItem } from '../types';

export const INITIAL_VIDEOS: VideoItem[] = [
  {
    id: 'vid-01',
    title: 'Cyberpunk Neon Metropolis 4K Night Flight',
    fileName: 'Cyberpunk_Metropolis_4K.mp4',
    filePath: '/storage/emulated/0/DCIM/Camera/Cyberpunk_Metropolis_4K.mp4',
    folder: 'Camera (DCIM)',
    duration: 124, // 2m 04s
    size: 98500000, // ~98.5 MB
    resolution: '3840x2160 (4K UHD)',
    fps: 60,
    dateAdded: Date.now() - 3600000 * 4,
    thumbnailUrl: 'https://images.unsplash.com/photo-1508739773434-c26b3d09e071?w=600&auto=format&fit=crop&q=80',
    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
  },
  {
    id: 'vid-02',
    title: 'Cosmic Nebula & Space Exploration Documentary',
    fileName: 'Cosmos_Nebula_Documentary_HDR.mp4',
    filePath: '/storage/emulated/0/Movies/Cosmos_Nebula_Documentary_HDR.mp4',
    folder: 'Movies',
    duration: 345, // 5m 45s
    size: 245000000, // ~245 MB
    resolution: '1920x1080 (1080p FHD)',
    fps: 30,
    dateAdded: Date.now() - 3600000 * 18,
    thumbnailUrl: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=600&auto=format&fit=crop&q=80',
    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
  },
  {
    id: 'vid-03',
    title: 'Sunset Coastline Aerial Drone 60FPS',
    fileName: 'Drone_Sunset_Goa_Coast.mp4',
    filePath: '/storage/emulated/0/DCIM/Camera/Drone_Sunset_Goa_Coast.mp4',
    folder: 'Camera (DCIM)',
    duration: 88, // 1m 28s
    size: 64200000,
    resolution: '1920x1080 (1080p FHD)',
    fps: 60,
    dateAdded: Date.now() - 3600000 * 36,
    thumbnailUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600&auto=format&fit=crop&q=80',
    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
  },
  {
    id: 'vid-04',
    title: 'Flutter Advanced Architecture Masterclass',
    fileName: 'Flutter_Clean_Architecture_Ep1.mp4',
    filePath: '/storage/emulated/0/Download/Flutter_Clean_Architecture_Ep1.mp4',
    folder: 'Downloads',
    duration: 612, // 10m 12s
    size: 420000000,
    resolution: '1920x1080 (1080p FHD)',
    fps: 30,
    dateAdded: Date.now() - 3600000 * 72,
    thumbnailUrl: 'https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=600&auto=format&fit=crop&q=80',
    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
  },
  {
    id: 'vid-05',
    title: 'WhatsApp Viral Stunt Video Clip',
    fileName: 'VID_20261108_WA0014.mp4',
    filePath: '/storage/emulated/0/WhatsApp/Media/WhatsApp Video/VID_20261108_WA0014.mp4',
    folder: 'WhatsApp Video',
    duration: 45, // 45s
    size: 14800000,
    resolution: '1280x720 (720p HD)',
    fps: 30,
    dateAdded: Date.now() - 3600000 * 2,
    thumbnailUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600&auto=format&fit=crop&q=80',
    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
  },
  {
    id: 'vid-06',
    title: 'Supercar Track Lap Mountain Pass',
    fileName: 'Supercar_Mountain_Pass_FullThrottle.mp4',
    filePath: '/storage/emulated/0/Movies/Supercar_Mountain_Pass_FullThrottle.mp4',
    folder: 'Movies',
    duration: 215, // 3m 35s
    size: 182000000,
    resolution: '3840x2160 (4K UHD)',
    fps: 60,
    dateAdded: Date.now() - 3600000 * 96,
    thumbnailUrl: 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=600&auto=format&fit=crop&q=80',
    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
  },
  {
    id: 'vid-07',
    title: 'Screen Recording - Mobile Game Win',
    fileName: 'Screen_20261107_193240.mp4',
    filePath: '/storage/emulated/0/Movies/Screen Recordings/Screen_20261107_193240.mp4',
    folder: 'Screen Recordings',
    duration: 178, // 2m 58s
    size: 89000000,
    resolution: '1080x2400 (FHD+)',
    fps: 60,
    dateAdded: Date.now() - 3600000 * 22,
    thumbnailUrl: 'https://images.unsplash.com/photo-1542751371-adc38448a05e?w=600&auto=format&fit=crop&q=80',
    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4',
  }
];

export const INITIAL_STATUSES: StatusItem[] = [
  {
    id: 'stat-01',
    type: 'video',
    source: 'whatsapp',
    title: 'Aman Sharma Status',
    url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyBlazes.mp4',
    thumbnailUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500&auto=format&fit=crop&q=80',
    date: '10 minutes ago',
    size: '4.2 MB',
    isSaved: false,
  },
  {
    id: 'stat-02',
    type: 'image',
    source: 'whatsapp',
    title: 'Priya Patel Status',
    url: 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=1080&auto=format&fit=crop&q=80',
    thumbnailUrl: 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=500&auto=format&fit=crop&q=80',
    date: '45 minutes ago',
    size: '1.8 MB',
    isSaved: false,
  },
  {
    id: 'stat-03',
    type: 'video',
    source: 'whatsapp',
    title: 'Rahul V. Travel Reels',
    url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4',
    thumbnailUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=500&auto=format&fit=crop&q=80',
    date: '2 hours ago',
    size: '6.8 MB',
    isSaved: false,
  },
  {
    id: 'stat-04',
    type: 'image',
    source: 'whatsapp_business',
    title: 'Style Studio Official Story',
    url: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=1080&auto=format&fit=crop&q=80',
    thumbnailUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=500&auto=format&fit=crop&q=80',
    date: '3 hours ago',
    size: '2.1 MB',
    isSaved: false,
  },
  {
    id: 'stat-05',
    type: 'image',
    source: 'whatsapp',
    title: 'Gym Workout Motivation',
    url: 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=1080&auto=format&fit=crop&q=80',
    thumbnailUrl: 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=500&auto=format&fit=crop&q=80',
    date: '5 hours ago',
    size: '1.4 MB',
    isSaved: true,
  },
  {
    id: 'stat-06',
    type: 'video',
    source: 'whatsapp_business',
    title: 'Coffee Roasters Special Offer',
    url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WhatCarCanYouGetForAGrand.mp4',
    thumbnailUrl: 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=500&auto=format&fit=crop&q=80',
    date: '7 hours ago',
    size: '3.9 MB',
    isSaved: false,
  }
];

export function formatDuration(seconds: number): string {
  if (isNaN(seconds) || seconds < 0) return '00:00';
  const hrs = Math.floor(seconds / 3600);
  const mins = Math.floor((seconds % 3600) / 60);
  const secs = Math.floor(seconds % 60);

  if (hrs > 0) {
    return `${hrs}:${mins < 10 ? '0' : ''}${mins}:${secs < 10 ? '0' : ''}${secs}`;
  }
  return `${mins < 10 ? '0' : ''}${mins}:${secs < 10 ? '0' : ''}${secs}`;
}

export function formatFileSize(bytes: number): string {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
}
