// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'call_to_actions_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CallToActionsCubitState {


/// Create a copy of CallToActionsCubitState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CallToActionsCubitStateCopyWith<CallToActionsCubitState> get copyWith => _$CallToActionsCubitStateCopyWithImpl<CallToActionsCubitState>(this as CallToActionsCubitState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CallToActionsCubitState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CallToActionsCubitState&&(identical(other.locale, _this.locale) || other.locale == _this.locale)&&const DeepCollectionEquality().equals(other.actions, _this.actions)&&(identical(other.visible, _this.visible) || other.visible == _this.visible)&&(identical(other.flavor, _this.flavor) || other.flavor == _this.flavor));
}


@override
int get hashCode {
  final _this = this as CallToActionsCubitState;
  return Object.hash(runtimeType,_this.locale,const DeepCollectionEquality().hash(_this.actions),_this.visible,_this.flavor);
}

@override
String toString() {
  final _this = this as CallToActionsCubitState;
  return 'CallToActionsCubitState(locale: ${_this.locale}, actions: ${_this.actions}, visible: ${_this.visible}, flavor: ${_this.flavor})';
}


}

/// @nodoc
abstract mixin class $CallToActionsCubitStateCopyWith<$Res>  {
  factory $CallToActionsCubitStateCopyWith(CallToActionsCubitState value, $Res Function(CallToActionsCubitState) _then) = _$CallToActionsCubitStateCopyWithImpl;
@useResult
$Res call({
 Locale locale, Map<MainFlavor, List<CallToAction>> actions, bool visible, MainFlavor? flavor
});




}
/// @nodoc
class _$CallToActionsCubitStateCopyWithImpl<$Res>
    implements $CallToActionsCubitStateCopyWith<$Res> {
  _$CallToActionsCubitStateCopyWithImpl(this._self, this._then);

  final CallToActionsCubitState _self;
  final $Res Function(CallToActionsCubitState) _then;

/// Create a copy of CallToActionsCubitState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? locale = null,Object? actions = null,Object? visible = null,Object? flavor = freezed,}) {
  return _then(CallToActionsCubitState(
locale: null == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as Locale,actions: null == actions ? _self.actions : actions // ignore: cast_nullable_to_non_nullable
as Map<MainFlavor, List<CallToAction>>,visible: null == visible ? _self.visible : visible // ignore: cast_nullable_to_non_nullable
as bool,flavor: freezed == flavor ? _self.flavor : flavor // ignore: cast_nullable_to_non_nullable
as MainFlavor?,
  ));
}

}


/// Adds pattern-matching-related methods to [CallToActionsCubitState].
extension CallToActionsCubitStatePatterns on CallToActionsCubitState {
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
