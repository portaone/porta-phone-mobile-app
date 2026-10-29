// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'text_style_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TextStyleConfig {


/// Create a copy of TextStyleConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TextStyleConfigCopyWith<TextStyleConfig> get copyWith => _$TextStyleConfigCopyWithImpl<TextStyleConfig>(this as TextStyleConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TextStyleConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TextStyleConfig&&(identical(other.fontFamily, _this.fontFamily) || other.fontFamily == _this.fontFamily)&&(identical(other.fontSize, _this.fontSize) || other.fontSize == _this.fontSize)&&(identical(other.fontWeight, _this.fontWeight) || other.fontWeight == _this.fontWeight)&&(identical(other.fontStyle, _this.fontStyle) || other.fontStyle == _this.fontStyle)&&(identical(other.color, _this.color) || other.color == _this.color)&&(identical(other.letterSpacing, _this.letterSpacing) || other.letterSpacing == _this.letterSpacing)&&(identical(other.wordSpacing, _this.wordSpacing) || other.wordSpacing == _this.wordSpacing)&&(identical(other.height, _this.height) || other.height == _this.height)&&(identical(other.decoration, _this.decoration) || other.decoration == _this.decoration)&&(identical(other.backgroundColor, _this.backgroundColor) || other.backgroundColor == _this.backgroundColor)&&(identical(other.backgroundBorderRadius, _this.backgroundBorderRadius) || other.backgroundBorderRadius == _this.backgroundBorderRadius)&&(identical(other.backgroundPadding, _this.backgroundPadding) || other.backgroundPadding == _this.backgroundPadding));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TextStyleConfig;
  return Object.hash(runtimeType,_this.fontFamily,_this.fontSize,_this.fontWeight,_this.fontStyle,_this.color,_this.letterSpacing,_this.wordSpacing,_this.height,_this.decoration,_this.backgroundColor,_this.backgroundBorderRadius,_this.backgroundPadding);
}

@override
String toString() {
  final _this = this as TextStyleConfig;
  return 'TextStyleConfig(fontFamily: ${_this.fontFamily}, fontSize: ${_this.fontSize}, fontWeight: ${_this.fontWeight}, fontStyle: ${_this.fontStyle}, color: ${_this.color}, letterSpacing: ${_this.letterSpacing}, wordSpacing: ${_this.wordSpacing}, height: ${_this.height}, decoration: ${_this.decoration}, backgroundColor: ${_this.backgroundColor}, backgroundBorderRadius: ${_this.backgroundBorderRadius}, backgroundPadding: ${_this.backgroundPadding})';
}


}

/// @nodoc
abstract mixin class $TextStyleConfigCopyWith<$Res>  {
  factory $TextStyleConfigCopyWith(TextStyleConfig value, $Res Function(TextStyleConfig) _then) = _$TextStyleConfigCopyWithImpl;
@useResult
$Res call({
 String? fontFamily, double? fontSize, FontWeightConfig? fontWeight, FontStyleConfig? fontStyle, String? color, double? letterSpacing, double? wordSpacing, double? height, TextDecorationConfig? decoration, String? backgroundColor, double? backgroundBorderRadius, PaddingConfig? backgroundPadding
});




}
/// @nodoc
class _$TextStyleConfigCopyWithImpl<$Res>
    implements $TextStyleConfigCopyWith<$Res> {
  _$TextStyleConfigCopyWithImpl(this._self, this._then);

  final TextStyleConfig _self;
  final $Res Function(TextStyleConfig) _then;

/// Create a copy of TextStyleConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fontFamily = freezed,Object? fontSize = freezed,Object? fontWeight = freezed,Object? fontStyle = freezed,Object? color = freezed,Object? letterSpacing = freezed,Object? wordSpacing = freezed,Object? height = freezed,Object? decoration = freezed,Object? backgroundColor = freezed,Object? backgroundBorderRadius = freezed,Object? backgroundPadding = freezed,}) {
  return _then(TextStyleConfig(
fontFamily: freezed == fontFamily ? _self.fontFamily : fontFamily // ignore: cast_nullable_to_non_nullable
as String?,fontSize: freezed == fontSize ? _self.fontSize : fontSize // ignore: cast_nullable_to_non_nullable
as double?,fontWeight: freezed == fontWeight ? _self.fontWeight : fontWeight // ignore: cast_nullable_to_non_nullable
as FontWeightConfig?,fontStyle: freezed == fontStyle ? _self.fontStyle : fontStyle // ignore: cast_nullable_to_non_nullable
as FontStyleConfig?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,letterSpacing: freezed == letterSpacing ? _self.letterSpacing : letterSpacing // ignore: cast_nullable_to_non_nullable
as double?,wordSpacing: freezed == wordSpacing ? _self.wordSpacing : wordSpacing // ignore: cast_nullable_to_non_nullable
as double?,height: freezed == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as double?,decoration: freezed == decoration ? _self.decoration : decoration // ignore: cast_nullable_to_non_nullable
as TextDecorationConfig?,backgroundColor: freezed == backgroundColor ? _self.backgroundColor : backgroundColor // ignore: cast_nullable_to_non_nullable
as String?,backgroundBorderRadius: freezed == backgroundBorderRadius ? _self.backgroundBorderRadius : backgroundBorderRadius // ignore: cast_nullable_to_non_nullable
as double?,backgroundPadding: freezed == backgroundPadding ? _self.backgroundPadding : backgroundPadding // ignore: cast_nullable_to_non_nullable
as PaddingConfig?,
  ));
}

}


