part of 'network_cubit.dart';

@freezed
class NetworkState with _$NetworkState {
  const NetworkState({
    this.incomingCallTypeModels = const [],
    this.incomingCallTypesRemainder = const [],
    this.smsFallbackEnabled = false,
  });

  final List<IncomingCallTypeModel> incomingCallTypeModels;

  final List<IncomingCallType> incomingCallTypesRemainder;

  final bool smsFallbackEnabled;

  IncomingCallTypeModel? get selectedIncomingCallTypeModel =>
      incomingCallTypeModels.firstWhereOrNull((m) => m.selected);

  IncomingCallType get incomingCallType =>
      selectedIncomingCallTypeModel?.incomingCallType ?? IncomingCallType.pushNotification;

  bool get isSelectedTypeInRemainder => incomingCallTypesRemainder.contains(incomingCallType);
}
