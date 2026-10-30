// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'system_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SystemInfo {


/// Create a copy of SystemInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SystemInfoCopyWith<SystemInfo> get copyWith => _$SystemInfoCopyWithImpl<SystemInfo>(this as SystemInfo, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SystemInfo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SystemInfo&&(identical(other.core, _this.core) || other.core == _this.core)&&(identical(other.postgres, _this.postgres) || other.postgres == _this.postgres)&&(identical(other.adapter, _this.adapter) || other.adapter == _this.adapter)&&(identical(other.janus, _this.janus) || other.janus == _this.janus)&&(identical(other.gorush, _this.gorush) || other.gorush == _this.gorush)&&(identical(other.minSupportedAppVersion, _this.minSupportedAppVersion) || other.minSupportedAppVersion == _this.minSupportedAppVersion)&&(identical(other.bundleVersion, _this.bundleVersion) || other.bundleVersion == _this.bundleVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SystemInfo;
  return Object.hash(runtimeType,_this.core,_this.postgres,_this.adapter,_this.janus,_this.gorush,_this.minSupportedAppVersion,_this.bundleVersion);
}

@override
String toString() {
  final _this = this as SystemInfo;
  return 'SystemInfo(core: ${_this.core}, postgres: ${_this.postgres}, adapter: ${_this.adapter}, janus: ${_this.janus}, gorush: ${_this.gorush}, minSupportedAppVersion: ${_this.minSupportedAppVersion}, bundleVersion: ${_this.bundleVersion})';
}


}

