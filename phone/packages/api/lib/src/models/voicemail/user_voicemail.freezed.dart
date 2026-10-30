// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_voicemail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserVoicemail {


/// Create a copy of UserVoicemail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserVoicemailCopyWith<UserVoicemail> get copyWith => _$UserVoicemailCopyWithImpl<UserVoicemail>(this as UserVoicemail, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as UserVoicemail;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserVoicemail&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.duration, _this.duration) || other.duration == _this.duration)&&(identical(other.sender, _this.sender) || other.sender == _this.sender)&&(identical(other.receiver, _this.receiver) || other.receiver == _this.receiver)&&(identical(other.seen, _this.seen) || other.seen == _this.seen)&&(identical(other.size, _this.size) || other.size == _this.size)&&(identical(other.type, _this.type) || other.type == _this.type)&&const DeepCollectionEquality().equals(other.attachments, _this.attachments)&&(identical(other.saved, _this.saved) || other.saved == _this.saved)&&(identical(other.forwardedBy, _this.forwardedBy) || other.forwardedBy == _this.forwardedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as UserVoicemail;
  return Object.hash(runtimeType,_this.id,_this.date,_this.duration,_this.sender,_this.receiver,_this.seen,_this.size,_this.type,const DeepCollectionEquality().hash(_this.attachments),_this.saved,_this.forwardedBy);
}

@override
String toString() {
  final _this = this as UserVoicemail;
  return 'UserVoicemail(id: ${_this.id}, date: ${_this.date}, duration: ${_this.duration}, sender: ${_this.sender}, receiver: ${_this.receiver}, seen: ${_this.seen}, size: ${_this.size}, type: ${_this.type}, attachments: ${_this.attachments}, saved: ${_this.saved}, forwardedBy: ${_this.forwardedBy})';
}


}

/// @nodoc
abstract mixin class $UserVoicemailCopyWith<$Res>  {
  factory $UserVoicemailCopyWith(UserVoicemail value, $Res Function(UserVoicemail) _then) = _$UserVoicemailCopyWithImpl;
@useResult
$Res call({
 String id, String date, double duration, String sender, String receiver, bool seen, int size, String type, List<UserVoicemailAttachment> attachments, bool? saved, String? forwardedBy
});




}
/// @nodoc
class _$UserVoicemailCopyWithImpl<$Res>
    implements $UserVoicemailCopyWith<$Res> {
  _$UserVoicemailCopyWithImpl(this._self, this._then);

  final UserVoicemail _self;
  final $Res Function(UserVoicemail) _then;

/// Create a copy of UserVoicemail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? date = null,Object? duration = null,Object? sender = null,Object? receiver = null,Object? seen = null,Object? size = null,Object? type = null,Object? attachments = null,Object? saved = freezed,Object? forwardedBy = freezed,}) {
  return _then(UserVoicemail(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as double,sender: null == sender ? _self.sender : sender // ignore: cast_nullable_to_non_nullable
as String,receiver: null == receiver ? _self.receiver : receiver // ignore: cast_nullable_to_non_nullable
as String,seen: null == seen ? _self.seen : seen // ignore: cast_nullable_to_non_nullable
as bool,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,attachments: null == attachments ? _self.attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<UserVoicemailAttachment>,saved: freezed == saved ? _self.saved : saved // ignore: cast_nullable_to_non_nullable
as bool?,forwardedBy: freezed == forwardedBy ? _self.forwardedBy : forwardedBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [UserVoicemail].
extension UserVoicemailPatterns on UserVoicemail {
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
mixin _$UserVoicemailAttachment {


/// Create a copy of UserVoicemailAttachment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserVoicemailAttachmentCopyWith<UserVoicemailAttachment> get copyWith => _$UserVoicemailAttachmentCopyWithImpl<UserVoicemailAttachment>(this as UserVoicemailAttachment, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as UserVoicemailAttachment;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserVoicemailAttachment&&(identical(other.filename, _this.filename) || other.filename == _this.filename)&&(identical(other.size, _this.size) || other.size == _this.size)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.subtype, _this.subtype) || other.subtype == _this.subtype));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as UserVoicemailAttachment;
  return Object.hash(runtimeType,_this.filename,_this.size,_this.type,_this.subtype);
}

@override
String toString() {
  final _this = this as UserVoicemailAttachment;
  return 'UserVoicemailAttachment(filename: ${_this.filename}, size: ${_this.size}, type: ${_this.type}, subtype: ${_this.subtype})';
}


}

/// @nodoc
abstract mixin class $UserVoicemailAttachmentCopyWith<$Res>  {
  factory $UserVoicemailAttachmentCopyWith(UserVoicemailAttachment value, $Res Function(UserVoicemailAttachment) _then) = _$UserVoicemailAttachmentCopyWithImpl;
@useResult
$Res call({
 String filename, int size, String type, String subtype
});




}
/// @nodoc
class _$UserVoicemailAttachmentCopyWithImpl<$Res>
    implements $UserVoicemailAttachmentCopyWith<$Res> {
  _$UserVoicemailAttachmentCopyWithImpl(this._self, this._then);

  final UserVoicemailAttachment _self;
  final $Res Function(UserVoicemailAttachment) _then;

/// Create a copy of UserVoicemailAttachment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? filename = null,Object? size = null,Object? type = null,Object? subtype = null,}) {
  return _then(UserVoicemailAttachment(
filename: null == filename ? _self.filename : filename // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,subtype: null == subtype ? _self.subtype : subtype // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [UserVoicemailAttachment].
extension UserVoicemailAttachmentPatterns on UserVoicemailAttachment {
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
