// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'call_queue.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CallQueue {

 String get id; String get name; bool get loggedIn; int get agentsTotal; int get agentsLoggedIn; int? get callersWaiting;
/// Create a copy of CallQueue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CallQueueCopyWith<CallQueue> get copyWith => _$CallQueueCopyWithImpl<CallQueue>(this as CallQueue, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CallQueue&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.loggedIn, loggedIn) || other.loggedIn == loggedIn)&&(identical(other.agentsTotal, agentsTotal) || other.agentsTotal == agentsTotal)&&(identical(other.agentsLoggedIn, agentsLoggedIn) || other.agentsLoggedIn == agentsLoggedIn)&&(identical(other.callersWaiting, callersWaiting) || other.callersWaiting == callersWaiting));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,loggedIn,agentsTotal,agentsLoggedIn,callersWaiting);

@override
String toString() {
  return 'CallQueue(id: $id, name: $name, loggedIn: $loggedIn, agentsTotal: $agentsTotal, agentsLoggedIn: $agentsLoggedIn, callersWaiting: $callersWaiting)';
}


}

/// @nodoc
abstract mixin class $CallQueueCopyWith<$Res>  {
  factory $CallQueueCopyWith(CallQueue value, $Res Function(CallQueue) _then) = _$CallQueueCopyWithImpl;
@useResult
$Res call({
 String id, String name, bool loggedIn, int agentsTotal, int agentsLoggedIn, int? callersWaiting
});




}
/// @nodoc
class _$CallQueueCopyWithImpl<$Res>
    implements $CallQueueCopyWith<$Res> {
  _$CallQueueCopyWithImpl(this._self, this._then);

  final CallQueue _self;
  final $Res Function(CallQueue) _then;

/// Create a copy of CallQueue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? loggedIn = null,Object? agentsTotal = null,Object? agentsLoggedIn = null,Object? callersWaiting = freezed,}) {
  return _then(CallQueue(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,loggedIn: null == loggedIn ? _self.loggedIn : loggedIn // ignore: cast_nullable_to_non_nullable
as bool,agentsTotal: null == agentsTotal ? _self.agentsTotal : agentsTotal // ignore: cast_nullable_to_non_nullable
as int,agentsLoggedIn: null == agentsLoggedIn ? _self.agentsLoggedIn : agentsLoggedIn // ignore: cast_nullable_to_non_nullable
as int,callersWaiting: freezed == callersWaiting ? _self.callersWaiting : callersWaiting // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [CallQueue].
extension CallQueuePatterns on CallQueue {
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
