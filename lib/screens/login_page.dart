import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sendra/core/theme.dart';
import 'package:sendra/core/constants.dart';
import 'package:sendra/core/app_localizations.dart';
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

  String _authPassword(String pin) => '${pin}_sendra';

  Future<void> _login() async {
    if (_loading) return;
    final l = AppLocalizations.of(context);

    final phone =
        _phoneCtrl.text.replaceAll(RegExp(r'\D'), '').trim();
    final pin = _pinCtrl.text.trim();

    if (phone.isEmpty || pin.isEmpty) {
      setState(() => _errorMessage = l.isSwahili
          ? 'Tafadhali weka nambari ya simu na PIN.'
          : 'Please enter your phone number and PIN.');
      return;
    }
    if (!Validators.isValidTZPhone(phone)) {
      setState(() => _errorMessage = l.isSwahili
          ? 'Weka nambari sahihi ya simu ya Tanzania.'
          : 'Enter a valid Tanzanian phone number (e.g. 0779122997).');
      return;
    }
    if (!Validators.isValidPin(pin)) {
      setState(() => _errorMessage = l.pinMust4Digits);
      return;
    }

    setState(() {
      _errorMessage = '';
      _loading = true;
    });

    try {
      final email = '$phone@sendra.app';
      final password = _authPassword(pin);

      UserCredential credential;
      try {
        credential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
                email: email, password: password);
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        setState(() {
          _errorMessage = (e.code == 'wrong-password' ||
                  e.code == 'invalid-credential')
              ? l.incorrectPin
              : e.code == 'user-not-found'
                  ? l.accountNotFound
                  : l.loginFailed;
          _loading = false;
        });
        return;
      }

      final uid = credential.user!.uid;
      final snap = await FirebaseFirestore.instance
          .collection(FSKeys.usersCollection)
          .doc(uid)
          .get();

      if (!mounted) return;

      if (!snap.exists) {
        await FirebaseAuth.instance.signOut();
        setState(() {
          _errorMessage = l.isSwahili
              ? 'Data ya akaunti haikupatikana. Tafadhali jiandikishe tena.'
              : 'Account data not found. Please sign up again.';
          _loading = false;
        });
        return;
      }

      final data = snap.data()!;
      final firestorePin =
          (data[FSKeys.pin] ?? '').toString().trim();
      if (firestorePin != pin) {
        await FirebaseFirestore.instance
            .collection(FSKeys.usersCollection)
            .doc(uid)
            .update({FSKeys.pin: pin});
      }

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
          _errorMessage = _friendlyMessage(e, AppLocalizations.of(context));
          _loading = false;
        });
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _errorMessage = AppLocalizations.of(context).isSwahili
              ? 'Muda wa kuingia umekwisha. Jaribu tena.'
              : 'Login timed out. Please try again.';
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = AppLocalizations.of(context).loginFailed;
          _loading = false;
        });
      }
    }
  }

  String _friendlyMessage(
      FirebaseException e, AppLocalizations l) {
    switch (e.code) {
      case 'permission-denied':
        return l.isSwahili
            ? 'Ruhusa imekataliwa. Jaribu tena.'
            : 'Permission denied. Please try again.';
      case 'unavailable':
        return l.isSwahili
            ? 'Huduma haipatikani kwa sasa.'
            : 'Firebase is temporarily unavailable.';
      case 'deadline-exceeded':
        return l.isSwahili
            ? 'Ombi lilichukua muda mrefu. Jaribu tena.'
            : 'The request took too long. Please try again.';
      default:
        return e.message ?? l.loginFailed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? SColors.bg : SColors.lightBg;
    final textPrimary =
        isDark ? SColors.textPrimary : SColors.lightTextPrimary;
    final textSub = isDark ? SColors.textSub : SColors.lightTextSub;

    return Scaffold(
      backgroundColor: bgColor,
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
                    _SendraLogo(isDark: isDark),
                    const SizedBox(height: 48),
                    _buildHeading(l, isDark),
                    const SizedBox(height: 36),
                    _buildPhoneField(l, isDark),
                    const SizedBox(height: 16),
                    _buildPinField(l, isDark),
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
                            : Text(l.logIn,
                                style: SButton.primaryLabel),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(l.noAccount,
                            style: TextStyle(
                                color: textSub, fontSize: 13)),
                        GestureDetector(
                          onTap: _loading
                              ? null
                              : () =>
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => const SignUpPage(),
                                    ),
                                  ),
                          child: Text(
                            l.signUp,
                            style: const TextStyle(
                              color: SColors.gold,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
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
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: SColors.gold,
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l.loggingIn,
                          style: TextStyle(
                              color: textPrimary, fontSize: 14),
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

  Widget _buildHeading(AppLocalizations l, bool isDark) {
    final textPrimary =
        isDark ? SColors.textPrimary : SColors.lightTextPrimary;
    final textSub = isDark ? SColors.textSub : SColors.lightTextSub;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: SColors.gold.withOpacity(0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.lock_outline_rounded,
              color: SColors.gold, size: 28),
        ),
        const SizedBox(height: 20),
        Text(l.welcomeBack,
            style: TextStyle(
                color: textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5)),
        const SizedBox(height: 6),
        Text(l.loginSubtitle,
            style: TextStyle(color: textSub, fontSize: 13)),
      ],
    );
  }

  Widget _buildPhoneField(AppLocalizations l, bool isDark) {
    final cardColor = isDark ? SColors.navyCard : SColors.lightCard;
    final borderColor =
        isDark ? SColors.navyLight : SColors.lightBorder;
    final textPrimary =
        isDark ? SColors.textPrimary : SColors.lightTextPrimary;
    final textSub = isDark ? SColors.textSub : SColors.lightTextSub;
    final textDim = isDark ? SColors.textDim : SColors.lightTextDim;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.phoneNumber,
            style: TextStyle(
                color: textSub,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                      right: BorderSide(color: borderColor, width: 1)),
                ),
                child: Row(
                  children: [
                    const Text('🇹🇿',
                        style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text('+255',
                        style: TextStyle(
                            color: textSub, fontSize: 13)),
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
                  style: TextStyle(
                      color: textPrimary, fontSize: 15),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '07XXXXXXXX',
                    hintStyle: TextStyle(
                        color: textDim, fontSize: 15),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPinField(AppLocalizations l, bool isDark) {
    final cardColor = isDark ? SColors.navyCard : SColors.lightCard;
    final borderColor =
        isDark ? SColors.navyLight : SColors.lightBorder;
    final textPrimary =
        isDark ? SColors.textPrimary : SColors.lightTextPrimary;
    final textDim = isDark ? SColors.textDim : SColors.lightTextDim;
    final textSub = isDark ? SColors.textSub : SColors.lightTextSub;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.pin,
            style: TextStyle(
                color: textSub,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
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
            style: TextStyle(
              color: textPrimary,
              fontSize: 22,
              letterSpacing: 10,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: '••••',
              hintStyle: TextStyle(color: textDim, fontSize: 15),
              suffixIcon: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12),
                child: GestureDetector(
                  onTap: _loading
                      ? null
                      : () => setState(
                          () => _pinHidden = !_pinHidden),
                  child: Icon(
                    _pinHidden
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: _loading ? borderColor : textDim,
                    size: 18,
                  ),
                ),
              ),
              suffixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────
class _SendraLogo extends StatelessWidget {
  final bool isDark;
  const _SendraLogo({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? SColors.textPrimary : SColors.lightTextPrimary;
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
              'S',
              style: TextStyle(
                color: SColors.navy,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Sendra',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
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
          const Icon(Icons.error_outline,
              color: SColors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: SText.errorText)),
        ],
      ),
    );
  }
}