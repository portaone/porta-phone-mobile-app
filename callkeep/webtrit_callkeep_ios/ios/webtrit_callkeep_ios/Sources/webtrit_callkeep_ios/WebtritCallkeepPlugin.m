#import "WebtritCallkeepPlugin.h"

#import <AVFoundation/AVFoundation.h>
#import <PushKit/PushKit.h>
#import <CallKit/CallKit.h>
#import <Intents/Intents.h>
#import <UserNotifications/UserNotifications.h>

#import "Generated.h"
#import "Converters.h"
#import "NSUUID+v5.h"
#import "CallWaitingTonePlayer.h"
#import <os/log.h>

// The plugin's lines that reach the device log of a release build. NSLog's arguments are shown as
// <private> there, so the UUIDs of the calls and the errors of CallKit could not be read; os_log
// with the whole message public keeps them. The UUIDs are derived from the server's callId - no
// number or name is written.
#define WTPLog(fmt, ...) \
  os_log(OS_LOG_DEFAULT, "%{public}s", [[NSString stringWithFormat:(fmt), ##__VA_ARGS__] UTF8String])
#import "CallPresentations.h"

static NSString *const OptionsKey = @"WebtritCallkeepPluginOptions";

/// How long after CallKit activates the audio session an unrequested unmute is taken for the
/// session coming back up rather than for a person - see performSetMutedCallAction.
static const CFAbsoluteTime kAudioSessionMuteResyncWindow = 1.0;

@interface WebtritCallkeepPlugin ()<PKPushRegistryDelegate, CXProviderDelegate, CXCallObserverDelegate, WTPPushRegistryHostApi, WTPHostApi, WTPHostSoundApi>
@end

@implementation WebtritCallkeepPlugin {
  NSObject<FlutterPluginRegistrar> *_registrar;
  WTPPushRegistryDelegateFlutterApi *_pushRegistryDelegateFlutterApi;
  PKPushRegistry *_pushRegistry;
  WTPDelegateFlutterApi *_delegateFlutterApi;
  CXProvider *_provider;
  AVAudioPlayer *_ringback;
  CallWaitingTonePlayer *_callWaitingTone;
  NSMutableSet<NSUUID *> *_ownCallUuids;
  NSMutableSet<NSUUID *> *_videoCallUuids;
  NSMutableSet<NSUUID *> *_answeringCallUuids;
  // CallKit UUIDs of calls whose end CallKit asked for and the application has not answered yet.
  // Such a call is on its way out by the user's word: it is not taken out of CallKit to come back
  // later - see answerQueuedIncomingCallUUID.
  NSMutableSet<NSUUID *> *_endingCallUuids;
  // Group actions this plugin asked CallKit for, by action UUID, until CallKit answers them.
  NSMutableSet<NSUUID *> *_requestedGroupActionUuids;
  // The calls of the current group, and this plugin's own hold changes on them by action UUID
  // until the delegate performs them - see "Group hold".
  NSMutableSet<NSUUID *> *_groupMemberUuids;
  NSMutableSet<NSUUID *> *_groupHoldActionUuids;
  // Mute actions this plugin asked CallKit for, by action UUID; the calls last known muted; and
  // when CallKit last activated the audio session - see performSetMutedCallAction.
  NSMutableSet<NSUUID *> *_ownMuteActionUuids;
  // End actions this plugin asked CallKit for, by action UUID, with who asked (a WTPEndedByEnum).
  // CallKit hands the app's own end back as the same performEndCallAction a tap on the CallKit UI
  // produces; this is how the delegate learns which of the two it was.
  NSMutableDictionary<NSUUID *, NSNumber *> *_ownEndActionInitiators;
  NSMutableSet<NSUUID *> *_mutedCallUuids;
  CFAbsoluteTime _audioSessionActivatedAt;
  BOOL _callWaitingToneOwnCallsOnly;
  CXCallController *_callController;
  BOOL _driveIdleTimerDisabled;
  // The incoming queue (queueIncomingWhileRinging) - see "Incoming queue". The calls that came
  // while another of ours rang in CallKit, oldest first, and the update each one enters CallKit
  // with; and the calls admitted to CallKit as incoming - from the moment their report is sent
  // until the call observer shows them connected or ended, or the report fails. The observer
  // learns of a call later than the report's completion says it was taken, and the pushes of a
  // cold start arrive milliseconds apart: a call counts as ringing all that time.
  BOOL _queueIncomingWhileRinging;
  NSMutableArray<NSUUID *> *_queuedIncomingUuids;
  NSMutableDictionary<NSUUID *, CXCallUpdate *> *_queuedIncomingUpdates;
  NSMutableSet<NSUUID *> *_admittedIncomingUuids;
  // Under which UUID CallKit shows each incoming call, now and before: a call this plugin takes
  // out of CallKit to let a waiting one be answered comes back under a new UUID, while the
  // application goes on naming it by its own - see "Incoming queue" and CallPresentations.h. And
  // the update every incoming call was last reported with, by the application's UUID, for such a
  // return.
  CallPresentations *_presentations;
  NSMutableDictionary<NSUUID *, CXCallUpdate *> *_incomingUpdates;
  // The hold before a third call (holdActiveBeforeThirdIncoming) - see "Hold before a third call".
  // For each incoming call whose report waits for this plugin to hold an active call of ours, by
  // the incoming call's CallKit UUID: the call it held, to take off hold again once CallKit has
  // the report.
  BOOL _holdActiveBeforeThirdIncoming;
  NSMutableDictionary<NSUUID *, NSUUID *> *_heldForIncoming;
  // The hold changes of the hold before a third call: CallKit's only, fulfilled without asking
  // the application.
  NSMutableSet<NSUUID *> *_screenHoldActionUuids;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  WebtritCallkeepPlugin *instance = [[WebtritCallkeepPlugin alloc] initWithRegistrar:registrar];
  [instance restoreSetUp];
  [registrar addApplicationDelegate:instance];
  [registrar publish:instance];
}

- (instancetype)initWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
#ifdef DEBUG
  NSLog(@"[Callkeep][initWithRegistrar:]");
#endif
  self = [super init];
  if (self) {
    _registrar = registrar;
    NSObject<FlutterBinaryMessenger> *binaryMessenger = [_registrar messenger];
    _pushRegistryDelegateFlutterApi = [[WTPPushRegistryDelegateFlutterApi alloc] initWithBinaryMessenger:binaryMessenger];
    SetUpWTPPushRegistryHostApi(binaryMessenger, self);
    _delegateFlutterApi = [[WTPDelegateFlutterApi alloc] initWithBinaryMessenger:binaryMessenger];
    SetUpWTPHostApi(binaryMessenger, self);
    SetUpWTPHostSoundApi(binaryMessenger, self);
    // Created eagerly so it can be pre-warmed from the very first
    // didActivateAudioSession callback, not from the first play request.
    _callWaitingTone = [[CallWaitingTonePlayer alloc] init];
    _ownCallUuids = [NSMutableSet set];
    _videoCallUuids = [NSMutableSet set];
    _answeringCallUuids = [NSMutableSet set];
    _endingCallUuids = [NSMutableSet set];
    _requestedGroupActionUuids = [NSMutableSet set];
    _groupMemberUuids = [NSMutableSet set];
    _groupHoldActionUuids = [NSMutableSet set];
    _ownMuteActionUuids = [NSMutableSet set];
    _ownEndActionInitiators = [NSMutableDictionary dictionary];
    _mutedCallUuids = [NSMutableSet set];
    _queuedIncomingUuids = [NSMutableArray array];
    _queuedIncomingUpdates = [NSMutableDictionary dictionary];
    _admittedIncomingUuids = [NSMutableSet set];
    _presentations = [[CallPresentations alloc] init];
    _incomingUpdates = [NSMutableDictionary dictionary];
    _heldForIncoming = [NSMutableDictionary dictionary];
    _screenHoldActionUuids = [NSMutableSet set];
    _callWaitingToneOwnCallsOnly = YES;
  }
  return self;
}

- (void)dealloc {
#ifdef DEBUG
  NSLog(@"[Callkeep][dealloc]");
#endif
  NSObject<FlutterBinaryMessenger> *binaryMessenger = [_registrar messenger];
  SetUpWTPHostApi(binaryMessenger, nil);
  SetUpWTPPushRegistryHostApi(binaryMessenger, nil);
  SetUpWTPHostSoundApi(binaryMessenger, nil);
}

- (BOOL)isSetUp {
  if (_provider != nil) {
#ifdef DEBUG
    NSLog(@"[Callkeep][isSetUp] YES");
#endif
    return YES;
  } else {
#ifdef DEBUG
    NSLog(@"[Callkeep][isSetUp] NO");
#endif
    return NO;
  }
}

- (void)restoreSetUp {
  WTPIOSOptions *iosOptions = [self getUserDefaultsIosOptions];
  if (iosOptions != nil) {
#ifdef DEBUG
    NSLog(@"[Callkeep][restoreSetUp] processed");
#endif
    _pushRegistry = [[PKPushRegistry alloc] initWithQueue:nil];
    _pushRegistry.delegate = self;
    _pushRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];

    _provider = [[CXProvider alloc] initWithConfiguration:[iosOptions toCallKitWithRegistrar:_registrar]];
    [_provider setDelegate:self queue:nil];

    _callController = [[CXCallController alloc] init];
    [_callController.callObserver setDelegate:self queue:dispatch_get_main_queue()];
    [self syncCallWaitingTone:_callController.callObserver];

    _callWaitingToneOwnCallsOnly =
        iosOptions.callWaitingToneOwnCallsOnly == nil || iosOptions.callWaitingToneOwnCallsOnly.boolValue;
    _queueIncomingWhileRinging =
        iosOptions.queueIncomingWhileRinging != nil && iosOptions.queueIncomingWhileRinging.boolValue;
    _holdActiveBeforeThirdIncoming =
        iosOptions.holdActiveBeforeThirdIncoming != nil && iosOptions.holdActiveBeforeThirdIncoming.boolValue;

    if (iosOptions.ringbackSound != nil) {
      _ringback = [self createRingbackPlayer:iosOptions.ringbackSound];
    }
 
    _driveIdleTimerDisabled = iosOptions.driveIdleTimerDisabled;
  } else {
#ifdef DEBUG
    NSLog(@"[Callkeep][restoreSetUp] skipped");
#endif
  }
}

#pragma mark - WTPPushRegistryHostApi

- (nullable NSString *)pushTokenForPushTypeVoIP:(FlutterError **)error {
  if (_pushRegistry != nil) {
#ifdef DEBUG
    NSLog(@"[Callkeep][pushTokenForPushTypeVoIP] processed");
#endif
    return [[_pushRegistry pushTokenForType:PKPushTypeVoIP] toHexString];
  } else {
#ifdef DEBUG
    NSLog(@"[Callkeep][pushTokenForPushTypeVoIP] skipped");
#endif
    return nil;
  }
}

#pragma mark - WTPHostApi

- (nullable NSNumber *)isSetUp:(FlutterError **)error {
  return @([self isSetUp]);
}

- (void)setUp:(WTPOptions *)options
   completion:(void (^)(FlutterError *))completion {
  WTPIOSOptions *iosOptions = options.ios;
  if ([self setUserDefaultsIosOptions:iosOptions] == YES) {
#ifdef DEBUG
    NSLog(@"[Callkeep][setUp] processed");
#endif
    // apply new options
    if (_pushRegistry == nil) {
      _pushRegistry = [[PKPushRegistry alloc] initWithQueue:nil];
      _pushRegistry.delegate = self;
      _pushRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
    }
    if (_provider == nil) {
      _provider = [[CXProvider alloc] initWithConfiguration:[iosOptions toCallKitWithRegistrar:_registrar]];
      [_provider setDelegate:self queue:nil];
    } else {
      _provider.configuration = [iosOptions toCallKitWithRegistrar:_registrar];
    }
    if (_callController == nil) {
      _callController = [[CXCallController alloc] init];
      [_callController.callObserver setDelegate:self queue:dispatch_get_main_queue()];
      [self syncCallWaitingTone:_callController.callObserver];
    }
    _callWaitingToneOwnCallsOnly =
        iosOptions.callWaitingToneOwnCallsOnly == nil || iosOptions.callWaitingToneOwnCallsOnly.boolValue;
    _queueIncomingWhileRinging =
        iosOptions.queueIncomingWhileRinging != nil && iosOptions.queueIncomingWhileRinging.boolValue;
    _holdActiveBeforeThirdIncoming =
        iosOptions.holdActiveBeforeThirdIncoming != nil && iosOptions.holdActiveBeforeThirdIncoming.boolValue;
    
    if (_ringback == nil && iosOptions.ringbackSound != nil) {
      _ringback = [self createRingbackPlayer:iosOptions.ringbackSound];
    }
    
    _driveIdleTimerDisabled = iosOptions.driveIdleTimerDisabled;
  } else {
#ifdef DEBUG
    NSLog(@"[Callkeep][setUp] skipped");
#endif
  }
  completion(nil);
}

- (void)tearDown:(void (^)(FlutterError *))completion {
#ifdef DEBUG
  NSLog(@"[Callkeep][tearDown]");
#endif
  if (_callController != nil) {
    [_callController.callObserver setDelegate:nil queue:nil];
    _callController = nil;
  }
  [_callWaitingTone stop];
  [_ownCallUuids removeAllObjects];
  [_answeringCallUuids removeAllObjects];
  // An end action still in flight never reaches performEndCallAction once the plugin is done.
  [_ownEndActionInitiators removeAllObjects];
  [_endingCallUuids removeAllObjects];
  // The plugin is done with its calls: no video call of ours is live any more, so the screen
  // it kept awake is released here rather than left to a setUp() that never clears this set.
  [_videoCallUuids removeAllObjects];
  [self refreshIdleTimer];
  [self forgetIncomingQueue];
  [_heldForIncoming removeAllObjects];
  [_screenHoldActionUuids removeAllObjects];
  if (_provider != nil) {
    [_provider invalidate];
    _provider = nil;
  }
  if (_pushRegistry != nil) {
    _pushRegistry.desiredPushTypes = [NSSet set];
    _pushRegistry = nil;
  }
  [self removeUserDefaultsIosOptions];
  completion(nil);
}

- (void)reportNewIncomingCall:(NSString *)uuidString
                       handle:(WTPHandle *)handle
                  displayName:(NSString *)displayName
                     hasVideo:(BOOL)hasVideo
                   completion:(void (^)(WTPIncomingCallError *, FlutterError *))completion {
#ifdef DEBUG
  NSLog(@"[Callkeep][reportNewIncomingCall] uuidString = %@", uuidString);
#endif
  CXCallUpdate *callUpdate = [[CXCallUpdate alloc] init];
  callUpdate.remoteHandle = [handle toCallKit];
  callUpdate.localizedCallerName = displayName;
  callUpdate.hasVideo = hasVideo;
  callUpdate.supportsGrouping = NO;
  callUpdate.supportsUngrouping = NO;
  callUpdate.supportsHolding = YES;
  callUpdate.supportsDTMF = YES;
  NSUUID *callUuid = [[NSUUID alloc] initWithUUIDString:uuidString];
  if ([self shouldQueueIncomingCallUUID:callUuid]) {
    // Another call of ours rings: this one waits outside CallKit. For the caller it is presented -
    // the application has it and shows it - and CallKit learns of it once nothing else rings.
    [self queueIncomingCallUUID:callUuid update:callUpdate];
    completion(nil, nil);
    return;
  }
  // The call's live presentation, so that CallKit sees a duplicate of it, or a new one.
  NSUUID *logicalUuid = callUuid;
  callUuid = callUuid != nil ? [_presentations presentationToReportForLogicalUUID:callUuid].callKitUUID : nil;
  if (callUuid != nil) {
    [_ownCallUuids addObject:callUuid];
    [self admitIncomingCallUUID:callUuid];
    _incomingUpdates[logicalUuid] = callUpdate;
  }
  [self holdActiveBeforeReportingIncomingCallUUID:callUuid then:^{
    [self->_provider reportNewIncomingCallWithUUID:callUuid
                                            update:callUpdate
                                        completion:^(NSError *error) {
                                          dispatch_async(dispatch_get_main_queue(), ^{
                                            [self settleAdmittedIncomingCallUUID:callUuid afterReportError:error];
                                            [self resumeCallHeldForReportedIncomingCallUUID:callUuid];
                                            [self releaseQueuedIncomingIfNothingRings];
                                          });
                                          if (error == nil) {
                                            // Only for a call that is still ours: this completion can run
                                            // after the call ended, was reset or torn down, and must not
                                            // bring its video state back then.
                                            if ([self isLiveOwnCallUUID:callUuid]) {
                                              [self setVideo:callUpdate.hasVideo forCallUUID:callUuid];
                                            }
                                            completion(nil, nil);
                                          } else if ([error.domain isEqualToString:CXErrorDomainIncomingCall]) {
                                            completion([WTPIncomingCallError makeWithValue:CXErrorCodeIncomingCallErrorToPigeon((CXErrorCodeIncomingCallError) error.code)], nil);
                                          } else {
                                            completion(nil, [FlutterError errorWithCode:error.domain
                                                                                message:[error description]
                                                                                details:nil]);
                                          }
                                        }];
  }];
}

- (void)reportConnectingOutgoingCall:(NSString *)uuidString
                          completion:(void (^)(FlutterError *))completion {
#ifdef DEBUG
  NSLog(@"[Callkeep][reportConnectingOutgoingCall] uuidString = %@", uuidString);
#endif
  [_provider reportOutgoingCallWithUUID:[[NSUUID alloc] initWithUUIDString:uuidString]
                startedConnectingAtDate:nil];
  completion(nil);
}

- (void)reportConnectedOutgoingCall:(NSString *)uuidString
                         completion:(void (^)(FlutterError *))completion {
#ifdef DEBUG
  NSLog(@"[Callkeep][reportConnectedOutgoingCall] uuidString = %@", uuidString);
#endif
  [_provider reportOutgoingCallWithUUID:[[NSUUID alloc] initWithUUIDString:uuidString]
                        connectedAtDate:nil];
  completion(nil);
}

- (void)reportUpdateCall:(NSString *)uuidString
                  handle:(nullable WTPHandle *)handle
             displayName:(nullable NSString *)displayName
                hasVideo:(nullable NSNumber *)hasVideo
        proximityEnabled:(nullable NSNumber *)proximityEnabled
              completion:(void (^)(FlutterError *))completion {
#ifdef DEBUG
  NSLog(@"[Callkeep][reportUpdateCall] uuidString = %@", uuidString);
#endif
  CXCallUpdate *callUpdate = [[CXCallUpdate alloc] init];
  if (handle != nil) {
    callUpdate.remoteHandle = [handle toCallKit];
  }
  if (displayName != nil) {
    callUpdate.localizedCallerName = displayName;
  }
  if (hasVideo != nil) {
    callUpdate.hasVideo = [hasVideo boolValue];
  }
  if (proximityEnabled != nil) {
     if ([proximityEnabled boolValue]) {
          [[AVAudioSession sharedInstance] setMode: AVAudioSessionModeVoiceChat error:nil];
     } else {
//          Can cause bug when the speaker automatically turns on during audio calls at the moment when the user declines an active call
//          needs additional testing
          [[AVAudioSession sharedInstance] setMode: AVAudioSessionModeVideoChat error:nil];
     }
  }
    
  NSUUID *updateUuid = [[NSUUID alloc] initWithUUIDString:uuidString];
  CXCallUpdate *queued = updateUuid != nil ? _queuedIncomingUpdates[updateUuid] : nil;
  if (queued != nil) {
    // Not in CallKit yet: the update is kept for the moment the call enters it.
    if (handle != nil) queued.remoteHandle = callUpdate.remoteHandle;
    if (displayName != nil) queued.localizedCallerName = displayName;
    if (hasVideo != nil) queued.hasVideo = callUpdate.hasVideo;
    completion(nil);
    return;
  }
  CXCallUpdate *reported = updateUuid != nil ? _incomingUpdates[updateUuid] : nil;
  if (reported != nil) {
    if (handle != nil) reported.remoteHandle = callUpdate.remoteHandle;
    if (displayName != nil) reported.localizedCallerName = displayName;
    if (hasVideo != nil) reported.hasVideo = callUpdate.hasVideo;
  }
  [_provider reportCallWithUUID:[self presentedUuidFor:updateUuid]
                        updated:callUpdate];
  // Only when the caller actually said something about video. This is a partial update, and
  // an unset hasVideo reads as NO on a fresh CXCallUpdate - taking that at face value let an
  // update carrying nothing but a display name put a live video call's screen back to sleep.
  if (hasVideo != nil) {
    [self setVideo:[hasVideo boolValue] forCallUUID:[self presentedUuidFor:updateUuid]];
  }
  completion(nil);
}

- (void)reportEndCall:(NSString *)uuidString
                displayName:(NSString *)displayName
               reason:(WTPEndCallReason *)reason
           completion:(void (^)(FlutterError *))completion {
#ifdef DEBUG
  NSLog(@"[Callkeep][reportEndCall] uuidString = %@", uuidString);
#endif
    
  NSUUID *endedLogicalUuid = [[NSUUID alloc] initWithUUIDString:uuidString];
  NSUUID *endedUuid = [self presentedUuidFor:endedLogicalUuid];
  if (![self dequeueIncomingCallUUID:endedLogicalUuid]) {
    [_provider reportCallWithUUID:endedUuid
                      endedAtDate:nil
                           reason:[reason toCallKit]];
  }
  [self forgetCall:endedUuid];
  if (endedLogicalUuid != nil) {
    // The call is over for the application: nothing of it is shown again.
    [_presentations forgetLogicalUUID:endedLogicalUuid];
    [_incomingUpdates removeObjectForKey:endedLogicalUuid];
  }
  // A waiting call is let in here and now, in the step that ends the one before it - not when the
  // call observer comes round to saying so. An app in the background lives only while it has a call
  // in CallKit: once the last one is gone iOS suspends it, the observer's word is never handled, and
  // the waiting call would go on ringing for its caller with nothing on the phone to show it.
  [self releaseQueuedIncomingIfNothingRings];
    
    if ([reason toCallKit] == CXCallEndedReasonUnanswered) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];

        UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
        content.title = @"Missed Call";
        content.body = displayName;
        content.sound = [UNNotificationSound defaultSound];
        
        NSString *identifier = [NSString stringWithFormat:@"missed call-%@", displayName];

        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:nil];

        [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
          if (error != nil) {
            WTPLog(@"[Callkeep][reportEndCall] Error adding notification: %@", error);
          }
        }];
    }

  completion(nil);
}

