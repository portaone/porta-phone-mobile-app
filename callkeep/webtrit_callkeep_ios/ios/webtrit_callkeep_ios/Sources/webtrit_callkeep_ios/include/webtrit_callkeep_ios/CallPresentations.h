#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// One showing of an incoming call in CallKit.
///
/// The application names a call by one UUID for as long as the call lives (the "logical" UUID,
/// derived from the call id). CallKit usually shows the call under that same UUID - but a call
/// this plugin took out of CallKit and shows again later comes back under a new one, because a
/// UUID reported ended cannot be relied on a second time. A presentation is one such showing.
@interface CallPresentation : NSObject

/// The UUID the application names the call by.
@property(nonatomic, readonly) NSUUID *logicalUUID;

/// The UUID CallKit shows this presentation under.
@property(nonatomic, readonly) NSUUID *callKitUUID;

/// 1 for the first showing of the call, 2 for its second, and so on.
@property(nonatomic, readonly) NSUInteger generation;

@end

/// What is known about a UUID that CallKit hands back in an action.
typedef NS_ENUM(NSInteger, CallPresentationStanding) {
  /// No incoming call was ever shown under it: a call the application started, whose CallKit
  /// UUID is its logical one.
  CallPresentationStandingUntracked,
  /// The presentation the call is shown under now.
  CallPresentationStandingCurrent,
  /// The latest presentation of its call, already over in CallKit: the call was not shown again.
  CallPresentationStandingOver,
  /// A presentation this plugin took out of CallKit, or one the call has moved on from: the call
  /// lives under another presentation, or waits to be shown again.
  CallPresentationStandingSuperseded,
  /// A UUID made for a presentation of a call the registry has forgotten since.
  CallPresentationStandingForgotten,
};

/// The presentations of the incoming calls: which UUID CallKit shows a call under now, and which
/// ones it was shown under before.
///
/// It exists for the questions a callback that arrives late must be able to ask - a report's
/// completion, an action, an observer event: is this still the showing the call lives under, and
/// which call is it. A bare pair of maps answers neither once a call has had two showings.
///
/// Not thread-safe: the plugin uses it on the main queue only.
@interface CallPresentations : NSObject

/// The live presentation of [logicalUUID], or a new one when it has none (none yet, or the last
/// one is over). A new one is shown under the logical UUID itself, unless a presentation of this
/// call was ever withdrawn - then under a fresh UUID.
- (CallPresentation *)presentationToReportForLogicalUUID:(NSUUID *)logicalUUID;

/// The presentation of [logicalUUID] that is not over, if any.
- (nullable CallPresentation *)livePresentationOfLogicalUUID:(NSUUID *)logicalUUID;

/// The UUID CallKit knows the call under now: of its live presentation, or of its latest one,
/// or - for a call never presented - the logical UUID itself.
- (NSUUID *)callKitUUIDForLogicalUUID:(NSUUID *)logicalUUID;

/// Whether [presentation] is still the one its call lives under.
- (BOOL)isLive:(CallPresentation *)presentation;

/// What [callKitUUID] stands for now.
- (CallPresentationStanding)standingOfCallKitUUID:(NSUUID *)callKitUUID;

/// The logical UUID of the call shown under [callKitUUID] - for any standing but Forgotten, for
/// which there is none. An untracked UUID is its own logical UUID.
- (nullable NSUUID *)logicalUUIDForCallKitUUID:(NSUUID *)callKitUUID;

/// CallKit is done with the presentation shown under [callKitUUID]: it ended there.
- (void)markOverCallKitUUID:(NSUUID *)callKitUUID;

/// This plugin takes the live presentation of [logicalUUID] out of CallKit while the call lives
/// on; the next presentation of the call gets a fresh UUID. Returns the presentation taken out.
- (nullable CallPresentation *)withdrawLivePresentationOfLogicalUUID:(NSUUID *)logicalUUID;

/// Whether the next presentation of [logicalUUID] is a return after a withdrawal.
- (BOOL)wasWithdrawnLogicalUUID:(NSUUID *)logicalUUID;

/// The call is over for the application: its presentations are forgotten.
- (void)forgetLogicalUUID:(NSUUID *)logicalUUID;

/// The provider was reset or torn down: nothing of what was presented holds any more.
- (void)reset;

@end

NS_ASSUME_NONNULL_END
