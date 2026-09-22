import 'package:flutter/widgets.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/repositories/repositories.dart';

import '../bloc/bloc.dart';
import 'call_center_polling.dart';
import 'call_center_tab_screen.dart';

/// Route of the bottom-menu call center section.
///
/// It brings its own cubit because the settings stack, where the same screen
/// is also reached from, provides one of its own above its router - the state
/// they both mirror is the repository's, so two readers of it cost nothing and
/// neither placement has to know about the other.
@RoutePage()
class CallCenterTabPage extends StatelessWidget {
  // ignore: use_key_in_widget_constructors
  const CallCenterTabPage();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CallQueuesCubit(context.read<CallQueuesRepository>()),
      child: const CallCenterPolling(child: CallCenterTabScreen()),
    );
  }
}
