import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sendra/core/theme.dart';
import 'package:sendra/core/constants.dart';
import 'package:sendra/screens/login_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage>
    with SingleTickerProviderStateMixin {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _confirmPinCtrl = TextEditingController();

  int _step = 0;
  bool _loading = false;
  bool _pinHidden = true;
  bool _confirmPinHidden = true;
  String _errorMessage = '';
  String _generatedAccNumber = '';

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
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _pinCtrl.dispose();
    _confirmPinCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  String get _normalizedPhone =>
      _phoneCtrl.text.replaceAll(RegExp(r'\D'), '').trim();

  // Firebase Auth requires min 6 chars — pad PIN consistently in both files
  String _authPassword(String pin) => '${pin}_sendra';

  // ── Step 1: validate + check phone uniqueness ─────────────────────────────
  Future<void> _proceedToPin() async {
    if (_loading) return;

    final first = _firstNameCtrl.text.trim();
    final last = _lastNameCtrl.text.trim();
    final phone = _normalizedPhone;

    if (first.isEmpty || last.isEmpty) {
      setState(() => _errorMessage = 'Please enter your first and last name.');
      return;
    }
    if (!Validators.isValidTZPhone(phone)) {
      setState(() => _errorMessage = 'Enter a valid Tanzanian phone number.');
      return;
    }

    setState(() {
      _errorMessage = '';
      _loading = true;
    });

    try {
      final snap = await FirebaseFirestore.instance
          .collection(FSKeys.usersCollection)
          .where(FSKeys.phone, isEqualTo: phone)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (snap.docs.isNotEmpty) {
        setState(() {
          _errorMessage = 'This phone number is already registered.';
          _loading = false;
        });
        return;
      }

      final accNumber = await _generateUniqueAccNumber();
      if (!mounted) return;

      setState(() {
        _step = 1;
        _generatedAccNumber = accNumber;
        _loading = false;
      });
      _animCtrl
        ..reset()
        ..forward();
    } on _SignUpFlowException catch (e) {
      if (mounted)
        setState(() {
          _errorMessage = e.message;
          _loading = false;
        });
    } on FirebaseException catch (e) {
      if (mounted)
        setState(() {
          _errorMessage = _friendlyMessage(e);
          _loading = false;
        });
    } on TimeoutException {
      if (mounted)
        setState(() {
          _errorMessage = 'Request timed out. Please try again.';
          _loading = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _errorMessage = 'Unable to continue right now.';
          _loading = false;
        });
    }
  }

  // ── Step 2: create Firebase Auth account + Firestore document ─────────────
  Future<void> _createAccount() async {
    if (_loading) return;

    final pin = _pinCtrl.text.trim();
    final confirm = _confirmPinCtrl.text.trim();
    final phone = _normalizedPhone;

    if (!Validators.isValidPin(pin)) {
      setState(() => _errorMessage = 'PIN must be exactly 4 digits.');
      return;
    }
    if (pin != confirm) {
      setState(() => _errorMessage = 'PINs do not match.');
      return;
    }

    setState(() {
      _errorMessage = '';
      _loading = true;
    });

    UserCredential? credential;

    try {
      final firstName = _firstNameCtrl.text.trim();
      final lastName = _lastNameCtrl.text.trim();
      final accNumber = _generatedAccNumber.isNotEmpty
          ? _generatedAccNumber
          : await _generateUniqueAccNumber();

      final email = '$phone@sendra.app';
      final password = _authPassword(pin);

      try {
        credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        throw _SignUpFlowException(
          e.code == 'email-already-in-use'
              ? 'This phone number is already registered.'
              : 'Could not create account: ${e.message}',
        );
      }

      final uid = credential.user!.uid;

      await FirebaseFirestore.instance
          .collection(FSKeys.usersCollection)
          .doc(uid)
          .set({
            FSKeys.firstName: firstName,
            FSKeys.lastName: lastName,
            FSKeys.fullName: '$firstName $lastName',
            FSKeys.phone: phone,
            FSKeys.accNumber: accNumber,
            FSKeys.pin: pin,
            FSKeys.balanceTzs: 0,
            FSKeys.balanceUsdt: 0.0,
            FSKeys.createdAt: FieldValue.serverTimestamp(),
          })
          .timeout(const Duration(seconds: 15));

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      setState(() => _loading = false);
      _showSuccessDialog(accNumber);
    } on _SignUpFlowException catch (e) {
      await credential?.user?.delete();
      if (mounted)
        setState(() {
          _loading = false;
          _errorMessage = e.message;
          _generatedAccNumber = '';
        });
    } on FirebaseException catch (e) {
      await credential?.user?.delete();
      if (mounted)
        setState(() {
          _loading = false;
          _errorMessage = _friendlyMessage(e);
        });
    } on TimeoutException {
      await credential?.user?.delete();
      if (mounted)
        setState(() {
          _loading = false;
          _errorMessage = 'Signup timed out. Check your connection.';
        });
    } catch (_) {
      await credential?.user?.delete();
      if (mounted)
        setState(() {
          _loading = false;
          _errorMessage = 'Unable to create the account right now.';
        });
    }
  }

  Future<String> _generateUniqueAccNumber() async {
    final users = FirebaseFirestore.instance.collection(FSKeys.usersCollection);
    final random = Random();

    for (var i = 0; i < 25; i++) {
      final candidate = (10000 + random.nextInt(90000)).toString();
      final snap = await users
          .where(FSKeys.accNumber, isEqualTo: candidate)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 15));
      if (snap.docs.isEmpty) return candidate;
    }
    throw const _SignUpFlowException(
      'Could not reserve a Sendra ID. Please try again.',
    );
  }

  String _friendlyMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Permission denied. Please try again.';
      case 'unavailable':
        return 'Firebase is temporarily unavailable.';
      case 'deadline-exceeded':
        return 'Request took too long. Please try again.';
      default:
        return e.message ?? 'A database error occurred.';
    }
  }

  void _showSuccessDialog(String accNumber) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: SColors.navyCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: SColors.green,
                size: 48,
              ),
              const SizedBox(height: 18),
              const Text(
                'Account Created!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your Sendra ID',
                style: TextStyle(color: SColors.textSub, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(
                accNumber,
                style: const TextStyle(
                  color: SColors.gold,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: SButton.primary,
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                  child: const Text('Go to Login', style: SButton.primaryLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SendraLogo(),
                    const SizedBox(height: 36),
                    _buildStepIndicator(),
                    const SizedBox(height: 32),
                    _step == 0 ? _buildStep0() : _buildStep1(),
                    if (_errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _ErrorBox(message: _errorMessage),
                    ],
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: SButton.primary,
                        onPressed: _loading
                            ? null
                            : (_step == 0 ? _proceedToPin : _createAccount),
                        child: Text(
                          _step == 0 ? 'Continue' : 'Create Account',
                          style: SButton.primaryLabel,
                        ),
                      ),
                    ),
                    if (_step == 0) ...[
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(AppStrings.alreadyHave, style: SText.caption),
                          GestureDetector(
                            onTap: _loading
                                ? null
                                : () => Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => const LoginPage(),
                                    ),
                                  ),
                            child: Text(
                              AppStrings.logInLink,
                              style: SText.goldAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (_loading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.6),
                child: const Center(
                  child: CircularProgressIndicator(color: SColors.gold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _StepDot(index: 0, current: _step),
            _StepLine(active: _step >= 1),
            _StepDot(index: 1, current: _step),
          ],
        ),
        const SizedBox(height: 14),
        Text('Step ${_step + 1} of 2', style: SText.caption),
        Text(
          _step == 0 ? AppStrings.step1Title : AppStrings.step2Title,
          style: SText.heading,
        ),
      ],
    );
  }

  Widget _buildStep0() {
    return Column(
      children: [
        _InputField(
          controller: _firstNameCtrl,
          label: 'First Name',
          hint: 'Amara',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 16),
        _InputField(
          controller: _lastNameCtrl,
          label: 'Last Name',
          hint: 'Osei',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 16),
        _PhoneField(controller: _phoneCtrl),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: SDecor.goldGlow,
          child: Column(
            children: [
              const Text(
                'Your Sendra ID',
                style: TextStyle(color: SColors.textSub, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Text(
                _generatedAccNumber.isNotEmpty ? _generatedAccNumber : '—',
                style: const TextStyle(
                  color: SColors.gold,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _PinField(
          controller: _pinCtrl,
          label: 'Create PIN',
          hint: '****',
          hidden: _pinHidden,
          onToggle: () => setState(() => _pinHidden = !_pinHidden),
        ),
        const SizedBox(height: 16),
        _PinField(
          controller: _confirmPinCtrl,
          label: 'Confirm PIN',
          hint: '****',
          hidden: _confirmPinHidden,
          onToggle: () =>
              setState(() => _confirmPinHidden = !_confirmPinHidden),
        ),
      ],
    );
  }
}

// ─── Reusable widgets ────────────────────────────────────────────────────────

class _StepDot extends StatelessWidget {
  final int index, current;
  const _StepDot({required this.index, required this.current});
  @override
  Widget build(BuildContext context) {
    final active = current >= index;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: active ? SColors.gold : SColors.navyCard,
        shape: BoxShape.circle,
        border: Border.all(
          color: active ? SColors.gold : SColors.navyLight,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          style: TextStyle(color: active ? SColors.navy : Colors.white),
        ),
      ),
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool active;
  const _StepLine({required this.active});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: active ? SColors.gold : SColors.navyLight,
    ),
  );
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: SText.label),
      const SizedBox(height: 8),
      Container(
        decoration: SDecor.inputField,
        child: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          style: SText.body,
          decoration: SDecor.textInput(
            hint: hint,
            prefix: Icon(icon, color: SColors.textDim, size: 18),
          ),
        ),
      ),
    ],
  );
}

