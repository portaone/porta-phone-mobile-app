// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'theme_widget_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ThemeWidgetConfig {


/// Create a copy of ThemeWidgetConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ThemeWidgetConfigCopyWith<ThemeWidgetConfig> get copyWith => _$ThemeWidgetConfigCopyWithImpl<ThemeWidgetConfig>(this as ThemeWidgetConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ThemeWidgetConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ThemeWidgetConfig&&(identical(other.fonts, _this.fonts) || other.fonts == _this.fonts)&&(identical(other.button, _this.button) || other.button == _this.button)&&(identical(other.group, _this.group) || other.group == _this.group)&&(identical(other.bar, _this.bar) || other.bar == _this.bar)&&(identical(other.imageAssets, _this.imageAssets) || other.imageAssets == _this.imageAssets)&&(identical(other.input, _this.input) || other.input == _this.input)&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.dialog, _this.dialog) || other.dialog == _this.dialog)&&(identical(other.statuses, _this.statuses) || other.statuses == _this.statuses));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ThemeWidgetConfig;
  return Object.hash(runtimeType,_this.fonts,_this.button,_this.group,_this.bar,_this.imageAssets,_this.input,_this.text,_this.dialog,_this.statuses);
}

@override
String toString() {
  final _this = this as ThemeWidgetConfig;
  return 'ThemeWidgetConfig(fonts: ${_this.fonts}, button: ${_this.button}, group: ${_this.group}, bar: ${_this.bar}, imageAssets: ${_this.imageAssets}, input: ${_this.input}, text: ${_this.text}, dialog: ${_this.dialog}, statuses: ${_this.statuses})';
}


}

/// @nodoc
abstract mixin class $ThemeWidgetConfigCopyWith<$Res>  {
  factory $ThemeWidgetConfigCopyWith(ThemeWidgetConfig value, $Res Function(ThemeWidgetConfig) _then) = _$ThemeWidgetConfigCopyWithImpl;
@useResult
$Res call({
 FontsConfig fonts, ButtonWidgetConfig button, GroupWidgetConfig? group, BarWidgetConfig bar, ImageAssetsConfig imageAssets, InputWidgetConfig input, TextWidgetConfig text, DialogWidgetConfig dialog, StatusesWidgetConfig statuses
});




}
/// @nodoc
class _$ThemeWidgetConfigCopyWithImpl<$Res>
    implements $ThemeWidgetConfigCopyWith<$Res> {
  _$ThemeWidgetConfigCopyWithImpl(this._self, this._then);

  final ThemeWidgetConfig _self;
  final $Res Function(ThemeWidgetConfig) _then;

/// Create a copy of ThemeWidgetConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fonts = null,Object? button = null,Object? group = freezed,Object? bar = null,Object? imageAssets = null,Object? input = null,Object? text = null,Object? dialog = null,Object? statuses = null,}) {
  return _then(ThemeWidgetConfig(
fonts: null == fonts ? _self.fonts : fonts // ignore: cast_nullable_to_non_nullable
as FontsConfig,button: null == button ? _self.button : button // ignore: cast_nullable_to_non_nullable
as ButtonWidgetConfig,group: freezed == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as GroupWidgetConfig?,bar: null == bar ? _self.bar : bar // ignore: cast_nullable_to_non_nullable
as BarWidgetConfig,imageAssets: null == imageAssets ? _self.imageAssets : imageAssets // ignore: cast_nullable_to_non_nullable
as ImageAssetsConfig,input: null == input ? _self.input : input // ignore: cast_nullable_to_non_nullable
as InputWidgetConfig,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as TextWidgetConfig,dialog: null == dialog ? _self.dialog : dialog // ignore: cast_nullable_to_non_nullable
as DialogWidgetConfig,statuses: null == statuses ? _self.statuses : statuses // ignore: cast_nullable_to_non_nullable
as StatusesWidgetConfig,
  ));
}

}


/// Adds pattern-matching-related methods to [ThemeWidgetConfig].
extension ThemeWidgetConfigPatterns on ThemeWidgetConfig {
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
mixin _$FontsConfig {


/// Create a copy of FontsConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FontsConfigCopyWith<FontsConfig> get copyWith => _$FontsConfigCopyWithImpl<FontsConfig>(this as FontsConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FontsConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FontsConfig&&(identical(other.fontFamily, _this.fontFamily) || other.fontFamily == _this.fontFamily));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as FontsConfig;
  return Object.hash(runtimeType,_this.fontFamily);
}

@override
String toString() {
  final _this = this as FontsConfig;
  return 'FontsConfig(fontFamily: ${_this.fontFamily})';
}


}

/// @nodoc
abstract mixin class $FontsConfigCopyWith<$Res>  {
  factory $FontsConfigCopyWith(FontsConfig value, $Res Function(FontsConfig) _then) = _$FontsConfigCopyWithImpl;
@useResult
$Res call({
 String? fontFamily
});




}
/// @nodoc
class _$FontsConfigCopyWithImpl<$Res>
    implements $FontsConfigCopyWith<$Res> {
  _$FontsConfigCopyWithImpl(this._self, this._then);

  final FontsConfig _self;
  final $Res Function(FontsConfig) _then;

/// Create a copy of FontsConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fontFamily = freezed,}) {
  return _then(FontsConfig(
fontFamily: freezed == fontFamily ? _self.fontFamily : fontFamily // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [FontsConfig].
extension FontsConfigPatterns on FontsConfig {
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
mixin _$ButtonWidgetConfig {


/// Create a copy of ButtonWidgetConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ButtonWidgetConfigCopyWith<ButtonWidgetConfig> get copyWith => _$ButtonWidgetConfigCopyWithImpl<ButtonWidgetConfig>(this as ButtonWidgetConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ButtonWidgetConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ButtonWidgetConfig&&(identical(other.primaryElevatedButton, _this.primaryElevatedButton) || other.primaryElevatedButton == _this.primaryElevatedButton));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ButtonWidgetConfig;
  return Object.hash(runtimeType,_this.primaryElevatedButton);
}

@override
String toString() {
  final _this = this as ButtonWidgetConfig;
  return 'ButtonWidgetConfig(primaryElevatedButton: ${_this.primaryElevatedButton})';
}


}

/// @nodoc
abstract mixin class $ButtonWidgetConfigCopyWith<$Res>  {
  factory $ButtonWidgetConfigCopyWith(ButtonWidgetConfig value, $Res Function(ButtonWidgetConfig) _then) = _$ButtonWidgetConfigCopyWithImpl;
@useResult
$Res call({
 ButtonStyleConfig? primaryElevatedButton
});




}
/// @nodoc
class _$ButtonWidgetConfigCopyWithImpl<$Res>
    implements $ButtonWidgetConfigCopyWith<$Res> {
  _$ButtonWidgetConfigCopyWithImpl(this._self, this._then);

  final ButtonWidgetConfig _self;
  final $Res Function(ButtonWidgetConfig) _then;

/// Create a copy of ButtonWidgetConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? primaryElevatedButton = freezed,}) {
  return _then(ButtonWidgetConfig(
primaryElevatedButton: freezed == primaryElevatedButton ? _self.primaryElevatedButton : primaryElevatedButton // ignore: cast_nullable_to_non_nullable
as ButtonStyleConfig?,
  ));
}

}


/// Adds pattern-matching-related methods to [ButtonWidgetConfig].
extension ButtonWidgetConfigPatterns on ButtonWidgetConfig {
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
mixin _$GroupWidgetConfig {


/// Create a copy of GroupWidgetConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupWidgetConfigCopyWith<GroupWidgetConfig> get copyWith => _$GroupWidgetConfigCopyWithImpl<GroupWidgetConfig>(this as GroupWidgetConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as GroupWidgetConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupWidgetConfig&&(identical(other.groupTitleListTile, _this.groupTitleListTile) || other.groupTitleListTile == _this.groupTitleListTile));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as GroupWidgetConfig;
  return Object.hash(runtimeType,_this.groupTitleListTile);
}

@override
String toString() {
  final _this = this as GroupWidgetConfig;
  return 'GroupWidgetConfig(groupTitleListTile: ${_this.groupTitleListTile})';
}


}

/// @nodoc
abstract mixin class $GroupWidgetConfigCopyWith<$Res>  {
  factory $GroupWidgetConfigCopyWith(GroupWidgetConfig value, $Res Function(GroupWidgetConfig) _then) = _$GroupWidgetConfigCopyWithImpl;
@useResult
$Res call({
 GroupTitleListTileWidgetConfig groupTitleListTile
});




}
/// @nodoc
class _$GroupWidgetConfigCopyWithImpl<$Res>
    implements $GroupWidgetConfigCopyWith<$Res> {
  _$GroupWidgetConfigCopyWithImpl(this._self, this._then);

  final GroupWidgetConfig _self;
  final $Res Function(GroupWidgetConfig) _then;

/// Create a copy of GroupWidgetConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? groupTitleListTile = null,}) {
  return _then(GroupWidgetConfig(
groupTitleListTile: null == groupTitleListTile ? _self.groupTitleListTile : groupTitleListTile // ignore: cast_nullable_to_non_nullable
as GroupTitleListTileWidgetConfig,
  ));
}

}


/// Adds pattern-matching-related methods to [GroupWidgetConfig].
extension GroupWidgetConfigPatterns on GroupWidgetConfig {
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
mixin _$BarWidgetConfig {


/// Create a copy of BarWidgetConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BarWidgetConfigCopyWith<BarWidgetConfig> get copyWith => _$BarWidgetConfigCopyWithImpl<BarWidgetConfig>(this as BarWidgetConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as BarWidgetConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BarWidgetConfig&&(identical(other.bottomNavigationBar, _this.bottomNavigationBar) || other.bottomNavigationBar == _this.bottomNavigationBar)&&(identical(other.appBarConfig, _this.appBarConfig) || other.appBarConfig == _this.appBarConfig)&&(identical(other.tabBarConfig, _this.tabBarConfig) || other.tabBarConfig == _this.tabBarConfig));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BarWidgetConfig;
  return Object.hash(runtimeType,_this.bottomNavigationBar,_this.appBarConfig,_this.tabBarConfig);
}

@override
String toString() {
  final _this = this as BarWidgetConfig;
  return 'BarWidgetConfig(bottomNavigationBar: ${_this.bottomNavigationBar}, appBarConfig: ${_this.appBarConfig}, tabBarConfig: ${_this.tabBarConfig})';
}


}

/// @nodoc
abstract mixin class $BarWidgetConfigCopyWith<$Res>  {
  factory $BarWidgetConfigCopyWith(BarWidgetConfig value, $Res Function(BarWidgetConfig) _then) = _$BarWidgetConfigCopyWithImpl;
@useResult
$Res call({
 BottomNavigationBarWidgetConfig bottomNavigationBar, AppBarConfig appBarConfig, TabBarConfig tabBarConfig
});




}
/// @nodoc
class _$BarWidgetConfigCopyWithImpl<$Res>
    implements $BarWidgetConfigCopyWith<$Res> {
  _$BarWidgetConfigCopyWithImpl(this._self, this._then);

  final BarWidgetConfig _self;
  final $Res Function(BarWidgetConfig) _then;

/// Create a copy of BarWidgetConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bottomNavigationBar = null,Object? appBarConfig = null,Object? tabBarConfig = null,}) {
  return _then(BarWidgetConfig(
bottomNavigationBar: null == bottomNavigationBar ? _self.bottomNavigationBar : bottomNavigationBar // ignore: cast_nullable_to_non_nullable
as BottomNavigationBarWidgetConfig,appBarConfig: null == appBarConfig ? _self.appBarConfig : appBarConfig // ignore: cast_nullable_to_non_nullable
as AppBarConfig,tabBarConfig: null == tabBarConfig ? _self.tabBarConfig : tabBarConfig // ignore: cast_nullable_to_non_nullable
as TabBarConfig,
  ));
}

}


