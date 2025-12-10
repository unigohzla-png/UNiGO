import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../firebase_options.dart';

/// Helper to create Firebase Auth users from the admin account
/// without logging the admin out (uses a secondary Firebase app).
class AdminAuthHelper {
  static FirebaseApp? _secondaryApp;
  static FirebaseAuth? _secondaryAuth;

  static Future<FirebaseAuth> _getAuth() async {
    if (_secondaryAuth != null) return _secondaryAuth!;

    _secondaryApp ??= await Firebase.initializeApp(
      name: 'admin-helper', // secondary app name
      options: DefaultFirebaseOptions.currentPlatform,
    );

    _secondaryAuth = FirebaseAuth.instanceFor(app: _secondaryApp!);
    return _secondaryAuth!;
  }

  /// Creates an Auth user and returns the new uid.
  static Future<String> createUser({
    required String email,
    required String password,
  }) async {
    final auth = await _getAuth();
    final cred = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Make sure secondary app isn't left logged in (just to be clean)
    await auth.signOut();

    return cred.user!.uid;
  }
}
