// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'embedded_resource.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EmbeddedResource {


/// Create a copy of EmbeddedResource
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmbeddedResourceCopyWith<EmbeddedResource> get copyWith => _$EmbeddedResourceCopyWithImpl<EmbeddedResource>(this as EmbeddedResource, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as EmbeddedResource;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmbeddedResource&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.uri, _this.uri) || other.uri == _this.uri)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.toolbar, _this.toolbar) || other.toolbar == _this.toolbar)&&(identical(other.metadata, _this.metadata) || other.metadata == _this.metadata)&&const DeepCollectionEquality().equals(other.payload, _this.payload)&&(identical(other.enableConsoleLogCapture, _this.enableConsoleLogCapture) || other.enableConsoleLogCapture == _this.enableConsoleLogCapture)&&(identical(other.reconnectStrategy, _this.reconnectStrategy) || other.reconnectStrategy == _this.reconnectStrategy)&&(identical(other.resultStrategy, _this.resultStrategy) || other.resultStrategy == _this.resultStrategy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as EmbeddedResource;
  return Object.hash(runtimeType,_this.id,_this.uri,_this.type,_this.toolbar,_this.metadata,const DeepCollectionEquality().hash(_this.payload),_this.enableConsoleLogCapture,_this.reconnectStrategy,_this.resultStrategy);
}

@override
String toString() {
  final _this = this as EmbeddedResource;
  return 'EmbeddedResource(id: ${_this.id}, uri: ${_this.uri}, type: ${_this.type}, toolbar: ${_this.toolbar}, metadata: ${_this.metadata}, payload: ${_this.payload}, enableConsoleLogCapture: ${_this.enableConsoleLogCapture}, reconnectStrategy: ${_this.reconnectStrategy}, resultStrategy: ${_this.resultStrategy})';
}


}

/// @nodoc
abstract mixin class $EmbeddedResourceCopyWith<$Res>  {
  factory $EmbeddedResourceCopyWith(EmbeddedResource value, $Res Function(EmbeddedResource) _then) = _$EmbeddedResourceCopyWithImpl;
@useResult
$Res call({
 String id, String uri, EmbeddedResourceType type, ToolbarConfig toolbar, Metadata metadata, List<String> payload, bool enableConsoleLogCapture, String? reconnectStrategy, ResultStrategyConfig? resultStrategy
});




}
/// @nodoc
class _$EmbeddedResourceCopyWithImpl<$Res>
    implements $EmbeddedResourceCopyWith<$Res> {
  _$EmbeddedResourceCopyWithImpl(this._self, this._then);

  final EmbeddedResource _self;
  final $Res Function(EmbeddedResource) _then;

/// Create a copy of EmbeddedResource
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? uri = null,Object? type = null,Object? toolbar = null,Object? metadata = null,Object? payload = null,Object? enableConsoleLogCapture = null,Object? reconnectStrategy = freezed,Object? resultStrategy = freezed,}) {
  return _then(EmbeddedResource(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,uri: null == uri ? _self.uri : uri // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as EmbeddedResourceType,toolbar: null == toolbar ? _self.toolbar : toolbar // ignore: cast_nullable_to_non_nullable
as ToolbarConfig,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Metadata,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as List<String>,enableConsoleLogCapture: null == enableConsoleLogCapture ? _self.enableConsoleLogCapture : enableConsoleLogCapture // ignore: cast_nullable_to_non_nullable
as bool,reconnectStrategy: freezed == reconnectStrategy ? _self.reconnectStrategy : reconnectStrategy // ignore: cast_nullable_to_non_nullable
as String?,resultStrategy: freezed == resultStrategy ? _self.resultStrategy : resultStrategy // ignore: cast_nullable_to_non_nullable
as ResultStrategyConfig?,
  ));
}

}


/// Adds pattern-matching-related methods to [EmbeddedResource].
extension EmbeddedResourcePatterns on EmbeddedResource {
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
mixin _$ToolbarConfig {


/// Create a copy of ToolbarConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ToolbarConfigCopyWith<ToolbarConfig> get copyWith => _$ToolbarConfigCopyWithImpl<ToolbarConfig>(this as ToolbarConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ToolbarConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ToolbarConfig&&(identical(other.titleL10n, _this.titleL10n) || other.titleL10n == _this.titleL10n)&&(identical(other.showToolbar, _this.showToolbar) || other.showToolbar == _this.showToolbar));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ToolbarConfig;
  return Object.hash(runtimeType,_this.titleL10n,_this.showToolbar);
}

@override
String toString() {
  final _this = this as ToolbarConfig;
  return 'ToolbarConfig(titleL10n: ${_this.titleL10n}, showToolbar: ${_this.showToolbar})';
}


}

/// @nodoc
abstract mixin class $ToolbarConfigCopyWith<$Res>  {
  factory $ToolbarConfigCopyWith(ToolbarConfig value, $Res Function(ToolbarConfig) _then) = _$ToolbarConfigCopyWithImpl;
@useResult
$Res call({
 String? titleL10n, bool showToolbar
});




}
/// @nodoc
class _$ToolbarConfigCopyWithImpl<$Res>
    implements $ToolbarConfigCopyWith<$Res> {
  _$ToolbarConfigCopyWithImpl(this._self, this._then);

  final ToolbarConfig _self;
  final $Res Function(ToolbarConfig) _then;

/// Create a copy of ToolbarConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? titleL10n = freezed,Object? showToolbar = null,}) {
  return _then(ToolbarConfig(
titleL10n: freezed == titleL10n ? _self.titleL10n : titleL10n // ignore: cast_nullable_to_non_nullable
as String?,showToolbar: null == showToolbar ? _self.showToolbar : showToolbar // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ToolbarConfig].
extension ToolbarConfigPatterns on ToolbarConfig {
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