/// Adds pattern-matching-related methods to [TextStyleConfig].
extension TextStyleConfigPatterns on TextStyleConfig {
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
mixin _$FontWeightConfig {


/// Create a copy of FontWeightConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FontWeightConfigCopyWith<FontWeightConfig> get copyWith => _$FontWeightConfigCopyWithImpl<FontWeightConfig>(this as FontWeightConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FontWeightConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FontWeightConfig&&(identical(other.weight, _this.weight) || other.weight == _this.weight));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as FontWeightConfig;
  return Object.hash(runtimeType,_this.weight);
}

@override
String toString() {
  final _this = this as FontWeightConfig;
  return 'FontWeightConfig(weight: ${_this.weight})';
}


}

/// @nodoc
abstract mixin class $FontWeightConfigCopyWith<$Res>  {
  factory $FontWeightConfigCopyWith(FontWeightConfig value, $Res Function(FontWeightConfig) _then) = _$FontWeightConfigCopyWithImpl;
@useResult
$Res call({
 int weight
});




}
/// @nodoc
class _$FontWeightConfigCopyWithImpl<$Res>
    implements $FontWeightConfigCopyWith<$Res> {
  _$FontWeightConfigCopyWithImpl(this._self, this._then);

  final FontWeightConfig _self;
  final $Res Function(FontWeightConfig) _then;

/// Create a copy of FontWeightConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? weight = null,}) {
  return _then(FontWeightConfig(
weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [FontWeightConfig].
extension FontWeightConfigPatterns on FontWeightConfig {
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
mixin _$FontStyleConfig {


/// Create a copy of FontStyleConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FontStyleConfigCopyWith<FontStyleConfig> get copyWith => _$FontStyleConfigCopyWithImpl<FontStyleConfig>(this as FontStyleConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FontStyleConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FontStyleConfig&&(identical(other.value, _this.value) || other.value == _this.value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as FontStyleConfig;
  return Object.hash(runtimeType,_this.value);
}

@override
String toString() {
  final _this = this as FontStyleConfig;
  return 'FontStyleConfig(value: ${_this.value})';
}


}

/// @nodoc
abstract mixin class $FontStyleConfigCopyWith<$Res>  {
  factory $FontStyleConfigCopyWith(FontStyleConfig value, $Res Function(FontStyleConfig) _then) = _$FontStyleConfigCopyWithImpl;
@useResult
$Res call({
 String value
});




}
/// @nodoc
class _$FontStyleConfigCopyWithImpl<$Res>
    implements $FontStyleConfigCopyWith<$Res> {
  _$FontStyleConfigCopyWithImpl(this._self, this._then);

  final FontStyleConfig _self;
  final $Res Function(FontStyleConfig) _then;

/// Create a copy of FontStyleConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? value = null,}) {
  return _then(FontStyleConfig(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [FontStyleConfig].
extension FontStyleConfigPatterns on FontStyleConfig {
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
mixin _$TextDecorationConfig {


/// Create a copy of TextDecorationConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TextDecorationConfigCopyWith<TextDecorationConfig> get copyWith => _$TextDecorationConfigCopyWithImpl<TextDecorationConfig>(this as TextDecorationConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TextDecorationConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TextDecorationConfig&&const DeepCollectionEquality().equals(other.types, _this.types)&&(identical(other.hint, _this.hint) || other.hint == _this.hint)&&(identical(other.hintStyle, _this.hintStyle) || other.hintStyle == _this.hintStyle)&&(identical(other.prefixText, _this.prefixText) || other.prefixText == _this.prefixText)&&(identical(other.prefixStyle, _this.prefixStyle) || other.prefixStyle == _this.prefixStyle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TextDecorationConfig;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.types),_this.hint,_this.hintStyle,_this.prefixText,_this.prefixStyle);
}

@override
String toString() {
  final _this = this as TextDecorationConfig;
  return 'TextDecorationConfig(types: ${_this.types}, hint: ${_this.hint}, hintStyle: ${_this.hintStyle}, prefixText: ${_this.prefixText}, prefixStyle: ${_this.prefixStyle})';
}


}

/// @nodoc
abstract mixin class $TextDecorationConfigCopyWith<$Res>  {
  factory $TextDecorationConfigCopyWith(TextDecorationConfig value, $Res Function(TextDecorationConfig) _then) = _$TextDecorationConfigCopyWithImpl;
@useResult
$Res call({
 List<String> types, String? hint, TextStyleConfig? hintStyle, String? prefixText, TextStyleConfig? prefixStyle
});




}
/// @nodoc
class _$TextDecorationConfigCopyWithImpl<$Res>
    implements $TextDecorationConfigCopyWith<$Res> {
  _$TextDecorationConfigCopyWithImpl(this._self, this._then);

  final TextDecorationConfig _self;
  final $Res Function(TextDecorationConfig) _then;

/// Create a copy of TextDecorationConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? types = null,Object? hint = freezed,Object? hintStyle = freezed,Object? prefixText = freezed,Object? prefixStyle = freezed,}) {
  return _then(TextDecorationConfig(
types: null == types ? _self.types : types // ignore: cast_nullable_to_non_nullable
as List<String>,hint: freezed == hint ? _self.hint : hint // ignore: cast_nullable_to_non_nullable
as String?,hintStyle: freezed == hintStyle ? _self.hintStyle : hintStyle // ignore: cast_nullable_to_non_nullable
as TextStyleConfig?,prefixText: freezed == prefixText ? _self.prefixText : prefixText // ignore: cast_nullable_to_non_nullable
as String?,prefixStyle: freezed == prefixStyle ? _self.prefixStyle : prefixStyle // ignore: cast_nullable_to_non_nullable
as TextStyleConfig?,
  ));
}

}


/// Adds pattern-matching-related methods to [TextDecorationConfig].
extension TextDecorationConfigPatterns on TextDecorationConfig {
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
