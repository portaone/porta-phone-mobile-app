import 'package:material_ui/material_ui.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/blocs/blocs.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/environment_config.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/features/features.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

@RoutePage()
class ContactsScreenPage extends StatelessWidget {
  // ignore: use_key_in_widget_constructors
  const ContactsScreenPage({required this.sourceTypes});

  final List<ContactSourceType> sourceTypes;

  static PageRouteInfo<dynamic>? getPageRouteInfo(RouteMatch route, List<ContactSourceType> Function() sourceTypes) {
    final featureRoute = route.findRouteWithRequiredParams(ContactsScreenPageRoute.page);
    return featureRoute != null ? ContactsScreenPageRoute(sourceTypes: sourceTypes()) : null;
  }

  @override
  Widget build(BuildContext context) {
    final widget = ContactsScreen(
      title: Text(EnvironmentConfig.APP_NAME),
      // On a watch the list is headed by the section's own name, as the hub
      // shows it.
      watchTitle: context.watchSectionTitle<ContactsBottomMenuTab>(
        fallback: context.l10n.main_BottomNavigationBarItemLabel_contacts,
      ),
      sourceTypes: sourceTypes,
      sourceTypeWidgetBuilder: contactSourceTypeWidgetBuilder,
      sourceTypeWatchWidgetBuilder: contactSourceTypeWatchWidgetBuilder,
    );
    final provider = BlocProvider(
      create: (context) => ContactsBloc(activeContactsListRepository: context.read<ActiveContactsListRepository>()),
      child: widget,
    );
    return provider;
  }
}

/// Mounts the list of one contact source with the blocs that feed it.
///
/// Shared by both contacts screens: the arrangement around the lists differs
/// between them, the lists themselves do not.
Widget contactSourceTypeWidgetBuilder(
  BuildContext context,
  ContactSourceType sourceType, {
  bool markFavorites = false,
}) {
  return _contactSourceTypeBlocProvider(context, sourceType, switch (sourceType) {
    ContactSourceType.local => ContactsLocalTab(markFavorites: markFavorites),
    ContactSourceType.external => ContactsExternalTab(markFavorites: markFavorites),
  });
}

/// Mounts the list of one contact source on a watch, with the same blocs as
/// the phone's.
Widget contactSourceTypeWatchWidgetBuilder(BuildContext context, ContactSourceType sourceType) {
  return _contactSourceTypeBlocProvider(context, sourceType, switch (sourceType) {
    ContactSourceType.local => const ContactsLocalTabWatch(),
    ContactSourceType.external => const ContactsExternalTabWatch(),
  });
}

/// Provides [child] with the bloc of the contact source it lists.
Widget _contactSourceTypeBlocProvider(BuildContext context, ContactSourceType sourceType, Widget child) {
  switch (sourceType) {
    case ContactSourceType.local:
      return BlocProvider(
        create: (context) {
          final contactsSearchBloc = context.read<ContactsBloc>();
          return ContactsLocalTabBloc(
            contactsRepository: context.read<ContactsRepository>(),
            contactsSearchBloc: contactsSearchBloc,
            localContactsSyncCubit: context.read<LocalContactsSyncCubit>(),
          )..add(ContactsLocalTabStarted(search: contactsSearchBloc.state.search));
        },
        child: child,
      );
    case ContactSourceType.external:
      final sync = context.read<ExternalContactsSync>();
      return BlocProvider(
        create: (context) {
          final contactsSearchBloc = context.read<ContactsBloc>();
          return ContactsExternalTabBloc(
            contactsRepository: context.read<ContactsRepository>(),
            contactsSearchBloc: contactsSearchBloc,
            syncState: sync,
            syncRunner: sync,
          )..add(ContactsExternalTabStarted(search: contactsSearchBloc.state.search));
        },
        child: child,
      );
  }
}

/// Mounts the favourites section's own list.
///
/// The same bloc, the same rows, the same empty state as the favourites
/// section: a second list built from the contacts table would be a second
/// answer to the same question.
///
/// The bloc is not provided here. The button that turns rearranging on sits in
/// the screen's scaffold, above this, and has to read the same list to know
/// whether rearranging is worth offering at all.
Widget contactsFavoritesWidgetBuilder(
  BuildContext context, {
  bool reorderMode = false,
  void Function(int index)? onReorderStart,
  void Function(int index)? onReorderEnd,
}) {
  final featureAccess = context.read<FeatureAccess>();
  final cdrsEnabled = featureAccess.bottomMenuConfig.getTabEnabled<RecentsBottomMenuTab>()?.supportsCallHistory;

  return FavoritesList(
    reorderMode: reorderMode,
    onReorderStart: onReorderStart,
    onReorderEnd: onReorderEnd,
    transferEnabled: featureAccess.callConfig.capabilities.isBlindTransferEnabled,
    videoEnabled: featureAccess.callConfig.capabilities.isVideoCallEnabled,
    chatsEnabled: featureAccess.messagingConfig.chatsPresent,
    smssEnabled: featureAccess.messagingConfig.smsPresent,
    cdrsEnabled: cdrsEnabled ?? false,
  );
}

/// Mounts the favourites section's list on a watch, drawn by [body]: the same
/// bloc and the same rows as the favourites section's.
Widget contactsFavoritesWatchWidgetBuilder(BuildContext context, FavoritesWatchBodyBuilder body) {
  final featureAccess = context.read<FeatureAccess>();
  final cdrsEnabled = featureAccess.bottomMenuConfig.getTabEnabled<RecentsBottomMenuTab>()?.supportsCallHistory;

  return FavoritesWatchList(cdrsEnabled: cdrsEnabled ?? false, body: body);
}
