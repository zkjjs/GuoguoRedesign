import 'auth_session.dart';

abstract interface class AuthRepository implements SessionRefresher {
  Future<AuthSession> currentSession();

  Future<void> signOut();
}
