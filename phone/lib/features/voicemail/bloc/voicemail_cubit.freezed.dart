// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'voicemail_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$VoicemailState {


/// Create a copy of VoicemailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VoicemailStateCopyWith<VoicemailState> get copyWith => _$VoicemailStateCopyWithImpl<VoicemailState>(this as VoicemailState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as VoicemailState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VoicemailState&&(identical(other.filter, _this.filter) || other.filter == _this.filter)&&const DeepCollectionEquality().equals(other.filters, _this.filters)&&(identical(other.forwardSupported, _this.forwardSupported) || other.forwardSupported == _this.forwardSupported)&&const DeepCollectionEquality().equals(other.selectedVoicemailsIds, _this.selectedVoicemailsIds)&&const DeepCollectionEquality().equals(other.heardByListening, _this.heardByListening)&&const DeepCollectionEquality().equals(other.trashedItems, _this.trashedItems)&&(identical(other.trashStatus, _this.trashStatus) || other.trashStatus == _this.trashStatus)&&const DeepCollectionEquality().equals(other.trashError, _this.trashError)&&(identical(other.busy, _this.busy) || other.busy == _this.busy));
}


@override
int get hashCode {
  final _this = this as VoicemailState;
  return Object.hash(runtimeType,_this.filter,const DeepCollectionEquality().hash(_this.filters),_this.forwardSupported,const DeepCollectionEquality().hash(_this.selectedVoicemailsIds),const DeepCollectionEquality().hash(_this.heardByListening),const DeepCollectionEquality().hash(_this.trashedItems),_this.trashStatus,const DeepCollectionEquality().hash(_this.trashError),_this.busy);
}



}

/// @nodoc
abstract mixin class $VoicemailStateCopyWith<$Res>  {
  factory $VoicemailStateCopyWith(VoicemailState value, $Res Function(VoicemailState) _then) = _$VoicemailStateCopyWithImpl;
@useResult
$Res call({
 VoicemailFilter filter, List<VoicemailFilter> filters, bool forwardSupported, List<String> selectedVoicemailsIds, List<String> heardByListening, List<Voicemail> trashedItems, VoicemailStatus trashStatus, Object? trashError, bool busy
});




}
/// @nodoc
class _$VoicemailStateCopyWithImpl<$Res>
    implements $VoicemailStateCopyWith<$Res> {
  _$VoicemailStateCopyWithImpl(this._self, this._then);

  final VoicemailState _self;
  final $Res Function(VoicemailState) _then;

/// Create a copy of VoicemailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? filter = null,Object? filters = null,Object? forwardSupported = null,Object? selectedVoicemailsIds = null,Object? heardByListening = null,Object? trashedItems = null,Object? trashStatus = null,Object? trashError = freezed,Object? busy = null,}) {
  return _then(VoicemailState(
filter: null == filter ? _self.filter : filter // ignore: cast_nullable_to_non_nullable
as VoicemailFilter,filters: null == filters ? _self.filters : filters // ignore: cast_nullable_to_non_nullable
as List<VoicemailFilter>,forwardSupported: null == forwardSupported ? _self.forwardSupported : forwardSupported // ignore: cast_nullable_to_non_nullable
as bool,selectedVoicemailsIds: null == selectedVoicemailsIds ? _self.selectedVoicemailsIds : selectedVoicemailsIds // ignore: cast_nullable_to_non_nullable
as List<String>,heardByListening: null == heardByListening ? _self.heardByListening : heardByListening // ignore: cast_nullable_to_non_nullable
as List<String>,trashedItems: null == trashedItems ? _self.trashedItems : trashedItems // ignore: cast_nullable_to_non_nullable
as List<Voicemail>,trashStatus: null == trashStatus ? _self.trashStatus : trashStatus // ignore: cast_nullable_to_non_nullable
as VoicemailStatus,trashError: freezed == trashError ? _self.trashError : trashError ,busy: null == busy ? _self.busy : busy // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [VoicemailState].
extension VoicemailStatePatterns on VoicemailState {
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
