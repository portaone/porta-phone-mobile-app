// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'color_scheme.config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ColorSchemeConfig {


/// Create a copy of ColorSchemeConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ColorSchemeConfigCopyWith<ColorSchemeConfig> get copyWith => _$ColorSchemeConfigCopyWithImpl<ColorSchemeConfig>(this as ColorSchemeConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ColorSchemeConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ColorSchemeConfig&&(identical(other.seedColor, _this.seedColor) || other.seedColor == _this.seedColor)&&(identical(other.colorSchemeOverride, _this.colorSchemeOverride) || other.colorSchemeOverride == _this.colorSchemeOverride));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ColorSchemeConfig;
  return Object.hash(runtimeType,_this.seedColor,_this.colorSchemeOverride);
}

@override
String toString() {
  final _this = this as ColorSchemeConfig;
  return 'ColorSchemeConfig(seedColor: ${_this.seedColor}, colorSchemeOverride: ${_this.colorSchemeOverride})';
}


}

/// @nodoc
abstract mixin class $ColorSchemeConfigCopyWith<$Res>  {
  factory $ColorSchemeConfigCopyWith(ColorSchemeConfig value, $Res Function(ColorSchemeConfig) _then) = _$ColorSchemeConfigCopyWithImpl;
@useResult
$Res call({
 String seedColor, ColorSchemeOverride colorSchemeOverride
});




}
/// @nodoc
class _$ColorSchemeConfigCopyWithImpl<$Res>
    implements $ColorSchemeConfigCopyWith<$Res> {
  _$ColorSchemeConfigCopyWithImpl(this._self, this._then);

  final ColorSchemeConfig _self;
  final $Res Function(ColorSchemeConfig) _then;

/// Create a copy of ColorSchemeConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? seedColor = null,Object? colorSchemeOverride = null,}) {
  return _then(ColorSchemeConfig(
seedColor: null == seedColor ? _self.seedColor : seedColor // ignore: cast_nullable_to_non_nullable
as String,colorSchemeOverride: null == colorSchemeOverride ? _self.colorSchemeOverride : colorSchemeOverride // ignore: cast_nullable_to_non_nullable
as ColorSchemeOverride,
  ));
}

}


