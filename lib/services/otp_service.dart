import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class OtpService {
  static String get _brevoApiKey =>
      dotenv.env['BREVO_API_KEY'] ?? (throw Exception('BREVO_API_KEY not set'));
  static const _senderEmail = 'ramadhanizaidi2050@gmail.com';
  static const _senderName = 'Sendra';

  static Future<void> sendOtp({
    required String email,
    required String phone,
  }) async {
    final code = (100000 + Random().nextInt(900000)).toString();
    final expiresAt = DateTime.now().add(const Duration(minutes: 10));

    await FirebaseFirestore.instance.collection('otps').doc(phone).set({
      'code': code,
      'email': email,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'verified': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final response = await http.post(
      Uri.parse('https://api.brevo.com/v3/smtp/email'),
      headers: {
        'accept': 'application/json',
        'api-key': _brevoApiKey,
        'content-type': 'application/json',
      },
      body: jsonEncode({
        'sender': {'name': _senderName, 'email': _senderEmail},
        'to': [
          {'email': email},
        ],
        'subject': 'Your Sendra Verification Code',
        'htmlContent':
            '''
          <div style="font-family: Arial, sans-serif; max-width: 480px;
                      margin: auto; background: #0f1520; padding: 40px;
                      border-radius: 16px;">
            <div style="text-align: center; margin-bottom: 32px;">
              <div style="display: inline-block; background: #C9A84C;
                          width: 48px; height: 48px; border-radius: 12px;
                          line-height: 48px; font-size: 24px; font-weight: 900;
                          color: #0f1520;">S</div>
              <h2 style="color: #ffffff; margin: 12px 0 4px;">Sendra</h2>
              <p style="color: #8899aa; font-size: 13px; margin: 0;">
                Secure Money Transfers
              </p>
            </div>
            <p style="color: #ccddee; font-size: 14px; margin-bottom: 8px;">
              Your verification code is:
            </p>
            <div style="background: #1a2236; border: 1px solid #2a3550;
                        border-radius: 12px; padding: 28px; text-align: center;
                        margin: 16px 0;">
              <span style="font-size: 42px; font-weight: 900;
                           letter-spacing: 14px; color: #C9A84C;">$code</span>
            </div>
            <p style="color: #8899aa; font-size: 12px; text-align: center;">
              Expires in <strong style="color: #ccddee;">10 minutes</strong>.
              Never share this code with anyone.
            </p>
            <hr style="border: none; border-top: 1px solid #1a2236;
                       margin: 28px 0;">
            <p style="color: #556677; font-size: 11px;
                      text-align: center; margin: 0;">
              If you didn\'t request this, ignore this email.
            </p>
          </div>
        ''',
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to send OTP email. Please try again.');
    }
  }

  static Future<void> verifyOtp({
    required String phone,
    required String code,
  }) async {
    final doc = await FirebaseFirestore.instance
        .collection('otps')
        .doc(phone)
        .get();

    if (!doc.exists) {
      throw Exception('No verification code found. Please request a new one.');
    }

    final data = doc.data()!;
    final stored = data['code'] as String;
    final expiresAt = (data['expiresAt'] as Timestamp).toDate();
    final verified = data['verified'] as bool;

    if (verified) {
      throw Exception('Code already used. Please request a new one.');
    }
    if (DateTime.now().isAfter(expiresAt)) {
      throw Exception('Code has expired. Please request a new one.');
    }
    if (code != stored) {
      throw Exception('Incorrect code. Please try again.');
    }

    await FirebaseFirestore.instance.collection('otps').doc(phone).update({
      'verified': true,
    });
  }
}
