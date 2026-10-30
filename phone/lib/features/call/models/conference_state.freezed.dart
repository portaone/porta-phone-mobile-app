// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'conference_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ConferenceState {


/// Create a copy of ConferenceState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConferenceStateCopyWith<ConferenceState> get copyWith => _$ConferenceStateCopyWithImpl<ConferenceState>(this as ConferenceState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ConferenceState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConferenceState&&(identical(other.room, _this.room) || other.room == _this.room)&&(identical(other.phase, _this.phase) || other.phase == _this.phase)&&const DeepCollectionEquality().equals(other.legs, _this.legs)&&const DeepCollectionEquality().equals(other.participants, _this.participants)&&(identical(other.selfMuted, _this.selfMuted) || other.selfMuted == _this.selfMuted));
}


@override
int get hashCode {
  final _this = this as ConferenceState;
  return Object.hash(runtimeType,_this.room,_this.phase,const DeepCollectionEquality().hash(_this.legs),const DeepCollectionEquality().hash(_this.participants),_this.selfMuted);
}

@override
String toString() {
  final _this = this as ConferenceState;
  return 'ConferenceState(room: ${_this.room}, phase: ${_this.phase}, legs: ${_this.legs}, participants: ${_this.participants}, selfMuted: ${_this.selfMuted})';
}


}

/// @nodoc
abstract mixin class $ConferenceStateCopyWith<$Res>  {
  factory $ConferenceStateCopyWith(ConferenceState value, $Res Function(ConferenceState) _then) = _$ConferenceStateCopyWithImpl;
@useResult
$Res call({
 int? room, ConferencePhase phase, Map<String, int> legs, List<ConferenceParticipant> participants, bool selfMuted
});




}
/// @nodoc
class _$ConferenceStateCopyWithImpl<$Res>
    implements $ConferenceStateCopyWith<$Res> {
  _$ConferenceStateCopyWithImpl(this._self, this._then);

  final ConferenceState _self;
  final $Res Function(ConferenceState) _then;

/// Create a copy of ConferenceState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? room = freezed,Object? phase = null,Object? legs = null,Object? participants = null,Object? selfMuted = null,}) {
  return _then(ConferenceState(
room: freezed == room ? _self.room : room // ignore: cast_nullable_to_non_nullable
as int?,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as ConferencePhase,legs: null == legs ? _self.legs : legs // ignore: cast_nullable_to_non_nullable
as Map<String, int>,participants: null == participants ? _self.participants : participants // ignore: cast_nullable_to_non_nullable
as List<ConferenceParticipant>,selfMuted: null == selfMuted ? _self.selfMuted : selfMuted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ConferenceState].
extension ConferenceStatePatterns on ConferenceState {
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
