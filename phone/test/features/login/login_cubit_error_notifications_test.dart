import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pub_semver/pub_semver.dart';

import 'package:api/api.dart';

import 'package:webtrit_phone/app/notifications/notifications.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/features/login/login.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockAppInfo extends Mock implements AppInfo {}

class _MockPackageInfo extends Mock implements PackageInfo {}

RequestFailure _requestFailure(String code, {int statusCode = 422}) {
  return RequestFailure(
    url: Uri.parse('https://demo.example.com/api/v1/session/otp-create'),
    statusCode: statusCode,
    requestId: 'test-request-id',
    error: ErrorResponse(code: code),
  );
}

void main() {
  late _MockAuthRepository authRepository;
  late NotificationsBloc notificationsBloc;

  setUp(() {
    authRepository = _MockAuthRepository();
    notificationsBloc = NotificationsBloc();
  });

  tearDown(() {
    notificationsBloc.close();
  });

  LoginCubit buildCubit() {
    final appInfo = _MockAppInfo();
    when(() => appInfo.version).thenReturn(Version.parse('1.0.0'));
    final packageInfo = _MockPackageInfo();
    when(() => packageInfo.version).thenReturn('0.0.0');
    when(() => packageInfo.buildNumber).thenReturn('0');
    return LoginCubit(
      authRepository: authRepository,
      notificationsBloc: notificationsBloc,
      appInfo: appInfo,
      packageInfo: packageInfo,
      appCompatibilityResolver: const DefaultAppCompatibilityResolver(),
      onLoginSuccess: (_, _) {},
    );
  }

  test('maps delivery_channel_unspecified to a visible notification', () async {
    final cubit = buildCubit();

    cubit.handleError(_requestFailure('delivery_channel_unspecified'), StackTrace.current, 'test');
    await pumpEventQueue();

    final notification = notificationsBloc.state.lastNotification;
    expect(notification, isA<LoginDeliveryChannelUnspecifiedNotification>());
    // The OTP user reference input is untouched, so the error cannot be
    // attributed to the OTP sign-in form and the message stays generic.
    expect((notification as LoginDeliveryChannelUnspecifiedNotification).identifiers, isEmpty);
  });

  test('delivery_channel_unspecified carries the advertised identifiers when the OTP form was used', () async {
    final cubit = buildCubit();
    cubit.otpSigninUserRefInputChanged('380441234567');

    cubit.handleError(_requestFailure('delivery_channel_unspecified'), StackTrace.current, 'test');
    await pumpEventQueue();

    final notification = notificationsBloc.state.lastNotification;
    expect(notification, isA<LoginDeliveryChannelUnspecifiedNotification>());
    expect((notification as LoginDeliveryChannelUnspecifiedNotification).identifiers, cubit.state.otpSigninIdentifiers);
  });

  test('maps empty_email to a visible notification', () async {
    final cubit = buildCubit();

    cubit.handleError(_requestFailure('empty_email'), StackTrace.current, 'test');
    await pumpEventQueue();

    expect(notificationsBloc.state.lastNotification, isA<LoginEmptyEmailNotification>());
  });

  test('names refused credentials even though the backend sent no code', () async {
    final cubit = buildCubit();

    cubit.handleError(
      IncorrectCredentialsException(
        url: Uri.parse('https://demo.example.com/api/v1/session'),
        requestId: 'test-request-id',
        statusCode: 401,
        error: const ErrorResponse(message: 'User authentication error'),
      ),
      StackTrace.current,
      'test',
    );
    await pumpEventQueue();

    expect(notificationsBloc.state.lastNotification, isA<LoginIncorrectCredentialsNotification>());
  });

  test('a failure with no wording of its own still reaches the user', () async {
    final cubit = buildCubit();

    cubit.handleError(_requestFailure('something_the_app_never_heard_of'), StackTrace.current, 'test');
    await pumpEventQueue();

    expect(notificationsBloc.state.lastNotification, isA<LoginUnexpectedErrorNotification>());
  });

  test('a transport failure reaches the user as well', () async {
    final cubit = buildCubit();

    cubit.handleError(const SocketException('no route to host'), StackTrace.current, 'test');
    await pumpEventQueue();

    expect(notificationsBloc.state.lastNotification, isA<LoginUnexpectedErrorNotification>());
  });
}
