// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'theme_page_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ThemePageConfig {


/// Create a copy of ThemePageConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ThemePageConfigCopyWith<ThemePageConfig> get copyWith => _$ThemePageConfigCopyWithImpl<ThemePageConfig>(this as ThemePageConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ThemePageConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ThemePageConfig&&(identical(other.login, _this.login) || other.login == _this.login)&&(identical(other.about, _this.about) || other.about == _this.about)&&(identical(other.dialing, _this.dialing) || other.dialing == _this.dialing)&&(identical(other.keypad, _this.keypad) || other.keypad == _this.keypad)&&(identical(other.settings, _this.settings) || other.settings == _this.settings)&&(identical(other.contacts, _this.contacts) || other.contacts == _this.contacts)&&(identical(other.embedded, _this.embedded) || other.embedded == _this.embedded)&&(identical(other.favorites, _this.favorites) || other.favorites == _this.favorites)&&(identical(other.conversations, _this.conversations) || other.conversations == _this.conversations)&&(identical(other.recents, _this.recents) || other.recents == _this.recents)&&(identical(other.numberCdrs, _this.numberCdrs) || other.numberCdrs == _this.numberCdrs)&&(identical(other.voicemail, _this.voicemail) || other.voicemail == _this.voicemail)&&(identical(other.callCenter, _this.callCenter) || other.callCenter == _this.callCenter)&&(identical(other.systemNotifications, _this.systemNotifications) || other.systemNotifications == _this.systemNotifications));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ThemePageConfig;
  return Object.hash(runtimeType,_this.login,_this.about,_this.dialing,_this.keypad,_this.settings,_this.contacts,_this.embedded,_this.favorites,_this.conversations,_this.recents,_this.numberCdrs,_this.voicemail,_this.callCenter,_this.systemNotifications);
}

@override
String toString() {
  final _this = this as ThemePageConfig;
  return 'ThemePageConfig(login: ${_this.login}, about: ${_this.about}, dialing: ${_this.dialing}, keypad: ${_this.keypad}, settings: ${_this.settings}, contacts: ${_this.contacts}, embedded: ${_this.embedded}, favorites: ${_this.favorites}, conversations: ${_this.conversations}, recents: ${_this.recents}, numberCdrs: ${_this.numberCdrs}, voicemail: ${_this.voicemail}, callCenter: ${_this.callCenter}, systemNotifications: ${_this.systemNotifications})';
}


}

/// @nodoc
abstract mixin class $ThemePageConfigCopyWith<$Res>  {
  factory $ThemePageConfigCopyWith(ThemePageConfig value, $Res Function(ThemePageConfig) _then) = _$ThemePageConfigCopyWithImpl;
@useResult
$Res call({
 LoginPageConfig login, AboutPageConfig about, CallPageConfig dialing, KeypadPageConfig keypad, SettingsPageConfig settings, ContactsPageConfig contacts, EmbeddedPageConfig embedded, FavoritesPageConfig favorites, ConversationsPageConfig conversations, RecentsPageConfig recents, NumberCdrsPageConfig numberCdrs, VoicemailPageConfig voicemail, CallCenterPageConfig callCenter, SystemNotificationsPageConfig systemNotifications
});




}
/// @nodoc
class _$ThemePageConfigCopyWithImpl<$Res>
    implements $ThemePageConfigCopyWith<$Res> {
  _$ThemePageConfigCopyWithImpl(this._self, this._then);

  final ThemePageConfig _self;
  final $Res Function(ThemePageConfig) _then;

/// Create a copy of ThemePageConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? login = null,Object? about = null,Object? dialing = null,Object? keypad = null,Object? settings = null,Object? contacts = null,Object? embedded = null,Object? favorites = null,Object? conversations = null,Object? recents = null,Object? numberCdrs = null,Object? voicemail = null,Object? callCenter = null,Object? systemNotifications = null,}) {
  return _then(ThemePageConfig(
login: null == login ? _self.login : login // ignore: cast_nullable_to_non_nullable
as LoginPageConfig,about: null == about ? _self.about : about // ignore: cast_nullable_to_non_nullable
as AboutPageConfig,dialing: null == dialing ? _self.dialing : dialing // ignore: cast_nullable_to_non_nullable
as CallPageConfig,keypad: null == keypad ? _self.keypad : keypad // ignore: cast_nullable_to_non_nullable
as KeypadPageConfig,settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as SettingsPageConfig,contacts: null == contacts ? _self.contacts : contacts // ignore: cast_nullable_to_non_nullable
as ContactsPageConfig,embedded: null == embedded ? _self.embedded : embedded // ignore: cast_nullable_to_non_nullable
as EmbeddedPageConfig,favorites: null == favorites ? _self.favorites : favorites // ignore: cast_nullable_to_non_nullable
as FavoritesPageConfig,conversations: null == conversations ? _self.conversations : conversations // ignore: cast_nullable_to_non_nullable
as ConversationsPageConfig,recents: null == recents ? _self.recents : recents // ignore: cast_nullable_to_non_nullable
as RecentsPageConfig,numberCdrs: null == numberCdrs ? _self.numberCdrs : numberCdrs // ignore: cast_nullable_to_non_nullable
as NumberCdrsPageConfig,voicemail: null == voicemail ? _self.voicemail : voicemail // ignore: cast_nullable_to_non_nullable
as VoicemailPageConfig,callCenter: null == callCenter ? _self.callCenter : callCenter // ignore: cast_nullable_to_non_nullable
as CallCenterPageConfig,systemNotifications: null == systemNotifications ? _self.systemNotifications : systemNotifications // ignore: cast_nullable_to_non_nullable
as SystemNotificationsPageConfig,
  ));
}

}


/// Adds pattern-matching-related methods to [ThemePageConfig].
extension ThemePageConfigPatterns on ThemePageConfig {
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
mixin _$ThemeOverrideConfig {


/// Create a copy of ThemeOverrideConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ThemeOverrideConfigCopyWith<ThemeOverrideConfig> get copyWith => _$ThemeOverrideConfigCopyWithImpl<ThemeOverrideConfig>(this as ThemeOverrideConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ThemeOverrideConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ThemeOverrideConfig&&(identical(other.mode, _this.mode) || other.mode == _this.mode)&&(identical(other.applyToAppBar, _this.applyToAppBar) || other.applyToAppBar == _this.applyToAppBar));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ThemeOverrideConfig;
  return Object.hash(runtimeType,_this.mode,_this.applyToAppBar);
}

@override
String toString() {
  final _this = this as ThemeOverrideConfig;
  return 'ThemeOverrideConfig(mode: ${_this.mode}, applyToAppBar: ${_this.applyToAppBar})';
}


}

/// @nodoc
abstract mixin class $ThemeOverrideConfigCopyWith<$Res>  {
  factory $ThemeOverrideConfigCopyWith(ThemeOverrideConfig value, $Res Function(ThemeOverrideConfig) _then) = _$ThemeOverrideConfigCopyWithImpl;
@useResult
$Res call({
 ThemeModeConfig mode, bool applyToAppBar
});




}
/// @nodoc
class _$ThemeOverrideConfigCopyWithImpl<$Res>
    implements $ThemeOverrideConfigCopyWith<$Res> {
  _$ThemeOverrideConfigCopyWithImpl(this._self, this._then);

  final ThemeOverrideConfig _self;
  final $Res Function(ThemeOverrideConfig) _then;

/// Create a copy of ThemeOverrideConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mode = null,Object? applyToAppBar = null,}) {
  return _then(ThemeOverrideConfig(
mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as ThemeModeConfig,applyToAppBar: null == applyToAppBar ? _self.applyToAppBar : applyToAppBar // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ThemeOverrideConfig].
extension ThemeOverrideConfigPatterns on ThemeOverrideConfig {
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
mixin _$LoginPageConfig {


/// Create a copy of LoginPageConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoginPageConfigCopyWith<LoginPageConfig> get copyWith => _$LoginPageConfigCopyWithImpl<LoginPageConfig>(this as LoginPageConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LoginPageConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoginPageConfig&&(identical(other.modeSelect, _this.modeSelect) || other.modeSelect == _this.modeSelect)&&(identical(other.switchPage, _this.switchPage) || other.switchPage == _this.switchPage)&&(identical(other.otpSignin, _this.otpSignin) || other.otpSignin == _this.otpSignin)&&(identical(other.passwordSignin, _this.passwordSignin) || other.passwordSignin == _this.passwordSignin)&&(identical(other.otpSigninVerify, _this.otpSigninVerify) || other.otpSigninVerify == _this.otpSigninVerify)&&(identical(other.signupVerify, _this.signupVerify) || other.signupVerify == _this.signupVerify)&&(identical(other.coreUrlAssign, _this.coreUrlAssign) || other.coreUrlAssign == _this.coreUrlAssign));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LoginPageConfig;
  return Object.hash(runtimeType,_this.modeSelect,_this.switchPage,_this.otpSignin,_this.passwordSignin,_this.otpSigninVerify,_this.signupVerify,_this.coreUrlAssign);
}

@override
String toString() {
  final _this = this as LoginPageConfig;
  return 'LoginPageConfig(modeSelect: ${_this.modeSelect}, switchPage: ${_this.switchPage}, otpSignin: ${_this.otpSignin}, passwordSignin: ${_this.passwordSignin}, otpSigninVerify: ${_this.otpSigninVerify}, signupVerify: ${_this.signupVerify}, coreUrlAssign: ${_this.coreUrlAssign})';
}


}

/// @nodoc
abstract mixin class $LoginPageConfigCopyWith<$Res>  {
  factory $LoginPageConfigCopyWith(LoginPageConfig value, $Res Function(LoginPageConfig) _then) = _$LoginPageConfigCopyWithImpl;
@useResult
$Res call({
 LoginModeSelectPageConfig modeSelect, LoginSwitchPageConfig switchPage, LoginOtpSigninPageConfig otpSignin, LoginPasswordSigninPageConfig passwordSignin, LoginOtpSigninVerifyScreenPageConfig otpSigninVerify, LoginSignupVerifyScreenPageConfig signupVerify, LoginCoreUrlAssignPageConfig coreUrlAssign
});




}
/// @nodoc
class _$LoginPageConfigCopyWithImpl<$Res>
    implements $LoginPageConfigCopyWith<$Res> {
  _$LoginPageConfigCopyWithImpl(this._self, this._then);

  final LoginPageConfig _self;
  final $Res Function(LoginPageConfig) _then;

/// Create a copy of LoginPageConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? modeSelect = null,Object? switchPage = null,Object? otpSignin = null,Object? passwordSignin = null,Object? otpSigninVerify = null,Object? signupVerify = null,Object? coreUrlAssign = null,}) {
  return _then(LoginPageConfig(
modeSelect: null == modeSelect ? _self.modeSelect : modeSelect // ignore: cast_nullable_to_non_nullable
as LoginModeSelectPageConfig,switchPage: null == switchPage ? _self.switchPage : switchPage // ignore: cast_nullable_to_non_nullable
as LoginSwitchPageConfig,otpSignin: null == otpSignin ? _self.otpSignin : otpSignin // ignore: cast_nullable_to_non_nullable
as LoginOtpSigninPageConfig,passwordSignin: null == passwordSignin ? _self.passwordSignin : passwordSignin // ignore: cast_nullable_to_non_nullable
as LoginPasswordSigninPageConfig,otpSigninVerify: null == otpSigninVerify ? _self.otpSigninVerify : otpSigninVerify // ignore: cast_nullable_to_non_nullable
as LoginOtpSigninVerifyScreenPageConfig,signupVerify: null == signupVerify ? _self.signupVerify : signupVerify // ignore: cast_nullable_to_non_nullable
as LoginSignupVerifyScreenPageConfig,coreUrlAssign: null == coreUrlAssign ? _self.coreUrlAssign : coreUrlAssign // ignore: cast_nullable_to_non_nullable
as LoginCoreUrlAssignPageConfig,
  ));
}

}


/// Adds pattern-matching-related methods to [LoginPageConfig].
extension LoginPageConfigPatterns on LoginPageConfig {
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
mixin _$LoginOtpSigninPageConfig {


/// Create a copy of LoginOtpSigninPageConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoginOtpSigninPageConfigCopyWith<LoginOtpSigninPageConfig> get copyWith => _$LoginOtpSigninPageConfigCopyWithImpl<LoginOtpSigninPageConfig>(this as LoginOtpSigninPageConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LoginOtpSigninPageConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoginOtpSigninPageConfig&&(identical(other.refTextField, _this.refTextField) || other.refTextField == _this.refTextField));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LoginOtpSigninPageConfig;
  return Object.hash(runtimeType,_this.refTextField);
}

@override
String toString() {
  final _this = this as LoginOtpSigninPageConfig;
  return 'LoginOtpSigninPageConfig(refTextField: ${_this.refTextField})';
}


}

/// @nodoc
abstract mixin class $LoginOtpSigninPageConfigCopyWith<$Res>  {
  factory $LoginOtpSigninPageConfigCopyWith(LoginOtpSigninPageConfig value, $Res Function(LoginOtpSigninPageConfig) _then) = _$LoginOtpSigninPageConfigCopyWithImpl;
@useResult
$Res call({
 TextFieldConfig? refTextField
});




}
/// @nodoc
class _$LoginOtpSigninPageConfigCopyWithImpl<$Res>
    implements $LoginOtpSigninPageConfigCopyWith<$Res> {
  _$LoginOtpSigninPageConfigCopyWithImpl(this._self, this._then);

  final LoginOtpSigninPageConfig _self;
  final $Res Function(LoginOtpSigninPageConfig) _then;

/// Create a copy of LoginOtpSigninPageConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? refTextField = freezed,}) {
  return _then(LoginOtpSigninPageConfig(
refTextField: freezed == refTextField ? _self.refTextField : refTextField // ignore: cast_nullable_to_non_nullable
as TextFieldConfig?,
  ));
}

}


/// Adds pattern-matching-related methods to [LoginOtpSigninPageConfig].
extension LoginOtpSigninPageConfigPatterns on LoginOtpSigninPageConfig {
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
mixin _$LoginPasswordSigninPageConfig {


/// Create a copy of LoginPasswordSigninPageConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoginPasswordSigninPageConfigCopyWith<LoginPasswordSigninPageConfig> get copyWith => _$LoginPasswordSigninPageConfigCopyWithImpl<LoginPasswordSigninPageConfig>(this as LoginPasswordSigninPageConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LoginPasswordSigninPageConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoginPasswordSigninPageConfig&&(identical(other.refTextField, _this.refTextField) || other.refTextField == _this.refTextField)&&(identical(other.passwordTextField, _this.passwordTextField) || other.passwordTextField == _this.passwordTextField));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LoginPasswordSigninPageConfig;
  return Object.hash(runtimeType,_this.refTextField,_this.passwordTextField);
}

@override
String toString() {
  final _this = this as LoginPasswordSigninPageConfig;
  return 'LoginPasswordSigninPageConfig(refTextField: ${_this.refTextField}, passwordTextField: ${_this.passwordTextField})';
}


}

/// @nodoc
abstract mixin class $LoginPasswordSigninPageConfigCopyWith<$Res>  {
  factory $LoginPasswordSigninPageConfigCopyWith(LoginPasswordSigninPageConfig value, $Res Function(LoginPasswordSigninPageConfig) _then) = _$LoginPasswordSigninPageConfigCopyWithImpl;
@useResult
$Res call({
 TextFieldConfig? refTextField, TextFieldConfig? passwordTextField
});




}
/// @nodoc
class _$LoginPasswordSigninPageConfigCopyWithImpl<$Res>
    implements $LoginPasswordSigninPageConfigCopyWith<$Res> {
  _$LoginPasswordSigninPageConfigCopyWithImpl(this._self, this._then);

  final LoginPasswordSigninPageConfig _self;
  final $Res Function(LoginPasswordSigninPageConfig) _then;

/// Create a copy of LoginPasswordSigninPageConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? refTextField = freezed,Object? passwordTextField = freezed,}) {
  return _then(LoginPasswordSigninPageConfig(
refTextField: freezed == refTextField ? _self.refTextField : refTextField // ignore: cast_nullable_to_non_nullable
as TextFieldConfig?,passwordTextField: freezed == passwordTextField ? _self.passwordTextField : passwordTextField // ignore: cast_nullable_to_non_nullable
as TextFieldConfig?,
  ));
}

}


