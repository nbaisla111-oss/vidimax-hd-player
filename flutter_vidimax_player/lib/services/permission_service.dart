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
      // Android 13+ (API 33, 34+)
      final statuses = await [
        Permission.videos,
        Permission.photos,
        Permission.audio,
      ].request();

      final videoGranted = statuses[Permission.videos]?.isGranted ?? false;
      
      // Also request manageExternalStorage if not granted to ensure hidden WhatsApp .Statuses and full folders are accessible
      if (!await Permission.manageExternalStorage.isGranted) {
        await Permission.manageExternalStorage.request();
      }

      return videoGranted || (await Permission.manageExternalStorage.isGranted);
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
    if (androidInfo.version.sdkInt >= 30) {
      final status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        final result = await Permission.manageExternalStorage.request();
        return result.isGranted;
      }
      return true;
    }
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  /// Check current permission status
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

  /// Check if all files / manage external storage permission is granted
  Future<bool> hasManageStoragePermission() async {
    if (!Platform.isAndroid) return true;
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    if (androidInfo.version.sdkInt >= 30) {
      return await Permission.manageExternalStorage.isGranted;
    }
    return await Permission.storage.isGranted;
  }
}
