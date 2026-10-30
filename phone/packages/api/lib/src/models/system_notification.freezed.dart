// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'system_notification.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SystemNotification {


/// Create a copy of SystemNotification
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SystemNotificationCopyWith<SystemNotification> get copyWith => _$SystemNotificationCopyWithImpl<SystemNotification>(this as SystemNotification, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SystemNotification;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SystemNotification&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.content, _this.content) || other.content == _this.content)&&(identical(other.seen, _this.seen) || other.seen == _this.seen)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&(identical(other.readAt, _this.readAt) || other.readAt == _this.readAt)&&(identical(other.deletedAt, _this.deletedAt) || other.deletedAt == _this.deletedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SystemNotification;
  return Object.hash(runtimeType,_this.id,_this.title,_this.content,_this.seen,_this.type,_this.createdAt,_this.updatedAt,_this.readAt,_this.deletedAt);
}

@override
String toString() {
  final _this = this as SystemNotification;
  return 'SystemNotification(id: ${_this.id}, title: ${_this.title}, content: ${_this.content}, seen: ${_this.seen}, type: ${_this.type}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt}, readAt: ${_this.readAt}, deletedAt: ${_this.deletedAt})';
}


}

/// @nodoc
abstract mixin class $SystemNotificationCopyWith<$Res>  {
  factory $SystemNotificationCopyWith(SystemNotification value, $Res Function(SystemNotification) _then) = _$SystemNotificationCopyWithImpl;
@useResult
$Res call({
 int id, String title, String content, bool seen, SystemNotificationType type, DateTime createdAt, DateTime updatedAt, DateTime? readAt, DateTime? deletedAt
});




}
/// @nodoc
class _$SystemNotificationCopyWithImpl<$Res>
    implements $SystemNotificationCopyWith<$Res> {
  _$SystemNotificationCopyWithImpl(this._self, this._then);

  final SystemNotification _self;
  final $Res Function(SystemNotification) _then;

/// Create a copy of SystemNotification
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? content = null,Object? seen = null,Object? type = null,Object? createdAt = null,Object? updatedAt = null,Object? readAt = freezed,Object? deletedAt = freezed,}) {
  return _then(SystemNotification(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,seen: null == seen ? _self.seen : seen // ignore: cast_nullable_to_non_nullable
as bool,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as SystemNotificationType,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,readAt: freezed == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as DateTime?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [SystemNotification].
extension SystemNotificationPatterns on SystemNotification {
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


/// @nodoc
mixin _$SystemNotificationResponce {


/// Create a copy of SystemNotificationResponce
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SystemNotificationResponceCopyWith<SystemNotificationResponce> get copyWith => _$SystemNotificationResponceCopyWithImpl<SystemNotificationResponce>(this as SystemNotificationResponce, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SystemNotificationResponce;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SystemNotificationResponce&&const DeepCollectionEquality().equals(other.items, _this.items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SystemNotificationResponce;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items));
}

@override
String toString() {
  final _this = this as SystemNotificationResponce;
  return 'SystemNotificationResponce(items: ${_this.items})';
}


}

/// @nodoc
abstract mixin class $SystemNotificationResponceCopyWith<$Res>  {
  factory $SystemNotificationResponceCopyWith(SystemNotificationResponce value, $Res Function(SystemNotificationResponce) _then) = _$SystemNotificationResponceCopyWithImpl;
@useResult
$Res call({
 List<SystemNotification> items
});




}
/// @nodoc
class _$SystemNotificationResponceCopyWithImpl<$Res>
    implements $SystemNotificationResponceCopyWith<$Res> {
  _$SystemNotificationResponceCopyWithImpl(this._self, this._then);

  final SystemNotificationResponce _self;
  final $Res Function(SystemNotificationResponce) _then;

/// Create a copy of SystemNotificationResponce
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,}) {
  return _then(SystemNotificationResponce(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<SystemNotification>,
  ));
}

}


/// Adds pattern-matching-related methods to [SystemNotificationResponce].
extension SystemNotificationResponcePatterns on SystemNotificationResponce {
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


/// @nodoc
mixin _$SystemNotificationsDeleteResponse {


/// Create a copy of SystemNotificationsDeleteResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SystemNotificationsDeleteResponseCopyWith<SystemNotificationsDeleteResponse> get copyWith => _$SystemNotificationsDeleteResponseCopyWithImpl<SystemNotificationsDeleteResponse>(this as SystemNotificationsDeleteResponse, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SystemNotificationsDeleteResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SystemNotificationsDeleteResponse&&const DeepCollectionEquality().equals(other.deletedIds, _this.deletedIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SystemNotificationsDeleteResponse;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.deletedIds));
}

@override
String toString() {
  final _this = this as SystemNotificationsDeleteResponse;
  return 'SystemNotificationsDeleteResponse(deletedIds: ${_this.deletedIds})';
}


}

/// @nodoc
abstract mixin class $SystemNotificationsDeleteResponseCopyWith<$Res>  {
  factory $SystemNotificationsDeleteResponseCopyWith(SystemNotificationsDeleteResponse value, $Res Function(SystemNotificationsDeleteResponse) _then) = _$SystemNotificationsDeleteResponseCopyWithImpl;
@useResult
$Res call({
 List<int> deletedIds
});




}
/// @nodoc
class _$SystemNotificationsDeleteResponseCopyWithImpl<$Res>
    implements $SystemNotificationsDeleteResponseCopyWith<$Res> {
  _$SystemNotificationsDeleteResponseCopyWithImpl(this._self, this._then);

  final SystemNotificationsDeleteResponse _self;
  final $Res Function(SystemNotificationsDeleteResponse) _then;

/// Create a copy of SystemNotificationsDeleteResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deletedIds = null,}) {
  return _then(SystemNotificationsDeleteResponse(
deletedIds: null == deletedIds ? _self.deletedIds : deletedIds // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}

}


/// Adds pattern-matching-related methods to [SystemNotificationsDeleteResponse].
extension SystemNotificationsDeleteResponsePatterns on SystemNotificationsDeleteResponse {
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
