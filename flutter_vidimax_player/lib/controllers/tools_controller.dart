import 'dart:io';
import 'package:flutter/material.dart';
import '../models/status_item_model.dart';
import '../services/audio_extractor_service.dart';
import '../services/status_saver_service.dart';

class ToolsController extends ChangeNotifier {
  final AudioExtractorService _audioService = AudioExtractorService();
  final StatusSaverService _statusService = StatusSaverService();

  // Audio Extractor State
  bool _isConverting = false;
  double _conversionProgress = 0.0;
  File? _lastExtractedAudio;
  String? _conversionError;

  bool get isConverting => _isConverting;
  double get conversionProgress => _conversionProgress;
  File? get lastExtractedAudio => _lastExtractedAudio;
  String? get conversionError => _conversionError;

  // Status Saver State
  List<StatusItemModel> _statuses = [];
  bool _isLoadingStatuses = false;
  StatusAppSource _selectedSource = StatusAppSource.whatsapp;

  List<StatusItemModel> get statuses => _statuses;
  bool get isLoadingStatuses => _isLoadingStatuses;
  StatusAppSource get selectedSource => _selectedSource;

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
}