/// Adds pattern-matching-related methods to [BarWidgetConfig].
extension BarWidgetConfigPatterns on BarWidgetConfig {
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
mixin _$BottomNavigationBarWidgetConfig {


/// Create a copy of BottomNavigationBarWidgetConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BottomNavigationBarWidgetConfigCopyWith<BottomNavigationBarWidgetConfig> get copyWith => _$BottomNavigationBarWidgetConfigCopyWithImpl<BottomNavigationBarWidgetConfig>(this as BottomNavigationBarWidgetConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as BottomNavigationBarWidgetConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BottomNavigationBarWidgetConfig&&(identical(other.backgroundColor, _this.backgroundColor) || other.backgroundColor == _this.backgroundColor)&&(identical(other.elevation, _this.elevation) || other.elevation == _this.elevation)&&(identical(other.selectedItemColor, _this.selectedItemColor) || other.selectedItemColor == _this.selectedItemColor)&&(identical(other.unSelectedItemColor, _this.unSelectedItemColor) || other.unSelectedItemColor == _this.unSelectedItemColor)&&(identical(other.selectedLabelStyle, _this.selectedLabelStyle) || other.selectedLabelStyle == _this.selectedLabelStyle)&&(identical(other.unselectedLabelStyle, _this.unselectedLabelStyle) || other.unselectedLabelStyle == _this.unselectedLabelStyle)&&(identical(other.selectedIconTheme, _this.selectedIconTheme) || other.selectedIconTheme == _this.selectedIconTheme)&&(identical(other.unselectedIconTheme, _this.unselectedIconTheme) || other.unselectedIconTheme == _this.unselectedIconTheme)&&(identical(other.showSelectedLabels, _this.showSelectedLabels) || other.showSelectedLabels == _this.showSelectedLabels)&&(identical(other.showUnselectedLabels, _this.showUnselectedLabels) || other.showUnselectedLabels == _this.showUnselectedLabels));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BottomNavigationBarWidgetConfig;
  return Object.hash(runtimeType,_this.backgroundColor,_this.elevation,_this.selectedItemColor,_this.unSelectedItemColor,_this.selectedLabelStyle,_this.unselectedLabelStyle,_this.selectedIconTheme,_this.unselectedIconTheme,_this.showSelectedLabels,_this.showUnselectedLabels);
}

@override
String toString() {
  final _this = this as BottomNavigationBarWidgetConfig;
  return 'BottomNavigationBarWidgetConfig(backgroundColor: ${_this.backgroundColor}, elevation: ${_this.elevation}, selectedItemColor: ${_this.selectedItemColor}, unSelectedItemColor: ${_this.unSelectedItemColor}, selectedLabelStyle: ${_this.selectedLabelStyle}, unselectedLabelStyle: ${_this.unselectedLabelStyle}, selectedIconTheme: ${_this.selectedIconTheme}, unselectedIconTheme: ${_this.unselectedIconTheme}, showSelectedLabels: ${_this.showSelectedLabels}, showUnselectedLabels: ${_this.showUnselectedLabels})';
}


}

