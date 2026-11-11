import 'package:material_ui/material_ui.dart';

import 'package:auto_route/auto_route.dart';

import 'package:webtrit_phone/app/router/app_router.dart';

/// Opens the calls with a favourite's number: the account's call history
/// where the deployment keeps one, the device's call log otherwise.
///
/// Shared by the favourites list of a phone and of a watch, so both open the
/// same page for the same number.
void openFavoriteCallLog(BuildContext context, {required String number, required bool cdrsEnabled}) {
  if (cdrsEnabled) {
    context.router.navigate(NumberCdrsScreenPageRoute(number: number));
  } else {
    context.router.navigate(CallLogScreenPageRoute(number: number));
  }
}
