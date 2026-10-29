// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_voicemail_list_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserVoicemailListResponse {


/// Create a copy of UserVoicemailListResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserVoicemailListResponseCopyWith<UserVoicemailListResponse> get copyWith => _$UserVoicemailListResponseCopyWithImpl<UserVoicemailListResponse>(this as UserVoicemailListResponse, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as UserVoicemailListResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserVoicemailListResponse&&(identical(other.hasNewMessages, _this.hasNewMessages) || other.hasNewMessages == _this.hasNewMessages)&&const DeepCollectionEquality().equals(other.items, _this.items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as UserVoicemailListResponse;
  return Object.hash(runtimeType,_this.hasNewMessages,const DeepCollectionEquality().hash(_this.items));
}

@override
String toString() {
  final _this = this as UserVoicemailListResponse;
  return 'UserVoicemailListResponse(hasNewMessages: ${_this.hasNewMessages}, items: ${_this.items})';
}


}

/// @nodoc
abstract mixin class $UserVoicemailListResponseCopyWith<$Res>  {
  factory $UserVoicemailListResponseCopyWith(UserVoicemailListResponse value, $Res Function(UserVoicemailListResponse) _then) = _$UserVoicemailListResponseCopyWithImpl;
@useResult
$Res call({
 bool hasNewMessages, List<UserVoicemailSummary> items
});




}
/// @nodoc
class _$UserVoicemailListResponseCopyWithImpl<$Res>
    implements $UserVoicemailListResponseCopyWith<$Res> {
  _$UserVoicemailListResponseCopyWithImpl(this._self, this._then);

  final UserVoicemailListResponse _self;
  final $Res Function(UserVoicemailListResponse) _then;

/// Create a copy of UserVoicemailListResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? hasNewMessages = null,Object? items = null,}) {
  return _then(UserVoicemailListResponse(
hasNewMessages: null == hasNewMessages ? _self.hasNewMessages : hasNewMessages // ignore: cast_nullable_to_non_nullable
as bool,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<UserVoicemailSummary>,
  ));
}

}


/// Adds pattern-matching-related methods to [UserVoicemailListResponse].
extension UserVoicemailListResponsePatterns on UserVoicemailListResponse {
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
mixin _$UserVoicemailSummary {


/// Create a copy of UserVoicemailSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserVoicemailSummaryCopyWith<UserVoicemailSummary> get copyWith => _$UserVoicemailSummaryCopyWithImpl<UserVoicemailSummary>(this as UserVoicemailSummary, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as UserVoicemailSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserVoicemailSummary&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.duration, _this.duration) || other.duration == _this.duration)&&(identical(other.seen, _this.seen) || other.seen == _this.seen)&&(identical(other.size, _this.size) || other.size == _this.size)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.saved, _this.saved) || other.saved == _this.saved)&&(identical(other.forwardedBy, _this.forwardedBy) || other.forwardedBy == _this.forwardedBy)&&(identical(other.sender, _this.sender) || other.sender == _this.sender)&&(identical(other.receiver, _this.receiver) || other.receiver == _this.receiver));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as UserVoicemailSummary;
  return Object.hash(runtimeType,_this.id,_this.date,_this.duration,_this.seen,_this.size,_this.type,_this.saved,_this.forwardedBy,_this.sender,_this.receiver);
}

@override
String toString() {
  final _this = this as UserVoicemailSummary;
  return 'UserVoicemailSummary(id: ${_this.id}, date: ${_this.date}, duration: ${_this.duration}, seen: ${_this.seen}, size: ${_this.size}, type: ${_this.type}, saved: ${_this.saved}, forwardedBy: ${_this.forwardedBy}, sender: ${_this.sender}, receiver: ${_this.receiver})';
}


}

/// @nodoc
abstract mixin class $UserVoicemailSummaryCopyWith<$Res>  {
  factory $UserVoicemailSummaryCopyWith(UserVoicemailSummary value, $Res Function(UserVoicemailSummary) _then) = _$UserVoicemailSummaryCopyWithImpl;
@useResult
$Res call({
 String id, String date, bool seen, int size, String type, double? duration, bool? saved, String? forwardedBy, String? sender, String? receiver
});




}
/// @nodoc
class _$UserVoicemailSummaryCopyWithImpl<$Res>
    implements $UserVoicemailSummaryCopyWith<$Res> {
  _$UserVoicemailSummaryCopyWithImpl(this._self, this._then);

  final UserVoicemailSummary _self;
  final $Res Function(UserVoicemailSummary) _then;

/// Create a copy of UserVoicemailSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? date = null,Object? seen = null,Object? size = null,Object? type = null,Object? duration = freezed,Object? saved = freezed,Object? forwardedBy = freezed,Object? sender = freezed,Object? receiver = freezed,}) {
  return _then(UserVoicemailSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,seen: null == seen ? _self.seen : seen // ignore: cast_nullable_to_non_nullable
as bool,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as double?,saved: freezed == saved ? _self.saved : saved // ignore: cast_nullable_to_non_nullable
as bool?,forwardedBy: freezed == forwardedBy ? _self.forwardedBy : forwardedBy // ignore: cast_nullable_to_non_nullable
as String?,sender: freezed == sender ? _self.sender : sender // ignore: cast_nullable_to_non_nullable
as String?,receiver: freezed == receiver ? _self.receiver : receiver // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [UserVoicemailSummary].
extension UserVoicemailSummaryPatterns on UserVoicemailSummary {
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
