// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'geometry_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SizeConfig {


/// Create a copy of SizeConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SizeConfigCopyWith<SizeConfig> get copyWith => _$SizeConfigCopyWithImpl<SizeConfig>(this as SizeConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SizeConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SizeConfig&&(identical(other.width, _this.width) || other.width == _this.width)&&(identical(other.height, _this.height) || other.height == _this.height));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SizeConfig;
  return Object.hash(runtimeType,_this.width,_this.height);
}

@override
String toString() {
  final _this = this as SizeConfig;
  return 'SizeConfig(width: ${_this.width}, height: ${_this.height})';
}


}

/// @nodoc
abstract mixin class $SizeConfigCopyWith<$Res>  {
  factory $SizeConfigCopyWith(SizeConfig value, $Res Function(SizeConfig) _then) = _$SizeConfigCopyWithImpl;
@useResult
$Res call({
 double width, double height
});




}
/// @nodoc
class _$SizeConfigCopyWithImpl<$Res>
    implements $SizeConfigCopyWith<$Res> {
  _$SizeConfigCopyWithImpl(this._self, this._then);

  final SizeConfig _self;
  final $Res Function(SizeConfig) _then;

/// Create a copy of SizeConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? width = null,Object? height = null,}) {
  return _then(SizeConfig(
width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as double,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [SizeConfig].
extension SizeConfigPatterns on SizeConfig {
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
mixin _$EdgeInsetsConfig {


/// Create a copy of EdgeInsetsConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EdgeInsetsConfigCopyWith<EdgeInsetsConfig> get copyWith => _$EdgeInsetsConfigCopyWithImpl<EdgeInsetsConfig>(this as EdgeInsetsConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as EdgeInsetsConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EdgeInsetsConfig&&(identical(other.left, _this.left) || other.left == _this.left)&&(identical(other.top, _this.top) || other.top == _this.top)&&(identical(other.right, _this.right) || other.right == _this.right)&&(identical(other.bottom, _this.bottom) || other.bottom == _this.bottom));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as EdgeInsetsConfig;
  return Object.hash(runtimeType,_this.left,_this.top,_this.right,_this.bottom);
}

@override
String toString() {
  final _this = this as EdgeInsetsConfig;
  return 'EdgeInsetsConfig(left: ${_this.left}, top: ${_this.top}, right: ${_this.right}, bottom: ${_this.bottom})';
}


}

/// @nodoc
abstract mixin class $EdgeInsetsConfigCopyWith<$Res>  {
  factory $EdgeInsetsConfigCopyWith(EdgeInsetsConfig value, $Res Function(EdgeInsetsConfig) _then) = _$EdgeInsetsConfigCopyWithImpl;
@useResult
$Res call({
 double left, double top, double right, double bottom
});




}
/// @nodoc
class _$EdgeInsetsConfigCopyWithImpl<$Res>
    implements $EdgeInsetsConfigCopyWith<$Res> {
  _$EdgeInsetsConfigCopyWithImpl(this._self, this._then);

  final EdgeInsetsConfig _self;
  final $Res Function(EdgeInsetsConfig) _then;

/// Create a copy of EdgeInsetsConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? left = null,Object? top = null,Object? right = null,Object? bottom = null,}) {
  return _then(EdgeInsetsConfig(
left: null == left ? _self.left : left // ignore: cast_nullable_to_non_nullable
as double,top: null == top ? _self.top : top // ignore: cast_nullable_to_non_nullable
as double,right: null == right ? _self.right : right // ignore: cast_nullable_to_non_nullable
as double,bottom: null == bottom ? _self.bottom : bottom // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [EdgeInsetsConfig].
extension EdgeInsetsConfigPatterns on EdgeInsetsConfig {
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
mixin _$BorderSideConfig {


/// Create a copy of BorderSideConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BorderSideConfigCopyWith<BorderSideConfig> get copyWith => _$BorderSideConfigCopyWithImpl<BorderSideConfig>(this as BorderSideConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as BorderSideConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BorderSideConfig&&(identical(other.color, _this.color) || other.color == _this.color)&&(identical(other.width, _this.width) || other.width == _this.width)&&(identical(other.style, _this.style) || other.style == _this.style));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BorderSideConfig;
  return Object.hash(runtimeType,_this.color,_this.width,_this.style);
}

@override
String toString() {
  final _this = this as BorderSideConfig;
  return 'BorderSideConfig(color: ${_this.color}, width: ${_this.width}, style: ${_this.style})';
}


}

/// @nodoc
abstract mixin class $BorderSideConfigCopyWith<$Res>  {
  factory $BorderSideConfigCopyWith(BorderSideConfig value, $Res Function(BorderSideConfig) _then) = _$BorderSideConfigCopyWithImpl;
@useResult
$Res call({
 String? color, double width, String style
});




}
/// @nodoc
class _$BorderSideConfigCopyWithImpl<$Res>
    implements $BorderSideConfigCopyWith<$Res> {
  _$BorderSideConfigCopyWithImpl(this._self, this._then);

  final BorderSideConfig _self;
  final $Res Function(BorderSideConfig) _then;

/// Create a copy of BorderSideConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? color = freezed,Object? width = null,Object? style = null,}) {
  return _then(BorderSideConfig(
color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as double,style: null == style ? _self.style : style // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BorderSideConfig].
extension BorderSideConfigPatterns on BorderSideConfig {
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
mixin _$ShapeBorderConfig {


/// Create a copy of ShapeBorderConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShapeBorderConfigCopyWith<ShapeBorderConfig> get copyWith => _$ShapeBorderConfigCopyWithImpl<ShapeBorderConfig>(this as ShapeBorderConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ShapeBorderConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShapeBorderConfig&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.borderRadius, _this.borderRadius) || other.borderRadius == _this.borderRadius));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ShapeBorderConfig;
  return Object.hash(runtimeType,_this.type,_this.borderRadius);
}

@override
String toString() {
  final _this = this as ShapeBorderConfig;
  return 'ShapeBorderConfig(type: ${_this.type}, borderRadius: ${_this.borderRadius})';
}


}

/// @nodoc
abstract mixin class $ShapeBorderConfigCopyWith<$Res>  {
  factory $ShapeBorderConfigCopyWith(ShapeBorderConfig value, $Res Function(ShapeBorderConfig) _then) = _$ShapeBorderConfigCopyWithImpl;
@useResult
$Res call({
 String type, double? borderRadius
});




}
/// @nodoc
class _$ShapeBorderConfigCopyWithImpl<$Res>
    implements $ShapeBorderConfigCopyWith<$Res> {
  _$ShapeBorderConfigCopyWithImpl(this._self, this._then);

  final ShapeBorderConfig _self;
  final $Res Function(ShapeBorderConfig) _then;

/// Create a copy of ShapeBorderConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? borderRadius = freezed,}) {
  return _then(ShapeBorderConfig(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,borderRadius: freezed == borderRadius ? _self.borderRadius : borderRadius // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [ShapeBorderConfig].
extension ShapeBorderConfigPatterns on ShapeBorderConfig {
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
mixin _$VisualDensityConfig {


/// Create a copy of VisualDensityConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VisualDensityConfigCopyWith<VisualDensityConfig> get copyWith => _$VisualDensityConfigCopyWithImpl<VisualDensityConfig>(this as VisualDensityConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as VisualDensityConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VisualDensityConfig&&(identical(other.horizontal, _this.horizontal) || other.horizontal == _this.horizontal)&&(identical(other.vertical, _this.vertical) || other.vertical == _this.vertical));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as VisualDensityConfig;
  return Object.hash(runtimeType,_this.horizontal,_this.vertical);
}

@override
String toString() {
  final _this = this as VisualDensityConfig;
  return 'VisualDensityConfig(horizontal: ${_this.horizontal}, vertical: ${_this.vertical})';
}


}

/// @nodoc
abstract mixin class $VisualDensityConfigCopyWith<$Res>  {
  factory $VisualDensityConfigCopyWith(VisualDensityConfig value, $Res Function(VisualDensityConfig) _then) = _$VisualDensityConfigCopyWithImpl;
@useResult
$Res call({
 double horizontal, double vertical
});




}
/// @nodoc
class _$VisualDensityConfigCopyWithImpl<$Res>
    implements $VisualDensityConfigCopyWith<$Res> {
  _$VisualDensityConfigCopyWithImpl(this._self, this._then);

  final VisualDensityConfig _self;
  final $Res Function(VisualDensityConfig) _then;

/// Create a copy of VisualDensityConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? horizontal = null,Object? vertical = null,}) {
  return _then(VisualDensityConfig(
horizontal: null == horizontal ? _self.horizontal : horizontal // ignore: cast_nullable_to_non_nullable
as double,vertical: null == vertical ? _self.vertical : vertical // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [VisualDensityConfig].
extension VisualDensityConfigPatterns on VisualDensityConfig {
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
