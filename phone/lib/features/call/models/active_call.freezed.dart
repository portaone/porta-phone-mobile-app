// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'active_call.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ActiveCall {


/// Create a copy of ActiveCall
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActiveCallCopyWith<ActiveCall> get copyWith => _$ActiveCallCopyWithImpl<ActiveCall>(this as ActiveCall, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ActiveCall;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActiveCall&&(identical(other.direction, _this.direction) || other.direction == _this.direction)&&(identical(other.line, _this.line) || other.line == _this.line)&&(identical(other.callId, _this.callId) || other.callId == _this.callId)&&(identical(other.handle, _this.handle) || other.handle == _this.handle)&&(identical(other.createdTime, _this.createdTime) || other.createdTime == _this.createdTime)&&(identical(other.video, _this.video) || other.video == _this.video)&&(identical(other.videoPermissionDenied, _this.videoPermissionDenied) || other.videoPermissionDenied == _this.videoPermissionDenied)&&(identical(other.processingStatus, _this.processingStatus) || other.processingStatus == _this.processingStatus)&&(identical(other.frontCamera, _this.frontCamera) || other.frontCamera == _this.frontCamera)&&(identical(other.held, _this.held) || other.held == _this.held)&&(identical(other.muted, _this.muted) || other.muted == _this.muted)&&(identical(other.updating, _this.updating) || other.updating == _this.updating)&&(identical(other.incomingOffer, _this.incomingOffer) || other.incomingOffer == _this.incomingOffer)&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName)&&(identical(other.fromReferId, _this.fromReferId) || other.fromReferId == _this.fromReferId)&&(identical(other.fromReplaces, _this.fromReplaces) || other.fromReplaces == _this.fromReplaces)&&(identical(other.fromNumber, _this.fromNumber) || other.fromNumber == _this.fromNumber)&&(identical(other.acceptedTime, _this.acceptedTime) || other.acceptedTime == _this.acceptedTime)&&(identical(other.hungUpTime, _this.hungUpTime) || other.hungUpTime == _this.hungUpTime)&&(identical(other.transfer, _this.transfer) || other.transfer == _this.transfer)&&const DeepCollectionEquality().equals(other.failure, _this.failure)&&(identical(other.localStream, _this.localStream) || other.localStream == _this.localStream)&&(identical(other.remoteStream, _this.remoteStream) || other.remoteStream == _this.remoteStream)&&(identical(other.remoteCameraEnabled, _this.remoteCameraEnabled) || other.remoteCameraEnabled == _this.remoteCameraEnabled)&&(identical(other.transition, _this.transition) || other.transition == _this.transition)&&(identical(other.peerReportedConferenceMute, _this.peerReportedConferenceMute) || other.peerReportedConferenceMute == _this.peerReportedConferenceMute)&&(identical(other.peerReportedConferenceHostAway, _this.peerReportedConferenceHostAway) || other.peerReportedConferenceHostAway == _this.peerReportedConferenceHostAway)&&const DeepCollectionEquality().equals(other.iceCandidates, _this.iceCandidates)&&(identical(other.iceConnectionIssue, _this.iceConnectionIssue) || other.iceConnectionIssue == _this.iceConnectionIssue)&&(identical(other.networkQuality, _this.networkQuality) || other.networkQuality == _this.networkQuality)&&(identical(other.earlyMedia, _this.earlyMedia) || other.earlyMedia == _this.earlyMedia));
}


@override
int get hashCode {
  final _this = this as ActiveCall;
  return Object.hashAll([runtimeType,_this.direction,_this.line,_this.callId,_this.handle,_this.createdTime,_this.video,_this.videoPermissionDenied,_this.processingStatus,_this.frontCamera,_this.held,_this.muted,_this.updating,_this.incomingOffer,_this.displayName,_this.fromReferId,_this.fromReplaces,_this.fromNumber,_this.acceptedTime,_this.hungUpTime,_this.transfer,const DeepCollectionEquality().hash(_this.failure),_this.localStream,_this.remoteStream,_this.remoteCameraEnabled,_this.transition,_this.peerReportedConferenceMute,_this.peerReportedConferenceHostAway,const DeepCollectionEquality().hash(_this.iceCandidates),_this.iceConnectionIssue,_this.networkQuality,_this.earlyMedia]);
}