/// Adds pattern-matching-related methods to [LoginPasswordSigninPageConfig].
extension LoginPasswordSigninPageConfigPatterns on LoginPasswordSigninPageConfig {
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
mixin _$LoginOtpSigninVerifyScreenPageConfig {


/// Create a copy of LoginOtpSigninVerifyScreenPageConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoginOtpSigninVerifyScreenPageConfigCopyWith<LoginOtpSigninVerifyScreenPageConfig> get copyWith => _$LoginOtpSigninVerifyScreenPageConfigCopyWithImpl<LoginOtpSigninVerifyScreenPageConfig>(this as LoginOtpSigninVerifyScreenPageConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LoginOtpSigninVerifyScreenPageConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoginOtpSigninVerifyScreenPageConfig&&(identical(other.countdownRepeatIntervalSeconds, _this.countdownRepeatIntervalSeconds) || other.countdownRepeatIntervalSeconds == _this.countdownRepeatIntervalSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LoginOtpSigninVerifyScreenPageConfig;
  return Object.hash(runtimeType,_this.countdownRepeatIntervalSeconds);
}

@override
String toString() {
  final _this = this as LoginOtpSigninVerifyScreenPageConfig;
  return 'LoginOtpSigninVerifyScreenPageConfig(countdownRepeatIntervalSeconds: ${_this.countdownRepeatIntervalSeconds})';
}


}