/// @nodoc
abstract mixin class $BottomNavigationBarWidgetConfigCopyWith<$Res>  {
  factory $BottomNavigationBarWidgetConfigCopyWith(BottomNavigationBarWidgetConfig value, $Res Function(BottomNavigationBarWidgetConfig) _then) = _$BottomNavigationBarWidgetConfigCopyWithImpl;
@useResult
$Res call({
 String? backgroundColor, double? elevation, String? selectedItemColor, String? unSelectedItemColor, TextStyleConfig? selectedLabelStyle, TextStyleConfig? unselectedLabelStyle, IconThemeDataConfig? selectedIconTheme, IconThemeDataConfig? unselectedIconTheme, bool? showSelectedLabels, bool? showUnselectedLabels
});




}
/// @nodoc
class _$BottomNavigationBarWidgetConfigCopyWithImpl<$Res>
    implements $BottomNavigationBarWidgetConfigCopyWith<$Res> {
  _$BottomNavigationBarWidgetConfigCopyWithImpl(this._self, this._then);

  final BottomNavigationBarWidgetConfig _self;
  final $Res Function(BottomNavigationBarWidgetConfig) _then;

/// Create a copy of BottomNavigationBarWidgetConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? backgroundColor = freezed,Object? elevation = freezed,Object? selectedItemColor = freezed,Object? unSelectedItemColor = freezed,Object? selectedLabelStyle = freezed,Object? unselectedLabelStyle = freezed,Object? selectedIconTheme = freezed,Object? unselectedIconTheme = freezed,Object? showSelectedLabels = freezed,Object? showUnselectedLabels = freezed,}) {
  return _then(BottomNavigationBarWidgetConfig(
backgroundColor: freezed == backgroundColor ? _self.backgroundColor : backgroundColor // ignore: cast_nullable_to_non_nullable
as String?,elevation: freezed == elevation ? _self.elevation : elevation // ignore: cast_nullable_to_non_nullable
as double?,selectedItemColor: freezed == selectedItemColor ? _self.selectedItemColor : selectedItemColor // ignore: cast_nullable_to_non_nullable
as String?,unSelectedItemColor: freezed == unSelectedItemColor ? _self.unSelectedItemColor : unSelectedItemColor // ignore: cast_nullable_to_non_nullable
as String?,selectedLabelStyle: freezed == selectedLabelStyle ? _self.selectedLabelStyle : selectedLabelStyle // ignore: cast_nullable_to_non_nullable
as TextStyleConfig?,unselectedLabelStyle: freezed == unselectedLabelStyle ? _self.unselectedLabelStyle : unselectedLabelStyle // ignore: cast_nullable_to_non_nullable
as TextStyleConfig?,selectedIconTheme: freezed == selectedIconTheme ? _self.selectedIconTheme : selectedIconTheme // ignore: cast_nullable_to_non_nullable
as IconThemeDataConfig?,unselectedIconTheme: freezed == unselectedIconTheme ? _self.unselectedIconTheme : unselectedIconTheme // ignore: cast_nullable_to_non_nullable
as IconThemeDataConfig?,showSelectedLabels: freezed == showSelectedLabels ? _self.showSelectedLabels : showSelectedLabels // ignore: cast_nullable_to_non_nullable
as bool?,showUnselectedLabels: freezed == showUnselectedLabels ? _self.showUnselectedLabels : showUnselectedLabels // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [BottomNavigationBarWidgetConfig].
extension BottomNavigationBarWidgetConfigPatterns on BottomNavigationBarWidgetConfig {
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
mixin _$GroupTitleListTileWidgetConfig {


/// Create a copy of GroupTitleListTileWidgetConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupTitleListTileWidgetConfigCopyWith<GroupTitleListTileWidgetConfig> get copyWith => _$GroupTitleListTileWidgetConfigCopyWithImpl<GroupTitleListTileWidgetConfig>(this as GroupTitleListTileWidgetConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as GroupTitleListTileWidgetConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupTitleListTileWidgetConfig&&(identical(other.backgroundColor, _this.backgroundColor) || other.backgroundColor == _this.backgroundColor)&&(identical(other.textStyle, _this.textStyle) || other.textStyle == _this.textStyle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as GroupTitleListTileWidgetConfig;
  return Object.hash(runtimeType,_this.backgroundColor,_this.textStyle);
}

@override
String toString() {
  final _this = this as GroupTitleListTileWidgetConfig;
  return 'GroupTitleListTileWidgetConfig(backgroundColor: ${_this.backgroundColor}, textStyle: ${_this.textStyle})';
}


}

/// @nodoc
abstract mixin class $GroupTitleListTileWidgetConfigCopyWith<$Res>  {
  factory $GroupTitleListTileWidgetConfigCopyWith(GroupTitleListTileWidgetConfig value, $Res Function(GroupTitleListTileWidgetConfig) _then) = _$GroupTitleListTileWidgetConfigCopyWithImpl;
@useResult
$Res call({
 String? backgroundColor, TextStyleConfig? textStyle
});




}
/// @nodoc
class _$GroupTitleListTileWidgetConfigCopyWithImpl<$Res>
    implements $GroupTitleListTileWidgetConfigCopyWith<$Res> {
  _$GroupTitleListTileWidgetConfigCopyWithImpl(this._self, this._then);

  final GroupTitleListTileWidgetConfig _self;
  final $Res Function(GroupTitleListTileWidgetConfig) _then;

/// Create a copy of GroupTitleListTileWidgetConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? backgroundColor = freezed,Object? textStyle = freezed,}) {
  return _then(GroupTitleListTileWidgetConfig(
backgroundColor: freezed == backgroundColor ? _self.backgroundColor : backgroundColor // ignore: cast_nullable_to_non_nullable
as String?,textStyle: freezed == textStyle ? _self.textStyle : textStyle // ignore: cast_nullable_to_non_nullable
as TextStyleConfig?,
  ));
}

}


/// Adds pattern-matching-related methods to [GroupTitleListTileWidgetConfig].
extension GroupTitleListTileWidgetConfigPatterns on GroupTitleListTileWidgetConfig {
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
mixin _$ImageAssetsConfig {


/// Create a copy of ImageAssetsConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImageAssetsConfigCopyWith<ImageAssetsConfig> get copyWith => _$ImageAssetsConfigCopyWithImpl<ImageAssetsConfig>(this as ImageAssetsConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ImageAssetsConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImageAssetsConfig&&(identical(other.defaultPlaceholderImage, _this.defaultPlaceholderImage) || other.defaultPlaceholderImage == _this.defaultPlaceholderImage)&&(identical(other.appIcon, _this.appIcon) || other.appIcon == _this.appIcon)&&(identical(other.leadingAvatarStyle, _this.leadingAvatarStyle) || other.leadingAvatarStyle == _this.leadingAvatarStyle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ImageAssetsConfig;
  return Object.hash(runtimeType,_this.defaultPlaceholderImage,_this.appIcon,_this.leadingAvatarStyle);
}

@override
String toString() {
  final _this = this as ImageAssetsConfig;
  return 'ImageAssetsConfig(defaultPlaceholderImage: ${_this.defaultPlaceholderImage}, appIcon: ${_this.appIcon}, leadingAvatarStyle: ${_this.leadingAvatarStyle})';
}


}

/// @nodoc
abstract mixin class $ImageAssetsConfigCopyWith<$Res>  {
  factory $ImageAssetsConfigCopyWith(ImageAssetsConfig value, $Res Function(ImageAssetsConfig) _then) = _$ImageAssetsConfigCopyWithImpl;
@useResult
$Res call({
 ImageSource? defaultPlaceholderImage, AppIconWidgetConfig appIcon, LeadingAvatarStyleConfig leadingAvatarStyle
});




}
/// @nodoc
class _$ImageAssetsConfigCopyWithImpl<$Res>
    implements $ImageAssetsConfigCopyWith<$Res> {
  _$ImageAssetsConfigCopyWithImpl(this._self, this._then);

  final ImageAssetsConfig _self;
  final $Res Function(ImageAssetsConfig) _then;

/// Create a copy of ImageAssetsConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? defaultPlaceholderImage = freezed,Object? appIcon = null,Object? leadingAvatarStyle = null,}) {
  return _then(ImageAssetsConfig(
defaultPlaceholderImage: freezed == defaultPlaceholderImage ? _self.defaultPlaceholderImage : defaultPlaceholderImage // ignore: cast_nullable_to_non_nullable
as ImageSource?,appIcon: null == appIcon ? _self.appIcon : appIcon // ignore: cast_nullable_to_non_nullable
as AppIconWidgetConfig,leadingAvatarStyle: null == leadingAvatarStyle ? _self.leadingAvatarStyle : leadingAvatarStyle // ignore: cast_nullable_to_non_nullable
as LeadingAvatarStyleConfig,
  ));
}

}


/// Adds pattern-matching-related methods to [ImageAssetsConfig].
extension ImageAssetsConfigPatterns on ImageAssetsConfig {
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
mixin _$AppIconWidgetConfig {


/// Create a copy of AppIconWidgetConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppIconWidgetConfigCopyWith<AppIconWidgetConfig> get copyWith => _$AppIconWidgetConfigCopyWithImpl<AppIconWidgetConfig>(this as AppIconWidgetConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AppIconWidgetConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppIconWidgetConfig&&(identical(other.color, _this.color) || other.color == _this.color));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AppIconWidgetConfig;
  return Object.hash(runtimeType,_this.color);
}

@override
String toString() {
  final _this = this as AppIconWidgetConfig;
  return 'AppIconWidgetConfig(color: ${_this.color})';
}


}

/// @nodoc
abstract mixin class $AppIconWidgetConfigCopyWith<$Res>  {
  factory $AppIconWidgetConfigCopyWith(AppIconWidgetConfig value, $Res Function(AppIconWidgetConfig) _then) = _$AppIconWidgetConfigCopyWithImpl;
@useResult
$Res call({
 String? color
});




}
/// @nodoc
class _$AppIconWidgetConfigCopyWithImpl<$Res>
    implements $AppIconWidgetConfigCopyWith<$Res> {
  _$AppIconWidgetConfigCopyWithImpl(this._self, this._then);

  final AppIconWidgetConfig _self;
  final $Res Function(AppIconWidgetConfig) _then;

/// Create a copy of AppIconWidgetConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? color = freezed,}) {
  return _then(AppIconWidgetConfig(
color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppIconWidgetConfig].
extension AppIconWidgetConfigPatterns on AppIconWidgetConfig {
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
mixin _$InputWidgetConfig {


/// Create a copy of InputWidgetConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InputWidgetConfigCopyWith<InputWidgetConfig> get copyWith => _$InputWidgetConfigCopyWithImpl<InputWidgetConfig>(this as InputWidgetConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as InputWidgetConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InputWidgetConfig&&(identical(other.primary, _this.primary) || other.primary == _this.primary));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as InputWidgetConfig;
  return Object.hash(runtimeType,_this.primary);
}

@override
String toString() {
  final _this = this as InputWidgetConfig;
  return 'InputWidgetConfig(primary: ${_this.primary})';
}


}

/// @nodoc
abstract mixin class $InputWidgetConfigCopyWith<$Res>  {
  factory $InputWidgetConfigCopyWith(InputWidgetConfig value, $Res Function(InputWidgetConfig) _then) = _$InputWidgetConfigCopyWithImpl;
@useResult
$Res call({
 TextFormFieldWidgetConfig primary
});




}
/// @nodoc
class _$InputWidgetConfigCopyWithImpl<$Res>
    implements $InputWidgetConfigCopyWith<$Res> {
  _$InputWidgetConfigCopyWithImpl(this._self, this._then);

  final InputWidgetConfig _self;
  final $Res Function(InputWidgetConfig) _then;

/// Create a copy of InputWidgetConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? primary = null,}) {
  return _then(InputWidgetConfig(
primary: null == primary ? _self.primary : primary // ignore: cast_nullable_to_non_nullable
as TextFormFieldWidgetConfig,
  ));
}

}


/// Adds pattern-matching-related methods to [InputWidgetConfig].
extension InputWidgetConfigPatterns on InputWidgetConfig {
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
mixin _$TextFormFieldWidgetConfig {


/// Create a copy of TextFormFieldWidgetConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TextFormFieldWidgetConfigCopyWith<TextFormFieldWidgetConfig> get copyWith => _$TextFormFieldWidgetConfigCopyWithImpl<TextFormFieldWidgetConfig>(this as TextFormFieldWidgetConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TextFormFieldWidgetConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TextFormFieldWidgetConfig&&(identical(other.labelColor, _this.labelColor) || other.labelColor == _this.labelColor)&&(identical(other.border, _this.border) || other.border == _this.border));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TextFormFieldWidgetConfig;
  return Object.hash(runtimeType,_this.labelColor,_this.border);
}

@override
String toString() {
  final _this = this as TextFormFieldWidgetConfig;
  return 'TextFormFieldWidgetConfig(labelColor: ${_this.labelColor}, border: ${_this.border})';
}


}

/// @nodoc
abstract mixin class $TextFormFieldWidgetConfigCopyWith<$Res>  {
  factory $TextFormFieldWidgetConfigCopyWith(TextFormFieldWidgetConfig value, $Res Function(TextFormFieldWidgetConfig) _then) = _$TextFormFieldWidgetConfigCopyWithImpl;
@useResult
$Res call({
 String? labelColor, InputBorderWidgetConfig border
});




}
/// @nodoc
class _$TextFormFieldWidgetConfigCopyWithImpl<$Res>
    implements $TextFormFieldWidgetConfigCopyWith<$Res> {
  _$TextFormFieldWidgetConfigCopyWithImpl(this._self, this._then);

  final TextFormFieldWidgetConfig _self;
  final $Res Function(TextFormFieldWidgetConfig) _then;

/// Create a copy of TextFormFieldWidgetConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? labelColor = freezed,Object? border = null,}) {
  return _then(TextFormFieldWidgetConfig(
labelColor: freezed == labelColor ? _self.labelColor : labelColor // ignore: cast_nullable_to_non_nullable
as String?,border: null == border ? _self.border : border // ignore: cast_nullable_to_non_nullable
as InputBorderWidgetConfig,
  ));
}

}


/// Adds pattern-matching-related methods to [TextFormFieldWidgetConfig].
extension TextFormFieldWidgetConfigPatterns on TextFormFieldWidgetConfig {
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
mixin _$InputBorderWidgetConfig {


/// Create a copy of InputBorderWidgetConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InputBorderWidgetConfigCopyWith<InputBorderWidgetConfig> get copyWith => _$InputBorderWidgetConfigCopyWithImpl<InputBorderWidgetConfig>(this as InputBorderWidgetConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as InputBorderWidgetConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InputBorderWidgetConfig&&(identical(other.disabled, _this.disabled) || other.disabled == _this.disabled)&&(identical(other.focused, _this.focused) || other.focused == _this.focused)&&(identical(other.any, _this.any) || other.any == _this.any));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as InputBorderWidgetConfig;
  return Object.hash(runtimeType,_this.disabled,_this.focused,_this.any);
}

@override
String toString() {
  final _this = this as InputBorderWidgetConfig;
  return 'InputBorderWidgetConfig(disabled: ${_this.disabled}, focused: ${_this.focused}, any: ${_this.any})';
}


}

/// @nodoc
abstract mixin class $InputBorderWidgetConfigCopyWith<$Res>  {
  factory $InputBorderWidgetConfigCopyWith(InputBorderWidgetConfig value, $Res Function(InputBorderWidgetConfig) _then) = _$InputBorderWidgetConfigCopyWithImpl;
@useResult
$Res call({
 BorderWidgetConfig disabled, BorderWidgetConfig focused, BorderWidgetConfig any
});




}
/// @nodoc
class _$InputBorderWidgetConfigCopyWithImpl<$Res>
    implements $InputBorderWidgetConfigCopyWith<$Res> {
  _$InputBorderWidgetConfigCopyWithImpl(this._self, this._then);

  final InputBorderWidgetConfig _self;
  final $Res Function(InputBorderWidgetConfig) _then;

/// Create a copy of InputBorderWidgetConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? disabled = null,Object? focused = null,Object? any = null,}) {
  return _then(InputBorderWidgetConfig(
disabled: null == disabled ? _self.disabled : disabled // ignore: cast_nullable_to_non_nullable
as BorderWidgetConfig,focused: null == focused ? _self.focused : focused // ignore: cast_nullable_to_non_nullable
as BorderWidgetConfig,any: null == any ? _self.any : any // ignore: cast_nullable_to_non_nullable
as BorderWidgetConfig,
  ));
}

}


