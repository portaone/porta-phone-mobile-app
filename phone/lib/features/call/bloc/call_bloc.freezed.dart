// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'call_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CallState {

 CallServiceState get callServiceState; AppLifecycleState? get currentAppLifecycleState; int get linesCount; List<ActiveCall> get activeCalls; bool? get minimized; CallAudioDevice? get audioDevice; List<CallAudioDevice> get availableAudioDevices; String? get selectedCallId; ConferenceState get conference;
/// Create a copy of CallState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CallStateCopyWith<CallState> get copyWith => _$CallStateCopyWithImpl<CallState>(this as CallState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CallState&&(identical(other.callServiceState, callServiceState) || other.callServiceState == callServiceState)&&(identical(other.currentAppLifecycleState, currentAppLifecycleState) || other.currentAppLifecycleState == currentAppLifecycleState)&&(identical(other.linesCount, linesCount) || other.linesCount == linesCount)&&const DeepCollectionEquality().equals(other.activeCalls, activeCalls)&&(identical(other.minimized, minimized) || other.minimized == minimized)&&(identical(other.audioDevice, audioDevice) || other.audioDevice == audioDevice)&&const DeepCollectionEquality().equals(other.availableAudioDevices, availableAudioDevices)&&(identical(other.selectedCallId, selectedCallId) || other.selectedCallId == selectedCallId)&&(identical(other.conference, conference) || other.conference == conference));
}


@override
int get hashCode => Object.hash(runtimeType,callServiceState,currentAppLifecycleState,linesCount,const DeepCollectionEquality().hash(activeCalls),minimized,audioDevice,const DeepCollectionEquality().hash(availableAudioDevices),selectedCallId,conference);

@override
String toString() {
  return 'CallState(callServiceState: $callServiceState, currentAppLifecycleState: $currentAppLifecycleState, linesCount: $linesCount, activeCalls: $activeCalls, minimized: $minimized, audioDevice: $audioDevice, availableAudioDevices: $availableAudioDevices, selectedCallId: $selectedCallId, conference: $conference)';
}


}

/// @nodoc
abstract mixin class $CallStateCopyWith<$Res>  {
  factory $CallStateCopyWith(CallState value, $Res Function(CallState) _then) = _$CallStateCopyWithImpl;
@useResult
$Res call({
 CallServiceState callServiceState, AppLifecycleState? currentAppLifecycleState, int linesCount, List<ActiveCall> activeCalls, bool? minimized, CallAudioDevice? audioDevice, List<CallAudioDevice> availableAudioDevices, String? selectedCallId, ConferenceState conference
});




}
/// @nodoc
class _$CallStateCopyWithImpl<$Res>
    implements $CallStateCopyWith<$Res> {
  _$CallStateCopyWithImpl(this._self, this._then);

  final CallState _self;
  final $Res Function(CallState) _then;

/// Create a copy of CallState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? callServiceState = null,Object? currentAppLifecycleState = freezed,Object? linesCount = null,Object? activeCalls = null,Object? minimized = freezed,Object? audioDevice = freezed,Object? availableAudioDevices = null,Object? selectedCallId = freezed,Object? conference = null,}) {
  return _then(CallState(
callServiceState: null == callServiceState ? _self.callServiceState : callServiceState // ignore: cast_nullable_to_non_nullable
as CallServiceState,currentAppLifecycleState: freezed == currentAppLifecycleState ? _self.currentAppLifecycleState : currentAppLifecycleState // ignore: cast_nullable_to_non_nullable
as AppLifecycleState?,linesCount: null == linesCount ? _self.linesCount : linesCount // ignore: cast_nullable_to_non_nullable
as int,activeCalls: null == activeCalls ? _self.activeCalls : activeCalls // ignore: cast_nullable_to_non_nullable
as List<ActiveCall>,minimized: freezed == minimized ? _self.minimized : minimized // ignore: cast_nullable_to_non_nullable
as bool?,audioDevice: freezed == audioDevice ? _self.audioDevice : audioDevice // ignore: cast_nullable_to_non_nullable
as CallAudioDevice?,availableAudioDevices: null == availableAudioDevices ? _self.availableAudioDevices : availableAudioDevices // ignore: cast_nullable_to_non_nullable
as List<CallAudioDevice>,selectedCallId: freezed == selectedCallId ? _self.selectedCallId : selectedCallId // ignore: cast_nullable_to_non_nullable
as String?,conference: null == conference ? _self.conference : conference // ignore: cast_nullable_to_non_nullable
as ConferenceState,
  ));
}

}


/// Adds pattern-matching-related methods to [CallState].
extension CallStatePatterns on CallState {
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