/// @nodoc
abstract mixin class $LoginOtpSigninVerifyScreenPageConfigCopyWith<$Res>  {
  factory $LoginOtpSigninVerifyScreenPageConfigCopyWith(LoginOtpSigninVerifyScreenPageConfig value, $Res Function(LoginOtpSigninVerifyScreenPageConfig) _then) = _$LoginOtpSigninVerifyScreenPageConfigCopyWithImpl;
@useResult
$Res call({
 int countdownRepeatIntervalSeconds
});




}
/// @nodoc
class _$LoginOtpSigninVerifyScreenPageConfigCopyWithImpl<$Res>
    implements $LoginOtpSigninVerifyScreenPageConfigCopyWith<$Res> {
  _$LoginOtpSigninVerifyScreenPageConfigCopyWithImpl(this._self, this._then);

  final LoginOtpSigninVerifyScreenPageConfig _self;
  final $Res Function(LoginOtpSigninVerifyScreenPageConfig) _then;

/// Create a copy of LoginOtpSigninVerifyScreenPageConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? countdownRepeatIntervalSeconds = null,}) {
  return _then(LoginOtpSigninVerifyScreenPageConfig(
countdownRepeatIntervalSeconds: null == countdownRepeatIntervalSeconds ? _self.countdownRepeatIntervalSeconds : countdownRepeatIntervalSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [LoginOtpSigninVerifyScreenPageConfig].
extension LoginOtpSigninVerifyScreenPageConfigPatterns on LoginOtpSigninVerifyScreenPageConfig {
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
mixin _$LoginSignupVerifyScreenPageConfig {


/// Create a copy of LoginSignupVerifyScreenPageConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoginSignupVerifyScreenPageConfigCopyWith<LoginSignupVerifyScreenPageConfig> get copyWith => _$LoginSignupVerifyScreenPageConfigCopyWithImpl<LoginSignupVerifyScreenPageConfig>(this as LoginSignupVerifyScreenPageConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LoginSignupVerifyScreenPageConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoginSignupVerifyScreenPageConfig&&(identical(other.countdownRepeatIntervalSeconds, _this.countdownRepeatIntervalSeconds) || other.countdownRepeatIntervalSeconds == _this.countdownRepeatIntervalSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LoginSignupVerifyScreenPageConfig;
  return Object.hash(runtimeType,_this.countdownRepeatIntervalSeconds);
}

@override
String toString() {
  final _this = this as LoginSignupVerifyScreenPageConfig;
  return 'LoginSignupVerifyScreenPageConfig(countdownRepeatIntervalSeconds: ${_this.countdownRepeatIntervalSeconds})';
}


}

/// @nodoc
abstract mixin class $LoginSignupVerifyScreenPageConfigCopyWith<$Res>  {
  factory $LoginSignupVerifyScreenPageConfigCopyWith(LoginSignupVerifyScreenPageConfig value, $Res Function(LoginSignupVerifyScreenPageConfig) _then) = _$LoginSignupVerifyScreenPageConfigCopyWithImpl;
@useResult
$Res call({
 int countdownRepeatIntervalSeconds
});




}
/// @nodoc
class _$LoginSignupVerifyScreenPageConfigCopyWithImpl<$Res>
    implements $LoginSignupVerifyScreenPageConfigCopyWith<$Res> {
  _$LoginSignupVerifyScreenPageConfigCopyWithImpl(this._self, this._then);

  final LoginSignupVerifyScreenPageConfig _self;
  final $Res Function(LoginSignupVerifyScreenPageConfig) _then;

/// Create a copy of LoginSignupVerifyScreenPageConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? countdownRepeatIntervalSeconds = null,}) {
  return _then(LoginSignupVerifyScreenPageConfig(
countdownRepeatIntervalSeconds: null == countdownRepeatIntervalSeconds ? _self.countdownRepeatIntervalSeconds : countdownRepeatIntervalSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [LoginSignupVerifyScreenPageConfig].
extension LoginSignupVerifyScreenPageConfigPatterns on LoginSignupVerifyScreenPageConfig {
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
mixin _$LoginModeSelectPageConfig {


/// Create a copy of LoginModeSelectPageConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoginModeSelectPageConfigCopyWith<LoginModeSelectPageConfig> get copyWith => _$LoginModeSelectPageConfigCopyWithImpl<LoginModeSelectPageConfig>(this as LoginModeSelectPageConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LoginModeSelectPageConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoginModeSelectPageConfig&&(identical(other.themeOverride, _this.themeOverride) || other.themeOverride == _this.themeOverride)&&(identical(other.systemUiOverlayStyle, _this.systemUiOverlayStyle) || other.systemUiOverlayStyle == _this.systemUiOverlayStyle)&&(identical(other.mainLogo, _this.mainLogo) || other.mainLogo == _this.mainLogo)&&(identical(other.buttonLoginStyleType, _this.buttonLoginStyleType) || other.buttonLoginStyleType == _this.buttonLoginStyleType)&&(identical(other.buttonSignupStyleType, _this.buttonSignupStyleType) || other.buttonSignupStyleType == _this.buttonSignupStyleType)&&(identical(other.background, _this.background) || other.background == _this.background)&&(identical(other.greetingTextStyle, _this.greetingTextStyle) || other.greetingTextStyle == _this.greetingTextStyle)&&(identical(other.appBarBlurredSurface, _this.appBarBlurredSurface) || other.appBarBlurredSurface == _this.appBarBlurredSurface)&&(identical(other.appBarStyle, _this.appBarStyle) || other.appBarStyle == _this.appBarStyle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LoginModeSelectPageConfig;
  return Object.hash(runtimeType,_this.themeOverride,_this.systemUiOverlayStyle,_this.mainLogo,_this.buttonLoginStyleType,_this.buttonSignupStyleType,_this.background,_this.greetingTextStyle,_this.appBarBlurredSurface,_this.appBarStyle);
}

@override
String toString() {
  final _this = this as LoginModeSelectPageConfig;
  return 'LoginModeSelectPageConfig(themeOverride: ${_this.themeOverride}, systemUiOverlayStyle: ${_this.systemUiOverlayStyle}, mainLogo: ${_this.mainLogo}, buttonLoginStyleType: ${_this.buttonLoginStyleType}, buttonSignupStyleType: ${_this.buttonSignupStyleType}, background: ${_this.background}, greetingTextStyle: ${_this.greetingTextStyle}, appBarBlurredSurface: ${_this.appBarBlurredSurface}, appBarStyle: ${_this.appBarStyle})';
}


}

/// @nodoc
abstract mixin class $LoginModeSelectPageConfigCopyWith<$Res>  {
  factory $LoginModeSelectPageConfigCopyWith(LoginModeSelectPageConfig value, $Res Function(LoginModeSelectPageConfig) _then) = _$LoginModeSelectPageConfigCopyWithImpl;
@useResult
$Res call({
 ThemeOverrideConfig themeOverride, OverlayStyleModel? systemUiOverlayStyle, ImageSource? mainLogo, ElevatedButtonStyleType buttonLoginStyleType, ElevatedButtonStyleType buttonSignupStyleType, PageBackground? background, TextStyleConfig? greetingTextStyle, BlurredSurfaceConfig? appBarBlurredSurface, AppBarConfig? appBarStyle
});




}
/// @nodoc
class _$LoginModeSelectPageConfigCopyWithImpl<$Res>
    implements $LoginModeSelectPageConfigCopyWith<$Res> {
  _$LoginModeSelectPageConfigCopyWithImpl(this._self, this._then);

  final LoginModeSelectPageConfig _self;
  final $Res Function(LoginModeSelectPageConfig) _then;

/// Create a copy of LoginModeSelectPageConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? themeOverride = null,Object? systemUiOverlayStyle = freezed,Object? mainLogo = freezed,Object? buttonLoginStyleType = null,Object? buttonSignupStyleType = null,Object? background = freezed,Object? greetingTextStyle = freezed,Object? appBarBlurredSurface = freezed,Object? appBarStyle = freezed,}) {
  return _then(LoginModeSelectPageConfig(
themeOverride: null == themeOverride ? _self.themeOverride : themeOverride // ignore: cast_nullable_to_non_nullable
as ThemeOverrideConfig,systemUiOverlayStyle: freezed == systemUiOverlayStyle ? _self.systemUiOverlayStyle : systemUiOverlayStyle // ignore: cast_nullable_to_non_nullable
as OverlayStyleModel?,mainLogo: freezed == mainLogo ? _self.mainLogo : mainLogo // ignore: cast_nullable_to_non_nullable
as ImageSource?,buttonLoginStyleType: null == buttonLoginStyleType ? _self.buttonLoginStyleType : buttonLoginStyleType // ignore: cast_nullable_to_non_nullable
as ElevatedButtonStyleType,buttonSignupStyleType: null == buttonSignupStyleType ? _self.buttonSignupStyleType : buttonSignupStyleType // ignore: cast_nullable_to_non_nullable
as ElevatedButtonStyleType,background: freezed == background ? _self.background : background // ignore: cast_nullable_to_non_nullable
as PageBackground?,greetingTextStyle: freezed == greetingTextStyle ? _self.greetingTextStyle : greetingTextStyle // ignore: cast_nullable_to_non_nullable
as TextStyleConfig?,appBarBlurredSurface: freezed == appBarBlurredSurface ? _self.appBarBlurredSurface : appBarBlurredSurface // ignore: cast_nullable_to_non_nullable
as BlurredSurfaceConfig?,appBarStyle: freezed == appBarStyle ? _self.appBarStyle : appBarStyle // ignore: cast_nullable_to_non_nullable
as AppBarConfig?,
  ));
}

}


/// Adds pattern-matching-related methods to [LoginModeSelectPageConfig].
extension LoginModeSelectPageConfigPatterns on LoginModeSelectPageConfig {
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
mixin _$LoginSwitchPageConfig {


/// Create a copy of LoginSwitchPageConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoginSwitchPageConfigCopyWith<LoginSwitchPageConfig> get copyWith => _$LoginSwitchPageConfigCopyWithImpl<LoginSwitchPageConfig>(this as LoginSwitchPageConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LoginSwitchPageConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoginSwitchPageConfig&&(identical(other.themeOverride, _this.themeOverride) || other.themeOverride == _this.themeOverride)&&(identical(other.mainLogo, _this.mainLogo) || other.mainLogo == _this.mainLogo)&&(identical(other.background, _this.background) || other.background == _this.background)&&(identical(other.segmentButtonStyle, _this.segmentButtonStyle) || other.segmentButtonStyle == _this.segmentButtonStyle)&&(identical(other.appBarBlurredSurface, _this.appBarBlurredSurface) || other.appBarBlurredSurface == _this.appBarBlurredSurface)&&(identical(other.appBarStyle, _this.appBarStyle) || other.appBarStyle == _this.appBarStyle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LoginSwitchPageConfig;
  return Object.hash(runtimeType,_this.themeOverride,_this.mainLogo,_this.background,_this.segmentButtonStyle,_this.appBarBlurredSurface,_this.appBarStyle);
}

@override
String toString() {
  final _this = this as LoginSwitchPageConfig;
  return 'LoginSwitchPageConfig(themeOverride: ${_this.themeOverride}, mainLogo: ${_this.mainLogo}, background: ${_this.background}, segmentButtonStyle: ${_this.segmentButtonStyle}, appBarBlurredSurface: ${_this.appBarBlurredSurface}, appBarStyle: ${_this.appBarStyle})';
}


}

/// @nodoc
abstract mixin class $LoginSwitchPageConfigCopyWith<$Res>  {
  factory $LoginSwitchPageConfigCopyWith(LoginSwitchPageConfig value, $Res Function(LoginSwitchPageConfig) _then) = _$LoginSwitchPageConfigCopyWithImpl;
@useResult
$Res call({
 ImageSource? mainLogo, PageBackground? background, ThemeOverrideConfig themeOverride, ButtonStyleConfig? segmentButtonStyle, BlurredSurfaceConfig? appBarBlurredSurface, AppBarConfig? appBarStyle
});




}
/// @nodoc
class _$LoginSwitchPageConfigCopyWithImpl<$Res>
    implements $LoginSwitchPageConfigCopyWith<$Res> {
  _$LoginSwitchPageConfigCopyWithImpl(this._self, this._then);

  final LoginSwitchPageConfig _self;
  final $Res Function(LoginSwitchPageConfig) _then;

/// Create a copy of LoginSwitchPageConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mainLogo = freezed,Object? background = freezed,Object? themeOverride = null,Object? segmentButtonStyle = freezed,Object? appBarBlurredSurface = freezed,Object? appBarStyle = freezed,}) {
  return _then(LoginSwitchPageConfig(
mainLogo: freezed == mainLogo ? _self.mainLogo : mainLogo // ignore: cast_nullable_to_non_nullable
as ImageSource?,background: freezed == background ? _self.background : background // ignore: cast_nullable_to_non_nullable
as PageBackground?,themeOverride: null == themeOverride ? _self.themeOverride : themeOverride // ignore: cast_nullable_to_non_nullable
as ThemeOverrideConfig,segmentButtonStyle: freezed == segmentButtonStyle ? _self.segmentButtonStyle : segmentButtonStyle // ignore: cast_nullable_to_non_nullable
as ButtonStyleConfig?,appBarBlurredSurface: freezed == appBarBlurredSurface ? _self.appBarBlurredSurface : appBarBlurredSurface // ignore: cast_nullable_to_non_nullable
as BlurredSurfaceConfig?,appBarStyle: freezed == appBarStyle ? _self.appBarStyle : appBarStyle // ignore: cast_nullable_to_non_nullable
as AppBarConfig?,
  ));
}

}


/// Adds pattern-matching-related methods to [LoginSwitchPageConfig].
extension LoginSwitchPageConfigPatterns on LoginSwitchPageConfig {
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
mixin _$AboutPageConfig {


/// Create a copy of AboutPageConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AboutPageConfigCopyWith<AboutPageConfig> get copyWith => _$AboutPageConfigCopyWithImpl<AboutPageConfig>(this as AboutPageConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AboutPageConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AboutPageConfig&&(identical(other.mainLogo, _this.mainLogo) || other.mainLogo == _this.mainLogo)&&(identical(other.metadata, _this.metadata) || other.metadata == _this.metadata)&&(identical(other.background, _this.background) || other.background == _this.background)&&(identical(other.appBarBlurredSurface, _this.appBarBlurredSurface) || other.appBarBlurredSurface == _this.appBarBlurredSurface)&&(identical(other.appBarStyle, _this.appBarStyle) || other.appBarStyle == _this.appBarStyle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AboutPageConfig;
  return Object.hash(runtimeType,_this.mainLogo,_this.metadata,_this.background,_this.appBarBlurredSurface,_this.appBarStyle);
}

@override
String toString() {
  final _this = this as AboutPageConfig;
  return 'AboutPageConfig(mainLogo: ${_this.mainLogo}, metadata: ${_this.metadata}, background: ${_this.background}, appBarBlurredSurface: ${_this.appBarBlurredSurface}, appBarStyle: ${_this.appBarStyle})';
}


}

/// @nodoc
abstract mixin class $AboutPageConfigCopyWith<$Res>  {
  factory $AboutPageConfigCopyWith(AboutPageConfig value, $Res Function(AboutPageConfig) _then) = _$AboutPageConfigCopyWithImpl;
@useResult
$Res call({
 ImageSource? mainLogo, Metadata metadata, PageBackground? background, BlurredSurfaceConfig? appBarBlurredSurface, AppBarConfig? appBarStyle
});




}
/// @nodoc
class _$AboutPageConfigCopyWithImpl<$Res>
    implements $AboutPageConfigCopyWith<$Res> {
  _$AboutPageConfigCopyWithImpl(this._self, this._then);

  final AboutPageConfig _self;
  final $Res Function(AboutPageConfig) _then;

/// Create a copy of AboutPageConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mainLogo = freezed,Object? metadata = null,Object? background = freezed,Object? appBarBlurredSurface = freezed,Object? appBarStyle = freezed,}) {
  return _then(AboutPageConfig(
mainLogo: freezed == mainLogo ? _self.mainLogo : mainLogo // ignore: cast_nullable_to_non_nullable
as ImageSource?,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Metadata,background: freezed == background ? _self.background : background // ignore: cast_nullable_to_non_nullable
as PageBackground?,appBarBlurredSurface: freezed == appBarBlurredSurface ? _self.appBarBlurredSurface : appBarBlurredSurface // ignore: cast_nullable_to_non_nullable
as BlurredSurfaceConfig?,appBarStyle: freezed == appBarStyle ? _self.appBarStyle : appBarStyle // ignore: cast_nullable_to_non_nullable
as AppBarConfig?,
  ));
}

}


/// Adds pattern-matching-related methods to [AboutPageConfig].
extension AboutPageConfigPatterns on AboutPageConfig {
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
mixin _$CallPageConfig {


/// Create a copy of CallPageConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CallPageConfigCopyWith<CallPageConfig> get copyWith => _$CallPageConfigCopyWithImpl<CallPageConfig>(this as CallPageConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CallPageConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CallPageConfig&&(identical(other.systemUiOverlayStyle, _this.systemUiOverlayStyle) || other.systemUiOverlayStyle == _this.systemUiOverlayStyle)&&(identical(other.appBarStyle, _this.appBarStyle) || other.appBarStyle == _this.appBarStyle)&&(identical(other.callInfo, _this.callInfo) || other.callInfo == _this.callInfo)&&(identical(other.callList, _this.callList) || other.callList == _this.callList)&&(identical(other.actingOnHint, _this.actingOnHint) || other.actingOnHint == _this.actingOnHint)&&(identical(other.actions, _this.actions) || other.actions == _this.actions)&&(identical(other.background, _this.background) || other.background == _this.background)&&(identical(other.appBarBlurredSurface, _this.appBarBlurredSurface) || other.appBarBlurredSurface == _this.appBarBlurredSurface));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CallPageConfig;
  return Object.hash(runtimeType,_this.systemUiOverlayStyle,_this.appBarStyle,_this.callInfo,_this.callList,_this.actingOnHint,_this.actions,_this.background,_this.appBarBlurredSurface);
}

@override
String toString() {
  final _this = this as CallPageConfig;
  return 'CallPageConfig(systemUiOverlayStyle: ${_this.systemUiOverlayStyle}, appBarStyle: ${_this.appBarStyle}, callInfo: ${_this.callInfo}, callList: ${_this.callList}, actingOnHint: ${_this.actingOnHint}, actions: ${_this.actions}, background: ${_this.background}, appBarBlurredSurface: ${_this.appBarBlurredSurface})';
}


}

/// @nodoc
abstract mixin class $CallPageConfigCopyWith<$Res>  {
  factory $CallPageConfigCopyWith(CallPageConfig value, $Res Function(CallPageConfig) _then) = _$CallPageConfigCopyWithImpl;
@useResult
$Res call({
 OverlayStyleModel? systemUiOverlayStyle, CallPageInfoConfig? callInfo, CallPageListConfig? callList, CallPageHintConfig? actingOnHint, CallPageActionsConfig? actions, PageBackground? background, AppBarConfig? appBarStyle, BlurredSurfaceConfig? appBarBlurredSurface
});




}
/// @nodoc
class _$CallPageConfigCopyWithImpl<$Res>
    implements $CallPageConfigCopyWith<$Res> {
  _$CallPageConfigCopyWithImpl(this._self, this._then);

  final CallPageConfig _self;
  final $Res Function(CallPageConfig) _then;

/// Create a copy of CallPageConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? systemUiOverlayStyle = freezed,Object? callInfo = freezed,Object? callList = freezed,Object? actingOnHint = freezed,Object? actions = freezed,Object? background = freezed,Object? appBarStyle = freezed,Object? appBarBlurredSurface = freezed,}) {
  return _then(CallPageConfig(
systemUiOverlayStyle: freezed == systemUiOverlayStyle ? _self.systemUiOverlayStyle : systemUiOverlayStyle // ignore: cast_nullable_to_non_nullable
as OverlayStyleModel?,callInfo: freezed == callInfo ? _self.callInfo : callInfo // ignore: cast_nullable_to_non_nullable
as CallPageInfoConfig?,callList: freezed == callList ? _self.callList : callList // ignore: cast_nullable_to_non_nullable
as CallPageListConfig?,actingOnHint: freezed == actingOnHint ? _self.actingOnHint : actingOnHint // ignore: cast_nullable_to_non_nullable
as CallPageHintConfig?,actions: freezed == actions ? _self.actions : actions // ignore: cast_nullable_to_non_nullable
as CallPageActionsConfig?,background: freezed == background ? _self.background : background // ignore: cast_nullable_to_non_nullable
as PageBackground?,appBarStyle: freezed == appBarStyle ? _self.appBarStyle : appBarStyle // ignore: cast_nullable_to_non_nullable
as AppBarConfig?,appBarBlurredSurface: freezed == appBarBlurredSurface ? _self.appBarBlurredSurface : appBarBlurredSurface // ignore: cast_nullable_to_non_nullable
as BlurredSurfaceConfig?,
  ));
}

}


/// Adds pattern-matching-related methods to [CallPageConfig].
extension CallPageConfigPatterns on CallPageConfig {
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
mixin _$CallPageActionsConfig {


/// Create a copy of CallPageActionsConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CallPageActionsConfigCopyWith<CallPageActionsConfig> get copyWith => _$CallPageActionsConfigCopyWithImpl<CallPageActionsConfig>(this as CallPageActionsConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CallPageActionsConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CallPageActionsConfig&&(identical(other.callStart, _this.callStart) || other.callStart == _this.callStart)&&(identical(other.hangup, _this.hangup) || other.hangup == _this.hangup)&&(identical(other.transfer, _this.transfer) || other.transfer == _this.transfer)&&(identical(other.camera, _this.camera) || other.camera == _this.camera)&&(identical(other.muted, _this.muted) || other.muted == _this.muted)&&(identical(other.speaker, _this.speaker) || other.speaker == _this.speaker)&&(identical(other.held, _this.held) || other.held == _this.held)&&(identical(other.swap, _this.swap) || other.swap == _this.swap)&&(identical(other.key, _this.key) || other.key == _this.key)&&(identical(other.keypadInputStyle, _this.keypadInputStyle) || other.keypadInputStyle == _this.keypadInputStyle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CallPageActionsConfig;
  return Object.hash(runtimeType,_this.callStart,_this.hangup,_this.transfer,_this.camera,_this.muted,_this.speaker,_this.held,_this.swap,_this.key,_this.keypadInputStyle);
}

@override
String toString() {
  final _this = this as CallPageActionsConfig;
  return 'CallPageActionsConfig(callStart: ${_this.callStart}, hangup: ${_this.hangup}, transfer: ${_this.transfer}, camera: ${_this.camera}, muted: ${_this.muted}, speaker: ${_this.speaker}, held: ${_this.held}, swap: ${_this.swap}, key: ${_this.key}, keypadInputStyle: ${_this.keypadInputStyle})';
}


}

/// @nodoc
abstract mixin class $CallPageActionsConfigCopyWith<$Res>  {
  factory $CallPageActionsConfigCopyWith(CallPageActionsConfig value, $Res Function(CallPageActionsConfig) _then) = _$CallPageActionsConfigCopyWithImpl;
@useResult
$Res call({
 ButtonStyleConfig callStart, ButtonStyleConfig hangup, ButtonStyleConfig transfer, ButtonStyleConfig camera, ButtonStyleConfig muted, ButtonStyleConfig speaker, ButtonStyleConfig held, ButtonStyleConfig swap, ButtonStyleConfig key, TextStyleConfig? keypadInputStyle
});




}
/// @nodoc
class _$CallPageActionsConfigCopyWithImpl<$Res>
    implements $CallPageActionsConfigCopyWith<$Res> {
  _$CallPageActionsConfigCopyWithImpl(this._self, this._then);

  final CallPageActionsConfig _self;
  final $Res Function(CallPageActionsConfig) _then;

/// Create a copy of CallPageActionsConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? callStart = null,Object? hangup = null,Object? transfer = null,Object? camera = null,Object? muted = null,Object? speaker = null,Object? held = null,Object? swap = null,Object? key = null,Object? keypadInputStyle = freezed,}) {
  return _then(CallPageActionsConfig(
callStart: null == callStart ? _self.callStart : callStart // ignore: cast_nullable_to_non_nullable
as ButtonStyleConfig,hangup: null == hangup ? _self.hangup : hangup // ignore: cast_nullable_to_non_nullable
as ButtonStyleConfig,transfer: null == transfer ? _self.transfer : transfer // ignore: cast_nullable_to_non_nullable
as ButtonStyleConfig,camera: null == camera ? _self.camera : camera // ignore: cast_nullable_to_non_nullable
as ButtonStyleConfig,muted: null == muted ? _self.muted : muted // ignore: cast_nullable_to_non_nullable
as ButtonStyleConfig,speaker: null == speaker ? _self.speaker : speaker // ignore: cast_nullable_to_non_nullable
as ButtonStyleConfig,held: null == held ? _self.held : held // ignore: cast_nullable_to_non_nullable
as ButtonStyleConfig,swap: null == swap ? _self.swap : swap // ignore: cast_nullable_to_non_nullable
as ButtonStyleConfig,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as ButtonStyleConfig,keypadInputStyle: freezed == keypadInputStyle ? _self.keypadInputStyle : keypadInputStyle // ignore: cast_nullable_to_non_nullable
as TextStyleConfig?,
  ));
}

}


/// Adds pattern-matching-related methods to [CallPageActionsConfig].
extension CallPageActionsConfigPatterns on CallPageActionsConfig {
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
mixin _$CallPageInfoConfig {


/// Create a copy of CallPageInfoConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CallPageInfoConfigCopyWith<CallPageInfoConfig> get copyWith => _$CallPageInfoConfigCopyWithImpl<CallPageInfoConfig>(this as CallPageInfoConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CallPageInfoConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CallPageInfoConfig&&(identical(other.usernameTextStyle, _this.usernameTextStyle) || other.usernameTextStyle == _this.usernameTextStyle)&&(identical(other.numberTextStyle, _this.numberTextStyle) || other.numberTextStyle == _this.numberTextStyle)&&(identical(other.callStatusTextStyle, _this.callStatusTextStyle) || other.callStatusTextStyle == _this.callStatusTextStyle)&&(identical(other.processingStatusTextStyle, _this.processingStatusTextStyle) || other.processingStatusTextStyle == _this.processingStatusTextStyle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CallPageInfoConfig;
  return Object.hash(runtimeType,_this.usernameTextStyle,_this.numberTextStyle,_this.callStatusTextStyle,_this.processingStatusTextStyle);
}

@override
String toString() {
  final _this = this as CallPageInfoConfig;
  return 'CallPageInfoConfig(usernameTextStyle: ${_this.usernameTextStyle}, numberTextStyle: ${_this.numberTextStyle}, callStatusTextStyle: ${_this.callStatusTextStyle}, processingStatusTextStyle: ${_this.processingStatusTextStyle})';
}


}

/// @nodoc
abstract mixin class $CallPageInfoConfigCopyWith<$Res>  {
  factory $CallPageInfoConfigCopyWith(CallPageInfoConfig value, $Res Function(CallPageInfoConfig) _then) = _$CallPageInfoConfigCopyWithImpl;
@useResult
$Res call({
 TextStyleConfig? usernameTextStyle, TextStyleConfig? numberTextStyle, TextStyleConfig? callStatusTextStyle, TextStyleConfig? processingStatusTextStyle
});




}
/// @nodoc
class _$CallPageInfoConfigCopyWithImpl<$Res>
    implements $CallPageInfoConfigCopyWith<$Res> {
  _$CallPageInfoConfigCopyWithImpl(this._self, this._then);

  final CallPageInfoConfig _self;
  final $Res Function(CallPageInfoConfig) _then;

/// Create a copy of CallPageInfoConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? usernameTextStyle = freezed,Object? numberTextStyle = freezed,Object? callStatusTextStyle = freezed,Object? processingStatusTextStyle = freezed,}) {
  return _then(CallPageInfoConfig(
usernameTextStyle: freezed == usernameTextStyle ? _self.usernameTextStyle : usernameTextStyle // ignore: cast_nullable_to_non_nullable
as TextStyleConfig?,numberTextStyle: freezed == numberTextStyle ? _self.numberTextStyle : numberTextStyle // ignore: cast_nullable_to_non_nullable
as TextStyleConfig?,callStatusTextStyle: freezed == callStatusTextStyle ? _self.callStatusTextStyle : callStatusTextStyle // ignore: cast_nullable_to_non_nullable
as TextStyleConfig?,processingStatusTextStyle: freezed == processingStatusTextStyle ? _self.processingStatusTextStyle : processingStatusTextStyle // ignore: cast_nullable_to_non_nullable
as TextStyleConfig?,
  ));
}

}