/// Adds pattern-matching-related methods to [ColorSchemeConfig].
extension ColorSchemeConfigPatterns on ColorSchemeConfig {
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
mixin _$ColorSchemeOverride {


/// Create a copy of ColorSchemeOverride
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ColorSchemeOverrideCopyWith<ColorSchemeOverride> get copyWith => _$ColorSchemeOverrideCopyWithImpl<ColorSchemeOverride>(this as ColorSchemeOverride, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ColorSchemeOverride;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ColorSchemeOverride&&(identical(other.primary, _this.primary) || other.primary == _this.primary)&&(identical(other.onPrimary, _this.onPrimary) || other.onPrimary == _this.onPrimary)&&(identical(other.primaryContainer, _this.primaryContainer) || other.primaryContainer == _this.primaryContainer)&&(identical(other.onPrimaryContainer, _this.onPrimaryContainer) || other.onPrimaryContainer == _this.onPrimaryContainer)&&(identical(other.primaryFixed, _this.primaryFixed) || other.primaryFixed == _this.primaryFixed)&&(identical(other.primaryFixedDim, _this.primaryFixedDim) || other.primaryFixedDim == _this.primaryFixedDim)&&(identical(other.onPrimaryFixed, _this.onPrimaryFixed) || other.onPrimaryFixed == _this.onPrimaryFixed)&&(identical(other.onPrimaryFixedVariant, _this.onPrimaryFixedVariant) || other.onPrimaryFixedVariant == _this.onPrimaryFixedVariant)&&(identical(other.secondary, _this.secondary) || other.secondary == _this.secondary)&&(identical(other.onSecondary, _this.onSecondary) || other.onSecondary == _this.onSecondary)&&(identical(other.secondaryContainer, _this.secondaryContainer) || other.secondaryContainer == _this.secondaryContainer)&&(identical(other.onSecondaryContainer, _this.onSecondaryContainer) || other.onSecondaryContainer == _this.onSecondaryContainer)&&(identical(other.secondaryFixed, _this.secondaryFixed) || other.secondaryFixed == _this.secondaryFixed)&&(identical(other.secondaryFixedDim, _this.secondaryFixedDim) || other.secondaryFixedDim == _this.secondaryFixedDim)&&(identical(other.onSecondaryFixed, _this.onSecondaryFixed) || other.onSecondaryFixed == _this.onSecondaryFixed)&&(identical(other.onSecondaryFixedVariant, _this.onSecondaryFixedVariant) || other.onSecondaryFixedVariant == _this.onSecondaryFixedVariant)&&(identical(other.tertiary, _this.tertiary) || other.tertiary == _this.tertiary)&&(identical(other.onTertiary, _this.onTertiary) || other.onTertiary == _this.onTertiary)&&(identical(other.tertiaryContainer, _this.tertiaryContainer) || other.tertiaryContainer == _this.tertiaryContainer)&&(identical(other.onTertiaryContainer, _this.onTertiaryContainer) || other.onTertiaryContainer == _this.onTertiaryContainer)&&(identical(other.tertiaryFixed, _this.tertiaryFixed) || other.tertiaryFixed == _this.tertiaryFixed)&&(identical(other.tertiaryFixedDim, _this.tertiaryFixedDim) || other.tertiaryFixedDim == _this.tertiaryFixedDim)&&(identical(other.onTertiaryFixed, _this.onTertiaryFixed) || other.onTertiaryFixed == _this.onTertiaryFixed)&&(identical(other.onTertiaryFixedVariant, _this.onTertiaryFixedVariant) || other.onTertiaryFixedVariant == _this.onTertiaryFixedVariant)&&(identical(other.error, _this.error) || other.error == _this.error)&&(identical(other.onError, _this.onError) || other.onError == _this.onError)&&(identical(other.errorContainer, _this.errorContainer) || other.errorContainer == _this.errorContainer)&&(identical(other.onErrorContainer, _this.onErrorContainer) || other.onErrorContainer == _this.onErrorContainer)&&(identical(other.outline, _this.outline) || other.outline == _this.outline)&&(identical(other.outlineVariant, _this.outlineVariant) || other.outlineVariant == _this.outlineVariant)&&(identical(other.surface, _this.surface) || other.surface == _this.surface)&&(identical(other.onSurface, _this.onSurface) || other.onSurface == _this.onSurface)&&(identical(other.surfaceDim, _this.surfaceDim) || other.surfaceDim == _this.surfaceDim)&&(identical(other.surfaceBright, _this.surfaceBright) || other.surfaceBright == _this.surfaceBright)&&(identical(other.surfaceContainerLowest, _this.surfaceContainerLowest) || other.surfaceContainerLowest == _this.surfaceContainerLowest)&&(identical(other.surfaceContainerLow, _this.surfaceContainerLow) || other.surfaceContainerLow == _this.surfaceContainerLow)&&(identical(other.surfaceContainer, _this.surfaceContainer) || other.surfaceContainer == _this.surfaceContainer)&&(identical(other.surfaceContainerHigh, _this.surfaceContainerHigh) || other.surfaceContainerHigh == _this.surfaceContainerHigh)&&(identical(other.surfaceContainerHighest, _this.surfaceContainerHighest) || other.surfaceContainerHighest == _this.surfaceContainerHighest)&&(identical(other.onSurfaceVariant, _this.onSurfaceVariant) || other.onSurfaceVariant == _this.onSurfaceVariant)&&(identical(other.inverseSurface, _this.inverseSurface) || other.inverseSurface == _this.inverseSurface)&&(identical(other.onInverseSurface, _this.onInverseSurface) || other.onInverseSurface == _this.onInverseSurface)&&(identical(other.inversePrimary, _this.inversePrimary) || other.inversePrimary == _this.inversePrimary)&&(identical(other.shadow, _this.shadow) || other.shadow == _this.shadow)&&(identical(other.scrim, _this.scrim) || other.scrim == _this.scrim)&&(identical(other.surfaceTint, _this.surfaceTint) || other.surfaceTint == _this.surfaceTint));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ColorSchemeOverride;
  return Object.hashAll([runtimeType,_this.primary,_this.onPrimary,_this.primaryContainer,_this.onPrimaryContainer,_this.primaryFixed,_this.primaryFixedDim,_this.onPrimaryFixed,_this.onPrimaryFixedVariant,_this.secondary,_this.onSecondary,_this.secondaryContainer,_this.onSecondaryContainer,_this.secondaryFixed,_this.secondaryFixedDim,_this.onSecondaryFixed,_this.onSecondaryFixedVariant,_this.tertiary,_this.onTertiary,_this.tertiaryContainer,_this.onTertiaryContainer,_this.tertiaryFixed,_this.tertiaryFixedDim,_this.onTertiaryFixed,_this.onTertiaryFixedVariant,_this.error,_this.onError,_this.errorContainer,_this.onErrorContainer,_this.outline,_this.outlineVariant,_this.surface,_this.onSurface,_this.surfaceDim,_this.surfaceBright,_this.surfaceContainerLowest,_this.surfaceContainerLow,_this.surfaceContainer,_this.surfaceContainerHigh,_this.surfaceContainerHighest,_this.onSurfaceVariant,_this.inverseSurface,_this.onInverseSurface,_this.inversePrimary,_this.shadow,_this.scrim,_this.surfaceTint]);
}

@override
String toString() {
  final _this = this as ColorSchemeOverride;
  return 'ColorSchemeOverride(primary: ${_this.primary}, onPrimary: ${_this.onPrimary}, primaryContainer: ${_this.primaryContainer}, onPrimaryContainer: ${_this.onPrimaryContainer}, primaryFixed: ${_this.primaryFixed}, primaryFixedDim: ${_this.primaryFixedDim}, onPrimaryFixed: ${_this.onPrimaryFixed}, onPrimaryFixedVariant: ${_this.onPrimaryFixedVariant}, secondary: ${_this.secondary}, onSecondary: ${_this.onSecondary}, secondaryContainer: ${_this.secondaryContainer}, onSecondaryContainer: ${_this.onSecondaryContainer}, secondaryFixed: ${_this.secondaryFixed}, secondaryFixedDim: ${_this.secondaryFixedDim}, onSecondaryFixed: ${_this.onSecondaryFixed}, onSecondaryFixedVariant: ${_this.onSecondaryFixedVariant}, tertiary: ${_this.tertiary}, onTertiary: ${_this.onTertiary}, tertiaryContainer: ${_this.tertiaryContainer}, onTertiaryContainer: ${_this.onTertiaryContainer}, tertiaryFixed: ${_this.tertiaryFixed}, tertiaryFixedDim: ${_this.tertiaryFixedDim}, onTertiaryFixed: ${_this.onTertiaryFixed}, onTertiaryFixedVariant: ${_this.onTertiaryFixedVariant}, error: ${_this.error}, onError: ${_this.onError}, errorContainer: ${_this.errorContainer}, onErrorContainer: ${_this.onErrorContainer}, outline: ${_this.outline}, outlineVariant: ${_this.outlineVariant}, surface: ${_this.surface}, onSurface: ${_this.onSurface}, surfaceDim: ${_this.surfaceDim}, surfaceBright: ${_this.surfaceBright}, surfaceContainerLowest: ${_this.surfaceContainerLowest}, surfaceContainerLow: ${_this.surfaceContainerLow}, surfaceContainer: ${_this.surfaceContainer}, surfaceContainerHigh: ${_this.surfaceContainerHigh}, surfaceContainerHighest: ${_this.surfaceContainerHighest}, onSurfaceVariant: ${_this.onSurfaceVariant}, inverseSurface: ${_this.inverseSurface}, onInverseSurface: ${_this.onInverseSurface}, inversePrimary: ${_this.inversePrimary}, shadow: ${_this.shadow}, scrim: ${_this.scrim}, surfaceTint: ${_this.surfaceTint})';
}


}

