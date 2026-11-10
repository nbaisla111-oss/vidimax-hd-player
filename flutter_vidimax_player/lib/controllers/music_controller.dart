import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/music_model.dart';
import '../services/music_scanner_service.dart';

enum MusicLoopMode { off, all, single }

class MusicController extends ChangeNotifier {
  final MusicScannerService _scannerService = MusicScannerService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<MusicModel> _allSongs = [];
  List<MusicModel> _playlist = [];
  int _currentIndex = -1;

  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isShuffle = false;
  MusicLoopMode _loopMode = MusicLoopMode.all;
  bool _isLoading = false;
  String _searchQuery = '';
  String? _selectedFolder;
  final Set<String> _favoriteIds = {};
  int _sortOption = 0; // 0: Date, 1: Name, 2: Duration, 3: Artist

  // Getters
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isShuffle => _isShuffle;
  MusicLoopMode get loopMode => _loopMode;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String? get selectedFolder => _selectedFolder;
  int get sortOption => _sortOption;

  MusicModel? get currentSong {
    if (_currentIndex >= 0 && _currentIndex < _playlist.length) {
      return _playlist[_currentIndex];
    }
    return null;
  }

  List<String> get folders {
    final Set<String> set = {};
    for (final song in _allSongs) {
      if (song.folder.isNotEmpty) {
        set.add(song.folder);
      }
    }
    return set.toList()..sort();
  }

  List<MusicModel> get favoriteSongs {
    return _allSongs.where((s) => _favoriteIds.contains(s.id)).toList();
  }

  List<MusicModel> get songs {
    List<MusicModel> list = List.from(_allSongs);

    // Apply folder filter
    if (_selectedFolder != null) {
      list = list.where((s) => s.folder == _selectedFolder).toList();
    }

    // Apply search filter
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      list = list.where((s) {
        return s.title.toLowerCase().contains(q) ||
            s.artist.toLowerCase().contains(q) ||
            s.album.toLowerCase().contains(q);
      }).toList();
    }

    // Apply sorting
    switch (_sortOption) {
      case 1: // Name A-Z
        list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case 2: // Duration (longest first)
        list.sort((a, b) => b.duration.compareTo(a.duration));
        break;
      case 3: // Artist
        list.sort((a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()));
        break;
      case 0: // Date added (newest first)
      default:
        list.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
        break;
    }

    return list.map((s) => s.copyWith(isFavorite: _favoriteIds.contains(s.id))).toList();
  }

  Future<void> init() async {
    _initAudioListeners();
    await _loadFavorites();
    await scanMusic();
  }

  void _initAudioListeners() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      notifyListeners();
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      _duration = newDuration;
      notifyListeners();
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      _position = newPosition;
      notifyListeners();
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (_loopMode == MusicLoopMode.single) {
        _audioPlayer.seek(Duration.zero);
        _audioPlayer.resume();
      } else {
        playNext(autoTrigger: true);
      }
    });
  }

  Future<void> scanMusic() async {
    _isLoading = true;
    notifyListeners();

    try {
      final scanned = await _scannerService.scanDeviceMusic();
      _allSongs = scanned.map((s) => s.copyWith(isFavorite: _favoriteIds.contains(s.id))).toList();
      if (_playlist.isEmpty && _allSongs.isNotEmpty) {
        _playlist = List.from(_allSongs);
      }
    } catch (e) {
      debugPrint("Error scanning music: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> playSong(MusicModel song, {List<MusicModel>? queue}) async {
    if (queue != null && queue.isNotEmpty) {
      _playlist = List.from(queue);
    } else if (_playlist.isEmpty) {
      _playlist = List.from(_allSongs);
    }

    _currentIndex = _playlist.indexWhere((s) => s.id == song.id);
    if (_currentIndex == -1) {
      _playlist.insert(0, song);
      _currentIndex = 0;
    }

    try {
      await _audioPlayer.stop();
      _position = Duration.zero;

      if (song.path.startsWith('http://') || song.path.startsWith('https://')) {
        await _audioPlayer.play(UrlSource(song.path));
      } else {
        await _audioPlayer.play(DeviceFileSource(song.path));
      }
    } catch (e) {
      debugPrint("Error playing song ${song.title}: $e");
    }
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (currentSong == null) {
      if (_allSongs.isNotEmpty) {
        await playSong(_allSongs.first);
      }
      return;
    }

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.resume();
      }
    } catch (e) {
      debugPrint("Error toggling play/pause: $e");
    }
    notifyListeners();
  }

  Future<void> playNext({bool autoTrigger = false}) async {
    if (_playlist.isEmpty) return;

    if (_loopMode == MusicLoopMode.off && autoTrigger && _currentIndex >= _playlist.length - 1) {
      await _audioPlayer.stop();
      _isPlaying = false;
      notifyListeners();
      return;
    }

    if (_isShuffle && _playlist.length > 1) {
      final random = Random();
      int nextIdx = random.nextInt(_playlist.length);
      if (nextIdx == _currentIndex) {
        nextIdx = (nextIdx + 1) % _playlist.length;
      }
      _currentIndex = nextIdx;
    } else {
      _currentIndex = (_currentIndex + 1) % _playlist.length;
    }

    final nextSong = _playlist[_currentIndex];
    await playSong(nextSong);
  }

  Future<void> playPrevious() async {
    if (_playlist.isEmpty) return;

    // If more than 3 seconds in, restart current song
    if (_position.inSeconds > 3) {
      await seekTo(Duration.zero);
      return;
    }

    _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    final prevSong = _playlist[_currentIndex];
    await playSong(prevSong);
  }

  Future<void> seekTo(Duration targetPosition) async {
    try {
      await _audioPlayer.seek(targetPosition);
      _position = targetPosition;
      notifyListeners();
    } catch (e) {
      debugPrint("Error seeking music: $e");
    }
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    notifyListeners();
  }

  void toggleLoopMode() {
    if (_loopMode == MusicLoopMode.all) {
      _loopMode = MusicLoopMode.single;
    } else if (_loopMode == MusicLoopMode.single) {
      _loopMode = MusicLoopMode.off;
    } else {
      _loopMode = MusicLoopMode.all;
    }
    notifyListeners();
  }

  Future<void> toggleFavorite(MusicModel song) async {
    if (_favoriteIds.contains(song.id)) {
      _favoriteIds.remove(song.id);
    } else {
      _favoriteIds.add(song.id);
    }
    await _saveFavorites();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedFolder(String? folder) {
    _selectedFolder = folder;
    notifyListeners();
  }

  void setSortOption(int option) {
    _sortOption = option;
    notifyListeners();
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('vidimax_music_favorites') ?? [];
      _favoriteIds.addAll(list);
    } catch (_) {}
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('vidimax_music_favorites', _favoriteIds.toList());
    } catch (_) {}
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