/// Adds pattern-matching-related methods to [CallPageInfoConfig].
extension CallPageInfoConfigPatterns on CallPageInfoConfig {
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
mixin _$CallPageListConfig {


/// Create a copy of CallPageListConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CallPageListConfigCopyWith<CallPageListConfig> get copyWith => _$CallPageListConfigCopyWithImpl<CallPageListConfig>(this as CallPageListConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CallPageListConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CallPageListConfig&&(identical(other.rowBackgroundColor, _this.rowBackgroundColor) || other.rowBackgroundColor == _this.rowBackgroundColor)&&(identical(other.rowFocusedBackgroundColor, _this.rowFocusedBackgroundColor) || other.rowFocusedBackgroundColor == _this.rowFocusedBackgroundColor)&&(identical(other.rowFocusedBorderColor, _this.rowFocusedBorderColor) || other.rowFocusedBorderColor == _this.rowFocusedBorderColor)&&(identical(other.dotRingingColor, _this.dotRingingColor) || other.dotRingingColor == _this.dotRingingColor)&&(identical(other.dotOnCallColor, _this.dotOnCallColor) || other.dotOnCallColor == _this.dotOnCallColor)&&(identical(other.dotHeldColor, _this.dotHeldColor) || other.dotHeldColor == _this.dotHeldColor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CallPageListConfig;
  return Object.hash(runtimeType,_this.rowBackgroundColor,_this.rowFocusedBackgroundColor,_this.rowFocusedBorderColor,_this.dotRingingColor,_this.dotOnCallColor,_this.dotHeldColor);
}

@override
String toString() {
  final _this = this as CallPageListConfig;
  return 'CallPageListConfig(rowBackgroundColor: ${_this.rowBackgroundColor}, rowFocusedBackgroundColor: ${_this.rowFocusedBackgroundColor}, rowFocusedBorderColor: ${_this.rowFocusedBorderColor}, dotRingingColor: ${_this.dotRingingColor}, dotOnCallColor: ${_this.dotOnCallColor}, dotHeldColor: ${_this.dotHeldColor})';
}


}

