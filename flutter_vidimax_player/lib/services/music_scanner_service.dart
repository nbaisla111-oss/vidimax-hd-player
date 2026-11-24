import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/music_model.dart';
import 'system_controls_service.dart';

class MusicScannerService {
  static final MusicScannerService _instance = MusicScannerService._internal();
  factory MusicScannerService() => _instance;
  MusicScannerService._internal();

  static const String _cacheKey = 'rox_cached_music_v2';

  static final RegExp _whatsappAudioNameRegex = RegExp(
    r'^(aud|ptt)-?\d{6,8}-wa\d+',
    caseSensitive: false,
  );

  final List<String> supportedAudioExtensions = [
    '.mp3', '.m4a', '.wav', '.aac', '.flac', '.ogg', '.opus', '.wma'
  ];

  String _canonicalPathKey(String rawPath) {
    String resolved = rawPath;
    try {
      resolved = File(rawPath).resolveSymbolicLinksSync();
    } catch (_) {}
    String normalized = p.normalize(resolved).replaceAll('\\', '/').trim();
    final lower = normalized.toLowerCase();
    const prefixes = [
      '/sdcard/',
      '/mnt/sdcard/',
      '/storage/self/primary/',
      '/mnt/user/0/primary/',
    ];
    for (final prefix in prefixes) {
      if (lower.startsWith(prefix)) {
        normalized = '/storage/emulated/0/${normalized.substring(prefix.length)}';
        break;
      }
    }
    return normalized.toLowerCase();
  }

  bool _isExcludedAudioPath(String rawPath) {
    final lowerPath = _canonicalPathKey(rawPath);
    final fileName = p.basename(rawPath).toLowerCase();
    if (fileName.startsWith('.') ||
        fileName.startsWith('.trashed-') ||
        lowerPath.contains('/.') ||
        lowerPath.contains('/android/data/') ||
        lowerPath.contains('/android/obb/') ||
        lowerPath.contains('/notifications/') ||
        lowerPath.contains('/ringtones/') ||
        lowerPath.contains('/alarms/') ||
        lowerPath.contains('/ui/') ||
        lowerPath.contains('/whatsapp') ||
        lowerPath.contains('com.whatsapp') ||
        _whatsappAudioNameRegex.hasMatch(fileName) ||
        lowerPath.contains('/callrecordings') ||
        lowerPath.contains('/call recordings') ||
        lowerPath.contains('/call_rec') ||
        lowerPath.contains('/callrecord') ||
        lowerPath.contains('/voicemail')) {
      return true;
    }
    return false;
  }

  bool _hasNomediaAncestor(String filePath, Map<String, bool> cache) {
    String current = p.dirname(filePath);
    for (int depth = 0; depth < 10; depth++) {
      final lowerDir = current.toLowerCase();
      if (lowerDir.isEmpty ||
          lowerDir == '/' ||
          lowerDir == '/storage' ||
          lowerDir == '/storage/emulated/0') {
        break;
      }
      final cached = cache[current];
      if (cached != null) {
        if (cached) return true;
      } else {
        bool hasNomedia = false;
        try {
          hasNomedia = File(p.join(current, '.nomedia')).existsSync();
        } catch (_) {}
        cache[current] = hasNomedia;
        if (hasNomedia) return true;
      }
      final parent = p.dirname(current);
      if (parent == current) break;
      current = parent;
    }
    return false;
  }

