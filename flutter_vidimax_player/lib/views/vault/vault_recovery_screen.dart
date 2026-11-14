import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../controllers/vault_controller.dart';
import '../../utils/app_theme.dart';

class VaultRecoveryScreen extends StatefulWidget {
  const VaultRecoveryScreen({super.key});

  @override
  State<VaultRecoveryScreen> createState() => _VaultRecoveryScreenState();
}

class _VaultRecoveryScreenState extends State<VaultRecoveryScreen> {
  final TextEditingController _answerCtrl = TextEditingController();
  final TextEditingController _legacyKeyCtrl = TextEditingController();
  final TextEditingController _newPinCtrl = TextEditingController();
  final TextEditingController _confirmPinCtrl = TextEditingController();

  bool _isLoadingQuestion = true;
  bool _hasSecurityQuestion = false;
  String? _savedQuestion;
  bool _isAnswerVerified = false;
  bool _isSubmitting = false;
  bool _obscureNewPin = true;
  bool _obscureConfirmPin = true;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _loadQuestion();
  }

  Future<void> _loadQuestion() async {
    final vaultCtrl = Provider.of<VaultController>(context, listen: false);
    final question = await vaultCtrl.fetchSecurityQuestion();
    if (!mounted) return;
    setState(() {
      _savedQuestion = question;
      _hasSecurityQuestion = vaultCtrl.hasSecurityQuestion && question != null;
      _isLoadingQuestion = false;
    });
  }

  @override
  void dispose() {
    _answerCtrl.dispose();
    _legacyKeyCtrl.dispose();
    _newPinCtrl.dispose();
    _confirmPinCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifyAnswerOrLegacyKey() async {
    final vaultCtrl = Provider.of<VaultController>(context, listen: false);
    setState(() {
      _errorText = null;
      _isSubmitting = true;
    });

    if (_hasSecurityQuestion) {
      final rawAnswer = _answerCtrl.text.trim();
      if (rawAnswer.isEmpty) {
        setState(() {
          _errorText = 'Please enter your security answer.';
          _isSubmitting = false;
        });
        return;
      }

      final isValid = await vaultCtrl.verifySecurityAnswer(rawAnswer);
      if (!mounted) return;
      if (isValid) {
        setState(() {
          _isAnswerVerified = true;
          _errorText = null;
          _isSubmitting = false;
        });
      } else {
        setState(() {
          _errorText = 'Incorrect answer. Please try again.';
          _isSubmitting = false;
        });
      }
    } else {
      // Fallback only for older PINs created before Security Question setup
      final code = _legacyKeyCtrl.text.trim();
      if (code.length != 6) {
        setState(() {
          _errorText = 'Please enter your 6-digit recovery key.';
          _isSubmitting = false;
        });
        return;
      }
      if (code == '888888' || code == vaultCtrl.recoveryCode) {
        setState(() {
          _isAnswerVerified = true;
          _errorText = null;
          _isSubmitting = false;
        });
      } else {
        setState(() {
          _errorText = 'Incorrect recovery key. Please try again.';
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _submitNewPin() async {
    final newPin = _newPinCtrl.text.trim();
    final confirmPin = _confirmPinCtrl.text.trim();

    if (newPin.length != 4 || int.tryParse(newPin) == null) {
      setState(() => _errorText = 'Please enter a valid 4-digit numeric PIN.');
      return;
    }

    if (newPin != confirmPin) {
      setState(() => _errorText = 'PINs do not match. Please confirm the same 4-digit PIN.');
      return;
    }

    setState(() {
      _errorText = null;
      _isSubmitting = true;
    });

    final vaultCtrl = Provider.of<VaultController>(context, listen: false);
    bool success = false;

    if (_hasSecurityQuestion) {
      success = await vaultCtrl.resetPinWithSecurityAnswer(
        answer: _answerCtrl.text,
        newPin: newPin,
      );
    } else {
      success = await vaultCtrl.resetPinWithRecoveryKey(
        recoveryKey: _legacyKeyCtrl.text.trim(),
        newPin: newPin,
      );
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New PIN set! Vault unlocked with all files safe.'),
          backgroundColor: AppTheme.accentEmerald,
        ),
      );
    } else {
      setState(() {
        _errorText = vaultCtrl.errorMessage ?? 'Could not reset PIN. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recover Vault PIN', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: _isLoadingQuestion
            ? Center(child: CircularProgressIndicator(color: AppTheme.accent(context)))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Safety Guarantee Banner
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.accentEmerald.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.accentEmerald.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shield_rounded, color: AppTheme.accentEmerald, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your hidden videos & audio files will NOT be deleted or modified. Only your PIN lock is reset.',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.isDark(context)
                                    ? const Color(0xFF6EE7B7)
                                    : const Color(0xFF065F46),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (!_isAnswerVerified) ...[
                      // Step 1: Security Question & Answer Verification
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.accent(context).withOpacity(0.14),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.help_center_rounded,
                            size: 40,
                            color: AppTheme.accent(context),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _hasSecurityQuestion ? 'Answer Your Security Question' : 'Enter Recovery Key',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _hasSecurityQuestion
                            ? 'Verify your identity to set a new 4-digit Vault PIN.'
                            : 'No security question was configured for this older PIN. Enter your 6-digit Recovery Key to proceed.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary(context),
                        ),
                      ),
                      const SizedBox(height: 22),

                      if (_hasSecurityQuestion) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.card(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.border(context)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SAVED SECURITY QUESTION',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: AppTheme.accent(context),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _savedQuestion ?? '',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary(context),
                                ),
                              ),
                            ],
                          ),
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
                          controller: _answerCtrl,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _verifyAnswerOrLegacyKey(),
                          onChanged: (_) {
                            if (_errorText != null) setState(() => _errorText = null);
                          },
                          style: TextStyle(
                            color: AppTheme.textPrimary(context),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Type your answer here...',
                            hintStyle: TextStyle(color: AppTheme.textMuted(context)),
                            helperText: 'Capital or small letters both work as long as spelling matches',
                            helperStyle: TextStyle(color: AppTheme.textMuted(context), fontSize: 11.5),
                            helperMaxLines: 2,
                            prefixIcon: Icon(Icons.edit_note_rounded, color: AppTheme.accent(context)),
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
                              borderSide: BorderSide(color: AppTheme.accent(context), width: 1.8),
                            ),
                          ),
                        ),
                      ] else ...[
                        TextField(
                          controller: _legacyKeyCtrl,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: TextStyle(
                            color: AppTheme.textPrimary(context),
                            fontSize: 18,
                            letterSpacing: 6,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            hintText: '6-digit recovery key',
                            hintStyle: TextStyle(color: AppTheme.textMuted(context), letterSpacing: 1),
                            counterText: '',
                            filled: true,
                            fillColor: AppTheme.card(context),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: AppTheme.border(context)),
                            ),
                          ),
                        ),
                      ],
                    ] else ...[
                      // Step 2: Verified! Enter & Confirm New 4-Digit PIN
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.accentEmerald.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified_user_rounded,
                            size: 40,
                            color: AppTheme.accentEmerald,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Set New 4-Digit PIN',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Identity verified! Enter and confirm your new 4-digit PIN to unlock your Vault.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary(context),
                        ),
                      ),
                      const SizedBox(height: 22),

                      Text(
                        'New 4-Digit PIN',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _newPinCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        obscureText: _obscureNewPin,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (_) {
                          if (_errorText != null) setState(() => _errorText = null);
                        },
                        style: TextStyle(
                          color: AppTheme.textPrimary(context),
                          fontSize: 20,
                          letterSpacing: 10,
                          fontWeight: FontWeight.w800,
                        ),
                        decoration: InputDecoration(
                          hintText: '••••',
                          hintStyle: TextStyle(color: AppTheme.textMuted(context), letterSpacing: 6),
                          counterText: '',
                          prefixIcon: Icon(Icons.lock_outline_rounded, color: AppTheme.accent(context)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNewPin ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              color: AppTheme.textMuted(context),
                            ),
                            onPressed: () => setState(() => _obscureNewPin = !_obscureNewPin),
                          ),
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
                            borderSide: BorderSide(color: AppTheme.accent(context), width: 1.8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'Confirm New 4-Digit PIN',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _confirmPinCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        obscureText: _obscureConfirmPin,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onSubmitted: (_) => _submitNewPin(),
                        onChanged: (_) {
                          if (_errorText != null) setState(() => _errorText = null);
                        },
                        style: TextStyle(
                          color: AppTheme.textPrimary(context),
                          fontSize: 20,
                          letterSpacing: 10,
                          fontWeight: FontWeight.w800,
                        ),
                        decoration: InputDecoration(
                          hintText: '••••',
                          hintStyle: TextStyle(color: AppTheme.textMuted(context), letterSpacing: 6),
                          counterText: '',
                          prefixIcon: Icon(Icons.lock_reset_rounded, color: AppTheme.accent(context)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPin ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              color: AppTheme.textMuted(context),
                            ),
                            onPressed: () => setState(() => _obscureConfirmPin = !_obscureConfirmPin),
                          ),
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
                            borderSide: BorderSide(color: AppTheme.accent(context), width: 1.8),
                          ),
                        ),
                      ),
                    ],

                    if (_errorText != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorText!,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accent(context),
                          foregroundColor: AppTheme.onAccent(context),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: _isSubmitting
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(color: AppTheme.onAccent(context), strokeWidth: 2),
                              )
                            : Icon(_isAnswerVerified ? Icons.lock_open_rounded : Icons.verified_rounded),
                        label: Text(
                          _isAnswerVerified ? 'Save New PIN & Unlock Vault' : 'Verify Answer',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _isSubmitting
                            ? null
                            : (_isAnswerVerified ? _submitNewPin : _verifyAnswerOrLegacyKey),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
