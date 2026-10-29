// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'login_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LoginState {


/// Create a copy of LoginState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoginStateCopyWith<LoginState> get copyWith => _$LoginStateCopyWithImpl<LoginState>(this as LoginState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LoginState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoginState&&(identical(other.processing, _this.processing) || other.processing == _this.processing)&&(identical(other.mode, _this.mode) || other.mode == _this.mode)&&(identical(other.coreUrl, _this.coreUrl) || other.coreUrl == _this.coreUrl)&&(identical(other.tenantId, _this.tenantId) || other.tenantId == _this.tenantId)&&(identical(other.systemInfo, _this.systemInfo) || other.systemInfo == _this.systemInfo)&&const DeepCollectionEquality().equals(other.supportedLoginTypes, _this.supportedLoginTypes)&&(identical(other.otpSigninSessionOtpProvisionalWithDateTime, _this.otpSigninSessionOtpProvisionalWithDateTime) || other.otpSigninSessionOtpProvisionalWithDateTime == _this.otpSigninSessionOtpProvisionalWithDateTime)&&(identical(other.passwordSigninPasswordInputObscureText, _this.passwordSigninPasswordInputObscureText) || other.passwordSigninPasswordInputObscureText == _this.passwordSigninPasswordInputObscureText)&&(identical(other.signupSessionOtpProvisionalWithDateTime, _this.signupSessionOtpProvisionalWithDateTime) || other.signupSessionOtpProvisionalWithDateTime == _this.signupSessionOtpProvisionalWithDateTime)&&(identical(other.token, _this.token) || other.token == _this.token)&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.embedded, _this.embedded) || other.embedded == _this.embedded)&&const DeepCollectionEquality().equals(other.embeddedExtras, _this.embeddedExtras)&&const DeepCollectionEquality().equals(other.embeddedCallbackData, _this.embeddedCallbackData)&&const DeepCollectionEquality().equals(other.embeddedRequestError, _this.embeddedRequestError)&&(identical(other.embeddedSignupFailure, _this.embeddedSignupFailure) || other.embeddedSignupFailure == _this.embeddedSignupFailure)&&(identical(other.coreUrlInput, _this.coreUrlInput) || other.coreUrlInput == _this.coreUrlInput)&&const DeepCollectionEquality().equals(other.coreUrlAssignError, _this.coreUrlAssignError)&&(identical(other.otpSigninUserRefInput, _this.otpSigninUserRefInput) || other.otpSigninUserRefInput == _this.otpSigninUserRefInput)&&(identical(other.otpSigninCodeInput, _this.otpSigninCodeInput) || other.otpSigninCodeInput == _this.otpSigninCodeInput)&&(identical(other.passwordSigninUserRefInput, _this.passwordSigninUserRefInput) || other.passwordSigninUserRefInput == _this.passwordSigninUserRefInput)&&(identical(other.passwordSigninPasswordInput, _this.passwordSigninPasswordInput) || other.passwordSigninPasswordInput == _this.passwordSigninPasswordInput)&&(identical(other.signupEmailInput, _this.signupEmailInput) || other.signupEmailInput == _this.signupEmailInput)&&(identical(other.signupCodeInput, _this.signupCodeInput) || other.signupCodeInput == _this.signupCodeInput)&&(identical(other.pendingLogin, _this.pendingLogin) || other.pendingLogin == _this.pendingLogin)&&(identical(other.pendingLoginRevokingSessionId, _this.pendingLoginRevokingSessionId) || other.pendingLoginRevokingSessionId == _this.pendingLoginRevokingSessionId)&&const DeepCollectionEquality().equals(other.pendingLoginCallbackData, _this.pendingLoginCallbackData));
}


@override
int get hashCode {
  final _this = this as LoginState;
  return Object.hashAll([runtimeType,_this.processing,_this.mode,_this.coreUrl,_this.tenantId,_this.systemInfo,const DeepCollectionEquality().hash(_this.supportedLoginTypes),_this.otpSigninSessionOtpProvisionalWithDateTime,_this.passwordSigninPasswordInputObscureText,_this.signupSessionOtpProvisionalWithDateTime,_this.token,_this.userId,_this.embedded,const DeepCollectionEquality().hash(_this.embeddedExtras),const DeepCollectionEquality().hash(_this.embeddedCallbackData),const DeepCollectionEquality().hash(_this.embeddedRequestError),_this.embeddedSignupFailure,_this.coreUrlInput,const DeepCollectionEquality().hash(_this.coreUrlAssignError),_this.otpSigninUserRefInput,_this.otpSigninCodeInput,_this.passwordSigninUserRefInput,_this.passwordSigninPasswordInput,_this.signupEmailInput,_this.signupCodeInput,_this.pendingLogin,_this.pendingLoginRevokingSessionId,const DeepCollectionEquality().hash(_this.pendingLoginCallbackData)]);
}

