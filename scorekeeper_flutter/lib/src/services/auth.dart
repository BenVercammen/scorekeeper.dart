import 'package:firebase_auth/firebase_auth.dart';


/// TODO: eigenlijk PORT+ADAPTER inbouwen rond die UserCredential/User
/// en dan de manier waarop er geauthenticeerd wordt?
/// kwestie van later gemakkelijk te kunnen switchen?
/// nog kijken of en hoe ik die user authentication laat doorstromen naar de core layer?
/// Gaan we authorisatie op application layer of domain layer doen?
///   -> rechten per aggregaat? té granulair?
///
class AuthService {

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Sign in anonymously
  Future<User?> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      return credential.user;
    } on Exception catch (e) {
      print(e.toString());
      return null;
    }
  }

  /// sign in with google
  Future<User?> signInWithGoogle() async {
    // TODO!!
    return null;
  }

  /// sign in with facebook
  Future<User?> signInWithFacebook() async {
    // TODO!!!
    return null;
  }

  /// sign in with email & password

  /// register with email & password

  /// sign out



}