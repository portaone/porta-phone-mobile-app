part of 'network_cubit.dart';

@freezed
class NetworkState with _$NetworkState {
  const NetworkState({this.incomingCallTypeModels = const [], this.incomingCallTypesRemainder = const []});

  final List<IncomingCallTypeModel> incomingCallTypeModels;

  final List<IncomingCallType> incomingCallTypesRemainder;

  IncomingCallTypeModel? get selectedIncomingCallTypeModel =>
      incomingCallTypeModels.firstWhereOrNull((m) => m.selected);

  IncomingCallType get incomingCallType =>
      selectedIncomingCallTypeModel?.incomingCallType ?? IncomingCallType.pushNotification;

  bool get isSelectedTypeInRemainder => incomingCallTypesRemainder.contains(incomingCallType);
}
