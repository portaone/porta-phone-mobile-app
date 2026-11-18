import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/features/call/conference/conference.dart';

void main() {
  test('a room started in the foreground publishes the camera at once', () {
    final plan = ConferenceCameraPlan();

    expect(plan.start(camera: true, inBackground: false), isTrue);
    expect(plan.cameraWanted, isTrue);
    expect(plan.cameraPaused, isFalse);
  });

  test('a room started in the background publishes the camera when the app returns', () {
    final plan = ConferenceCameraPlan();

    expect(plan.start(camera: true, inBackground: true), isFalse);
    expect(plan.cameraPaused, isTrue);
    expect(plan.resume(), isTrue);
    expect(plan.resume(), isFalse, reason: 'put back once');
  });

  test('a room without a camera publishes nothing, in the foreground or after it', () {
    final plan = ConferenceCameraPlan();

    expect(plan.start(camera: false, inBackground: true), isFalse);
    expect(plan.resume(), isFalse);
  });

  test('the background takes a published camera off and the return puts it back', () {
    final plan = ConferenceCameraPlan()..start(camera: true, inBackground: false);

    expect(plan.pause(publishing: true), isTrue);
    expect(plan.resume(), isTrue);
  });

  test('a camera that never got published is not unpublished, and not put back', () {
    final plan = ConferenceCameraPlan()..start(camera: true, inBackground: false);

    expect(plan.pause(publishing: false), isFalse);
    expect(plan.resume(), isFalse);
  });

  test('a camera turned off in the background stays off when the app returns', () {
    final plan = ConferenceCameraPlan()..start(camera: true, inBackground: false);
    plan.pause(publishing: true);

    expect(plan.setCamera(false, inBackground: true), isFalse);
    expect(plan.resume(), isFalse);
  });

  test('a camera turned on in the background waits for the app', () {
    final plan = ConferenceCameraPlan()..start(camera: false, inBackground: false);

    expect(plan.setCamera(true, inBackground: true), isFalse);
    expect(plan.resume(), isTrue);
  });

  test('an invitation names its line until the room is over', () {
    final plan = ConferenceCameraPlan()..start(camera: true, inBackground: true, invitedLine: 2);

    expect(plan.invitedLine, 2);
    plan.end();
    expect(plan.invitedLine, isNull);
    expect(plan.cameraWanted, isFalse);
    expect(plan.resume(), isFalse, reason: 'nothing waits for a room that is over');
  });

  test('the host\'s own room names no line', () {
    final plan = ConferenceCameraPlan()..start(camera: false, inBackground: false);

    expect(plan.invitedLine, isNull);
  });
}
