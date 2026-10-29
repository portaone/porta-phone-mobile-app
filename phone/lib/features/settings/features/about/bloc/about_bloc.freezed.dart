// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'about_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AboutState {


/// Create a copy of AboutState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AboutStateCopyWith<AboutState> get copyWith => _$AboutStateCopyWithImpl<AboutState>(this as AboutState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AboutState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AboutState&&(identical(other.progress, _this.progress) || other.progress == _this.progress)&&const DeepCollectionEquality().equals(other.embeddedResources, _this.embeddedResources)&&(identical(other.packageName, _this.packageName) || other.packageName == _this.packageName)&&(identical(other.appIdentifier, _this.appIdentifier) || other.appIdentifier == _this.appIdentifier)&&(identical(other.coreUrl, _this.coreUrl) || other.coreUrl == _this.coreUrl)&&(identical(other.userAgent, _this.userAgent) || other.userAgent == _this.userAgent)&&(identical(other.appInfo, _this.appInfo) || other.appInfo == _this.appInfo)&&(identical(other.deviceInfo, _this.deviceInfo) || other.deviceInfo == _this.deviceInfo)&&(identical(other.fcmPushToken, _this.fcmPushToken) || other.fcmPushToken == _this.fcmPushToken)&&(identical(other.coreVersion, _this.coreVersion) || other.coreVersion == _this.coreVersion)&&(identical(other.bundleVersion, _this.bundleVersion) || other.bundleVersion == _this.bundleVersion));
}


@override
int get hashCode {
  final _this = this as AboutState;
  return Object.hash(runtimeType,_this.progress,const DeepCollectionEquality().hash(_this.embeddedResources),_this.packageName,_this.appIdentifier,_this.coreUrl,_this.userAgent,_this.appInfo,_this.deviceInfo,_this.fcmPushToken,_this.coreVersion,_this.bundleVersion);
}

@override
String toString() {
  final _this = this as AboutState;
  return 'AboutState(progress: ${_this.progress}, embeddedResources: ${_this.embeddedResources}, packageName: ${_this.packageName}, appIdentifier: ${_this.appIdentifier}, coreUrl: ${_this.coreUrl}, userAgent: ${_this.userAgent}, appInfo: ${_this.appInfo}, deviceInfo: ${_this.deviceInfo}, fcmPushToken: ${_this.fcmPushToken}, coreVersion: ${_this.coreVersion}, bundleVersion: ${_this.bundleVersion})';
}


}

/// @nodoc
abstract mixin class $AboutStateCopyWith<$Res>  {
  factory $AboutStateCopyWith(AboutState value, $Res Function(AboutState) _then) = _$AboutStateCopyWithImpl;
@useResult
$Res call({
 bool progress, List<EmbeddedData> embeddedResources, String packageName, String appIdentifier, Uri coreUrl, String userAgent, String appInfo, String deviceInfo, String? fcmPushToken, Version? coreVersion, String? bundleVersion
});




}
/// @nodoc
class _$AboutStateCopyWithImpl<$Res>
    implements $AboutStateCopyWith<$Res> {
  _$AboutStateCopyWithImpl(this._self, this._then);

  final AboutState _self;
  final $Res Function(AboutState) _then;

/// Create a copy of AboutState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? progress = null,Object? embeddedResources = null,Object? packageName = null,Object? appIdentifier = null,Object? coreUrl = null,Object? userAgent = null,Object? appInfo = null,Object? deviceInfo = null,Object? fcmPushToken = freezed,Object? coreVersion = freezed,Object? bundleVersion = freezed,}) {
  return _then(AboutState(
progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as bool,embeddedResources: null == embeddedResources ? _self.embeddedResources : embeddedResources // ignore: cast_nullable_to_non_nullable
as List<EmbeddedData>,packageName: null == packageName ? _self.packageName : packageName // ignore: cast_nullable_to_non_nullable
as String,appIdentifier: null == appIdentifier ? _self.appIdentifier : appIdentifier // ignore: cast_nullable_to_non_nullable
as String,coreUrl: null == coreUrl ? _self.coreUrl : coreUrl // ignore: cast_nullable_to_non_nullable
as Uri,userAgent: null == userAgent ? _self.userAgent : userAgent // ignore: cast_nullable_to_non_nullable
as String,appInfo: null == appInfo ? _self.appInfo : appInfo // ignore: cast_nullable_to_non_nullable
as String,deviceInfo: null == deviceInfo ? _self.deviceInfo : deviceInfo // ignore: cast_nullable_to_non_nullable
as String,fcmPushToken: freezed == fcmPushToken ? _self.fcmPushToken : fcmPushToken // ignore: cast_nullable_to_non_nullable
as String?,coreVersion: freezed == coreVersion ? _self.coreVersion : coreVersion // ignore: cast_nullable_to_non_nullable
as Version?,bundleVersion: freezed == bundleVersion ? _self.bundleVersion : bundleVersion // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AboutState].
extension AboutStatePatterns on AboutState {
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
