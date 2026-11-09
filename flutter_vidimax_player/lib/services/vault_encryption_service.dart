import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vault_item_model.dart';
import '../models/video_model.dart';

class VaultEncryptionService {
  static const String _pinKey = 'vidimax_vault_pin_hash';
  static const String _secQuestionKey = 'vidimax_vault_sec_question';
  static const String _secAnswerHashKey = 'vidimax_vault_sec_answer_hash';

  /// Hash a 4-digit PIN with SHA-256
  String _hash(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }

  /// Check if Vault PIN is configured
  Future<bool> isVaultConfigured() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_pinKey);
  }

  /// Setup Vault PIN and security recovery question
  Future<void> setupPin({
    required String pin,
    required String securityQuestion,
    required String securityAnswer,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, _hash(pin));
    await prefs.setString(_secQuestionKey, securityQuestion);
    await prefs.setString(_secAnswerHashKey, _hash(securityAnswer.trim().toLowerCase()));
  }

  /// Verify entered 4-digit PIN
  Future<bool> verifyPin(String enteredPin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString(_pinKey);
    if (storedHash == null) return false;
    return storedHash == _hash(enteredPin);
  }

  /// Reset PIN using security answer
  Future<bool> resetPinWithSecurityAnswer({
    required String answer,
    required String newPin,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final storedAnswerHash = prefs.getString(_secAnswerHashKey);
    if (storedAnswerHash == null) return false;
    if (storedAnswerHash == _hash(answer.trim().toLowerCase())) {
      await prefs.setString(_pinKey, _hash(newPin));
      return true;
    }
    return false;
  }

  /// Get the private vault directory in app internal storage
  Future<Directory> _getVaultDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final vaultDir = Directory(p.join(appDir.path, '.vidimax_vault'));
    if (!await vaultDir.exists()) {
      await vaultDir.create(recursive: true);
    }
    return vaultDir;
  }

  /// Generate AES 256 Key from PIN
  enc.Key _deriveKeyFromPin(String pin) {
    final hashBytes = sha256.convert(utf8.encode('vidimax_salt_$pin')).bytes;
    return enc.Key(Uint8List.fromList(hashBytes));
  }

  /// Hide video: Read file, encrypt with AES, save into private vault, remove from gallery
  Future<VaultItemModel> hideVideo(VideoModel video, String pin) async {
    final vaultDir = await _getVaultDirectory();
    final sourceFile = File(video.path);

    if (!await sourceFile.exists()) {
      throw Exception("Source video file does not exist: ${video.path}");
    }

    final originalFileName = p.basename(video.path);
    final encryptedFileName = '${DateTime.now().millisecondsSinceEpoch}_${video.id}.vdmx';
    final targetPath = p.join(vaultDir.path, encryptedFileName);

    // Encrypt file bytes
    final key = _deriveKeyFromPin(pin);
    final iv = enc.IV.fromLength(16);
    final encrypter = enc.Encrypter(enc.AES(key));

    final fileBytes = await sourceFile.readAsBytes();
    final encrypted = encrypter.encryptBytes(fileBytes, iv: iv);

    // Save IV prepended with ciphertext
    final targetFile = File(targetPath);
    final combined = Uint8List.fromList(iv.bytes + encrypted.bytes);
    await targetFile.writeAsBytes(combined);

    // Safely remove the original file so it is hidden from external media scanners
    await sourceFile.delete();

    return VaultItemModel(
      id: video.id,
      originalName: originalFileName,
      originalPath: video.path,
      encryptedPath: targetPath,
      sizeBytes: video.sizeBytes,
      dateAdded: DateTime.now().millisecondsSinceEpoch,
      durationMs: video.durationMs,
      thumbnailPath: video.thumbnailPath,
    );
  }

  /// Unhide video: Decrypt and restore to original path
  Future<File> unhideVideo(VaultItemModel vaultItem, String pin) async {
    final encryptedFile = File(vaultItem.encryptedPath);
    if (!await encryptedFile.exists()) {
      throw Exception("Encrypted vault file not found");
    }

    final key = _deriveKeyFromPin(pin);
    final allBytes = await encryptedFile.readAsBytes();

    // Extract IV (first 16 bytes) and ciphertext
    final ivBytes = allBytes.sublist(0, 16);
    final cipherBytes = allBytes.sublist(16);

    final iv = enc.IV(ivBytes);
    final encrypter = enc.Encrypter(enc.AES(key));
    final decryptedBytes = encrypter.decryptBytes(enc.Encrypted(cipherBytes), iv: iv);

    // Restore to original directory or Downloads fallback
    final targetDir = Directory(p.dirname(vaultItem.originalPath));
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final restoredFile = File(vaultItem.originalPath);
    await restoredFile.writeAsBytes(decryptedBytes);

    // Delete encrypted vault file
    await encryptedFile.delete();

    return restoredFile;
  }

  /// Decrypt temporarily for playing inside secret vault
  Future<File> getDecryptedPlaybackFile(VaultItemModel vaultItem, String pin) async {
    final tempDir = await getTemporaryDirectory();
    final tempPlayPath = p.join(tempDir.path, 'vault_play_${vaultItem.originalName}');
    final tempFile = File(tempPlayPath);

    if (await tempFile.exists()) {
      return tempFile;
    }

    final encryptedFile = File(vaultItem.encryptedPath);
    final key = _deriveKeyFromPin(pin);
    final allBytes = await encryptedFile.readAsBytes();

    final ivBytes = allBytes.sublist(0, 16);
    final cipherBytes = allBytes.sublist(16);

    final iv = enc.IV(ivBytes);
    final encrypter = enc.Encrypter(enc.AES(key));
    final decryptedBytes = encrypter.decryptBytes(enc.Encrypted(cipherBytes), iv: iv);

    await tempFile.writeAsBytes(decryptedBytes);
    return tempFile;
  }
}
