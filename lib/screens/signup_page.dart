import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sendra/core/theme.dart';
import 'package:sendra/core/constants.dart';
import 'package:sendra/screens/login_page.dart';
import 'package:sendra/services/otp_service.dart';

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
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _confirmPinCtrl = TextEditingController();

  int _step = 0;
  bool _loading = false;
  bool _pinHidden = true;
  bool _confirmPinHidden = true;
  String _errorMessage = '';
  String _generatedAccNumber = '';
  int _resendCooldown = 0;
  Timer? _resendTimer;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();

    // Auto-capitalize names as user types
    _firstNameCtrl.addListener(_formatFirstName);
    _lastNameCtrl.addListener(_formatLastName);
  }

  // ── UPPERCASE formatters ─────────────────────────────────────────────────
  void _formatFirstName() => _applyUpperCase(_firstNameCtrl);
  void _formatLastName() => _applyUpperCase(_lastNameCtrl);

  /// Applies UPPERCASE formatting to any text input
  /// This ensures all letters are converted to CAPITALS
  void _applyUpperCase(TextEditingController ctrl) {
    final text = ctrl.text;
    final formatted = text.toUpperCase();
    
    // Only update if the text has actually changed
    if (formatted != text) {
      final cursorPosition = formatted.length;
      ctrl.value = ctrl.value.copyWith(
        text: formatted,
        selection: TextSelection.collapsed(offset: cursorPosition),
      );
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.removeListener(_formatFirstName);
    _lastNameCtrl.removeListener(_formatLastName);
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _pinCtrl.dispose();
    _confirmPinCtrl.dispose();
    _animCtrl.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  // ── Phone normalization ───────────────────────────────────────────────────
  // User types 7XXXXXXXX (9 digits, no leading 0)
  // We prepend 255 → stored as 2557XXXXXXXX
  String get _normalizedPhone {
    final digits = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '').trim();
    return '255$digits';
  }

  String _authPassword(String pin) => '${pin}_sendra';

  bool _isValidEmail(String e) =>
      RegExp(r'^[\w\-.]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(e);

  void _startResendCooldown() {
    setState(() => _resendCooldown = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_resendCooldown <= 0) {
        t.cancel();
        return;
      }
      setState(() => _resendCooldown--);
    });
  }

  void _nextStep() {
    setState(() {
      _step++;
      _errorMessage = '';
    });
    _animCtrl
      ..reset()
      ..forward();
  }

  // ── Step 0 → 1 ────────────────────────────────────────────────────────────
  Future<void> _proceedToOtp() async {
    if (_loading) return;
    final first = _firstNameCtrl.text.trim();
    final last = _lastNameCtrl.text.trim();
    final phone = _normalizedPhone;
    final email = _emailCtrl.text.trim();

    if (first.isEmpty || last.isEmpty) {
      setState(() => _errorMessage = 'Please enter your first and last name.');
      return;
    }
    // Phone must be 9 digits starting with 7
    final rawDigits = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (rawDigits.length != 9 || !rawDigits.startsWith('7')) {
      setState(
        () => _errorMessage =
            'Enter a valid phone number starting with 7 (e.g. 7XXXXXXXX).',
      );
      return;
    }
    if (!_isValidEmail(email)) {
      setState(() => _errorMessage = 'Enter a valid email address.');
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
      await OtpService.sendOtp(email: email, phone: phone);

      if (!mounted) return;
      setState(() {
        _generatedAccNumber = accNumber;
        _loading = false;
      });
      _startResendCooldown();
      _nextStep();
    } on TimeoutException {
      if (mounted)
        setState(() {
          _errorMessage = 'Request timed out. Please try again.';
          _loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
    }
  }

  // ── Step 1 → 2 ────────────────────────────────────────────────────────────
  Future<void> _verifyOtp() async {
    if (_loading) return;
    final code = _otpCtrl.text.trim();

    if (code.length != 6) {
      setState(
        () => _errorMessage = 'Enter the 6-digit code sent to your email.',
      );
      return;
    }

    setState(() {
      _errorMessage = '';
      _loading = true;
    });

    try {
      await OtpService.verifyOtp(phone: _normalizedPhone, code: code);
      if (!mounted) return;
      setState(() => _loading = false);
      _nextStep();
    } catch (e) {
      if (mounted)
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
    }
  }

  // ── Step 2: create account ────────────────────────────────────────────────
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
      setState(() => _errorMessage = 'PINs do not match. Please try again.');
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
      final authEmail = '$phone@sendra.app';
      final password = _authPassword(pin);

      try {
        credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: authEmail,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        throw Exception(
          e.code == 'email-already-in-use'
              ? 'This phone number is already registered.'
              : 'Could not create account: ${e.message}',
        );
      }

      await FirebaseFirestore.instance
          .collection(FSKeys.usersCollection)
          .doc(credential.user!.uid)
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
      _showSuccessDialog(accNumber, '$firstName $lastName');
    } catch (e) {
      await credential?.user?.delete();
      if (mounted)
        setState(() {
          _loading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
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
    throw Exception('Could not reserve a Sendra ID. Please try again.');
  }

  void _showSuccessDialog(String accNumber, String fullName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: SColors.navyCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: SColors.green.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: SColors.green.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: SColors.green,
                  size: 38,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Account Created!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Welcome to Sendra, ${fullName.split(' ').first}!',
                style: const TextStyle(color: SColors.textSub, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      SColors.gold.withOpacity(0.15),
                      SColors.goldDark.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: SColors.gold.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.tag_rounded, color: SColors.gold, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'Your Sendra ID',
                          style: TextStyle(
                            color: SColors.gold,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      accNumber,
                      style: const TextStyle(
                        color: SColors.gold,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 10,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Share this ID to receive money',
                      style: TextStyle(color: SColors.textDim, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: SColors.navyLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      color: SColors.textDim,
                      size: 14,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Keep your PIN safe. Never share it with anyone.',
                        style: TextStyle(color: SColors.textDim, fontSize: 11),
                      ),
                    ),
                  ],
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

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SColors.bg,
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SColors.gold.withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SColors.gold.withOpacity(0.03),
              ),
            ),
          ),

          FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopBar(),
                      const SizedBox(height: 32),
                      _buildStepHeader(),
                      const SizedBox(height: 28),
                      if (_step == 0) _buildStep0(),
                      if (_step == 1) _buildStep1(),
                      if (_step == 2) _buildStep2(),
                      if (_errorMessage.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _ErrorBox(message: _errorMessage),
                      ],
                      const SizedBox(height: 28),
                      _buildPrimaryButton(),
                      if (_step == 0) ...[
                        const SizedBox(height: 20),
                        _buildLoginLink(),
                        const SizedBox(height: 32),
                        _buildTrustBadges(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (_loading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.65),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: SColors.navyCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: SColors.navyLight),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: SColors.gold,
                          strokeWidth: 2.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _step == 0
                          ? 'Verifying...'
                          : _step == 1
                          ? 'Sending code...'
                          : 'Creating your account...',
                      style: const TextStyle(
                        color: SColors.textSub,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [SColors.gold, SColors.goldDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text(
              'S',
              style: TextStyle(
                color: SColors.navy,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'Sendra',
          style: TextStyle(
            color: SColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: SColors.gold.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: SColors.gold.withOpacity(0.25)),
          ),
          child: Text(
            'Step ${_step + 1} of 3',
            style: const TextStyle(
              color: SColors.gold,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepHeader() {
    final titles = [
      'Personal Information',
      'Verify Email',
      'Secure Your Account',
    ];
    final subtitles = [
      'Tell us who you are to get started',
      'Enter the 6-digit code sent to your email',
      'Create a 4-digit PIN to protect your wallet',
    ];
    final icons = [
      Icons.person_add_alt_1_outlined,
      Icons.mark_email_read_outlined,
      Icons.lock_outline_rounded,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (_step + 1) / 3,
            backgroundColor: SColors.navyLight,
            valueColor: const AlwaysStoppedAnimation<Color>(SColors.gold),
            minHeight: 3,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: SColors.gold.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: SColors.gold.withOpacity(0.25)),
              ),
              child: Icon(icons[_step], color: SColors.gold, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titles[_step],
                    style: const TextStyle(
                      color: SColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitles[_step],
                    style: const TextStyle(
                      color: SColors.textSub,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Step 0 ────────────────────────────────────────────────────────────────
  Widget _buildStep0() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _Field(
                controller: _firstNameCtrl,
                label: 'First Name',
                hint: 'Amara',
                icon: Icons.badge_outlined,
                capitalize: TextCapitalization.words,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Field(
                controller: _lastNameCtrl,
                label: 'Last Name',
                hint: 'Osei',
                icon: Icons.badge_outlined,
                capitalize: TextCapitalization.words,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildPhoneField(),
        const SizedBox(height: 16),
        _Field(
          controller: _emailCtrl,
          label: 'Email Address',
          hint: 'you@gmail.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: SColors.navyCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SColors.navyLight),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: SColors.gold.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: SColors.gold,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Your phone number is your login ID. We\'ll send a verification code to your email.',
                  style: TextStyle(color: SColors.textSub, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phone Number',
          style: TextStyle(
            color: SColors.textSub,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: SDecor.inputField,
          child: Row(
            children: [
              Container(
                margin: const EdgeInsets.only(left: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: SColors.navyLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Text('🇹🇿', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 6),
                    Text(
                      '+255',
                      style: TextStyle(
                        color: SColors.textSub,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(9),
                    // Block leading zero
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      if (newValue.text.startsWith('0')) return oldValue;
                      return newValue;
                    }),
                  ],
                  style: const TextStyle(
                    color: SColors.textPrimary,
                    fontSize: 15,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '7XXXXXXXX',
                    hintStyle: TextStyle(color: SColors.textDim, fontSize: 15),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Step 1: OTP ───────────────────────────────────────────────────────────
  Widget _buildStep1() {
    final email = _emailCtrl.text.trim();
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: SColors.navyCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: SColors.navyLight),
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: SColors.gold.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: SColors.gold.withOpacity(0.25)),
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  color: SColors.gold,
                  size: 26,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Check your email',
                style: TextStyle(
                  color: SColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'We sent a 6-digit code to\n$email',
                textAlign: TextAlign.center,
                style: const TextStyle(color: SColors.textSub, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Verification Code',
              style: TextStyle(
                color: SColors.textSub,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: SDecor.inputField,
              child: TextField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                style: const TextStyle(
                  color: SColors.textPrimary,
                  fontSize: 28,
                  letterSpacing: 12,
                  fontWeight: FontWeight.w700,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: '------',
                  hintStyle: TextStyle(color: SColors.textDim, fontSize: 22),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Didn't receive it? ",
              style: TextStyle(color: SColors.textSub, fontSize: 13),
            ),
            _resendCooldown > 0
                ? Text(
                    'Resend in ${_resendCooldown}s',
                    style: const TextStyle(
                      color: SColors.textDim,
                      fontSize: 13,
                    ),
                  )
                : GestureDetector(
                    onTap: () async {
                      setState(() {
                        _loading = true;
                        _errorMessage = '';
                      });
                      try {
                        await OtpService.sendOtp(
                          email: _emailCtrl.text.trim(),
                          phone: _normalizedPhone,
                        );
                        _startResendCooldown();
                      } catch (e) {
                        if (mounted)
                          setState(
                            () => _errorMessage = e.toString().replaceAll(
                              'Exception: ',
                              '',
                            ),
                          );
                      } finally {
                        if (mounted) setState(() => _loading = false);
                      }
                    },
                    child: const Text(
                      'Resend',
                      style: TextStyle(
                        color: SColors.gold,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
          ],
        ),
      ],
    );
  }

  // ── Step 2: PIN ───────────────────────────────────────────────────────────
  Widget _buildStep2() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                SColors.gold.withOpacity(0.12),
                SColors.goldDark.withOpacity(0.06),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: SColors.gold.withOpacity(0.25)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.verified_outlined, color: SColors.gold, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Your Sendra ID is Reserved',
                    style: TextStyle(
                      color: SColors.gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _generatedAccNumber.isNotEmpty ? _generatedAccNumber : '—',
                style: const TextStyle(
                  color: SColors.gold,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 12,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}',
                style: const TextStyle(color: SColors.textSub, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: SColors.navyCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SColors.navyLight),
          ),
          child: const Row(
            children: [
              Icon(Icons.shield_outlined, color: SColors.green, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Choose a PIN you\'ll remember. You\'ll need it every time you send money.',
                  style: TextStyle(color: SColors.textSub, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _PinField(
          controller: _pinCtrl,
          label: 'Create PIN',
          hint: '••••',
          hidden: _pinHidden,
          onToggle: () => setState(() => _pinHidden = !_pinHidden),
        ),
        const SizedBox(height: 16),
        _PinField(
          controller: _confirmPinCtrl,
          label: 'Confirm PIN',
          hint: '••••',
          hidden: _confirmPinHidden,
          onToggle: () =>
              setState(() => _confirmPinHidden = !_confirmPinHidden),
        ),
        if (_pinCtrl.text.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              4,
              (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _pinCtrl.text.length
                      ? SColors.gold
                      : SColors.navyLight,
                  border: Border.all(
                    color: i < _pinCtrl.text.length
                        ? SColors.gold
                        : SColors.navyBorder,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPrimaryButton() {
    final labels = ['Continue', 'Verify Email', 'Create My Account'];
    final actions = [_proceedToOtp, _verifyOtp, _createAccount];
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: SButton.primary,
        onPressed: _loading ? null : actions[_step],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(labels[_step], style: SButton.primaryLabel),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_rounded,
              color: SColors.navy,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Already have an account? ',
          style: TextStyle(color: SColors.textSub, fontSize: 13),
        ),
        GestureDetector(
          onTap: _loading
              ? null
              : () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                ),
          child: const Text(
            'Log In',
            style: TextStyle(
              color: SColors.gold,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrustBadges() {
    return Column(
      children: [
        const Row(
          children: [
            Expanded(child: Divider(color: SColors.navyLight)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Why Sendra?',
                style: TextStyle(color: SColors.textDim, fontSize: 11),
              ),
            ),
            Expanded(child: Divider(color: SColors.navyLight)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _TrustBadge(
              icon: Icons.bolt_rounded,
              label: 'Instant\nTransfers',
              color: SColors.gold,
            ),
            const SizedBox(width: 10),
            _TrustBadge(
              icon: Icons.security_rounded,
              label: 'Bank-Grade\nSecurity',
              color: SColors.green,
            ),
            const SizedBox(width: 10),
            _TrustBadge(
              icon: Icons.currency_exchange_rounded,
              label: 'Live\nRates',
              color: const Color(0xFF3B82F6),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _TrustBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: SColors.navyCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SColors.navyLight),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: SColors.textSub,
              fontSize: 10,
              height: 1.4,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Custom text input field widget for regular text inputs
class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final TextCapitalization capitalize;
  final TextInputType? keyboardType;
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.capitalize = TextCapitalization.none,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: SColors.textSub,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 8),
      Container(
        decoration: SDecor.inputField,
        child: TextField(
          controller: controller,
          textCapitalization: capitalize,
          keyboardType: keyboardType,
          style: const TextStyle(color: SColors.textPrimary, fontSize: 15),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: hint,
            hintStyle: const TextStyle(color: SColors.textDim, fontSize: 15),
            prefixIcon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(icon, color: SColors.textDim, size: 18),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    ],
  );
}

/// Custom PIN field widget with show/hide toggle
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
      Text(
        label,
        style: const TextStyle(
          color: SColors.textSub,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
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
          style: const TextStyle(
            color: SColors.textPrimary,
            fontSize: 28,
            letterSpacing: 16,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: hint,
            hintStyle: const TextStyle(color: SColors.textDim, fontSize: 20),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                hidden
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
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

/// Error message box widget
class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: SDecor.errorBox,
    child: Row(
      children: [
        const Icon(Icons.error_outline_rounded, color: SColors.red, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: SColors.red, fontSize: 12),
          ),
        ),
      ],
    ),
  );
}