- (void)             startCall:(NSString *)uuidString
                        handle:(WTPHandle *)handle
displayNameOrContactIdentifier:(NSString *)displayNameOrContactIdentifier
                         video:(BOOL)video
              proximityEnabled:(BOOL)proximityEnabled
                    completion:(void (^)(WTPCallRequestError *, FlutterError *))completion {
#ifdef DEBUG
  NSLog(@"[Callkeep][startCall] uuidString = %@", uuidString);
#endif
  NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
    
// Can be ignored, coz webrtc doing same on getusermedia before call
// and needs to edit package to override this behavior, so we can let it go
// if (proximityEnabled) {
//     [[AVAudioSession sharedInstance] setMode: AVAudioSessionModeVoiceChat error:nil];
// } else {
//     [[AVAudioSession sharedInstance] setMode: AVAudioSessionModeVideoChat error:nil];
// }

  CXStartCallAction *action = [[CXStartCallAction alloc] initWithCallUUID:uuid
                                                                   handle:[handle toCallKit]];
  if (displayNameOrContactIdentifier != nil) {
    action.contactIdentifier = displayNameOrContactIdentifier;
  }
  action.video = video;
  NSMutableArray<CXAction *> *actions = [[self holdActionsForGroup:_groupMemberUuids onHold:YES] mutableCopy];
  [actions addObject:action];
  CXTransaction *transaction = [[CXTransaction alloc] initWithActions:actions];

  [self requestGroupHoldTransaction:transaction completion:^(WTPCallRequestError *pigeonError, FlutterError *flutterError) {
    if (pigeonError == nil && flutterError == nil) {
      CXCallUpdate *callUpdate = [[CXCallUpdate alloc] init];
      callUpdate.remoteHandle = action.handle;
      callUpdate.localizedCallerName = action.contactIdentifier;
      callUpdate.hasVideo = action.video;
      callUpdate.supportsGrouping = NO;
      callUpdate.supportsUngrouping = NO;
      callUpdate.supportsHolding = YES;
      callUpdate.supportsDTMF = YES;
      [self->_provider reportCallWithUUID:uuid
                                  updated:callUpdate];

      completion(nil, nil);
    } else {
      completion(pigeonError, flutterError);
    }
  }];
}

- (void)answerCall:(NSString *)uuidString
        completion:(void (^)(WTPCallRequestError *, FlutterError *))completion {
#ifdef DEBUG
  NSLog(@"[Callkeep][answerCall] uuidString = %@", uuidString);
#endif
  NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
  if ([_queuedIncomingUuids containsObject:uuid]) {
    [self answerQueuedIncomingCallUUID:uuid completion:completion];
    return;
  }
  [self requestAnswerOfCallUUID:[self presentedUuidFor:uuid] completion:completion];
}