  /// Load cached local audio tracks for instant 0ms launch
  Future<List<MusicModel>> getCachedMusic() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_cacheKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        final list = <MusicModel>[];
        final seenCanonical = <String>{};
        final seenSigs = <String>{};
        for (final item in decoded) {
          final path = item['path'] as String? ?? '';
          if (path.isEmpty || path.startsWith('http')) continue;
          if (_isExcludedAudioPath(path)) continue;
          if (!File(path).existsSync()) continue;
          final canonical = _canonicalPathKey(path);
          if (!seenCanonical.add(canonical)) continue;
          final size = (item['size'] as num?)?.toInt() ?? 0;
          final sig = '${p.basename(path).toLowerCase()}_$size';
          if (!seenSigs.add(sig)) continue;
          list.add(
            MusicModel(
              id: item['id'] ?? canonical.hashCode.toString(),
              title: item['title'] ?? '',
              artist: item['artist'] ?? 'Unknown Artist',
              album: item['album'] ?? '',
              path: path,
              size: size,
              duration: Duration(milliseconds: (item['durationMs'] as num?)?.toInt() ?? 0),
              folder: item['folder'] ?? 'Internal',
              dateAdded: DateTime.fromMillisecondsSinceEpoch(
                (item['dateAddedMs'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
              ),
            ),
          );
        }
        return list;
      }
    } catch (_) {}
    return [];
  }

  Future<void> _saveMusicToCache(List<MusicModel> tracks) async {
    try {
      final localOnly = tracks.where((t) => !t.path.startsWith('http') && !t.id.startsWith('sample_')).toList();
      final prefs = await SharedPreferences.getInstance();
      final mapped = localOnly.map((m) => {
        'id': m.id,
        'title': m.title,
        'artist': m.artist,
        'album': m.album,
        'path': m.path,
        'size': m.size,
        'durationMs': m.duration.inMilliseconds,
        'folder': m.folder,
        'dateAddedMs': m.dateAdded.millisecondsSinceEpoch,
      }).toList();
      await prefs.setString(_cacheKey, jsonEncode(mapped));
    } catch (_) {}
  }

  /// Complete scan of device audio via Android MediaStore + direct storage directories
  Future<List<MusicModel>> scanDeviceMusic({bool allowSampleFallback = false}) async {
    final List<MusicModel> musicList = [];
    final Set<String> seenCanonicalPaths = {};
    final Set<String> seenSignatures = {};
    final Map<String, bool> nomediaCache = {};
    final List<MusicModel> directOnlyTracks = [];

    // 1. Primary source on Android: query MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
    if (Platform.isAndroid) {
      final storeTracks = await SystemControlsService().queryAllDeviceAudio();
      for (final item in storeTracks) {
        final rawPath = item['path'] as String? ?? '';
        if (rawPath.isEmpty || _isExcludedAudioPath(rawPath)) continue;

        final canonicalKey = _canonicalPathKey(rawPath);
        if (!seenCanonicalPaths.add(canonicalKey)) continue;

        final size = (item['size'] as num?)?.toInt() ?? 0;
        final sig = '${p.basename(rawPath).toLowerCase()}_$size';
        if (!seenSignatures.add(sig)) continue;

        final folder = (item['folder'] as String?)?.trim();
        final safeFolder = (folder != null && folder.isNotEmpty) ? folder : 'Internal';
        final rawTitle = (item['title'] as String?)?.trim() ?? '';
        final safeTitle = rawTitle.isNotEmpty
            ? rawTitle
            : p.basenameWithoutExtension(rawPath).replaceAll(RegExp(r'[_-]'), ' ');
        final rawArtist = (item['artist'] as String?)?.trim() ?? '';
        final safeArtist = rawArtist.isNotEmpty ? rawArtist : safeFolder;
        final rawAlbum = (item['album'] as String?)?.trim() ?? '';
        final safeAlbum = rawAlbum.isNotEmpty ? rawAlbum : safeFolder;
        final durMs = (item['durationMs'] as num?)?.toInt() ?? 0;
        final dateAddedMs = (item['dateAddedMs'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch;

        musicList.add(
          MusicModel(
            id: canonicalKey.hashCode.toString(),
            title: safeTitle,
            artist: safeArtist,
            album: safeAlbum,
            path: rawPath,
            size: size,
            duration: Duration(milliseconds: durMs),
            folder: safeFolder,
            dateAdded: DateTime.fromMillisecondsSinceEpoch(dateAddedMs),
          ),
        );
      }
    }

    // 2. Supplement with direct directory scan to pick up freshly created/unindexed music files
    final targetDirs = [
      Directory('/storage/emulated/0/Music'),
      Directory('/storage/emulated/0/Download'),
      Directory('/storage/emulated/0/Quick Share'),
      Directory('/storage/emulated/0/Audio'),
      Directory('/storage/emulated/0/Podcasts'),
      Directory('/storage/emulated/0/Recordings'),
      Directory('/storage/emulated/0/Bluetooth'),
      Directory('/storage/emulated/0/Snaptube/download'),
      Directory('/storage/emulated/0/Vidmate/download'),
    ];

    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      targetDirs.add(appDocDir);
    } catch (_) {}

    for (final dir in targetDirs) {
      if (await dir.exists()) {
        try {
          await for (final entity in dir.list(recursive: true, followLinks: false)) {
            if (entity is File) {
              final ext = p.extension(entity.path).toLowerCase();
              if (!supportedAudioExtensions.contains(ext)) continue;
              if (_isExcludedAudioPath(entity.path)) continue;
              if (_hasNomediaAncestor(entity.path, nomediaCache)) continue;

              final canonicalKey = _canonicalPathKey(entity.path);
              if (seenCanonicalPaths.contains(canonicalKey)) continue;

              try {
                final stat = await entity.stat();
                if (stat.size < 8 * 1024) continue;

                final fileName = p.basename(entity.path);
                final sig = '${fileName.toLowerCase()}_${stat.size}';
                if (seenSignatures.contains(sig)) continue;

                seenCanonicalPaths.add(canonicalKey);
                seenSignatures.add(sig);

                final folderName = p.basename(p.dirname(entity.path));
                final title = p.basenameWithoutExtension(fileName);

                // Initial estimate replaced immediately by native metadata below
                final estimatedSeconds = (stat.size / (192 * 1024 / 8)).clamp(15.0, 3600.0).toInt();

                final track = MusicModel(
                  id: canonicalKey.hashCode.toString(),
                  title: title.replaceAll(RegExp(r'[_-]'), ' '),
                  artist: (folderName.contains('RoxPlayer') || folderName.contains('VidiMax'))
                      ? 'Rox Extracted'
                      : (folderName.isEmpty ? 'Device Audio' : folderName),
                  album: folderName,
                  path: entity.path,
                  size: stat.size,
                  duration: Duration(seconds: estimatedSeconds),
                  folder: folderName.isEmpty ? 'Internal' : folderName,
                  dateAdded: stat.modified,
                );
                directOnlyTracks.add(track);
              } catch (_) {}
            }
          }
        } catch (_) {}
      }
    }

    // Hydrate real durations, title, artist, and album tags natively for direct-scanned extras
    if (directOnlyTracks.isNotEmpty) {
      final mediaInfoMap = await SystemControlsService().getAudiosMediaInfo(
        directOnlyTracks.map((m) => m.path).toList(),
      );
      for (final m in directOnlyTracks) {
        final info = mediaInfoMap[m.path];
        final lowerPath = m.path.toLowerCase();
        final isRoxExtracted = lowerPath.contains('roxplayer') || lowerPath.contains('vidimax');
        if (info != null) {
          final durMs = (info['durationMs'] as num?)?.toInt() ?? 0;
          if (!isRoxExtracted && durMs > 0 && durMs < 15000) {
            continue;
          }
          final nativeArtist = (info['artist'] as String? ?? '').trim();
          final nativeAlbum = (info['album'] as String? ?? '').trim();
          final nativeTitle = (info['title'] as String? ?? '').trim();
          musicList.add(
            m.copyWith(
              title: nativeTitle.isNotEmpty ? nativeTitle : m.title,
              duration: durMs > 0 ? Duration(milliseconds: durMs) : m.duration,
              artist: nativeArtist.isNotEmpty ? nativeArtist : m.artist,
              album: nativeAlbum.isNotEmpty ? nativeAlbum : m.album,
            ),
          );
        } else {
          musicList.add(m);
        }
      }
    }

    // Sort by latest added first
    musicList.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));

    if (musicList.isNotEmpty) {
      await _saveMusicToCache(musicList);
      return musicList;
    }

    // Only show sample tracks when permission is confirmed granted AND disk has 0 tracks
    if (allowSampleFallback) {
      return _getSampleTracks();
    }

    return [];
  }

  List<MusicModel> _getSampleTracks() {
    return [
      MusicModel(
        id: 'sample_1',
        title: 'Midnight Chill Vibes',
        artist: 'Rox Player Studio',
        album: 'Lo-Fi Lounge',
        path: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        size: 4194304,
        duration: const Duration(minutes: 3, seconds: 45),
        folder: 'Rox Player Studio',
        dateAdded: DateTime.now().subtract(const Duration(days: 1)),
        isFavorite: true,
      ),
      MusicModel(
        id: 'sample_2',
        title: 'Electric Horizon Bass',
        artist: 'Neon Wave',
        album: 'Synth Drive',
        path: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
        size: 5242880,
        duration: const Duration(minutes: 4, seconds: 12),
        folder: 'Downloads',
        dateAdded: DateTime.now().subtract(const Duration(days: 2)),
      ),
      MusicModel(
        id: 'sample_3',
        title: 'Acoustic Sunrise Breeze',
        artist: 'Elena Harper',
        album: 'Acoustic Sessions',
        path: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
        size: 3670016,
        duration: const Duration(minutes: 3, seconds: 20),
        folder: 'Music',
        dateAdded: DateTime.now().subtract(const Duration(days: 3)),
        isFavorite: true,
      ),
      MusicModel(
        id: 'sample_4',
        title: 'Deep Focus Groove',
        artist: 'Audio Resonance',
        album: 'Ambient Motion',
        path: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
        size: 6291456,
        duration: const Duration(minutes: 5, seconds: 02),
        folder: 'Music',
        dateAdded: DateTime.now().subtract(const Duration(days: 4)),
      ),
    ];
  }
}
