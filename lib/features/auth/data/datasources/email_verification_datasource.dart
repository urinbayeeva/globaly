import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/services/email_service.dart';
import '../../../../core/utils/app_logger.dart';

abstract class EmailVerificationDataSource {
  Future<void> sendCode({required String name, required String email});
  Future<void> verifyCode({required String email, required String code});
}

class EmailVerificationDataSourceImpl implements EmailVerificationDataSource {
  EmailVerificationDataSourceImpl(this._email, this._db);

  final EmailService _email;
  final FirebaseFirestore _db;

  static const String _collection = 'email_verifications';
  static const Duration _ttl = Duration(minutes: 10);
  static const int _maxAttempts = 5;

  DocumentReference<Map<String, dynamic>> _doc(String email) =>
      _db.collection(_collection).doc(_key(email));

  @override
  Future<void> sendCode({required String name, required String email}) async {
    final String code = _generateCode();
    final String hash = _hash(code, email);
    final DateTime now = DateTime.now();

    try {
      await _doc(email).set(<String, dynamic>{
        'hash': hash,
        'attempts': 0,
        'createdAt': Timestamp.fromDate(now),
        'expiresAt': Timestamp.fromDate(now.add(_ttl)),
      });
    } catch (e) {
      appLogger.w('otp store failed: $e');
      throw const OtpException(OtpError.sendFailed);
    }

    final bool sent =
        await _email.sendOtp(email: email, code: code, name: name);
    if (!sent) throw const OtpException(OtpError.sendFailed);
  }

  @override
  Future<void> verifyCode({
    required String email,
    required String code,
  }) async {
    final DocumentReference<Map<String, dynamic>> ref = _doc(email);
    final DocumentSnapshot<Map<String, dynamic>> snap = await ref.get();

    if (!snap.exists) throw const OtpException(OtpError.expired);
    final Map<String, dynamic> data = snap.data()!;

    final Timestamp? expiresAt = data['expiresAt'] as Timestamp?;
    if (expiresAt == null || expiresAt.toDate().isBefore(DateTime.now())) {
      await ref.delete();
      throw const OtpException(OtpError.expired);
    }

    final int attempts = (data['attempts'] as int?) ?? 0;
    if (attempts >= _maxAttempts) {
      await ref.delete();
      throw const OtpException(OtpError.tooManyAttempts);
    }

    final bool ok = (data['hash'] as String?) == _hash(code, email);
    if (!ok) {
      await ref.update(<String, dynamic>{'attempts': attempts + 1});
      throw const OtpException(OtpError.invalid);
    }

    await ref.delete();
  }

  String _key(String email) => email.trim().toLowerCase();

  String _generateCode() {
    final Random rnd = Random.secure();
    return (rnd.nextInt(900000) + 100000).toString();
  }

  String _hash(String code, String email) =>
      sha256.convert(utf8.encode('${code.trim()}:${_key(email)}')).toString();
}
