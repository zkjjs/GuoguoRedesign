import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guoguo/core/auth/keychain_token_store.dart';

void main() {
  test(
    'reads writes and clears only the user token using device keychain',
    () async {
      final storage = _MemorySecureStorage();
      final store = KeychainTokenStore(storage: storage);

      await store.writeUserToken('user-token');
      expect(await store.readUserToken(), 'user-token');
      await store.clear();

      expect(await store.readUserToken(), isNull);
      expect(storage.operations, ['write', 'read', 'delete', 'read']);
      expect(storage.keys, [
        KeychainTokenStore.userTokenKey,
        KeychainTokenStore.userTokenKey,
        KeychainTokenStore.userTokenKey,
        KeychainTokenStore.userTokenKey,
      ]);
      expect(
        storage.options,
        everyElement(
          isA<IOSOptions>().having(
            (options) => options.accessibility,
            'accessibility',
            KeychainAccessibility.first_unlock_this_device,
          ),
        ),
      );
    },
  );

  test(
    'conditional clear is atomic with a concurrent new-token write',
    () async {
      final storage = _MemorySecureStorage()
        ..values[KeychainTokenStore.userTokenKey] = 'old'
        ..pauseNextRead = true;
      final store = KeychainTokenStore(storage: storage);

      final clearing = store.clearIfUserToken('old');
      await storage.readStarted.future;
      final signingIn = store.writeUserToken('new');
      storage.releaseRead.complete();

      expect(await clearing, isTrue);
      await signingIn;
      expect(await store.readUserToken(), 'new');
    },
  );

  test('conditional clear removes only the matching rejected token', () async {
    final storage = _MemorySecureStorage()
      ..values[KeychainTokenStore.userTokenKey] = 'rejected';
    final store = KeychainTokenStore(storage: storage);

    expect(await store.clearIfUserToken('different'), isFalse);
    expect(await store.readUserToken(), 'rejected');
    expect(await store.clearIfUserToken('rejected'), isTrue);
    expect(await store.readUserToken(), isNull);
  });
}

final class _MemorySecureStorage implements SecureStorageBoundary {
  final Map<String, String> values = {};
  final List<String> keys = [];
  final List<String> operations = [];
  final List<IOSOptions> options = [];
  bool pauseNextRead = false;
  final readStarted = Completer<void>();
  final releaseRead = Completer<void>();

  @override
  Future<void> delete({
    required String key,
    required IOSOptions iOptions,
  }) async {
    operations.add('delete');
    keys.add(key);
    options.add(iOptions);
    values.remove(key);
  }

  @override
  Future<String?> read({
    required String key,
    required IOSOptions iOptions,
  }) async {
    operations.add('read');
    keys.add(key);
    options.add(iOptions);
    if (pauseNextRead) {
      pauseNextRead = false;
      readStarted.complete();
      await releaseRead.future;
    }
    return values[key];
  }

  @override
  Future<void> write({
    required String key,
    required String value,
    required IOSOptions iOptions,
  }) async {
    operations.add('write');
    keys.add(key);
    options.add(iOptions);
    values[key] = value;
  }
}
