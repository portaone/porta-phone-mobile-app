// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'favorites.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FavoritesGetResult {


/// Create a copy of FavoritesGetResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FavoritesGetResultCopyWith<FavoritesGetResult> get copyWith => _$FavoritesGetResultCopyWithImpl<FavoritesGetResult>(this as FavoritesGetResult, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FavoritesGetResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FavoritesGetResult&&(identical(other.notModified, _this.notModified) || other.notModified == _this.notModified)&&(identical(other.etag, _this.etag) || other.etag == _this.etag)&&(identical(other.data, _this.data) || other.data == _this.data));
}


@override
int get hashCode {
  final _this = this as FavoritesGetResult;
  return Object.hash(runtimeType,_this.notModified,_this.etag,_this.data);
}

@override
String toString() {
  final _this = this as FavoritesGetResult;
  return 'FavoritesGetResult(notModified: ${_this.notModified}, etag: ${_this.etag}, data: ${_this.data})';
}


}

/// @nodoc
abstract mixin class $FavoritesGetResultCopyWith<$Res>  {
  factory $FavoritesGetResultCopyWith(FavoritesGetResult value, $Res Function(FavoritesGetResult) _then) = _$FavoritesGetResultCopyWithImpl;
@useResult
$Res call({
 bool notModified, String etag, FavoritesListResponse? data
});




}
/// @nodoc
class _$FavoritesGetResultCopyWithImpl<$Res>
    implements $FavoritesGetResultCopyWith<$Res> {
  _$FavoritesGetResultCopyWithImpl(this._self, this._then);

  final FavoritesGetResult _self;
  final $Res Function(FavoritesGetResult) _then;

/// Create a copy of FavoritesGetResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? notModified = null,Object? etag = null,Object? data = freezed,}) {
  return _then(FavoritesGetResult(
notModified: null == notModified ? _self.notModified : notModified // ignore: cast_nullable_to_non_nullable
as bool,etag: null == etag ? _self.etag : etag // ignore: cast_nullable_to_non_nullable
as String,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as FavoritesListResponse?,
  ));
}

}


/// Adds pattern-matching-related methods to [FavoritesGetResult].
extension FavoritesGetResultPatterns on FavoritesGetResult {
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
mixin _$FavoritesListResponse {


/// Create a copy of FavoritesListResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FavoritesListResponseCopyWith<FavoritesListResponse> get copyWith => _$FavoritesListResponseCopyWithImpl<FavoritesListResponse>(this as FavoritesListResponse, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FavoritesListResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FavoritesListResponse&&const DeepCollectionEquality().equals(other.items, _this.items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as FavoritesListResponse;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items));
}

@override
String toString() {
  final _this = this as FavoritesListResponse;
  return 'FavoritesListResponse(items: ${_this.items})';
}


}

