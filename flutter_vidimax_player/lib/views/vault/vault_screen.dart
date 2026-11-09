import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/vault_controller.dart';
import '../../controllers/video_controller.dart';
import '../../models/vault_item_model.dart';
import '../../models/video_model.dart';
import '../../utils/app_theme.dart';
import '../player/custom_video_player_screen.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  String _enteredPin = '';
  String _setupStep = 'initial'; // initial, confirm, security
  String _firstEnteredPin = '';
  final TextEditingController _questionCtrl = TextEditingController(text: 'What was the name of your first school?');
  final TextEditingController _answerCtrl = TextEditingController();

  void _onDigitPress(String digit) {
    if (_enteredPin.length < 4) {
      setState(() => _enteredPin += digit);
      if (_enteredPin.length == 4) {
        _handlePinComplete();
      }
    }
  }

  void _onDeletePress() {
    if (_enteredPin.isNotEmpty) {
      setState(() => _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1));
    }
  }

  Future<void> _handlePinComplete() async {
    final vaultCtrl = Provider.of<VaultController>(context, listen: false);

    if (vaultCtrl.isConfigured) {
      // Authenticate
      final success = await vaultCtrl.unlockWithPin(_enteredPin);
      if (!success) {
        setState(() => _enteredPin = '');
      }
    } else {
      // First-time setup flow
      if (_setupStep == 'initial') {
        _firstEnteredPin = _enteredPin;
        setState(() {
          _setupStep = 'confirm';
          _enteredPin = '';
        });
      } else if (_setupStep == 'confirm') {
        if (_enteredPin == _firstEnteredPin) {
          setState(() {
            _setupStep = 'security';
            _enteredPin = '';
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PIN does not match. Try again.')),
          );
          setState(() {
            _setupStep = 'initial';
            _enteredPin = '';
          });
        }
      }
    }
  }

  void _saveSecurityAndFinish() {
    if (_answerCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a security answer for recovery')),
      );
      return;
    }

    final vaultCtrl = Provider.of<VaultController>(context, listen: false);
    vaultCtrl.setupNewPin(
      pin: _firstEnteredPin,
      question: _questionCtrl.text.trim(),
      answer: _answerCtrl.text.trim(),
    );
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    _answerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vaultCtrl = Provider.of<VaultController>(context);

    if (vaultCtrl.isUnlocked) {
      return _buildUnlockedVault(vaultCtrl);
    }

    if (_setupStep == 'security') {
      return _buildSecurityRecoveryView();
    }

    return _buildPinLockView(vaultCtrl);
  }

  Widget _buildPinLockView(VaultController vaultCtrl) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String headerTitle = 'Private Secret Vault';
    String headerSubtitle = 'Enter 4-digit PIN to access locked videos';

    if (!vaultCtrl.isConfigured) {
      if (_setupStep == 'initial') {
        headerTitle = 'Create Vault PIN';
        headerSubtitle = 'Choose a secure 4-digit master PIN';
      } else if (_setupStep == 'confirm') {
        headerTitle = 'Confirm PIN';
        headerSubtitle = 'Re-enter your 4-digit master PIN';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Secret Vault', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.primaryViolet.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_rounded, size: 48, color: AppTheme.primaryViolet),
            ),
            const SizedBox(height: 20),
            Text(
              headerTitle,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              headerSubtitle,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppTheme.textMutedDark : AppTheme.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 32),
            // PIN Dots Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _enteredPin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? AppTheme.primaryViolet : Colors.transparent,
                    border: Border.all(
                      color: isFilled ? AppTheme.primaryViolet : AppTheme.borderDark,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
            if (vaultCtrl.errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                vaultCtrl.errorMessage!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 40),
            // Numeric Keypad
            _buildKeypad(),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        _buildKeypadRow(['1', '2', '3']),
        const SizedBox(height: 16),
        _buildKeypadRow(['4', '5', '6']),
        const SizedBox(height: 16),
        _buildKeypadRow(['7', '8', '9']),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 80, height: 70),
            _buildKeyButton('0'),
            SizedBox(
              width: 80,
              height: 70,
              child: IconButton(
                icon: const Icon(Icons.backspace_rounded, color: AppTheme.textSecondaryDark, size: 24),
                onPressed: _onDeletePress,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeypadRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: digits.map((d) => _buildKeyButton(d)).toList(),
    );
  }

  Widget _buildKeyButton(String digit) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: () => _onDigitPress(digit),
        borderRadius: BorderRadius.circular(35),
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.cardDark,
            border: Border.all(color: AppTheme.borderDark),
          ),
          child: Center(
            child: Text(
              digit,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityRecoveryView() {
    return Scaffold(
      appBar: AppBar(title: const Text('Recovery Setup')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Security Question for Recovery',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'Used to reset your PIN if you ever forget it. Stored strictly offline in encrypted storage.',
              style: TextStyle(fontSize: 13, color: AppTheme.textMutedDark),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _questionCtrl,
              decoration: const InputDecoration(
                labelText: 'Security Question',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _answerCtrl,
              decoration: const InputDecoration(
                labelText: 'Your Secret Answer',
                border: OutlineInputBorder(),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saveSecurityAndFinish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryViolet,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Complete Vault Setup', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnlockedVault(VaultController vaultCtrl) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vault (Unlocked)', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_rounded, color: Colors.amber),
            tooltip: 'Lock Vault',
            onPressed: () => vaultCtrl.lockVault(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryViolet,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Hide Video', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showHideVideoPicker(context, vaultCtrl),
      ),
      body: vaultCtrl.vaultItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield_rounded, size: 64, color: AppTheme.primaryViolet.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text(
                    'No Hidden Videos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tap "Hide Video" to lock and encrypt sensitive files',
                    style: TextStyle(fontSize: 13, color: AppTheme.textMutedDark),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: vaultCtrl.vaultItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = vaultCtrl.vaultItems[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderDark),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryViolet.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.lock_outline_rounded, color: AppTheme.primaryViolet),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.originalName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'AES-256 Encrypted · Hidden from gallery',
                              style: TextStyle(fontSize: 11, color: AppTheme.accentEmerald),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.lock_open_rounded, color: AppTheme.secondaryCyan),
                        tooltip: 'Unhide & restore to gallery',
                        onPressed: () async {
                          await vaultCtrl.unhideVideo(item);
                          Provider.of<VideoController>(context, listen: false).loadVideos();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Video decrypted and restored to gallery')),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _showHideVideoPicker(BuildContext context, VaultController vaultCtrl) {
    final videoCtrl = Provider.of<VideoController>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Video to Hide in Vault',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: videoCtrl.videos.length,
                  itemBuilder: (context, idx) {
                    final v = videoCtrl.videos[idx];
                    return ListTile(
                      title: Text(v.title, maxLines: 1, style: const TextStyle(color: Colors.white)),
                      subtitle: Text('${v.formattedSize} · ${v.folderName}', style: const TextStyle(color: AppTheme.textMutedDark)),
                      trailing: const Icon(Icons.lock_outline_rounded, color: AppTheme.primaryViolet),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await vaultCtrl.hideVideo(v);
                        videoCtrl.removeVideoLocally(v.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Video encrypted & hidden inside Vault')),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
