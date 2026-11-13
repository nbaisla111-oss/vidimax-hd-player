import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/music_model.dart';

class MusicScannerService {
  static final MusicScannerService _instance = MusicScannerService._internal();
  factory MusicScannerService() => _instance;
  MusicScannerService._internal();

  final List<String> supportedAudioExtensions = [
    '.mp3', '.m4a', '.wav', '.aac', '.flac', '.ogg', '.opus', '.wma'
  ];

  /// Fast scan of device storage directories for offline audio & music files
  Future<List<MusicModel>> scanDeviceMusic() async {
    final List<MusicModel> musicList = [];
    final Set<String> seenPaths = {};

    final targetDirs = [
      Directory('/storage/emulated/0/Music'),
      Directory('/storage/emulated/0/Music/RoxPlayer'),
      Directory('/storage/emulated/0/Music/VidiMax'),
      Directory('/storage/emulated/0/Download'),
      Directory('/storage/emulated/0/Audio'),
      Directory('/storage/emulated/0/Podcasts'),
      Directory('/storage/emulated/0/Recordings'),
      Directory('/storage/emulated/0/WhatsApp/Media/WhatsApp Audio'),
      Directory('/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Audio'),
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
              if (supportedAudioExtensions.contains(ext) && !seenPaths.contains(entity.path)) {
                try {
                  seenPaths.add(entity.path);
                  final stat = await entity.stat();
                  final folderName = p.basename(p.dirname(entity.path));
                  final fileName = p.basename(entity.path);
                  final title = p.basenameWithoutExtension(fileName);

                  // Estimate duration based on bitrate / file size if tag reading is not available
                  final estimatedSeconds = (stat.size / (192 * 1024 / 8)).clamp(30.0, 3600.0).toInt();

                  musicList.add(
                    MusicModel(
                      id: entity.path.hashCode.toString(),
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
                    ),
                  );
                } catch (_) {}
              }
            }
          }
        } catch (_) {}
      }
    }

    // Sort by latest added first
    musicList.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));

    // If no songs found on disk (e.g. test environment or clean device), add demo items
    if (musicList.isEmpty) {
      musicList.addAll(_getSampleTracks());
    }

    return musicList;
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
