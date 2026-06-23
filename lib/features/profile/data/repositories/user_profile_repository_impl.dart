import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/app_logger.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/repositories/user_profile_repository.dart';

class UserProfileRepositoryImpl implements UserProfileRepository {
  UserProfileRepositoryImpl(this._db, this._auth);

  final FirebaseFirestore _db;
  final AuthRepository _auth;

  DocumentReference<Map<String, dynamic>>? get _doc {
    final AppUser? u = _auth.currentUser();
    if (u == null || u.id.isEmpty) return null;
    return _db.collection('users').doc(u.id);
  }

  Future<void> _merge(Map<String, dynamic> data) async {
    final DocumentReference<Map<String, dynamic>>? ref = _doc;
    if (ref == null) {
      appLogger.i('👤 Skip profile write — no signed-in user');
      return;
    }
    try {
      await ref.set(
        <String, dynamic>{
          ...data,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      appLogger.w('👤 Profile write failed for ${data.keys.first}: $e');
    }
  }

  @override
  Future<void> saveIelts(double value) =>
      _merge(<String, dynamic>{'ielts': value});

  @override
  Future<void> saveSat(int value) => _merge(<String, dynamic>{'sat': value});

  @override
  Future<void> saveEducationLevel(String code) =>
      _merge(<String, dynamic>{'educationLevel': code});

  @override
  Future<void> saveFieldOfStudy(String label) =>
      _merge(<String, dynamic>{'fieldOfStudy': label});

  @override
  Future<void> saveDestinationCountry(String code) =>
      _merge(<String, dynamic>{'destinationCountry': code});
}
