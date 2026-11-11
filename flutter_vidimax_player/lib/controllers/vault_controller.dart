import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/music_model.dart';
import '../models/vault_item_model.dart';
import '../models/video_model.dart';
import '../services/vault_encryption_service.dart';

class VaultController extends ChangeNotifier {
  final VaultEncryptionService _vaultService = VaultEncryptionService();

  bool _isConfigured = false;
  bool _isUnlocked = false;
  String _activePin = '';
  String _recoveryCode = '';
  List<VaultItemModel> _vaultItems = [];
  bool _isLoading = false;
  String? _errorMessage;

  bool get isConfigured => _isConfigured;
  bool get isUnlocked => _isUnlocked;
  List<VaultItemModel> get vaultItems => _vaultItems;
  List<VaultItemModel> get videoItems => _vaultItems.where((i) => i.mediaType == 'video').toList();
  List<VaultItemModel> get musicItems => _vaultItems.where((i) => i.mediaType == 'music').toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get activePin => _activePin;
  String get recoveryCode => _recoveryCode;

  Future<void> checkStatus() async {
    _isConfigured = await _vaultService.isVaultConfigured();
    if (_isConfigured) {
      _recoveryCode = await _vaultService.getRecoveryCode();
    }
    notifyListeners();
  }

  Future<void> setupNewPin({required String pin}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _recoveryCode = await _vaultService.setupPin(pin: pin);
      _isConfigured = true;
      _activePin = pin;
      _isUnlocked = true;
      await _loadVaultItemsFromPrefs();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> unlockWithPin(String pin) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final isValid = await _vaultService.verifyPin(pin);
    if (isValid) {
      _activePin = pin;
      _isUnlocked = true;
      _recoveryCode = await _vaultService.getRecoveryCode();
      await _loadVaultItemsFromPrefs();
    } else {
      _errorMessage = 'Incorrect PIN. Try again.';
    }
    _isLoading = false;
    notifyListeners();
    return isValid;
  }

  Future<bool> resetPinWithRecoveryKey({
    required String recoveryKey,
    required String newPin,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final isValidKey = await _vaultService.verifyRecoveryCode(recoveryKey);
      if (!isValidKey) {
        _errorMessage = 'Invalid Recovery Key';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      await _vaultService.resetPinWithRecoveryCode(newPin: newPin);
      _activePin = newPin;
      _isUnlocked = true;
      _isConfigured = true;
      _recoveryCode = await _vaultService.getRecoveryCode();
      await _loadVaultItemsFromPrefs();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void lockVault() {
    _isUnlocked = false;
    _activePin = '';
    notifyListeners();
  }

  Future<void> hideVideo(VideoModel video) async {
    _isLoading = true;
    notifyListeners();

    try {
      final vaultItem = await _vaultService.hideVideo(video);
      _vaultItems.add(vaultItem);
      await _saveVaultItemsToPrefs();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> hideMusic(MusicModel song) async {
    _isLoading = true;
    notifyListeners();

    try {
      final vaultItem = await _vaultService.hideMusic(song);
      _vaultItems.add(vaultItem);
      await _saveVaultItemsToPrefs();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> unhideItem(VaultItemModel item) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _vaultService.unhideItem(item);
      _vaultItems.removeWhere((v) => v.id == item.id);
      await _saveVaultItemsToPrefs();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadVaultItemsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('vidimax_vault_items_list');
    if (jsonString != null && jsonString.isNotEmpty) {
      final List decoded = jsonDecode(jsonString);
      _vaultItems = decoded.map((e) => VaultItemModel.fromJson(e)).toList();
    } else {
      _vaultItems = [];
    }
  }

  Future<void> _saveVaultItemsToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _vaultItems.map((e) => e.toJson()).toList();
    await prefs.setString('vidimax_vault_items_list', jsonEncode(jsonList));
  }
}
