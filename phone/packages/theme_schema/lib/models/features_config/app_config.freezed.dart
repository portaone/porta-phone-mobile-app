// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppConfig {


/// Create a copy of AppConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppConfigCopyWith<AppConfig> get copyWith => _$AppConfigCopyWithImpl<AppConfig>(this as AppConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AppConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppConfig&&(identical(other.loginConfig, _this.loginConfig) || other.loginConfig == _this.loginConfig)&&(identical(other.mainConfig, _this.mainConfig) || other.mainConfig == _this.mainConfig)&&(identical(other.settingsConfig, _this.settingsConfig) || other.settingsConfig == _this.settingsConfig)&&(identical(other.callConfig, _this.callConfig) || other.callConfig == _this.callConfig)&&(identical(other.contacts, _this.contacts) || other.contacts == _this.contacts)&&(identical(other.messaging, _this.messaging) || other.messaging == _this.messaging)&&const DeepCollectionEquality().equals(other.supported, _this.supported));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AppConfig;
  return Object.hash(runtimeType,_this.loginConfig,_this.mainConfig,_this.settingsConfig,_this.callConfig,_this.contacts,_this.messaging,const DeepCollectionEquality().hash(_this.supported));
}

@override
String toString() {
  final _this = this as AppConfig;
  return 'AppConfig(loginConfig: ${_this.loginConfig}, mainConfig: ${_this.mainConfig}, settingsConfig: ${_this.settingsConfig}, callConfig: ${_this.callConfig}, contacts: ${_this.contacts}, messaging: ${_this.messaging}, supported: ${_this.supported})';
}


}

/// @nodoc
abstract mixin class $AppConfigCopyWith<$Res>  {
  factory $AppConfigCopyWith(AppConfig value, $Res Function(AppConfig) _then) = _$AppConfigCopyWithImpl;
@useResult
$Res call({
 AppConfigLogin loginConfig, AppConfigMain mainConfig, AppConfigSettings settingsConfig, AppConfigCall callConfig, AppConfigContacts contacts, AppConfigMessaging messaging, List<SupportedFeature> supported
});




}
/// @nodoc
class _$AppConfigCopyWithImpl<$Res>
    implements $AppConfigCopyWith<$Res> {
  _$AppConfigCopyWithImpl(this._self, this._then);

  final AppConfig _self;
  final $Res Function(AppConfig) _then;

/// Create a copy of AppConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? loginConfig = null,Object? mainConfig = null,Object? settingsConfig = null,Object? callConfig = null,Object? contacts = null,Object? messaging = null,Object? supported = null,}) {
  return _then(AppConfig(
loginConfig: null == loginConfig ? _self.loginConfig : loginConfig // ignore: cast_nullable_to_non_nullable
as AppConfigLogin,mainConfig: null == mainConfig ? _self.mainConfig : mainConfig // ignore: cast_nullable_to_non_nullable
as AppConfigMain,settingsConfig: null == settingsConfig ? _self.settingsConfig : settingsConfig // ignore: cast_nullable_to_non_nullable
as AppConfigSettings,callConfig: null == callConfig ? _self.callConfig : callConfig // ignore: cast_nullable_to_non_nullable
as AppConfigCall,contacts: null == contacts ? _self.contacts : contacts // ignore: cast_nullable_to_non_nullable
as AppConfigContacts,messaging: null == messaging ? _self.messaging : messaging // ignore: cast_nullable_to_non_nullable
as AppConfigMessaging,supported: null == supported ? _self.supported : supported // ignore: cast_nullable_to_non_nullable
as List<SupportedFeature>,
  ));
}

}


/// Adds pattern-matching-related methods to [AppConfig].
extension AppConfigPatterns on AppConfig {
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
mixin _$AppConfigLogin {


/// Create a copy of AppConfigLogin
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppConfigLoginCopyWith<AppConfigLogin> get copyWith => _$AppConfigLoginCopyWithImpl<AppConfigLogin>(this as AppConfigLogin, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AppConfigLogin;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppConfigLogin&&(identical(other.common, _this.common) || other.common == _this.common)&&(identical(other.modeSelect, _this.modeSelect) || other.modeSelect == _this.modeSelect)&&const DeepCollectionEquality().equals(other.signinOrder, _this.signinOrder)&&(identical(other.qr, _this.qr) || other.qr == _this.qr));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AppConfigLogin;
  return Object.hash(runtimeType,_this.common,_this.modeSelect,const DeepCollectionEquality().hash(_this.signinOrder),_this.qr);
}

@override
String toString() {
  final _this = this as AppConfigLogin;
  return 'AppConfigLogin(common: ${_this.common}, modeSelect: ${_this.modeSelect}, signinOrder: ${_this.signinOrder}, qr: ${_this.qr})';
}


}

/// @nodoc
abstract mixin class $AppConfigLoginCopyWith<$Res>  {
  factory $AppConfigLoginCopyWith(AppConfigLogin value, $Res Function(AppConfigLogin) _then) = _$AppConfigLoginCopyWithImpl;
@useResult
$Res call({
 AppConfigLoginCommon common, AppConfigLoginModeSelect modeSelect, List<String> signinOrder, AppConfigLoginQr qr
});




}
/// @nodoc
class _$AppConfigLoginCopyWithImpl<$Res>
    implements $AppConfigLoginCopyWith<$Res> {
  _$AppConfigLoginCopyWithImpl(this._self, this._then);

  final AppConfigLogin _self;
  final $Res Function(AppConfigLogin) _then;

/// Create a copy of AppConfigLogin
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? common = null,Object? modeSelect = null,Object? signinOrder = null,Object? qr = null,}) {
  return _then(AppConfigLogin(
common: null == common ? _self.common : common // ignore: cast_nullable_to_non_nullable
as AppConfigLoginCommon,modeSelect: null == modeSelect ? _self.modeSelect : modeSelect // ignore: cast_nullable_to_non_nullable
as AppConfigLoginModeSelect,signinOrder: null == signinOrder ? _self.signinOrder : signinOrder // ignore: cast_nullable_to_non_nullable
as List<String>,qr: null == qr ? _self.qr : qr // ignore: cast_nullable_to_non_nullable
as AppConfigLoginQr,
  ));
}

}


/// Adds pattern-matching-related methods to [AppConfigLogin].
extension AppConfigLoginPatterns on AppConfigLogin {
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
mixin _$AppConfigLoginQr {


/// Create a copy of AppConfigLoginQr
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppConfigLoginQrCopyWith<AppConfigLoginQr> get copyWith => _$AppConfigLoginQrCopyWithImpl<AppConfigLoginQr>(this as AppConfigLoginQr, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AppConfigLoginQr;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppConfigLoginQr&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled)&&const DeepCollectionEquality().equals(other.formats, _this.formats)&&(identical(other.expectedHost, _this.expectedHost) || other.expectedHost == _this.expectedHost));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AppConfigLoginQr;
  return Object.hash(runtimeType,_this.enabled,const DeepCollectionEquality().hash(_this.formats),_this.expectedHost);
}

@override
String toString() {
  final _this = this as AppConfigLoginQr;
  return 'AppConfigLoginQr(enabled: ${_this.enabled}, formats: ${_this.formats}, expectedHost: ${_this.expectedHost})';
}


}

