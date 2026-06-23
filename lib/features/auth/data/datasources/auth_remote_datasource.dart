import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/app_logger.dart';
import '../models/app_user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AppUserModel> signIn(String email, String password);
  Future<AppUserModel> signUp(String email, String password, String name);

  Future<AppUserModel?> signInWithGoogle();
  Future<AppUserModel?> signInWithApple();

  Future<void> signOut();
  AppUserModel? currentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl([GoogleSignIn? googleSignIn])
      : _google = googleSignIn ?? GoogleSignIn(scopes: <String>['email']);

  final GoogleSignIn _google;

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  Future<AppUserModel> signIn(String email, String password) async {
    try {
      final UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _fromUser(cred.user!);
    } on FirebaseAuthException catch (e) {
      appLogger.w('signIn ${e.code}: ${e.message}');
      throw AuthException(e.message ?? 'Sign-in failed');
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<AppUserModel> signUp(
    String email,
    String password,
    String name,
  ) async {
    try {
      final UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await cred.user!.updateDisplayName(name);
      final AppUserModel u = _fromUser(cred.user!, displayName: name);
      await _writeProfile(u);
      return u;
    } on FirebaseAuthException catch (e) {
      appLogger.w('signUp ${e.code}: ${e.message}');
      throw AuthException(e.message ?? 'Sign-up failed');
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<AppUserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? account = await _google.signIn();
      if (account == null) return null;
      final GoogleSignInAuthentication auth = await account.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );
      final UserCredential cred = await _auth.signInWithCredential(credential);
      final AppUserModel u = _fromUser(cred.user!);
      await _writeProfile(u, merge: true);
      return u;
    } on FirebaseAuthException catch (e) {
      appLogger.w('google ${e.code}: ${e.message}');
      throw AuthException(e.message ?? 'Google sign-in failed');
    } catch (e) {
      appLogger.w('google error: $e');
      throw AuthException(e.toString());
    }
  }

  @override
  Future<AppUserModel?> signInWithApple() async {
    try {
      final String rawNonce = _nonce();
      final String hashedNonce =
          sha256.convert(utf8.encode(rawNonce)).toString();

      final AuthorizationCredentialAppleID apple =
          await SignInWithApple.getAppleIDCredential(
        scopes: <AppleIDAuthorizationScopes>[
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final OAuthCredential credential = OAuthProvider('apple.com').credential(
        idToken: apple.identityToken,
        rawNonce: rawNonce,
      );
      final UserCredential cred = await _auth.signInWithCredential(credential);

      final String? fullName = _appleFullName(apple);
      final User user = cred.user!;
      if (fullName != null && (user.displayName ?? '').isEmpty) {
        await user.updateDisplayName(fullName);
      }
      final AppUserModel u =
          _fromUser(user, displayName: fullName ?? user.displayName);
      await _writeProfile(u, merge: true);
      return u;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      appLogger.w('apple ${e.code}: ${e.message}');
      throw AuthException(e.message);
    } on FirebaseAuthException catch (e) {
      appLogger.w('apple-fb ${e.code}: ${e.message}');
      throw AuthException(e.message ?? 'Apple sign-in failed');
    } catch (e) {
      appLogger.w('apple error: $e');
      throw AuthException(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _google.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  @override
  AppUserModel? currentUser() {
    try {
      final User? u = _auth.currentUser;
      return u == null ? null : _fromUser(u);
    } catch (e) {
      appLogger.w('currentUser unavailable: $e');
      return null;
    }
  }

  Future<void> _writeProfile(AppUserModel u, {bool merge = false}) =>
      _db.collection('users').doc(u.id).set(
            u.toMap(),
            merge ? SetOptions(merge: true) : null,
          );

  String? _appleFullName(AuthorizationCredentialAppleID a) {
    final String name = <String?>[a.givenName, a.familyName]
        .where((String? p) => p != null && p.isNotEmpty)
        .join(' ')
        .trim();
    return name.isEmpty ? null : name;
  }

  String _nonce([int length = 32]) {
    const String chars =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final Random rnd = Random.secure();
    return List<String>.generate(
      length,
      (_) => chars[rnd.nextInt(chars.length)],
    ).join();
  }

  AppUserModel _fromUser(User u, {String? displayName}) => AppUserModel(
        id: u.uid,
        email: u.email ?? '',
        name: displayName ?? u.displayName,
      );
}
