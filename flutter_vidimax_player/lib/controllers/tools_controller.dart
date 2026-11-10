import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart'; // ऑडियो प्ले करने के लिए
import '../models/status_item_model.dart';
import '../services/audio_extractor_service.dart';
import '../services/status_saver_service.dart';

class ToolsController extends ChangeNotifier {
  final AudioExtractorService _audioService = AudioExtractorService();
  final StatusSaverService _statusService = StatusSaverService();
  final AudioPlayer _audioPlayer = AudioPlayer(); // इन-एप ऑडियो प्ले करने के लिए प्लेयर

  // Audio Extractor State
  bool _isConverting = false;
  double _conversionProgress = 0.0;
  File? _lastExtractedAudio;
  String? _conversionError;

  // Audio Playback State (नया स्टेट जो ऑडियो सुनने में मदद करेगा)
  bool _isPlayingAudio = false;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;

  bool get isConverting => _isConverting;
  double get conversionProgress => _conversionProgress;
  File? get lastExtractedAudio => _lastExtractedAudio;
  String? get conversionError => _conversionError;
  bool get isPlayingAudio => _isPlayingAudio;
  Duration get audioDuration => _audioDuration;
  Duration get audioPosition => _audioPosition;

  ToolsController() {
    // ऑडियो प्लेयर के लिसनर सेट करना ताकि प्रोग्रेस पता चल सके
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _isPlayingAudio = state == PlayerState.playing;
      notifyListeners();
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      _audioDuration = newDuration;
      notifyListeners();
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      _audioPosition = newPosition;
      notifyListeners();
    });
  }

  Future<void> extractAudio({
    required String videoPath,
    required String outputName,
    int bitrate = 192,
  }) async {
    _isConverting = true;
    _conversionProgress = 0.0;
    _conversionError = null;
    notifyListeners();

    try {
      _lastExtractedAudio = await _audioService.extractAudioFromVideo(
        videoPath: videoPath,
        outputFileName: outputName,
        bitrateKbps: bitrate,
        onProgress: (p) {
          _conversionProgress = p;
          notifyListeners();
        },
      );
    } catch (e) {
      _conversionError = e.toString();
    } finally {
      _isConverting = false;
      notifyListeners();
    }
  }

  // एक्सट्रैक्टेड ऑडियो को तुरंत प्ले या पॉज करने का फंक्शन
  Future<void> togglePlayExtractedAudio() async {
    if (_lastExtractedAudio == null) return;

    if (_isPlayingAudio) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(DeviceFileSource(_lastExtractedAudio!.path));
    }
    notifyListeners();
  }

  // ऑडियो प्लेबैक बंद करने के लिए
  Future<void> stopAudio() async {
    await _audioPlayer.stop();
    _isPlayingAudio = false;
    notifyListeners();
  }

  // Status Saver State
  List<StatusItemModel> _statuses = [];
  bool _isLoadingStatuses = false;
  StatusAppSource _selectedSource = StatusAppSource.whatsapp;

  List<StatusItemModel> get statuses => _statuses;
  bool get isLoadingStatuses => _isLoadingStatuses;
  StatusAppSource get selectedSource => _selectedSource;

  void setSelectedStatusSource(StatusAppSource source) {
    _selectedSource = source;
    loadStatuses();
  }

  Future<void> loadStatuses() async {
    _isLoadingStatuses = true;
    notifyListeners();

    try {
      _statuses = await _statusService.fetchStatuses(filterSource: _selectedSource);
    } finally {
      _isLoadingStatuses = false;
      notifyListeners();
    }
  }

  Future<void> saveStatus(StatusItemModel status) async {
    await _statusService.saveStatusToGallery(status);
    final index = _statuses.indexWhere((s) => s.id == status.id);
    if (index != -1) {
      _statuses[index] = status.copyWith(isSaved: true);
      notifyListeners();
    }
  }

  Future<void> shareStatus(StatusItemModel status) async {
    await _statusService.shareStatus(status);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
