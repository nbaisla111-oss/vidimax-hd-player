import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vault_item_model.dart';
import '../models/video_model.dart';
import '../services/vault_encryption_service.dart';

class VaultController extends ChangeNotifier {
  final VaultEncryptionService _vaultService = VaultEncryptionService();

  bool _isConfigured = false;
  bool _isUnlocked = false;
  String _activePin = '';
  List<VaultItemModel> _vaultItems = [];
  bool _isLoading = false;
  String? _errorMessage;

  bool get isConfigured => _isConfigured;
  bool get isUnlocked => _isUnlocked;
  List<VaultItemModel> get vaultItems => _vaultItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get activePin => _activePin;

  Future<void> checkStatus() async {
    _isConfigured = await _vaultService.isVaultConfigured();
    notifyListeners();
  }

  Future<void> setupNewPin({
    required String pin,
    required String question,
    required String answer,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _vaultService.setupPin(pin: pin, securityQuestion: question, securityAnswer: answer);
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
      await _loadVaultItemsFromPrefs();
    } else {
      _errorMessage = 'Incorrect PIN. Please try again.';
    }
    _isLoading = false;
    notifyListeners();
    return isValid;
  }

  void lockVault() {
    _isUnlocked = false;
    _activePin = '';
    notifyListeners();
  }

  Future<void> hideVideo(VideoModel video) async {
    if (!_isUnlocked || _activePin.isEmpty) return;
    _isLoading = true;
    notifyListeners();

    try {
      final vaultItem = await _vaultService.hideVideo(video, _activePin);
      _vaultItems.add(vaultItem);
      await _saveVaultItemsToPrefs();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> unhideVideo(VaultItemModel item) async {
    if (!_isUnlocked || _activePin.isEmpty) return;
    _isLoading = true;
    notifyListeners();

    try {
      await _vaultService.unhideVideo(item, _activePin);
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