@override
String toString() {
  final _this = this as ActiveCall;
  return 'ActiveCall(direction: ${_this.direction}, line: ${_this.line}, callId: ${_this.callId}, handle: ${_this.handle}, createdTime: ${_this.createdTime}, video: ${_this.video}, videoPermissionDenied: ${_this.videoPermissionDenied}, processingStatus: ${_this.processingStatus}, frontCamera: ${_this.frontCamera}, held: ${_this.held}, muted: ${_this.muted}, updating: ${_this.updating}, incomingOffer: ${_this.incomingOffer}, displayName: ${_this.displayName}, fromReferId: ${_this.fromReferId}, fromReplaces: ${_this.fromReplaces}, fromNumber: ${_this.fromNumber}, acceptedTime: ${_this.acceptedTime}, hungUpTime: ${_this.hungUpTime}, transfer: ${_this.transfer}, failure: ${_this.failure}, localStream: ${_this.localStream}, remoteStream: ${_this.remoteStream}, remoteCameraEnabled: ${_this.remoteCameraEnabled}, transition: ${_this.transition}, peerReportedConferenceMute: ${_this.peerReportedConferenceMute}, peerReportedConferenceHostAway: ${_this.peerReportedConferenceHostAway}, iceCandidates: ${_this.iceCandidates}, iceConnectionIssue: ${_this.iceConnectionIssue}, networkQuality: ${_this.networkQuality}, earlyMedia: ${_this.earlyMedia})';
}


}

