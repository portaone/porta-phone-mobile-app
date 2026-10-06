import 'package:flutter/widgets.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/bloc.dart';
import '../cubits/cubits.dart';

/// Builds from what a voicemail screen shows: the session's mailbox and the
/// screen's own state, read together.
///
/// The one place a widget takes both from, so none of them has to know that
/// the mailbox lives with the session and the rest with the screen - and none
/// can read one of the two and forget the other.
class VoicemailViewBuilder extends StatelessWidget {
  const VoicemailViewBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, VoicemailView view) builder;

  @override
  Widget build(BuildContext context) {
    final mailbox = context.watch<VoicemailSessionCubit>().state;
    final screen = context.watch<VoicemailCubit>().state;

    return builder(context, VoicemailView(mailbox: mailbox, screen: screen));
  }
}
