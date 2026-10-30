// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'text_field_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TextFieldConfig {


/// Create a copy of TextFieldConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TextFieldConfigCopyWith<TextFieldConfig> get copyWith => _$TextFieldConfigCopyWithImpl<TextFieldConfig>(this as TextFieldConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TextFieldConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TextFieldConfig&&(identical(other.decoration, _this.decoration) || other.decoration == _this.decoration)&&(identical(other.style, _this.style) || other.style == _this.style)&&(identical(other.textAlign, _this.textAlign) || other.textAlign == _this.textAlign)&&(identical(other.showCursor, _this.showCursor) || other.showCursor == _this.showCursor)&&(identical(other.keyboardType, _this.keyboardType) || other.keyboardType == _this.keyboardType)&&(identical(other.mask, _this.mask) || other.mask == _this.mask)&&(identical(other.inputValue, _this.inputValue) || other.inputValue == _this.inputValue));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TextFieldConfig;
  return Object.hash(runtimeType,_this.decoration,_this.style,_this.textAlign,_this.showCursor,_this.keyboardType,_this.mask,_this.inputValue);
}

@override
String toString() {
  final _this = this as TextFieldConfig;
  return 'TextFieldConfig(decoration: ${_this.decoration}, style: ${_this.style}, textAlign: ${_this.textAlign}, showCursor: ${_this.showCursor}, keyboardType: ${_this.keyboardType}, mask: ${_this.mask}, inputValue: ${_this.inputValue})';
}


}

/// @nodoc
abstract mixin class $TextFieldConfigCopyWith<$Res>  {
  factory $TextFieldConfigCopyWith(TextFieldConfig value, $Res Function(TextFieldConfig) _then) = _$TextFieldConfigCopyWithImpl;
@useResult
$Res call({
 InputDecorationConfig? decoration, TextStyleConfig? style, String textAlign, bool showCursor, String keyboardType, MaskConfig? mask, InputValueConfig? inputValue
});




}
/// @nodoc
class _$TextFieldConfigCopyWithImpl<$Res>
    implements $TextFieldConfigCopyWith<$Res> {
  _$TextFieldConfigCopyWithImpl(this._self, this._then);

  final TextFieldConfig _self;
  final $Res Function(TextFieldConfig) _then;

/// Create a copy of TextFieldConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? decoration = freezed,Object? style = freezed,Object? textAlign = null,Object? showCursor = null,Object? keyboardType = null,Object? mask = freezed,Object? inputValue = freezed,}) {
  return _then(TextFieldConfig(
decoration: freezed == decoration ? _self.decoration : decoration // ignore: cast_nullable_to_non_nullable
as InputDecorationConfig?,style: freezed == style ? _self.style : style // ignore: cast_nullable_to_non_nullable
as TextStyleConfig?,textAlign: null == textAlign ? _self.textAlign : textAlign // ignore: cast_nullable_to_non_nullable
as String,showCursor: null == showCursor ? _self.showCursor : showCursor // ignore: cast_nullable_to_non_nullable
as bool,keyboardType: null == keyboardType ? _self.keyboardType : keyboardType // ignore: cast_nullable_to_non_nullable
as String,mask: freezed == mask ? _self.mask : mask // ignore: cast_nullable_to_non_nullable
as MaskConfig?,inputValue: freezed == inputValue ? _self.inputValue : inputValue // ignore: cast_nullable_to_non_nullable
as InputValueConfig?,
  ));
}

}


/// Adds pattern-matching-related methods to [TextFieldConfig].
extension TextFieldConfigPatterns on TextFieldConfig {
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
mixin _$InputValueConfig {


/// Create a copy of InputValueConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InputValueConfigCopyWith<InputValueConfig> get copyWith => _$InputValueConfigCopyWithImpl<InputValueConfig>(this as InputValueConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as InputValueConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InputValueConfig&&(identical(other.includePrefixInData, _this.includePrefixInData) || other.includePrefixInData == _this.includePrefixInData)&&(identical(other.initialValue, _this.initialValue) || other.initialValue == _this.initialValue));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as InputValueConfig;
  return Object.hash(runtimeType,_this.includePrefixInData,_this.initialValue);
}

@override
String toString() {
  final _this = this as InputValueConfig;
  return 'InputValueConfig(includePrefixInData: ${_this.includePrefixInData}, initialValue: ${_this.initialValue})';
}


}

/// @nodoc
abstract mixin class $InputValueConfigCopyWith<$Res>  {
  factory $InputValueConfigCopyWith(InputValueConfig value, $Res Function(InputValueConfig) _then) = _$InputValueConfigCopyWithImpl;
@useResult
$Res call({
 bool? includePrefixInData, String? initialValue
});




}
/// @nodoc
class _$InputValueConfigCopyWithImpl<$Res>
    implements $InputValueConfigCopyWith<$Res> {
  _$InputValueConfigCopyWithImpl(this._self, this._then);

  final InputValueConfig _self;
  final $Res Function(InputValueConfig) _then;

/// Create a copy of InputValueConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? includePrefixInData = freezed,Object? initialValue = freezed,}) {
  return _then(InputValueConfig(
includePrefixInData: freezed == includePrefixInData ? _self.includePrefixInData : includePrefixInData // ignore: cast_nullable_to_non_nullable
as bool?,initialValue: freezed == initialValue ? _self.initialValue : initialValue // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [InputValueConfig].
extension InputValueConfigPatterns on InputValueConfig {
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