/// @nodoc
abstract mixin class $AppConfigLoginQrCopyWith<$Res>  {
  factory $AppConfigLoginQrCopyWith(AppConfigLoginQr value, $Res Function(AppConfigLoginQr) _then) = _$AppConfigLoginQrCopyWithImpl;
@useResult
$Res call({
 bool enabled, List<AppConfigLoginQrFormat> formats, String? expectedHost
});




}
/// @nodoc
class _$AppConfigLoginQrCopyWithImpl<$Res>
    implements $AppConfigLoginQrCopyWith<$Res> {
  _$AppConfigLoginQrCopyWithImpl(this._self, this._then);

  final AppConfigLoginQr _self;
  final $Res Function(AppConfigLoginQr) _then;

/// Create a copy of AppConfigLoginQr
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,Object? formats = null,Object? expectedHost = freezed,}) {
  return _then(AppConfigLoginQr(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,formats: null == formats ? _self.formats : formats // ignore: cast_nullable_to_non_nullable
as List<AppConfigLoginQrFormat>,expectedHost: freezed == expectedHost ? _self.expectedHost : expectedHost // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppConfigLoginQr].
extension AppConfigLoginQrPatterns on AppConfigLoginQr {
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
mixin _$AppConfigLoginQrFormat {


/// Create a copy of AppConfigLoginQrFormat
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppConfigLoginQrFormatCopyWith<AppConfigLoginQrFormat> get copyWith => _$AppConfigLoginQrFormatCopyWithImpl<AppConfigLoginQrFormat>(this as AppConfigLoginQrFormat, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AppConfigLoginQrFormat;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppConfigLoginQrFormat&&(identical(other.type, _this.type) || other.type == _this.type)&&const DeepCollectionEquality().equals(other.schemes, _this.schemes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AppConfigLoginQrFormat;
  return Object.hash(runtimeType,_this.type,const DeepCollectionEquality().hash(_this.schemes));
}

@override
String toString() {
  final _this = this as AppConfigLoginQrFormat;
  return 'AppConfigLoginQrFormat(type: ${_this.type}, schemes: ${_this.schemes})';
}


}

/// @nodoc
abstract mixin class $AppConfigLoginQrFormatCopyWith<$Res>  {
  factory $AppConfigLoginQrFormatCopyWith(AppConfigLoginQrFormat value, $Res Function(AppConfigLoginQrFormat) _then) = _$AppConfigLoginQrFormatCopyWithImpl;
@useResult
$Res call({
 String type, List<String>? schemes
});




}
/// @nodoc
class _$AppConfigLoginQrFormatCopyWithImpl<$Res>
    implements $AppConfigLoginQrFormatCopyWith<$Res> {
  _$AppConfigLoginQrFormatCopyWithImpl(this._self, this._then);

  final AppConfigLoginQrFormat _self;
  final $Res Function(AppConfigLoginQrFormat) _then;

/// Create a copy of AppConfigLoginQrFormat
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? schemes = freezed,}) {
  return _then(AppConfigLoginQrFormat(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,schemes: freezed == schemes ? _self.schemes : schemes // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppConfigLoginQrFormat].
extension AppConfigLoginQrFormatPatterns on AppConfigLoginQrFormat {
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
mixin _$AppConfigLoginCommon {


/// Create a copy of AppConfigLoginCommon
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppConfigLoginCommonCopyWith<AppConfigLoginCommon> get copyWith => _$AppConfigLoginCommonCopyWithImpl<AppConfigLoginCommon>(this as AppConfigLoginCommon, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AppConfigLoginCommon;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppConfigLoginCommon&&(identical(other.fullScreenLaunchEmbeddedResourceId, _this.fullScreenLaunchEmbeddedResourceId) || other.fullScreenLaunchEmbeddedResourceId == _this.fullScreenLaunchEmbeddedResourceId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AppConfigLoginCommon;
  return Object.hash(runtimeType,_this.fullScreenLaunchEmbeddedResourceId);
}

@override
String toString() {
  final _this = this as AppConfigLoginCommon;
  return 'AppConfigLoginCommon(fullScreenLaunchEmbeddedResourceId: ${_this.fullScreenLaunchEmbeddedResourceId})';
}


}

/// @nodoc
abstract mixin class $AppConfigLoginCommonCopyWith<$Res>  {
  factory $AppConfigLoginCommonCopyWith(AppConfigLoginCommon value, $Res Function(AppConfigLoginCommon) _then) = _$AppConfigLoginCommonCopyWithImpl;
@useResult
$Res call({
 String? fullScreenLaunchEmbeddedResourceId
});




}
/// @nodoc
class _$AppConfigLoginCommonCopyWithImpl<$Res>
    implements $AppConfigLoginCommonCopyWith<$Res> {
  _$AppConfigLoginCommonCopyWithImpl(this._self, this._then);

  final AppConfigLoginCommon _self;
  final $Res Function(AppConfigLoginCommon) _then;

/// Create a copy of AppConfigLoginCommon
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fullScreenLaunchEmbeddedResourceId = freezed,}) {
  return _then(AppConfigLoginCommon(
fullScreenLaunchEmbeddedResourceId: freezed == fullScreenLaunchEmbeddedResourceId ? _self.fullScreenLaunchEmbeddedResourceId : fullScreenLaunchEmbeddedResourceId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppConfigLoginCommon].
extension AppConfigLoginCommonPatterns on AppConfigLoginCommon {
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
mixin _$AppConfigLoginModeSelect {


/// Create a copy of AppConfigLoginModeSelect
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppConfigLoginModeSelectCopyWith<AppConfigLoginModeSelect> get copyWith => _$AppConfigLoginModeSelectCopyWithImpl<AppConfigLoginModeSelect>(this as AppConfigLoginModeSelect, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AppConfigLoginModeSelect;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppConfigLoginModeSelect&&(identical(other.greetingL10n, _this.greetingL10n) || other.greetingL10n == _this.greetingL10n)&&const DeepCollectionEquality().equals(other.actions, _this.actions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AppConfigLoginModeSelect;
  return Object.hash(runtimeType,_this.greetingL10n,const DeepCollectionEquality().hash(_this.actions));
}

@override
String toString() {
  final _this = this as AppConfigLoginModeSelect;
  return 'AppConfigLoginModeSelect(greetingL10n: ${_this.greetingL10n}, actions: ${_this.actions})';
}


}

/// @nodoc
abstract mixin class $AppConfigLoginModeSelectCopyWith<$Res>  {
  factory $AppConfigLoginModeSelectCopyWith(AppConfigLoginModeSelect value, $Res Function(AppConfigLoginModeSelect) _then) = _$AppConfigLoginModeSelectCopyWithImpl;
@useResult
$Res call({
 String? greetingL10n, List<AppConfigModeSelectAction> actions
});




}
/// @nodoc
class _$AppConfigLoginModeSelectCopyWithImpl<$Res>
    implements $AppConfigLoginModeSelectCopyWith<$Res> {
  _$AppConfigLoginModeSelectCopyWithImpl(this._self, this._then);

  final AppConfigLoginModeSelect _self;
  final $Res Function(AppConfigLoginModeSelect) _then;

/// Create a copy of AppConfigLoginModeSelect
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? greetingL10n = freezed,Object? actions = null,}) {
  return _then(AppConfigLoginModeSelect(
greetingL10n: freezed == greetingL10n ? _self.greetingL10n : greetingL10n // ignore: cast_nullable_to_non_nullable
as String?,actions: null == actions ? _self.actions : actions // ignore: cast_nullable_to_non_nullable
as List<AppConfigModeSelectAction>,
  ));
}

}


/// Adds pattern-matching-related methods to [AppConfigLoginModeSelect].
extension AppConfigLoginModeSelectPatterns on AppConfigLoginModeSelect {
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
mixin _$AppConfigModeSelectAction {


/// Create a copy of AppConfigModeSelectAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppConfigModeSelectActionCopyWith<AppConfigModeSelectAction> get copyWith => _$AppConfigModeSelectActionCopyWithImpl<AppConfigModeSelectAction>(this as AppConfigModeSelectAction, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AppConfigModeSelectAction;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppConfigModeSelectAction&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.titleL10n, _this.titleL10n) || other.titleL10n == _this.titleL10n)&&(identical(other.embeddedId, _this.embeddedId) || other.embeddedId == _this.embeddedId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AppConfigModeSelectAction;
  return Object.hash(runtimeType,_this.enabled,_this.type,_this.titleL10n,_this.embeddedId);
}

@override
String toString() {
  final _this = this as AppConfigModeSelectAction;
  return 'AppConfigModeSelectAction(enabled: ${_this.enabled}, type: ${_this.type}, titleL10n: ${_this.titleL10n}, embeddedId: ${_this.embeddedId})';
}


}

/// @nodoc
abstract mixin class $AppConfigModeSelectActionCopyWith<$Res>  {
  factory $AppConfigModeSelectActionCopyWith(AppConfigModeSelectAction value, $Res Function(AppConfigModeSelectAction) _then) = _$AppConfigModeSelectActionCopyWithImpl;
@useResult
$Res call({
 bool enabled, String type, String titleL10n, String? embeddedId
});




}
/// @nodoc
class _$AppConfigModeSelectActionCopyWithImpl<$Res>
    implements $AppConfigModeSelectActionCopyWith<$Res> {
  _$AppConfigModeSelectActionCopyWithImpl(this._self, this._then);

  final AppConfigModeSelectAction _self;
  final $Res Function(AppConfigModeSelectAction) _then;

/// Create a copy of AppConfigModeSelectAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,Object? type = null,Object? titleL10n = null,Object? embeddedId = freezed,}) {
  return _then(AppConfigModeSelectAction(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,titleL10n: null == titleL10n ? _self.titleL10n : titleL10n // ignore: cast_nullable_to_non_nullable
as String,embeddedId: freezed == embeddedId ? _self.embeddedId : embeddedId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppConfigModeSelectAction].
extension AppConfigModeSelectActionPatterns on AppConfigModeSelectAction {
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
mixin _$AppConfigMain {


/// Create a copy of AppConfigMain
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppConfigMainCopyWith<AppConfigMain> get copyWith => _$AppConfigMainCopyWithImpl<AppConfigMain>(this as AppConfigMain, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AppConfigMain;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppConfigMain&&(identical(other.bottomMenu, _this.bottomMenu) || other.bottomMenu == _this.bottomMenu));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AppConfigMain;
  return Object.hash(runtimeType,_this.bottomMenu);
}

@override
String toString() {
  final _this = this as AppConfigMain;
  return 'AppConfigMain(bottomMenu: ${_this.bottomMenu})';
}


}

/// @nodoc
abstract mixin class $AppConfigMainCopyWith<$Res>  {
  factory $AppConfigMainCopyWith(AppConfigMain value, $Res Function(AppConfigMain) _then) = _$AppConfigMainCopyWithImpl;
@useResult
$Res call({
 AppConfigBottomMenu bottomMenu
});




}
/// @nodoc
class _$AppConfigMainCopyWithImpl<$Res>
    implements $AppConfigMainCopyWith<$Res> {
  _$AppConfigMainCopyWithImpl(this._self, this._then);

  final AppConfigMain _self;
  final $Res Function(AppConfigMain) _then;

/// Create a copy of AppConfigMain
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bottomMenu = null,}) {
  return _then(AppConfigMain(
bottomMenu: null == bottomMenu ? _self.bottomMenu : bottomMenu // ignore: cast_nullable_to_non_nullable
as AppConfigBottomMenu,
  ));
}

}


/// Adds pattern-matching-related methods to [AppConfigMain].
extension AppConfigMainPatterns on AppConfigMain {
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
mixin _$AppConfigBottomMenu {


/// Create a copy of AppConfigBottomMenu
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppConfigBottomMenuCopyWith<AppConfigBottomMenu> get copyWith => _$AppConfigBottomMenuCopyWithImpl<AppConfigBottomMenu>(this as AppConfigBottomMenu, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AppConfigBottomMenu;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppConfigBottomMenu&&(identical(other.cacheSelectedTab, _this.cacheSelectedTab) || other.cacheSelectedTab == _this.cacheSelectedTab)&&const DeepCollectionEquality().equals(other.tabs, _this.tabs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AppConfigBottomMenu;
  return Object.hash(runtimeType,_this.cacheSelectedTab,const DeepCollectionEquality().hash(_this.tabs));
}

@override
String toString() {
  final _this = this as AppConfigBottomMenu;
  return 'AppConfigBottomMenu(cacheSelectedTab: ${_this.cacheSelectedTab}, tabs: ${_this.tabs})';
}


}

/// @nodoc
abstract mixin class $AppConfigBottomMenuCopyWith<$Res>  {
  factory $AppConfigBottomMenuCopyWith(AppConfigBottomMenu value, $Res Function(AppConfigBottomMenu) _then) = _$AppConfigBottomMenuCopyWithImpl;
@useResult
$Res call({
 bool cacheSelectedTab, List<BottomMenuTabScheme> tabs
});




}
/// @nodoc
class _$AppConfigBottomMenuCopyWithImpl<$Res>
    implements $AppConfigBottomMenuCopyWith<$Res> {
  _$AppConfigBottomMenuCopyWithImpl(this._self, this._then);

  final AppConfigBottomMenu _self;
  final $Res Function(AppConfigBottomMenu) _then;

/// Create a copy of AppConfigBottomMenu
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cacheSelectedTab = null,Object? tabs = null,}) {
  return _then(AppConfigBottomMenu(
cacheSelectedTab: null == cacheSelectedTab ? _self.cacheSelectedTab : cacheSelectedTab // ignore: cast_nullable_to_non_nullable
as bool,tabs: null == tabs ? _self.tabs : tabs // ignore: cast_nullable_to_non_nullable
as List<BottomMenuTabScheme>,
  ));
}

}


/// Adds pattern-matching-related methods to [AppConfigBottomMenu].
extension AppConfigBottomMenuPatterns on AppConfigBottomMenu {
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
mixin _$AppConfigCall {


/// Create a copy of AppConfigCall
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppConfigCallCopyWith<AppConfigCall> get copyWith => _$AppConfigCallCopyWithImpl<AppConfigCall>(this as AppConfigCall, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AppConfigCall;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppConfigCall&&(identical(other.videoEnabled, _this.videoEnabled) || other.videoEnabled == _this.videoEnabled)&&(identical(other.transfer, _this.transfer) || other.transfer == _this.transfer)&&(identical(other.encoding, _this.encoding) || other.encoding == _this.encoding)&&(identical(other.peerConnection, _this.peerConnection) || other.peerConnection == _this.peerConnection)&&(identical(other.ice, _this.ice) || other.ice == _this.ice)&&(identical(other.audio, _this.audio) || other.audio == _this.audio));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AppConfigCall;
  return Object.hash(runtimeType,_this.videoEnabled,_this.transfer,_this.encoding,_this.peerConnection,_this.ice,_this.audio);
}

@override
String toString() {
  final _this = this as AppConfigCall;
  return 'AppConfigCall(videoEnabled: ${_this.videoEnabled}, transfer: ${_this.transfer}, encoding: ${_this.encoding}, peerConnection: ${_this.peerConnection}, ice: ${_this.ice}, audio: ${_this.audio})';
}


}

/// @nodoc
abstract mixin class $AppConfigCallCopyWith<$Res>  {
  factory $AppConfigCallCopyWith(AppConfigCall value, $Res Function(AppConfigCall) _then) = _$AppConfigCallCopyWithImpl;
@useResult
$Res call({
 bool videoEnabled, AppConfigTransfer transfer, AppConfigEncoding encoding, AppConfigPeerConnection peerConnection, AppConfigIce ice, AppConfigCallAudio audio
});




}
/// @nodoc
class _$AppConfigCallCopyWithImpl<$Res>
    implements $AppConfigCallCopyWith<$Res> {
  _$AppConfigCallCopyWithImpl(this._self, this._then);

  final AppConfigCall _self;
  final $Res Function(AppConfigCall) _then;

/// Create a copy of AppConfigCall
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? videoEnabled = null,Object? transfer = null,Object? encoding = null,Object? peerConnection = null,Object? ice = null,Object? audio = null,}) {
  return _then(AppConfigCall(
videoEnabled: null == videoEnabled ? _self.videoEnabled : videoEnabled // ignore: cast_nullable_to_non_nullable
as bool,transfer: null == transfer ? _self.transfer : transfer // ignore: cast_nullable_to_non_nullable
as AppConfigTransfer,encoding: null == encoding ? _self.encoding : encoding // ignore: cast_nullable_to_non_nullable
as AppConfigEncoding,peerConnection: null == peerConnection ? _self.peerConnection : peerConnection // ignore: cast_nullable_to_non_nullable
as AppConfigPeerConnection,ice: null == ice ? _self.ice : ice // ignore: cast_nullable_to_non_nullable
as AppConfigIce,audio: null == audio ? _self.audio : audio // ignore: cast_nullable_to_non_nullable
as AppConfigCallAudio,
  ));
}

}


/// Adds pattern-matching-related methods to [AppConfigCall].
extension AppConfigCallPatterns on AppConfigCall {
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
mixin _$AppConfigTransfer {


/// Create a copy of AppConfigTransfer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppConfigTransferCopyWith<AppConfigTransfer> get copyWith => _$AppConfigTransferCopyWithImpl<AppConfigTransfer>(this as AppConfigTransfer, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AppConfigTransfer;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppConfigTransfer&&(identical(other.enableBlindTransfer, _this.enableBlindTransfer) || other.enableBlindTransfer == _this.enableBlindTransfer)&&(identical(other.enableAttendedTransfer, _this.enableAttendedTransfer) || other.enableAttendedTransfer == _this.enableAttendedTransfer));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AppConfigTransfer;
  return Object.hash(runtimeType,_this.enableBlindTransfer,_this.enableAttendedTransfer);
}

@override
String toString() {
  final _this = this as AppConfigTransfer;
  return 'AppConfigTransfer(enableBlindTransfer: ${_this.enableBlindTransfer}, enableAttendedTransfer: ${_this.enableAttendedTransfer})';
}


}

/// @nodoc
abstract mixin class $AppConfigTransferCopyWith<$Res>  {
  factory $AppConfigTransferCopyWith(AppConfigTransfer value, $Res Function(AppConfigTransfer) _then) = _$AppConfigTransferCopyWithImpl;
@useResult
$Res call({
 bool enableBlindTransfer, bool enableAttendedTransfer
});




}
/// @nodoc
class _$AppConfigTransferCopyWithImpl<$Res>
    implements $AppConfigTransferCopyWith<$Res> {
  _$AppConfigTransferCopyWithImpl(this._self, this._then);

  final AppConfigTransfer _self;
  final $Res Function(AppConfigTransfer) _then;

/// Create a copy of AppConfigTransfer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enableBlindTransfer = null,Object? enableAttendedTransfer = null,}) {
  return _then(AppConfigTransfer(
enableBlindTransfer: null == enableBlindTransfer ? _self.enableBlindTransfer : enableBlindTransfer // ignore: cast_nullable_to_non_nullable
as bool,enableAttendedTransfer: null == enableAttendedTransfer ? _self.enableAttendedTransfer : enableAttendedTransfer // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AppConfigTransfer].
extension AppConfigTransferPatterns on AppConfigTransfer {
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
mixin _$AppConfigEncoding {


/// Create a copy of AppConfigEncoding
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppConfigEncodingCopyWith<AppConfigEncoding> get copyWith => _$AppConfigEncodingCopyWithImpl<AppConfigEncoding>(this as AppConfigEncoding, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AppConfigEncoding;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppConfigEncoding&&(identical(other.bypassConfig, _this.bypassConfig) || other.bypassConfig == _this.bypassConfig)&&(identical(other.defaultPresetOverride, _this.defaultPresetOverride) || other.defaultPresetOverride == _this.defaultPresetOverride)&&const DeepCollectionEquality().equals(other.conferenceAudioCodecs, _this.conferenceAudioCodecs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AppConfigEncoding;
  return Object.hash(runtimeType,_this.bypassConfig,_this.defaultPresetOverride,const DeepCollectionEquality().hash(_this.conferenceAudioCodecs));
}

@override
String toString() {
  final _this = this as AppConfigEncoding;
  return 'AppConfigEncoding(bypassConfig: ${_this.bypassConfig}, defaultPresetOverride: ${_this.defaultPresetOverride}, conferenceAudioCodecs: ${_this.conferenceAudioCodecs})';
}


}

/// @nodoc
abstract mixin class $AppConfigEncodingCopyWith<$Res>  {
  factory $AppConfigEncodingCopyWith(AppConfigEncoding value, $Res Function(AppConfigEncoding) _then) = _$AppConfigEncodingCopyWithImpl;
@useResult
$Res call({
 bool bypassConfig, EncodingDefaultPresetOverride defaultPresetOverride, List<String>? conferenceAudioCodecs
});




}
/// @nodoc
class _$AppConfigEncodingCopyWithImpl<$Res>
    implements $AppConfigEncodingCopyWith<$Res> {
  _$AppConfigEncodingCopyWithImpl(this._self, this._then);

  final AppConfigEncoding _self;
  final $Res Function(AppConfigEncoding) _then;

/// Create a copy of AppConfigEncoding
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bypassConfig = null,Object? defaultPresetOverride = null,Object? conferenceAudioCodecs = freezed,}) {
  return _then(AppConfigEncoding(
bypassConfig: null == bypassConfig ? _self.bypassConfig : bypassConfig // ignore: cast_nullable_to_non_nullable
as bool,defaultPresetOverride: null == defaultPresetOverride ? _self.defaultPresetOverride : defaultPresetOverride // ignore: cast_nullable_to_non_nullable
as EncodingDefaultPresetOverride,conferenceAudioCodecs: freezed == conferenceAudioCodecs ? _self.conferenceAudioCodecs : conferenceAudioCodecs // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppConfigEncoding].
extension AppConfigEncodingPatterns on AppConfigEncoding {
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
mixin _$AppConfigIce {


/// Create a copy of AppConfigIce
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppConfigIceCopyWith<AppConfigIce> get copyWith => _$AppConfigIceCopyWithImpl<AppConfigIce>(this as AppConfigIce, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AppConfigIce;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppConfigIce&&(identical(other.certificateVerification, _this.certificateVerification) || other.certificateVerification == _this.certificateVerification)&&(identical(other.certificateVerificationConfigurable, _this.certificateVerificationConfigurable) || other.certificateVerificationConfigurable == _this.certificateVerificationConfigurable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AppConfigIce;
  return Object.hash(runtimeType,_this.certificateVerification,_this.certificateVerificationConfigurable);
}

@override
String toString() {
  final _this = this as AppConfigIce;
  return 'AppConfigIce(certificateVerification: ${_this.certificateVerification}, certificateVerificationConfigurable: ${_this.certificateVerificationConfigurable})';
}


}

/// @nodoc
abstract mixin class $AppConfigIceCopyWith<$Res>  {
  factory $AppConfigIceCopyWith(AppConfigIce value, $Res Function(AppConfigIce) _then) = _$AppConfigIceCopyWithImpl;
@useResult
$Res call({
 String certificateVerification, bool certificateVerificationConfigurable
});




}
/// @nodoc
class _$AppConfigIceCopyWithImpl<$Res>
    implements $AppConfigIceCopyWith<$Res> {
  _$AppConfigIceCopyWithImpl(this._self, this._then);

  final AppConfigIce _self;
  final $Res Function(AppConfigIce) _then;

/// Create a copy of AppConfigIce
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? certificateVerification = null,Object? certificateVerificationConfigurable = null,}) {
  return _then(AppConfigIce(
certificateVerification: null == certificateVerification ? _self.certificateVerification : certificateVerification // ignore: cast_nullable_to_non_nullable
as String,certificateVerificationConfigurable: null == certificateVerificationConfigurable ? _self.certificateVerificationConfigurable : certificateVerificationConfigurable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AppConfigIce].
extension AppConfigIcePatterns on AppConfigIce {
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
mixin _$AppConfigCallAudio {


/// Create a copy of AppConfigCallAudio
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppConfigCallAudioCopyWith<AppConfigCallAudio> get copyWith => _$AppConfigCallAudioCopyWithImpl<AppConfigCallAudio>(this as AppConfigCallAudio, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AppConfigCallAudio;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppConfigCallAudio&&(identical(other.speakerOnMinimize, _this.speakerOnMinimize) || other.speakerOnMinimize == _this.speakerOnMinimize)&&(identical(other.speakerOnMinimizeConfigurable, _this.speakerOnMinimizeConfigurable) || other.speakerOnMinimizeConfigurable == _this.speakerOnMinimizeConfigurable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AppConfigCallAudio;
  return Object.hash(runtimeType,_this.speakerOnMinimize,_this.speakerOnMinimizeConfigurable);
}

@override
String toString() {
  final _this = this as AppConfigCallAudio;
  return 'AppConfigCallAudio(speakerOnMinimize: ${_this.speakerOnMinimize}, speakerOnMinimizeConfigurable: ${_this.speakerOnMinimizeConfigurable})';
}


}

/// @nodoc
abstract mixin class $AppConfigCallAudioCopyWith<$Res>  {
  factory $AppConfigCallAudioCopyWith(AppConfigCallAudio value, $Res Function(AppConfigCallAudio) _then) = _$AppConfigCallAudioCopyWithImpl;
@useResult
$Res call({
 bool speakerOnMinimize, bool speakerOnMinimizeConfigurable
});




}
/// @nodoc
class _$AppConfigCallAudioCopyWithImpl<$Res>
    implements $AppConfigCallAudioCopyWith<$Res> {
  _$AppConfigCallAudioCopyWithImpl(this._self, this._then);

  final AppConfigCallAudio _self;
  final $Res Function(AppConfigCallAudio) _then;

/// Create a copy of AppConfigCallAudio
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? speakerOnMinimize = null,Object? speakerOnMinimizeConfigurable = null,}) {
  return _then(AppConfigCallAudio(
speakerOnMinimize: null == speakerOnMinimize ? _self.speakerOnMinimize : speakerOnMinimize // ignore: cast_nullable_to_non_nullable
as bool,speakerOnMinimizeConfigurable: null == speakerOnMinimizeConfigurable ? _self.speakerOnMinimizeConfigurable : speakerOnMinimizeConfigurable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AppConfigCallAudio].
extension AppConfigCallAudioPatterns on AppConfigCallAudio {
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
mixin _$AppConfigPeerConnection {


/// Create a copy of AppConfigPeerConnection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppConfigPeerConnectionCopyWith<AppConfigPeerConnection> get copyWith => _$AppConfigPeerConnectionCopyWithImpl<AppConfigPeerConnection>(this as AppConfigPeerConnection, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AppConfigPeerConnection;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppConfigPeerConnection&&(identical(other.negotiation, _this.negotiation) || other.negotiation == _this.negotiation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AppConfigPeerConnection;
  return Object.hash(runtimeType,_this.negotiation);
}

@override
String toString() {
  final _this = this as AppConfigPeerConnection;
  return 'AppConfigPeerConnection(negotiation: ${_this.negotiation})';
}


}

/// @nodoc
abstract mixin class $AppConfigPeerConnectionCopyWith<$Res>  {
  factory $AppConfigPeerConnectionCopyWith(AppConfigPeerConnection value, $Res Function(AppConfigPeerConnection) _then) = _$AppConfigPeerConnectionCopyWithImpl;
@useResult
$Res call({
 AppConfigNegotiationSettingsOverride negotiation
});




}
/// @nodoc
class _$AppConfigPeerConnectionCopyWithImpl<$Res>
    implements $AppConfigPeerConnectionCopyWith<$Res> {
  _$AppConfigPeerConnectionCopyWithImpl(this._self, this._then);

  final AppConfigPeerConnection _self;
  final $Res Function(AppConfigPeerConnection) _then;

/// Create a copy of AppConfigPeerConnection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? negotiation = null,}) {
  return _then(AppConfigPeerConnection(
negotiation: null == negotiation ? _self.negotiation : negotiation // ignore: cast_nullable_to_non_nullable
as AppConfigNegotiationSettingsOverride,
  ));
}

}


/// Adds pattern-matching-related methods to [AppConfigPeerConnection].
extension AppConfigPeerConnectionPatterns on AppConfigPeerConnection {
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
mixin _$AppConfigNegotiationSettingsOverride {


/// Create a copy of AppConfigNegotiationSettingsOverride
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppConfigNegotiationSettingsOverrideCopyWith<AppConfigNegotiationSettingsOverride> get copyWith => _$AppConfigNegotiationSettingsOverrideCopyWithImpl<AppConfigNegotiationSettingsOverride>(this as AppConfigNegotiationSettingsOverride, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AppConfigNegotiationSettingsOverride;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppConfigNegotiationSettingsOverride&&(identical(other.includeInactiveVideoInOfferAnswer, _this.includeInactiveVideoInOfferAnswer) || other.includeInactiveVideoInOfferAnswer == _this.includeInactiveVideoInOfferAnswer));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AppConfigNegotiationSettingsOverride;
  return Object.hash(runtimeType,_this.includeInactiveVideoInOfferAnswer);
}

@override
String toString() {
  final _this = this as AppConfigNegotiationSettingsOverride;
  return 'AppConfigNegotiationSettingsOverride(includeInactiveVideoInOfferAnswer: ${_this.includeInactiveVideoInOfferAnswer})';
}


}

/// @nodoc
abstract mixin class $AppConfigNegotiationSettingsOverrideCopyWith<$Res>  {
  factory $AppConfigNegotiationSettingsOverrideCopyWith(AppConfigNegotiationSettingsOverride value, $Res Function(AppConfigNegotiationSettingsOverride) _then) = _$AppConfigNegotiationSettingsOverrideCopyWithImpl;
@useResult
$Res call({
 bool includeInactiveVideoInOfferAnswer
});




}
/// @nodoc
class _$AppConfigNegotiationSettingsOverrideCopyWithImpl<$Res>
    implements $AppConfigNegotiationSettingsOverrideCopyWith<$Res> {
  _$AppConfigNegotiationSettingsOverrideCopyWithImpl(this._self, this._then);

  final AppConfigNegotiationSettingsOverride _self;
  final $Res Function(AppConfigNegotiationSettingsOverride) _then;

/// Create a copy of AppConfigNegotiationSettingsOverride
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? includeInactiveVideoInOfferAnswer = null,}) {
  return _then(AppConfigNegotiationSettingsOverride(
includeInactiveVideoInOfferAnswer: null == includeInactiveVideoInOfferAnswer ? _self.includeInactiveVideoInOfferAnswer : includeInactiveVideoInOfferAnswer // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AppConfigNegotiationSettingsOverride].
extension AppConfigNegotiationSettingsOverridePatterns on AppConfigNegotiationSettingsOverride {
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
mixin _$EncodingDefaultPresetOverride {


/// Create a copy of EncodingDefaultPresetOverride
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EncodingDefaultPresetOverrideCopyWith<EncodingDefaultPresetOverride> get copyWith => _$EncodingDefaultPresetOverrideCopyWithImpl<EncodingDefaultPresetOverride>(this as EncodingDefaultPresetOverride, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as EncodingDefaultPresetOverride;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EncodingDefaultPresetOverride&&(identical(other.audioBitrate, _this.audioBitrate) || other.audioBitrate == _this.audioBitrate)&&(identical(other.videoBitrate, _this.videoBitrate) || other.videoBitrate == _this.videoBitrate)&&(identical(other.ptime, _this.ptime) || other.ptime == _this.ptime)&&(identical(other.maxptime, _this.maxptime) || other.maxptime == _this.maxptime)&&(identical(other.opusSamplingRate, _this.opusSamplingRate) || other.opusSamplingRate == _this.opusSamplingRate)&&(identical(other.opusBitrate, _this.opusBitrate) || other.opusBitrate == _this.opusBitrate)&&(identical(other.opusStereo, _this.opusStereo) || other.opusStereo == _this.opusStereo)&&(identical(other.opusDtx, _this.opusDtx) || other.opusDtx == _this.opusDtx)&&(identical(other.removeStaticAudioRtpMaps, _this.removeStaticAudioRtpMaps) || other.removeStaticAudioRtpMaps == _this.removeStaticAudioRtpMaps)&&(identical(other.remapTE8payloadTo101, _this.remapTE8payloadTo101) || other.remapTE8payloadTo101 == _this.remapTE8payloadTo101)&&(identical(other.removeREMBFeedback, _this.removeREMBFeedback) || other.removeREMBFeedback == _this.removeREMBFeedback)&&(identical(other.removeTWCCFeedback, _this.removeTWCCFeedback) || other.removeTWCCFeedback == _this.removeTWCCFeedback)&&const DeepCollectionEquality().equals(other.removeExtmaps, _this.removeExtmaps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as EncodingDefaultPresetOverride;
  return Object.hash(runtimeType,_this.audioBitrate,_this.videoBitrate,_this.ptime,_this.maxptime,_this.opusSamplingRate,_this.opusBitrate,_this.opusStereo,_this.opusDtx,_this.removeStaticAudioRtpMaps,_this.remapTE8payloadTo101,_this.removeREMBFeedback,_this.removeTWCCFeedback,const DeepCollectionEquality().hash(_this.removeExtmaps));
}

@override
String toString() {
  final _this = this as EncodingDefaultPresetOverride;
  return 'EncodingDefaultPresetOverride(audioBitrate: ${_this.audioBitrate}, videoBitrate: ${_this.videoBitrate}, ptime: ${_this.ptime}, maxptime: ${_this.maxptime}, opusSamplingRate: ${_this.opusSamplingRate}, opusBitrate: ${_this.opusBitrate}, opusStereo: ${_this.opusStereo}, opusDtx: ${_this.opusDtx}, removeStaticAudioRtpMaps: ${_this.removeStaticAudioRtpMaps}, remapTE8payloadTo101: ${_this.remapTE8payloadTo101}, removeREMBFeedback: ${_this.removeREMBFeedback}, removeTWCCFeedback: ${_this.removeTWCCFeedback}, removeExtmaps: ${_this.removeExtmaps})';
}


}

/// @nodoc
abstract mixin class $EncodingDefaultPresetOverrideCopyWith<$Res>  {
  factory $EncodingDefaultPresetOverrideCopyWith(EncodingDefaultPresetOverride value, $Res Function(EncodingDefaultPresetOverride) _then) = _$EncodingDefaultPresetOverrideCopyWithImpl;
@useResult
$Res call({
 int? audioBitrate, int? videoBitrate, int? ptime, int? maxptime, int? opusSamplingRate, int? opusBitrate, bool? opusStereo, bool? opusDtx, bool? removeStaticAudioRtpMaps, bool? remapTE8payloadTo101, bool? removeREMBFeedback, bool? removeTWCCFeedback, List<String>? removeExtmaps
});




}
/// @nodoc
class _$EncodingDefaultPresetOverrideCopyWithImpl<$Res>
    implements $EncodingDefaultPresetOverrideCopyWith<$Res> {
  _$EncodingDefaultPresetOverrideCopyWithImpl(this._self, this._then);

  final EncodingDefaultPresetOverride _self;
  final $Res Function(EncodingDefaultPresetOverride) _then;

/// Create a copy of EncodingDefaultPresetOverride
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? audioBitrate = freezed,Object? videoBitrate = freezed,Object? ptime = freezed,Object? maxptime = freezed,Object? opusSamplingRate = freezed,Object? opusBitrate = freezed,Object? opusStereo = freezed,Object? opusDtx = freezed,Object? removeStaticAudioRtpMaps = freezed,Object? remapTE8payloadTo101 = freezed,Object? removeREMBFeedback = freezed,Object? removeTWCCFeedback = freezed,Object? removeExtmaps = freezed,}) {
  return _then(EncodingDefaultPresetOverride(
audioBitrate: freezed == audioBitrate ? _self.audioBitrate : audioBitrate // ignore: cast_nullable_to_non_nullable
as int?,videoBitrate: freezed == videoBitrate ? _self.videoBitrate : videoBitrate // ignore: cast_nullable_to_non_nullable
as int?,ptime: freezed == ptime ? _self.ptime : ptime // ignore: cast_nullable_to_non_nullable
as int?,maxptime: freezed == maxptime ? _self.maxptime : maxptime // ignore: cast_nullable_to_non_nullable
as int?,opusSamplingRate: freezed == opusSamplingRate ? _self.opusSamplingRate : opusSamplingRate // ignore: cast_nullable_to_non_nullable
as int?,opusBitrate: freezed == opusBitrate ? _self.opusBitrate : opusBitrate // ignore: cast_nullable_to_non_nullable
as int?,opusStereo: freezed == opusStereo ? _self.opusStereo : opusStereo // ignore: cast_nullable_to_non_nullable
as bool?,opusDtx: freezed == opusDtx ? _self.opusDtx : opusDtx // ignore: cast_nullable_to_non_nullable
as bool?,removeStaticAudioRtpMaps: freezed == removeStaticAudioRtpMaps ? _self.removeStaticAudioRtpMaps : removeStaticAudioRtpMaps // ignore: cast_nullable_to_non_nullable
as bool?,remapTE8payloadTo101: freezed == remapTE8payloadTo101 ? _self.remapTE8payloadTo101 : remapTE8payloadTo101 // ignore: cast_nullable_to_non_nullable
as bool?,removeREMBFeedback: freezed == removeREMBFeedback ? _self.removeREMBFeedback : removeREMBFeedback // ignore: cast_nullable_to_non_nullable
as bool?,removeTWCCFeedback: freezed == removeTWCCFeedback ? _self.removeTWCCFeedback : removeTWCCFeedback // ignore: cast_nullable_to_non_nullable
as bool?,removeExtmaps: freezed == removeExtmaps ? _self.removeExtmaps : removeExtmaps // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}

}


/// Adds pattern-matching-related methods to [EncodingDefaultPresetOverride].
extension EncodingDefaultPresetOverridePatterns on EncodingDefaultPresetOverride {
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
mixin _$FavoritesTabScheme {


/// Create a copy of FavoritesTabScheme
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FavoritesTabSchemeCopyWith<FavoritesTabScheme> get copyWith => _$FavoritesTabSchemeCopyWithImpl<FavoritesTabScheme>(this as FavoritesTabScheme, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FavoritesTabScheme;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FavoritesTabScheme&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled)&&(identical(other.initial, _this.initial) || other.initial == _this.initial)&&(identical(other.titleL10n, _this.titleL10n) || other.titleL10n == _this.titleL10n)&&(identical(other.icon, _this.icon) || other.icon == _this.icon)&&(identical(other.type, _this.type) || other.type == _this.type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as FavoritesTabScheme;
  return Object.hash(runtimeType,_this.enabled,_this.initial,_this.titleL10n,_this.icon,_this.type);
}

@override
String toString() {
  final _this = this as FavoritesTabScheme;
  return 'FavoritesTabScheme(enabled: ${_this.enabled}, initial: ${_this.initial}, titleL10n: ${_this.titleL10n}, icon: ${_this.icon}, type: ${_this.type})';
}


}

/// @nodoc
abstract mixin class $FavoritesTabSchemeCopyWith<$Res>  {
  factory $FavoritesTabSchemeCopyWith(FavoritesTabScheme value, $Res Function(FavoritesTabScheme) _then) = _$FavoritesTabSchemeCopyWithImpl;
@useResult
$Res call({
 bool enabled, bool initial, String titleL10n, String icon, String type
});




}
/// @nodoc
class _$FavoritesTabSchemeCopyWithImpl<$Res>
    implements $FavoritesTabSchemeCopyWith<$Res> {
  _$FavoritesTabSchemeCopyWithImpl(this._self, this._then);

  final FavoritesTabScheme _self;
  final $Res Function(FavoritesTabScheme) _then;

/// Create a copy of FavoritesTabScheme
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,Object? initial = null,Object? titleL10n = null,Object? icon = null,Object? type = null,}) {
  return _then(FavoritesTabScheme(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,initial: null == initial ? _self.initial : initial // ignore: cast_nullable_to_non_nullable
as bool,titleL10n: null == titleL10n ? _self.titleL10n : titleL10n // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [FavoritesTabScheme].
extension FavoritesTabSchemePatterns on FavoritesTabScheme {
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
mixin _$RecentsTabScheme {


/// Create a copy of RecentsTabScheme
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecentsTabSchemeCopyWith<RecentsTabScheme> get copyWith => _$RecentsTabSchemeCopyWithImpl<RecentsTabScheme>(this as RecentsTabScheme, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RecentsTabScheme;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecentsTabScheme&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled)&&(identical(other.initial, _this.initial) || other.initial == _this.initial)&&(identical(other.titleL10n, _this.titleL10n) || other.titleL10n == _this.titleL10n)&&(identical(other.icon, _this.icon) || other.icon == _this.icon)&&(identical(other.supportsCallHistory, _this.supportsCallHistory) || other.supportsCallHistory == _this.supportsCallHistory)&&(identical(other.layout, _this.layout) || other.layout == _this.layout)&&(identical(other.type, _this.type) || other.type == _this.type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RecentsTabScheme;
  return Object.hash(runtimeType,_this.enabled,_this.initial,_this.titleL10n,_this.icon,_this.supportsCallHistory,_this.layout,_this.type);
}

@override
String toString() {
  final _this = this as RecentsTabScheme;
  return 'RecentsTabScheme(enabled: ${_this.enabled}, initial: ${_this.initial}, titleL10n: ${_this.titleL10n}, icon: ${_this.icon}, supportsCallHistory: ${_this.supportsCallHistory}, layout: ${_this.layout}, type: ${_this.type})';
}


}

/// @nodoc
abstract mixin class $RecentsTabSchemeCopyWith<$Res>  {
  factory $RecentsTabSchemeCopyWith(RecentsTabScheme value, $Res Function(RecentsTabScheme) _then) = _$RecentsTabSchemeCopyWithImpl;
@useResult
$Res call({
 bool enabled, bool initial, String titleL10n, String icon, bool supportsCallHistory, RecentsLayoutScheme layout, String type
});




}
/// @nodoc
class _$RecentsTabSchemeCopyWithImpl<$Res>
    implements $RecentsTabSchemeCopyWith<$Res> {
  _$RecentsTabSchemeCopyWithImpl(this._self, this._then);

  final RecentsTabScheme _self;
  final $Res Function(RecentsTabScheme) _then;

/// Create a copy of RecentsTabScheme
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,Object? initial = null,Object? titleL10n = null,Object? icon = null,Object? supportsCallHistory = null,Object? layout = null,Object? type = null,}) {
  return _then(RecentsTabScheme(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,initial: null == initial ? _self.initial : initial // ignore: cast_nullable_to_non_nullable
as bool,titleL10n: null == titleL10n ? _self.titleL10n : titleL10n // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,supportsCallHistory: null == supportsCallHistory ? _self.supportsCallHistory : supportsCallHistory // ignore: cast_nullable_to_non_nullable
as bool,layout: null == layout ? _self.layout : layout // ignore: cast_nullable_to_non_nullable
as RecentsLayoutScheme,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RecentsTabScheme].
extension RecentsTabSchemePatterns on RecentsTabScheme {
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
mixin _$ContactsTabScheme {


/// Create a copy of ContactsTabScheme
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContactsTabSchemeCopyWith<ContactsTabScheme> get copyWith => _$ContactsTabSchemeCopyWithImpl<ContactsTabScheme>(this as ContactsTabScheme, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ContactsTabScheme;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContactsTabScheme&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled)&&(identical(other.initial, _this.initial) || other.initial == _this.initial)&&(identical(other.titleL10n, _this.titleL10n) || other.titleL10n == _this.titleL10n)&&(identical(other.icon, _this.icon) || other.icon == _this.icon)&&const DeepCollectionEquality().equals(other.contactSourceTypes, _this.contactSourceTypes)&&(identical(other.layout, _this.layout) || other.layout == _this.layout)&&(identical(other.favorites, _this.favorites) || other.favorites == _this.favorites)&&(identical(other.type, _this.type) || other.type == _this.type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ContactsTabScheme;
  return Object.hash(runtimeType,_this.enabled,_this.initial,_this.titleL10n,_this.icon,const DeepCollectionEquality().hash(_this.contactSourceTypes),_this.layout,_this.favorites,_this.type);
}

@override
String toString() {
  final _this = this as ContactsTabScheme;
  return 'ContactsTabScheme(enabled: ${_this.enabled}, initial: ${_this.initial}, titleL10n: ${_this.titleL10n}, icon: ${_this.icon}, contactSourceTypes: ${_this.contactSourceTypes}, layout: ${_this.layout}, favorites: ${_this.favorites}, type: ${_this.type})';
}


}

/// @nodoc
abstract mixin class $ContactsTabSchemeCopyWith<$Res>  {
  factory $ContactsTabSchemeCopyWith(ContactsTabScheme value, $Res Function(ContactsTabScheme) _then) = _$ContactsTabSchemeCopyWithImpl;
@useResult
$Res call({
 bool enabled, bool initial, String titleL10n, String icon, List<String> contactSourceTypes, ContactsLayoutScheme layout, bool favorites, String type
});




}
/// @nodoc
class _$ContactsTabSchemeCopyWithImpl<$Res>
    implements $ContactsTabSchemeCopyWith<$Res> {
  _$ContactsTabSchemeCopyWithImpl(this._self, this._then);

  final ContactsTabScheme _self;
  final $Res Function(ContactsTabScheme) _then;

/// Create a copy of ContactsTabScheme
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,Object? initial = null,Object? titleL10n = null,Object? icon = null,Object? contactSourceTypes = null,Object? layout = null,Object? favorites = null,Object? type = null,}) {
  return _then(ContactsTabScheme(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,initial: null == initial ? _self.initial : initial // ignore: cast_nullable_to_non_nullable
as bool,titleL10n: null == titleL10n ? _self.titleL10n : titleL10n // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,contactSourceTypes: null == contactSourceTypes ? _self.contactSourceTypes : contactSourceTypes // ignore: cast_nullable_to_non_nullable
as List<String>,layout: null == layout ? _self.layout : layout // ignore: cast_nullable_to_non_nullable
as ContactsLayoutScheme,favorites: null == favorites ? _self.favorites : favorites // ignore: cast_nullable_to_non_nullable
as bool,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ContactsTabScheme].
extension ContactsTabSchemePatterns on ContactsTabScheme {
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
mixin _$KeypadTabScheme {


/// Create a copy of KeypadTabScheme
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KeypadTabSchemeCopyWith<KeypadTabScheme> get copyWith => _$KeypadTabSchemeCopyWithImpl<KeypadTabScheme>(this as KeypadTabScheme, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as KeypadTabScheme;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KeypadTabScheme&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled)&&(identical(other.initial, _this.initial) || other.initial == _this.initial)&&(identical(other.titleL10n, _this.titleL10n) || other.titleL10n == _this.titleL10n)&&(identical(other.icon, _this.icon) || other.icon == _this.icon)&&(identical(other.type, _this.type) || other.type == _this.type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as KeypadTabScheme;
  return Object.hash(runtimeType,_this.enabled,_this.initial,_this.titleL10n,_this.icon,_this.type);
}

@override
String toString() {
  final _this = this as KeypadTabScheme;
  return 'KeypadTabScheme(enabled: ${_this.enabled}, initial: ${_this.initial}, titleL10n: ${_this.titleL10n}, icon: ${_this.icon}, type: ${_this.type})';
}


}

/// @nodoc
abstract mixin class $KeypadTabSchemeCopyWith<$Res>  {
  factory $KeypadTabSchemeCopyWith(KeypadTabScheme value, $Res Function(KeypadTabScheme) _then) = _$KeypadTabSchemeCopyWithImpl;
@useResult
$Res call({
 bool enabled, bool initial, String titleL10n, String icon, String type
});




}
/// @nodoc
class _$KeypadTabSchemeCopyWithImpl<$Res>
    implements $KeypadTabSchemeCopyWith<$Res> {
  _$KeypadTabSchemeCopyWithImpl(this._self, this._then);

  final KeypadTabScheme _self;
  final $Res Function(KeypadTabScheme) _then;

/// Create a copy of KeypadTabScheme
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,Object? initial = null,Object? titleL10n = null,Object? icon = null,Object? type = null,}) {
  return _then(KeypadTabScheme(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,initial: null == initial ? _self.initial : initial // ignore: cast_nullable_to_non_nullable
as bool,titleL10n: null == titleL10n ? _self.titleL10n : titleL10n // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [KeypadTabScheme].
extension KeypadTabSchemePatterns on KeypadTabScheme {
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
mixin _$MessagingTabScheme {


/// Create a copy of MessagingTabScheme
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessagingTabSchemeCopyWith<MessagingTabScheme> get copyWith => _$MessagingTabSchemeCopyWithImpl<MessagingTabScheme>(this as MessagingTabScheme, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as MessagingTabScheme;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessagingTabScheme&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled)&&(identical(other.initial, _this.initial) || other.initial == _this.initial)&&(identical(other.titleL10n, _this.titleL10n) || other.titleL10n == _this.titleL10n)&&(identical(other.icon, _this.icon) || other.icon == _this.icon)&&(identical(other.type, _this.type) || other.type == _this.type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MessagingTabScheme;
  return Object.hash(runtimeType,_this.enabled,_this.initial,_this.titleL10n,_this.icon,_this.type);
}

@override
String toString() {
  final _this = this as MessagingTabScheme;
  return 'MessagingTabScheme(enabled: ${_this.enabled}, initial: ${_this.initial}, titleL10n: ${_this.titleL10n}, icon: ${_this.icon}, type: ${_this.type})';
}


}

/// @nodoc
abstract mixin class $MessagingTabSchemeCopyWith<$Res>  {
  factory $MessagingTabSchemeCopyWith(MessagingTabScheme value, $Res Function(MessagingTabScheme) _then) = _$MessagingTabSchemeCopyWithImpl;
@useResult
$Res call({
 bool enabled, bool initial, String titleL10n, String icon, String type
});




}
/// @nodoc
class _$MessagingTabSchemeCopyWithImpl<$Res>
    implements $MessagingTabSchemeCopyWith<$Res> {
  _$MessagingTabSchemeCopyWithImpl(this._self, this._then);

  final MessagingTabScheme _self;
  final $Res Function(MessagingTabScheme) _then;

/// Create a copy of MessagingTabScheme
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,Object? initial = null,Object? titleL10n = null,Object? icon = null,Object? type = null,}) {
  return _then(MessagingTabScheme(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,initial: null == initial ? _self.initial : initial // ignore: cast_nullable_to_non_nullable
as bool,titleL10n: null == titleL10n ? _self.titleL10n : titleL10n // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MessagingTabScheme].
extension MessagingTabSchemePatterns on MessagingTabScheme {
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
mixin _$VoicemailTabScheme {


/// Create a copy of VoicemailTabScheme
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VoicemailTabSchemeCopyWith<VoicemailTabScheme> get copyWith => _$VoicemailTabSchemeCopyWithImpl<VoicemailTabScheme>(this as VoicemailTabScheme, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as VoicemailTabScheme;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VoicemailTabScheme&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled)&&(identical(other.initial, _this.initial) || other.initial == _this.initial)&&(identical(other.titleL10n, _this.titleL10n) || other.titleL10n == _this.titleL10n)&&(identical(other.icon, _this.icon) || other.icon == _this.icon)&&(identical(other.type, _this.type) || other.type == _this.type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as VoicemailTabScheme;
  return Object.hash(runtimeType,_this.enabled,_this.initial,_this.titleL10n,_this.icon,_this.type);
}

@override
String toString() {
  final _this = this as VoicemailTabScheme;
  return 'VoicemailTabScheme(enabled: ${_this.enabled}, initial: ${_this.initial}, titleL10n: ${_this.titleL10n}, icon: ${_this.icon}, type: ${_this.type})';
}


}

/// @nodoc
abstract mixin class $VoicemailTabSchemeCopyWith<$Res>  {
  factory $VoicemailTabSchemeCopyWith(VoicemailTabScheme value, $Res Function(VoicemailTabScheme) _then) = _$VoicemailTabSchemeCopyWithImpl;
@useResult
$Res call({
 bool enabled, bool initial, String titleL10n, String icon, String type
});




}
/// @nodoc
class _$VoicemailTabSchemeCopyWithImpl<$Res>
    implements $VoicemailTabSchemeCopyWith<$Res> {
  _$VoicemailTabSchemeCopyWithImpl(this._self, this._then);

  final VoicemailTabScheme _self;
  final $Res Function(VoicemailTabScheme) _then;

/// Create a copy of VoicemailTabScheme
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,Object? initial = null,Object? titleL10n = null,Object? icon = null,Object? type = null,}) {
  return _then(VoicemailTabScheme(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,initial: null == initial ? _self.initial : initial // ignore: cast_nullable_to_non_nullable
as bool,titleL10n: null == titleL10n ? _self.titleL10n : titleL10n // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [VoicemailTabScheme].
extension VoicemailTabSchemePatterns on VoicemailTabScheme {
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
mixin _$CallCenterTabScheme {


/// Create a copy of CallCenterTabScheme
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CallCenterTabSchemeCopyWith<CallCenterTabScheme> get copyWith => _$CallCenterTabSchemeCopyWithImpl<CallCenterTabScheme>(this as CallCenterTabScheme, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CallCenterTabScheme;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CallCenterTabScheme&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled)&&(identical(other.initial, _this.initial) || other.initial == _this.initial)&&(identical(other.titleL10n, _this.titleL10n) || other.titleL10n == _this.titleL10n)&&(identical(other.icon, _this.icon) || other.icon == _this.icon)&&(identical(other.type, _this.type) || other.type == _this.type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CallCenterTabScheme;
  return Object.hash(runtimeType,_this.enabled,_this.initial,_this.titleL10n,_this.icon,_this.type);
}

@override
String toString() {
  final _this = this as CallCenterTabScheme;
  return 'CallCenterTabScheme(enabled: ${_this.enabled}, initial: ${_this.initial}, titleL10n: ${_this.titleL10n}, icon: ${_this.icon}, type: ${_this.type})';
}


}

/// @nodoc
abstract mixin class $CallCenterTabSchemeCopyWith<$Res>  {
  factory $CallCenterTabSchemeCopyWith(CallCenterTabScheme value, $Res Function(CallCenterTabScheme) _then) = _$CallCenterTabSchemeCopyWithImpl;
@useResult
$Res call({
 bool enabled, bool initial, String titleL10n, String icon, String type
});




}
/// @nodoc
class _$CallCenterTabSchemeCopyWithImpl<$Res>
    implements $CallCenterTabSchemeCopyWith<$Res> {
  _$CallCenterTabSchemeCopyWithImpl(this._self, this._then);

  final CallCenterTabScheme _self;
  final $Res Function(CallCenterTabScheme) _then;

/// Create a copy of CallCenterTabScheme
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,Object? initial = null,Object? titleL10n = null,Object? icon = null,Object? type = null,}) {
  return _then(CallCenterTabScheme(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,initial: null == initial ? _self.initial : initial // ignore: cast_nullable_to_non_nullable
as bool,titleL10n: null == titleL10n ? _self.titleL10n : titleL10n // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CallCenterTabScheme].
extension CallCenterTabSchemePatterns on CallCenterTabScheme {
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
mixin _$EmbeddedTabScheme {


/// Create a copy of EmbeddedTabScheme
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmbeddedTabSchemeCopyWith<EmbeddedTabScheme> get copyWith => _$EmbeddedTabSchemeCopyWithImpl<EmbeddedTabScheme>(this as EmbeddedTabScheme, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as EmbeddedTabScheme;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmbeddedTabScheme&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled)&&(identical(other.initial, _this.initial) || other.initial == _this.initial)&&(identical(other.titleL10n, _this.titleL10n) || other.titleL10n == _this.titleL10n)&&(identical(other.icon, _this.icon) || other.icon == _this.icon)&&(identical(other.embeddedResourceId, _this.embeddedResourceId) || other.embeddedResourceId == _this.embeddedResourceId)&&(identical(other.type, _this.type) || other.type == _this.type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as EmbeddedTabScheme;
  return Object.hash(runtimeType,_this.enabled,_this.initial,_this.titleL10n,_this.icon,_this.embeddedResourceId,_this.type);
}

@override
String toString() {
  final _this = this as EmbeddedTabScheme;
  return 'EmbeddedTabScheme(enabled: ${_this.enabled}, initial: ${_this.initial}, titleL10n: ${_this.titleL10n}, icon: ${_this.icon}, embeddedResourceId: ${_this.embeddedResourceId}, type: ${_this.type})';
}


}

/// @nodoc
abstract mixin class $EmbeddedTabSchemeCopyWith<$Res>  {
  factory $EmbeddedTabSchemeCopyWith(EmbeddedTabScheme value, $Res Function(EmbeddedTabScheme) _then) = _$EmbeddedTabSchemeCopyWithImpl;
@useResult
$Res call({
 bool enabled, bool initial, String titleL10n, String icon, String embeddedResourceId, String type
});




}
/// @nodoc
class _$EmbeddedTabSchemeCopyWithImpl<$Res>
    implements $EmbeddedTabSchemeCopyWith<$Res> {
  _$EmbeddedTabSchemeCopyWithImpl(this._self, this._then);

  final EmbeddedTabScheme _self;
  final $Res Function(EmbeddedTabScheme) _then;

/// Create a copy of EmbeddedTabScheme
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,Object? initial = null,Object? titleL10n = null,Object? icon = null,Object? embeddedResourceId = null,Object? type = null,}) {
  return _then(EmbeddedTabScheme(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,initial: null == initial ? _self.initial : initial // ignore: cast_nullable_to_non_nullable
as bool,titleL10n: null == titleL10n ? _self.titleL10n : titleL10n // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,embeddedResourceId: null == embeddedResourceId ? _self.embeddedResourceId : embeddedResourceId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [EmbeddedTabScheme].
extension EmbeddedTabSchemePatterns on EmbeddedTabScheme {
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
mixin _$AppConfigSettings {


/// Create a copy of AppConfigSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppConfigSettingsCopyWith<AppConfigSettings> get copyWith => _$AppConfigSettingsCopyWithImpl<AppConfigSettings>(this as AppConfigSettings, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AppConfigSettings;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppConfigSettings&&const DeepCollectionEquality().equals(other.sections, _this.sections));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AppConfigSettings;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.sections));
}

@override
String toString() {
  final _this = this as AppConfigSettings;
  return 'AppConfigSettings(sections: ${_this.sections})';
}


}

/// @nodoc
abstract mixin class $AppConfigSettingsCopyWith<$Res>  {
  factory $AppConfigSettingsCopyWith(AppConfigSettings value, $Res Function(AppConfigSettings) _then) = _$AppConfigSettingsCopyWithImpl;
@useResult
$Res call({
 List<AppConfigSettingsSection> sections
});




}
/// @nodoc
class _$AppConfigSettingsCopyWithImpl<$Res>
    implements $AppConfigSettingsCopyWith<$Res> {
  _$AppConfigSettingsCopyWithImpl(this._self, this._then);

  final AppConfigSettings _self;
  final $Res Function(AppConfigSettings) _then;

/// Create a copy of AppConfigSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sections = null,}) {
  return _then(AppConfigSettings(
sections: null == sections ? _self.sections : sections // ignore: cast_nullable_to_non_nullable
as List<AppConfigSettingsSection>,
  ));
}

}


/// Adds pattern-matching-related methods to [AppConfigSettings].
extension AppConfigSettingsPatterns on AppConfigSettings {
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
mixin _$AppConfigSettingsSection {


/// Create a copy of AppConfigSettingsSection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppConfigSettingsSectionCopyWith<AppConfigSettingsSection> get copyWith => _$AppConfigSettingsSectionCopyWithImpl<AppConfigSettingsSection>(this as AppConfigSettingsSection, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AppConfigSettingsSection;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppConfigSettingsSection&&(identical(other.titleL10n, _this.titleL10n) || other.titleL10n == _this.titleL10n)&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled)&&const DeepCollectionEquality().equals(other.items, _this.items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AppConfigSettingsSection;
  return Object.hash(runtimeType,_this.titleL10n,_this.enabled,const DeepCollectionEquality().hash(_this.items));
}

@override
String toString() {
  final _this = this as AppConfigSettingsSection;
  return 'AppConfigSettingsSection(titleL10n: ${_this.titleL10n}, enabled: ${_this.enabled}, items: ${_this.items})';
}


}

/// @nodoc
abstract mixin class $AppConfigSettingsSectionCopyWith<$Res>  {
  factory $AppConfigSettingsSectionCopyWith(AppConfigSettingsSection value, $Res Function(AppConfigSettingsSection) _then) = _$AppConfigSettingsSectionCopyWithImpl;
@useResult
$Res call({
 String titleL10n, bool enabled, List<AppConfigSettingsItem> items
});




}
/// @nodoc
class _$AppConfigSettingsSectionCopyWithImpl<$Res>
    implements $AppConfigSettingsSectionCopyWith<$Res> {
  _$AppConfigSettingsSectionCopyWithImpl(this._self, this._then);

  final AppConfigSettingsSection _self;
  final $Res Function(AppConfigSettingsSection) _then;

/// Create a copy of AppConfigSettingsSection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? titleL10n = null,Object? enabled = null,Object? items = null,}) {
  return _then(AppConfigSettingsSection(
titleL10n: null == titleL10n ? _self.titleL10n : titleL10n // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<AppConfigSettingsItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [AppConfigSettingsSection].
extension AppConfigSettingsSectionPatterns on AppConfigSettingsSection {
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
mixin _$AppConfigSettingsItem {


/// Create a copy of AppConfigSettingsItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppConfigSettingsItemCopyWith<AppConfigSettingsItem> get copyWith => _$AppConfigSettingsItemCopyWithImpl<AppConfigSettingsItem>(this as AppConfigSettingsItem, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AppConfigSettingsItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppConfigSettingsItem&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled)&&(identical(other.titleL10n, _this.titleL10n) || other.titleL10n == _this.titleL10n)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.icon, _this.icon) || other.icon == _this.icon)&&(identical(other.iconColor, _this.iconColor) || other.iconColor == _this.iconColor)&&(identical(other.embeddedResourceId, _this.embeddedResourceId) || other.embeddedResourceId == _this.embeddedResourceId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AppConfigSettingsItem;
  return Object.hash(runtimeType,_this.enabled,_this.titleL10n,_this.type,_this.icon,_this.iconColor,_this.embeddedResourceId);
}

@override
String toString() {
  final _this = this as AppConfigSettingsItem;
  return 'AppConfigSettingsItem(enabled: ${_this.enabled}, titleL10n: ${_this.titleL10n}, type: ${_this.type}, icon: ${_this.icon}, iconColor: ${_this.iconColor}, embeddedResourceId: ${_this.embeddedResourceId})';
}


}

/// @nodoc
abstract mixin class $AppConfigSettingsItemCopyWith<$Res>  {
  factory $AppConfigSettingsItemCopyWith(AppConfigSettingsItem value, $Res Function(AppConfigSettingsItem) _then) = _$AppConfigSettingsItemCopyWithImpl;
@useResult
$Res call({
 bool enabled, String titleL10n, String type, String icon, String? iconColor, String? embeddedResourceId
});




}
/// @nodoc
class _$AppConfigSettingsItemCopyWithImpl<$Res>
    implements $AppConfigSettingsItemCopyWith<$Res> {
  _$AppConfigSettingsItemCopyWithImpl(this._self, this._then);

  final AppConfigSettingsItem _self;
  final $Res Function(AppConfigSettingsItem) _then;

/// Create a copy of AppConfigSettingsItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,Object? titleL10n = null,Object? type = null,Object? icon = null,Object? iconColor = freezed,Object? embeddedResourceId = freezed,}) {
  return _then(AppConfigSettingsItem(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,titleL10n: null == titleL10n ? _self.titleL10n : titleL10n // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,iconColor: freezed == iconColor ? _self.iconColor : iconColor // ignore: cast_nullable_to_non_nullable
as String?,embeddedResourceId: freezed == embeddedResourceId ? _self.embeddedResourceId : embeddedResourceId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppConfigSettingsItem].
extension AppConfigSettingsItemPatterns on AppConfigSettingsItem {
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
mixin _$AppConfigContacts {


/// Create a copy of AppConfigContacts
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppConfigContactsCopyWith<AppConfigContacts> get copyWith => _$AppConfigContactsCopyWithImpl<AppConfigContacts>(this as AppConfigContacts, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AppConfigContacts;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppConfigContacts&&(identical(other.details, _this.details) || other.details == _this.details));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AppConfigContacts;
  return Object.hash(runtimeType,_this.details);
}

@override
String toString() {
  final _this = this as AppConfigContacts;
  return 'AppConfigContacts(details: ${_this.details})';
}


}

/// @nodoc
abstract mixin class $AppConfigContactsCopyWith<$Res>  {
  factory $AppConfigContactsCopyWith(AppConfigContacts value, $Res Function(AppConfigContacts) _then) = _$AppConfigContactsCopyWithImpl;
@useResult
$Res call({
 AppConfigContactDetails details
});




}
/// @nodoc
class _$AppConfigContactsCopyWithImpl<$Res>
    implements $AppConfigContactsCopyWith<$Res> {
  _$AppConfigContactsCopyWithImpl(this._self, this._then);

  final AppConfigContacts _self;
  final $Res Function(AppConfigContacts) _then;

/// Create a copy of AppConfigContacts
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? details = null,}) {
  return _then(AppConfigContacts(
details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as AppConfigContactDetails,
  ));
}

}


/// Adds pattern-matching-related methods to [AppConfigContacts].
extension AppConfigContactsPatterns on AppConfigContacts {
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
mixin _$AppConfigContactDetails {


/// Create a copy of AppConfigContactDetails
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppConfigContactDetailsCopyWith<AppConfigContactDetails> get copyWith => _$AppConfigContactDetailsCopyWithImpl<AppConfigContactDetails>(this as AppConfigContactDetails, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AppConfigContactDetails;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppConfigContactDetails&&(identical(other.actions, _this.actions) || other.actions == _this.actions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AppConfigContactDetails;
  return Object.hash(runtimeType,_this.actions);
}

@override
String toString() {
  final _this = this as AppConfigContactDetails;
  return 'AppConfigContactDetails(actions: ${_this.actions})';
}


}

/// @nodoc
abstract mixin class $AppConfigContactDetailsCopyWith<$Res>  {
  factory $AppConfigContactDetailsCopyWith(AppConfigContactDetails value, $Res Function(AppConfigContactDetails) _then) = _$AppConfigContactDetailsCopyWithImpl;
@useResult
$Res call({
 AppConfigContactDetailsActions actions
});




}
/// @nodoc
class _$AppConfigContactDetailsCopyWithImpl<$Res>
    implements $AppConfigContactDetailsCopyWith<$Res> {
  _$AppConfigContactDetailsCopyWithImpl(this._self, this._then);

  final AppConfigContactDetails _self;
  final $Res Function(AppConfigContactDetails) _then;

/// Create a copy of AppConfigContactDetails
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? actions = null,}) {
  return _then(AppConfigContactDetails(
actions: null == actions ? _self.actions : actions // ignore: cast_nullable_to_non_nullable
as AppConfigContactDetailsActions,
  ));
}

}


/// Adds pattern-matching-related methods to [AppConfigContactDetails].
extension AppConfigContactDetailsPatterns on AppConfigContactDetails {
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
mixin _$AppConfigContactDetailsActions {


/// Create a copy of AppConfigContactDetailsActions
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppConfigContactDetailsActionsCopyWith<AppConfigContactDetailsActions> get copyWith => _$AppConfigContactDetailsActionsCopyWithImpl<AppConfigContactDetailsActions>(this as AppConfigContactDetailsActions, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AppConfigContactDetailsActions;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppConfigContactDetailsActions&&const DeepCollectionEquality().equals(other.appBar, _this.appBar)&&const DeepCollectionEquality().equals(other.phoneTile, _this.phoneTile)&&const DeepCollectionEquality().equals(other.emailTile, _this.emailTile));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AppConfigContactDetailsActions;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.appBar),const DeepCollectionEquality().hash(_this.phoneTile),const DeepCollectionEquality().hash(_this.emailTile));
}

@override
String toString() {
  final _this = this as AppConfigContactDetailsActions;
  return 'AppConfigContactDetailsActions(appBar: ${_this.appBar}, phoneTile: ${_this.phoneTile}, emailTile: ${_this.emailTile})';
}


}

/// @nodoc
abstract mixin class $AppConfigContactDetailsActionsCopyWith<$Res>  {
  factory $AppConfigContactDetailsActionsCopyWith(AppConfigContactDetailsActions value, $Res Function(AppConfigContactDetailsActions) _then) = _$AppConfigContactDetailsActionsCopyWithImpl;
@useResult
$Res call({
 List<String>? appBar, List<String>? phoneTile, List<String>? emailTile
});




}
/// @nodoc
class _$AppConfigContactDetailsActionsCopyWithImpl<$Res>
    implements $AppConfigContactDetailsActionsCopyWith<$Res> {
  _$AppConfigContactDetailsActionsCopyWithImpl(this._self, this._then);

  final AppConfigContactDetailsActions _self;
  final $Res Function(AppConfigContactDetailsActions) _then;

/// Create a copy of AppConfigContactDetailsActions
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? appBar = freezed,Object? phoneTile = freezed,Object? emailTile = freezed,}) {
  return _then(AppConfigContactDetailsActions(
appBar: freezed == appBar ? _self.appBar : appBar // ignore: cast_nullable_to_non_nullable
as List<String>?,phoneTile: freezed == phoneTile ? _self.phoneTile : phoneTile // ignore: cast_nullable_to_non_nullable
as List<String>?,emailTile: freezed == emailTile ? _self.emailTile : emailTile // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppConfigContactDetailsActions].
extension AppConfigContactDetailsActionsPatterns on AppConfigContactDetailsActions {
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
mixin _$AppConfigMessaging {


/// Create a copy of AppConfigMessaging
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppConfigMessagingCopyWith<AppConfigMessaging> get copyWith => _$AppConfigMessagingCopyWithImpl<AppConfigMessaging>(this as AppConfigMessaging, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AppConfigMessaging;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppConfigMessaging&&(identical(other.chats, _this.chats) || other.chats == _this.chats));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AppConfigMessaging;
  return Object.hash(runtimeType,_this.chats);
}

@override
String toString() {
  final _this = this as AppConfigMessaging;
  return 'AppConfigMessaging(chats: ${_this.chats})';
}


}

/// @nodoc
abstract mixin class $AppConfigMessagingCopyWith<$Res>  {
  factory $AppConfigMessagingCopyWith(AppConfigMessaging value, $Res Function(AppConfigMessaging) _then) = _$AppConfigMessagingCopyWithImpl;
@useResult
$Res call({
 AppConfigChats chats
});




}
/// @nodoc
class _$AppConfigMessagingCopyWithImpl<$Res>
    implements $AppConfigMessagingCopyWith<$Res> {
  _$AppConfigMessagingCopyWithImpl(this._self, this._then);

  final AppConfigMessaging _self;
  final $Res Function(AppConfigMessaging) _then;

/// Create a copy of AppConfigMessaging
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? chats = null,}) {
  return _then(AppConfigMessaging(
chats: null == chats ? _self.chats : chats // ignore: cast_nullable_to_non_nullable
as AppConfigChats,
  ));
}

}


/// Adds pattern-matching-related methods to [AppConfigMessaging].
extension AppConfigMessagingPatterns on AppConfigMessaging {
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
mixin _$AppConfigChats {


/// Create a copy of AppConfigChats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppConfigChatsCopyWith<AppConfigChats> get copyWith => _$AppConfigChatsCopyWithImpl<AppConfigChats>(this as AppConfigChats, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AppConfigChats;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppConfigChats&&(identical(other.groupChatButtonEnabled, _this.groupChatButtonEnabled) || other.groupChatButtonEnabled == _this.groupChatButtonEnabled)&&(identical(other.contactInfo, _this.contactInfo) || other.contactInfo == _this.contactInfo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AppConfigChats;
  return Object.hash(runtimeType,_this.groupChatButtonEnabled,_this.contactInfo);
}

@override
String toString() {
  final _this = this as AppConfigChats;
  return 'AppConfigChats(groupChatButtonEnabled: ${_this.groupChatButtonEnabled}, contactInfo: ${_this.contactInfo})';
}


}

/// @nodoc
abstract mixin class $AppConfigChatsCopyWith<$Res>  {
  factory $AppConfigChatsCopyWith(AppConfigChats value, $Res Function(AppConfigChats) _then) = _$AppConfigChatsCopyWithImpl;
@useResult
$Res call({
 bool groupChatButtonEnabled, ChatContactInfo contactInfo
});




}
/// @nodoc
class _$AppConfigChatsCopyWithImpl<$Res>
    implements $AppConfigChatsCopyWith<$Res> {
  _$AppConfigChatsCopyWithImpl(this._self, this._then);

  final AppConfigChats _self;
  final $Res Function(AppConfigChats) _then;

/// Create a copy of AppConfigChats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? groupChatButtonEnabled = null,Object? contactInfo = null,}) {
  return _then(AppConfigChats(
groupChatButtonEnabled: null == groupChatButtonEnabled ? _self.groupChatButtonEnabled : groupChatButtonEnabled // ignore: cast_nullable_to_non_nullable
as bool,contactInfo: null == contactInfo ? _self.contactInfo : contactInfo // ignore: cast_nullable_to_non_nullable
as ChatContactInfo,
  ));
}

}


/// Adds pattern-matching-related methods to [AppConfigChats].
extension AppConfigChatsPatterns on AppConfigChats {
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
mixin _$ChatContactInfo {


/// Create a copy of ChatContactInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatContactInfoCopyWith<ChatContactInfo> get copyWith => _$ChatContactInfoCopyWithImpl<ChatContactInfo>(this as ChatContactInfo, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ChatContactInfo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatContactInfo&&(identical(other.showVideoButtonAction, _this.showVideoButtonAction) || other.showVideoButtonAction == _this.showVideoButtonAction));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ChatContactInfo;
  return Object.hash(runtimeType,_this.showVideoButtonAction);
}

@override
String toString() {
  final _this = this as ChatContactInfo;
  return 'ChatContactInfo(showVideoButtonAction: ${_this.showVideoButtonAction})';
}


}

/// @nodoc
abstract mixin class $ChatContactInfoCopyWith<$Res>  {
  factory $ChatContactInfoCopyWith(ChatContactInfo value, $Res Function(ChatContactInfo) _then) = _$ChatContactInfoCopyWithImpl;
@useResult
$Res call({
 bool showVideoButtonAction
});




}
/// @nodoc
class _$ChatContactInfoCopyWithImpl<$Res>
    implements $ChatContactInfoCopyWith<$Res> {
  _$ChatContactInfoCopyWithImpl(this._self, this._then);

  final ChatContactInfo _self;
  final $Res Function(ChatContactInfo) _then;

/// Create a copy of ChatContactInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? showVideoButtonAction = null,}) {
  return _then(ChatContactInfo(
showVideoButtonAction: null == showVideoButtonAction ? _self.showVideoButtonAction : showVideoButtonAction // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatContactInfo].
extension ChatContactInfoPatterns on ChatContactInfo {
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
