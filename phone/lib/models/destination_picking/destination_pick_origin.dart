import 'package:auto_route/auto_route.dart';

/// A purpose that knows which screen asked, and wants the person back on it.
///
/// Apart from `DestinationPickPurpose` because most purposes have no such
/// screen to name: a transfer is taken back to its call by the call itself.
abstract interface class DestinationPickOrigin {
  PageRouteInfo get origin;
}
