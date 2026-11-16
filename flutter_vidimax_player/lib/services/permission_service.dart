import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  Future<bool>? _inFlightStorageRequest;
  final StreamController<void> _permissionsUpdatedController = StreamController<void>.broadcast();

  Stream<void> get onPermissionsUpdated => _permissionsUpdatedController.stream;

  /// Check and request media storage permissions smoothly across all Android versions
  /// Safe to invoke concurrently from multiple controllers without overlapping OS prompts.
  Future<bool> requestStoragePermissions() {
    _inFlightStorageRequest ??= _performStoragePermissionRequest().whenComplete(() {
      _inFlightStorageRequest = null;
      if (!_permissionsUpdatedController.isClosed) {
        _permissionsUpdatedController.add(null);
      }
    });
    return _inFlightStorageRequest!;
  }

  Future<bool> _performStoragePermissionRequest() async {
    if (!Platform.isAndroid) return true;

    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    if (sdkInt >= 33) {
      // Android 13+ (API 33, 34+)
      final statuses = await [
        Permission.videos,
        Permission.photos,
        Permission.audio,
      ].request();

      final videoGranted = statuses[Permission.videos]?.isGranted ?? false;
      final audioGranted = statuses[Permission.audio]?.isGranted ?? false;

      // Also request manageExternalStorage if not granted to ensure hidden WhatsApp .Statuses and full folders are accessible
      if (!await Permission.manageExternalStorage.isGranted) {
        await Permission.manageExternalStorage.request();
      }

      return videoGranted || audioGranted || (await Permission.manageExternalStorage.isGranted);
    } else if (sdkInt >= 30) {
      // Android 11 & 12 (API 30, 31, 32)
      final storageStatus = await Permission.storage.request();
      if (!await Permission.manageExternalStorage.isGranted) {
        await Permission.manageExternalStorage.request();
      }
      return storageStatus.isGranted || (await Permission.manageExternalStorage.isGranted);
    } else {
      // Android 10 and below
      final status = await Permission.storage.request();
      return status.isGranted;
    }
  }

  /// Request all-files access for Vault file relocation or WhatsApp Status Saver
  Future<bool> requestManageStoragePermission() async {
    if (!Platform.isAndroid) return true;
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    bool granted = false;
    if (androidInfo.version.sdkInt >= 30) {
      final status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        final result = await Permission.manageExternalStorage.request();
        granted = result.isGranted;
      } else {
        granted = true;
      }
    } else {
      final status = await Permission.storage.request();
      granted = status.isGranted;
    }
    if (granted && !_permissionsUpdatedController.isClosed) {
      _permissionsUpdatedController.add(null);
    }
    return granted;
  }

  /// Check current video/storage permission status
  Future<bool> hasStoragePermission() async {
    if (!Platform.isAndroid) return true;
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    if (sdkInt >= 30 && await Permission.manageExternalStorage.isGranted) {
      return true;
    }

    if (sdkInt >= 33) {
      return await Permission.videos.isGranted;
    }
    return await Permission.storage.isGranted;
  }

  /// Check current audio/music permission status across all Android versions
  Future<bool> hasAudioPermission() async {
    if (!Platform.isAndroid) return true;
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    if (sdkInt >= 30 && await Permission.manageExternalStorage.isGranted) {
      return true;
    }

    if (sdkInt >= 33) {
      return await Permission.audio.isGranted;
    }
    return await Permission.storage.isGranted;
  }

  /// Check if all files / manage external storage permission is granted
  Future<bool> hasManageStoragePermission() async {
    if (!Platform.isAndroid) return true;
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    if (androidInfo.version.sdkInt >= 30) {
      return await Permission.manageExternalStorage.isGranted;
    }
    return await Permission.storage.isGranted;
  }

  /// Request notification permission gracefully on Android 13+ for lock screen & shade controls
  Future<bool> requestNotificationPermission() async {
    if (!Platform.isAndroid) return true;
    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        final status = await Permission.notification.status;
        if (!status.isGranted && !status.isPermanentlyDenied) {
          final result = await Permission.notification.request();
          return result.isGranted;
        }
        return status.isGranted;
      }
    } catch (_) {}
    return true;
  }
}
