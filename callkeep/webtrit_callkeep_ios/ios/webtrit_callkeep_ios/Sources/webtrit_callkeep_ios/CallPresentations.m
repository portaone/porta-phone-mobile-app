#import "CallPresentations.h"

@interface CallPresentation ()
@property(nonatomic) BOOL over;
@property(nonatomic) BOOL withdrawn;
@property(nonatomic, nullable) NSNumber *offeredAtMs;
- (instancetype)initWithLogicalUUID:(NSUUID *)logicalUUID callKitUUID:(NSUUID *)callKitUUID generation:(NSUInteger)generation;
@end

@implementation CallPresentation

- (instancetype)initWithLogicalUUID:(NSUUID *)logicalUUID callKitUUID:(NSUUID *)callKitUUID generation:(NSUInteger)generation {
  self = [super init];
  if (self) {
    _logicalUUID = logicalUUID;
    _callKitUUID = callKitUUID;
    _generation = generation;
  }
  return self;
}

@end

@implementation CallPresentations {
  // Every presentation of the calls not forgotten yet, by the UUID CallKit shows it under, and
  // the latest one of each call by its logical UUID.
  NSMutableDictionary<NSUUID *, CallPresentation *> *_byCallKitUUID;
  NSMutableDictionary<NSUUID *, CallPresentation *> *_latestByLogicalUUID;
  // Calls a presentation of which was withdrawn: their own UUID was reported ended to CallKit
  // while they lived, so every later presentation of them is shown under a fresh one.
  NSMutableSet<NSUUID *> *_withdrawnLogicalUUIDs;
  // The fresh UUIDs ever handed out. One of them without a presentation left belongs to a call
  // that is over; it must never be mistaken for a logical UUID.
  NSMutableSet<NSUUID *> *_mintedCallKitUUIDs;
  // The last presentation of each call the application ended (forgotten), oldest first, at most
  // kEndedLimit: an offer of its call id again is told against it - a new attempt or a late copy.
  NSMutableDictionary<NSUUID *, CallPresentation *> *_endedByLogicalUUID;
  NSMutableArray<NSUUID *> *_endedOrder;
}

static const NSUInteger kEndedLimit = 64;

- (instancetype)init {
  self = [super init];
  if (self) {
    _byCallKitUUID = [NSMutableDictionary dictionary];
    _latestByLogicalUUID = [NSMutableDictionary dictionary];
    _withdrawnLogicalUUIDs = [NSMutableSet set];
    _mintedCallKitUUIDs = [NSMutableSet set];
    _endedByLogicalUUID = [NSMutableDictionary dictionary];
    _endedOrder = [NSMutableArray array];
  }
  return self;
}

- (CallPresentation *)presentationToReportForLogicalUUID:(NSUUID *)logicalUUID {
  return [self presentationToReportForLogicalUUID:logicalUUID offeredAtMs:nil];
}

- (CallPresentation *)presentationToReportForLogicalUUID:(NSUUID *)logicalUUID
                                             offeredAtMs:(nullable NSNumber *)offeredAtMs {
  CallPresentation *latest = _latestByLogicalUUID[logicalUUID];
  if (latest != nil && !latest.over) {
    // Another delivery of the live offer; Core's time of it, once known, is kept for a late copy.
    if (latest.offeredAtMs == nil && offeredAtMs != nil) latest.offeredAtMs = offeredAtMs;
    return latest;
  }
  // A late copy of the ended attempt is refused before this (ghostCallKitUUIDForLogicalUUID). With
  // Core's offered_at of both offers, another time is a new attempt: CallKit saw the ended one's
  // UUID end, so it is shown under a fresh one. When either time is unknown nothing tells the two
  // apart, and the call is presented as before this registry.
  CallPresentation *ended = _endedByLogicalUUID[logicalUUID];
  BOOL newAttempt = ended != nil && ended.offeredAtMs != nil && offeredAtMs != nil &&
                    ![ended.offeredAtMs isEqualToNumber:offeredAtMs];
  if (newAttempt) {
    [_endedByLogicalUUID removeObjectForKey:logicalUUID];
    [_endedOrder removeObject:logicalUUID];
  }
  NSUUID *callKitUUID = logicalUUID;
  if (newAttempt || [_withdrawnLogicalUUIDs containsObject:logicalUUID]) {
    callKitUUID = [NSUUID UUID];
    [_mintedCallKitUUIDs addObject:callKitUUID];
  }
  NSUInteger generation = MAX(latest.generation, ended.generation) + 1;
  CallPresentation *presentation = [[CallPresentation alloc] initWithLogicalUUID:logicalUUID
                                                                     callKitUUID:callKitUUID
                                                                      generation:generation];
  presentation.offeredAtMs = offeredAtMs;
  _byCallKitUUID[callKitUUID] = presentation;
  _latestByLogicalUUID[logicalUUID] = presentation;
  return presentation;
}

