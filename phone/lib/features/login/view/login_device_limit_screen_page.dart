import 'package:material_ui/material_ui.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/data/data.dart';

import 'login_device_limit_screen.dart';

@RoutePage()
class LoginDeviceLimitScreenPage extends StatelessWidget {
  // ignore: use_key_in_widget_constructors
  const LoginDeviceLimitScreenPage();

  @override
  Widget build(BuildContext context) {
    return LoginDeviceLimitScreen(dateFormat: context.read<AppTime>().formatDateTime(true));
  }
}
