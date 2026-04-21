import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sendra/core/theme.dart';
import 'package:sendra/core/constants.dart';
import 'package:sendra/screens/home_screen.dart';
import 'package:sendra/screens/signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _phoneCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();

  bool _loading = false;
  bool _pinHidden = true;
  String _errorMessage = '';

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _pinCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // Must match _authPassword() in signup_page.dart
  String _authPassword(String pin) => '${pin}_sendra';

  Future<void> _login() async {
    if (_loading) return;

    final phone = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '').trim();
    final pin = _pinCtrl.text.trim();

    if (phone.isEmpty || pin.isEmpty) {
      setState(() => _errorMessage = 'Please enter your phone number and PIN.');
      return;
    }
    if (!Validators.isValidTZPhone(phone)) {
      setState(
        () => _errorMessage =
            'Enter a valid Tanzanian phone number (e.g. 0779122997).',
      );
      return;
    }
    if (!Validators.isValidPin(pin)) {
      setState(() => _errorMessage = 'PIN must be exactly 4 digits.');
      return;
    }

    setState(() {
      _errorMessage = '';
      _loading = true;
    });

    try {
      // ── Step 1: Firebase Auth sign-in ────────────────────────────────────
      final email = '$phone@sendra.app';
      final password = _authPassword(pin);

      UserCredential credential;
      try {
        credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        setState(() {
          _errorMessage =
              (e.code == 'wrong-password' || e.code == 'invalid-credential')
              ? 'Incorrect PIN. Please try again.'
              : e.code == 'user-not-found'
              ? 'No account found with this phone number.'
              : 'Login failed. Please try again.';
          _loading = false;
        });
        return;
      }

      // ── Step 2: Load user profile from Firestore ─────────────────────────
      final uid = credential.user!.uid;
      final snap = await FirebaseFirestore.instance
          .collection(FSKeys.usersCollection)
          .doc(uid)
          .get();

      if (!mounted) return;

      if (!snap.exists) {
        await FirebaseAuth.instance.signOut();
        setState(() {
          _errorMessage = 'Account data not found. Please sign up again.';
          _loading = false;
        });
        return;
      }

      final data = snap.data()!;
      setState(() => _loading = false);
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            userId: uid,
            userName: data[FSKeys.fullName] ?? '',
            accNumber: data[FSKeys.accNumber] ?? '',
            phone: data[FSKeys.phone] ?? '',
          ),
        ),
      );
    } on FirebaseException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _friendlyMessage(e);
          _loading = false;
        });
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _errorMessage = 'Login timed out. Please try again.';
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to log in right now.';
          _loading = false;
        });
      }
    }
  }

  String _friendlyMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Permission denied. Please try again.';
      case 'unavailable':
        return 'Firebase is temporarily unavailable.';
      case 'deadline-exceeded':
        return 'The request took too long. Please try again.';
      default:
        return e.message ?? 'A database error occurred during login.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SColors.bg,
      body: Stack(
        children: [
          FadeTransition(
            opacity: _fadeAnim,
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SendraLogo(),
                    const SizedBox(height: 48),
                    _buildHeading(),
                    const SizedBox(height: 36),
                    _buildPhoneField(),
                    const SizedBox(height: 16),
                    _buildPinField(),
                    if (_errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _ErrorBox(message: _errorMessage),
                    ],
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        style: SButton.primary,
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: SColors.navy,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text('Log In', style: SButton.primaryLabel),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(AppStrings.noAccount, style: SText.caption),
                        GestureDetector(
                          onTap: _loading
                              ? null
                              : () => Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => const SignUpPage(),
                                  ),
                                ),
                          child: Text(
                            AppStrings.signUpLink,
                            style: SText.goldAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_loading)
            Positioned.fill(
              child: AbsorbPointer(
                absorbing: true,
                child: Container(
                  color: Colors.black.withOpacity(0.55),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: SColors.gold,
                          strokeWidth: 3,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Logging you in...',
                          style: TextStyle(
                            color: SColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: SColors.gold.withOpacity(0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.lock_outline_rounded,
            color: SColors.gold,
            size: 28,
          ),
        ),
        const SizedBox(height: 20),
        Text(AppStrings.welcomeBack, style: SText.heading),
        const SizedBox(height: 6),
        Text(AppStrings.loginSubtitle, style: SText.caption),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Phone Number', style: SText.label),
        const SizedBox(height: 8),
        Container(
          decoration: SDecor.inputField,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: SColors.navyLight, width: 1),
                  ),
                ),
                child: const Row(
                  children: [
                    Text('🇹🇿', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 6),
                    Text('+255', style: SText.caption),
                  ],
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _phoneCtrl,
                  enabled: !_loading,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  style: SText.body,
                  decoration: SDecor.textInput(
                    hint: AppStrings.phonePlaceholder,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPinField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PIN', style: SText.label),
        const SizedBox(height: 8),
        Container(
          decoration: SDecor.inputField,
          child: TextField(
            controller: _pinCtrl,
            obscureText: _pinHidden,
            enabled: !_loading,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            onSubmitted: (_) => _login(),
            style: const TextStyle(
              color: SColors.textPrimary,
              fontSize: 22,
              letterSpacing: 10,
              fontWeight: FontWeight.w700,
            ),
            decoration: SDecor.textInput(
              hint: '••••',
              suffix: GestureDetector(
                onTap: _loading
                    ? null
                    : () => setState(() => _pinHidden = !_pinHidden),
                child: Icon(
                  _pinHidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: _loading ? SColors.navyLight : SColors.textDim,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Shared widgets ──────────────────────────────────────────────────────────

class _SendraLogo extends StatelessWidget {
  const _SendraLogo();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [SColors.gold, SColors.goldDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(
            child: Text(
              AppStrings.logoLetter,
              style: TextStyle(
                color: SColors.navy,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(AppStrings.appName, style: SText.appBarTitle),
      ],
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: SDecor.errorBox,
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: SColors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: SText.errorText)),
        ],
      ),
    );
  }
}
