// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'leading_avatar_style_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LeadingAvatarStyleConfig {


/// Create a copy of LeadingAvatarStyleConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LeadingAvatarStyleConfigCopyWith<LeadingAvatarStyleConfig> get copyWith => _$LeadingAvatarStyleConfigCopyWithImpl<LeadingAvatarStyleConfig>(this as LeadingAvatarStyleConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LeadingAvatarStyleConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LeadingAvatarStyleConfig&&(identical(other.backgroundColor, _this.backgroundColor) || other.backgroundColor == _this.backgroundColor)&&(identical(other.radius, _this.radius) || other.radius == _this.radius)&&(identical(other.initialsTextStyle, _this.initialsTextStyle) || other.initialsTextStyle == _this.initialsTextStyle)&&(identical(other.placeholderIcon, _this.placeholderIcon) || other.placeholderIcon == _this.placeholderIcon)&&(identical(other.loading, _this.loading) || other.loading == _this.loading)&&(identical(other.smartIndicator, _this.smartIndicator) || other.smartIndicator == _this.smartIndicator)&&(identical(other.registeredBadge, _this.registeredBadge) || other.registeredBadge == _this.registeredBadge)&&(identical(other.presenceBadge, _this.presenceBadge) || other.presenceBadge == _this.presenceBadge)&&(identical(other.nameColors, _this.nameColors) || other.nameColors == _this.nameColors));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LeadingAvatarStyleConfig;
  return Object.hash(runtimeType,_this.backgroundColor,_this.radius,_this.initialsTextStyle,_this.placeholderIcon,_this.loading,_this.smartIndicator,_this.registeredBadge,_this.presenceBadge,_this.nameColors);
}

@override
String toString() {
  final _this = this as LeadingAvatarStyleConfig;
  return 'LeadingAvatarStyleConfig(backgroundColor: ${_this.backgroundColor}, radius: ${_this.radius}, initialsTextStyle: ${_this.initialsTextStyle}, placeholderIcon: ${_this.placeholderIcon}, loading: ${_this.loading}, smartIndicator: ${_this.smartIndicator}, registeredBadge: ${_this.registeredBadge}, presenceBadge: ${_this.presenceBadge}, nameColors: ${_this.nameColors})';
}


}

/// @nodoc
abstract mixin class $LeadingAvatarStyleConfigCopyWith<$Res>  {
  factory $LeadingAvatarStyleConfigCopyWith(LeadingAvatarStyleConfig value, $Res Function(LeadingAvatarStyleConfig) _then) = _$LeadingAvatarStyleConfigCopyWithImpl;
@useResult
$Res call({
 String? backgroundColor, double? radius, TextStyleConfig? initialsTextStyle, IconDataConfig? placeholderIcon, LoadingOverlayStyleConfig? loading, SmartIndicatorStyleConfig? smartIndicator, RegisteredBadgeStyleConfig? registeredBadge, PresenceBadgeStyleConfig? presenceBadge, NameColorsStyleConfig? nameColors
});




}
/// @nodoc
class _$LeadingAvatarStyleConfigCopyWithImpl<$Res>
    implements $LeadingAvatarStyleConfigCopyWith<$Res> {
  _$LeadingAvatarStyleConfigCopyWithImpl(this._self, this._then);

  final LeadingAvatarStyleConfig _self;
  final $Res Function(LeadingAvatarStyleConfig) _then;

/// Create a copy of LeadingAvatarStyleConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? backgroundColor = freezed,Object? radius = freezed,Object? initialsTextStyle = freezed,Object? placeholderIcon = freezed,Object? loading = freezed,Object? smartIndicator = freezed,Object? registeredBadge = freezed,Object? presenceBadge = freezed,Object? nameColors = freezed,}) {
  return _then(LeadingAvatarStyleConfig(
backgroundColor: freezed == backgroundColor ? _self.backgroundColor : backgroundColor // ignore: cast_nullable_to_non_nullable
as String?,radius: freezed == radius ? _self.radius : radius // ignore: cast_nullable_to_non_nullable
as double?,initialsTextStyle: freezed == initialsTextStyle ? _self.initialsTextStyle : initialsTextStyle // ignore: cast_nullable_to_non_nullable
as TextStyleConfig?,placeholderIcon: freezed == placeholderIcon ? _self.placeholderIcon : placeholderIcon // ignore: cast_nullable_to_non_nullable
as IconDataConfig?,loading: freezed == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as LoadingOverlayStyleConfig?,smartIndicator: freezed == smartIndicator ? _self.smartIndicator : smartIndicator // ignore: cast_nullable_to_non_nullable
as SmartIndicatorStyleConfig?,registeredBadge: freezed == registeredBadge ? _self.registeredBadge : registeredBadge // ignore: cast_nullable_to_non_nullable
as RegisteredBadgeStyleConfig?,presenceBadge: freezed == presenceBadge ? _self.presenceBadge : presenceBadge // ignore: cast_nullable_to_non_nullable
as PresenceBadgeStyleConfig?,nameColors: freezed == nameColors ? _self.nameColors : nameColors // ignore: cast_nullable_to_non_nullable
as NameColorsStyleConfig?,
  ));
}

}


