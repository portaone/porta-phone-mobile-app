import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto_route/auto_route.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/features/settings/features/media_settings/media_settings.dart';
import 'package:webtrit_phone/features/settings/features/media_settings/view/components/audio_processing_content.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';

import '../../../../../helpers/helpers.dart';

class _MockMediaSettingsCubit extends MockCubit<MediaSettingsState> implements MediaSettingsCubit {}

class _MockStackRouter extends Mock implements StackRouter {}

MediaSettingsState _state(AudioProcessingSettings audioProcessingSettings) => MediaSettingsState(
  encodingSettings: EncodingSettings.blank(),
  encodingPreset: null,
  audioProcessingSettings: audioProcessingSettings,
  videoCapturingSettings: VideoCapturingSettings.blank(),
  iceSettings: IceSettings.blank(),
  pearConnectionSettings: PeerConnectionSettings.blank(),
  certificateVerificationConfigurable: false,
  speakerOnMinimize: false,
  speakerOnMinimizeConfigurable: false,
);

void main() {
  setUpAll(() => registerFallbackValue(AudioProcessingSettings.blank()));

  late _MockMediaSettingsCubit cubit;

  setUp(() {
    cubit = _MockMediaSettingsCubit();
    when(() => cubit.setAudioProcessingSettings(any())).thenReturn(null);
    when(() => cubit.voiceNoiseReductionDefault).thenReturn(false);
  });

  Widget wrap() => MaterialApp(
    localizationsDelegates: appLocalizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SingleChildScrollView(
        child: BlocProvider<MediaSettingsCubit>.value(value: cubit, child: const AudioProcessingContent()),
      ),
    ),
  );

  final offId = settingsOptionId(mediaSettingsOptionIdPrefix, 'audioProcessingVnrOff');
  final onId = settingsOptionId(mediaSettingsOptionIdPrefix, 'audioProcessingVnrOn');

  testWidgets('the audio processing section opens through semantics and shows the switch', (tester) async {
    final handle = tester.ensureSemantics();
    when(() => cubit.state).thenReturn(_state(AudioProcessingSettings.blank()));
    final router = _MockStackRouter();
    when(
      () => router.canPop(
        ignoreChildRoutes: any(named: 'ignoreChildRoutes'),
        ignoreParentRoutes: any(named: 'ignoreParentRoutes'),
        ignorePagelessRoutes: any(named: 'ignorePagelessRoutes'),
      ),
    ).thenReturn(false);
    when(() => router.topPage).thenReturn(null);
    when(() => router.pagelessRoutesObserver).thenReturn(PagelessRoutesObserver());

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: RouterScope(
          controller: router,
          inheritableObserversBuilder: () => const [],
          stateHash: 0,
          navigatorObservers: const [],
          child: StackRouterScope(
            controller: router,
            stateHash: 0,
            child: BlocProvider<MediaSettingsCubit>.value(value: cubit, child: const MediaSettingsScreen()),
          ),
        ),
      ),
    );
    final section = find.bySemanticsIdentifier(mediaSettingsAudioProcessingSectionId);
    expect(section, findsOneWidget);
    expect(find.bySemanticsIdentifier(offId), findsNothing);

    await tapViaSemantics(tester, section);
    await tester.pumpAndSettle();

    expect(find.bySemanticsIdentifier(offId), findsOneWidget);

    handle.dispose();
  });

  testWidgets('voice noise reduction is off until chosen and has only off and on', (tester) async {
    final handle = tester.ensureSemantics();
    when(() => cubit.state).thenReturn(_state(AudioProcessingSettings.blank()));

    await tester.pumpWidget(wrap());

    expect(find.bySemanticsIdentifier(offId), findsOneWidget);
    expect(find.bySemanticsIdentifier(onId), findsOneWidget);
    expect(
      find.bySemanticsIdentifier(settingsOptionId(mediaSettingsOptionIdPrefix, 'audioProcessingVnrAuto')),
      findsNothing,
    );
    expect(tester.getSemantics(find.bySemanticsIdentifier(offId)), isSemantics(isChecked: true, hasTapAction: true));
    expect(tester.getSemantics(find.bySemanticsIdentifier(onId)), isSemantics(isChecked: false, hasTapAction: true));

    handle.dispose();
  });

  testWidgets('choosing on through semantics saves it and keeps the other settings', (tester) async {
    final handle = tester.ensureSemantics();
    const before = AudioProcessingSettings(noiseSuppression: false);
    when(() => cubit.state).thenReturn(_state(before));

    await tester.pumpWidget(wrap());
    await tapViaSemantics(tester, find.bySemanticsIdentifier(onId));

    final saved =
        verify(() => cubit.setAudioProcessingSettings(captureAny())).captured.single as AudioProcessingSettings;
    expect(saved.voiceNoiseReduction, isTrue);
    expect(saved.noiseSuppression, isFalse);

    handle.dispose();
  });

  testWidgets('choosing off through semantics stores off', (tester) async {
    final handle = tester.ensureSemantics();
    when(() => cubit.state).thenReturn(_state(const AudioProcessingSettings(voiceNoiseReduction: true)));

    await tester.pumpWidget(wrap());
    await tapViaSemantics(tester, find.bySemanticsIdentifier(offId));

    final saved =
        verify(() => cubit.setAudioProcessingSettings(captureAny())).captured.single as AudioProcessingSettings;
    expect(saved.voiceNoiseReduction, isFalse);

    handle.dispose();
  });

  testWidgets('a deployment that turns it on shows on until the person chooses', (tester) async {
    final handle = tester.ensureSemantics();
    when(() => cubit.voiceNoiseReductionDefault).thenReturn(true);
    when(() => cubit.state).thenReturn(_state(AudioProcessingSettings.blank()));

    await tester.pumpWidget(wrap());

    expect(tester.getSemantics(find.bySemanticsIdentifier(onId)), isSemantics(isChecked: true, hasTapAction: true));
    expect(tester.getSemantics(find.bySemanticsIdentifier(offId)), isSemantics(isChecked: false, hasTapAction: true));

    handle.dispose();
  });

  testWidgets('a person who chose off keeps it off when the deployment turns it on', (tester) async {
    final handle = tester.ensureSemantics();
    when(() => cubit.voiceNoiseReductionDefault).thenReturn(true);
    when(() => cubit.state).thenReturn(_state(const AudioProcessingSettings(voiceNoiseReduction: false)));

    await tester.pumpWidget(wrap());

    expect(tester.getSemantics(find.bySemanticsIdentifier(offId)), isSemantics(isChecked: true, hasTapAction: true));
    expect(tester.getSemantics(find.bySemanticsIdentifier(onId)), isSemantics(isChecked: false, hasTapAction: true));

    handle.dispose();
  });
}