/// @nodoc
abstract mixin class $ColorSchemeOverrideCopyWith<$Res>  {
  factory $ColorSchemeOverrideCopyWith(ColorSchemeOverride value, $Res Function(ColorSchemeOverride) _then) = _$ColorSchemeOverrideCopyWithImpl;
@useResult
$Res call({
 String? primary, String? onPrimary, String? primaryContainer, String? onPrimaryContainer, String? primaryFixed, String? primaryFixedDim, String? onPrimaryFixed, String? onPrimaryFixedVariant, String? secondary, String? onSecondary, String? secondaryContainer, String? onSecondaryContainer, String? secondaryFixed, String? secondaryFixedDim, String? onSecondaryFixed, String? onSecondaryFixedVariant, String? tertiary, String? onTertiary, String? tertiaryContainer, String? onTertiaryContainer, String? tertiaryFixed, String? tertiaryFixedDim, String? onTertiaryFixed, String? onTertiaryFixedVariant, String? error, String? onError, String? errorContainer, String? onErrorContainer, String? outline, String? outlineVariant, String? surface, String? onSurface, String? surfaceDim, String? surfaceBright, String? surfaceContainerLowest, String? surfaceContainerLow, String? surfaceContainer, String? surfaceContainerHigh, String? surfaceContainerHighest, String? onSurfaceVariant, String? inverseSurface, String? onInverseSurface, String? inversePrimary, String? shadow, String? scrim, String? surfaceTint
});




}
/// @nodoc
class _$ColorSchemeOverrideCopyWithImpl<$Res>
    implements $ColorSchemeOverrideCopyWith<$Res> {
  _$ColorSchemeOverrideCopyWithImpl(this._self, this._then);

  final ColorSchemeOverride _self;
  final $Res Function(ColorSchemeOverride) _then;

/// Create a copy of ColorSchemeOverride
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? primary = freezed,Object? onPrimary = freezed,Object? primaryContainer = freezed,Object? onPrimaryContainer = freezed,Object? primaryFixed = freezed,Object? primaryFixedDim = freezed,Object? onPrimaryFixed = freezed,Object? onPrimaryFixedVariant = freezed,Object? secondary = freezed,Object? onSecondary = freezed,Object? secondaryContainer = freezed,Object? onSecondaryContainer = freezed,Object? secondaryFixed = freezed,Object? secondaryFixedDim = freezed,Object? onSecondaryFixed = freezed,Object? onSecondaryFixedVariant = freezed,Object? tertiary = freezed,Object? onTertiary = freezed,Object? tertiaryContainer = freezed,Object? onTertiaryContainer = freezed,Object? tertiaryFixed = freezed,Object? tertiaryFixedDim = freezed,Object? onTertiaryFixed = freezed,Object? onTertiaryFixedVariant = freezed,Object? error = freezed,Object? onError = freezed,Object? errorContainer = freezed,Object? onErrorContainer = freezed,Object? outline = freezed,Object? outlineVariant = freezed,Object? surface = freezed,Object? onSurface = freezed,Object? surfaceDim = freezed,Object? surfaceBright = freezed,Object? surfaceContainerLowest = freezed,Object? surfaceContainerLow = freezed,Object? surfaceContainer = freezed,Object? surfaceContainerHigh = freezed,Object? surfaceContainerHighest = freezed,Object? onSurfaceVariant = freezed,Object? inverseSurface = freezed,Object? onInverseSurface = freezed,Object? inversePrimary = freezed,Object? shadow = freezed,Object? scrim = freezed,Object? surfaceTint = freezed,}) {
  return _then(ColorSchemeOverride(
primary: freezed == primary ? _self.primary : primary // ignore: cast_nullable_to_non_nullable
as String?,onPrimary: freezed == onPrimary ? _self.onPrimary : onPrimary // ignore: cast_nullable_to_non_nullable
as String?,primaryContainer: freezed == primaryContainer ? _self.primaryContainer : primaryContainer // ignore: cast_nullable_to_non_nullable
as String?,onPrimaryContainer: freezed == onPrimaryContainer ? _self.onPrimaryContainer : onPrimaryContainer // ignore: cast_nullable_to_non_nullable
as String?,primaryFixed: freezed == primaryFixed ? _self.primaryFixed : primaryFixed // ignore: cast_nullable_to_non_nullable
as String?,primaryFixedDim: freezed == primaryFixedDim ? _self.primaryFixedDim : primaryFixedDim // ignore: cast_nullable_to_non_nullable
as String?,onPrimaryFixed: freezed == onPrimaryFixed ? _self.onPrimaryFixed : onPrimaryFixed // ignore: cast_nullable_to_non_nullable
as String?,onPrimaryFixedVariant: freezed == onPrimaryFixedVariant ? _self.onPrimaryFixedVariant : onPrimaryFixedVariant // ignore: cast_nullable_to_non_nullable
as String?,secondary: freezed == secondary ? _self.secondary : secondary // ignore: cast_nullable_to_non_nullable
as String?,onSecondary: freezed == onSecondary ? _self.onSecondary : onSecondary // ignore: cast_nullable_to_non_nullable
as String?,secondaryContainer: freezed == secondaryContainer ? _self.secondaryContainer : secondaryContainer // ignore: cast_nullable_to_non_nullable
as String?,onSecondaryContainer: freezed == onSecondaryContainer ? _self.onSecondaryContainer : onSecondaryContainer // ignore: cast_nullable_to_non_nullable
as String?,secondaryFixed: freezed == secondaryFixed ? _self.secondaryFixed : secondaryFixed // ignore: cast_nullable_to_non_nullable
as String?,secondaryFixedDim: freezed == secondaryFixedDim ? _self.secondaryFixedDim : secondaryFixedDim // ignore: cast_nullable_to_non_nullable
as String?,onSecondaryFixed: freezed == onSecondaryFixed ? _self.onSecondaryFixed : onSecondaryFixed // ignore: cast_nullable_to_non_nullable
as String?,onSecondaryFixedVariant: freezed == onSecondaryFixedVariant ? _self.onSecondaryFixedVariant : onSecondaryFixedVariant // ignore: cast_nullable_to_non_nullable
as String?,tertiary: freezed == tertiary ? _self.tertiary : tertiary // ignore: cast_nullable_to_non_nullable
as String?,onTertiary: freezed == onTertiary ? _self.onTertiary : onTertiary // ignore: cast_nullable_to_non_nullable
as String?,tertiaryContainer: freezed == tertiaryContainer ? _self.tertiaryContainer : tertiaryContainer // ignore: cast_nullable_to_non_nullable
as String?,onTertiaryContainer: freezed == onTertiaryContainer ? _self.onTertiaryContainer : onTertiaryContainer // ignore: cast_nullable_to_non_nullable
as String?,tertiaryFixed: freezed == tertiaryFixed ? _self.tertiaryFixed : tertiaryFixed // ignore: cast_nullable_to_non_nullable
as String?,tertiaryFixedDim: freezed == tertiaryFixedDim ? _self.tertiaryFixedDim : tertiaryFixedDim // ignore: cast_nullable_to_non_nullable
as String?,onTertiaryFixed: freezed == onTertiaryFixed ? _self.onTertiaryFixed : onTertiaryFixed // ignore: cast_nullable_to_non_nullable
as String?,onTertiaryFixedVariant: freezed == onTertiaryFixedVariant ? _self.onTertiaryFixedVariant : onTertiaryFixedVariant // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,onError: freezed == onError ? _self.onError : onError // ignore: cast_nullable_to_non_nullable
as String?,errorContainer: freezed == errorContainer ? _self.errorContainer : errorContainer // ignore: cast_nullable_to_non_nullable
as String?,onErrorContainer: freezed == onErrorContainer ? _self.onErrorContainer : onErrorContainer // ignore: cast_nullable_to_non_nullable
as String?,outline: freezed == outline ? _self.outline : outline // ignore: cast_nullable_to_non_nullable
as String?,outlineVariant: freezed == outlineVariant ? _self.outlineVariant : outlineVariant // ignore: cast_nullable_to_non_nullable
as String?,surface: freezed == surface ? _self.surface : surface // ignore: cast_nullable_to_non_nullable
as String?,onSurface: freezed == onSurface ? _self.onSurface : onSurface // ignore: cast_nullable_to_non_nullable
as String?,surfaceDim: freezed == surfaceDim ? _self.surfaceDim : surfaceDim // ignore: cast_nullable_to_non_nullable
as String?,surfaceBright: freezed == surfaceBright ? _self.surfaceBright : surfaceBright // ignore: cast_nullable_to_non_nullable
as String?,surfaceContainerLowest: freezed == surfaceContainerLowest ? _self.surfaceContainerLowest : surfaceContainerLowest // ignore: cast_nullable_to_non_nullable
as String?,surfaceContainerLow: freezed == surfaceContainerLow ? _self.surfaceContainerLow : surfaceContainerLow // ignore: cast_nullable_to_non_nullable
as String?,surfaceContainer: freezed == surfaceContainer ? _self.surfaceContainer : surfaceContainer // ignore: cast_nullable_to_non_nullable
as String?,surfaceContainerHigh: freezed == surfaceContainerHigh ? _self.surfaceContainerHigh : surfaceContainerHigh // ignore: cast_nullable_to_non_nullable
as String?,surfaceContainerHighest: freezed == surfaceContainerHighest ? _self.surfaceContainerHighest : surfaceContainerHighest // ignore: cast_nullable_to_non_nullable
as String?,onSurfaceVariant: freezed == onSurfaceVariant ? _self.onSurfaceVariant : onSurfaceVariant // ignore: cast_nullable_to_non_nullable
as String?,inverseSurface: freezed == inverseSurface ? _self.inverseSurface : inverseSurface // ignore: cast_nullable_to_non_nullable
as String?,onInverseSurface: freezed == onInverseSurface ? _self.onInverseSurface : onInverseSurface // ignore: cast_nullable_to_non_nullable
as String?,inversePrimary: freezed == inversePrimary ? _self.inversePrimary : inversePrimary // ignore: cast_nullable_to_non_nullable
as String?,shadow: freezed == shadow ? _self.shadow : shadow // ignore: cast_nullable_to_non_nullable
as String?,scrim: freezed == scrim ? _self.scrim : scrim // ignore: cast_nullable_to_non_nullable
as String?,surfaceTint: freezed == surfaceTint ? _self.surfaceTint : surfaceTint // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ColorSchemeOverride].
extension ColorSchemeOverridePatterns on ColorSchemeOverride {
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