- (void)requestAnswerOfCallUUID:(NSUUID *)uuid
                     completion:(void (^)(WTPCallRequestError *, FlutterError *))completion {
  CXAnswerCallAction *action = [[CXAnswerCallAction alloc] initWithCallUUID:uuid];
  NSMutableArray<CXAction *> *actions = [[self holdActionsForGroup:_groupMemberUuids onHold:YES] mutableCopy];
  [actions addObject:action];

  // Answering from this request on, not from the provider's perform: the queue must not take the
  // call out of CallKit while the answer is on its way - see answerQueuedIncomingCallUUID.
  [_answeringCallUuids addObject:uuid];
  __weak typeof(self) weakSelf = self;
  [self requestGroupHoldTransaction:[[CXTransaction alloc] initWithActions:actions]
                         completion:^(WTPCallRequestError *error, FlutterError *flutterError) {
    typeof(self) strongSelf = weakSelf;
    if (strongSelf != nil && (error != nil || flutterError != nil)) {
      [strongSelf->_answeringCallUuids removeObject:uuid];
    }
    completion(error, flutterError);
  }];
}

- (void)setSpeaker:(NSString *)uuidString
        enabled:(BOOL)enabled
      completion:(void (^)(WTPCallRequestError *, FlutterError *))completion {
#ifdef DEBUG
    NSLog(@"[Callkeep][setSpeaker] uuidString = %@ muted = %d", uuidString, enabled);
#endif
}

- (void)endCall:(NSString *)uuidString
        endedBy:(WTPEndedByEnum)endedBy
     completion:(void (^)(WTPCallRequestError *, FlutterError *))completion {
#ifdef DEBUG
  NSLog(@"[Callkeep][endCall] uuidString = %@ endedBy = %lu", uuidString, (unsigned long)endedBy);
#endif
  NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
  if ([self dequeueIncomingCallUUID:uuid]) {
    // CallKit has no entry to end: the application is told what a fulfilled end would have told
    // it, so the call ends on its side the way any other does.
    [_delegateFlutterApi performEndCall:uuidString endedBy:endedBy completion:^(NSNumber *fulfill, FlutterError *error) {}];
    completion(nil, nil);
    return;
  }
  uuid = [self presentedUuidFor:uuid];
  CXEndCallAction *endAction = [[CXEndCallAction alloc] initWithCallUUID:uuid];
  _ownEndActionInitiators[endAction.UUID] = @(endedBy);
  NSMutableArray<CXAction *> *actions = [NSMutableArray arrayWithObject:endAction];
  if (![_groupMemberUuids containsObject:uuid] && ![self isCallOutsideGroup:_groupMemberUuids activeIgnoring:uuid]) {
    // Resumed in the same transaction rather than after the end is seen: in between CallKit has
    // no active call, deactivates the audio session and brings it straight back.
    [actions addObjectsFromArray:[self holdActionsForGroup:_groupMemberUuids onHold:NO]];
  }

  __weak typeof(self) weakSelf = self;
  [self requestGroupHoldTransaction:[[CXTransaction alloc] initWithActions:actions]
                         completion:^(WTPCallRequestError *error, FlutterError *flutterError) {
                           typeof(self) strongSelf = weakSelf;
                           // A refused transaction never reaches performEndCallAction.
                           if (strongSelf != nil && (error != nil || flutterError != nil)) {
                             [strongSelf->_ownEndActionInitiators removeObjectForKey:endAction.UUID];
                           }
                           completion(error, flutterError);
                         }];
}

- (void)setHeld:(NSString *)uuidString
         onHold:(BOOL)onHold
     completion:(void (^)(WTPCallRequestError *, FlutterError *))completion {
#ifdef DEBUG
  NSLog(@"[Callkeep][setHeld] uuidString = %@ held = %d", uuidString, onHold);
#endif
  NSUUID *uuid = [self presentedUuidFor:[[NSUUID alloc] initWithUUIDString:uuidString]];
  CXSetHeldCallAction *action = [[CXSetHeldCallAction alloc] initWithCallUUID:uuid onHold:onHold];
  NSMutableArray<CXAction *> *actions = [NSMutableArray arrayWithObject:action];
  if (![_groupMemberUuids containsObject:uuid]) {
    // Resuming this call takes the active place from the group; holding it gives the place
    // back unless another call outside the group still holds it.
    BOOL groupOnHold = !onHold || [self isCallOutsideGroup:_groupMemberUuids activeIgnoring:uuid];
    NSArray<CXAction *> *groupActions = [self holdActionsForGroup:_groupMemberUuids onHold:groupOnHold];
    if (onHold) {
      [actions addObjectsFromArray:groupActions];
    } else {
      [actions insertObjects:groupActions atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, groupActions.count)]];
    }
  }

  [self requestGroupHoldTransaction:[[CXTransaction alloc] initWithActions:actions] completion:completion];
}

- (void)setMuted:(NSString *)uuidString
           muted:(BOOL)muted
      completion:(void (^)(WTPCallRequestError *, FlutterError *))completion {
#ifdef DEBUG
  NSLog(@"[Callkeep][setMuted] uuidString = %@ muted = %d", uuidString, muted);
#endif
  CXSetMutedCallAction *action = [[CXSetMutedCallAction alloc] initWithCallUUID:[self presentedUuidFor:[[NSUUID alloc] initWithUUIDString:uuidString]]
                                                                          muted:muted];
  CXTransaction *transaction = [[CXTransaction alloc] initWithAction:action];
  [_ownMuteActionUuids addObject:action.UUID];

  __weak typeof(self) weakSelf = self;
  [self requestTransaction:transaction completion:^(WTPCallRequestError *error, FlutterError *flutterError) {
    typeof(self) strongSelf = weakSelf;
    if (strongSelf != nil && (error != nil || flutterError != nil)) {
      [strongSelf->_ownMuteActionUuids removeObject:action.UUID];
    }
    completion(error, flutterError);
  }];
}

- (void)sendDTMF:(NSString *)uuidString
             key:(NSString *)key
      completion:(void (^)(WTPCallRequestError *, FlutterError *))completion {
#ifdef DEBUG
  NSLog(@"[Callkeep][sendDTMF] uuidString = %@ key = %@", uuidString, key);
#endif
  CXPlayDTMFCallAction *action = [[CXPlayDTMFCallAction alloc] initWithCallUUID:[self presentedUuidFor:[[NSUUID alloc] initWithUUIDString:uuidString]]
                                                                         digits:key
                                                                           type:CXPlayDTMFCallActionTypeSingleTone];
  CXTransaction *transaction = [[CXTransaction alloc] initWithAction:action];

  [self requestTransaction:transaction completion:completion];
}

/// Parses [uuidStrings] into CallKit UUIDs, dropping any that are malformed.
///
/// A string CallKit cannot parse names no call, so grouping the rest is better than failing
/// the whole request over one bad entry.
- (NSArray<NSUUID *> *)callUUIDsFromStrings:(NSArray<NSString *> *)uuidStrings {
  NSMutableArray<NSUUID *> *uuids = [NSMutableArray arrayWithCapacity:uuidStrings.count];
  for (NSString *uuidString in uuidStrings) {
    NSUUID *uuid = [self presentedUuidFor:[[NSUUID alloc] initWithUUIDString:uuidString]];
    if (uuid != nil) {
      [uuids addObject:uuid];
    } else {
#ifdef DEBUG
      NSLog(@"[Callkeep][callUUIDsFromStrings] skipping malformed uuid %@", uuidString);
#endif
    }
  }
  return uuids;
}

/// Tells CallKit that [uuid] may now be grouped, or taken out of a group.
///
/// Calls are reported with grouping off, and it is raised here for the moment a grouping
/// request is being made rather than for the life of the call. The flags are what put the
/// merge and split controls in the system call UI, and offering either one in a build whose
/// backend cannot conference would show a control that can only fail. Merging is started from
/// the application instead, and there is no split flow to offer yet.
///
/// Holding and DTMF are restated alongside the grouping flags. Apple documents a call update
/// as carrying only new and changed information, and the header gives the `BOOL` properties no
/// default, so this is a precaution rather than a correction: the set here is the one every
/// call is reported with, and restating it can never take a capability away.
- (void)setGroupingAllowed:(BOOL)grouping ungrouping:(BOOL)ungrouping forCallUUID:(NSUUID *)uuid {
  CXCallUpdate *callUpdate = [[CXCallUpdate alloc] init];
  callUpdate.supportsGrouping = grouping;
  callUpdate.supportsUngrouping = ungrouping;
  callUpdate.supportsHolding = YES;
  callUpdate.supportsDTMF = YES;
  [_provider reportCallWithUUID:uuid updated:callUpdate];
}

- (void)setCallGroup:(NSArray<NSString *> *)uuidStrings
           completion:(void (^)(WTPCallRequestError *, FlutterError *))completion {
#ifdef DEBUG
  NSLog(@"[Callkeep][setCallGroup] uuidStrings = %@", uuidStrings);
#endif
  NSArray<NSUUID *> *uuids = [self callUUIDsFromStrings:uuidStrings];
  if (uuids.count == 0) {
    // An empty membership names no group and changes nothing.
    completion(nil, nil);
    return;
  }
  if (uuids.count == 1) {
    // One call is not a group, so naming it as the whole membership means it now stands alone.
    [self requestUngroupingOfCallUUIDs:uuids completion:completion];
    return;
  }

  // Every member is grouped with the first, which is what makes calling this again with a
  // longer membership add to the same group rather than start another one.
  NSUUID *anchor = uuids.firstObject;
  NSMutableArray<CXAction *> *actions = [NSMutableArray arrayWithCapacity:uuids.count - 1];
  for (NSUUID *uuid in uuids) {
    [self setGroupingAllowed:YES ungrouping:NO forCallUUID:uuid];
    if ([uuid isEqual:anchor]) {
      continue;
    }
    [actions addObject:[[CXSetGroupCallAction alloc] initWithCallUUID:uuid callUUIDToGroupWith:anchor]];
  }
  NSSet<NSUUID *> *members = [NSSet setWithArray:uuids];
  BOOL otherCallIsActive = [self isCallOutsideGroup:members activeIgnoring:nil];
  NSArray<CXAction *> *holdActions = [self holdActionsForGroup:members onHold:otherCallIsActive];
  [actions addObjectsFromArray:holdActions];
  [self requestGroupTransaction:[[CXTransaction alloc] initWithActions:actions] forCallUUIDs:uuids completion:^(WTPCallRequestError *error, FlutterError *flutterError) {
    if (error == nil && flutterError == nil) {
      [self->_groupMemberUuids setSet:members];
    } else {
      for (CXAction *action in holdActions) {
        [self->_groupHoldActionUuids removeObject:action.UUID];
      }
    }
    completion(error, flutterError);
  }];
}

- (void)unsetCallGroup:(NSArray<NSString *> *)uuidStrings
             completion:(void (^)(WTPCallRequestError *, FlutterError *))completion {
#ifdef DEBUG
  NSLog(@"[Callkeep][unsetCallGroup] uuidStrings = %@", uuidStrings);
#endif
  NSArray<NSUUID *> *uuids = [self callUUIDsFromStrings:uuidStrings];
  if (uuids.count == 0) {
    // An empty list does nothing, so a caller that computes one cannot take a group apart by
    // accident.
    completion(nil, nil);
    return;
  }
  [self requestUngroupingOfCallUUIDs:uuids completion:completion];
}

/// Takes [uuids] out of whatever group they are in, leaving the calls themselves running.
///
/// A nil second UUID is CallKit's way of saying ungroup.
- (void)requestUngroupingOfCallUUIDs:(NSArray<NSUUID *> *)uuids
                          completion:(void (^)(WTPCallRequestError *, FlutterError *))completion {
  NSMutableArray<CXAction *> *actions = [NSMutableArray arrayWithCapacity:uuids.count];
  for (NSUUID *uuid in uuids) {
    [self setGroupingAllowed:NO ungrouping:YES forCallUUID:uuid];
    [actions addObject:[[CXSetGroupCallAction alloc] initWithCallUUID:uuid callUUIDToGroupWith:nil]];
  }
  // The members leave the group's hold only once CallKit has taken them out of the group: a
  // refused ungrouping leaves the group standing in CallKit, and the next call outside it still
  // has to hold it.
  [self requestGroupTransaction:[[CXTransaction alloc] initWithActions:actions] forCallUUIDs:uuids completion:^(WTPCallRequestError *error, FlutterError *flutterError) {
    if (error == nil && flutterError == nil) {
      for (NSUUID *uuid in uuids) {
        [self->_groupMemberUuids removeObject:uuid];
      }
    }
    completion(error, flutterError);
  }];
}

