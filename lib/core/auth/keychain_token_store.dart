import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_session.dart';

abstract interface class SecureStorageBoundary {
  Future<String?> read({required String key, required IOSOptions iOptions});

  Future<void> write({
    required String key,
    required String value,
    required IOSOptions iOptions,
  });

  Future<void> delete({required String key, required IOSOptions iOptions});
}

final class FlutterSecureStorageBoundary implements SecureStorageBoundary {
  const FlutterSecureStorageBoundary([
    this._storage = const FlutterSecureStorage(),
  ]);

  final FlutterSecureStorage _storage;

  @override
  Future<void> delete({required String key, required IOSOptions iOptions}) {
    return _storage.delete(key: key, iOptions: iOptions);
  }

  @override
  Future<String?> read({required String key, required IOSOptions iOptions}) {
    return _storage.read(key: key, iOptions: iOptions);
  }

  @override
  Future<void> write({
    required String key,
    required String value,
    required IOSOptions iOptions,
  }) {
    return _storage.write(key: key, value: value, iOptions: iOptions);
  }
}

final class KeychainTokenStore implements TokenStore, ConditionalTokenStore {
  KeychainTokenStore({SecureStorageBoundary? storage})
    : _storage = storage ?? const FlutterSecureStorageBoundary();

  static const userTokenKey = 'guoguo.user-token';
  static const _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  final SecureStorageBoundary _storage;
  Future<void> _operationTail = Future<void>.value();

  @override
  Future<void> clear() {
    return _serialize(
      () => _storage.delete(key: userTokenKey, iOptions: _iosOptions),
    );
  }

  @override
  Future<bool> clearIfUserToken(String expected) {
    return _serialize(() async {
      final current = await _storage.read(
        key: userTokenKey,
        iOptions: _iosOptions,
      );
      if (current != expected) {
        return false;
      }
      await _storage.delete(key: userTokenKey, iOptions: _iosOptions);
      return true;
    });
  }

  @override
  Future<String?> readUserToken() {
    return _serialize(
      () => _storage.read(key: userTokenKey, iOptions: _iosOptions),
    );
  }

  @override
  Future<void> writeUserToken(String value) {
    return _serialize(
      () => _storage.write(
        key: userTokenKey,
        value: value,
        iOptions: _iosOptions,
      ),
    );
  }

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = Completer<T>();
    _operationTail = _operationTail.then((_) async {
      try {
        result.complete(await operation());
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    return result.future;
  }
}
