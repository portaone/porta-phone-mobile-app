import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/l10n/l10n.dart';

import '../models/models.dart';

extension CodeValidationErrorL10n on CodeValidationError {
  String? l10n(BuildContext context) {
    switch (this) {
      case CodeValidationError.blank:
        return context.l10n.validationBlankError;
    }
  }
}
