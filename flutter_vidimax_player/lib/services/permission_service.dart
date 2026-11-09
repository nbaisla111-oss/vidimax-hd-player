import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// Check and request media storage permissions smoothly across all Android versions
  Future<bool> requestStoragePermissions() async {
    if (!Platform.isAndroid) return true;

    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    if (sdkInt >= 33) {
      // Android 13 (Tiramisu) and Android 14+ (Upside Down Cake)
      final statuses = await [
        Permission.videos,
        Permission.photos,
        Permission.audio,
      ].request();

      final videoGranted = statuses[Permission.videos]?.isGranted ?? false;
      return videoGranted;
    } else {
      // Android 12 (API 32) and below
      final status = await Permission.storage.request();
      return status.isGranted;
    }
  }

  /// Request all-files access for Vault file relocation or Status Saver if needed
  Future<bool> requestManageStoragePermission() async {
    if (!Platform.isAndroid) return true;
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    if (androidInfo.version.sdkInt >= 30) {
      final status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        final result = await Permission.manageExternalStorage.request();
        return result.isGranted;
      }
      return true;
    }
    return true;
  }

  /// Check current permission status
  Future<bool> hasStoragePermission() async {
    if (!Platform.isAndroid) return true;
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    if (androidInfo.version.sdkInt >= 33) {
      return await Permission.videos.isGranted;
    }
    return await Permission.storage.isGranted;
  }
}
