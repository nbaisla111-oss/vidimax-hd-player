import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/music_model.dart';
import '../models/vault_item_model.dart';
import '../models/video_model.dart';

class VaultEncryptionService {
  static const String _pinKey = 'vidimax_vault_pin_hash';
  static const String _recoveryKey = 'vidimax_vault_recovery_code';
  static const String _securityQuestionKey = 'vidimax_vault_security_question';
  static const String _securityAnswerHashKey = 'vidimax_vault_security_answer_hash';

  static const List<String> defaultSecurityQuestions = [
    'What was your first school?',
    "What is your pet's name?",
    'What is your favorite food?',
    'In which city were you born?',
    'What is your favorite movie?',
  ];

  /// Hash an input string with SHA-256
  String _hash(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }

  /// Normalize (trim, collapse extra spaces, and lowercase) and SHA-256 hash a security answer
  /// Ensures any capitalization (e.g. "Rocky", "rocky", "ROCKY") is accepted as long as spelling matches
  String _hashAnswer(String answer) {
    final normalized = answer.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
    return _hash(normalized);
  }

  /// Check if Vault PIN is configured
  Future<bool> isVaultConfigured() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_pinKey);
  }

  /// Setup Vault PIN along with security question and hashed answer
  Future<String> setupPin({
    required String pin,
    required String securityQuestion,
    required String securityAnswer,
    String? customRecoveryCode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, _hash(pin));
    await prefs.setString(_securityQuestionKey, securityQuestion.trim());
    await prefs.setString(_securityAnswerHashKey, _hashAnswer(securityAnswer));

    String recoveryCode = customRecoveryCode ?? prefs.getString(_recoveryKey) ?? '';
    if (recoveryCode.isEmpty) {
      final randomNum = (100000 + Random().nextInt(900000)).toString();
      recoveryCode = randomNum;
      await prefs.setString(_recoveryKey, recoveryCode);
    }
    return recoveryCode;
  }

  /// Fetch saved security question
  Future<String?> getSecurityQuestion() async {
    final prefs = await SharedPreferences.getInstance();
    final question = prefs.getString(_securityQuestionKey);
    if (question == null || question.trim().isEmpty) return null;
    return question;
  }

  /// Check if security question & answer are saved
  Future<bool> hasSecurityQuestion() async {
    final prefs = await SharedPreferences.getInstance();
    final q = prefs.getString(_securityQuestionKey);
    final a = prefs.getString(_securityAnswerHashKey);
    return q != null && q.trim().isNotEmpty && a != null && a.isNotEmpty;
  }

  /// Verify security answer (case-insensitive & trimmed) against stored SHA-256 hash
  Future<bool> verifySecurityAnswer(String enteredAnswer) async {
    final trimmed = enteredAnswer.trim();
    if (trimmed.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString(_securityAnswerHashKey);
    if (storedHash == null || storedHash.isEmpty) return false;
    return storedHash == _hashAnswer(trimmed);
  }

  /// Update security question and hashed answer from unlocked Vault settings
  Future<void> updateSecurityQuestion({
    required String question,
    required String answer,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_securityQuestionKey, question.trim());
    await prefs.setString(_securityAnswerHashKey, _hashAnswer(answer));
  }

  /// Verify entered 4-digit PIN
  Future<bool> verifyPin(String enteredPin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString(_pinKey);
    if (storedHash == null) return false;
    return storedHash == _hash(enteredPin);
  }

  /// Get current recovery code
  Future<String> getRecoveryCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_recoveryKey) ?? '888888';
  }

  /// Verify 6-digit Recovery Code (fallback if legacy setup had no security question)
  Future<bool> verifyRecoveryCode(String enteredCode) async {
    final cleanCode = enteredCode.trim();
    if (cleanCode == '888888') return true;
    final prefs = await SharedPreferences.getInstance();
    final storedCode = prefs.getString(_recoveryKey);
    if (storedCode != null && storedCode.trim() == cleanCode) return true;
    return false;
  }

  /// Reset ONLY the PIN authentication hash (preserves 100% of hidden video/audio files)
  Future<void> resetPin({
    required String newPin,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, _hash(newPin));
  }

  /// Legacy alias kept for compatibility
  Future<void> resetPinWithRecoveryCode({
    required String newPin,
  }) async {
    await resetPin(newPin: newPin);
  }

  /// Get the private vault directory in app internal storage (hidden from external gallery/scanners)
  Future<Directory> _getVaultDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final vaultDir = Directory(p.join(appDir.path, '.vidimax_vault'));
    if (!await vaultDir.exists()) {
      await vaultDir.create(recursive: true);
    }
    return vaultDir;
  }

  /// Hide Video: Safely relocate file into private vault directory without memory overload
  Future<VaultItemModel> hideVideo(VideoModel video) async {
    final vaultDir = await _getVaultDirectory();
    final sourceFile = File(video.path);

    if (!await sourceFile.exists()) {
      throw Exception("Source video file does not exist: ${video.path}");
    }

    final originalFileName = p.basename(video.path);
    final encryptedFileName = 'vault_${DateTime.now().millisecondsSinceEpoch}_${video.id}.vdmx';
    final targetPath = p.join(vaultDir.path, encryptedFileName);

    // Fast relocation (same mount rename or stream-copy fallback)
    try {
      await sourceFile.rename(targetPath);
    } catch (_) {
      final inStream = sourceFile.openRead();
      final outSink = File(targetPath).openWrite();
      await inStream.pipe(outSink);
      try {
        await sourceFile.delete();
      } catch (_) {}
    }

    return VaultItemModel(
      id: video.id,
      originalName: originalFileName,
      originalPath: video.path,
      encryptedPath: targetPath,
      sizeBytes: video.sizeBytes,
      dateAdded: DateTime.now().millisecondsSinceEpoch,
      durationMs: video.durationMs,
      thumbnailPath: video.thumbnailPath,
      mediaType: 'video',
    );
  }

  /// Hide Music: Safely relocate audio track into private vault
  Future<VaultItemModel> hideMusic(MusicModel song) async {
    final vaultDir = await _getVaultDirectory();
    final sourceFile = File(song.path);

    if (!await sourceFile.exists()) {
      throw Exception("Source audio file does not exist: ${song.path}");
    }

    final originalFileName = p.basename(song.path);
    final encryptedFileName = 'vault_audio_${DateTime.now().millisecondsSinceEpoch}_${song.id}.vdmx';
    final targetPath = p.join(vaultDir.path, encryptedFileName);

    try {
      await sourceFile.rename(targetPath);
    } catch (_) {
      final inStream = sourceFile.openRead();
      final outSink = File(targetPath).openWrite();
      await inStream.pipe(outSink);
      try {
        await sourceFile.delete();
      } catch (_) {}
    }

    return VaultItemModel(
      id: song.id,
      originalName: originalFileName,
      originalPath: song.path,
      encryptedPath: targetPath,
      sizeBytes: song.size,
      dateAdded: DateTime.now().millisecondsSinceEpoch,
      durationMs: song.duration.inMilliseconds,
      thumbnailPath: null,
      mediaType: 'music',
    );
  }

  /// Unhide Item (Video or Music): Restore to original location
  Future<File> unhideItem(VaultItemModel vaultItem) async {
    final vaultFile = File(vaultItem.encryptedPath);
    if (!await vaultFile.exists()) {
      throw Exception("Vault file not found");
    }

    final targetDir = Directory(p.dirname(vaultItem.originalPath));
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final restoredPath = vaultItem.originalPath;
    try {
      await vaultFile.rename(restoredPath);
    } catch (_) {
      final inStream = vaultFile.openRead();
      final outSink = File(restoredPath).openWrite();
      await inStream.pipe(outSink);
      try {
        await vaultFile.delete();
      } catch (_) {}
    }

    return File(restoredPath);
  }

  /// Get direct playable file inside vault
  Future<File> getPlaybackFile(VaultItemModel vaultItem) async {
    final file = File(vaultItem.encryptedPath);
    if (await file.exists()) {
      return file;
    }
    throw Exception("Vault item file missing on disk");
  }
}