/// Adds pattern-matching-related methods to [LeadingAvatarStyleConfig].
extension LeadingAvatarStyleConfigPatterns on LeadingAvatarStyleConfig {
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
mixin _$NameColorsStyleConfig {


/// Create a copy of NameColorsStyleConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NameColorsStyleConfigCopyWith<NameColorsStyleConfig> get copyWith => _$NameColorsStyleConfigCopyWithImpl<NameColorsStyleConfig>(this as NameColorsStyleConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as NameColorsStyleConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NameColorsStyleConfig&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled)&&const DeepCollectionEquality().equals(other.palette, _this.palette));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as NameColorsStyleConfig;
  return Object.hash(runtimeType,_this.enabled,const DeepCollectionEquality().hash(_this.palette));
}

@override
String toString() {
  final _this = this as NameColorsStyleConfig;
  return 'NameColorsStyleConfig(enabled: ${_this.enabled}, palette: ${_this.palette})';
}


}

/// @nodoc
abstract mixin class $NameColorsStyleConfigCopyWith<$Res>  {
  factory $NameColorsStyleConfigCopyWith(NameColorsStyleConfig value, $Res Function(NameColorsStyleConfig) _then) = _$NameColorsStyleConfigCopyWithImpl;
@useResult
$Res call({
 bool enabled, List<String>? palette
});




}
/// @nodoc
class _$NameColorsStyleConfigCopyWithImpl<$Res>
    implements $NameColorsStyleConfigCopyWith<$Res> {
  _$NameColorsStyleConfigCopyWithImpl(this._self, this._then);

  final NameColorsStyleConfig _self;
  final $Res Function(NameColorsStyleConfig) _then;

/// Create a copy of NameColorsStyleConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,Object? palette = freezed,}) {
  return _then(NameColorsStyleConfig(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,palette: freezed == palette ? _self.palette : palette // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}

}


/// Adds pattern-matching-related methods to [NameColorsStyleConfig].
extension NameColorsStyleConfigPatterns on NameColorsStyleConfig {
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
mixin _$LoadingOverlayStyleConfig {


/// Create a copy of LoadingOverlayStyleConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoadingOverlayStyleConfigCopyWith<LoadingOverlayStyleConfig> get copyWith => _$LoadingOverlayStyleConfigCopyWithImpl<LoadingOverlayStyleConfig>(this as LoadingOverlayStyleConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LoadingOverlayStyleConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoadingOverlayStyleConfig&&(identical(other.showByDefault, _this.showByDefault) || other.showByDefault == _this.showByDefault)&&(identical(other.padding, _this.padding) || other.padding == _this.padding)&&(identical(other.strokeWidth, _this.strokeWidth) || other.strokeWidth == _this.strokeWidth));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LoadingOverlayStyleConfig;
  return Object.hash(runtimeType,_this.showByDefault,_this.padding,_this.strokeWidth);
}

@override
String toString() {
  final _this = this as LoadingOverlayStyleConfig;
  return 'LoadingOverlayStyleConfig(showByDefault: ${_this.showByDefault}, padding: ${_this.padding}, strokeWidth: ${_this.strokeWidth})';
}


}

/// @nodoc
abstract mixin class $LoadingOverlayStyleConfigCopyWith<$Res>  {
  factory $LoadingOverlayStyleConfigCopyWith(LoadingOverlayStyleConfig value, $Res Function(LoadingOverlayStyleConfig) _then) = _$LoadingOverlayStyleConfigCopyWithImpl;
@useResult
$Res call({
 bool showByDefault, PaddingConfig padding, double? strokeWidth
});




}
/// @nodoc
class _$LoadingOverlayStyleConfigCopyWithImpl<$Res>
    implements $LoadingOverlayStyleConfigCopyWith<$Res> {
  _$LoadingOverlayStyleConfigCopyWithImpl(this._self, this._then);

  final LoadingOverlayStyleConfig _self;
  final $Res Function(LoadingOverlayStyleConfig) _then;

/// Create a copy of LoadingOverlayStyleConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? showByDefault = null,Object? padding = null,Object? strokeWidth = freezed,}) {
  return _then(LoadingOverlayStyleConfig(
showByDefault: null == showByDefault ? _self.showByDefault : showByDefault // ignore: cast_nullable_to_non_nullable
as bool,padding: null == padding ? _self.padding : padding // ignore: cast_nullable_to_non_nullable
as PaddingConfig,strokeWidth: freezed == strokeWidth ? _self.strokeWidth : strokeWidth // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [LoadingOverlayStyleConfig].
extension LoadingOverlayStyleConfigPatterns on LoadingOverlayStyleConfig {
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
mixin _$SmartIndicatorStyleConfig {


/// Create a copy of SmartIndicatorStyleConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SmartIndicatorStyleConfigCopyWith<SmartIndicatorStyleConfig> get copyWith => _$SmartIndicatorStyleConfigCopyWithImpl<SmartIndicatorStyleConfig>(this as SmartIndicatorStyleConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SmartIndicatorStyleConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SmartIndicatorStyleConfig&&(identical(other.backgroundColor, _this.backgroundColor) || other.backgroundColor == _this.backgroundColor)&&(identical(other.icon, _this.icon) || other.icon == _this.icon)&&(identical(other.sizeFactor, _this.sizeFactor) || other.sizeFactor == _this.sizeFactor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SmartIndicatorStyleConfig;
  return Object.hash(runtimeType,_this.backgroundColor,_this.icon,_this.sizeFactor);
}

@override
String toString() {
  final _this = this as SmartIndicatorStyleConfig;
  return 'SmartIndicatorStyleConfig(backgroundColor: ${_this.backgroundColor}, icon: ${_this.icon}, sizeFactor: ${_this.sizeFactor})';
}


}

/// @nodoc
abstract mixin class $SmartIndicatorStyleConfigCopyWith<$Res>  {
  factory $SmartIndicatorStyleConfigCopyWith(SmartIndicatorStyleConfig value, $Res Function(SmartIndicatorStyleConfig) _then) = _$SmartIndicatorStyleConfigCopyWithImpl;
@useResult
$Res call({
 String? backgroundColor, IconDataConfig? icon, double? sizeFactor
});




}
/// @nodoc
class _$SmartIndicatorStyleConfigCopyWithImpl<$Res>
    implements $SmartIndicatorStyleConfigCopyWith<$Res> {
  _$SmartIndicatorStyleConfigCopyWithImpl(this._self, this._then);

  final SmartIndicatorStyleConfig _self;
  final $Res Function(SmartIndicatorStyleConfig) _then;

/// Create a copy of SmartIndicatorStyleConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? backgroundColor = freezed,Object? icon = freezed,Object? sizeFactor = freezed,}) {
  return _then(SmartIndicatorStyleConfig(
backgroundColor: freezed == backgroundColor ? _self.backgroundColor : backgroundColor // ignore: cast_nullable_to_non_nullable
as String?,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as IconDataConfig?,sizeFactor: freezed == sizeFactor ? _self.sizeFactor : sizeFactor // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [SmartIndicatorStyleConfig].
extension SmartIndicatorStyleConfigPatterns on SmartIndicatorStyleConfig {
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
mixin _$RegisteredBadgeStyleConfig {


/// Create a copy of RegisteredBadgeStyleConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RegisteredBadgeStyleConfigCopyWith<RegisteredBadgeStyleConfig> get copyWith => _$RegisteredBadgeStyleConfigCopyWithImpl<RegisteredBadgeStyleConfig>(this as RegisteredBadgeStyleConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RegisteredBadgeStyleConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegisteredBadgeStyleConfig&&(identical(other.registeredColor, _this.registeredColor) || other.registeredColor == _this.registeredColor)&&(identical(other.unregisteredColor, _this.unregisteredColor) || other.unregisteredColor == _this.unregisteredColor)&&(identical(other.sizeFactor, _this.sizeFactor) || other.sizeFactor == _this.sizeFactor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RegisteredBadgeStyleConfig;
  return Object.hash(runtimeType,_this.registeredColor,_this.unregisteredColor,_this.sizeFactor);
}

@override
String toString() {
  final _this = this as RegisteredBadgeStyleConfig;
  return 'RegisteredBadgeStyleConfig(registeredColor: ${_this.registeredColor}, unregisteredColor: ${_this.unregisteredColor}, sizeFactor: ${_this.sizeFactor})';
}


}

/// @nodoc
abstract mixin class $RegisteredBadgeStyleConfigCopyWith<$Res>  {
  factory $RegisteredBadgeStyleConfigCopyWith(RegisteredBadgeStyleConfig value, $Res Function(RegisteredBadgeStyleConfig) _then) = _$RegisteredBadgeStyleConfigCopyWithImpl;
@useResult
$Res call({
 String? registeredColor, String? unregisteredColor, double? sizeFactor
});




}
/// @nodoc
class _$RegisteredBadgeStyleConfigCopyWithImpl<$Res>
    implements $RegisteredBadgeStyleConfigCopyWith<$Res> {
  _$RegisteredBadgeStyleConfigCopyWithImpl(this._self, this._then);

  final RegisteredBadgeStyleConfig _self;
  final $Res Function(RegisteredBadgeStyleConfig) _then;

/// Create a copy of RegisteredBadgeStyleConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? registeredColor = freezed,Object? unregisteredColor = freezed,Object? sizeFactor = freezed,}) {
  return _then(RegisteredBadgeStyleConfig(
registeredColor: freezed == registeredColor ? _self.registeredColor : registeredColor // ignore: cast_nullable_to_non_nullable
as String?,unregisteredColor: freezed == unregisteredColor ? _self.unregisteredColor : unregisteredColor // ignore: cast_nullable_to_non_nullable
as String?,sizeFactor: freezed == sizeFactor ? _self.sizeFactor : sizeFactor // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [RegisteredBadgeStyleConfig].
extension RegisteredBadgeStyleConfigPatterns on RegisteredBadgeStyleConfig {
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
mixin _$PresenceBadgeStyleConfig {


/// Create a copy of PresenceBadgeStyleConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresenceBadgeStyleConfigCopyWith<PresenceBadgeStyleConfig> get copyWith => _$PresenceBadgeStyleConfigCopyWithImpl<PresenceBadgeStyleConfig>(this as PresenceBadgeStyleConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PresenceBadgeStyleConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresenceBadgeStyleConfig&&(identical(other.availableColor, _this.availableColor) || other.availableColor == _this.availableColor)&&(identical(other.unavailableColor, _this.unavailableColor) || other.unavailableColor == _this.unavailableColor)&&(identical(other.busyColor, _this.busyColor) || other.busyColor == _this.busyColor)&&(identical(other.iconColor, _this.iconColor) || other.iconColor == _this.iconColor)&&(identical(other.sizeFactor, _this.sizeFactor) || other.sizeFactor == _this.sizeFactor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PresenceBadgeStyleConfig;
  return Object.hash(runtimeType,_this.availableColor,_this.unavailableColor,_this.busyColor,_this.iconColor,_this.sizeFactor);
}

@override
String toString() {
  final _this = this as PresenceBadgeStyleConfig;
  return 'PresenceBadgeStyleConfig(availableColor: ${_this.availableColor}, unavailableColor: ${_this.unavailableColor}, busyColor: ${_this.busyColor}, iconColor: ${_this.iconColor}, sizeFactor: ${_this.sizeFactor})';
}


}

/// @nodoc
abstract mixin class $PresenceBadgeStyleConfigCopyWith<$Res>  {
  factory $PresenceBadgeStyleConfigCopyWith(PresenceBadgeStyleConfig value, $Res Function(PresenceBadgeStyleConfig) _then) = _$PresenceBadgeStyleConfigCopyWithImpl;
@useResult
$Res call({
 String? availableColor, String? unavailableColor, String? busyColor, String? iconColor, double? sizeFactor
});




}
/// @nodoc
class _$PresenceBadgeStyleConfigCopyWithImpl<$Res>
    implements $PresenceBadgeStyleConfigCopyWith<$Res> {
  _$PresenceBadgeStyleConfigCopyWithImpl(this._self, this._then);

  final PresenceBadgeStyleConfig _self;
  final $Res Function(PresenceBadgeStyleConfig) _then;

/// Create a copy of PresenceBadgeStyleConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? availableColor = freezed,Object? unavailableColor = freezed,Object? busyColor = freezed,Object? iconColor = freezed,Object? sizeFactor = freezed,}) {
  return _then(PresenceBadgeStyleConfig(
availableColor: freezed == availableColor ? _self.availableColor : availableColor // ignore: cast_nullable_to_non_nullable
as String?,unavailableColor: freezed == unavailableColor ? _self.unavailableColor : unavailableColor // ignore: cast_nullable_to_non_nullable
as String?,busyColor: freezed == busyColor ? _self.busyColor : busyColor // ignore: cast_nullable_to_non_nullable
as String?,iconColor: freezed == iconColor ? _self.iconColor : iconColor // ignore: cast_nullable_to_non_nullable
as String?,sizeFactor: freezed == sizeFactor ? _self.sizeFactor : sizeFactor // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [PresenceBadgeStyleConfig].
extension PresenceBadgeStyleConfigPatterns on PresenceBadgeStyleConfig {
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
