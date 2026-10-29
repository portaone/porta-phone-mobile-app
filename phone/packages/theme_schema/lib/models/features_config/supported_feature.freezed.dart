// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'supported_feature.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SupportedThemeMode {


/// Create a copy of SupportedThemeMode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SupportedThemeModeCopyWith<SupportedThemeMode> get copyWith => _$SupportedThemeModeCopyWithImpl<SupportedThemeMode>(this as SupportedThemeMode, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SupportedThemeMode;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SupportedThemeMode&&(identical(other.mode, _this.mode) || other.mode == _this.mode)&&(identical(other.type, _this.type) || other.type == _this.type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SupportedThemeMode;
  return Object.hash(runtimeType,_this.mode,_this.type);
}

@override
String toString() {
  final _this = this as SupportedThemeMode;
  return 'SupportedThemeMode(mode: ${_this.mode}, type: ${_this.type})';
}


}

/// @nodoc
abstract mixin class $SupportedThemeModeCopyWith<$Res>  {
  factory $SupportedThemeModeCopyWith(SupportedThemeMode value, $Res Function(SupportedThemeMode) _then) = _$SupportedThemeModeCopyWithImpl;
@useResult
$Res call({
 ThemeModeConfig mode, String type
});




}
/// @nodoc
class _$SupportedThemeModeCopyWithImpl<$Res>
    implements $SupportedThemeModeCopyWith<$Res> {
  _$SupportedThemeModeCopyWithImpl(this._self, this._then);

  final SupportedThemeMode _self;
  final $Res Function(SupportedThemeMode) _then;

/// Create a copy of SupportedThemeMode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mode = null,Object? type = null,}) {
  return _then(SupportedThemeMode(
mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as ThemeModeConfig,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SupportedThemeMode].
extension SupportedThemeModePatterns on SupportedThemeMode {
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
mixin _$SupportedVideoCall {


/// Create a copy of SupportedVideoCall
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SupportedVideoCallCopyWith<SupportedVideoCall> get copyWith => _$SupportedVideoCallCopyWithImpl<SupportedVideoCall>(this as SupportedVideoCall, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SupportedVideoCall;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SupportedVideoCall&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled)&&(identical(other.type, _this.type) || other.type == _this.type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SupportedVideoCall;
  return Object.hash(runtimeType,_this.enabled,_this.type);
}

@override
String toString() {
  final _this = this as SupportedVideoCall;
  return 'SupportedVideoCall(enabled: ${_this.enabled}, type: ${_this.type})';
}


}

/// @nodoc
abstract mixin class $SupportedVideoCallCopyWith<$Res>  {
  factory $SupportedVideoCallCopyWith(SupportedVideoCall value, $Res Function(SupportedVideoCall) _then) = _$SupportedVideoCallCopyWithImpl;
@useResult
$Res call({
 bool enabled, String type
});




}
/// @nodoc
class _$SupportedVideoCallCopyWithImpl<$Res>
    implements $SupportedVideoCallCopyWith<$Res> {
  _$SupportedVideoCallCopyWithImpl(this._self, this._then);

  final SupportedVideoCall _self;
  final $Res Function(SupportedVideoCall) _then;

/// Create a copy of SupportedVideoCall
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,Object? type = null,}) {
  return _then(SupportedVideoCall(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SupportedVideoCall].
extension SupportedVideoCallPatterns on SupportedVideoCall {
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
mixin _$SupportedLoggingConfig {


/// Create a copy of SupportedLoggingConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SupportedLoggingConfigCopyWith<SupportedLoggingConfig> get copyWith => _$SupportedLoggingConfigCopyWithImpl<SupportedLoggingConfig>(this as SupportedLoggingConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SupportedLoggingConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SupportedLoggingConfig&&(identical(other.logLevel, _this.logLevel) || other.logLevel == _this.logLevel)&&(identical(other.checkIntervalSec, _this.checkIntervalSec) || other.checkIntervalSec == _this.checkIntervalSec)&&(identical(other.anonymizationEnabled, _this.anonymizationEnabled) || other.anonymizationEnabled == _this.anonymizationEnabled)&&(identical(other.type, _this.type) || other.type == _this.type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SupportedLoggingConfig;
  return Object.hash(runtimeType,_this.logLevel,_this.checkIntervalSec,_this.anonymizationEnabled,_this.type);
}

@override
String toString() {
  final _this = this as SupportedLoggingConfig;
  return 'SupportedLoggingConfig(logLevel: ${_this.logLevel}, checkIntervalSec: ${_this.checkIntervalSec}, anonymizationEnabled: ${_this.anonymizationEnabled}, type: ${_this.type})';
}


}

/// @nodoc
abstract mixin class $SupportedLoggingConfigCopyWith<$Res>  {
  factory $SupportedLoggingConfigCopyWith(SupportedLoggingConfig value, $Res Function(SupportedLoggingConfig) _then) = _$SupportedLoggingConfigCopyWithImpl;
@useResult
$Res call({
 String logLevel, int checkIntervalSec, bool anonymizationEnabled, String type
});




}
/// @nodoc
class _$SupportedLoggingConfigCopyWithImpl<$Res>
    implements $SupportedLoggingConfigCopyWith<$Res> {
  _$SupportedLoggingConfigCopyWithImpl(this._self, this._then);

  final SupportedLoggingConfig _self;
  final $Res Function(SupportedLoggingConfig) _then;

/// Create a copy of SupportedLoggingConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? logLevel = null,Object? checkIntervalSec = null,Object? anonymizationEnabled = null,Object? type = null,}) {
  return _then(SupportedLoggingConfig(
logLevel: null == logLevel ? _self.logLevel : logLevel // ignore: cast_nullable_to_non_nullable
as String,checkIntervalSec: null == checkIntervalSec ? _self.checkIntervalSec : checkIntervalSec // ignore: cast_nullable_to_non_nullable
as int,anonymizationEnabled: null == anonymizationEnabled ? _self.anonymizationEnabled : anonymizationEnabled // ignore: cast_nullable_to_non_nullable
as bool,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SupportedLoggingConfig].
extension SupportedLoggingConfigPatterns on SupportedLoggingConfig {
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
mixin _$SupportedSystemNotifications {


/// Create a copy of SupportedSystemNotifications
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SupportedSystemNotificationsCopyWith<SupportedSystemNotifications> get copyWith => _$SupportedSystemNotificationsCopyWithImpl<SupportedSystemNotifications>(this as SupportedSystemNotifications, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SupportedSystemNotifications;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SupportedSystemNotifications&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled)&&(identical(other.type, _this.type) || other.type == _this.type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SupportedSystemNotifications;
  return Object.hash(runtimeType,_this.enabled,_this.type);
}

@override
String toString() {
  final _this = this as SupportedSystemNotifications;
  return 'SupportedSystemNotifications(enabled: ${_this.enabled}, type: ${_this.type})';
}


}

/// @nodoc
abstract mixin class $SupportedSystemNotificationsCopyWith<$Res>  {
  factory $SupportedSystemNotificationsCopyWith(SupportedSystemNotifications value, $Res Function(SupportedSystemNotifications) _then) = _$SupportedSystemNotificationsCopyWithImpl;
@useResult
$Res call({
 bool enabled, String type
});




}
/// @nodoc
class _$SupportedSystemNotificationsCopyWithImpl<$Res>
    implements $SupportedSystemNotificationsCopyWith<$Res> {
  _$SupportedSystemNotificationsCopyWithImpl(this._self, this._then);

  final SupportedSystemNotifications _self;
  final $Res Function(SupportedSystemNotifications) _then;

/// Create a copy of SupportedSystemNotifications
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,Object? type = null,}) {
  return _then(SupportedSystemNotifications(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SupportedSystemNotifications].
extension SupportedSystemNotificationsPatterns on SupportedSystemNotifications {
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
mixin _$SupportedHybridPresence {


/// Create a copy of SupportedHybridPresence
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SupportedHybridPresenceCopyWith<SupportedHybridPresence> get copyWith => _$SupportedHybridPresenceCopyWithImpl<SupportedHybridPresence>(this as SupportedHybridPresence, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SupportedHybridPresence;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SupportedHybridPresence&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled)&&(identical(other.type, _this.type) || other.type == _this.type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SupportedHybridPresence;
  return Object.hash(runtimeType,_this.enabled,_this.type);
}

@override
String toString() {
  final _this = this as SupportedHybridPresence;
  return 'SupportedHybridPresence(enabled: ${_this.enabled}, type: ${_this.type})';
}


}

/// @nodoc
abstract mixin class $SupportedHybridPresenceCopyWith<$Res>  {
  factory $SupportedHybridPresenceCopyWith(SupportedHybridPresence value, $Res Function(SupportedHybridPresence) _then) = _$SupportedHybridPresenceCopyWithImpl;
@useResult
$Res call({
 bool enabled, String type
});




}
/// @nodoc
class _$SupportedHybridPresenceCopyWithImpl<$Res>
    implements $SupportedHybridPresenceCopyWith<$Res> {
  _$SupportedHybridPresenceCopyWithImpl(this._self, this._then);

  final SupportedHybridPresence _self;
  final $Res Function(SupportedHybridPresence) _then;

/// Create a copy of SupportedHybridPresence
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,Object? type = null,}) {
  return _then(SupportedHybridPresence(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SupportedHybridPresence].
extension SupportedHybridPresencePatterns on SupportedHybridPresence {
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
mixin _$SupportedCallPull {


/// Create a copy of SupportedCallPull
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SupportedCallPullCopyWith<SupportedCallPull> get copyWith => _$SupportedCallPullCopyWithImpl<SupportedCallPull>(this as SupportedCallPull, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SupportedCallPull;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SupportedCallPull&&(identical(other.videoStrategy, _this.videoStrategy) || other.videoStrategy == _this.videoStrategy)&&(identical(other.type, _this.type) || other.type == _this.type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SupportedCallPull;
  return Object.hash(runtimeType,_this.videoStrategy,_this.type);
}

@override
String toString() {
  final _this = this as SupportedCallPull;
  return 'SupportedCallPull(videoStrategy: ${_this.videoStrategy}, type: ${_this.type})';
}


}

/// @nodoc
abstract mixin class $SupportedCallPullCopyWith<$Res>  {
  factory $SupportedCallPullCopyWith(SupportedCallPull value, $Res Function(SupportedCallPull) _then) = _$SupportedCallPullCopyWithImpl;
@useResult
$Res call({
 String videoStrategy, String type
});




}
/// @nodoc
class _$SupportedCallPullCopyWithImpl<$Res>
    implements $SupportedCallPullCopyWith<$Res> {
  _$SupportedCallPullCopyWithImpl(this._self, this._then);

  final SupportedCallPull _self;
  final $Res Function(SupportedCallPull) _then;

/// Create a copy of SupportedCallPull
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? videoStrategy = null,Object? type = null,}) {
  return _then(SupportedCallPull(
videoStrategy: null == videoStrategy ? _self.videoStrategy : videoStrategy // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SupportedCallPull].
extension SupportedCallPullPatterns on SupportedCallPull {
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
