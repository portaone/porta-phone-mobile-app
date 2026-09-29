import 'package:material_ui/material_ui.dart';

import 'package:api/api.dart';

import 'package:webtrit_phone/l10n/l10n.dart';

extension AccountErrorCodeL10n on AccountErrorCode {
  String l10n(BuildContext context) {
    return switch (this) {
      AccountErrorCode.passwordChangeRequired => context.l10n.account_selfCarePasswordExpired_message,
      AccountErrorCode.userNotFound => context.l10n.login_RequestFailureUserNotFoundError,
    };
  }
}