/// @nodoc
abstract mixin class $FavoritesListResponseCopyWith<$Res>  {
  factory $FavoritesListResponseCopyWith(FavoritesListResponse value, $Res Function(FavoritesListResponse) _then) = _$FavoritesListResponseCopyWithImpl;
@useResult
$Res call({
 List<FavoriteItem> items
});




}
/// @nodoc
class _$FavoritesListResponseCopyWithImpl<$Res>
    implements $FavoritesListResponseCopyWith<$Res> {
  _$FavoritesListResponseCopyWithImpl(this._self, this._then);

  final FavoritesListResponse _self;
  final $Res Function(FavoritesListResponse) _then;

/// Create a copy of FavoritesListResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,}) {
  return _then(FavoritesListResponse(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<FavoriteItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [FavoritesListResponse].
extension FavoritesListResponsePatterns on FavoritesListResponse {
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
mixin _$FavoriteItem {


/// Create a copy of FavoriteItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FavoriteItemCopyWith<FavoriteItem> get copyWith => _$FavoriteItemCopyWithImpl<FavoriteItem>(this as FavoriteItem, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FavoriteItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FavoriteItem&&(identical(other.number, _this.number) || other.number == _this.number)&&(identical(other.sourceType, _this.sourceType) || other.sourceType == _this.sourceType)&&(identical(other.sourceId, _this.sourceId) || other.sourceId == _this.sourceId)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.position, _this.position) || other.position == _this.position));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as FavoriteItem;
  return Object.hash(runtimeType,_this.number,_this.sourceType,_this.sourceId,_this.label,_this.position);
}

@override
String toString() {
  final _this = this as FavoriteItem;
  return 'FavoriteItem(number: ${_this.number}, sourceType: ${_this.sourceType}, sourceId: ${_this.sourceId}, label: ${_this.label}, position: ${_this.position})';
}


}

/// @nodoc
abstract mixin class $FavoriteItemCopyWith<$Res>  {
  factory $FavoriteItemCopyWith(FavoriteItem value, $Res Function(FavoriteItem) _then) = _$FavoriteItemCopyWithImpl;
@useResult
$Res call({
 String number, FavoriteSourceType sourceType, String sourceId, String label, int position
});




}
/// @nodoc
class _$FavoriteItemCopyWithImpl<$Res>
    implements $FavoriteItemCopyWith<$Res> {
  _$FavoriteItemCopyWithImpl(this._self, this._then);

  final FavoriteItem _self;
  final $Res Function(FavoriteItem) _then;

/// Create a copy of FavoriteItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? number = null,Object? sourceType = null,Object? sourceId = null,Object? label = null,Object? position = null,}) {
  return _then(FavoriteItem(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,sourceType: null == sourceType ? _self.sourceType : sourceType // ignore: cast_nullable_to_non_nullable
as FavoriteSourceType,sourceId: null == sourceId ? _self.sourceId : sourceId // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [FavoriteItem].
extension FavoriteItemPatterns on FavoriteItem {
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
mixin _$FavoriteBatchAction {


/// Create a copy of FavoriteBatchAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FavoriteBatchActionCopyWith<FavoriteBatchAction> get copyWith => _$FavoriteBatchActionCopyWithImpl<FavoriteBatchAction>(this as FavoriteBatchAction, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FavoriteBatchAction;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FavoriteBatchAction&&(identical(other.action, _this.action) || other.action == _this.action)&&(identical(other.number, _this.number) || other.number == _this.number)&&(identical(other.sourceType, _this.sourceType) || other.sourceType == _this.sourceType)&&(identical(other.sourceId, _this.sourceId) || other.sourceId == _this.sourceId)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.position, _this.position) || other.position == _this.position));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as FavoriteBatchAction;
  return Object.hash(runtimeType,_this.action,_this.number,_this.sourceType,_this.sourceId,_this.label,_this.position);
}

@override
String toString() {
  final _this = this as FavoriteBatchAction;
  return 'FavoriteBatchAction(action: ${_this.action}, number: ${_this.number}, sourceType: ${_this.sourceType}, sourceId: ${_this.sourceId}, label: ${_this.label}, position: ${_this.position})';
}


}

/// @nodoc
abstract mixin class $FavoriteBatchActionCopyWith<$Res>  {
  factory $FavoriteBatchActionCopyWith(FavoriteBatchAction value, $Res Function(FavoriteBatchAction) _then) = _$FavoriteBatchActionCopyWithImpl;
@useResult
$Res call({
 FavoriteBatchActionType action, String number, FavoriteSourceType sourceType, String? sourceId, String? label, int? position
});




}
/// @nodoc
class _$FavoriteBatchActionCopyWithImpl<$Res>
    implements $FavoriteBatchActionCopyWith<$Res> {
  _$FavoriteBatchActionCopyWithImpl(this._self, this._then);

  final FavoriteBatchAction _self;
  final $Res Function(FavoriteBatchAction) _then;

/// Create a copy of FavoriteBatchAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? action = null,Object? number = null,Object? sourceType = null,Object? sourceId = freezed,Object? label = freezed,Object? position = freezed,}) {
  return _then(FavoriteBatchAction(
action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as FavoriteBatchActionType,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,sourceType: null == sourceType ? _self.sourceType : sourceType // ignore: cast_nullable_to_non_nullable
as FavoriteSourceType,sourceId: freezed == sourceId ? _self.sourceId : sourceId // ignore: cast_nullable_to_non_nullable
as String?,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,position: freezed == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [FavoriteBatchAction].
extension FavoriteBatchActionPatterns on FavoriteBatchAction {
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
mixin _$FavoriteBatchSyncResult {


/// Create a copy of FavoriteBatchSyncResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FavoriteBatchSyncResultCopyWith<FavoriteBatchSyncResult> get copyWith => _$FavoriteBatchSyncResultCopyWithImpl<FavoriteBatchSyncResult>(this as FavoriteBatchSyncResult, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FavoriteBatchSyncResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FavoriteBatchSyncResult&&(identical(other.data, _this.data) || other.data == _this.data)&&(identical(other.etag, _this.etag) || other.etag == _this.etag));
}


@override
int get hashCode {
  final _this = this as FavoriteBatchSyncResult;
  return Object.hash(runtimeType,_this.data,_this.etag);
}

@override
String toString() {
  final _this = this as FavoriteBatchSyncResult;
  return 'FavoriteBatchSyncResult(data: ${_this.data}, etag: ${_this.etag})';
}


}

/// @nodoc
abstract mixin class $FavoriteBatchSyncResultCopyWith<$Res>  {
  factory $FavoriteBatchSyncResultCopyWith(FavoriteBatchSyncResult value, $Res Function(FavoriteBatchSyncResult) _then) = _$FavoriteBatchSyncResultCopyWithImpl;
@useResult
$Res call({
 FavoriteBatchSyncResponse data, String etag
});




}
/// @nodoc
class _$FavoriteBatchSyncResultCopyWithImpl<$Res>
    implements $FavoriteBatchSyncResultCopyWith<$Res> {
  _$FavoriteBatchSyncResultCopyWithImpl(this._self, this._then);

  final FavoriteBatchSyncResult _self;
  final $Res Function(FavoriteBatchSyncResult) _then;

/// Create a copy of FavoriteBatchSyncResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? data = null,Object? etag = null,}) {
  return _then(FavoriteBatchSyncResult(
data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as FavoriteBatchSyncResponse,etag: null == etag ? _self.etag : etag // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [FavoriteBatchSyncResult].
extension FavoriteBatchSyncResultPatterns on FavoriteBatchSyncResult {
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
mixin _$FavoriteBatchSyncResponse {


/// Create a copy of FavoriteBatchSyncResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FavoriteBatchSyncResponseCopyWith<FavoriteBatchSyncResponse> get copyWith => _$FavoriteBatchSyncResponseCopyWithImpl<FavoriteBatchSyncResponse>(this as FavoriteBatchSyncResponse, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FavoriteBatchSyncResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FavoriteBatchSyncResponse&&const DeepCollectionEquality().equals(other.items, _this.items)&&const DeepCollectionEquality().equals(other.conflicts, _this.conflicts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as FavoriteBatchSyncResponse;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items),const DeepCollectionEquality().hash(_this.conflicts));
}

@override
String toString() {
  final _this = this as FavoriteBatchSyncResponse;
  return 'FavoriteBatchSyncResponse(items: ${_this.items}, conflicts: ${_this.conflicts})';
}


}

/// @nodoc
abstract mixin class $FavoriteBatchSyncResponseCopyWith<$Res>  {
  factory $FavoriteBatchSyncResponseCopyWith(FavoriteBatchSyncResponse value, $Res Function(FavoriteBatchSyncResponse) _then) = _$FavoriteBatchSyncResponseCopyWithImpl;
@useResult
$Res call({
 List<FavoriteItem> items, List<FavoriteBatchConflict> conflicts
});




}
/// @nodoc
class _$FavoriteBatchSyncResponseCopyWithImpl<$Res>
    implements $FavoriteBatchSyncResponseCopyWith<$Res> {
  _$FavoriteBatchSyncResponseCopyWithImpl(this._self, this._then);

  final FavoriteBatchSyncResponse _self;
  final $Res Function(FavoriteBatchSyncResponse) _then;

/// Create a copy of FavoriteBatchSyncResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? conflicts = null,}) {
  return _then(FavoriteBatchSyncResponse(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<FavoriteItem>,conflicts: null == conflicts ? _self.conflicts : conflicts // ignore: cast_nullable_to_non_nullable
as List<FavoriteBatchConflict>,
  ));
}

}


/// Adds pattern-matching-related methods to [FavoriteBatchSyncResponse].
extension FavoriteBatchSyncResponsePatterns on FavoriteBatchSyncResponse {
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
mixin _$FavoriteBatchConflict {


/// Create a copy of FavoriteBatchConflict
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FavoriteBatchConflictCopyWith<FavoriteBatchConflict> get copyWith => _$FavoriteBatchConflictCopyWithImpl<FavoriteBatchConflict>(this as FavoriteBatchConflict, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FavoriteBatchConflict;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FavoriteBatchConflict&&(identical(other.action, _this.action) || other.action == _this.action)&&(identical(other.number, _this.number) || other.number == _this.number)&&(identical(other.sourceType, _this.sourceType) || other.sourceType == _this.sourceType)&&(identical(other.reason, _this.reason) || other.reason == _this.reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as FavoriteBatchConflict;
  return Object.hash(runtimeType,_this.action,_this.number,_this.sourceType,_this.reason);
}

@override
String toString() {
  final _this = this as FavoriteBatchConflict;
  return 'FavoriteBatchConflict(action: ${_this.action}, number: ${_this.number}, sourceType: ${_this.sourceType}, reason: ${_this.reason})';
}


}

/// @nodoc
abstract mixin class $FavoriteBatchConflictCopyWith<$Res>  {
  factory $FavoriteBatchConflictCopyWith(FavoriteBatchConflict value, $Res Function(FavoriteBatchConflict) _then) = _$FavoriteBatchConflictCopyWithImpl;
@useResult
$Res call({
 FavoriteBatchActionType action, String number, FavoriteSourceType sourceType, FavoriteBatchConflictReason reason
});




}
/// @nodoc
class _$FavoriteBatchConflictCopyWithImpl<$Res>
    implements $FavoriteBatchConflictCopyWith<$Res> {
  _$FavoriteBatchConflictCopyWithImpl(this._self, this._then);

  final FavoriteBatchConflict _self;
  final $Res Function(FavoriteBatchConflict) _then;

/// Create a copy of FavoriteBatchConflict
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? action = null,Object? number = null,Object? sourceType = null,Object? reason = null,}) {
  return _then(FavoriteBatchConflict(
action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as FavoriteBatchActionType,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,sourceType: null == sourceType ? _self.sourceType : sourceType // ignore: cast_nullable_to_non_nullable
as FavoriteSourceType,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as FavoriteBatchConflictReason,
  ));
}

}


/// Adds pattern-matching-related methods to [FavoriteBatchConflict].
extension FavoriteBatchConflictPatterns on FavoriteBatchConflict {
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
