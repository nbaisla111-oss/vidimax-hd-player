import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SystemControlsService {
  static final SystemControlsService _instance = SystemControlsService._internal();
  factory SystemControlsService() => _instance;

  static const MethodChannel _channel = MethodChannel('com.rox.player/system_controls');

  void Function(String action)? _musicMediaActionHandler;

  void Function(bool isPip)? _onPipModeChanged;
  void Function(String action)? _onPipAction;
  VoidCallback? _onPlayerBackgrounded;
  void Function(String action)? _videoMediaActionHandler;
  VoidCallback? _onAudioLibraryChanged;
  VoidCallback? _onVideoLibraryChanged;

  SystemControlsService._internal() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  MethodChannel get channel => _channel;

  void setMusicMediaActionHandler(void Function(String action)? handler) {
    _musicMediaActionHandler = handler;
  }

  void setAudioLibraryChangedHandler(VoidCallback? handler) {
    _onAudioLibraryChanged = handler;
  }

  void setVideoLibraryChangedHandler(VoidCallback? handler) {
    _onVideoLibraryChanged = handler;
  }

  void setVideoHandlers({
    void Function(bool isPip)? onPipModeChanged,
    void Function(String action)? onPipAction,
    VoidCallback? onPlayerBackgrounded,
    void Function(String action)? onMediaAction,
  }) {
    _onPipModeChanged = onPipModeChanged;
    _onPipAction = onPipAction;
    _onPlayerBackgrounded = onPlayerBackgrounded;
    _videoMediaActionHandler = onMediaAction;
  }

  void clearVideoHandlers() {
    _onPipModeChanged = null;
    _onPipAction = null;
    _onPlayerBackgrounded = null;
    _videoMediaActionHandler = null;
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onPipModeChanged':
        final isPip = call.arguments as bool? ?? false;
        _onPipModeChanged?.call(isPip);
        break;
      case 'onPipAction':
        final action = call.arguments as String? ?? '';
        _onPipAction?.call(action);
        break;
      case 'onPlayerBackgrounded':
        _onPlayerBackgrounded?.call();
        break;
      case 'onMediaAction':
        final action = call.arguments as String? ?? '';
        if (_videoMediaActionHandler != null) {
          _videoMediaActionHandler?.call(action);
        } else {
          _musicMediaActionHandler?.call(action);
        }
        break;
      case 'onAudioLibraryChanged':
        _onAudioLibraryChanged?.call();
        break;
      case 'onVideoLibraryChanged':
        _onVideoLibraryChanged?.call();
        break;
    }
  }

  Future<List<Map<String, dynamic>>> queryAllDeviceAudio() async {
    try {
      final raw = await _channel.invokeListMethod<dynamic>('queryAllDeviceAudio');
      if (raw == null) return [];
      final List<Map<String, dynamic>> parsed = [];
      for (final item in raw) {
        if (item is Map) {
          parsed.add(Map<String, dynamic>.from(item));
        }
      }
      return parsed;
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> saveMediaToGallery({
    required String sourcePath,
    required String fileName,
    required bool isVideo,
  }) async {
    try {
      final raw = await _channel.invokeMapMethod<dynamic, dynamic>(
        'saveMediaToGallery',
        {
          'sourcePath': sourcePath,
          'fileName': fileName,
          'isVideo': isVideo,
        },
      );
      if (raw == null) return {'success': false};
      return Map<String, dynamic>.from(raw);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<bool> scanMediaFile(String path, {String? mimeType}) async {
    if (path.isEmpty) return false;
    try {
      final res = await _channel.invokeMethod<bool>(
        'scanMediaFile',
        {'path': path, 'mimeType': mimeType},
      );
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, Map<String, dynamic>>> getVideosMediaInfo(List<String> paths) async {
    if (paths.isEmpty) return {};
    try {
      final raw = await _channel.invokeMapMethod<dynamic, dynamic>(
        'getVideosMediaInfo',
        {'paths': paths},
      );
      if (raw == null) return {};
      final Map<String, Map<String, dynamic>> parsed = {};
      raw.forEach((key, value) {
        if (key is String && value is Map) {
          parsed[key] = Map<String, dynamic>.from(value);
        }
      });
      return parsed;
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, Map<String, dynamic>>> getAudiosMediaInfo(List<String> paths) async {
    if (paths.isEmpty) return {};
    try {
      final raw = await _channel.invokeMapMethod<dynamic, dynamic>(
        'getAudiosMediaInfo',
        {'paths': paths},
      );
      if (raw == null) return {};
      final Map<String, Map<String, dynamic>> parsed = {};
      raw.forEach((key, value) {
        if (key is String && value is Map) {
          parsed[key] = Map<String, dynamic>.from(value);
        }
      });
      return parsed;
    } catch (_) {
      return {};
    }
  }

  Future<void> updateMediaNotification({
    required String title,
    required String subtitle,
    required String path,
    required String mediaType,
    required bool isPlaying,
    required int durationMs,
    required int positionMs,
  }) async {
    try {
      await _channel.invokeMethod('updateMediaNotification', {
        'title': title,
        'subtitle': subtitle,
        'path': path,
        'mediaType': mediaType,
        'isPlaying': isPlaying,
        'durationMs': durationMs,
        'positionMs': positionMs,
      });
    } catch (_) {}
  }

  Future<void> clearMediaNotification() async {
    try {
      await _channel.invokeMethod('clearMediaNotification');
    } catch (_) {}
  }
}