- (nullable NSUUID *)ghostCallKitUUIDForLogicalUUID:(NSUUID *)logicalUUID offeredAtMs:(nullable NSNumber *)offeredAtMs {
  if (offeredAtMs == nil || [self livePresentationOfLogicalUUID:logicalUUID] != nil) {
    return nil;
  }
  CallPresentation *ended = _endedByLogicalUUID[logicalUUID];
  if (ended.offeredAtMs == nil || ![ended.offeredAtMs isEqualToNumber:offeredAtMs]) {
    return nil;
  }
  return ended.callKitUUID;
}

- (nullable CallPresentation *)livePresentationOfLogicalUUID:(NSUUID *)logicalUUID {
  CallPresentation *latest = _latestByLogicalUUID[logicalUUID];
  return latest.over ? nil : latest;
}

- (NSUUID *)callKitUUIDForLogicalUUID:(NSUUID *)logicalUUID {
  return _latestByLogicalUUID[logicalUUID].callKitUUID ?: logicalUUID;
}

- (BOOL)isLive:(CallPresentation *)presentation {
  return !presentation.over && _latestByLogicalUUID[presentation.logicalUUID] == presentation;
}

- (CallPresentationStanding)standingOfCallKitUUID:(NSUUID *)callKitUUID {
  CallPresentation *presentation = _byCallKitUUID[callKitUUID];
  if (presentation == nil) {
    return [_mintedCallKitUUIDs containsObject:callKitUUID] ? CallPresentationStandingForgotten
                                                             : CallPresentationStandingUntracked;
  }
  if (presentation.withdrawn || _latestByLogicalUUID[presentation.logicalUUID] != presentation) {
    return CallPresentationStandingSuperseded;
  }
  return presentation.over ? CallPresentationStandingOver : CallPresentationStandingCurrent;
}

- (nullable NSUUID *)logicalUUIDForCallKitUUID:(NSUUID *)callKitUUID {
  CallPresentation *presentation = _byCallKitUUID[callKitUUID];
  if (presentation != nil) {
    return presentation.logicalUUID;
  }
  return [_mintedCallKitUUIDs containsObject:callKitUUID] ? nil : callKitUUID;
}

- (void)markOverCallKitUUID:(NSUUID *)callKitUUID {
  _byCallKitUUID[callKitUUID].over = YES;
}

- (nullable CallPresentation *)withdrawLivePresentationOfLogicalUUID:(NSUUID *)logicalUUID {
  CallPresentation *live = [self livePresentationOfLogicalUUID:logicalUUID];
  if (live == nil) {
    return nil;
  }
  live.over = YES;
  live.withdrawn = YES;
  [_withdrawnLogicalUUIDs addObject:logicalUUID];
  return live;
}

- (BOOL)wasWithdrawnLogicalUUID:(NSUUID *)logicalUUID {
  return [_withdrawnLogicalUUIDs containsObject:logicalUUID];
}

- (void)forgetLogicalUUID:(NSUUID *)logicalUUID {
  CallPresentation *latest = _latestByLogicalUUID[logicalUUID];
  if (latest != nil) {
    [_endedOrder removeObject:logicalUUID];
    [_endedOrder addObject:logicalUUID];
    _endedByLogicalUUID[logicalUUID] = latest;
    while (_endedOrder.count > kEndedLimit) {
      [_endedByLogicalUUID removeObjectForKey:_endedOrder.firstObject];
      [_endedOrder removeObjectAtIndex:0];
    }
  }
  [_latestByLogicalUUID removeObjectForKey:logicalUUID];
  for (NSUUID *callKitUUID in _byCallKitUUID.allKeys) {
    if ([_byCallKitUUID[callKitUUID].logicalUUID isEqual:logicalUUID]) {
      [_byCallKitUUID removeObjectForKey:callKitUUID];
    }
  }
}

- (void)reset {
  [_byCallKitUUID removeAllObjects];
  [_latestByLogicalUUID removeAllObjects];
  [_withdrawnLogicalUUIDs removeAllObjects];
  [_mintedCallKitUUIDs removeAllObjects];
  [_endedByLogicalUUID removeAllObjects];
  [_endedOrder removeAllObjects];
}

@end
