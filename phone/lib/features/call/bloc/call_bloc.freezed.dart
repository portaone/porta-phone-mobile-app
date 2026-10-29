// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'call_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CallState implements DiagnosticableTreeMixin {


/// Create a copy of CallState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CallStateCopyWith<CallState> get copyWith => _$CallStateCopyWithImpl<CallState>(this as CallState, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as CallState;
  properties
    ..add(DiagnosticsProperty('type', 'CallState'))
    ..add(DiagnosticsProperty('callServiceState', _this.callServiceState))..add(DiagnosticsProperty('currentAppLifecycleState', _this.currentAppLifecycleState))..add(DiagnosticsProperty('linesCount', _this.linesCount))..add(DiagnosticsProperty('activeCalls', _this.activeCalls))..add(DiagnosticsProperty('minimized', _this.minimized))..add(DiagnosticsProperty('audioDevice', _this.audioDevice))..add(DiagnosticsProperty('audioDeviceRequest', _this.audioDeviceRequest))..add(DiagnosticsProperty('availableAudioDevices', _this.availableAudioDevices))..add(DiagnosticsProperty('selectedCallId', _this.selectedCallId))..add(DiagnosticsProperty('placedCallFocus', _this.placedCallFocus))..add(DiagnosticsProperty('conference', _this.conference))..add(DiagnosticsProperty('linkedCall', _this.linkedCall));
}

@override
bool operator ==(Object other) {
  final _this = this as CallState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CallState&&(identical(other.callServiceState, _this.callServiceState) || other.callServiceState == _this.callServiceState)&&(identical(other.currentAppLifecycleState, _this.currentAppLifecycleState) || other.currentAppLifecycleState == _this.currentAppLifecycleState)&&(identical(other.linesCount, _this.linesCount) || other.linesCount == _this.linesCount)&&const DeepCollectionEquality().equals(other.activeCalls, _this.activeCalls)&&(identical(other.minimized, _this.minimized) || other.minimized == _this.minimized)&&(identical(other.audioDevice, _this.audioDevice) || other.audioDevice == _this.audioDevice)&&(identical(other.audioDeviceRequest, _this.audioDeviceRequest) || other.audioDeviceRequest == _this.audioDeviceRequest)&&const DeepCollectionEquality().equals(other.availableAudioDevices, _this.availableAudioDevices)&&(identical(other.selectedCallId, _this.selectedCallId) || other.selectedCallId == _this.selectedCallId)&&(identical(other.placedCallFocus, _this.placedCallFocus) || other.placedCallFocus == _this.placedCallFocus)&&(identical(other.conference, _this.conference) || other.conference == _this.conference)&&(identical(other.linkedCall, _this.linkedCall) || other.linkedCall == _this.linkedCall));
}


@override
int get hashCode {
  final _this = this as CallState;
  return Object.hash(runtimeType,_this.callServiceState,_this.currentAppLifecycleState,_this.linesCount,const DeepCollectionEquality().hash(_this.activeCalls),_this.minimized,_this.audioDevice,_this.audioDeviceRequest,const DeepCollectionEquality().hash(_this.availableAudioDevices),_this.selectedCallId,_this.placedCallFocus,_this.conference,_this.linkedCall);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as CallState;
  return 'CallState(callServiceState: ${_this.callServiceState}, currentAppLifecycleState: ${_this.currentAppLifecycleState}, linesCount: ${_this.linesCount}, activeCalls: ${_this.activeCalls}, minimized: ${_this.minimized}, audioDevice: ${_this.audioDevice}, audioDeviceRequest: ${_this.audioDeviceRequest}, availableAudioDevices: ${_this.availableAudioDevices}, selectedCallId: ${_this.selectedCallId}, placedCallFocus: ${_this.placedCallFocus}, conference: ${_this.conference}, linkedCall: ${_this.linkedCall})';
}


}

/// @nodoc
abstract mixin class $CallStateCopyWith<$Res>  {
  factory $CallStateCopyWith(CallState value, $Res Function(CallState) _then) = _$CallStateCopyWithImpl;
@useResult
$Res call({
 CallServiceState callServiceState, AppLifecycleState? currentAppLifecycleState, int linesCount, List<ActiveCall> activeCalls, bool? minimized, CallAudioDevice? audioDevice, AudioDeviceRequest? audioDeviceRequest, List<CallAudioDevice> availableAudioDevices, String? selectedCallId, ({String callId, String? returnsTo,})? placedCallFocus, ConferenceState conference, LinkedCall? linkedCall
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
@pragma('vm:prefer-inline') @override $Res call({Object? callServiceState = null,Object? currentAppLifecycleState = freezed,Object? linesCount = null,Object? activeCalls = null,Object? minimized = freezed,Object? audioDevice = freezed,Object? audioDeviceRequest = freezed,Object? availableAudioDevices = null,Object? selectedCallId = freezed,Object? placedCallFocus = freezed,Object? conference = null,Object? linkedCall = freezed,}) {
  return _then(CallState(
callServiceState: null == callServiceState ? _self.callServiceState : callServiceState // ignore: cast_nullable_to_non_nullable
as CallServiceState,currentAppLifecycleState: freezed == currentAppLifecycleState ? _self.currentAppLifecycleState : currentAppLifecycleState // ignore: cast_nullable_to_non_nullable
as AppLifecycleState?,linesCount: null == linesCount ? _self.linesCount : linesCount // ignore: cast_nullable_to_non_nullable
as int,activeCalls: null == activeCalls ? _self.activeCalls : activeCalls // ignore: cast_nullable_to_non_nullable
as List<ActiveCall>,minimized: freezed == minimized ? _self.minimized : minimized // ignore: cast_nullable_to_non_nullable
as bool?,audioDevice: freezed == audioDevice ? _self.audioDevice : audioDevice // ignore: cast_nullable_to_non_nullable
as CallAudioDevice?,audioDeviceRequest: freezed == audioDeviceRequest ? _self.audioDeviceRequest : audioDeviceRequest // ignore: cast_nullable_to_non_nullable
as AudioDeviceRequest?,availableAudioDevices: null == availableAudioDevices ? _self.availableAudioDevices : availableAudioDevices // ignore: cast_nullable_to_non_nullable
as List<CallAudioDevice>,selectedCallId: freezed == selectedCallId ? _self.selectedCallId : selectedCallId // ignore: cast_nullable_to_non_nullable
as String?,placedCallFocus: freezed == placedCallFocus ? _self.placedCallFocus : placedCallFocus // ignore: cast_nullable_to_non_nullable
as ({String callId, String? returnsTo,})?,conference: null == conference ? _self.conference : conference // ignore: cast_nullable_to_non_nullable
as ConferenceState,linkedCall: freezed == linkedCall ? _self.linkedCall : linkedCall // ignore: cast_nullable_to_non_nullable
as LinkedCall?,
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
