import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_contacts/flutter_contacts.dart' as native;

import 'package:webtrit_phone/repositories/contacts/local_contacts_repository_io.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const contactsChannel = MethodChannel('flutter_contacts');
  const changesChannel = MethodChannel('flutter_contacts/simple_listener');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  test('reads return snapshots while native notifications only signal invalidation', () async {
    var reads = 0;
    final listenerCalls = <String>[];
    messenger.setMockMethodCallHandler(contactsChannel, (call) async {
      expect(call.method, 'crud.getAll');
      reads++;
      return [
        const native.Contact(
          id: 'device-1',
          displayName: 'Alice',
          phones: [native.Phone(number: '12345')],
        ).toJson(),
        const native.Contact(displayName: 'No stable id').toJson(),
      ];
    });
    messenger.setMockMethodCallHandler(changesChannel, (call) async => listenerCalls.add(call.method));
    addTearDown(() => messenger.setMockMethodCallHandler(contactsChannel, null));
    addTearDown(() => messenger.setMockMethodCallHandler(changesChannel, null));

    final repository = LocalContactsRepository();
    final changed = Completer<void>();
    var notifications = 0;
    final subscription = repository.watchChanges().listen((_) {
      notifications++;
      changed.complete();
    });
    addTearDown(subscription.cancel);
    final contacts = await repository.fetchContacts();
    expect(contacts.single.id, 'device-1');
    expect(contacts.single.displayName, 'Alice');
    expect(contacts.single.phones.single.number, '12345');
    expect(notifications, 0);
    expect(reads, 1);
    expect(listenerCalls, ['listen']);

    binding.channelBuffers.push(changesChannel.name, const StandardMethodCodec().encodeSuccessEnvelope(null), (_) {});
    await changed.future;
    expect(notifications, 1);
    expect(reads, 1, reason: 'the sync owner must schedule the next read');
    await subscription.cancel();
    await Future<void>.delayed(Duration.zero);
    expect(listenerCalls, ['listen', 'cancel']);
  });
}