@override
String toString() {
  final _this = this as LoginState;
  return 'LoginState(processing: ${_this.processing}, mode: ${_this.mode}, coreUrl: ${_this.coreUrl}, tenantId: ${_this.tenantId}, systemInfo: ${_this.systemInfo}, supportedLoginTypes: ${_this.supportedLoginTypes}, otpSigninSessionOtpProvisionalWithDateTime: ${_this.otpSigninSessionOtpProvisionalWithDateTime}, passwordSigninPasswordInputObscureText: ${_this.passwordSigninPasswordInputObscureText}, signupSessionOtpProvisionalWithDateTime: ${_this.signupSessionOtpProvisionalWithDateTime}, token: ${_this.token}, userId: ${_this.userId}, embedded: ${_this.embedded}, embeddedExtras: ${_this.embeddedExtras}, embeddedCallbackData: ${_this.embeddedCallbackData}, embeddedRequestError: ${_this.embeddedRequestError}, embeddedSignupFailure: ${_this.embeddedSignupFailure}, coreUrlInput: ${_this.coreUrlInput}, coreUrlAssignError: ${_this.coreUrlAssignError}, otpSigninUserRefInput: ${_this.otpSigninUserRefInput}, otpSigninCodeInput: ${_this.otpSigninCodeInput}, passwordSigninUserRefInput: ${_this.passwordSigninUserRefInput}, passwordSigninPasswordInput: ${_this.passwordSigninPasswordInput}, signupEmailInput: ${_this.signupEmailInput}, signupCodeInput: ${_this.signupCodeInput}, pendingLogin: ${_this.pendingLogin}, pendingLoginRevokingSessionId: ${_this.pendingLoginRevokingSessionId}, pendingLoginCallbackData: ${_this.pendingLoginCallbackData})';
}


}