class _PhoneField extends StatelessWidget {
  final TextEditingController controller;
  const _PhoneField({required this.controller});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Phone Number', style: SText.label),
      const SizedBox(height: 8),
      Container(
        decoration: SDecor.inputField,
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          style: SText.body,
          decoration: SDecor.textInput(hint: '07...'),
        ),
      ),
    ],
  );
}

class _PinField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final bool hidden;
  final VoidCallback onToggle;
  const _PinField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.hidden,
    required this.onToggle,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: SText.label),
      const SizedBox(height: 8),
      Container(
        decoration: SDecor.inputField,
        child: TextField(
          controller: controller,
          obscureText: hidden,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          style: SText.body,
          decoration: SDecor.textInput(
            hint: hint,
            suffix: IconButton(
              icon: Icon(
                hidden ? Icons.visibility_off : Icons.visibility,
                color: SColors.textDim,
                size: 18,
              ),
              onPressed: onToggle,
            ),
          ),
        ),
      ),
    ],
  );
}

class _SignUpFlowException implements Exception {
  final String message;
  const _SignUpFlowException(this.message);
}

class _SendraLogo extends StatelessWidget {
  const _SendraLogo();
  @override
  Widget build(BuildContext context) => Row(
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

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});
  @override
  Widget build(BuildContext context) => Container(
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