/// Adds pattern-matching-related methods to [InputBorderWidgetConfig].
extension InputBorderWidgetConfigPatterns on InputBorderWidgetConfig {
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
mixin _$BorderWidgetConfig {


/// Create a copy of BorderWidgetConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BorderWidgetConfigCopyWith<BorderWidgetConfig> get copyWith => _$BorderWidgetConfigCopyWithImpl<BorderWidgetConfig>(this as BorderWidgetConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as BorderWidgetConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BorderWidgetConfig&&(identical(other.typicalColor, _this.typicalColor) || other.typicalColor == _this.typicalColor)&&(identical(other.errorColor, _this.errorColor) || other.errorColor == _this.errorColor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BorderWidgetConfig;
  return Object.hash(runtimeType,_this.typicalColor,_this.errorColor);
}

@override
String toString() {
  final _this = this as BorderWidgetConfig;
  return 'BorderWidgetConfig(typicalColor: ${_this.typicalColor}, errorColor: ${_this.errorColor})';
}


}

/// @nodoc
abstract mixin class $BorderWidgetConfigCopyWith<$Res>  {
  factory $BorderWidgetConfigCopyWith(BorderWidgetConfig value, $Res Function(BorderWidgetConfig) _then) = _$BorderWidgetConfigCopyWithImpl;
@useResult
$Res call({
 String? typicalColor, String? errorColor
});




}
/// @nodoc
class _$BorderWidgetConfigCopyWithImpl<$Res>
    implements $BorderWidgetConfigCopyWith<$Res> {
  _$BorderWidgetConfigCopyWithImpl(this._self, this._then);

  final BorderWidgetConfig _self;
  final $Res Function(BorderWidgetConfig) _then;

/// Create a copy of BorderWidgetConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? typicalColor = freezed,Object? errorColor = freezed,}) {
  return _then(BorderWidgetConfig(
typicalColor: freezed == typicalColor ? _self.typicalColor : typicalColor // ignore: cast_nullable_to_non_nullable
as String?,errorColor: freezed == errorColor ? _self.errorColor : errorColor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BorderWidgetConfig].
extension BorderWidgetConfigPatterns on BorderWidgetConfig {
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
mixin _$TextWidgetConfig {


/// Create a copy of TextWidgetConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TextWidgetConfigCopyWith<TextWidgetConfig> get copyWith => _$TextWidgetConfigCopyWithImpl<TextWidgetConfig>(this as TextWidgetConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TextWidgetConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TextWidgetConfig&&(identical(other.selection, _this.selection) || other.selection == _this.selection)&&(identical(other.linkify, _this.linkify) || other.linkify == _this.linkify));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TextWidgetConfig;
  return Object.hash(runtimeType,_this.selection,_this.linkify);
}

@override
String toString() {
  final _this = this as TextWidgetConfig;
  return 'TextWidgetConfig(selection: ${_this.selection}, linkify: ${_this.linkify})';
}


}

/// @nodoc
abstract mixin class $TextWidgetConfigCopyWith<$Res>  {
  factory $TextWidgetConfigCopyWith(TextWidgetConfig value, $Res Function(TextWidgetConfig) _then) = _$TextWidgetConfigCopyWithImpl;
@useResult
$Res call({
 TextSelectionWidgetConfig selection, LinkifyWidgetConfig linkify
});




}
/// @nodoc
class _$TextWidgetConfigCopyWithImpl<$Res>
    implements $TextWidgetConfigCopyWith<$Res> {
  _$TextWidgetConfigCopyWithImpl(this._self, this._then);

  final TextWidgetConfig _self;
  final $Res Function(TextWidgetConfig) _then;

/// Create a copy of TextWidgetConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? selection = null,Object? linkify = null,}) {
  return _then(TextWidgetConfig(
selection: null == selection ? _self.selection : selection // ignore: cast_nullable_to_non_nullable
as TextSelectionWidgetConfig,linkify: null == linkify ? _self.linkify : linkify // ignore: cast_nullable_to_non_nullable
as LinkifyWidgetConfig,
  ));
}

}


/// Adds pattern-matching-related methods to [TextWidgetConfig].
extension TextWidgetConfigPatterns on TextWidgetConfig {
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
mixin _$TextSelectionWidgetConfig {


/// Create a copy of TextSelectionWidgetConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TextSelectionWidgetConfigCopyWith<TextSelectionWidgetConfig> get copyWith => _$TextSelectionWidgetConfigCopyWithImpl<TextSelectionWidgetConfig>(this as TextSelectionWidgetConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TextSelectionWidgetConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TextSelectionWidgetConfig&&(identical(other.cursorColor, _this.cursorColor) || other.cursorColor == _this.cursorColor)&&(identical(other.selectionColor, _this.selectionColor) || other.selectionColor == _this.selectionColor)&&(identical(other.selectionHandleColor, _this.selectionHandleColor) || other.selectionHandleColor == _this.selectionHandleColor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TextSelectionWidgetConfig;
  return Object.hash(runtimeType,_this.cursorColor,_this.selectionColor,_this.selectionHandleColor);
}

@override
String toString() {
  final _this = this as TextSelectionWidgetConfig;
  return 'TextSelectionWidgetConfig(cursorColor: ${_this.cursorColor}, selectionColor: ${_this.selectionColor}, selectionHandleColor: ${_this.selectionHandleColor})';
}


}

/// @nodoc
abstract mixin class $TextSelectionWidgetConfigCopyWith<$Res>  {
  factory $TextSelectionWidgetConfigCopyWith(TextSelectionWidgetConfig value, $Res Function(TextSelectionWidgetConfig) _then) = _$TextSelectionWidgetConfigCopyWithImpl;
@useResult
$Res call({
 String? cursorColor, String? selectionColor, String? selectionHandleColor
});




}
/// @nodoc
class _$TextSelectionWidgetConfigCopyWithImpl<$Res>
    implements $TextSelectionWidgetConfigCopyWith<$Res> {
  _$TextSelectionWidgetConfigCopyWithImpl(this._self, this._then);

  final TextSelectionWidgetConfig _self;
  final $Res Function(TextSelectionWidgetConfig) _then;

/// Create a copy of TextSelectionWidgetConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cursorColor = freezed,Object? selectionColor = freezed,Object? selectionHandleColor = freezed,}) {
  return _then(TextSelectionWidgetConfig(
cursorColor: freezed == cursorColor ? _self.cursorColor : cursorColor // ignore: cast_nullable_to_non_nullable
as String?,selectionColor: freezed == selectionColor ? _self.selectionColor : selectionColor // ignore: cast_nullable_to_non_nullable
as String?,selectionHandleColor: freezed == selectionHandleColor ? _self.selectionHandleColor : selectionHandleColor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TextSelectionWidgetConfig].
extension TextSelectionWidgetConfigPatterns on TextSelectionWidgetConfig {
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
mixin _$LinkifyWidgetConfig {


/// Create a copy of LinkifyWidgetConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LinkifyWidgetConfigCopyWith<LinkifyWidgetConfig> get copyWith => _$LinkifyWidgetConfigCopyWithImpl<LinkifyWidgetConfig>(this as LinkifyWidgetConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LinkifyWidgetConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LinkifyWidgetConfig&&(identical(other.styleColor, _this.styleColor) || other.styleColor == _this.styleColor)&&(identical(other.linkifyStyleColor, _this.linkifyStyleColor) || other.linkifyStyleColor == _this.linkifyStyleColor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LinkifyWidgetConfig;
  return Object.hash(runtimeType,_this.styleColor,_this.linkifyStyleColor);
}

@override
String toString() {
  final _this = this as LinkifyWidgetConfig;
  return 'LinkifyWidgetConfig(styleColor: ${_this.styleColor}, linkifyStyleColor: ${_this.linkifyStyleColor})';
}


}

/// @nodoc
abstract mixin class $LinkifyWidgetConfigCopyWith<$Res>  {
  factory $LinkifyWidgetConfigCopyWith(LinkifyWidgetConfig value, $Res Function(LinkifyWidgetConfig) _then) = _$LinkifyWidgetConfigCopyWithImpl;
@useResult
$Res call({
 String? styleColor, String? linkifyStyleColor
});




}
/// @nodoc
class _$LinkifyWidgetConfigCopyWithImpl<$Res>
    implements $LinkifyWidgetConfigCopyWith<$Res> {
  _$LinkifyWidgetConfigCopyWithImpl(this._self, this._then);

  final LinkifyWidgetConfig _self;
  final $Res Function(LinkifyWidgetConfig) _then;

/// Create a copy of LinkifyWidgetConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? styleColor = freezed,Object? linkifyStyleColor = freezed,}) {
  return _then(LinkifyWidgetConfig(
styleColor: freezed == styleColor ? _self.styleColor : styleColor // ignore: cast_nullable_to_non_nullable
as String?,linkifyStyleColor: freezed == linkifyStyleColor ? _self.linkifyStyleColor : linkifyStyleColor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [LinkifyWidgetConfig].
extension LinkifyWidgetConfigPatterns on LinkifyWidgetConfig {
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
mixin _$DialogWidgetConfig {


/// Create a copy of DialogWidgetConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DialogWidgetConfigCopyWith<DialogWidgetConfig> get copyWith => _$DialogWidgetConfigCopyWithImpl<DialogWidgetConfig>(this as DialogWidgetConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DialogWidgetConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DialogWidgetConfig&&(identical(other.theme, _this.theme) || other.theme == _this.theme)&&(identical(other.confirmDialog, _this.confirmDialog) || other.confirmDialog == _this.confirmDialog)&&(identical(other.snackBar, _this.snackBar) || other.snackBar == _this.snackBar));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DialogWidgetConfig;
  return Object.hash(runtimeType,_this.theme,_this.confirmDialog,_this.snackBar);
}

@override
String toString() {
  final _this = this as DialogWidgetConfig;
  return 'DialogWidgetConfig(theme: ${_this.theme}, confirmDialog: ${_this.confirmDialog}, snackBar: ${_this.snackBar})';
}


}

/// @nodoc
abstract mixin class $DialogWidgetConfigCopyWith<$Res>  {
  factory $DialogWidgetConfigCopyWith(DialogWidgetConfig value, $Res Function(DialogWidgetConfig) _then) = _$DialogWidgetConfigCopyWithImpl;
@useResult
$Res call({
 DialogThemeConfig theme, ConfirmDialogWidgetConfig confirmDialog, SnackBarWidgetConfig snackBar
});




}
/// @nodoc
class _$DialogWidgetConfigCopyWithImpl<$Res>
    implements $DialogWidgetConfigCopyWith<$Res> {
  _$DialogWidgetConfigCopyWithImpl(this._self, this._then);

  final DialogWidgetConfig _self;
  final $Res Function(DialogWidgetConfig) _then;

/// Create a copy of DialogWidgetConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? theme = null,Object? confirmDialog = null,Object? snackBar = null,}) {
  return _then(DialogWidgetConfig(
theme: null == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as DialogThemeConfig,confirmDialog: null == confirmDialog ? _self.confirmDialog : confirmDialog // ignore: cast_nullable_to_non_nullable
as ConfirmDialogWidgetConfig,snackBar: null == snackBar ? _self.snackBar : snackBar // ignore: cast_nullable_to_non_nullable
as SnackBarWidgetConfig,
  ));
}

}


/// Adds pattern-matching-related methods to [DialogWidgetConfig].
extension DialogWidgetConfigPatterns on DialogWidgetConfig {
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
mixin _$DialogThemeConfig {


/// Create a copy of DialogThemeConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DialogThemeConfigCopyWith<DialogThemeConfig> get copyWith => _$DialogThemeConfigCopyWithImpl<DialogThemeConfig>(this as DialogThemeConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DialogThemeConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DialogThemeConfig&&(identical(other.backgroundColor, _this.backgroundColor) || other.backgroundColor == _this.backgroundColor)&&(identical(other.surfaceTintColor, _this.surfaceTintColor) || other.surfaceTintColor == _this.surfaceTintColor)&&(identical(other.shadowColor, _this.shadowColor) || other.shadowColor == _this.shadowColor)&&(identical(other.barrierColor, _this.barrierColor) || other.barrierColor == _this.barrierColor)&&(identical(other.elevation, _this.elevation) || other.elevation == _this.elevation)&&(identical(other.borderRadius, _this.borderRadius) || other.borderRadius == _this.borderRadius)&&(identical(other.titleTextStyle, _this.titleTextStyle) || other.titleTextStyle == _this.titleTextStyle)&&(identical(other.contentTextStyle, _this.contentTextStyle) || other.contentTextStyle == _this.contentTextStyle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DialogThemeConfig;
  return Object.hash(runtimeType,_this.backgroundColor,_this.surfaceTintColor,_this.shadowColor,_this.barrierColor,_this.elevation,_this.borderRadius,_this.titleTextStyle,_this.contentTextStyle);
}

@override
String toString() {
  final _this = this as DialogThemeConfig;
  return 'DialogThemeConfig(backgroundColor: ${_this.backgroundColor}, surfaceTintColor: ${_this.surfaceTintColor}, shadowColor: ${_this.shadowColor}, barrierColor: ${_this.barrierColor}, elevation: ${_this.elevation}, borderRadius: ${_this.borderRadius}, titleTextStyle: ${_this.titleTextStyle}, contentTextStyle: ${_this.contentTextStyle})';
}


}

/// @nodoc
abstract mixin class $DialogThemeConfigCopyWith<$Res>  {
  factory $DialogThemeConfigCopyWith(DialogThemeConfig value, $Res Function(DialogThemeConfig) _then) = _$DialogThemeConfigCopyWithImpl;
@useResult
$Res call({
 String? backgroundColor, String? surfaceTintColor, String? shadowColor, String? barrierColor, double? elevation, double? borderRadius, TextStyleConfig? titleTextStyle, TextStyleConfig? contentTextStyle
});




}
/// @nodoc
class _$DialogThemeConfigCopyWithImpl<$Res>
    implements $DialogThemeConfigCopyWith<$Res> {
  _$DialogThemeConfigCopyWithImpl(this._self, this._then);

  final DialogThemeConfig _self;
  final $Res Function(DialogThemeConfig) _then;

/// Create a copy of DialogThemeConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? backgroundColor = freezed,Object? surfaceTintColor = freezed,Object? shadowColor = freezed,Object? barrierColor = freezed,Object? elevation = freezed,Object? borderRadius = freezed,Object? titleTextStyle = freezed,Object? contentTextStyle = freezed,}) {
  return _then(DialogThemeConfig(
backgroundColor: freezed == backgroundColor ? _self.backgroundColor : backgroundColor // ignore: cast_nullable_to_non_nullable
as String?,surfaceTintColor: freezed == surfaceTintColor ? _self.surfaceTintColor : surfaceTintColor // ignore: cast_nullable_to_non_nullable
as String?,shadowColor: freezed == shadowColor ? _self.shadowColor : shadowColor // ignore: cast_nullable_to_non_nullable
as String?,barrierColor: freezed == barrierColor ? _self.barrierColor : barrierColor // ignore: cast_nullable_to_non_nullable
as String?,elevation: freezed == elevation ? _self.elevation : elevation // ignore: cast_nullable_to_non_nullable
as double?,borderRadius: freezed == borderRadius ? _self.borderRadius : borderRadius // ignore: cast_nullable_to_non_nullable
as double?,titleTextStyle: freezed == titleTextStyle ? _self.titleTextStyle : titleTextStyle // ignore: cast_nullable_to_non_nullable
as TextStyleConfig?,contentTextStyle: freezed == contentTextStyle ? _self.contentTextStyle : contentTextStyle // ignore: cast_nullable_to_non_nullable
as TextStyleConfig?,
  ));
}

}


/// Adds pattern-matching-related methods to [DialogThemeConfig].
extension DialogThemeConfigPatterns on DialogThemeConfig {
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
mixin _$ConfirmDialogWidgetConfig {


/// Create a copy of ConfirmDialogWidgetConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConfirmDialogWidgetConfigCopyWith<ConfirmDialogWidgetConfig> get copyWith => _$ConfirmDialogWidgetConfigCopyWithImpl<ConfirmDialogWidgetConfig>(this as ConfirmDialogWidgetConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ConfirmDialogWidgetConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConfirmDialogWidgetConfig&&(identical(other.activeButtonColor1, _this.activeButtonColor1) || other.activeButtonColor1 == _this.activeButtonColor1)&&(identical(other.activeButtonColor2, _this.activeButtonColor2) || other.activeButtonColor2 == _this.activeButtonColor2)&&(identical(other.defaultButtonColor, _this.defaultButtonColor) || other.defaultButtonColor == _this.defaultButtonColor)&&(identical(other.backgroundColor, _this.backgroundColor) || other.backgroundColor == _this.backgroundColor)&&(identical(other.surfaceTintColor, _this.surfaceTintColor) || other.surfaceTintColor == _this.surfaceTintColor)&&(identical(other.elevation, _this.elevation) || other.elevation == _this.elevation)&&(identical(other.borderRadius, _this.borderRadius) || other.borderRadius == _this.borderRadius)&&(identical(other.titleTextStyle, _this.titleTextStyle) || other.titleTextStyle == _this.titleTextStyle)&&(identical(other.contentTextStyle, _this.contentTextStyle) || other.contentTextStyle == _this.contentTextStyle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ConfirmDialogWidgetConfig;
  return Object.hash(runtimeType,_this.activeButtonColor1,_this.activeButtonColor2,_this.defaultButtonColor,_this.backgroundColor,_this.surfaceTintColor,_this.elevation,_this.borderRadius,_this.titleTextStyle,_this.contentTextStyle);
}

@override
String toString() {
  final _this = this as ConfirmDialogWidgetConfig;
  return 'ConfirmDialogWidgetConfig(activeButtonColor1: ${_this.activeButtonColor1}, activeButtonColor2: ${_this.activeButtonColor2}, defaultButtonColor: ${_this.defaultButtonColor}, backgroundColor: ${_this.backgroundColor}, surfaceTintColor: ${_this.surfaceTintColor}, elevation: ${_this.elevation}, borderRadius: ${_this.borderRadius}, titleTextStyle: ${_this.titleTextStyle}, contentTextStyle: ${_this.contentTextStyle})';
}


}

/// @nodoc
abstract mixin class $ConfirmDialogWidgetConfigCopyWith<$Res>  {
  factory $ConfirmDialogWidgetConfigCopyWith(ConfirmDialogWidgetConfig value, $Res Function(ConfirmDialogWidgetConfig) _then) = _$ConfirmDialogWidgetConfigCopyWithImpl;
@useResult
$Res call({
 String? activeButtonColor1, String? activeButtonColor2, String? defaultButtonColor, String? backgroundColor, String? surfaceTintColor, double? elevation, double? borderRadius, TextStyleConfig? titleTextStyle, TextStyleConfig? contentTextStyle
});




}
/// @nodoc
class _$ConfirmDialogWidgetConfigCopyWithImpl<$Res>
    implements $ConfirmDialogWidgetConfigCopyWith<$Res> {
  _$ConfirmDialogWidgetConfigCopyWithImpl(this._self, this._then);

  final ConfirmDialogWidgetConfig _self;
  final $Res Function(ConfirmDialogWidgetConfig) _then;

/// Create a copy of ConfirmDialogWidgetConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? activeButtonColor1 = freezed,Object? activeButtonColor2 = freezed,Object? defaultButtonColor = freezed,Object? backgroundColor = freezed,Object? surfaceTintColor = freezed,Object? elevation = freezed,Object? borderRadius = freezed,Object? titleTextStyle = freezed,Object? contentTextStyle = freezed,}) {
  return _then(ConfirmDialogWidgetConfig(
activeButtonColor1: freezed == activeButtonColor1 ? _self.activeButtonColor1 : activeButtonColor1 // ignore: cast_nullable_to_non_nullable
as String?,activeButtonColor2: freezed == activeButtonColor2 ? _self.activeButtonColor2 : activeButtonColor2 // ignore: cast_nullable_to_non_nullable
as String?,defaultButtonColor: freezed == defaultButtonColor ? _self.defaultButtonColor : defaultButtonColor // ignore: cast_nullable_to_non_nullable
as String?,backgroundColor: freezed == backgroundColor ? _self.backgroundColor : backgroundColor // ignore: cast_nullable_to_non_nullable
as String?,surfaceTintColor: freezed == surfaceTintColor ? _self.surfaceTintColor : surfaceTintColor // ignore: cast_nullable_to_non_nullable
as String?,elevation: freezed == elevation ? _self.elevation : elevation // ignore: cast_nullable_to_non_nullable
as double?,borderRadius: freezed == borderRadius ? _self.borderRadius : borderRadius // ignore: cast_nullable_to_non_nullable
as double?,titleTextStyle: freezed == titleTextStyle ? _self.titleTextStyle : titleTextStyle // ignore: cast_nullable_to_non_nullable
as TextStyleConfig?,contentTextStyle: freezed == contentTextStyle ? _self.contentTextStyle : contentTextStyle // ignore: cast_nullable_to_non_nullable
as TextStyleConfig?,
  ));
}

}


/// Adds pattern-matching-related methods to [ConfirmDialogWidgetConfig].
extension ConfirmDialogWidgetConfigPatterns on ConfirmDialogWidgetConfig {
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
mixin _$SnackBarWidgetConfig {


/// Create a copy of SnackBarWidgetConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SnackBarWidgetConfigCopyWith<SnackBarWidgetConfig> get copyWith => _$SnackBarWidgetConfigCopyWithImpl<SnackBarWidgetConfig>(this as SnackBarWidgetConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SnackBarWidgetConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SnackBarWidgetConfig&&(identical(other.successBackgroundColor, _this.successBackgroundColor) || other.successBackgroundColor == _this.successBackgroundColor)&&(identical(other.errorBackgroundColor, _this.errorBackgroundColor) || other.errorBackgroundColor == _this.errorBackgroundColor)&&(identical(other.infoBackgroundColor, _this.infoBackgroundColor) || other.infoBackgroundColor == _this.infoBackgroundColor)&&(identical(other.warningBackgroundColor, _this.warningBackgroundColor) || other.warningBackgroundColor == _this.warningBackgroundColor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SnackBarWidgetConfig;
  return Object.hash(runtimeType,_this.successBackgroundColor,_this.errorBackgroundColor,_this.infoBackgroundColor,_this.warningBackgroundColor);
}

@override
String toString() {
  final _this = this as SnackBarWidgetConfig;
  return 'SnackBarWidgetConfig(successBackgroundColor: ${_this.successBackgroundColor}, errorBackgroundColor: ${_this.errorBackgroundColor}, infoBackgroundColor: ${_this.infoBackgroundColor}, warningBackgroundColor: ${_this.warningBackgroundColor})';
}


}

/// @nodoc
abstract mixin class $SnackBarWidgetConfigCopyWith<$Res>  {
  factory $SnackBarWidgetConfigCopyWith(SnackBarWidgetConfig value, $Res Function(SnackBarWidgetConfig) _then) = _$SnackBarWidgetConfigCopyWithImpl;
@useResult
$Res call({
 String successBackgroundColor, String errorBackgroundColor, String infoBackgroundColor, String warningBackgroundColor
});




}
/// @nodoc
class _$SnackBarWidgetConfigCopyWithImpl<$Res>
    implements $SnackBarWidgetConfigCopyWith<$Res> {
  _$SnackBarWidgetConfigCopyWithImpl(this._self, this._then);

  final SnackBarWidgetConfig _self;
  final $Res Function(SnackBarWidgetConfig) _then;

/// Create a copy of SnackBarWidgetConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? successBackgroundColor = null,Object? errorBackgroundColor = null,Object? infoBackgroundColor = null,Object? warningBackgroundColor = null,}) {
  return _then(SnackBarWidgetConfig(
successBackgroundColor: null == successBackgroundColor ? _self.successBackgroundColor : successBackgroundColor // ignore: cast_nullable_to_non_nullable
as String,errorBackgroundColor: null == errorBackgroundColor ? _self.errorBackgroundColor : errorBackgroundColor // ignore: cast_nullable_to_non_nullable
as String,infoBackgroundColor: null == infoBackgroundColor ? _self.infoBackgroundColor : infoBackgroundColor // ignore: cast_nullable_to_non_nullable
as String,warningBackgroundColor: null == warningBackgroundColor ? _self.warningBackgroundColor : warningBackgroundColor // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SnackBarWidgetConfig].
extension SnackBarWidgetConfigPatterns on SnackBarWidgetConfig {
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
mixin _$StatusesWidgetConfig {


/// Create a copy of StatusesWidgetConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StatusesWidgetConfigCopyWith<StatusesWidgetConfig> get copyWith => _$StatusesWidgetConfigCopyWithImpl<StatusesWidgetConfig>(this as StatusesWidgetConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as StatusesWidgetConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StatusesWidgetConfig&&(identical(other.registrationStatuses, _this.registrationStatuses) || other.registrationStatuses == _this.registrationStatuses)&&(identical(other.callStatuses, _this.callStatuses) || other.callStatuses == _this.callStatuses));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as StatusesWidgetConfig;
  return Object.hash(runtimeType,_this.registrationStatuses,_this.callStatuses);
}

@override
String toString() {
  final _this = this as StatusesWidgetConfig;
  return 'StatusesWidgetConfig(registrationStatuses: ${_this.registrationStatuses}, callStatuses: ${_this.callStatuses})';
}


}

/// @nodoc
abstract mixin class $StatusesWidgetConfigCopyWith<$Res>  {
  factory $StatusesWidgetConfigCopyWith(StatusesWidgetConfig value, $Res Function(StatusesWidgetConfig) _then) = _$StatusesWidgetConfigCopyWithImpl;
@useResult
$Res call({
 RegistrationStatusesWidgetConfig registrationStatuses, CallStatusesWidgetConfig callStatuses
});




}
/// @nodoc
class _$StatusesWidgetConfigCopyWithImpl<$Res>
    implements $StatusesWidgetConfigCopyWith<$Res> {
  _$StatusesWidgetConfigCopyWithImpl(this._self, this._then);

  final StatusesWidgetConfig _self;
  final $Res Function(StatusesWidgetConfig) _then;

/// Create a copy of StatusesWidgetConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? registrationStatuses = null,Object? callStatuses = null,}) {
  return _then(StatusesWidgetConfig(
registrationStatuses: null == registrationStatuses ? _self.registrationStatuses : registrationStatuses // ignore: cast_nullable_to_non_nullable
as RegistrationStatusesWidgetConfig,callStatuses: null == callStatuses ? _self.callStatuses : callStatuses // ignore: cast_nullable_to_non_nullable
as CallStatusesWidgetConfig,
  ));
}

}


/// Adds pattern-matching-related methods to [StatusesWidgetConfig].
extension StatusesWidgetConfigPatterns on StatusesWidgetConfig {
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
mixin _$RegistrationStatusesWidgetConfig {


/// Create a copy of RegistrationStatusesWidgetConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RegistrationStatusesWidgetConfigCopyWith<RegistrationStatusesWidgetConfig> get copyWith => _$RegistrationStatusesWidgetConfigCopyWithImpl<RegistrationStatusesWidgetConfig>(this as RegistrationStatusesWidgetConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RegistrationStatusesWidgetConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegistrationStatusesWidgetConfig&&(identical(other.online, _this.online) || other.online == _this.online)&&(identical(other.offline, _this.offline) || other.offline == _this.offline));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RegistrationStatusesWidgetConfig;
  return Object.hash(runtimeType,_this.online,_this.offline);
}

@override
String toString() {
  final _this = this as RegistrationStatusesWidgetConfig;
  return 'RegistrationStatusesWidgetConfig(online: ${_this.online}, offline: ${_this.offline})';
}


}

/// @nodoc
abstract mixin class $RegistrationStatusesWidgetConfigCopyWith<$Res>  {
  factory $RegistrationStatusesWidgetConfigCopyWith(RegistrationStatusesWidgetConfig value, $Res Function(RegistrationStatusesWidgetConfig) _then) = _$RegistrationStatusesWidgetConfigCopyWithImpl;
@useResult
$Res call({
 String online, String offline
});




}
/// @nodoc
class _$RegistrationStatusesWidgetConfigCopyWithImpl<$Res>
    implements $RegistrationStatusesWidgetConfigCopyWith<$Res> {
  _$RegistrationStatusesWidgetConfigCopyWithImpl(this._self, this._then);

  final RegistrationStatusesWidgetConfig _self;
  final $Res Function(RegistrationStatusesWidgetConfig) _then;

/// Create a copy of RegistrationStatusesWidgetConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? online = null,Object? offline = null,}) {
  return _then(RegistrationStatusesWidgetConfig(
online: null == online ? _self.online : online // ignore: cast_nullable_to_non_nullable
as String,offline: null == offline ? _self.offline : offline // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RegistrationStatusesWidgetConfig].
extension RegistrationStatusesWidgetConfigPatterns on RegistrationStatusesWidgetConfig {
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
mixin _$CallStatusesWidgetConfig {


/// Create a copy of CallStatusesWidgetConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CallStatusesWidgetConfigCopyWith<CallStatusesWidgetConfig> get copyWith => _$CallStatusesWidgetConfigCopyWithImpl<CallStatusesWidgetConfig>(this as CallStatusesWidgetConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CallStatusesWidgetConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CallStatusesWidgetConfig&&(identical(other.connectivityNone, _this.connectivityNone) || other.connectivityNone == _this.connectivityNone)&&(identical(other.connectError, _this.connectError) || other.connectError == _this.connectError)&&(identical(other.appUnregistered, _this.appUnregistered) || other.appUnregistered == _this.appUnregistered)&&(identical(other.connectIssue, _this.connectIssue) || other.connectIssue == _this.connectIssue)&&(identical(other.inProgress, _this.inProgress) || other.inProgress == _this.inProgress)&&(identical(other.ready, _this.ready) || other.ready == _this.ready));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CallStatusesWidgetConfig;
  return Object.hash(runtimeType,_this.connectivityNone,_this.connectError,_this.appUnregistered,_this.connectIssue,_this.inProgress,_this.ready);
}

@override
String toString() {
  final _this = this as CallStatusesWidgetConfig;
  return 'CallStatusesWidgetConfig(connectivityNone: ${_this.connectivityNone}, connectError: ${_this.connectError}, appUnregistered: ${_this.appUnregistered}, connectIssue: ${_this.connectIssue}, inProgress: ${_this.inProgress}, ready: ${_this.ready})';
}


}

/// @nodoc
abstract mixin class $CallStatusesWidgetConfigCopyWith<$Res>  {
  factory $CallStatusesWidgetConfigCopyWith(CallStatusesWidgetConfig value, $Res Function(CallStatusesWidgetConfig) _then) = _$CallStatusesWidgetConfigCopyWithImpl;
@useResult
$Res call({
 String connectivityNone, String connectError, String appUnregistered, String connectIssue, String inProgress, String ready
});




}
/// @nodoc
class _$CallStatusesWidgetConfigCopyWithImpl<$Res>
    implements $CallStatusesWidgetConfigCopyWith<$Res> {
  _$CallStatusesWidgetConfigCopyWithImpl(this._self, this._then);

  final CallStatusesWidgetConfig _self;
  final $Res Function(CallStatusesWidgetConfig) _then;

/// Create a copy of CallStatusesWidgetConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? connectivityNone = null,Object? connectError = null,Object? appUnregistered = null,Object? connectIssue = null,Object? inProgress = null,Object? ready = null,}) {
  return _then(CallStatusesWidgetConfig(
connectivityNone: null == connectivityNone ? _self.connectivityNone : connectivityNone // ignore: cast_nullable_to_non_nullable
as String,connectError: null == connectError ? _self.connectError : connectError // ignore: cast_nullable_to_non_nullable
as String,appUnregistered: null == appUnregistered ? _self.appUnregistered : appUnregistered // ignore: cast_nullable_to_non_nullable
as String,connectIssue: null == connectIssue ? _self.connectIssue : connectIssue // ignore: cast_nullable_to_non_nullable
as String,inProgress: null == inProgress ? _self.inProgress : inProgress // ignore: cast_nullable_to_non_nullable
as String,ready: null == ready ? _self.ready : ready // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CallStatusesWidgetConfig].
extension CallStatusesWidgetConfigPatterns on CallStatusesWidgetConfig {
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
mixin _$TabBarConfig {


/// Create a copy of TabBarConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TabBarConfigCopyWith<TabBarConfig> get copyWith => _$TabBarConfigCopyWithImpl<TabBarConfig>(this as TabBarConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TabBarConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TabBarConfig&&(identical(other.indicatorColor, _this.indicatorColor) || other.indicatorColor == _this.indicatorColor)&&(identical(other.dividerColor, _this.dividerColor) || other.dividerColor == _this.dividerColor)&&(identical(other.labelColor, _this.labelColor) || other.labelColor == _this.labelColor)&&(identical(other.unselectedLabelColor, _this.unselectedLabelColor) || other.unselectedLabelColor == _this.unselectedLabelColor)&&(identical(other.overlayColor, _this.overlayColor) || other.overlayColor == _this.overlayColor)&&(identical(other.dividerHeight, _this.dividerHeight) || other.dividerHeight == _this.dividerHeight)&&(identical(other.labelPadding, _this.labelPadding) || other.labelPadding == _this.labelPadding)&&(identical(other.labelStyle, _this.labelStyle) || other.labelStyle == _this.labelStyle)&&(identical(other.unselectedLabelStyle, _this.unselectedLabelStyle) || other.unselectedLabelStyle == _this.unselectedLabelStyle)&&(identical(other.indicatorSize, _this.indicatorSize) || other.indicatorSize == _this.indicatorSize)&&(identical(other.tabAlignment, _this.tabAlignment) || other.tabAlignment == _this.tabAlignment)&&(identical(other.indicatorAnimation, _this.indicatorAnimation) || other.indicatorAnimation == _this.indicatorAnimation)&&(identical(other.splashFactory, _this.splashFactory) || other.splashFactory == _this.splashFactory)&&(identical(other.indicatorBorder, _this.indicatorBorder) || other.indicatorBorder == _this.indicatorBorder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TabBarConfig;
  return Object.hash(runtimeType,_this.indicatorColor,_this.dividerColor,_this.labelColor,_this.unselectedLabelColor,_this.overlayColor,_this.dividerHeight,_this.labelPadding,_this.labelStyle,_this.unselectedLabelStyle,_this.indicatorSize,_this.tabAlignment,_this.indicatorAnimation,_this.splashFactory,_this.indicatorBorder);
}

@override
String toString() {
  final _this = this as TabBarConfig;
  return 'TabBarConfig(indicatorColor: ${_this.indicatorColor}, dividerColor: ${_this.dividerColor}, labelColor: ${_this.labelColor}, unselectedLabelColor: ${_this.unselectedLabelColor}, overlayColor: ${_this.overlayColor}, dividerHeight: ${_this.dividerHeight}, labelPadding: ${_this.labelPadding}, labelStyle: ${_this.labelStyle}, unselectedLabelStyle: ${_this.unselectedLabelStyle}, indicatorSize: ${_this.indicatorSize}, tabAlignment: ${_this.tabAlignment}, indicatorAnimation: ${_this.indicatorAnimation}, splashFactory: ${_this.splashFactory}, indicatorBorder: ${_this.indicatorBorder})';
}


}

/// @nodoc
abstract mixin class $TabBarConfigCopyWith<$Res>  {
  factory $TabBarConfigCopyWith(TabBarConfig value, $Res Function(TabBarConfig) _then) = _$TabBarConfigCopyWithImpl;
@useResult
$Res call({
 String? indicatorColor, String? dividerColor, String? labelColor, String? unselectedLabelColor, String? overlayColor, double? dividerHeight, PaddingConfig? labelPadding, TextStyleConfig? labelStyle, TextStyleConfig? unselectedLabelStyle, TabBarIndicatorSizeConfig? indicatorSize, TabAlignmentConfig? tabAlignment, TabIndicatorAnimationConfig? indicatorAnimation, TabSplashFactoryConfig? splashFactory, BorderConfig? indicatorBorder
});




}
/// @nodoc
class _$TabBarConfigCopyWithImpl<$Res>
    implements $TabBarConfigCopyWith<$Res> {
  _$TabBarConfigCopyWithImpl(this._self, this._then);

  final TabBarConfig _self;
  final $Res Function(TabBarConfig) _then;

/// Create a copy of TabBarConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? indicatorColor = freezed,Object? dividerColor = freezed,Object? labelColor = freezed,Object? unselectedLabelColor = freezed,Object? overlayColor = freezed,Object? dividerHeight = freezed,Object? labelPadding = freezed,Object? labelStyle = freezed,Object? unselectedLabelStyle = freezed,Object? indicatorSize = freezed,Object? tabAlignment = freezed,Object? indicatorAnimation = freezed,Object? splashFactory = freezed,Object? indicatorBorder = freezed,}) {
  return _then(TabBarConfig(
indicatorColor: freezed == indicatorColor ? _self.indicatorColor : indicatorColor // ignore: cast_nullable_to_non_nullable
as String?,dividerColor: freezed == dividerColor ? _self.dividerColor : dividerColor // ignore: cast_nullable_to_non_nullable
as String?,labelColor: freezed == labelColor ? _self.labelColor : labelColor // ignore: cast_nullable_to_non_nullable
as String?,unselectedLabelColor: freezed == unselectedLabelColor ? _self.unselectedLabelColor : unselectedLabelColor // ignore: cast_nullable_to_non_nullable
as String?,overlayColor: freezed == overlayColor ? _self.overlayColor : overlayColor // ignore: cast_nullable_to_non_nullable
as String?,dividerHeight: freezed == dividerHeight ? _self.dividerHeight : dividerHeight // ignore: cast_nullable_to_non_nullable
as double?,labelPadding: freezed == labelPadding ? _self.labelPadding : labelPadding // ignore: cast_nullable_to_non_nullable
as PaddingConfig?,labelStyle: freezed == labelStyle ? _self.labelStyle : labelStyle // ignore: cast_nullable_to_non_nullable
as TextStyleConfig?,unselectedLabelStyle: freezed == unselectedLabelStyle ? _self.unselectedLabelStyle : unselectedLabelStyle // ignore: cast_nullable_to_non_nullable
as TextStyleConfig?,indicatorSize: freezed == indicatorSize ? _self.indicatorSize : indicatorSize // ignore: cast_nullable_to_non_nullable
as TabBarIndicatorSizeConfig?,tabAlignment: freezed == tabAlignment ? _self.tabAlignment : tabAlignment // ignore: cast_nullable_to_non_nullable
as TabAlignmentConfig?,indicatorAnimation: freezed == indicatorAnimation ? _self.indicatorAnimation : indicatorAnimation // ignore: cast_nullable_to_non_nullable
as TabIndicatorAnimationConfig?,splashFactory: freezed == splashFactory ? _self.splashFactory : splashFactory // ignore: cast_nullable_to_non_nullable
as TabSplashFactoryConfig?,indicatorBorder: freezed == indicatorBorder ? _self.indicatorBorder : indicatorBorder // ignore: cast_nullable_to_non_nullable
as BorderConfig?,
  ));
}

}


/// Adds pattern-matching-related methods to [TabBarConfig].
extension TabBarConfigPatterns on TabBarConfig {
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
mixin _$AppBarConfig {


/// Create a copy of AppBarConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppBarConfigCopyWith<AppBarConfig> get copyWith => _$AppBarConfigCopyWithImpl<AppBarConfig>(this as AppBarConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AppBarConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppBarConfig&&(identical(other.primary, _this.primary) || other.primary == _this.primary)&&(identical(other.showBackButton, _this.showBackButton) || other.showBackButton == _this.showBackButton)&&(identical(other.backgroundColor, _this.backgroundColor) || other.backgroundColor == _this.backgroundColor)&&(identical(other.foregroundColor, _this.foregroundColor) || other.foregroundColor == _this.foregroundColor)&&(identical(other.shadowColor, _this.shadowColor) || other.shadowColor == _this.shadowColor)&&(identical(other.surfaceTintColor, _this.surfaceTintColor) || other.surfaceTintColor == _this.surfaceTintColor)&&(identical(other.elevation, _this.elevation) || other.elevation == _this.elevation)&&(identical(other.scrolledUnderElevation, _this.scrolledUnderElevation) || other.scrolledUnderElevation == _this.scrolledUnderElevation)&&(identical(other.titleSpacing, _this.titleSpacing) || other.titleSpacing == _this.titleSpacing)&&(identical(other.leadingWidth, _this.leadingWidth) || other.leadingWidth == _this.leadingWidth)&&(identical(other.toolbarHeight, _this.toolbarHeight) || other.toolbarHeight == _this.toolbarHeight)&&(identical(other.centerTitle, _this.centerTitle) || other.centerTitle == _this.centerTitle)&&(identical(other.iconTheme, _this.iconTheme) || other.iconTheme == _this.iconTheme)&&(identical(other.actionsIconTheme, _this.actionsIconTheme) || other.actionsIconTheme == _this.actionsIconTheme)&&(identical(other.titleTextStyle, _this.titleTextStyle) || other.titleTextStyle == _this.titleTextStyle)&&(identical(other.toolbarTextStyle, _this.toolbarTextStyle) || other.toolbarTextStyle == _this.toolbarTextStyle)&&(identical(other.systemOverlayStyle, _this.systemOverlayStyle) || other.systemOverlayStyle == _this.systemOverlayStyle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AppBarConfig;
  return Object.hash(runtimeType,_this.primary,_this.showBackButton,_this.backgroundColor,_this.foregroundColor,_this.shadowColor,_this.surfaceTintColor,_this.elevation,_this.scrolledUnderElevation,_this.titleSpacing,_this.leadingWidth,_this.toolbarHeight,_this.centerTitle,_this.iconTheme,_this.actionsIconTheme,_this.titleTextStyle,_this.toolbarTextStyle,_this.systemOverlayStyle);
}

@override
String toString() {
  final _this = this as AppBarConfig;
  return 'AppBarConfig(primary: ${_this.primary}, showBackButton: ${_this.showBackButton}, backgroundColor: ${_this.backgroundColor}, foregroundColor: ${_this.foregroundColor}, shadowColor: ${_this.shadowColor}, surfaceTintColor: ${_this.surfaceTintColor}, elevation: ${_this.elevation}, scrolledUnderElevation: ${_this.scrolledUnderElevation}, titleSpacing: ${_this.titleSpacing}, leadingWidth: ${_this.leadingWidth}, toolbarHeight: ${_this.toolbarHeight}, centerTitle: ${_this.centerTitle}, iconTheme: ${_this.iconTheme}, actionsIconTheme: ${_this.actionsIconTheme}, titleTextStyle: ${_this.titleTextStyle}, toolbarTextStyle: ${_this.toolbarTextStyle}, systemOverlayStyle: ${_this.systemOverlayStyle})';
}


}

/// @nodoc
abstract mixin class $AppBarConfigCopyWith<$Res>  {
  factory $AppBarConfigCopyWith(AppBarConfig value, $Res Function(AppBarConfig) _then) = _$AppBarConfigCopyWithImpl;
@useResult
$Res call({
 bool primary, bool showBackButton, String? backgroundColor, String? foregroundColor, String? shadowColor, String? surfaceTintColor, double? elevation, double? scrolledUnderElevation, double? titleSpacing, double? leadingWidth, double? toolbarHeight, bool? centerTitle, IconThemeDataConfig? iconTheme, IconThemeDataConfig? actionsIconTheme, TextStyleConfig? titleTextStyle, TextStyleConfig? toolbarTextStyle, OverlayStyleModel? systemOverlayStyle
});




}
/// @nodoc
class _$AppBarConfigCopyWithImpl<$Res>
    implements $AppBarConfigCopyWith<$Res> {
  _$AppBarConfigCopyWithImpl(this._self, this._then);

  final AppBarConfig _self;
  final $Res Function(AppBarConfig) _then;

/// Create a copy of AppBarConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? primary = null,Object? showBackButton = null,Object? backgroundColor = freezed,Object? foregroundColor = freezed,Object? shadowColor = freezed,Object? surfaceTintColor = freezed,Object? elevation = freezed,Object? scrolledUnderElevation = freezed,Object? titleSpacing = freezed,Object? leadingWidth = freezed,Object? toolbarHeight = freezed,Object? centerTitle = freezed,Object? iconTheme = freezed,Object? actionsIconTheme = freezed,Object? titleTextStyle = freezed,Object? toolbarTextStyle = freezed,Object? systemOverlayStyle = freezed,}) {
  return _then(AppBarConfig(
primary: null == primary ? _self.primary : primary // ignore: cast_nullable_to_non_nullable
as bool,showBackButton: null == showBackButton ? _self.showBackButton : showBackButton // ignore: cast_nullable_to_non_nullable
as bool,backgroundColor: freezed == backgroundColor ? _self.backgroundColor : backgroundColor // ignore: cast_nullable_to_non_nullable
as String?,foregroundColor: freezed == foregroundColor ? _self.foregroundColor : foregroundColor // ignore: cast_nullable_to_non_nullable
as String?,shadowColor: freezed == shadowColor ? _self.shadowColor : shadowColor // ignore: cast_nullable_to_non_nullable
as String?,surfaceTintColor: freezed == surfaceTintColor ? _self.surfaceTintColor : surfaceTintColor // ignore: cast_nullable_to_non_nullable
as String?,elevation: freezed == elevation ? _self.elevation : elevation // ignore: cast_nullable_to_non_nullable
as double?,scrolledUnderElevation: freezed == scrolledUnderElevation ? _self.scrolledUnderElevation : scrolledUnderElevation // ignore: cast_nullable_to_non_nullable
as double?,titleSpacing: freezed == titleSpacing ? _self.titleSpacing : titleSpacing // ignore: cast_nullable_to_non_nullable
as double?,leadingWidth: freezed == leadingWidth ? _self.leadingWidth : leadingWidth // ignore: cast_nullable_to_non_nullable
as double?,toolbarHeight: freezed == toolbarHeight ? _self.toolbarHeight : toolbarHeight // ignore: cast_nullable_to_non_nullable
as double?,centerTitle: freezed == centerTitle ? _self.centerTitle : centerTitle // ignore: cast_nullable_to_non_nullable
as bool?,iconTheme: freezed == iconTheme ? _self.iconTheme : iconTheme // ignore: cast_nullable_to_non_nullable
as IconThemeDataConfig?,actionsIconTheme: freezed == actionsIconTheme ? _self.actionsIconTheme : actionsIconTheme // ignore: cast_nullable_to_non_nullable
as IconThemeDataConfig?,titleTextStyle: freezed == titleTextStyle ? _self.titleTextStyle : titleTextStyle // ignore: cast_nullable_to_non_nullable
as TextStyleConfig?,toolbarTextStyle: freezed == toolbarTextStyle ? _self.toolbarTextStyle : toolbarTextStyle // ignore: cast_nullable_to_non_nullable
as TextStyleConfig?,systemOverlayStyle: freezed == systemOverlayStyle ? _self.systemOverlayStyle : systemOverlayStyle // ignore: cast_nullable_to_non_nullable
as OverlayStyleModel?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppBarConfig].
extension AppBarConfigPatterns on AppBarConfig {
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