/// @nodoc
abstract mixin class $CallPageListConfigCopyWith<$Res>  {
  factory $CallPageListConfigCopyWith(CallPageListConfig value, $Res Function(CallPageListConfig) _then) = _$CallPageListConfigCopyWithImpl;
@useResult
$Res call({
 String? rowBackgroundColor, String? rowFocusedBackgroundColor, String? rowFocusedBorderColor, String? dotRingingColor, String? dotOnCallColor, String? dotHeldColor
});




}
/// @nodoc
class _$CallPageListConfigCopyWithImpl<$Res>
    implements $CallPageListConfigCopyWith<$Res> {
  _$CallPageListConfigCopyWithImpl(this._self, this._then);

  final CallPageListConfig _self;
  final $Res Function(CallPageListConfig) _then;

/// Create a copy of CallPageListConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rowBackgroundColor = freezed,Object? rowFocusedBackgroundColor = freezed,Object? rowFocusedBorderColor = freezed,Object? dotRingingColor = freezed,Object? dotOnCallColor = freezed,Object? dotHeldColor = freezed,}) {
  return _then(CallPageListConfig(
rowBackgroundColor: freezed == rowBackgroundColor ? _self.rowBackgroundColor : rowBackgroundColor // ignore: cast_nullable_to_non_nullable
as String?,rowFocusedBackgroundColor: freezed == rowFocusedBackgroundColor ? _self.rowFocusedBackgroundColor : rowFocusedBackgroundColor // ignore: cast_nullable_to_non_nullable
as String?,rowFocusedBorderColor: freezed == rowFocusedBorderColor ? _self.rowFocusedBorderColor : rowFocusedBorderColor // ignore: cast_nullable_to_non_nullable
as String?,dotRingingColor: freezed == dotRingingColor ? _self.dotRingingColor : dotRingingColor // ignore: cast_nullable_to_non_nullable
as String?,dotOnCallColor: freezed == dotOnCallColor ? _self.dotOnCallColor : dotOnCallColor // ignore: cast_nullable_to_non_nullable
as String?,dotHeldColor: freezed == dotHeldColor ? _self.dotHeldColor : dotHeldColor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CallPageListConfig].
extension CallPageListConfigPatterns on CallPageListConfig {
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
mixin _$CallPageHintConfig {


/// Create a copy of CallPageHintConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CallPageHintConfigCopyWith<CallPageHintConfig> get copyWith => _$CallPageHintConfigCopyWithImpl<CallPageHintConfig>(this as CallPageHintConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CallPageHintConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CallPageHintConfig&&(identical(other.backgroundColor, _this.backgroundColor) || other.backgroundColor == _this.backgroundColor)&&(identical(other.affectedNameColor, _this.affectedNameColor) || other.affectedNameColor == _this.affectedNameColor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CallPageHintConfig;
  return Object.hash(runtimeType,_this.backgroundColor,_this.affectedNameColor);
}

@override
String toString() {
  final _this = this as CallPageHintConfig;
  return 'CallPageHintConfig(backgroundColor: ${_this.backgroundColor}, affectedNameColor: ${_this.affectedNameColor})';
}


}

/// @nodoc
abstract mixin class $CallPageHintConfigCopyWith<$Res>  {
  factory $CallPageHintConfigCopyWith(CallPageHintConfig value, $Res Function(CallPageHintConfig) _then) = _$CallPageHintConfigCopyWithImpl;
@useResult
$Res call({
 String? backgroundColor, String? affectedNameColor
});




}
/// @nodoc
class _$CallPageHintConfigCopyWithImpl<$Res>
    implements $CallPageHintConfigCopyWith<$Res> {
  _$CallPageHintConfigCopyWithImpl(this._self, this._then);

  final CallPageHintConfig _self;
  final $Res Function(CallPageHintConfig) _then;

/// Create a copy of CallPageHintConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? backgroundColor = freezed,Object? affectedNameColor = freezed,}) {
  return _then(CallPageHintConfig(
backgroundColor: freezed == backgroundColor ? _self.backgroundColor : backgroundColor // ignore: cast_nullable_to_non_nullable
as String?,affectedNameColor: freezed == affectedNameColor ? _self.affectedNameColor : affectedNameColor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CallPageHintConfig].
extension CallPageHintConfigPatterns on CallPageHintConfig {
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
mixin _$KeypadPageConfig {


/// Create a copy of KeypadPageConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KeypadPageConfigCopyWith<KeypadPageConfig> get copyWith => _$KeypadPageConfigCopyWithImpl<KeypadPageConfig>(this as KeypadPageConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as KeypadPageConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KeypadPageConfig&&(identical(other.systemUiOverlayStyle, _this.systemUiOverlayStyle) || other.systemUiOverlayStyle == _this.systemUiOverlayStyle)&&(identical(other.textField, _this.textField) || other.textField == _this.textField)&&(identical(other.contactName, _this.contactName) || other.contactName == _this.contactName)&&(identical(other.keypad, _this.keypad) || other.keypad == _this.keypad)&&(identical(other.actionpad, _this.actionpad) || other.actionpad == _this.actionpad)&&(identical(other.background, _this.background) || other.background == _this.background)&&(identical(other.themeOverride, _this.themeOverride) || other.themeOverride == _this.themeOverride)&&(identical(other.appBarBlurredSurface, _this.appBarBlurredSurface) || other.appBarBlurredSurface == _this.appBarBlurredSurface)&&(identical(other.appBarStyle, _this.appBarStyle) || other.appBarStyle == _this.appBarStyle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as KeypadPageConfig;
  return Object.hash(runtimeType,_this.systemUiOverlayStyle,_this.textField,_this.contactName,_this.keypad,_this.actionpad,_this.background,_this.themeOverride,_this.appBarBlurredSurface,_this.appBarStyle);
}

@override
String toString() {
  final _this = this as KeypadPageConfig;
  return 'KeypadPageConfig(systemUiOverlayStyle: ${_this.systemUiOverlayStyle}, textField: ${_this.textField}, contactName: ${_this.contactName}, keypad: ${_this.keypad}, actionpad: ${_this.actionpad}, background: ${_this.background}, themeOverride: ${_this.themeOverride}, appBarBlurredSurface: ${_this.appBarBlurredSurface}, appBarStyle: ${_this.appBarStyle})';
}


}

/// @nodoc
abstract mixin class $KeypadPageConfigCopyWith<$Res>  {
  factory $KeypadPageConfigCopyWith(KeypadPageConfig value, $Res Function(KeypadPageConfig) _then) = _$KeypadPageConfigCopyWithImpl;
@useResult
$Res call({
 OverlayStyleModel? systemUiOverlayStyle, TextFieldConfig? textField, TextFieldConfig? contactName, KeypadStyleConfig? keypad, ActionPadWidgetConfig? actionpad, PageBackground? background, ThemeOverrideConfig themeOverride, BlurredSurfaceConfig? appBarBlurredSurface, AppBarConfig? appBarStyle
});




}
/// @nodoc
class _$KeypadPageConfigCopyWithImpl<$Res>
    implements $KeypadPageConfigCopyWith<$Res> {
  _$KeypadPageConfigCopyWithImpl(this._self, this._then);

  final KeypadPageConfig _self;
  final $Res Function(KeypadPageConfig) _then;

/// Create a copy of KeypadPageConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? systemUiOverlayStyle = freezed,Object? textField = freezed,Object? contactName = freezed,Object? keypad = freezed,Object? actionpad = freezed,Object? background = freezed,Object? themeOverride = null,Object? appBarBlurredSurface = freezed,Object? appBarStyle = freezed,}) {
  return _then(KeypadPageConfig(
systemUiOverlayStyle: freezed == systemUiOverlayStyle ? _self.systemUiOverlayStyle : systemUiOverlayStyle // ignore: cast_nullable_to_non_nullable
as OverlayStyleModel?,textField: freezed == textField ? _self.textField : textField // ignore: cast_nullable_to_non_nullable
as TextFieldConfig?,contactName: freezed == contactName ? _self.contactName : contactName // ignore: cast_nullable_to_non_nullable
as TextFieldConfig?,keypad: freezed == keypad ? _self.keypad : keypad // ignore: cast_nullable_to_non_nullable
as KeypadStyleConfig?,actionpad: freezed == actionpad ? _self.actionpad : actionpad // ignore: cast_nullable_to_non_nullable
as ActionPadWidgetConfig?,background: freezed == background ? _self.background : background // ignore: cast_nullable_to_non_nullable
as PageBackground?,themeOverride: null == themeOverride ? _self.themeOverride : themeOverride // ignore: cast_nullable_to_non_nullable
as ThemeOverrideConfig,appBarBlurredSurface: freezed == appBarBlurredSurface ? _self.appBarBlurredSurface : appBarBlurredSurface // ignore: cast_nullable_to_non_nullable
as BlurredSurfaceConfig?,appBarStyle: freezed == appBarStyle ? _self.appBarStyle : appBarStyle // ignore: cast_nullable_to_non_nullable
as AppBarConfig?,
  ));
}

}


/// Adds pattern-matching-related methods to [KeypadPageConfig].
extension KeypadPageConfigPatterns on KeypadPageConfig {
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
mixin _$ActionPadWidgetConfig {


/// Create a copy of ActionPadWidgetConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActionPadWidgetConfigCopyWith<ActionPadWidgetConfig> get copyWith => _$ActionPadWidgetConfigCopyWithImpl<ActionPadWidgetConfig>(this as ActionPadWidgetConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ActionPadWidgetConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActionPadWidgetConfig&&(identical(other.callStart, _this.callStart) || other.callStart == _this.callStart)&&(identical(other.callTransfer, _this.callTransfer) || other.callTransfer == _this.callTransfer)&&(identical(other.backspace, _this.backspace) || other.backspace == _this.backspace));
}


@override
int get hashCode {
  final _this = this as ActionPadWidgetConfig;
  return Object.hash(runtimeType,_this.callStart,_this.callTransfer,_this.backspace);
}

@override
String toString() {
  final _this = this as ActionPadWidgetConfig;
  return 'ActionPadWidgetConfig(callStart: ${_this.callStart}, callTransfer: ${_this.callTransfer}, backspace: ${_this.backspace})';
}


}

/// @nodoc
abstract mixin class $ActionPadWidgetConfigCopyWith<$Res>  {
  factory $ActionPadWidgetConfigCopyWith(ActionPadWidgetConfig value, $Res Function(ActionPadWidgetConfig) _then) = _$ActionPadWidgetConfigCopyWithImpl;
@useResult
$Res call({
 ButtonStyleConfig callStart, ButtonStyleConfig callTransfer, ButtonStyleConfig backspace
});




}
/// @nodoc
class _$ActionPadWidgetConfigCopyWithImpl<$Res>
    implements $ActionPadWidgetConfigCopyWith<$Res> {
  _$ActionPadWidgetConfigCopyWithImpl(this._self, this._then);

  final ActionPadWidgetConfig _self;
  final $Res Function(ActionPadWidgetConfig) _then;

/// Create a copy of ActionPadWidgetConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? callStart = null,Object? callTransfer = null,Object? backspace = null,}) {
  return _then(ActionPadWidgetConfig(
callStart: null == callStart ? _self.callStart : callStart // ignore: cast_nullable_to_non_nullable
as ButtonStyleConfig,callTransfer: null == callTransfer ? _self.callTransfer : callTransfer // ignore: cast_nullable_to_non_nullable
as ButtonStyleConfig,backspace: null == backspace ? _self.backspace : backspace // ignore: cast_nullable_to_non_nullable
as ButtonStyleConfig,
  ));
}

}


/// Adds pattern-matching-related methods to [ActionPadWidgetConfig].
extension ActionPadWidgetConfigPatterns on ActionPadWidgetConfig {
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
mixin _$SettingsPageConfig {


/// Create a copy of SettingsPageConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingsPageConfigCopyWith<SettingsPageConfig> get copyWith => _$SettingsPageConfigCopyWithImpl<SettingsPageConfig>(this as SettingsPageConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SettingsPageConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsPageConfig&&(identical(other.themeOverride, _this.themeOverride) || other.themeOverride == _this.themeOverride)&&(identical(other.leadingIconsColor, _this.leadingIconsColor) || other.leadingIconsColor == _this.leadingIconsColor)&&(identical(other.userIconColor, _this.userIconColor) || other.userIconColor == _this.userIconColor)&&(identical(other.logoutIconColor, _this.logoutIconColor) || other.logoutIconColor == _this.logoutIconColor)&&(identical(other.groupTitleListTile, _this.groupTitleListTile) || other.groupTitleListTile == _this.groupTitleListTile)&&(identical(other.separator, _this.separator) || other.separator == _this.separator)&&(identical(other.background, _this.background) || other.background == _this.background)&&(identical(other.itemTextStyle, _this.itemTextStyle) || other.itemTextStyle == _this.itemTextStyle)&&(identical(other.appBarBlurredSurface, _this.appBarBlurredSurface) || other.appBarBlurredSurface == _this.appBarBlurredSurface)&&(identical(other.appBarStyle, _this.appBarStyle) || other.appBarStyle == _this.appBarStyle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SettingsPageConfig;
  return Object.hash(runtimeType,_this.themeOverride,_this.leadingIconsColor,_this.userIconColor,_this.logoutIconColor,_this.groupTitleListTile,_this.separator,_this.background,_this.itemTextStyle,_this.appBarBlurredSurface,_this.appBarStyle);
}

@override
String toString() {
  final _this = this as SettingsPageConfig;
  return 'SettingsPageConfig(themeOverride: ${_this.themeOverride}, leadingIconsColor: ${_this.leadingIconsColor}, userIconColor: ${_this.userIconColor}, logoutIconColor: ${_this.logoutIconColor}, groupTitleListTile: ${_this.groupTitleListTile}, separator: ${_this.separator}, background: ${_this.background}, itemTextStyle: ${_this.itemTextStyle}, appBarBlurredSurface: ${_this.appBarBlurredSurface}, appBarStyle: ${_this.appBarStyle})';
}


}

/// @nodoc
abstract mixin class $SettingsPageConfigCopyWith<$Res>  {
  factory $SettingsPageConfigCopyWith(SettingsPageConfig value, $Res Function(SettingsPageConfig) _then) = _$SettingsPageConfigCopyWithImpl;
@useResult
$Res call({
 ThemeOverrideConfig themeOverride, String? leadingIconsColor, String? userIconColor, String? logoutIconColor, GroupTitleListTileWidgetConfig? groupTitleListTile, SeparatorStyleConfig? separator, PageBackground? background, TextStyleConfig? itemTextStyle, BlurredSurfaceConfig? appBarBlurredSurface, AppBarConfig? appBarStyle
});




}
/// @nodoc
class _$SettingsPageConfigCopyWithImpl<$Res>
    implements $SettingsPageConfigCopyWith<$Res> {
  _$SettingsPageConfigCopyWithImpl(this._self, this._then);

  final SettingsPageConfig _self;
  final $Res Function(SettingsPageConfig) _then;

/// Create a copy of SettingsPageConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? themeOverride = null,Object? leadingIconsColor = freezed,Object? userIconColor = freezed,Object? logoutIconColor = freezed,Object? groupTitleListTile = freezed,Object? separator = freezed,Object? background = freezed,Object? itemTextStyle = freezed,Object? appBarBlurredSurface = freezed,Object? appBarStyle = freezed,}) {
  return _then(SettingsPageConfig(
themeOverride: null == themeOverride ? _self.themeOverride : themeOverride // ignore: cast_nullable_to_non_nullable
as ThemeOverrideConfig,leadingIconsColor: freezed == leadingIconsColor ? _self.leadingIconsColor : leadingIconsColor // ignore: cast_nullable_to_non_nullable
as String?,userIconColor: freezed == userIconColor ? _self.userIconColor : userIconColor // ignore: cast_nullable_to_non_nullable
as String?,logoutIconColor: freezed == logoutIconColor ? _self.logoutIconColor : logoutIconColor // ignore: cast_nullable_to_non_nullable
as String?,groupTitleListTile: freezed == groupTitleListTile ? _self.groupTitleListTile : groupTitleListTile // ignore: cast_nullable_to_non_nullable
as GroupTitleListTileWidgetConfig?,separator: freezed == separator ? _self.separator : separator // ignore: cast_nullable_to_non_nullable
as SeparatorStyleConfig?,background: freezed == background ? _self.background : background // ignore: cast_nullable_to_non_nullable
as PageBackground?,itemTextStyle: freezed == itemTextStyle ? _self.itemTextStyle : itemTextStyle // ignore: cast_nullable_to_non_nullable
as TextStyleConfig?,appBarBlurredSurface: freezed == appBarBlurredSurface ? _self.appBarBlurredSurface : appBarBlurredSurface // ignore: cast_nullable_to_non_nullable
as BlurredSurfaceConfig?,appBarStyle: freezed == appBarStyle ? _self.appBarStyle : appBarStyle // ignore: cast_nullable_to_non_nullable
as AppBarConfig?,
  ));
}

}


/// Adds pattern-matching-related methods to [SettingsPageConfig].
extension SettingsPageConfigPatterns on SettingsPageConfig {
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
mixin _$ContactsPageConfig {


/// Create a copy of ContactsPageConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContactsPageConfigCopyWith<ContactsPageConfig> get copyWith => _$ContactsPageConfigCopyWithImpl<ContactsPageConfig>(this as ContactsPageConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ContactsPageConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContactsPageConfig&&(identical(other.themeOverride, _this.themeOverride) || other.themeOverride == _this.themeOverride)&&(identical(other.background, _this.background) || other.background == _this.background)&&(identical(other.appBarBlurredSurface, _this.appBarBlurredSurface) || other.appBarBlurredSurface == _this.appBarBlurredSurface)&&(identical(other.appBarStyle, _this.appBarStyle) || other.appBarStyle == _this.appBarStyle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ContactsPageConfig;
  return Object.hash(runtimeType,_this.themeOverride,_this.background,_this.appBarBlurredSurface,_this.appBarStyle);
}

@override
String toString() {
  final _this = this as ContactsPageConfig;
  return 'ContactsPageConfig(themeOverride: ${_this.themeOverride}, background: ${_this.background}, appBarBlurredSurface: ${_this.appBarBlurredSurface}, appBarStyle: ${_this.appBarStyle})';
}


}

/// @nodoc
abstract mixin class $ContactsPageConfigCopyWith<$Res>  {
  factory $ContactsPageConfigCopyWith(ContactsPageConfig value, $Res Function(ContactsPageConfig) _then) = _$ContactsPageConfigCopyWithImpl;
@useResult
$Res call({
 ThemeOverrideConfig themeOverride, PageBackground? background, BlurredSurfaceConfig? appBarBlurredSurface, AppBarConfig? appBarStyle
});




}
/// @nodoc
class _$ContactsPageConfigCopyWithImpl<$Res>
    implements $ContactsPageConfigCopyWith<$Res> {
  _$ContactsPageConfigCopyWithImpl(this._self, this._then);

  final ContactsPageConfig _self;
  final $Res Function(ContactsPageConfig) _then;

/// Create a copy of ContactsPageConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? themeOverride = null,Object? background = freezed,Object? appBarBlurredSurface = freezed,Object? appBarStyle = freezed,}) {
  return _then(ContactsPageConfig(
themeOverride: null == themeOverride ? _self.themeOverride : themeOverride // ignore: cast_nullable_to_non_nullable
as ThemeOverrideConfig,background: freezed == background ? _self.background : background // ignore: cast_nullable_to_non_nullable
as PageBackground?,appBarBlurredSurface: freezed == appBarBlurredSurface ? _self.appBarBlurredSurface : appBarBlurredSurface // ignore: cast_nullable_to_non_nullable
as BlurredSurfaceConfig?,appBarStyle: freezed == appBarStyle ? _self.appBarStyle : appBarStyle // ignore: cast_nullable_to_non_nullable
as AppBarConfig?,
  ));
}

}


