// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'demo_call_to_actions_param.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DemoCallToActionsParam {


/// Create a copy of DemoCallToActionsParam
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DemoCallToActionsParamCopyWith<DemoCallToActionsParam> get copyWith => _$DemoCallToActionsParamCopyWithImpl<DemoCallToActionsParam>(this as DemoCallToActionsParam, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DemoCallToActionsParam;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DemoCallToActionsParam&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.tab, _this.tab) || other.tab == _this.tab));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DemoCallToActionsParam;
  return Object.hash(runtimeType,_this.email,_this.tab);
}

@override
String toString() {
  final _this = this as DemoCallToActionsParam;
  return 'DemoCallToActionsParam(email: ${_this.email}, tab: ${_this.tab})';
}


}

/// @nodoc
abstract mixin class $DemoCallToActionsParamCopyWith<$Res>  {
  factory $DemoCallToActionsParamCopyWith(DemoCallToActionsParam value, $Res Function(DemoCallToActionsParam) _then) = _$DemoCallToActionsParamCopyWithImpl;
@useResult
$Res call({
 String email, String tab
});




}
/// @nodoc
class _$DemoCallToActionsParamCopyWithImpl<$Res>
    implements $DemoCallToActionsParamCopyWith<$Res> {
  _$DemoCallToActionsParamCopyWithImpl(this._self, this._then);

  final DemoCallToActionsParam _self;
  final $Res Function(DemoCallToActionsParam) _then;

/// Create a copy of DemoCallToActionsParam
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? email = null,Object? tab = null,}) {
  return _then(DemoCallToActionsParam(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,tab: null == tab ? _self.tab : tab // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DemoCallToActionsParam].
extension DemoCallToActionsParamPatterns on DemoCallToActionsParam {
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
