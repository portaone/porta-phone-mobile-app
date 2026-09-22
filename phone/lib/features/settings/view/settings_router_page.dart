import 'package:flutter/widgets.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/features/call_center/call_center.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

import '../features/sessions/sessions.dart';

@RoutePage()
class SettingsRouterPage extends StatelessWidget {
  const SettingsRouterPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Provided above the router so the settings row badge and the sessions
    // screen share one list: revoking a session updates the badge right away.
    // The call queues are here for the same reason - the row that leads to
    // them only exists while the list is not empty, so it has to read the same
    // state the screen does.
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => SessionsCubit(context.read<SessionsRepository>())..fetch()),
        BlocProvider(
          create: (context) {
            final cubit = CallQueuesCubit(context.read<CallQueuesRepository>());
            // Someone the backend has already called "not an agent" is not
            // asked about again every time they open their settings: the
            // answer is per account and the read costs the PBX a walk of the
            // customer's hunt groups. Anyone else gets a fresh list, because
            // the row shows a count.
            if (cubit.state.isAgent || !cubit.state.known) cubit.refresh();
            return cubit;
          },
        ),
      ],
      child: const AutoRouter(),
    );
  }
}