/// @nodoc
abstract mixin class $LoginStateCopyWith<$Res>  {
  factory $LoginStateCopyWith(LoginState value, $Res Function(LoginState) _then) = _$LoginStateCopyWithImpl;
@useResult
$Res call({
 bool processing, LoginMode? mode, String? coreUrl, String? tenantId, WebtritSystemInfo? systemInfo, List<LoginType>? supportedLoginTypes, SessionOtpProvisionalWithDateTime? otpSigninSessionOtpProvisionalWithDateTime, bool passwordSigninPasswordInputObscureText, SessionOtpProvisionalWithDateTime? signupSessionOtpProvisionalWithDateTime, String? token, String? userId, EmbeddedData? embedded, Map<String, dynamic>? embeddedExtras, Map<String, dynamic>? embeddedCallbackData, Object? embeddedRequestError, EmbeddedSignupFailure? embeddedSignupFailure, UrlInput coreUrlInput, Object? coreUrlAssignError, UserRefInput otpSigninUserRefInput, CodeInput otpSigninCodeInput, UserRefInput passwordSigninUserRefInput, PasswordInput passwordSigninPasswordInput, EmailInput signupEmailInput, CodeInput signupCodeInput, PendingLogin? pendingLogin, String? pendingLoginRevokingSessionId, Map<String, dynamic>? pendingLoginCallbackData
});




}
/// @nodoc
class _$LoginStateCopyWithImpl<$Res>
    implements $LoginStateCopyWith<$Res> {
  _$LoginStateCopyWithImpl(this._self, this._then);

  final LoginState _self;
  final $Res Function(LoginState) _then;

/// Create a copy of LoginState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? processing = null,Object? mode = freezed,Object? coreUrl = freezed,Object? tenantId = freezed,Object? systemInfo = freezed,Object? supportedLoginTypes = freezed,Object? otpSigninSessionOtpProvisionalWithDateTime = freezed,Object? passwordSigninPasswordInputObscureText = null,Object? signupSessionOtpProvisionalWithDateTime = freezed,Object? token = freezed,Object? userId = freezed,Object? embedded = freezed,Object? embeddedExtras = freezed,Object? embeddedCallbackData = freezed,Object? embeddedRequestError = freezed,Object? embeddedSignupFailure = freezed,Object? coreUrlInput = null,Object? coreUrlAssignError = freezed,Object? otpSigninUserRefInput = null,Object? otpSigninCodeInput = null,Object? passwordSigninUserRefInput = null,Object? passwordSigninPasswordInput = null,Object? signupEmailInput = null,Object? signupCodeInput = null,Object? pendingLogin = freezed,Object? pendingLoginRevokingSessionId = freezed,Object? pendingLoginCallbackData = freezed,}) {
  return _then(LoginState(
processing: null == processing ? _self.processing : processing // ignore: cast_nullable_to_non_nullable
as bool,mode: freezed == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as LoginMode?,coreUrl: freezed == coreUrl ? _self.coreUrl : coreUrl // ignore: cast_nullable_to_non_nullable
as String?,tenantId: freezed == tenantId ? _self.tenantId : tenantId // ignore: cast_nullable_to_non_nullable
as String?,systemInfo: freezed == systemInfo ? _self.systemInfo : systemInfo // ignore: cast_nullable_to_non_nullable
as WebtritSystemInfo?,supportedLoginTypes: freezed == supportedLoginTypes ? _self.supportedLoginTypes : supportedLoginTypes // ignore: cast_nullable_to_non_nullable
as List<LoginType>?,otpSigninSessionOtpProvisionalWithDateTime: freezed == otpSigninSessionOtpProvisionalWithDateTime ? _self.otpSigninSessionOtpProvisionalWithDateTime : otpSigninSessionOtpProvisionalWithDateTime // ignore: cast_nullable_to_non_nullable
as SessionOtpProvisionalWithDateTime?,passwordSigninPasswordInputObscureText: null == passwordSigninPasswordInputObscureText ? _self.passwordSigninPasswordInputObscureText : passwordSigninPasswordInputObscureText // ignore: cast_nullable_to_non_nullable
as bool,signupSessionOtpProvisionalWithDateTime: freezed == signupSessionOtpProvisionalWithDateTime ? _self.signupSessionOtpProvisionalWithDateTime : signupSessionOtpProvisionalWithDateTime // ignore: cast_nullable_to_non_nullable
as SessionOtpProvisionalWithDateTime?,token: freezed == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String?,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,embedded: freezed == embedded ? _self.embedded : embedded // ignore: cast_nullable_to_non_nullable
as EmbeddedData?,embeddedExtras: freezed == embeddedExtras ? _self.embeddedExtras : embeddedExtras // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,embeddedCallbackData: freezed == embeddedCallbackData ? _self.embeddedCallbackData : embeddedCallbackData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,embeddedRequestError: freezed == embeddedRequestError ? _self.embeddedRequestError : embeddedRequestError ,embeddedSignupFailure: freezed == embeddedSignupFailure ? _self.embeddedSignupFailure : embeddedSignupFailure // ignore: cast_nullable_to_non_nullable
as EmbeddedSignupFailure?,coreUrlInput: null == coreUrlInput ? _self.coreUrlInput : coreUrlInput // ignore: cast_nullable_to_non_nullable
as UrlInput,coreUrlAssignError: freezed == coreUrlAssignError ? _self.coreUrlAssignError : coreUrlAssignError ,otpSigninUserRefInput: null == otpSigninUserRefInput ? _self.otpSigninUserRefInput : otpSigninUserRefInput // ignore: cast_nullable_to_non_nullable
as UserRefInput,otpSigninCodeInput: null == otpSigninCodeInput ? _self.otpSigninCodeInput : otpSigninCodeInput // ignore: cast_nullable_to_non_nullable
as CodeInput,passwordSigninUserRefInput: null == passwordSigninUserRefInput ? _self.passwordSigninUserRefInput : passwordSigninUserRefInput // ignore: cast_nullable_to_non_nullable
as UserRefInput,passwordSigninPasswordInput: null == passwordSigninPasswordInput ? _self.passwordSigninPasswordInput : passwordSigninPasswordInput // ignore: cast_nullable_to_non_nullable
as PasswordInput,signupEmailInput: null == signupEmailInput ? _self.signupEmailInput : signupEmailInput // ignore: cast_nullable_to_non_nullable
as EmailInput,signupCodeInput: null == signupCodeInput ? _self.signupCodeInput : signupCodeInput // ignore: cast_nullable_to_non_nullable
as CodeInput,pendingLogin: freezed == pendingLogin ? _self.pendingLogin : pendingLogin // ignore: cast_nullable_to_non_nullable
as PendingLogin?,pendingLoginRevokingSessionId: freezed == pendingLoginRevokingSessionId ? _self.pendingLoginRevokingSessionId : pendingLoginRevokingSessionId // ignore: cast_nullable_to_non_nullable
as String?,pendingLoginCallbackData: freezed == pendingLoginCallbackData ? _self.pendingLoginCallbackData : pendingLoginCallbackData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [LoginState].
extension LoginStatePatterns on LoginState {
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
