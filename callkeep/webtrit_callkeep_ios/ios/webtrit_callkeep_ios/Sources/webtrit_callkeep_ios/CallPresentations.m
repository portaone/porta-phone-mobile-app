#import "CallPresentations.h"

@interface CallPresentation ()
@property(nonatomic) BOOL over;
@property(nonatomic) BOOL withdrawn;
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
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _byCallKitUUID = [NSMutableDictionary dictionary];
    _latestByLogicalUUID = [NSMutableDictionary dictionary];
    _withdrawnLogicalUUIDs = [NSMutableSet set];
    _mintedCallKitUUIDs = [NSMutableSet set];
  }
  return self;
}

- (CallPresentation *)presentationToReportForLogicalUUID:(NSUUID *)logicalUUID {
  CallPresentation *latest = _latestByLogicalUUID[logicalUUID];
  if (latest != nil && !latest.over) {
    return latest;
  }
  NSUUID *callKitUUID = logicalUUID;
  if ([_withdrawnLogicalUUIDs containsObject:logicalUUID]) {
    callKitUUID = [NSUUID UUID];
    [_mintedCallKitUUIDs addObject:callKitUUID];
  }
  CallPresentation *presentation = [[CallPresentation alloc] initWithLogicalUUID:logicalUUID
                                                                     callKitUUID:callKitUUID
                                                                      generation:latest.generation + 1];
  _byCallKitUUID[callKitUUID] = presentation;
  _latestByLogicalUUID[logicalUUID] = presentation;
  return presentation;
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
}

@end
