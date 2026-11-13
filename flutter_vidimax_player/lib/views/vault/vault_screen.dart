import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/music_controller.dart';
import '../../controllers/vault_controller.dart';
import '../../controllers/video_controller.dart';
import '../../models/vault_item_model.dart';
import '../../models/video_model.dart';
import '../../services/vault_encryption_service.dart';
import '../../utils/app_theme.dart';
import '../player/custom_video_player_screen.dart';
import '../../widgets/video_thumbnail_widget.dart';
import 'vault_recovery_screen.dart';

class VaultScreen extends StatefulWidget {
  final bool embedded;
  const VaultScreen({super.key, this.embedded = false});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  String _setupStep = 'initial'; // 'initial', 'confirm', 'security_question'
  String _firstEnteredPin = '';
  String _selectedQuestion = VaultEncryptionService.defaultSecurityQuestions.first;
  final TextEditingController _securityAnswerCtrl = TextEditingController();
  String? _setupAnswerError;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _securityAnswerCtrl.dispose();
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
      final success = await vaultCtrl.unlockWithPin(_enteredPin);
      if (!success) {
        setState(() => _enteredPin = '');
      }
    } else {
      if (_setupStep == 'initial') {
        _firstEnteredPin = _enteredPin;
        setState(() {
          _setupStep = 'confirm';
          _enteredPin = '';
        });
      } else if (_setupStep == 'confirm') {
        if (_enteredPin == _firstEnteredPin) {
          setState(() {
            _setupStep = 'security_question';
            _enteredPin = '';
            _setupAnswerError = null;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PIN does not match. Try again.')),
          );
          setState(() {
            _setupStep = 'initial';
            _firstEnteredPin = '';
            _enteredPin = '';
          });
        }
      }
    }
  }

  Future<void> _completeSecurityQuestionSetup(VaultController vaultCtrl) async {
    final trimmedAnswer = _securityAnswerCtrl.text.trim();
    if (trimmedAnswer.isEmpty) {
      setState(() => _setupAnswerError = 'Please enter an answer for your security question.');
      return;
    }

    await vaultCtrl.setupNewPin(
      pin: _firstEnteredPin,
      securityQuestion: _selectedQuestion,
      securityAnswer: trimmedAnswer,
    );

    if (mounted) {
      _securityAnswerCtrl.clear();
      setState(() {
        _setupStep = 'initial';
        _firstEnteredPin = '';
        _enteredPin = '';
        _setupAnswerError = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vault PIN & Security Question saved! Vault unlocked.'),
          backgroundColor: AppTheme.accentEmerald,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vaultCtrl = Provider.of<VaultController>(context);

    if (vaultCtrl.isUnlocked) {
      return _buildUnlockedVault(vaultCtrl);
    }

    if (!vaultCtrl.isConfigured && _setupStep == 'security_question') {
      return _buildSecurityQuestionSetupView(vaultCtrl);
    }

    return _buildPinLockView(vaultCtrl);
  }

  Widget _buildSecurityQuestionSetupView(VaultController vaultCtrl) {
    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text('Security Question Setup', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryViolet.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.security_rounded, size: 42, color: AppTheme.primaryViolet),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Set Security Question',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary(context),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose a security question so you can reset your PIN anytime without losing your hidden files.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary(context),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Select Security Question',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary(context),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedQuestion,
                isExpanded: true,
                dropdownColor: AppTheme.surface(context),
                style: TextStyle(
                  color: AppTheme.textPrimary(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppTheme.card(context),
                  prefixIcon: const Icon(Icons.quiz_outlined, color: AppTheme.primaryViolet),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppTheme.border(context)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppTheme.border(context)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.primaryViolet, width: 1.8),
                  ),
                ),
                items: VaultEncryptionService.defaultSecurityQuestions
                    .map(
                      (q) => DropdownMenuItem<String>(
                        value: q,
                        child: Text(q, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedQuestion = val);
                  }
                },
              ),
              const SizedBox(height: 18),
              Text(
                'Your Answer',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary(context),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _securityAnswerCtrl,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _completeSecurityQuestionSetup(vaultCtrl),
                onChanged: (_) {
                  if (_setupAnswerError != null) {
                    setState(() => _setupAnswerError = null);
                  }
                },
                style: TextStyle(
                  color: AppTheme.textPrimary(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter your secret answer...',
                  hintStyle: TextStyle(color: AppTheme.textMuted(context)),
                  helperText: 'Spelling matters, not capital/small letters (e.g. "Rocky" = "rocky")',
                  helperStyle: TextStyle(color: AppTheme.textMuted(context), fontSize: 11.5),
                  helperMaxLines: 2,
                  prefixIcon: const Icon(Icons.edit_note_rounded, color: AppTheme.secondaryCyan),
                  filled: true,
                  fillColor: AppTheme.card(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppTheme.border(context)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppTheme.border(context)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.primaryViolet, width: 1.8),
                  ),
                ),
              ),
              if (_setupAnswerError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _setupAnswerError!,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryViolet,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text(
                    'Complete Setup & Open Vault',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  onPressed: vaultCtrl.isLoading ? null : () => _completeSecurityQuestionSetup(vaultCtrl),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  setState(() {
                    _setupStep = 'initial';
                    _firstEnteredPin = '';
                    _enteredPin = '';
                    _setupAnswerError = null;
                  });
                },
                child: Text(
                  'Change PIN Instead',
                  style: TextStyle(color: AppTheme.textMuted(context), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinLockView(VaultController vaultCtrl) {
    String headerTitle = 'Private Secret Vault';
    String headerSubtitle = 'Enter 4-digit PIN to access private files';

    if (!vaultCtrl.isConfigured) {
      if (_setupStep == 'initial') {
        headerTitle = 'Create Vault PIN';
        headerSubtitle = 'Step 1 of 2: Choose a secure 4-digit PIN';
      } else if (_setupStep == 'confirm') {
        headerTitle = 'Confirm PIN';
        headerSubtitle = 'Step 1 of 2: Re-enter your 4-digit PIN';
      }
    }

    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text('Secret Vault', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryViolet.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_rounded, size: 44, color: AppTheme.primaryViolet),
                ),
                const SizedBox(height: 16),
                Text(
                  headerTitle,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  headerSubtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary(context),
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
                          color: isFilled ? AppTheme.primaryViolet : AppTheme.border(context),
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
                // Clearly visible Forgot PIN? button right below the 4-digit PIN input field
                if (vaultCtrl.isConfigured) ...[
                  const SizedBox(height: 10),
                  TextButton.icon(
                    icon: const Icon(Icons.help_outline_rounded, size: 18, color: AppTheme.secondaryCyan),
                    label: const Text(
                      'Forgot PIN?',
                      style: TextStyle(
                        color: AppTheme.secondaryCyan,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    onPressed: () {
                      setState(() => _enteredPin = '');
                      vaultCtrl.clearError();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const VaultRecoveryScreen(),
                        ),
                      );
                    },
                  ),
                ] else
                  const SizedBox(height: 14),
                const SizedBox(height: 12),
                // Numeric Keypad
                _buildKeypad(),
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
                icon: Icon(Icons.backspace_rounded, color: AppTheme.textSecondary(context), size: 24),
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
            color: AppTheme.card(context),
            border: Border.all(color: AppTheme.border(context)),
          ),
          child: Center(
            child: Text(
              digit,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary(context),
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
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text('Secret Vault', style: TextStyle(fontWeight: FontWeight.bold)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.security_rounded, color: AppTheme.secondaryCyan),
                  tooltip: 'Security Question Settings',
                  onPressed: () => _showSecuritySettingsDialog(context, vaultCtrl),
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
                unselectedLabelColor: AppTheme.textMuted(context),
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
      body: Column(
        children: [
          if (widget.embedded)
            Container(
              color: AppTheme.surface(context),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 10, 4),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_user_rounded, color: AppTheme.accentEmerald, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Vault Unlocked',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.textPrimary(context),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.security_rounded, color: AppTheme.secondaryCyan, size: 20),
                          tooltip: 'Security Question Settings',
                          onPressed: () => _showSecuritySettingsDialog(context, vaultCtrl),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.lock_rounded, color: Colors.amber, size: 18),
                          label: const Text('Lock', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                          onPressed: () => vaultCtrl.lockVault(),
                        ),
                      ],
                    ),
                  ),
                  TabBar(
                    controller: _tabController,
                    indicatorColor: AppTheme.primaryViolet,
                    labelColor: AppTheme.primaryViolet,
                    unselectedLabelColor: AppTheme.textMuted(context),
                    tabs: [
                      Tab(text: 'Videos (${videoItems.length})'),
                      Tab(text: 'Audios (${musicItems.length})'),
                    ],
                  ),
                ],
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildVaultItemsList(videoItems, vaultCtrl, isVideo: true),
                _buildVaultItemsList(musicItems, vaultCtrl, isVideo: false),
              ],
            ),
          ),
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isVideo
                  ? 'Tap "Add to Vault" to hide sensitive videos'
                  : 'Tap "Add to Vault" to hide private music/recordings',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted(context)),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 84),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        final sizeMb = (item.sizeBytes / (1024 * 1024)).toStringAsFixed(1);

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (isVideo) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CustomVideoPlayerScreen(
                    video: VideoModel(
                      id: item.id,
                      title: item.originalName,
                      path: item.encryptedPath,
                      sizeBytes: item.sizeBytes,
                      durationMs: item.durationMs,
                      resolution: 'Vault Secure',
                      dateModified: item.dateAdded,
                      folderName: 'Private Vault',
                    ),
                    isVaultPlayback: true,
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Playing private audio: ${item.originalName}')),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.card(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border(context)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 52,
                    height: 52,
                    color: AppTheme.primaryViolet.withOpacity(0.12),
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
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary(context),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$sizeMb MB • Private Storage • Hidden',
                        style: const TextStyle(fontSize: 11, color: AppTheme.accentEmerald, fontWeight: FontWeight.w600),
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
          ),
        );
      },
    );
  }

  void _showAddOptionsModal(BuildContext context, VaultController vaultCtrl) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Media to Secret Vault',
                  style: TextStyle(
                    color: AppTheme.textPrimary(ctx),
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
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
                  title: Text(
                    'Hide Video from Device',
                    style: TextStyle(color: AppTheme.textPrimary(ctx), fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Select video to encrypt & hide from gallery',
                    style: TextStyle(color: AppTheme.textMuted(ctx), fontSize: 12),
                  ),
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
                  title: Text(
                    'Hide Audio / Music from Device',
                    style: TextStyle(color: AppTheme.textPrimary(ctx), fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Select music or recording to encrypt & hide',
                    style: TextStyle(color: AppTheme.textMuted(ctx), fontSize: 12),
                  ),
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
      backgroundColor: AppTheme.surface(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Video to Hide in Vault',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(ctx)),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: videoCtrl.videos.isEmpty
                    ? Center(
                        child: Text(
                          'No videos found on device',
                          style: TextStyle(color: AppTheme.textMuted(ctx)),
                        ),
                      )
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
                            title: Text(
                              v.title,
                              maxLines: 1,
                              style: TextStyle(
                                color: AppTheme.textPrimary(ctx),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Text(
                              '${v.formattedDuration} · ${v.formattedSize} · ${v.folderName}',
                              style: TextStyle(color: AppTheme.textMuted(ctx), fontSize: 11),
                            ),
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
      backgroundColor: AppTheme.surface(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final songs = musicCtrl.songs;
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Audio Track to Hide in Vault',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(ctx)),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: songs.isEmpty
                    ? Center(
                        child: Text(
                          'No music tracks found on device',
                          style: TextStyle(color: AppTheme.textMuted(ctx)),
                        ),
                      )
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
                            title: Text(
                              song.title,
                              maxLines: 1,
                              style: TextStyle(
                                color: AppTheme.textPrimary(ctx),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Text(
                              '${song.artist} · ${song.formattedDuration}',
                              style: TextStyle(color: AppTheme.textMuted(ctx), fontSize: 11),
                            ),
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

  void _showSecuritySettingsDialog(BuildContext context, VaultController vaultCtrl) {
    String selectedQuestion = vaultCtrl.securityQuestion != null &&
            VaultEncryptionService.defaultSecurityQuestions.contains(vaultCtrl.securityQuestion)
        ? vaultCtrl.securityQuestion!
        : VaultEncryptionService.defaultSecurityQuestions.first;
    final answerCtrl = TextEditingController();
    String? errorMsg;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surface(context),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.security_rounded, color: AppTheme.secondaryCyan),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Security Question',
                      style: TextStyle(
                        color: AppTheme.textPrimary(context),
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (vaultCtrl.hasSecurityQuestion && vaultCtrl.securityQuestion != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.accentEmerald.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.accentEmerald.withOpacity(0.35)),
                        ),
                        child: Text(
                          'Current question:\n${vaultCtrl.securityQuestion}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textPrimary(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    Text(
                      'Update Security Question & Answer:',
                      style: TextStyle(
                        color: AppTheme.textSecondary(context),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedQuestion,
                      isExpanded: true,
                      dropdownColor: AppTheme.surface(context),
                      style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 13),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: VaultEncryptionService.defaultSecurityQuestions
                          .map(
                            (q) => DropdownMenuItem<String>(
                              value: q,
                              child: Text(q, overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedQuestion = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: answerCtrl,
                      style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Enter new answer...',
                        hintStyle: TextStyle(color: AppTheme.textMuted(context)),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    if (errorMsg != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        errorMsg!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Cancel', style: TextStyle(color: AppTheme.textMuted(context))),
                  onPressed: () => Navigator.pop(ctx),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryViolet,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                  onPressed: () async {
                    final ans = answerCtrl.text.trim();
                    if (ans.isEmpty) {
                      setDialogState(() => errorMsg = 'Please enter a security answer.');
                      return;
                    }
                    await vaultCtrl.updateSecurityQuestion(
                      question: selectedQuestion,
                      answer: ans,
                    );
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Security question updated securely!')),
                      );
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
}