/// Requests a grouping transaction and closes the capability window behind it.
///
/// Grouping was allowed on [uuids] for this request only. Once CallKit reports the transaction
/// complete - fulfilled, failed or refused by the delegate - both flags go back to NO, so the
/// system call UI is never left offering a merge or split the application did not ask for.
/// The completion is what CallKit gives: it fires after the provider has answered every action
/// in the transaction. Two overlapping requests on the same call would close each other's
/// window early; the application issues one grouping request at a time, and the flags are
/// re-raised by every request, so the cost of that is a refused action, not a stuck one.
- (void)requestGroupTransaction:(CXTransaction *)transaction
                   forCallUUIDs:(NSArray<NSUUID *> *)uuids
                     completion:(void (^)(WTPCallRequestError *, FlutterError *))completion {
  // CallKit hands every action back through the provider delegate, the plugin's own included.
  // Remembering them lets the delegate tell a grouping the application asked for, which it
  // fulfils on its own, from one started in the system call UI, which the application decides.
  // The delegate forgets an action as it fulfils it; the completion below only runs before
  // the delegate is asked - CallKit answers a request once it is committed, not once it is
  // performed - so it clears them only when the request was refused outright.
  for (CXAction *action in transaction.actions) {
    [_requestedGroupActionUuids addObject:action.UUID];
  }
  __weak typeof(self) weakSelf = self;
  [self requestTransaction:transaction completion:^(WTPCallRequestError *error, FlutterError *flutterError) {
    typeof(self) strongSelf = weakSelf;
    if (error != nil || flutterError != nil) {
      for (CXAction *action in transaction.actions) {
        [strongSelf->_requestedGroupActionUuids removeObject:action.UUID];
      }
    }
    for (NSUUID *uuid in uuids) {
      [strongSelf setGroupingAllowed:NO ungrouping:NO forCallUUID:uuid];
    }
    completion(error, flutterError);
  }];
}

#pragma mark - Group hold

// CallKit keeps one active call and one held call. It knows nothing of rooms: the members of a
// group are held and resumed like any call, and a group keeps whatever hold each member had
// before it was grouped. The application does not hold them either - a leg of a room is not
// held on its own, the room is, and the plugin answers such a request with callIsGrouped. Left
// alone, a fresh group is one active and one held call, and the next call that goes active
// makes CallKit end the active member ("Ending current active call ... because call ... is
// going to go active"): the room loses a participant.
//
// So the plugin keeps the members on one hold that follows the calls outside the group: held
// while one of them is active or going active, resumed once none is. The hold changes ride in
// the same transaction as whatever changes the calls outside - grouping, starting, answering,
// holding or resuming a call - and after a call outside ends. They are the plugin's own and are
// fulfilled without asking the application: they change how the operating system presents the
// calls, not what the calls do, and a room standing aside for another call is the
// application's own state already.

/// Whether a call outside [members] is active or going active, leaving [ignored] out. Any call
/// on the device counts, a cellular one included: CallKit makes room for it the same way.
- (BOOL)isCallOutsideGroup:(NSSet<NSUUID *> *)members activeIgnoring:(NSUUID *)ignored {
  for (CXCall *call in _callController.callObserver.calls) {
    if (call.hasEnded || [members containsObject:call.UUID] || [call.UUID isEqual:ignored]) {
      continue;
    }
    if (!call.isOnHold && (call.hasConnected || call.isOutgoing)) {
      return YES;
    }
  }
  return NO;
}

/// The hold changes that put every live member of [members] on [onHold], remembered as the
/// plugin's own so the delegate fulfils them.
- (NSArray<CXAction *> *)holdActionsForGroup:(NSSet<NSUUID *> *)members onHold:(BOOL)onHold {
  NSMutableArray<CXAction *> *actions = [NSMutableArray array];
  for (CXCall *call in _callController.callObserver.calls) {
    if (call.hasEnded || ![members containsObject:call.UUID] || call.isOnHold == onHold) {
      continue;
    }
    CXSetHeldCallAction *action = [[CXSetHeldCallAction alloc] initWithCallUUID:call.UUID onHold:onHold];
    [_groupHoldActionUuids addObject:action.UUID];
    [actions addObject:action];
  }
  return actions;
}

/// Requests [transaction], forgetting its group hold changes if CallKit refuses it outright -
/// the delegate is then never asked, so nothing else would.
- (void)requestGroupHoldTransaction:(CXTransaction *)transaction
                         completion:(void (^)(WTPCallRequestError *, FlutterError *))completion {
  __weak typeof(self) weakSelf = self;
  [self requestTransaction:transaction completion:^(WTPCallRequestError *error, FlutterError *flutterError) {
    typeof(self) strongSelf = weakSelf;
    if (strongSelf != nil && (error != nil || flutterError != nil)) {
      for (CXAction *action in transaction.actions) {
        [strongSelf->_groupHoldActionUuids removeObject:action.UUID];
      }
    }
    completion(error, flutterError);
  }];
}

/// Gives the active place back to the group once no call outside it has it - after a call
/// outside ended on the far side, which no request of the application's announces.
- (void)resumeGroupIfNothingElseIsActive {
  if (_groupMemberUuids.count == 0 || [self isCallOutsideGroup:_groupMemberUuids activeIgnoring:nil]) {
    return;
  }
  NSArray<CXAction *> *actions = [self holdActionsForGroup:_groupMemberUuids onHold:NO];
  if (actions.count == 0) {
    return;
  }
  [self requestGroupHoldTransaction:[[CXTransaction alloc] initWithActions:actions]
                         completion:^(WTPCallRequestError *error, FlutterError *flutterError) {
#ifdef DEBUG
                           if (error != nil || flutterError != nil) {
                             NSLog(@"[Callkeep][resumeGroupIfNothingElseIsActive] refused: %@ %@", error, flutterError);
                           }
#endif
                         }];
}

#pragma mark - Incoming queue

// With queueIncomingWhileRinging at most one incoming call of ours rings in CallKit.
//
// Why: with two of ours ringing there, the system's own Accept on one makes CallKit send an end for
// the other, and the call the user did not touch is declined (seen on the device, 2026-10-09). The
// end comes in a transaction of its own, a millisecond before the answer, and carries no reason:
// it cannot be told from a decline the user made. So the state itself is kept from forming.
//
// A call that comes while another rings waits outside CallKit: the application has it and shows
// it, the system does not. It enters CallKit as an ordinary incoming call as soon as nothing of
// ours rings there any more - the ringing call was answered (then it rings beside it, and iOS may
// ask about it on its call-waiting screen, as for any second call) or ended. Several wait in the
// order they came.
//
// A waiting call the user takes changes places with the one that rings: that one is taken out of
// CallKit by this plugin and waits in turn, at the head of the queue, and the taken call enters
// CallKit alone and is answered - see answerQueuedIncomingCallUUID. Whichever call the user picks,
// the other is kept. (The Android core declines the ringing call there -
// InProcessCallkeepCore.answerQueuedCall.)
//
// The VoIP push of a waiting call must still be reported. It is reported under the UUID of a call
// of ours that lives in CallKit: CallKit refuses it as a duplicate (callUUIDAlreadyExists), the
// obligation is met and nothing enters the registry (Apple DTS:
// https://developer.apple.com/forums/thread/775874). A waiting call's own UUID never reaches
// CallKit before the call is let in. The UUID of a call taken out of CallKit was reported ended
// there, and such a UUID is not relied on again: the call comes back under a new one, which
// CallPresentations keeps track of.

/// An own incoming call ringing in CallKit, or admitted to it and not yet seen connected or
/// ended, other than [excluded]; nil when there is none.
- (NSUUID *)ringingOwnIncomingCallUUIDExcluding:(NSUUID *)excluded {
  for (NSUUID *uuid in [self ringingOwnIncomingCallUUIDs]) {
    if (![uuid isEqual:excluded]) {
      return uuid;
    }
  }
  return nil;
}

/// The CallKit UUIDs of our incoming calls that ring: the ones the call observer lists as ringing,
/// and the admitted ones it does not list yet. What the observer shows of a call - connected,
/// ended - outweighs its admission: a call in conversation is never taken for a ringing one.
- (NSArray<NSUUID *> *)ringingOwnIncomingCallUUIDs {
  NSMutableOrderedSet<NSUUID *> *ringing = [NSMutableOrderedSet orderedSet];
  NSMutableSet<NSUUID *> *listed = [NSMutableSet set];
  for (CXCall *call in _callController.callObserver.calls) {
    [listed addObject:call.UUID];
    if (!call.hasEnded && !call.hasConnected && !call.isOutgoing && [_ownCallUuids containsObject:call.UUID]) {
      [ringing addObject:call.UUID];
    }
  }
  for (NSUUID *uuid in _admittedIncomingUuids) {
    if (![listed containsObject:uuid]) {
      [ringing addObject:uuid];
    }
  }
  return ringing.array;
}

/// Counts [uuid] as ringing from the moment its report is sent - see _admittedIncomingUuids -
/// unless the call observer already shows that very call connected: a second report of a call in
/// conversation (its push after its signaling event) reserves nothing.
- (void)admitIncomingCallUUID:(NSUUID *)uuid {
  for (CXCall *call in _callController.callObserver.calls) {
    if ([call.UUID isEqual:uuid] && !call.hasEnded && call.hasConnected) {
      return;
    }
  }
  [_admittedIncomingUuids addObject:uuid];
}

/// What a push is reported behind: an own call that CallKit lists as live, other than
/// [excluded], or - when the observer has none yet - a call admitted to CallKit whose report is
/// still on its way. Reports reach CallKit in the order they were sent, so the later one finds the
/// UUID taken; if the earlier report fails after all, reportQueuedPush takes the entry back out.
- (NSUUID *)liveOwnCallUUIDExcluding:(NSUUID *)excluded {
  for (CXCall *call in _callController.callObserver.calls) {
    if (!call.hasEnded && ![call.UUID isEqual:excluded] && [_ownCallUuids containsObject:call.UUID]) {
      return call.UUID;
    }
  }
  for (NSUUID *uuid in _admittedIncomingUuids) {
    if (![uuid isEqual:excluded]) {
      return uuid;
    }
  }
  return nil;
}

/// What the completion of an incoming report settles about its place among the admitted calls.
/// A report CallKit took leaves the call admitted: the observer will show it, and only what the
/// observer shows - connected or ended - frees the place (see forgetCall and callChanged). A
/// refused report frees it at once, except a duplicate of a call that still rings or that the
/// observer has not shown yet: CallKit holds that call, under the report sent first.
- (void)settleAdmittedIncomingCallUUID:(NSUUID *)uuid afterReportError:(NSError *)error {
  if (uuid == nil || error == nil) {
    return;
  }
  if ([error.domain isEqualToString:CXErrorDomainIncomingCall] &&
      error.code == CXErrorCodeIncomingCallErrorCallUUIDAlreadyExists) {
    BOOL listed = NO;
    for (CXCall *call in _callController.callObserver.calls) {
      if ([call.UUID isEqual:uuid]) {
        listed = YES;
        if (!call.hasEnded && !call.hasConnected) {
          return;
        }
      }
    }
    if (!listed) {
      return;
    }
  }
  [_admittedIncomingUuids removeObject:uuid];
}

/// Whether CallKit already has [uuid]: the signaling and push paths both report every call, and
/// the second of them must reach CallKit's duplicate check, not the queue.
- (BOOL)isInCallKit:(NSUUID *)uuid {
  uuid = [self presentedUuidFor:uuid];
  if ([_admittedIncomingUuids containsObject:uuid]) {
    return YES;
  }
  for (CXCall *call in _callController.callObserver.calls) {
    if (!call.hasEnded && [call.UUID isEqual:uuid]) {
      return YES;
    }
  }
  return NO;
}

- (BOOL)shouldQueueIncomingCallUUID:(NSUUID *)uuid {
  if (!_queueIncomingWhileRinging || uuid == nil || [self isInCallKit:uuid]) {
    return NO;
  }
  return [_queuedIncomingUuids containsObject:uuid] || [self ringingOwnIncomingCallUUIDExcluding:uuid] != nil;
}

- (void)queueIncomingCallUUID:(NSUUID *)uuid update:(CXCallUpdate *)update {
  if (![_queuedIncomingUuids containsObject:uuid]) {
    WTPLog(@"[Callkeep][queue] %@ waits behind a ringing call (%lu waiting)", uuid.UUIDString,
          (unsigned long)_queuedIncomingUuids.count + 1);
    [_queuedIncomingUuids addObject:uuid];
  }
  _queuedIncomingUpdates[uuid] = update;
}

/// Takes [uuid] out of the queue; NO when it was not waiting.
- (BOOL)dequeueIncomingCallUUID:(NSUUID *)uuid {
  if (uuid == nil || ![_queuedIncomingUuids containsObject:uuid]) {
    return NO;
  }
  [_queuedIncomingUuids removeObject:uuid];
  [_queuedIncomingUpdates removeObjectForKey:uuid];
  return YES;
}

- (void)forgetIncomingQueue {
  [_queuedIncomingUuids removeAllObjects];
  [_queuedIncomingUpdates removeAllObjects];
  [_admittedIncomingUuids removeAllObjects];
  [_presentations reset];
  [_incomingUpdates removeAllObjects];
}

