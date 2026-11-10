import 'package:flutter/material.dart';
import '../models/video_model.dart';
import '../models/folder_model.dart';
import '../services/video_scanner_service.dart';
import '../services/permission_service.dart';

enum VideoSortMode { dateDesc, dateAsc, nameAsc, sizeDesc, durationDesc }

class VideoController extends ChangeNotifier {
  final VideoScannerService _scanner = VideoScannerService();
  final PermissionService _permissions = PermissionService();

  List<VideoModel> _allVideos = [];
  Map<String, FolderModel> _folders = {};
  List<VideoModel> _filteredVideos = [];
  String _searchQuery = '';
  VideoSortMode _sortMode = VideoSortMode.dateDesc;
  bool _isLoading = false;
  bool _hasPermission = false;
  String? _selectedFolder;
  bool _isInitialized = false; // ताकि बार-बार फालतू री-स्कैन न हो

  List<VideoModel> get videos => _filteredVideos;
  Map<String, FolderModel> get folders => _folders;
  bool get isLoading => _isLoading;
  bool get hasPermission => _hasPermission;
  String? get selectedFolder => _selectedFolder;
  String get searchQuery => _searchQuery;
  VideoSortMode get sortMode => _sortMode;

  Future<void> init() async {
    // अगर पहले से डेटा लोड है, तो दोबारा फालतू लोडिंग स्पिनर मत दिखाओ (Instant Open)
    if (_isInitialized && _allVideos.isNotEmpty) {
      return;
    }

    _hasPermission = await _permissions.hasStoragePermission();
    if (!_hasPermission) {
      _hasPermission = await _permissions.requestStoragePermissions();
    }
    notifyListeners();

    if (_hasPermission) {
      await loadVideos();
    }
  }

  Future<void> loadVideos({bool forceRefresh = false}) async {
    // अगर पहले से वीडियो मौजूद हैं और जबरदस्ती रिफ्रेश नहीं मांग रहे, तो लोडिंग स्पिनर मत चलाओ
    if (_allVideos.isNotEmpty && !forceRefresh) {
      return;
    }

    // केवल तभी लोडिंग स्पिनर दिखाओ जब बिल्कुल खाली हो या जबरदस्ती रिफ्रेश किया जा रहा हो
    if (_allVideos.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      // डिवाइस से वीडियो स्कैन करना
      _allVideos = await _scanner.scanDeviceVideos();
      _folders = _scanner.groupVideosByFolder(_allVideos);
      _applyFilterAndSort();
      _isInitialized = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // नई वीडियो या फ्रेश लिस्ट लाने के लिए यूजर के लिए रिफ्रेश फंक्शन
  Future<void> refreshVideos() async {
    await loadVideos(forceRefresh: true);
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilterAndSort();
    notifyListeners();
  }

  void selectFolder(String? folderName) {
    _selectedFolder = folderName;
    _applyFilterAndSort();
    notifyListeners();
  }

  void setSortMode(VideoSortMode mode) {
    _sortMode = mode;
    _applyFilterAndSort();
    notifyListeners();
  }

  void _applyFilterAndSort() {
    List<VideoModel> list = List.from(_allVideos);

    if (_selectedFolder != null) {
      list = list.where((v) => v.folderName == _selectedFolder).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((v) => v.title.toLowerCase().contains(q) || v.folderName.toLowerCase().contains(q)).toList();
    }

    switch (_sortMode) {
      case VideoSortMode.dateDesc:
        list.sort((a, b) => b.dateModified.compareTo(a.dateModified));
        break;
      case VideoSortMode.dateAsc:
        list.sort((a, b) => a.dateModified.compareTo(b.dateModified));
        break;
      case VideoSortMode.nameAsc:
        list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case VideoSortMode.sizeDesc:
        list.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
        break;
      case VideoSortMode.durationDesc:
        list.sort((a, b) => b.durationMs.compareTo(a.durationMs));
        break;
    }

    _filteredVideos = list;
  }

  void removeVideoLocally(String id) {
    _allVideos.removeWhere((v) => v.id == id);
    _folders = _scanner.groupVideosByFolder(_allVideos);
    _applyFilterAndSort();
    notifyListeners();
  }
}