/// Adds pattern-matching-related methods to [ContactsPageConfig].
extension ContactsPageConfigPatterns on ContactsPageConfig {
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
mixin _$EmbeddedPageConfig {


/// Create a copy of EmbeddedPageConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmbeddedPageConfigCopyWith<EmbeddedPageConfig> get copyWith => _$EmbeddedPageConfigCopyWithImpl<EmbeddedPageConfig>(this as EmbeddedPageConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as EmbeddedPageConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmbeddedPageConfig&&(identical(other.themeOverride, _this.themeOverride) || other.themeOverride == _this.themeOverride)&&(identical(other.background, _this.background) || other.background == _this.background)&&(identical(other.appBarBlurredSurface, _this.appBarBlurredSurface) || other.appBarBlurredSurface == _this.appBarBlurredSurface)&&(identical(other.appBarStyle, _this.appBarStyle) || other.appBarStyle == _this.appBarStyle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as EmbeddedPageConfig;
  return Object.hash(runtimeType,_this.themeOverride,_this.background,_this.appBarBlurredSurface,_this.appBarStyle);
}

@override
String toString() {
  final _this = this as EmbeddedPageConfig;
  return 'EmbeddedPageConfig(themeOverride: ${_this.themeOverride}, background: ${_this.background}, appBarBlurredSurface: ${_this.appBarBlurredSurface}, appBarStyle: ${_this.appBarStyle})';
}


}

/// @nodoc
abstract mixin class $EmbeddedPageConfigCopyWith<$Res>  {
  factory $EmbeddedPageConfigCopyWith(EmbeddedPageConfig value, $Res Function(EmbeddedPageConfig) _then) = _$EmbeddedPageConfigCopyWithImpl;
@useResult
$Res call({
 ThemeOverrideConfig themeOverride, PageBackground? background, BlurredSurfaceConfig? appBarBlurredSurface, AppBarConfig? appBarStyle
});




}
/// @nodoc
class _$EmbeddedPageConfigCopyWithImpl<$Res>
    implements $EmbeddedPageConfigCopyWith<$Res> {
  _$EmbeddedPageConfigCopyWithImpl(this._self, this._then);

  final EmbeddedPageConfig _self;
  final $Res Function(EmbeddedPageConfig) _then;

/// Create a copy of EmbeddedPageConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? themeOverride = null,Object? background = freezed,Object? appBarBlurredSurface = freezed,Object? appBarStyle = freezed,}) {
  return _then(EmbeddedPageConfig(
themeOverride: null == themeOverride ? _self.themeOverride : themeOverride // ignore: cast_nullable_to_non_nullable
as ThemeOverrideConfig,background: freezed == background ? _self.background : background // ignore: cast_nullable_to_non_nullable
as PageBackground?,appBarBlurredSurface: freezed == appBarBlurredSurface ? _self.appBarBlurredSurface : appBarBlurredSurface // ignore: cast_nullable_to_non_nullable
as BlurredSurfaceConfig?,appBarStyle: freezed == appBarStyle ? _self.appBarStyle : appBarStyle // ignore: cast_nullable_to_non_nullable
as AppBarConfig?,
  ));
}

}


/// Adds pattern-matching-related methods to [EmbeddedPageConfig].
extension EmbeddedPageConfigPatterns on EmbeddedPageConfig {
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
mixin _$FavoritesPageConfig {


/// Create a copy of FavoritesPageConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FavoritesPageConfigCopyWith<FavoritesPageConfig> get copyWith => _$FavoritesPageConfigCopyWithImpl<FavoritesPageConfig>(this as FavoritesPageConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FavoritesPageConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FavoritesPageConfig&&(identical(other.themeOverride, _this.themeOverride) || other.themeOverride == _this.themeOverride)&&(identical(other.background, _this.background) || other.background == _this.background)&&(identical(other.appBarBlurredSurface, _this.appBarBlurredSurface) || other.appBarBlurredSurface == _this.appBarBlurredSurface)&&(identical(other.appBarStyle, _this.appBarStyle) || other.appBarStyle == _this.appBarStyle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as FavoritesPageConfig;
  return Object.hash(runtimeType,_this.themeOverride,_this.background,_this.appBarBlurredSurface,_this.appBarStyle);
}

@override
String toString() {
  final _this = this as FavoritesPageConfig;
  return 'FavoritesPageConfig(themeOverride: ${_this.themeOverride}, background: ${_this.background}, appBarBlurredSurface: ${_this.appBarBlurredSurface}, appBarStyle: ${_this.appBarStyle})';
}


}