/// The push of a waiting call, reported behind [shield] (see "Incoming queue").
- (void)reportQueuedPush:(NSUUID *)uuid
                  callId:(NSString *)callId
                  update:(CXCallUpdate *)callUpdate
                  shield:(NSUUID *)shield
              completion:(void (^)(void))completion {
  [_provider reportNewIncomingCallWithUUID:shield
                                    update:callUpdate
                                completion:^(NSError *error) {
                                  dispatch_async(dispatch_get_main_queue(), ^{
                                    if (error == nil) {
                                      // The shield ended in between and CallKit took the report for
                                      // a new call under the shield's UUID: it is taken straight
                                      // back out, and the queue lets the waiting call in instead.
                                      WTPLog(@"[Callkeep][queue] the call %@ was reported behind had ended - taking the entry back",
                                            shield.UUIDString);
                                      [self->_provider reportCallWithUUID:shield
                                                              endedAtDate:nil
                                                                   reason:CXCallEndedReasonAnsweredElsewhere];
                                    } else if (!([error.domain isEqualToString:CXErrorDomainIncomingCall] &&
                                                 error.code == CXErrorCodeIncomingCallErrorCallUUIDAlreadyExists)) {
                                      WTPLog(@"[Callkeep][queue] the push of %@ was reported with an unexpected error %@",
                                            uuid.UUIDString, error);
                                    }
                                    [self releaseQueuedIncomingIfNothingRings];
                                  });
                                  // For the application the call is presented: it has it and shows it.
                                  [self->_delegateFlutterApi didPresentIncomingCallHandle:[callUpdate.remoteHandle toPigeon]
                                                                           displayName:callUpdate.localizedCallerName
                                                                                 video:callUpdate.hasVideo
                                                                                callId:callId
                                                                                  uuid:[uuid UUIDString]
                                                                                 error:nil
                                                                            completion:^(FlutterError *flutterError) {
                                                                              completion();
                                                                            }];
                                }];
}

/// Lets the oldest waiting call into CallKit once nothing of ours rings there.
- (void)releaseQueuedIncomingIfNothingRings {
  if (_queuedIncomingUuids.count == 0 || [self ringingOwnIncomingCallUUIDExcluding:nil] != nil) {
    return;
  }
  NSUUID *uuid = _queuedIncomingUuids.firstObject;
  CXCallUpdate *update = _queuedIncomingUpdates[uuid];
  [self dequeueIncomingCallUUID:uuid];
  WTPLog(@"[Callkeep][queue] nothing rings - letting %@ in", uuid.UUIDString);
  [self reportQueuedIncomingCallUUID:uuid update:update keepWhenRefused:NO completion:nil];
}

/// Reports a call that waited to CallKit as an ordinary incoming call.
///
/// When CallKit refuses it and [keep] is NO, the application is told the call ended, as for any
/// call the system ends - it believed it presented. With [keep] the call is left alive and out of
/// CallKit, for the caller of this method to say what becomes of it: the user asked for this call,
/// and a refusal of the system is no reason to cut its caller off.
- (void)reportQueuedIncomingCallUUID:(NSUUID *)logicalUuid
                              update:(CXCallUpdate *)update
                     keepWhenRefused:(BOOL)keep
                          completion:(void (^)(NSError *, CallPresentation *))done {
  if (update == nil) {
    update = [[CXCallUpdate alloc] init];
  }
  if (![self hasConnectedOwnCall]) {
    [self configureAudioSession];
  }
  // A call that was taken out of CallKit comes back under a new UUID - its own was reported ended
  // there - and the application goes on naming it by its own.
  CallPresentation *presentation = [_presentations presentationToReportForLogicalUUID:logicalUuid];
  NSUUID *uuid = presentation.callKitUUID;
  WTPLog(@"[Callkeep][queue] %@ enters CallKit as %@ (presentation %lu)", logicalUuid.UUIDString, uuid.UUIDString,
        (unsigned long)presentation.generation);
  _incomingUpdates[logicalUuid] = update;
  [_ownCallUuids addObject:uuid];
  [self admitIncomingCallUUID:uuid];
  [self holdActiveBeforeReportingIncomingCallUUID:uuid then:^{
    [self->_provider reportNewIncomingCallWithUUID:uuid
                                            update:update
                                        completion:^(NSError *error) {
                                          dispatch_async(dispatch_get_main_queue(), ^{
                                            [self settleAdmittedIncomingCallUUID:uuid afterReportError:error];
                                            [self resumeCallHeldForReportedIncomingCallUUID:uuid];
                                            // What follows is this presentation's business only while it is
                                            // the one the call lives under: the call may have been taken out
                                            // again, ended or reset while the report was on its way, and a
                                            // late answer to it must not touch what came after.
                                            BOOL live = [self->_presentations isLive:presentation];
                                            if (!live) {
                                              WTPLog(@"[Callkeep][queue] a late answer to the report of %@ - not its call's presentation any more",
                                                    uuid.UUIDString);
                                            } else if (error == nil) {
                                              if ([self isLiveOwnCallUUID:uuid]) {
                                                [self setVideo:update.hasVideo forCallUUID:uuid];
                                              }
                                            } else if (keep) {
                                              WTPLog(@"[Callkeep][queue] CallKit refused the waiting call %@: %@ - it goes on waiting",
                                                    logicalUuid.UUIDString, error);
                                              // The UUID was refused; the call is shown under another one
                                              // the next time it is let in.
                                              [self->_presentations withdrawLivePresentationOfLogicalUUID:logicalUuid];
                                              [self forgetCall:uuid];
                                            } else {
                                              WTPLog(@"[Callkeep][queue] CallKit refused the waiting call %@: %@ - ending it",
                                                    logicalUuid.UUIDString, error);
                                              [self forgetCall:uuid];
                                              [self->_delegateFlutterApi performEndCall:logicalUuid.UUIDString
                                                                                endedBy:WTPEndedByEnumSystem
                                                                             completion:^(NSNumber *fulfill, FlutterError *e) {}];
                                            }
                                            if (done != nil) {
                                              done(error, live ? presentation : nil);
                                            }
                                            [self releaseQueuedIncomingIfNothingRings];
                                          });
                                        }];
  }];
}

/// The user takes a waiting call while another of ours rings in CallKit.
///
/// Two ringing there is the state in which the system's own Accept on one makes CallKit end the
/// other (see "Incoming queue"), and the taken call cannot be answered without entering CallKit.
/// So the ringing one is first taken out of CallKit - by this plugin, knowingly, and with nothing
/// said to the application: the call itself lives - and put at the head of the queue. The taken call
/// then enters CallKit alone and is answered. The one taken out comes back as an ordinary incoming
/// call once nothing of ours rings: beside the answered call, as any call that waited, under a new
/// UUID. iOS may show its call-waiting screen for it only for a moment or not at all (a call
/// reported right after an answer made in the app); the application's own list offers it either way.
///
/// A ringing call whose answer is on its way stays: nothing would answer it when it came back, and
/// it would ring alone under its new UUID while the application counts it as answered. That is how
/// two calls restored after a cold restart meet here, both answered by the application at once.
/// Only the system's own Accept makes CallKit end the other ringing call, so the two can pass.
- (void)answerQueuedIncomingCallUUID:(NSUUID *)uuid
                          completion:(void (^)(WTPCallRequestError *, FlutterError *))completion {
  CXCallUpdate *update = _queuedIncomingUpdates[uuid];
  [self dequeueIncomingCallUUID:uuid];
  NSUInteger place = 0;
  for (NSUUID *ringing in [self ringingOwnIncomingCallUUIDs]) {
    if ([_endingCallUuids containsObject:ringing]) {
      // The user declined this one and the application is ending it: it stays where it is until
      // that is done, and has no turn to come back for. Should the application refuse the end,
      // the call goes on ringing in CallKit beside the answered one, as a call that came second.
      continue;
    }
    if ([_answeringCallUuids containsObject:ringing]) {
      WTPLog(@"[Callkeep][queue] keeping the ringing %@ in CallKit: its answer is on its way", ringing.UUIDString);
      continue;
    }
    NSUUID *logical = [_presentations logicalUUIDForCallKitUUID:ringing];
    if (logical == nil || [_presentations withdrawLivePresentationOfLogicalUUID:logical] == nil) {
      // Not a presentation a call lives under: nothing of ours to keep for later.
      continue;
    }
    WTPLog(@"[Callkeep][queue] taking the ringing %@ out of CallKit: %@ is answered first", logical.UUIDString,
          uuid.UUIDString);
    [_queuedIncomingUuids insertObject:logical atIndex:place++];
    _queuedIncomingUpdates[logical] = _incomingUpdates[logical] ?: [[CXCallUpdate alloc] init];
    [_provider reportCallWithUUID:ringing endedAtDate:nil reason:CXCallEndedReasonAnsweredElsewhere];
    [self forgetCall:ringing];
  }
  NSUInteger takenOut = place;
  [self reportQueuedIncomingCallUUID:uuid
                              update:update
                     keepWhenRefused:YES
                          completion:^(NSError *error, CallPresentation *presentation) {
                            if (presentation == nil) {
                              // The call moved on while its report was on its way: there is
                              // nothing of this attempt left to answer.
                              completion([WTPCallRequestError makeWithValue:WTPCallRequestErrorEnumUnknownCallUuid], nil);
                            } else if (error != nil) {
                              // CallKit did not take the call, so it cannot be answered now. It
                              // waits again - behind the calls taken out for it, which rang
                              // before it and come back first - and the application hears that
                              // the answer was not made, so that the user can ask once more.
                              NSUInteger at = MIN(takenOut, self->_queuedIncomingUuids.count);
                              [self->_queuedIncomingUuids insertObject:uuid atIndex:at];
                              self->_queuedIncomingUpdates[uuid] =
                                  update ?: self->_incomingUpdates[uuid] ?: [[CXCallUpdate alloc] init];
                              completion([WTPCallRequestError makeWithValue:WTPCallRequestErrorEnumInternal], nil);
                            } else {
                              [self requestAnswerOfCallUUID:presentation.callKitUUID completion:completion];
                            }
                          }];
}

- (BOOL)hasConnectedOwnCall {
  for (CXCall *call in _callController.callObserver.calls) {
    if (!call.hasEnded && call.hasConnected && [_ownCallUuids containsObject:call.UUID]) {
      return YES;
    }
  }
  return NO;
}

#pragma mark - WTPHostApi - helpers

#pragma mark - Hold before a third call

/// The hold before a third call (holdActiveBeforeThirdIncoming), run before an incoming call of
/// ours is reported to CallKit.
///
/// With one call of ours held and another active, iOS builds the system screen of a third call
/// without `Hold & Accept`: it offers `End & Accept` and `End Held & Accept`, and both end a call -
/// a tap on `End Held & Accept` silently ends the oldest one (WT-2093). With nothing of ours
/// active it offers `Hold & Accept`. So when a held call and an active one are both there, the
/// active one is put on hold first, and the report waits for that transaction.
///
/// The hold is CallKit's only and lasts until CallKit has the report: the active call is taken
/// off hold again as soon as the call observer lists the incoming call, or in the report's
/// completion if that comes first, and neither change reaches the application or the far side.
/// The completion alone is too late: measured on an iPhone (iOS 27), it was still pending while
/// the system screen was up and the user had tapped `End & Accept` on it. iOS keeps the screen it built for the report (measured on an iPhone, iOS 27), so
/// the user meets `Hold & Accept`, `End & Accept` and `Decline` with the call still active, and
/// each does what it says: `Hold & Accept` holds the active call and answers, `End & Accept`
/// ends the active call only. Left held, both of ours would be held at the tap, and iOS reads
/// `End & Accept` as ending them all (a transaction of two ends and the answer).
///
/// Taking the call off hold needs this plugin's main queue, and iOS can keep that queue busy
/// while its screen covers the app: measured on an iPhone (iOS 27), the action mostly reached the
/// delegate 70-350 ms after the hold, once 1.2 s, and a tap on `End & Accept` in that time ends
/// both calls. Refusing the extra end does not help: CallKit drops the call anyway while the app
/// keeps it.
///
/// A call CallKit already lists is not held for: its screen is up, and a second report of it - the
/// one a VoIP push makes for a call signalling has already reported, refused as a duplicate - would
/// take the active call off hold again in its completion. Measured on an iPhone (iOS 27), with the
/// application in the background: the push came after the user had tapped `Hold & Accept`, the
/// active call went off hold while the third one was being answered, and CallKit ended the third.
///
/// [report] is always called, on the main queue; a hold CallKit refused still lets the call in.
- (void)holdActiveBeforeReportingIncomingCallUUID:(NSUUID *)incoming then:(void (^)(void))report {
  NSUUID *active = _holdActiveBeforeThirdIncoming && incoming != nil && ![self callKitListsCallUUID:incoming]
                       ? [self activeOwnCallToHoldBeforeIncomingCallUUID:incoming]
                       : nil;
  if (active == nil) {
    report();
    return;
  }
  WTPLog(@"[Callkeep][hold-before-third] holding %@ before %@ is reported", active.UUIDString, incoming.UUIDString);
  CXSetHeldCallAction *hold = [[CXSetHeldCallAction alloc] initWithCallUUID:active onHold:YES];
  [_screenHoldActionUuids addObject:hold.UUID];
  __weak typeof(self) weakSelf = self;
  [self requestTransaction:[[CXTransaction alloc] initWithAction:hold] completion:^(WTPCallRequestError *error, FlutterError *flutterError) {
    dispatch_async(dispatch_get_main_queue(), ^{
      typeof(self) strongSelf = weakSelf;
      if (strongSelf == nil) {
        return;
      }
      BOOL held = error == nil && flutterError == nil;
      if (held) {
        strongSelf->_heldForIncoming[incoming] = active;
      } else {
        [strongSelf->_screenHoldActionUuids removeObject:hold.UUID];
        WTPLog(@"[Callkeep][hold-before-third] CallKit refused to hold %@: %@ %@ - %@ is reported anyway",
              active.UUIDString, error, flutterError, incoming.UUIDString);
      }
      report();
    });
  }];
}