/// @nodoc
abstract mixin class $SystemInfoCopyWith<$Res>  {
  factory $SystemInfoCopyWith(SystemInfo value, $Res Function(SystemInfo) _then) = _$SystemInfoCopyWithImpl;
@useResult
$Res call({
 CoreInfo core, PostgresInfo postgres, AdapterInfo? adapter, JanusInfo? janus, GorushInfo? gorush, String? minSupportedAppVersion, String? bundleVersion
});




}
/// @nodoc
class _$SystemInfoCopyWithImpl<$Res>
    implements $SystemInfoCopyWith<$Res> {
  _$SystemInfoCopyWithImpl(this._self, this._then);

  final SystemInfo _self;
  final $Res Function(SystemInfo) _then;

/// Create a copy of SystemInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? core = null,Object? postgres = null,Object? adapter = freezed,Object? janus = freezed,Object? gorush = freezed,Object? minSupportedAppVersion = freezed,Object? bundleVersion = freezed,}) {
  return _then(SystemInfo(
core: null == core ? _self.core : core // ignore: cast_nullable_to_non_nullable
as CoreInfo,postgres: null == postgres ? _self.postgres : postgres // ignore: cast_nullable_to_non_nullable
as PostgresInfo,adapter: freezed == adapter ? _self.adapter : adapter // ignore: cast_nullable_to_non_nullable
as AdapterInfo?,janus: freezed == janus ? _self.janus : janus // ignore: cast_nullable_to_non_nullable
as JanusInfo?,gorush: freezed == gorush ? _self.gorush : gorush // ignore: cast_nullable_to_non_nullable
as GorushInfo?,minSupportedAppVersion: freezed == minSupportedAppVersion ? _self.minSupportedAppVersion : minSupportedAppVersion // ignore: cast_nullable_to_non_nullable
as String?,bundleVersion: freezed == bundleVersion ? _self.bundleVersion : bundleVersion // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SystemInfo].
extension SystemInfoPatterns on SystemInfo {
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
mixin _$CoreInfo {


/// Create a copy of CoreInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoreInfoCopyWith<CoreInfo> get copyWith => _$CoreInfoCopyWithImpl<CoreInfo>(this as CoreInfo, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CoreInfo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CoreInfo&&(identical(other.version, _this.version) || other.version == _this.version)&&(identical(other.iceServersConfigured, _this.iceServersConfigured) || other.iceServersConfigured == _this.iceServersConfigured)&&(identical(other.notificationDeletedRetentionDays, _this.notificationDeletedRetentionDays) || other.notificationDeletedRetentionDays == _this.notificationDeletedRetentionDays));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CoreInfo;
  return Object.hash(runtimeType,_this.version,_this.iceServersConfigured,_this.notificationDeletedRetentionDays);
}

@override
String toString() {
  final _this = this as CoreInfo;
  return 'CoreInfo(version: ${_this.version}, iceServersConfigured: ${_this.iceServersConfigured}, notificationDeletedRetentionDays: ${_this.notificationDeletedRetentionDays})';
}


}

/// @nodoc
abstract mixin class $CoreInfoCopyWith<$Res>  {
  factory $CoreInfoCopyWith(CoreInfo value, $Res Function(CoreInfo) _then) = _$CoreInfoCopyWithImpl;
@useResult
$Res call({
@VersionConverter() Version version, bool? iceServersConfigured, int? notificationDeletedRetentionDays
});




}
/// @nodoc
class _$CoreInfoCopyWithImpl<$Res>
    implements $CoreInfoCopyWith<$Res> {
  _$CoreInfoCopyWithImpl(this._self, this._then);

  final CoreInfo _self;
  final $Res Function(CoreInfo) _then;

/// Create a copy of CoreInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? version = null,Object? iceServersConfigured = freezed,Object? notificationDeletedRetentionDays = freezed,}) {
  return _then(CoreInfo(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as Version,iceServersConfigured: freezed == iceServersConfigured ? _self.iceServersConfigured : iceServersConfigured // ignore: cast_nullable_to_non_nullable
as bool?,notificationDeletedRetentionDays: freezed == notificationDeletedRetentionDays ? _self.notificationDeletedRetentionDays : notificationDeletedRetentionDays // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [CoreInfo].
extension CoreInfoPatterns on CoreInfo {
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
mixin _$PostgresInfo {


/// Create a copy of PostgresInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PostgresInfoCopyWith<PostgresInfo> get copyWith => _$PostgresInfoCopyWithImpl<PostgresInfo>(this as PostgresInfo, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PostgresInfo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PostgresInfo&&(identical(other.version, _this.version) || other.version == _this.version));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PostgresInfo;
  return Object.hash(runtimeType,_this.version);
}

@override
String toString() {
  final _this = this as PostgresInfo;
  return 'PostgresInfo(version: ${_this.version})';
}


}

/// @nodoc
abstract mixin class $PostgresInfoCopyWith<$Res>  {
  factory $PostgresInfoCopyWith(PostgresInfo value, $Res Function(PostgresInfo) _then) = _$PostgresInfoCopyWithImpl;
@useResult
$Res call({
 String? version
});




}
/// @nodoc
class _$PostgresInfoCopyWithImpl<$Res>
    implements $PostgresInfoCopyWith<$Res> {
  _$PostgresInfoCopyWithImpl(this._self, this._then);

  final PostgresInfo _self;
  final $Res Function(PostgresInfo) _then;

/// Create a copy of PostgresInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? version = freezed,}) {
  return _then(PostgresInfo(
version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PostgresInfo].
extension PostgresInfoPatterns on PostgresInfo {
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
mixin _$AdapterInfo {


/// Create a copy of AdapterInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdapterInfoCopyWith<AdapterInfo> get copyWith => _$AdapterInfoCopyWithImpl<AdapterInfo>(this as AdapterInfo, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AdapterInfo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdapterInfo&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.version, _this.version) || other.version == _this.version)&&const DeepCollectionEquality().equals(other.supported, _this.supported)&&const DeepCollectionEquality().equals(other.custom, _this.custom));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AdapterInfo;
  return Object.hash(runtimeType,_this.name,_this.version,const DeepCollectionEquality().hash(_this.supported),const DeepCollectionEquality().hash(_this.custom));
}

@override
String toString() {
  final _this = this as AdapterInfo;
  return 'AdapterInfo(name: ${_this.name}, version: ${_this.version}, supported: ${_this.supported}, custom: ${_this.custom})';
}


}

/// @nodoc
abstract mixin class $AdapterInfoCopyWith<$Res>  {
  factory $AdapterInfoCopyWith(AdapterInfo value, $Res Function(AdapterInfo) _then) = _$AdapterInfoCopyWithImpl;
@useResult
$Res call({
 String? name, String? version, List<String>? supported, Map<String, dynamic>? custom
});




}
/// @nodoc
class _$AdapterInfoCopyWithImpl<$Res>
    implements $AdapterInfoCopyWith<$Res> {
  _$AdapterInfoCopyWithImpl(this._self, this._then);

  final AdapterInfo _self;
  final $Res Function(AdapterInfo) _then;

/// Create a copy of AdapterInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = freezed,Object? version = freezed,Object? supported = freezed,Object? custom = freezed,}) {
  return _then(AdapterInfo(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String?,supported: freezed == supported ? _self.supported : supported // ignore: cast_nullable_to_non_nullable
as List<String>?,custom: freezed == custom ? _self.custom : custom // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [AdapterInfo].
extension AdapterInfoPatterns on AdapterInfo {
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
mixin _$JanusInfo {


/// Create a copy of JanusInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JanusInfoCopyWith<JanusInfo> get copyWith => _$JanusInfoCopyWithImpl<JanusInfo>(this as JanusInfo, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as JanusInfo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JanusInfo&&(identical(other.plugins, _this.plugins) || other.plugins == _this.plugins)&&(identical(other.transports, _this.transports) || other.transports == _this.transports)&&(identical(other.version, _this.version) || other.version == _this.version));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as JanusInfo;
  return Object.hash(runtimeType,_this.plugins,_this.transports,_this.version);
}

@override
String toString() {
  final _this = this as JanusInfo;
  return 'JanusInfo(plugins: ${_this.plugins}, transports: ${_this.transports}, version: ${_this.version})';
}


}

/// @nodoc
abstract mixin class $JanusInfoCopyWith<$Res>  {
  factory $JanusInfoCopyWith(JanusInfo value, $Res Function(JanusInfo) _then) = _$JanusInfoCopyWithImpl;
@useResult
$Res call({
 Plugins? plugins, Transports? transports, String? version
});




}
/// @nodoc
class _$JanusInfoCopyWithImpl<$Res>
    implements $JanusInfoCopyWith<$Res> {
  _$JanusInfoCopyWithImpl(this._self, this._then);

  final JanusInfo _self;
  final $Res Function(JanusInfo) _then;

/// Create a copy of JanusInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? plugins = freezed,Object? transports = freezed,Object? version = freezed,}) {
  return _then(JanusInfo(
plugins: freezed == plugins ? _self.plugins : plugins // ignore: cast_nullable_to_non_nullable
as Plugins?,transports: freezed == transports ? _self.transports : transports // ignore: cast_nullable_to_non_nullable
as Transports?,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [JanusInfo].
extension JanusInfoPatterns on JanusInfo {
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
mixin _$GorushInfo {


/// Create a copy of GorushInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GorushInfoCopyWith<GorushInfo> get copyWith => _$GorushInfoCopyWithImpl<GorushInfo>(this as GorushInfo, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as GorushInfo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GorushInfo&&(identical(other.version, _this.version) || other.version == _this.version));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as GorushInfo;
  return Object.hash(runtimeType,_this.version);
}

@override
String toString() {
  final _this = this as GorushInfo;
  return 'GorushInfo(version: ${_this.version})';
}


}

/// @nodoc
abstract mixin class $GorushInfoCopyWith<$Res>  {
  factory $GorushInfoCopyWith(GorushInfo value, $Res Function(GorushInfo) _then) = _$GorushInfoCopyWithImpl;
@useResult
$Res call({
 String? version
});




}
/// @nodoc
class _$GorushInfoCopyWithImpl<$Res>
    implements $GorushInfoCopyWith<$Res> {
  _$GorushInfoCopyWithImpl(this._self, this._then);

  final GorushInfo _self;
  final $Res Function(GorushInfo) _then;

/// Create a copy of GorushInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? version = freezed,}) {
  return _then(GorushInfo(
version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [GorushInfo].
extension GorushInfoPatterns on GorushInfo {
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
mixin _$Transports {


/// Create a copy of Transports
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransportsCopyWith<Transports> get copyWith => _$TransportsCopyWithImpl<Transports>(this as Transports, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Transports;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Transports&&(identical(other.websocket, _this.websocket) || other.websocket == _this.websocket));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Transports;
  return Object.hash(runtimeType,_this.websocket);
}

@override
String toString() {
  final _this = this as Transports;
  return 'Transports(websocket: ${_this.websocket})';
}


}

/// @nodoc
abstract mixin class $TransportsCopyWith<$Res>  {
  factory $TransportsCopyWith(Transports value, $Res Function(Transports) _then) = _$TransportsCopyWithImpl;
@useResult
$Res call({
 Websocket? websocket
});




}
/// @nodoc
class _$TransportsCopyWithImpl<$Res>
    implements $TransportsCopyWith<$Res> {
  _$TransportsCopyWithImpl(this._self, this._then);

  final Transports _self;
  final $Res Function(Transports) _then;

/// Create a copy of Transports
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? websocket = freezed,}) {
  return _then(Transports(
websocket: freezed == websocket ? _self.websocket : websocket // ignore: cast_nullable_to_non_nullable
as Websocket?,
  ));
}

}


/// Adds pattern-matching-related methods to [Transports].
extension TransportsPatterns on Transports {
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
mixin _$Websocket {


/// Create a copy of Websocket
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WebsocketCopyWith<Websocket> get copyWith => _$WebsocketCopyWithImpl<Websocket>(this as Websocket, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Websocket;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Websocket&&(identical(other.version, _this.version) || other.version == _this.version));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Websocket;
  return Object.hash(runtimeType,_this.version);
}

@override
String toString() {
  final _this = this as Websocket;
  return 'Websocket(version: ${_this.version})';
}


}

/// @nodoc
abstract mixin class $WebsocketCopyWith<$Res>  {
  factory $WebsocketCopyWith(Websocket value, $Res Function(Websocket) _then) = _$WebsocketCopyWithImpl;
@useResult
$Res call({
 String? version
});




}
/// @nodoc
class _$WebsocketCopyWithImpl<$Res>
    implements $WebsocketCopyWith<$Res> {
  _$WebsocketCopyWithImpl(this._self, this._then);

  final Websocket _self;
  final $Res Function(Websocket) _then;

/// Create a copy of Websocket
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? version = freezed,}) {
  return _then(Websocket(
version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Websocket].
extension WebsocketPatterns on Websocket {
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
mixin _$Plugins {


/// Create a copy of Plugins
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PluginsCopyWith<Plugins> get copyWith => _$PluginsCopyWithImpl<Plugins>(this as Plugins, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Plugins;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Plugins&&(identical(other.sip, _this.sip) || other.sip == _this.sip));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Plugins;
  return Object.hash(runtimeType,_this.sip);
}

@override
String toString() {
  final _this = this as Plugins;
  return 'Plugins(sip: ${_this.sip})';
}


}

/// @nodoc
abstract mixin class $PluginsCopyWith<$Res>  {
  factory $PluginsCopyWith(Plugins value, $Res Function(Plugins) _then) = _$PluginsCopyWithImpl;
@useResult
$Res call({
 SipVersion? sip
});




}
/// @nodoc
class _$PluginsCopyWithImpl<$Res>
    implements $PluginsCopyWith<$Res> {
  _$PluginsCopyWithImpl(this._self, this._then);

  final Plugins _self;
  final $Res Function(Plugins) _then;

/// Create a copy of Plugins
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sip = freezed,}) {
  return _then(Plugins(
sip: freezed == sip ? _self.sip : sip // ignore: cast_nullable_to_non_nullable
as SipVersion?,
  ));
}

}


/// Adds pattern-matching-related methods to [Plugins].
extension PluginsPatterns on Plugins {
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
mixin _$SipVersion {


/// Create a copy of SipVersion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SipVersionCopyWith<SipVersion> get copyWith => _$SipVersionCopyWithImpl<SipVersion>(this as SipVersion, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SipVersion;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SipVersion&&(identical(other.version, _this.version) || other.version == _this.version));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SipVersion;
  return Object.hash(runtimeType,_this.version);
}

@override
String toString() {
  final _this = this as SipVersion;
  return 'SipVersion(version: ${_this.version})';
}


}

/// @nodoc
abstract mixin class $SipVersionCopyWith<$Res>  {
  factory $SipVersionCopyWith(SipVersion value, $Res Function(SipVersion) _then) = _$SipVersionCopyWithImpl;
@useResult
$Res call({
 String? version
});




}
/// @nodoc
class _$SipVersionCopyWithImpl<$Res>
    implements $SipVersionCopyWith<$Res> {
  _$SipVersionCopyWithImpl(this._self, this._then);

  final SipVersion _self;
  final $Res Function(SipVersion) _then;

/// Create a copy of SipVersion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? version = freezed,}) {
  return _then(SipVersion(
version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SipVersion].
extension SipVersionPatterns on SipVersion {
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
