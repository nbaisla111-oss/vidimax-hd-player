import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../controllers/music_controller.dart';
import '../../controllers/vault_controller.dart';
import '../../controllers/video_controller.dart';
import '../../models/music_model.dart';
import '../../models/vault_item_model.dart';
import '../../models/video_model.dart';
import '../../utils/app_theme.dart';
import '../player/custom_video_player_screen.dart';
import '../../widgets/video_thumbnail_widget.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  String _setupStep = 'initial'; // 'initial' or 'confirm'
  String _firstEnteredPin = '';
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

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
      // Authenticate with 4-digit PIN
      final success = await vaultCtrl.unlockWithPin(_enteredPin);
      if (!success) {
        setState(() => _enteredPin = '');
      }
    } else {
      // First-time setup: Enter once, confirm once -> directly open vault!
      if (_setupStep == 'initial') {
        _firstEnteredPin = _enteredPin;
        setState(() {
          _setupStep = 'confirm';
          _enteredPin = '';
        });
      } else if (_setupStep == 'confirm') {
        if (_enteredPin == _firstEnteredPin) {
          await vaultCtrl.setupNewPin(pin: _firstEnteredPin);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Vault setup complete! Recovery Key: ${vaultCtrl.recoveryCode}'),
                duration: const Duration(seconds: 4),
              ),
            );
          }
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

  @override
  Widget build(BuildContext context) {
    final vaultCtrl = Provider.of<VaultController>(context);

    if (vaultCtrl.isUnlocked) {
      return _buildUnlockedVault(vaultCtrl);
    }

    return _buildPinLockView(vaultCtrl);
  }

  Widget _buildPinLockView(VaultController vaultCtrl) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String headerTitle = 'Private Secret Vault';
    String headerSubtitle = 'Enter 4-digit PIN to access private files';

    if (!vaultCtrl.isConfigured) {
      if (_setupStep == 'initial') {
        headerTitle = 'Create Vault PIN';
        headerSubtitle = 'Choose a secure 4-digit PIN';
      } else if (_setupStep == 'confirm') {
        headerTitle = 'Confirm PIN';
        headerSubtitle = 'Re-enter your 4-digit PIN';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Secret Vault', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryViolet.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_rounded, size: 48, color: AppTheme.primaryViolet),
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 24),
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
                  const SizedBox(height: 12),
                  Text(
                    vaultCtrl.errorMessage!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
                const SizedBox(height: 28),
                // Numeric Keypad
                _buildKeypad(),
                const SizedBox(height: 20),

                // Forgot PIN Option
                if (vaultCtrl.isConfigured)
                  TextButton.icon(
                    icon: const Icon(Icons.help_outline_rounded, size: 18, color: AppTheme.secondaryCyan),
                    label: const Text(
                      'Forgot PIN? Reset without data loss',
                      style: TextStyle(color: AppTheme.secondaryCyan, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    onPressed: () => _showForgotPinDialog(context, vaultCtrl),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        _buildKeypadRow(['1', '2', '3']),
        const SizedBox(height: 14),
        _buildKeypadRow(['4', '5', '6']),
        const SizedBox(height: 14),
        _buildKeypadRow(['7', '8', '9']),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 70, height: 60),
            _buildKeyButton('0'),
            SizedBox(
              width: 70,
              height: 60,
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
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: InkWell(
        onTap: () => _onDigitPress(digit),
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.cardDark,
            border: Border.all(color: AppTheme.borderDark),
          ),
          child: Center(
            child: Text(
              digit,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnlockedVault(VaultController vaultCtrl) {
    final videoItems = vaultCtrl.videoItems;
    final musicItems = vaultCtrl.musicItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Secret Vault', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.vpn_key_rounded, color: AppTheme.secondaryCyan),
            tooltip: 'View Master Recovery Key',
            onPressed: () => _showRecoveryKeyModal(context, vaultCtrl),
          ),
          IconButton(
            icon: const Icon(Icons.lock_rounded, color: Colors.amber),
            tooltip: 'Lock Vault',
            onPressed: () => vaultCtrl.lockVault(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryViolet,
          labelColor: AppTheme.primaryViolet,
          unselectedLabelColor: AppTheme.textMutedDark,
          tabs: [
            Tab(icon: const Icon(Icons.movie_rounded), text: 'Videos (${videoItems.length})'),
            Tab(icon: const Icon(Icons.audiotrack_rounded), text: 'Audios (${musicItems.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryViolet,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add to Vault', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showAddOptionsModal(context, vaultCtrl),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVaultItemsList(videoItems, vaultCtrl, isVideo: true),
          _buildVaultItemsList(musicItems, vaultCtrl, isVideo: false),
        ],
      ),
    );
  }

  Widget _buildVaultItemsList(List<VaultItemModel> items, VaultController vaultCtrl, {required bool isVideo}) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isVideo ? Icons.video_library_rounded : Icons.music_off_rounded,
              size: 56,
              color: AppTheme.primaryViolet.withOpacity(0.4),
            ),
            const SizedBox(height: 14),
            Text(
              isVideo ? 'No Hidden Videos' : 'No Hidden Audio Tracks',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              isVideo ? 'Tap "Add to Vault" to hide sensitive videos' : 'Tap "Add to Vault" to hide private music/recordings',
              style: const TextStyle(fontSize: 12, color: AppTheme.textMutedDark),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        final sizeMb = (item.sizeBytes / (1024 * 1024)).toStringAsFixed(1);

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderDark),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 52,
                  height: 52,
                  color: AppTheme.surfaceDark,
                  child: Icon(
                    isVideo ? Icons.lock_rounded : Icons.audiotrack_rounded,
                    color: AppTheme.primaryViolet,
                    size: 26,
                  ),
                ),
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
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$sizeMb MB • Private Storage • Hidden',
                      style: const TextStyle(fontSize: 11, color: AppTheme.accentEmerald),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.lock_open_rounded, color: AppTheme.secondaryCyan, size: 22),
                tooltip: 'Unhide & restore to gallery',
                onPressed: () async {
                  await vaultCtrl.unhideItem(item);
                  if (context.mounted) {
                    if (isVideo) {
                      Provider.of<VideoController>(context, listen: false).loadVideos();
                    } else {
                      Provider.of<MusicController>(context, listen: false).scanMusic();
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${item.originalName} restored to original folder')),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddOptionsModal(BuildContext context, VaultController vaultCtrl) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add Media to Secret Vault',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryViolet.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.movie_rounded, color: AppTheme.primaryViolet),
                  ),
                  title: const Text('Hide Video from Device', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Select video to encrypt & hide from gallery', style: TextStyle(color: AppTheme.textMutedDark, fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showHideVideoPicker(context, vaultCtrl);
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryCyan.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.audiotrack_rounded, color: AppTheme.secondaryCyan),
                  ),
                  title: const Text('Hide Audio / Music from Device', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Select music or recording to encrypt & hide', style: TextStyle(color: AppTheme.textMutedDark, fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showHideMusicPicker(context, vaultCtrl);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showHideVideoPicker(BuildContext context, VaultController vaultCtrl) {
    final videoCtrl = Provider.of<VideoController>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                child: videoCtrl.videos.isEmpty
                    ? const Center(child: Text('No videos found on device', style: TextStyle(color: AppTheme.textMutedDark)))
                    : ListView.builder(
                        itemCount: videoCtrl.videos.length,
                        itemBuilder: (context, idx) {
                          final v = videoCtrl.videos[idx];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            leading: SizedBox(
                              width: 64,
                              height: 44,
                              child: VideoThumbnailWidget(
                                videoPath: v.path,
                                width: 64,
                                height: 44,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            title: Text(v.title, maxLines: 1, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                            subtitle: Text('${v.formattedDuration} · ${v.formattedSize} · ${v.folderName}', style: const TextStyle(color: AppTheme.textMutedDark, fontSize: 11)),
                            trailing: const Icon(Icons.lock_outline_rounded, color: AppTheme.primaryViolet),
                            onTap: () async {
                              Navigator.pop(ctx);
                              await vaultCtrl.hideVideo(v);
                              videoCtrl.removeVideoLocally(v.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Video hidden safely inside Secret Vault')),
                                );
                              }
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

  void _showHideMusicPicker(BuildContext context, VaultController vaultCtrl) {
    final musicCtrl = Provider.of<MusicController>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final songs = musicCtrl.songs;
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Audio Track to Hide in Vault',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: songs.isEmpty
                    ? const Center(child: Text('No music tracks found on device', style: TextStyle(color: AppTheme.textMutedDark)))
                    : ListView.builder(
                        itemCount: songs.length,
                        itemBuilder: (context, idx) {
                          final song = songs[idx];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppTheme.secondaryCyan.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.audiotrack_rounded, color: AppTheme.secondaryCyan, size: 22),
                            ),
                            title: Text(song.title, maxLines: 1, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                            subtitle: Text('${song.artist} · ${song.formattedDuration}', style: const TextStyle(color: AppTheme.textMutedDark, fontSize: 11)),
                            trailing: const Icon(Icons.lock_outline_rounded, color: AppTheme.primaryViolet),
                            onTap: () async {
                              Navigator.pop(ctx);
                              await vaultCtrl.hideMusic(song);
                              await musicCtrl.scanMusic();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Audio track hidden safely inside Secret Vault')),
                                );
                              }
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

  void _showForgotPinDialog(BuildContext context, VaultController vaultCtrl) {
    final codeCtrl = TextEditingController();
    final newPinCtrl = TextEditingController();
    bool isKeyVerified = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: const [
                  Icon(Icons.lock_reset_rounded, color: AppTheme.secondaryCyan),
                  SizedBox(width: 10),
                  Text('Reset Vault PIN', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'All your hidden videos & audios will remain 100% safe and will NOT be deleted.',
                    style: TextStyle(color: AppTheme.accentEmerald, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 14),
                  if (!isKeyVerified) ...[
                    const Text(
                      'Enter your 6-digit Master Recovery Key (or emergency master rescue code 888888):',
                      style: TextStyle(color: AppTheme.textSecondaryDark, fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: codeCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      style: const TextStyle(color: Colors.white, letterSpacing: 4, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        hintText: '6-digit key',
                        hintStyle: TextStyle(color: Colors.white30, letterSpacing: 1),
                        border: OutlineInputBorder(),
                        counterText: '',
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'Master Key Verified! Enter new 4-digit PIN:',
                      style: TextStyle(color: AppTheme.secondaryCyan, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: newPinCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white, letterSpacing: 8, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        hintText: 'New PIN',
                        hintStyle: TextStyle(color: Colors.white30, letterSpacing: 1),
                        border: OutlineInputBorder(),
                        counterText: '',
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textMutedDark)),
                  onPressed: () => Navigator.pop(ctx),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryViolet),
                  child: Text(isKeyVerified ? 'Confirm New PIN' : 'Verify Key'),
                  onPressed: () async {
                    if (!isKeyVerified) {
                      final input = codeCtrl.text.trim();
                      if (input == '888888' || input == vaultCtrl.recoveryCode) {
                        setDialogState(() => isKeyVerified = true);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invalid Recovery Key. Try 888888 or your recovery key.')),
                        );
                      }
                    } else {
                      final newPin = newPinCtrl.text.trim();
                      if (newPin.length == 4) {
                        await vaultCtrl.resetPinWithRecoveryKey(
                          recoveryKey: codeCtrl.text.trim(),
                          newPin: newPin,
                        );
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('PIN reset successfully! Vault unlocked.')),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a 4-digit PIN')),
                        );
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRecoveryKeyModal(BuildContext context, VaultController vaultCtrl) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.vpn_key_rounded, color: AppTheme.secondaryCyan),
              SizedBox(width: 10),
              Text('Master Recovery Key', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Save this 6-digit key in a safe place. If you ever forget your PIN, you can use this key to reset it without losing any of your files.',
                style: TextStyle(color: AppTheme.textSecondaryDark, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryViolet),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      vaultCtrl.recoveryCode.isNotEmpty ? vaultCtrl.recoveryCode : '888888',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        letterSpacing: 4,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, color: AppTheme.secondaryCyan, size: 20),
                      tooltip: 'Copy Key',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: vaultCtrl.recoveryCode.isNotEmpty ? vaultCtrl.recoveryCode : '888888'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Recovery Key copied to clipboard!')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryViolet),
              child: const Text('Got it'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        );
      },
    );
  }
}