- (BOOL)callKitListsCallUUID:(NSUUID *)uuid {
  for (CXCall *call in _callController.callObserver.calls) {
    if ([call.UUID isEqual:uuid] && !call.hasEnded) {
      return YES;
    }
  }
  return NO;
}

/// The active call of ours to hold before [incoming] is reported, or nil: only when another call
/// of ours is already on hold - the third-call screen. Beside a single active call iOS offers
/// `Hold & Accept` by itself, and nothing is held early.
- (NSUUID *)activeOwnCallToHoldBeforeIncomingCallUUID:(NSUUID *)incoming {
  NSUUID *active = nil;
  BOOL someHeld = NO;
  for (CXCall *call in _callController.callObserver.calls) {
    if (call.hasEnded || !call.hasConnected || [call.UUID isEqual:incoming] || ![_ownCallUuids containsObject:call.UUID]) {
      continue;
    }
    if (call.isOnHold) {
      someHeld = YES;
    } else if (active == nil) {
      active = call.UUID;
    }
  }
  return someHeld ? active : nil;
}

/// CallKit has the report of [incoming] - the call observer lists it, or the report's completion
/// came, whichever is first: the call held for it goes off hold again, if it is still ours and
/// live. Called on the main queue, whether the report was taken or not.
///
/// The call observer is not asked whether the call is on hold: it lags behind the transaction -
/// measured on an iPhone (iOS 27), it still showed the call active 300 ms after its hold was
/// fulfilled. Taking off hold a call that is not held changes nothing, and neither change reaches
/// the application.
- (void)resumeCallHeldForReportedIncomingCallUUID:(NSUUID *)incoming {
  NSUUID *held = incoming != nil ? _heldForIncoming[incoming] : nil;
  if (held == nil) {
    return;
  }
  [_heldForIncoming removeObjectForKey:incoming];
  BOOL live = NO;
  for (CXCall *call in _callController.callObserver.calls) {
    if ([call.UUID isEqual:held] && !call.hasEnded && [_ownCallUuids containsObject:call.UUID]) {
      live = YES;
    }
  }
  if (!live) {
    return;
  }
  WTPLog(@"[Callkeep][hold-before-third] %@ is reported, taking %@ off hold", incoming.UUIDString, held.UUIDString);
  CXSetHeldCallAction *resume = [[CXSetHeldCallAction alloc] initWithCallUUID:held onHold:NO];
  [_screenHoldActionUuids addObject:resume.UUID];
  __weak typeof(self) weakSelf = self;
  [self requestTransaction:[[CXTransaction alloc] initWithAction:resume] completion:^(WTPCallRequestError *error, FlutterError *flutterError) {
    if (error != nil || flutterError != nil) {
      WTPLog(@"[Callkeep][hold-before-third] CallKit refused to take %@ off hold: %@ %@", held.UUIDString, error, flutterError);
      dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf forgetScreenHoldActionUUID:resume.UUID];
      });
    }
  }];
}

- (void)forgetScreenHoldActionUUID:(NSUUID *)uuid {
  [_screenHoldActionUuids removeObject:uuid];
}

- (void)requestTransaction:(CXTransaction *)transaction completion:(void (^)(WTPCallRequestError *, FlutterError *))completion {
  [_callController requestTransaction:transaction completion:^(NSError *error) {
    if (error == nil) {
      completion(nil, nil);
    } else if ([error.domain isEqualToString:CXErrorDomainRequestTransaction]) {
      completion([WTPCallRequestError makeWithValue:CXErrorCodeRequestTransactionErrorToPigeon((CXErrorCodeRequestTransactionError) error.code)], nil);
    } else {
      completion(nil, [FlutterError errorWithCode:error.domain
                                          message:[error description]
                                          details:nil]);
    }
  }];
}

#pragma mark - WTPHostSoundApi

- (AVAudioPlayer *) createRingbackPlayer:(NSString *)soundAsset {
    NSString* key = [_registrar lookupKeyForAsset:soundAsset];
    NSString* path = [[NSBundle mainBundle] pathForResource:key ofType:nil];
    NSURL *soundFileURL = [NSURL fileURLWithPath:path];
    AVAudioPlayer* p = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL error:nil];
    p.numberOfLoops = -1;
    return p;
}

- (void)playRingbackSound:(void (^)(FlutterError * _Nullable))completion{
    if(_ringback != nil)[_ringback play];
    completion(nil);
}

- (void)stopRingbackSound:(void (^)(FlutterError * _Nullable))completion{
    if(_ringback != nil)[_ringback pause];

    completion(nil);
}

#pragma mark - FlutterApplicationLifeCycleDelegate

- (BOOL) application:(nonnull UIApplication *)application
continueUserActivity:(nonnull NSUserActivity *)userActivity
  restorationHandler:(nonnull void (^)(NSArray *_Nonnull))restorationHandler {
#ifdef DEBUG
  NSLog(@"[Callkeep][FlutterApplicationLifeCycleDelegate][application:continueUserActivity:restorationHandler:]");
#endif
  INInteraction *interaction = userActivity.interaction;
  if (interaction == nil) {
    return NO;
  }
  INIntent *intent = interaction.intent;

  INPerson *person;
  BOOL isVideoCall = NO;

  if ([intent isKindOfClass:[INStartAudioCallIntent class]]) {
    INStartAudioCallIntent *startAudioCallIntent = (INStartAudioCallIntent *) intent;
    person = [startAudioCallIntent.contacts firstObject];
  } else if ([intent isKindOfClass:[INStartVideoCallIntent class]]) {
    INStartVideoCallIntent *startVideoCallIntent = (INStartVideoCallIntent *) intent;
    person = [startVideoCallIntent.contacts firstObject];
    isVideoCall = YES;
  } else if (@available(iOS 13, *)) {
    if ([intent isKindOfClass:[INStartCallIntent class]]) {
      INStartCallIntent *startCallIntent = (INStartCallIntent *) intent;
      person = [startCallIntent.contacts firstObject];
      isVideoCall = startCallIntent.callCapability == INCallCapabilityVideoCall;
    }
  }

  if (person != nil && person.personHandle != nil) {
    [_delegateFlutterApi continueStartCallIntentHandle:[person.personHandle toPigeon]
                                           displayName:[person displayName]
                                                 video:isVideoCall
                                            completion:^(FlutterError *error) {}];

    return YES;
  } else {
    return NO;
  }
}

#pragma mark - PKPushRegistryDelegate

- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)pushCredentials forType:(PKPushType)type {
#ifdef DEBUG
  NSLog(@"[Callkeep][PKPushRegistryDelegate][pushRegistry:didUpdatePushCredentials:forType:] pushCredentials = %@ type = %@", pushCredentials, type);
#endif
  if (type == PKPushTypeVoIP) {
    [_pushRegistryDelegateFlutterApi didUpdatePushTokenForPushTypeVoIP:[pushCredentials.token toHexString]
                                                            completion:^(FlutterError *error) {}];
  }
}

- (void)pushRegistry:(PKPushRegistry *)registry didInvalidatePushTokenForType:(PKPushType)type {
#ifdef DEBUG
  NSLog(@"[Callkeep][PKPushRegistryDelegate][pushRegistry:didInvalidatePushTokenForType:] type = %@", type);
#endif
  if (type == PKPushTypeVoIP) {
    [_pushRegistryDelegateFlutterApi didUpdatePushTokenForPushTypeVoIP:nil completion:^(FlutterError *error) {}];
  }
}

- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(PKPushType)type withCompletionHandler:(void (^)(void))completion {
#ifdef DEBUG
  NSLog(@"[Callkeep][PKPushRegistryDelegate][pushRegistry:didReceiveIncomingPushWithPayload:forType:withCompletionHandler:] type = %@", type);
#endif
  [self didReceiveIncomingPushWithPayloadForPushTypeVoIP:payload withCompletionHandler:completion];
}

- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(PKPushType)type {
#ifdef DEBUG
  NSLog(@"[Callkeep][PKPushRegistryDelegate][pushRegistry:didReceiveIncomingPushWithPayload:forType:] type = %@", type);
#endif
  [self didReceiveIncomingPushWithPayloadForPushTypeVoIP:payload withCompletionHandler:^() {}];
}

