import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'navigation_service.dart';

extension LocaleSupport on BuildContext {
  AppLocalizations get locale {
    // AppLocalizations? curLocale = AppLocalizations.of(this);
    // if (curLocale == null) {
    //   throw Exception('Locale is required before Localization initalised!');
    // }
    return AppLocalizations.of(this);
  }
}

AppLocalizations get locale =>
    AppLocalizations.of(NavigationService.inst.curContext);

//  NavigationService
//     .inst.rootNavigatorKey.currentState!.overlay!.context.locale;
