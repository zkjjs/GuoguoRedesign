abstract interface class TokenStore {
  Future<String?> readUserToken();

  Future<void> writeUserToken(String value);

  Future<void> clear();
}

/// Optional capability for stores that can atomically remove only a known
/// rejected credential without racing a concurrent sign-in write.
abstract interface class ConditionalTokenStore implements TokenStore {
  Future<bool> clearIfUserToken(String expected);
}

abstract interface class SessionRefresher {
  Future<String> refreshUserToken();
}

/// Signals that the refresh credential was definitively rejected by the
/// authentication service. Network, server, and storage failures must not use
/// this type because they do not prove that the user's session has expired.
final class RefreshAuthenticationRejected implements Exception {
  const RefreshAuthenticationRejected();
}

final class AuthSession {
  const AuthSession({this.xToken, this.userToken});

  final String? xToken;
  final String? userToken;

  bool get isAuthenticated => userToken?.isNotEmpty ?? false;
}