/// Called when a VoIP push notification is received by the system.
///
/// This method is responsible for parsing the VoIP payload and reporting a new
/// incoming call to CallKit. It prepares the `CXCallUpdate` and uses the UUID
/// derived from the call ID to avoid race conditions.
///
///  Important:
/// - Before calling `reportNewIncomingCallWithUUID:update:completion:`,
///   this method calls `configureAudioSession()` to preconfigure the audio session.
///   This is a workaround for a known issue (Radar #28774388) where `didActivateAudioSession`
///   might not be triggered correctly on cold start if audio session is not set up early enough.
///
/// @param payload The VoIP push payload containing call information.
/// @param completion A completion handler to signal that processing is complete.
- (void)didReceiveIncomingPushWithPayloadForPushTypeVoIP:(PKPushPayload *)payload withCompletionHandler:(void (^)(void))completion {
  NSDictionary *dictionaryPayload = payload.dictionaryPayload;
#ifdef DEBUG
  NSLog(@"[Callkeep][didReceiveIncomingPushWithPayloadForPushTypeVoIP:withCompletionHandler:] payload = %@", dictionaryPayload);
#endif
  id handleTypeObject = dictionaryPayload[@"handleType"];
  id handleValueObject = dictionaryPayload[@"handleValue"];
  id displayNameObject = dictionaryPayload[@"displayName"];
  id hasVideoObject = dictionaryPayload[@"hasVideo"];
  id callIdObject = dictionaryPayload[@"callId"];

  if ([handleTypeObject isKindOfClass:[NSString class]] == NO ||
    [handleValueObject isKindOfClass:[NSString class]] == NO ||
    [callIdObject isKindOfClass:[NSString class]] == NO) {
#ifdef DEBUG
    NSLog(@"[Callkeep][didReceiveIncomingPushWithPayloadForPushTypeVoIP:withCompletionHandler:] payload wrong format");
#endif
    NSUUID *uuid = [[NSUUID alloc] init];
    CXCallUpdate *callUpdate = [[CXCallUpdate alloc] init];

    [_ownCallUuids addObject:uuid];
    [_provider reportNewIncomingCallWithUUID:uuid
                                      update:callUpdate
                                  completion:^(NSError *error) {
                                    if (error != nil) {
                                      WTPLog(@"[Callkeep][didReceiveIncomingPushWithPayloadForPushTypeVoIP:withCompletionHandler:][reportNewIncomingCallWithUUID] payload wrong format error = %@",
                                            error);
                                    } else {
                                      [_provider reportCallWithUUID:uuid
                                                        endedAtDate:nil
                                                             reason:CXCallEndedReasonFailed];
                                    }
                                    completion();
                                  }];
    return;
  }

  NSString *handleType = handleTypeObject;
  NSString *handleValue = handleValueObject;
  NSString *displayName = [displayNameObject isKindOfClass:[NSString class]] ? displayNameObject : nil;

  // Check if hasVideoObject is a string and convert it to NSNumber
  NSNumber *hasVideo;
  if ([hasVideoObject isKindOfClass:[NSNumber class]]) {
      hasVideo = hasVideoObject;
  } else if ([hasVideoObject isKindOfClass:[NSString class]]) {
      NSString *hasVideoString = (NSString *)hasVideoObject;
      BOOL hasVideoBool = [hasVideoString boolValue];
      hasVideo = @(hasVideoBool);
  } else {
      hasVideo = @(NO);
  }
  // Log the value of hasVideo after initialization
  WTPLog(@"hasVideo after initialization: %@", hasVideo);

  NSString *callId = callIdObject;

  // It is crucial to use UUID version 5 (namespace name-based) based on callId to get the call UUID for reportNewIncomingCallWithUUID.
  // Such UUID allows overcoming possible races between VoIP push and relevant signaling events.
  NSUUID *uuid = [NSUUID makeWithName:callId namespace:[[NSUUID alloc] initWithUUIDString:NAMESPACE_OID]];

  CXCallUpdate *callUpdate = [[CXCallUpdate alloc] init];
  callUpdate.remoteHandle = [[CXHandle alloc] initWithType:CXHandleTypeFromString(handleType)
                                                     value:handleValue];
  callUpdate.localizedCallerName = displayName;
  callUpdate.hasVideo = [hasVideo boolValue];
  callUpdate.supportsGrouping = NO;
  callUpdate.supportsUngrouping = NO;
  callUpdate.supportsHolding = YES;
  callUpdate.supportsDTMF = YES;

  if ([self shouldQueueIncomingCallUUID:uuid]) {
    NSUUID *shield = [self liveOwnCallUUIDExcluding:uuid];
    if (shield != nil) {
      [self queueIncomingCallUUID:uuid update:callUpdate];
      [self reportQueuedPush:uuid callId:callId update:callUpdate shield:shield completion:completion];
      return;
    }
    // A call still in the queue while nothing of ours is in CallKit or on its way there: the
    // queue is about to let it in anyway, and this push does it.
    [self dequeueIncomingCallUUID:uuid];
  }

  [self configureAudioSession];
  // The call's live presentation, so that CallKit sees a duplicate of it, or a new one.
  NSUUID *pushPresentedUuid = [_presentations presentationToReportForLogicalUUID:uuid].callKitUUID;
  _incomingUpdates[uuid] = callUpdate;
  [_ownCallUuids addObject:pushPresentedUuid];
  [self admitIncomingCallUUID:pushPresentedUuid];
  // The push path is the one the third call took in the reproduction of WT-2093: the push reaches
  // CallKit before the application knows of the call, so the hold is made here, not in the app.
  [self holdActiveBeforeReportingIncomingCallUUID:pushPresentedUuid then:^{
    [self->_provider reportNewIncomingCallWithUUID:pushPresentedUuid
                                            update:callUpdate
                                        completion:^(NSError *error) {
                                          dispatch_async(dispatch_get_main_queue(), ^{
                                            [self settleAdmittedIncomingCallUUID:pushPresentedUuid afterReportError:error];
                                            [self resumeCallHeldForReportedIncomingCallUUID:pushPresentedUuid];
                                            [self releaseQueuedIncomingIfNothingRings];
                                          });
                                          WTPIncomingCallError *incomingCallError = nil;
                                          if (error != nil) {
                                            if ([error.domain isEqualToString:CXErrorDomainIncomingCall]) {
                                              incomingCallError = [WTPIncomingCallError makeWithValue:CXErrorCodeIncomingCallErrorToPigeon((CXErrorCodeIncomingCallError) error.code)];
                                            } else {
                                              WTPLog(@"[Callkeep][didReceiveIncomingPushWithPayloadForPushTypeVoIP:withCompletionHandler:][reportNewIncomingCallWithUUID] error = %@", error);
                                              incomingCallError = [WTPIncomingCallError makeWithValue:WTPIncomingCallErrorEnumInternal];
                                            }
                                          } else if ([self isLiveOwnCallUUID:pushPresentedUuid]) {
                                            // CallKit took the call: its video state counts from here, and only
                                            // here. A call CallKit refused never keeps the screen awake, and one
                                            // that ended or was reset before this completion ran is not brought
                                            // back into the set by it.
                                            [self setVideo:callUpdate.hasVideo forCallUUID:pushPresentedUuid];
                                          }

                                          [self->_delegateFlutterApi didPresentIncomingCallHandle:[callUpdate.remoteHandle toPigeon]
                                                                                   displayName:callUpdate.localizedCallerName
                                                                                         video:callUpdate.hasVideo
                                                                                        callId:callId
                                                                                          uuid:[uuid UUIDString]
                                                                                         error:incomingCallError
                                                                                    completion:^(FlutterError *error) {
                                                                                      completion();
                                                                                    }];
                                        }];
  }];
}

/// Prepares the AVAudioSession for an incoming call.
///
/// This method sets the audio session category and mode to support VoIP audio routing.
/// It is called before `reportNewIncomingCallWithUUID` to ensure the audio session
/// is properly configured before CallKit attempts to activate it.
///
/// Do not call `setActive:YES` here — CallKit is responsible for activating the audio session.
///
/// Best practice:
/// - Call this method *before* reporting the call to CallKit (e.g., in `didReceiveIncomingPush…`)
///   to prevent timing issues where `didActivateAudioSession` fails to trigger.
- (void)configureAudioSession {
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error = nil;

    BOOL success = [session setCategory:AVAudioSessionCategoryPlayAndRecord
                            withOptions:AVAudioSessionCategoryOptionAllowBluetooth
                                  error:&error];
    if (!success) {
        WTPLog(@"[Callkeep] Failed to set category: %@", error);
    }

    success = [session setMode:AVAudioSessionModeVoiceChat error:&error];
    if (!success) {
        WTPLog(@"[Callkeep] Failed to set mode: %@", error);
    }
}

#pragma mark - CXProviderDelegate

#pragma mark - CXCallObserverDelegate

- (void)callObserver:(CXCallObserver *)callObserver callChanged:(CXCall *)call {
  // `calls` lists the calls that are still active; a call that has just ended may already be
  // gone from it and reaches us only as the argument. Forget its video state here, so it cannot
  // keep the screen awake after CallKit is done with it.
  if (call.hasEnded) {
    [self forgetCall:call.UUID];
    [self resumeGroupIfNothingElseIsActive];
  }
  if (call.hasConnected) {
    // Answered: it rings no more, and its place among the admitted incoming calls is free.
    [_admittedIncomingUuids removeObject:call.UUID];
  }
  if (_heldForIncoming[call.UUID] != nil) {
    // CallKit lists the incoming call, and has built its system screen: the hold before a third
    // call has done its work.
    [self resumeCallHeldForReportedIncomingCallUUID:call.UUID];
  }
  [self syncCallWaitingTone:callObserver];
  [self releaseQueuedIncomingIfNothingRings];
}

/// Mirrors the Android connection-service behavior: a soft call-waiting beep plays
/// while one call is connected (or held) and another incoming call is ringing, and
/// stops as soon as that state ends (answered, declined, hung up on either side).
/// With callWaitingToneOwnCallsOnly (default) only this app's own calls are counted -
/// CXCallObserver reports every CallKit call on the device, including cellular and
/// other VoIP apps. Known scope boundary: an outgoing call that is still dialing has
/// hasConnected == NO, so a second incoming call during it produces no tone (same as
/// the Android connection-service logic, which plays the full ringtone there).
- (void)syncCallWaitingTone:(CXCallObserver *)callObserver {
  BOOL hasConnected = NO;
  BOOL hasRingingIncoming = NO;
  for (CXCall *call in callObserver.calls) {
    if (call.hasEnded || call.hasConnected) {
      [_answeringCallUuids removeObject:call.UUID];
    }
    if (call.hasEnded) {
      [self forgetCall:call.UUID];
      continue;
    }
    if (_callWaitingToneOwnCallsOnly && ![_ownCallUuids containsObject:call.UUID]) {
      continue;  // a foreign CallKit call (cellular / another VoIP app)
    }
    if (call.hasConnected) {
      hasConnected = YES;
    } else if (!call.outgoing && ![_answeringCallUuids containsObject:call.UUID]) {
      hasRingingIncoming = YES;
    }
  }
#ifdef DEBUG
  NSLog(@"[CallWaitingTone] sync: calls=%lu connected=%d ringingIncoming=%d",
        (unsigned long)callObserver.calls.count, hasConnected, hasRingingIncoming);
#endif
  if (hasConnected && hasRingingIncoming) {
    [_callWaitingTone play];
  } else {
    [_callWaitingTone stop];
  }
}

- (void)providerDidReset:(CXProvider *)provider {
#ifdef DEBUG
  NSLog(@"[Callkeep][CXProviderDelegate][providerDidReset:]");
#endif
  [_callWaitingTone stop];
  [_ownCallUuids removeAllObjects];
  [_videoCallUuids removeAllObjects];
  [self refreshIdleTimer];
  [_answeringCallUuids removeAllObjects];
  [_ownEndActionInitiators removeAllObjects];
  [_endingCallUuids removeAllObjects];
  [self forgetIncomingQueue];
  [_delegateFlutterApi didReset:^(FlutterError *error) {}];
}

- (void)provider:(CXProvider *)provider performStartCallAction:(CXStartCallAction *)action {
#ifdef DEBUG
  NSLog(@"[Callkeep][CXProviderDelegate][provider:performStartCallAction:]");
#endif
  [_ownCallUuids addObject:action.callUUID];
  [_delegateFlutterApi performStartCall:action.callUUID.UUIDString
                                 handle:[action.handle toPigeon]
         displayNameOrContactIdentifier:action.contactIdentifier
                                  video:action.video
                             completion:^(NSNumber *fulfill, FlutterError *error) {
                               if (error != nil || [fulfill boolValue] != YES) {
                                 [action fail];
                               } else {
                                 [action fulfill];
                                 // Same guard as the incoming paths: Dart's answer can come after
                                 // the call ended, was reset or torn down.
                                 if ([self isLiveOwnCallUUID:action.callUUID]) {
                                   [self setVideo:action.video forCallUUID:action.callUUID];
                                 }
                               }
                             }];
}

- (void)provider:(CXProvider *)provider performAnswerCallAction:(CXAnswerCallAction *)action {
#ifdef DEBUG
  NSLog(@"[Callkeep][CXProviderDelegate][provider:performAnswerCallAction:]");
#endif
  // Suppress the call-waiting tone from the moment the user accepts: the CXCall stays
  // "ringing" until the answer roundtrip fulfills the action, which can take seconds.
  NSUUID *answeredUuid = [self applicationUUIDForCallKitUUID:action.callUUID];
  if (answeredUuid == nil) {
    [action fail];
    return;
  }
  [_answeringCallUuids addObject:action.callUUID];
  [_delegateFlutterApi performAnswerCall:answeredUuid.UUIDString
                              completion:^(NSNumber *fulfill, FlutterError *error) {
                                if (error != nil || [fulfill boolValue] != YES) {
                                  [self->_answeringCallUuids removeObject:action.callUUID];
                                  [action fail];
                                } else {
                                  [action fulfill];
                                }
                              }];
}

- (void)provider:(CXProvider *)provider performEndCallAction:(CXEndCallAction *)action {
#ifdef DEBUG
  NSLog(@"[Callkeep][CXProviderDelegate][provider:performEndCallAction:]");
#endif
  // An end action this plugin did not request came from the CallKit UI (the end or decline
  // button, a headset, the lock screen): a person ended the call on this device. The plugin
  // itself ends calls only through endCall: or by reporting an end, which CallKit does not
  // turn into an action.
  NSNumber *ownInitiator = _ownEndActionInitiators[action.UUID];
  [_ownEndActionInitiators removeObjectForKey:action.UUID];
  WTPEndedByEnum endedBy = ownInitiator != nil ? (WTPEndedByEnum)ownInitiator.unsignedIntegerValue : WTPEndedByEnumUser;
  NSUUID *endedUuid = [self applicationUUIDForCallKitUUID:action.callUUID];
  if (endedUuid == nil) {
    // A presentation its call has moved on from, or of a call that is over: there is nothing of
    // the application's to end under this UUID. The call, if it lives, is ended where it is shown.
    [action fulfill];
    return;
  }
  [_endingCallUuids addObject:action.callUUID];
  [_delegateFlutterApi performEndCall:endedUuid.UUIDString
                              endedBy:endedBy
                           completion:^(NSNumber *fulfill, FlutterError *error) {
                             [self->_endingCallUuids removeObject:action.callUUID];
                             if (error != nil || [fulfill boolValue] != YES) {
                               [action fail];
                             } else {
                               [action fulfill];
                               [self forgetCall:action.callUUID];
                               // As in reportEndCall: the next waiting call enters before iOS has
                               // a moment in which the app holds no call.
                               [self releaseQueuedIncomingIfNothingRings];
                             }
                           }];
}