/// @nodoc
abstract mixin class $ActiveCallCopyWith<$Res>  {
  factory $ActiveCallCopyWith(ActiveCall value, $Res Function(ActiveCall) _then) = _$ActiveCallCopyWithImpl;
@useResult
$Res call({
 CallDirection direction, int? line, String callId, CallkeepHandle handle, DateTime createdTime, bool video, CallProcessingStatus processingStatus, bool videoPermissionDenied, bool? frontCamera, bool held, bool muted, bool updating, JsepValue? incomingOffer, String? displayName, String? fromReferId, String? fromReplaces, String? fromNumber, DateTime? acceptedTime, DateTime? hungUpTime, Transfer? transfer, Object? failure, MediaStream? localStream, MediaStream? remoteStream, bool? remoteCameraEnabled, CallTransition? transition, bool? peerReportedConferenceMute, bool? peerReportedConferenceHostAway, List<RTCIceCandidate> iceCandidates, IceConnectionIssue? iceConnectionIssue, CallNetworkQuality? networkQuality, bool earlyMedia
});




}
/// @nodoc
class _$ActiveCallCopyWithImpl<$Res>
    implements $ActiveCallCopyWith<$Res> {
  _$ActiveCallCopyWithImpl(this._self, this._then);

  final ActiveCall _self;
  final $Res Function(ActiveCall) _then;

/// Create a copy of ActiveCall
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? direction = null,Object? line = freezed,Object? callId = null,Object? handle = null,Object? createdTime = null,Object? video = null,Object? processingStatus = null,Object? videoPermissionDenied = null,Object? frontCamera = freezed,Object? held = null,Object? muted = null,Object? updating = null,Object? incomingOffer = freezed,Object? displayName = freezed,Object? fromReferId = freezed,Object? fromReplaces = freezed,Object? fromNumber = freezed,Object? acceptedTime = freezed,Object? hungUpTime = freezed,Object? transfer = freezed,Object? failure = freezed,Object? localStream = freezed,Object? remoteStream = freezed,Object? remoteCameraEnabled = freezed,Object? transition = freezed,Object? peerReportedConferenceMute = freezed,Object? peerReportedConferenceHostAway = freezed,Object? iceCandidates = null,Object? iceConnectionIssue = freezed,Object? networkQuality = freezed,Object? earlyMedia = null,}) {
  return _then(ActiveCall(
direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as CallDirection,line: freezed == line ? _self.line : line // ignore: cast_nullable_to_non_nullable
as int?,callId: null == callId ? _self.callId : callId // ignore: cast_nullable_to_non_nullable
as String,handle: null == handle ? _self.handle : handle // ignore: cast_nullable_to_non_nullable
as CallkeepHandle,createdTime: null == createdTime ? _self.createdTime : createdTime // ignore: cast_nullable_to_non_nullable
as DateTime,video: null == video ? _self.video : video // ignore: cast_nullable_to_non_nullable
as bool,processingStatus: null == processingStatus ? _self.processingStatus : processingStatus // ignore: cast_nullable_to_non_nullable
as CallProcessingStatus,videoPermissionDenied: null == videoPermissionDenied ? _self.videoPermissionDenied : videoPermissionDenied // ignore: cast_nullable_to_non_nullable
as bool,frontCamera: freezed == frontCamera ? _self.frontCamera : frontCamera // ignore: cast_nullable_to_non_nullable
as bool?,held: null == held ? _self.held : held // ignore: cast_nullable_to_non_nullable
as bool,muted: null == muted ? _self.muted : muted // ignore: cast_nullable_to_non_nullable
as bool,updating: null == updating ? _self.updating : updating // ignore: cast_nullable_to_non_nullable
as bool,incomingOffer: freezed == incomingOffer ? _self.incomingOffer : incomingOffer // ignore: cast_nullable_to_non_nullable
as JsepValue?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,fromReferId: freezed == fromReferId ? _self.fromReferId : fromReferId // ignore: cast_nullable_to_non_nullable
as String?,fromReplaces: freezed == fromReplaces ? _self.fromReplaces : fromReplaces // ignore: cast_nullable_to_non_nullable
as String?,fromNumber: freezed == fromNumber ? _self.fromNumber : fromNumber // ignore: cast_nullable_to_non_nullable
as String?,acceptedTime: freezed == acceptedTime ? _self.acceptedTime : acceptedTime // ignore: cast_nullable_to_non_nullable
as DateTime?,hungUpTime: freezed == hungUpTime ? _self.hungUpTime : hungUpTime // ignore: cast_nullable_to_non_nullable
as DateTime?,transfer: freezed == transfer ? _self.transfer : transfer // ignore: cast_nullable_to_non_nullable
as Transfer?,failure: freezed == failure ? _self.failure : failure ,localStream: freezed == localStream ? _self.localStream : localStream // ignore: cast_nullable_to_non_nullable
as MediaStream?,remoteStream: freezed == remoteStream ? _self.remoteStream : remoteStream // ignore: cast_nullable_to_non_nullable
as MediaStream?,remoteCameraEnabled: freezed == remoteCameraEnabled ? _self.remoteCameraEnabled : remoteCameraEnabled // ignore: cast_nullable_to_non_nullable
as bool?,transition: freezed == transition ? _self.transition : transition // ignore: cast_nullable_to_non_nullable
as CallTransition?,peerReportedConferenceMute: freezed == peerReportedConferenceMute ? _self.peerReportedConferenceMute : peerReportedConferenceMute // ignore: cast_nullable_to_non_nullable
as bool?,peerReportedConferenceHostAway: freezed == peerReportedConferenceHostAway ? _self.peerReportedConferenceHostAway : peerReportedConferenceHostAway // ignore: cast_nullable_to_non_nullable
as bool?,iceCandidates: null == iceCandidates ? _self.iceCandidates : iceCandidates // ignore: cast_nullable_to_non_nullable
as List<RTCIceCandidate>,iceConnectionIssue: freezed == iceConnectionIssue ? _self.iceConnectionIssue : iceConnectionIssue // ignore: cast_nullable_to_non_nullable
as IceConnectionIssue?,networkQuality: freezed == networkQuality ? _self.networkQuality : networkQuality // ignore: cast_nullable_to_non_nullable
as CallNetworkQuality?,earlyMedia: null == earlyMedia ? _self.earlyMedia : earlyMedia // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ActiveCall].
extension ActiveCallPatterns on ActiveCall {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({required TResult orElse(),}){
final _that = this;
switch (_that) {
case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({required TResult orElse(),}) {final _that = this;
switch (_that) {
case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
  return null;

}
}

}

// dart format on
