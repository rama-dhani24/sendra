const functions = require("firebase-functions");
const admin = require("firebase-admin");
const Brevo = require("@getbrevo/brevo");

admin.initializeApp();

// ── Send OTP ────────────────────────────────────────────────────────────────
exports.sendOtp = functions.https.onCall(async (data, context) => {
  const { email, phone } = data;

  if (!email || !phone) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Email and phone are required."
    );
  }

  // Generate 6-digit code
  const code = Math.floor(100000 + Math.random() * 900000).toString();
  const expiresAt = Date.now() + 10 * 60 * 1000; // 10 minutes

  // Store OTP in Firestore
  await admin.firestore().collection("otps").doc(phone).set({
    code,
    email,
    expiresAt,
    verified: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Send via Brevo
  const apiInstance = new Brevo.TransactionalEmailsApi();
  apiInstance.authentications["apiKey"].apiKey = process.env.BREVO_KEY;

  const sendSmtpEmail = new Brevo.SendSmtpEmail();
  sendSmtpEmail.to = [{ email: email }];
  sendSmtpEmail.sender = {
    name: "Sendra",
    email: "ramadhanizaidi2050@gmail.com", // ← must match your Brevo verified sender
  };
  sendSmtpEmail.subject = "Your Sendra Verification Code";
  sendSmtpEmail.htmlContent = `
    <div style="font-family: Arial, sans-serif; max-width: 480px; margin: auto;
                background: #0f1520; padding: 40px; border-radius: 16px;">

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
        <span style="font-size: 42px; font-weight: 900; letter-spacing: 14px;
                     color: #C9A84C;">${code}</span>
      </div>

      <p style="color: #8899aa; font-size: 12px; text-align: center;">
        Expires in <strong style="color: #ccddee;">10 minutes</strong>.
        Never share this code with anyone.
      </p>

      <hr style="border: none; border-top: 1px solid #1a2236; margin: 28px 0;">

      <p style="color: #556677; font-size: 11px; text-align: center; margin: 0;">
        If you didn't request this, ignore this email. Your account is safe.
      </p>
    </div>
  `;

  await apiInstance.sendTransacEmail(sendSmtpEmail);

  return { success: true };
});

// ── Verify OTP ───────────────────────────────────────────────────────────────
exports.verifyOtp = functions.https.onCall(async (data, context) => {
  const { phone, code } = data;

  if (!phone || !code) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Phone and code are required."
    );
  }

  const doc = await admin
    .firestore()
    .collection("otps")
    .doc(phone)
    .get();

  if (!doc.exists) {
    throw new functions.https.HttpsError(
      "not-found",
      "No verification code found. Please request a new one."
    );
  }

  const { code: stored, expiresAt, verified } = doc.data();

  if (verified) {
    throw new functions.https.HttpsError(
      "already-exists",
      "This code has already been used."
    );
  }

  if (Date.now() > expiresAt) {
    throw new functions.https.HttpsError(
      "deadline-exceeded",
      "Code has expired. Please request a new one."
    );
  }

  if (code !== stored) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Incorrect code. Please try again."
    );
  }

  // Mark verified
  await admin
    .firestore()
    .collection("otps")
    .doc(phone)
    .update({ verified: true });

  return { success: true };
});