- (void)provider:(CXProvider *)provider performSetHeldCallAction:(CXSetHeldCallAction *)action {
#ifdef DEBUG
  NSLog(@"[Callkeep][CXProviderDelegate][provider:performSetHeldCallAction:]");
#endif
  // The hold before a third call - see "Hold before a third call": CallKit's only.
  if ([_screenHoldActionUuids containsObject:action.UUID]) {
    [_screenHoldActionUuids removeObject:action.UUID];
    WTPLog(@"[Callkeep][hold-before-third] %@ %@ in CallKit", action.onHold ? @"holding" : @"taking off hold",
          action.callUUID.UUIDString);
    [action fulfill];
    return;
  }
  // The plugin's own hold on the members of a group - see "Group hold".
  if ([_groupHoldActionUuids containsObject:action.UUID]) {
    [_groupHoldActionUuids removeObject:action.UUID];
    [_requestedGroupActionUuids removeObject:action.UUID];
    [action fulfill];
    return;
  }
  NSUUID *actedUuid = [self applicationUUIDForCallKitUUID:action.callUUID];
  if (actedUuid == nil) {
    [action fail];
    return;
  }
  [_delegateFlutterApi performSetHeld:actedUuid.UUIDString
                               onHold:action.onHold
                           completion:^(NSNumber *fulfill, FlutterError *error) {
                             if (error != nil || [fulfill boolValue] != YES) {
                               [action fail];
                             } else {
                               [action fulfill];
                             }
                           }];
}

- (void)provider:(CXProvider *)provider performSetMutedCallAction:(CXSetMutedCallAction *)action {
#ifdef DEBUG
  NSLog(@"[Callkeep][CXProviderDelegate][provider:performSetMutedCallAction:]");
#endif
  BOOL own = [_ownMuteActionUuids containsObject:action.UUID];
  [_ownMuteActionUuids removeObject:action.UUID];
  // When CallKit activates the audio session again - a call ended on the far side while the
  // others were held, say - the session comes back with its input unmuted, and CallKit mirrors
  // that onto the calls: an unmute nobody asked for ("setUplinkMuted false ... userInitiated 0"),
  // measured 107 and 164 ms after the activation. Passed on, it unmuted a call the user had
  // muted. So an unmute the plugin did not request, for a call last known muted, arriving that
  // soon after an activation is refused: CallKit keeps the call muted, and the application never
  // hears of it. A person unmuting from the system UI or from a headset cannot do it within that
  // window of a session coming up, and one who somehow did has to press again.
  if (!own && !action.muted && [_mutedCallUuids containsObject:action.callUUID] &&
      CFAbsoluteTimeGetCurrent() - _audioSessionActivatedAt < kAudioSessionMuteResyncWindow) {
    [action fail];
    return;
  }
  NSUUID *actedUuid = [self applicationUUIDForCallKitUUID:action.callUUID];
  if (actedUuid == nil) {
    [action fail];
    return;
  }
  [_delegateFlutterApi performSetMuted:actedUuid.UUIDString
                                 muted:action.muted
                            completion:^(NSNumber *fulfill, FlutterError *error) {
                              if (error != nil || [fulfill boolValue] != YES) {
                                [action fail];
                              } else {
                                if (action.muted) {
                                  [self->_mutedCallUuids addObject:action.callUUID];
                                } else {
                                  [self->_mutedCallUuids removeObject:action.callUUID];
                                }
                                [action fulfill];
                              }
                            }];
}

- (void)provider:(CXProvider *)provider performSetGroupCallAction:(CXSetGroupCallAction *)action {
#ifdef DEBUG
  NSLog(@"[Callkeep][CXProviderDelegate][provider:performSetGroupCallAction:]");
#endif
  // Reached for grouping this plugin requested as well as for grouping started elsewhere:
  // CallKit routes every action through the provider delegate, the same way hold does. A
  // grouping the application asked for through setCallGroup is already its decision, so it is
  // fulfilled here without asking again - the way the Android backends apply a group without
  // a round trip. Only a grouping started in the system call UI goes to the application, where
  // a refusal fails the action and leaves the system presentation as it was.
  if ([_requestedGroupActionUuids containsObject:action.UUID]) {
    [_requestedGroupActionUuids removeObject:action.UUID];
    [action fulfill];
    return;
  }
  NSUUID *groupedUuid = [self applicationUUIDForCallKitUUID:action.callUUID];
  NSUUID *groupedWithUuid =
      action.callUUIDToGroupWith != nil ? [self applicationUUIDForCallKitUUID:action.callUUIDToGroupWith] : nil;
  if (groupedUuid == nil || (action.callUUIDToGroupWith != nil && groupedWithUuid == nil)) {
    [action fail];
    return;
  }
  [_delegateFlutterApi performSetCallGroup:groupedUuid.UUIDString
                           groupWithCallId:groupedWithUuid.UUIDString
                                completion:^(NSNumber *fulfill, FlutterError *error) {
                                  if (error != nil || [fulfill boolValue] != YES) {
                                    [action fail];
                                  } else {
                                    [action fulfill];
                                  }
                                }];
}

- (void)provider:(CXProvider *)provider performPlayDTMFCallAction:(CXPlayDTMFCallAction *)action {
#ifdef DEBUG
  NSLog(@"[Callkeep][CXProviderDelegate][provider:performPlayDTMFCallAction:]");
#endif
  if (action.type != CXPlayDTMFCallActionTypeSingleTone) {
    [action fail];
    return;
  }
  NSUUID *actedUuid = [self applicationUUIDForCallKitUUID:action.callUUID];
  if (actedUuid == nil) {
    [action fail];
    return;
  }
  [_delegateFlutterApi performSendDTMF:actedUuid.UUIDString
                                   key:action.digits
                            completion:^(NSNumber *fulfill, FlutterError *error) {
                              if (error != nil || [fulfill boolValue] != YES) {
                                [action fail];
                              } else {
                                [action fulfill];
                              }
                            }];
}

- (void)provider:(CXProvider *)provider timedOutPerformingAction:(CXAction *)action {
#ifdef DEBUG
  NSLog(@"[Callkeep][CXProviderDelegate][provider:timedOutPerformingAction:] action = %@", action);
#endif
}

- (void)provider:(CXProvider *)provider didActivateAudioSession:(AVAudioSession *)audioSession {
#ifdef DEBUG
  NSLog(@"[CallKeep][CXProviderDelegate][provider:didActivateAudioSession:]");
#endif
  _audioSessionActivatedAt = CFAbsoluteTimeGetCurrent();
  // Pre-warm the call-waiting tone player before the Dart side starts the WebRTC
  // voice-processing engine (playback sources created after it are near-silent).
  [_callWaitingTone onAudioSessionActivated];
  // Re-evaluate the tone on the observer's queue: this callback runs on the provider's
  // private queue and must not resume playback from stale state on its own.
  dispatch_async(dispatch_get_main_queue(), ^{
    CXCallController *controller = self->_callController;
    if (controller != nil) {
      [self syncCallWaitingTone:controller.callObserver];
    }
  });
  [_delegateFlutterApi didActivateAudioSession:^(FlutterError *error) {}];
}

- (void)provider:(CXProvider *)provider didDeactivateAudioSession:(AVAudioSession *)audioSession {
#ifdef DEBUG
  NSLog(@"[CallKeep][CXProviderDelegate][provider:didDeactivateAudioSession:]");
#endif
  [_callWaitingTone onAudioSessionDeactivated];
  [_delegateFlutterApi didDeactivateAudioSession:^(FlutterError *error) {}];
}

#pragma mark - helpers

- (WTPIOSOptions *)getUserDefaultsIosOptions {
  NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:OptionsKey];
  if (data != nil) {
    NSError *error;
    NSDictionary *iosOptionsMap = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    if (iosOptionsMap != nil) {
      // Currently is necessary to overcome possible inconsistence with the options dictionary because of add/remove/rename properties of WTPIOSOptions class.
      // This logic could be refactored when the following limitation is eliminated - Initialization isn't supported for fields in Pigeon data classes.
      NSDictionary *iosOptionsMapDefault = @{
        @"driveIdleTimerDisabled": @YES,
      };
      NSMutableDictionary *iosOptionsMapMerged = [[NSMutableDictionary alloc] init];
      [iosOptionsMapMerged addEntriesFromDictionary:iosOptionsMapDefault];
      [iosOptionsMapMerged addEntriesFromDictionary:iosOptionsMap];
      return [WTPIOSOptions fromMap:iosOptionsMapMerged];
    }
  }
  return nil;
}

- (BOOL)setUserDefaultsIosOptions:(WTPIOSOptions *)iosOptions {
  NSDictionary *iosOptionsMap = [iosOptions toMap];
  NSError *error;
  NSData *data = [NSJSONSerialization dataWithJSONObject:iosOptionsMap options:kNilOptions error:&error];
  NSData *currentData = [[NSUserDefaults standardUserDefaults] objectForKey:OptionsKey];
  if (currentData == nil || [data isEqualToData:currentData] != YES) {
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:OptionsKey];
    return YES;
  } else {
    return NO;
  }
}

- (void)removeUserDefaultsIosOptions {
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:OptionsKey];
}

- (void)assignIdleTimerDisabled:(BOOL)value {
  if (_driveIdleTimerDisabled) {
    [UIApplication sharedApplication].idleTimerDisabled = value;
  }
}

/// Records whether [uuid] is a video call, and re-decides the idle timer.
///
/// The screen is kept awake for a video call because the user is looking at it. That rule
/// has not changed; what has is the set it is decided over. `idleTimerDisabled` belongs to
/// the application, not to a call, so deciding it from whichever call last raised an event
/// lets one call answer for all of them - ending an audio call while a video call is live
/// let the screen sleep on the video call, and the reverse pinned it awake after the video
/// call was gone.
- (void)setVideo:(BOOL)video forCallUUID:(NSUUID *)uuid {
  if (uuid == nil) {
    return;
  }
  if (video) {
    [_videoCallUuids addObject:uuid];
  } else {
    [_videoCallUuids removeObject:uuid];
  }
  [self refreshIdleTimer];
}

/// The call is over, whoever ended it: it is no longer ours, no longer answering, and no
/// longer keeps the screen awake. Every end path comes through here, so a completion that
/// arrives late for the call finds it gone and cannot bring it back.
- (void)forgetCall:(NSUUID *)uuid {
  if (uuid == nil) {
    return;
  }
  [_ownCallUuids removeObject:uuid];
  [_answeringCallUuids removeObject:uuid];
  [_endingCallUuids removeObject:uuid];
  [_groupMemberUuids removeObject:uuid];
  [_mutedCallUuids removeObject:uuid];
  [_admittedIncomingUuids removeObject:uuid];
  // The presentation is over in CallKit; what it was a presentation OF is kept until the
  // application says the call is over, so that an action CallKit still delivers for this UUID
  // finds its call.
  [_presentations markOverCallKitUUID:uuid];
  [self setVideo:NO forCallUUID:uuid];
}

/// The UUID CallKit shows the call under that the application names by [uuid] - another one only
/// for a call that returned to CallKit after it was taken out (see answerQueuedIncomingCallUUID).
- (NSUUID *)presentedUuidFor:(NSUUID *)uuid {
  if (uuid == nil) {
    return nil;
  }
  return [_presentations callKitUUIDForLogicalUUID:uuid];
}

/// The UUID to name the call of a CallKit action by to the application - or nil when the action
/// is not the application's to hear of: it names a presentation its call has moved on from (taken
/// out of CallKit by this plugin, or replaced by a later one), or one of a call that is over. An
/// action for such a UUID acting on the call as the application has it now would act on the wrong
/// thing - on a conversation the user never touched, or on nothing at all.
- (nullable NSUUID *)applicationUUIDForCallKitUUID:(NSUUID *)uuid {
  switch ([_presentations standingOfCallKitUUID:uuid]) {
    case CallPresentationStandingUntracked:
    case CallPresentationStandingCurrent:
    case CallPresentationStandingOver:
      return [_presentations logicalUUIDForCallKitUUID:uuid];
    case CallPresentationStandingSuperseded:
    case CallPresentationStandingForgotten:
      return nil;
  }
}

/// Whether [uuid] is one of this plugin's calls that is still live: reported by us, not
/// forgotten by any end path, and not ended as far as the call observer knows. A call the
/// observer does not list yet counts as live: CallKit may complete a report before the
/// observer has seen the call.
- (BOOL)isLiveOwnCallUUID:(NSUUID *)uuid {
  if (uuid == nil || ![_ownCallUuids containsObject:uuid]) {
    return NO;
  }
  for (CXCall *call in _callController.callObserver.calls) {
    if ([call.UUID isEqual:uuid]) {
      return !call.hasEnded;
    }
  }
  return YES;
}

/// Keeps the screen awake while any live call is a video call.
///
/// The set holds only live calls: the observer drops a call from it when CallKit reports it
/// ended, which is the same place own-call tracking is pruned, so a call that ends while
/// the app is not looking cannot leave the screen pinned awake.
- (void)refreshIdleTimer {
  [self assignIdleTimerDisabled:_videoCallUuids.count > 0];
}

@end