/// @nodoc
abstract mixin class $FavoritesPageConfigCopyWith<$Res>  {
  factory $FavoritesPageConfigCopyWith(FavoritesPageConfig value, $Res Function(FavoritesPageConfig) _then) = _$FavoritesPageConfigCopyWithImpl;
@useResult
$Res call({
 ThemeOverrideConfig themeOverride, PageBackground? background, BlurredSurfaceConfig? appBarBlurredSurface, AppBarConfig? appBarStyle
});




}
/// @nodoc
class _$FavoritesPageConfigCopyWithImpl<$Res>
    implements $FavoritesPageConfigCopyWith<$Res> {
  _$FavoritesPageConfigCopyWithImpl(this._self, this._then);

  final FavoritesPageConfig _self;
  final $Res Function(FavoritesPageConfig) _then;

/// Create a copy of FavoritesPageConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? themeOverride = null,Object? background = freezed,Object? appBarBlurredSurface = freezed,Object? appBarStyle = freezed,}) {
  return _then(FavoritesPageConfig(
themeOverride: null == themeOverride ? _self.themeOverride : themeOverride // ignore: cast_nullable_to_non_nullable
as ThemeOverrideConfig,background: freezed == background ? _self.background : background // ignore: cast_nullable_to_non_nullable
as PageBackground?,appBarBlurredSurface: freezed == appBarBlurredSurface ? _self.appBarBlurredSurface : appBarBlurredSurface // ignore: cast_nullable_to_non_nullable
as BlurredSurfaceConfig?,appBarStyle: freezed == appBarStyle ? _self.appBarStyle : appBarStyle // ignore: cast_nullable_to_non_nullable
as AppBarConfig?,
  ));
}

}


/// Adds pattern-matching-related methods to [FavoritesPageConfig].
extension FavoritesPageConfigPatterns on FavoritesPageConfig {
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
mixin _$VoicemailPageConfig {


/// Create a copy of VoicemailPageConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VoicemailPageConfigCopyWith<VoicemailPageConfig> get copyWith => _$VoicemailPageConfigCopyWithImpl<VoicemailPageConfig>(this as VoicemailPageConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as VoicemailPageConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VoicemailPageConfig&&(identical(other.themeOverride, _this.themeOverride) || other.themeOverride == _this.themeOverride)&&(identical(other.background, _this.background) || other.background == _this.background)&&(identical(other.appBarBlurredSurface, _this.appBarBlurredSurface) || other.appBarBlurredSurface == _this.appBarBlurredSurface)&&(identical(other.appBarStyle, _this.appBarStyle) || other.appBarStyle == _this.appBarStyle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as VoicemailPageConfig;
  return Object.hash(runtimeType,_this.themeOverride,_this.background,_this.appBarBlurredSurface,_this.appBarStyle);
}

@override
String toString() {
  final _this = this as VoicemailPageConfig;
  return 'VoicemailPageConfig(themeOverride: ${_this.themeOverride}, background: ${_this.background}, appBarBlurredSurface: ${_this.appBarBlurredSurface}, appBarStyle: ${_this.appBarStyle})';
}


}

/// @nodoc
abstract mixin class $VoicemailPageConfigCopyWith<$Res>  {
  factory $VoicemailPageConfigCopyWith(VoicemailPageConfig value, $Res Function(VoicemailPageConfig) _then) = _$VoicemailPageConfigCopyWithImpl;
@useResult
$Res call({
 ThemeOverrideConfig themeOverride, PageBackground? background, BlurredSurfaceConfig? appBarBlurredSurface, AppBarConfig? appBarStyle
});




}
/// @nodoc
class _$VoicemailPageConfigCopyWithImpl<$Res>
    implements $VoicemailPageConfigCopyWith<$Res> {
  _$VoicemailPageConfigCopyWithImpl(this._self, this._then);

  final VoicemailPageConfig _self;
  final $Res Function(VoicemailPageConfig) _then;

/// Create a copy of VoicemailPageConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? themeOverride = null,Object? background = freezed,Object? appBarBlurredSurface = freezed,Object? appBarStyle = freezed,}) {
  return _then(VoicemailPageConfig(
themeOverride: null == themeOverride ? _self.themeOverride : themeOverride // ignore: cast_nullable_to_non_nullable
as ThemeOverrideConfig,background: freezed == background ? _self.background : background // ignore: cast_nullable_to_non_nullable
as PageBackground?,appBarBlurredSurface: freezed == appBarBlurredSurface ? _self.appBarBlurredSurface : appBarBlurredSurface // ignore: cast_nullable_to_non_nullable
as BlurredSurfaceConfig?,appBarStyle: freezed == appBarStyle ? _self.appBarStyle : appBarStyle // ignore: cast_nullable_to_non_nullable
as AppBarConfig?,
  ));
}

}


/// Adds pattern-matching-related methods to [VoicemailPageConfig].
extension VoicemailPageConfigPatterns on VoicemailPageConfig {
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
mixin _$CallCenterPageConfig {


/// Create a copy of CallCenterPageConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CallCenterPageConfigCopyWith<CallCenterPageConfig> get copyWith => _$CallCenterPageConfigCopyWithImpl<CallCenterPageConfig>(this as CallCenterPageConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CallCenterPageConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CallCenterPageConfig&&(identical(other.themeOverride, _this.themeOverride) || other.themeOverride == _this.themeOverride)&&(identical(other.background, _this.background) || other.background == _this.background)&&(identical(other.appBarBlurredSurface, _this.appBarBlurredSurface) || other.appBarBlurredSurface == _this.appBarBlurredSurface)&&(identical(other.appBarStyle, _this.appBarStyle) || other.appBarStyle == _this.appBarStyle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CallCenterPageConfig;
  return Object.hash(runtimeType,_this.themeOverride,_this.background,_this.appBarBlurredSurface,_this.appBarStyle);
}

@override
String toString() {
  final _this = this as CallCenterPageConfig;
  return 'CallCenterPageConfig(themeOverride: ${_this.themeOverride}, background: ${_this.background}, appBarBlurredSurface: ${_this.appBarBlurredSurface}, appBarStyle: ${_this.appBarStyle})';
}


}

/// @nodoc
abstract mixin class $CallCenterPageConfigCopyWith<$Res>  {
  factory $CallCenterPageConfigCopyWith(CallCenterPageConfig value, $Res Function(CallCenterPageConfig) _then) = _$CallCenterPageConfigCopyWithImpl;
@useResult
$Res call({
 ThemeOverrideConfig themeOverride, PageBackground? background, BlurredSurfaceConfig? appBarBlurredSurface, AppBarConfig? appBarStyle
});




}
/// @nodoc
class _$CallCenterPageConfigCopyWithImpl<$Res>
    implements $CallCenterPageConfigCopyWith<$Res> {
  _$CallCenterPageConfigCopyWithImpl(this._self, this._then);

  final CallCenterPageConfig _self;
  final $Res Function(CallCenterPageConfig) _then;

/// Create a copy of CallCenterPageConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? themeOverride = null,Object? background = freezed,Object? appBarBlurredSurface = freezed,Object? appBarStyle = freezed,}) {
  return _then(CallCenterPageConfig(
themeOverride: null == themeOverride ? _self.themeOverride : themeOverride // ignore: cast_nullable_to_non_nullable
as ThemeOverrideConfig,background: freezed == background ? _self.background : background // ignore: cast_nullable_to_non_nullable
as PageBackground?,appBarBlurredSurface: freezed == appBarBlurredSurface ? _self.appBarBlurredSurface : appBarBlurredSurface // ignore: cast_nullable_to_non_nullable
as BlurredSurfaceConfig?,appBarStyle: freezed == appBarStyle ? _self.appBarStyle : appBarStyle // ignore: cast_nullable_to_non_nullable
as AppBarConfig?,
  ));
}

}


/// Adds pattern-matching-related methods to [CallCenterPageConfig].
extension CallCenterPageConfigPatterns on CallCenterPageConfig {
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
mixin _$SystemNotificationsPageConfig {


/// Create a copy of SystemNotificationsPageConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SystemNotificationsPageConfigCopyWith<SystemNotificationsPageConfig> get copyWith => _$SystemNotificationsPageConfigCopyWithImpl<SystemNotificationsPageConfig>(this as SystemNotificationsPageConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SystemNotificationsPageConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SystemNotificationsPageConfig&&(identical(other.themeOverride, _this.themeOverride) || other.themeOverride == _this.themeOverride)&&(identical(other.background, _this.background) || other.background == _this.background)&&(identical(other.appBarBlurredSurface, _this.appBarBlurredSurface) || other.appBarBlurredSurface == _this.appBarBlurredSurface)&&(identical(other.appBarStyle, _this.appBarStyle) || other.appBarStyle == _this.appBarStyle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SystemNotificationsPageConfig;
  return Object.hash(runtimeType,_this.themeOverride,_this.background,_this.appBarBlurredSurface,_this.appBarStyle);
}

@override
String toString() {
  final _this = this as SystemNotificationsPageConfig;
  return 'SystemNotificationsPageConfig(themeOverride: ${_this.themeOverride}, background: ${_this.background}, appBarBlurredSurface: ${_this.appBarBlurredSurface}, appBarStyle: ${_this.appBarStyle})';
}


}

/// @nodoc
abstract mixin class $SystemNotificationsPageConfigCopyWith<$Res>  {
  factory $SystemNotificationsPageConfigCopyWith(SystemNotificationsPageConfig value, $Res Function(SystemNotificationsPageConfig) _then) = _$SystemNotificationsPageConfigCopyWithImpl;
@useResult
$Res call({
 ThemeOverrideConfig themeOverride, PageBackground? background, BlurredSurfaceConfig? appBarBlurredSurface, AppBarConfig? appBarStyle
});




}
/// @nodoc
class _$SystemNotificationsPageConfigCopyWithImpl<$Res>
    implements $SystemNotificationsPageConfigCopyWith<$Res> {
  _$SystemNotificationsPageConfigCopyWithImpl(this._self, this._then);

  final SystemNotificationsPageConfig _self;
  final $Res Function(SystemNotificationsPageConfig) _then;

/// Create a copy of SystemNotificationsPageConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? themeOverride = null,Object? background = freezed,Object? appBarBlurredSurface = freezed,Object? appBarStyle = freezed,}) {
  return _then(SystemNotificationsPageConfig(
themeOverride: null == themeOverride ? _self.themeOverride : themeOverride // ignore: cast_nullable_to_non_nullable
as ThemeOverrideConfig,background: freezed == background ? _self.background : background // ignore: cast_nullable_to_non_nullable
as PageBackground?,appBarBlurredSurface: freezed == appBarBlurredSurface ? _self.appBarBlurredSurface : appBarBlurredSurface // ignore: cast_nullable_to_non_nullable
as BlurredSurfaceConfig?,appBarStyle: freezed == appBarStyle ? _self.appBarStyle : appBarStyle // ignore: cast_nullable_to_non_nullable
as AppBarConfig?,
  ));
}

}


/// Adds pattern-matching-related methods to [SystemNotificationsPageConfig].
extension SystemNotificationsPageConfigPatterns on SystemNotificationsPageConfig {
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
mixin _$ConversationsPageConfig {


/// Create a copy of ConversationsPageConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversationsPageConfigCopyWith<ConversationsPageConfig> get copyWith => _$ConversationsPageConfigCopyWithImpl<ConversationsPageConfig>(this as ConversationsPageConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ConversationsPageConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversationsPageConfig&&(identical(other.themeOverride, _this.themeOverride) || other.themeOverride == _this.themeOverride)&&(identical(other.background, _this.background) || other.background == _this.background)&&(identical(other.appBarBlurredSurface, _this.appBarBlurredSurface) || other.appBarBlurredSurface == _this.appBarBlurredSurface)&&(identical(other.appBarStyle, _this.appBarStyle) || other.appBarStyle == _this.appBarStyle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ConversationsPageConfig;
  return Object.hash(runtimeType,_this.themeOverride,_this.background,_this.appBarBlurredSurface,_this.appBarStyle);
}

@override
String toString() {
  final _this = this as ConversationsPageConfig;
  return 'ConversationsPageConfig(themeOverride: ${_this.themeOverride}, background: ${_this.background}, appBarBlurredSurface: ${_this.appBarBlurredSurface}, appBarStyle: ${_this.appBarStyle})';
}


}

