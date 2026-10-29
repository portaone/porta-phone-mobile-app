// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'call_queues_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CallQueuesState {


/// Create a copy of CallQueuesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CallQueuesStateCopyWith<CallQueuesState> get copyWith => _$CallQueuesStateCopyWithImpl<CallQueuesState>(this as CallQueuesState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CallQueuesState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CallQueuesState&&const DeepCollectionEquality().equals(other.queues, _this.queues)&&(identical(other.known, _this.known) || other.known == _this.known)&&const DeepCollectionEquality().equals(other.pendingIds, _this.pendingIds)&&(identical(other.allPending, _this.allPending) || other.allPending == _this.allPending)&&(identical(other.readFailed, _this.readFailed) || other.readFailed == _this.readFailed));
}


@override
int get hashCode {
  final _this = this as CallQueuesState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.queues),_this.known,const DeepCollectionEquality().hash(_this.pendingIds),_this.allPending,_this.readFailed);
}

@override
String toString() {
  final _this = this as CallQueuesState;
  return 'CallQueuesState(queues: ${_this.queues}, known: ${_this.known}, pendingIds: ${_this.pendingIds}, allPending: ${_this.allPending}, readFailed: ${_this.readFailed})';
}


}

/// @nodoc
abstract mixin class $CallQueuesStateCopyWith<$Res>  {
  factory $CallQueuesStateCopyWith(CallQueuesState value, $Res Function(CallQueuesState) _then) = _$CallQueuesStateCopyWithImpl;
@useResult
$Res call({
 List<CallQueue> queues, bool known, Set<String> pendingIds, bool allPending, bool readFailed
});




}
/// @nodoc
class _$CallQueuesStateCopyWithImpl<$Res>
    implements $CallQueuesStateCopyWith<$Res> {
  _$CallQueuesStateCopyWithImpl(this._self, this._then);

  final CallQueuesState _self;
  final $Res Function(CallQueuesState) _then;

/// Create a copy of CallQueuesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? queues = null,Object? known = null,Object? pendingIds = null,Object? allPending = null,Object? readFailed = null,}) {
  return _then(CallQueuesState(
queues: null == queues ? _self.queues : queues // ignore: cast_nullable_to_non_nullable
as List<CallQueue>,known: null == known ? _self.known : known // ignore: cast_nullable_to_non_nullable
as bool,pendingIds: null == pendingIds ? _self.pendingIds : pendingIds // ignore: cast_nullable_to_non_nullable
as Set<String>,allPending: null == allPending ? _self.allPending : allPending // ignore: cast_nullable_to_non_nullable
as bool,readFailed: null == readFailed ? _self.readFailed : readFailed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CallQueuesState].
extension CallQueuesStatePatterns on CallQueuesState {
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