/// @nodoc
abstract mixin class $ConversationsPageConfigCopyWith<$Res>  {
  factory $ConversationsPageConfigCopyWith(ConversationsPageConfig value, $Res Function(ConversationsPageConfig) _then) = _$ConversationsPageConfigCopyWithImpl;
@useResult
$Res call({
 ThemeOverrideConfig themeOverride, PageBackground? background, BlurredSurfaceConfig? appBarBlurredSurface, AppBarConfig? appBarStyle
});




}
/// @nodoc
class _$ConversationsPageConfigCopyWithImpl<$Res>
    implements $ConversationsPageConfigCopyWith<$Res> {
  _$ConversationsPageConfigCopyWithImpl(this._self, this._then);

  final ConversationsPageConfig _self;
  final $Res Function(ConversationsPageConfig) _then;

/// Create a copy of ConversationsPageConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? themeOverride = null,Object? background = freezed,Object? appBarBlurredSurface = freezed,Object? appBarStyle = freezed,}) {
  return _then(ConversationsPageConfig(
themeOverride: null == themeOverride ? _self.themeOverride : themeOverride // ignore: cast_nullable_to_non_nullable
as ThemeOverrideConfig,background: freezed == background ? _self.background : background // ignore: cast_nullable_to_non_nullable
as PageBackground?,appBarBlurredSurface: freezed == appBarBlurredSurface ? _self.appBarBlurredSurface : appBarBlurredSurface // ignore: cast_nullable_to_non_nullable
as BlurredSurfaceConfig?,appBarStyle: freezed == appBarStyle ? _self.appBarStyle : appBarStyle // ignore: cast_nullable_to_non_nullable
as AppBarConfig?,
  ));
}

}


/// Adds pattern-matching-related methods to [ConversationsPageConfig].
extension ConversationsPageConfigPatterns on ConversationsPageConfig {
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
mixin _$RecentsPageConfig {


/// Create a copy of RecentsPageConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecentsPageConfigCopyWith<RecentsPageConfig> get copyWith => _$RecentsPageConfigCopyWithImpl<RecentsPageConfig>(this as RecentsPageConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RecentsPageConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecentsPageConfig&&(identical(other.themeOverride, _this.themeOverride) || other.themeOverride == _this.themeOverride)&&(identical(other.background, _this.background) || other.background == _this.background)&&(identical(other.appBarBlurredSurface, _this.appBarBlurredSurface) || other.appBarBlurredSurface == _this.appBarBlurredSurface)&&(identical(other.appBarStyle, _this.appBarStyle) || other.appBarStyle == _this.appBarStyle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RecentsPageConfig;
  return Object.hash(runtimeType,_this.themeOverride,_this.background,_this.appBarBlurredSurface,_this.appBarStyle);
}

@override
String toString() {
  final _this = this as RecentsPageConfig;
  return 'RecentsPageConfig(themeOverride: ${_this.themeOverride}, background: ${_this.background}, appBarBlurredSurface: ${_this.appBarBlurredSurface}, appBarStyle: ${_this.appBarStyle})';
}


}

/// @nodoc
abstract mixin class $RecentsPageConfigCopyWith<$Res>  {
  factory $RecentsPageConfigCopyWith(RecentsPageConfig value, $Res Function(RecentsPageConfig) _then) = _$RecentsPageConfigCopyWithImpl;
@useResult
$Res call({
 ThemeOverrideConfig themeOverride, PageBackground? background, BlurredSurfaceConfig? appBarBlurredSurface, AppBarConfig? appBarStyle
});




}
/// @nodoc
class _$RecentsPageConfigCopyWithImpl<$Res>
    implements $RecentsPageConfigCopyWith<$Res> {
  _$RecentsPageConfigCopyWithImpl(this._self, this._then);

  final RecentsPageConfig _self;
  final $Res Function(RecentsPageConfig) _then;

/// Create a copy of RecentsPageConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? themeOverride = null,Object? background = freezed,Object? appBarBlurredSurface = freezed,Object? appBarStyle = freezed,}) {
  return _then(RecentsPageConfig(
themeOverride: null == themeOverride ? _self.themeOverride : themeOverride // ignore: cast_nullable_to_non_nullable
as ThemeOverrideConfig,background: freezed == background ? _self.background : background // ignore: cast_nullable_to_non_nullable
as PageBackground?,appBarBlurredSurface: freezed == appBarBlurredSurface ? _self.appBarBlurredSurface : appBarBlurredSurface // ignore: cast_nullable_to_non_nullable
as BlurredSurfaceConfig?,appBarStyle: freezed == appBarStyle ? _self.appBarStyle : appBarStyle // ignore: cast_nullable_to_non_nullable
as AppBarConfig?,
  ));
}

}


/// Adds pattern-matching-related methods to [RecentsPageConfig].
extension RecentsPageConfigPatterns on RecentsPageConfig {
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
mixin _$LoginCoreUrlAssignPageConfig {


/// Create a copy of LoginCoreUrlAssignPageConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoginCoreUrlAssignPageConfigCopyWith<LoginCoreUrlAssignPageConfig> get copyWith => _$LoginCoreUrlAssignPageConfigCopyWithImpl<LoginCoreUrlAssignPageConfig>(this as LoginCoreUrlAssignPageConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LoginCoreUrlAssignPageConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoginCoreUrlAssignPageConfig&&(identical(other.themeOverride, _this.themeOverride) || other.themeOverride == _this.themeOverride)&&(identical(other.systemUiOverlayStyle, _this.systemUiOverlayStyle) || other.systemUiOverlayStyle == _this.systemUiOverlayStyle)&&(identical(other.background, _this.background) || other.background == _this.background)&&(identical(other.appBarBlurredSurface, _this.appBarBlurredSurface) || other.appBarBlurredSurface == _this.appBarBlurredSurface)&&(identical(other.appBarStyle, _this.appBarStyle) || other.appBarStyle == _this.appBarStyle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LoginCoreUrlAssignPageConfig;
  return Object.hash(runtimeType,_this.themeOverride,_this.systemUiOverlayStyle,_this.background,_this.appBarBlurredSurface,_this.appBarStyle);
}

@override
String toString() {
  final _this = this as LoginCoreUrlAssignPageConfig;
  return 'LoginCoreUrlAssignPageConfig(themeOverride: ${_this.themeOverride}, systemUiOverlayStyle: ${_this.systemUiOverlayStyle}, background: ${_this.background}, appBarBlurredSurface: ${_this.appBarBlurredSurface}, appBarStyle: ${_this.appBarStyle})';
}


}

/// @nodoc
abstract mixin class $LoginCoreUrlAssignPageConfigCopyWith<$Res>  {
  factory $LoginCoreUrlAssignPageConfigCopyWith(LoginCoreUrlAssignPageConfig value, $Res Function(LoginCoreUrlAssignPageConfig) _then) = _$LoginCoreUrlAssignPageConfigCopyWithImpl;
@useResult
$Res call({
 ThemeOverrideConfig themeOverride, OverlayStyleModel? systemUiOverlayStyle, PageBackground? background, BlurredSurfaceConfig? appBarBlurredSurface, AppBarConfig? appBarStyle
});




}
/// @nodoc
class _$LoginCoreUrlAssignPageConfigCopyWithImpl<$Res>
    implements $LoginCoreUrlAssignPageConfigCopyWith<$Res> {
  _$LoginCoreUrlAssignPageConfigCopyWithImpl(this._self, this._then);

  final LoginCoreUrlAssignPageConfig _self;
  final $Res Function(LoginCoreUrlAssignPageConfig) _then;

/// Create a copy of LoginCoreUrlAssignPageConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? themeOverride = null,Object? systemUiOverlayStyle = freezed,Object? background = freezed,Object? appBarBlurredSurface = freezed,Object? appBarStyle = freezed,}) {
  return _then(LoginCoreUrlAssignPageConfig(
themeOverride: null == themeOverride ? _self.themeOverride : themeOverride // ignore: cast_nullable_to_non_nullable
as ThemeOverrideConfig,systemUiOverlayStyle: freezed == systemUiOverlayStyle ? _self.systemUiOverlayStyle : systemUiOverlayStyle // ignore: cast_nullable_to_non_nullable
as OverlayStyleModel?,background: freezed == background ? _self.background : background // ignore: cast_nullable_to_non_nullable
as PageBackground?,appBarBlurredSurface: freezed == appBarBlurredSurface ? _self.appBarBlurredSurface : appBarBlurredSurface // ignore: cast_nullable_to_non_nullable
as BlurredSurfaceConfig?,appBarStyle: freezed == appBarStyle ? _self.appBarStyle : appBarStyle // ignore: cast_nullable_to_non_nullable
as AppBarConfig?,
  ));
}

}


/// Adds pattern-matching-related methods to [LoginCoreUrlAssignPageConfig].
extension LoginCoreUrlAssignPageConfigPatterns on LoginCoreUrlAssignPageConfig {
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
mixin _$NumberCdrsPageConfig {


/// Create a copy of NumberCdrsPageConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NumberCdrsPageConfigCopyWith<NumberCdrsPageConfig> get copyWith => _$NumberCdrsPageConfigCopyWithImpl<NumberCdrsPageConfig>(this as NumberCdrsPageConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as NumberCdrsPageConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NumberCdrsPageConfig&&(identical(other.background, _this.background) || other.background == _this.background)&&(identical(other.appBarBlurredSurface, _this.appBarBlurredSurface) || other.appBarBlurredSurface == _this.appBarBlurredSurface)&&(identical(other.appBarStyle, _this.appBarStyle) || other.appBarStyle == _this.appBarStyle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as NumberCdrsPageConfig;
  return Object.hash(runtimeType,_this.background,_this.appBarBlurredSurface,_this.appBarStyle);
}

@override
String toString() {
  final _this = this as NumberCdrsPageConfig;
  return 'NumberCdrsPageConfig(background: ${_this.background}, appBarBlurredSurface: ${_this.appBarBlurredSurface}, appBarStyle: ${_this.appBarStyle})';
}


}

/// @nodoc
abstract mixin class $NumberCdrsPageConfigCopyWith<$Res>  {
  factory $NumberCdrsPageConfigCopyWith(NumberCdrsPageConfig value, $Res Function(NumberCdrsPageConfig) _then) = _$NumberCdrsPageConfigCopyWithImpl;
@useResult
$Res call({
 PageBackground? background, BlurredSurfaceConfig? appBarBlurredSurface, AppBarConfig? appBarStyle
});




}
/// @nodoc
class _$NumberCdrsPageConfigCopyWithImpl<$Res>
    implements $NumberCdrsPageConfigCopyWith<$Res> {
  _$NumberCdrsPageConfigCopyWithImpl(this._self, this._then);

  final NumberCdrsPageConfig _self;
  final $Res Function(NumberCdrsPageConfig) _then;

/// Create a copy of NumberCdrsPageConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? background = freezed,Object? appBarBlurredSurface = freezed,Object? appBarStyle = freezed,}) {
  return _then(NumberCdrsPageConfig(
background: freezed == background ? _self.background : background // ignore: cast_nullable_to_non_nullable
as PageBackground?,appBarBlurredSurface: freezed == appBarBlurredSurface ? _self.appBarBlurredSurface : appBarBlurredSurface // ignore: cast_nullable_to_non_nullable
as BlurredSurfaceConfig?,appBarStyle: freezed == appBarStyle ? _self.appBarStyle : appBarStyle // ignore: cast_nullable_to_non_nullable
as AppBarConfig?,
  ));
}

}


/// Adds pattern-matching-related methods to [NumberCdrsPageConfig].
extension NumberCdrsPageConfigPatterns on NumberCdrsPageConfig {
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
