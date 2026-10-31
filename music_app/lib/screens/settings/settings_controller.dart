import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:muzee/constants/app_constants.dart';
import 'package:muzee/extensions/l10n.dart';
import 'package:muzee/main.dart';
import 'package:muzee/screens/search/search_controller.dart';
import 'package:muzee/services/common_services.dart';
import 'package:muzee/services/data_manager.dart';
import 'package:muzee/services/monetization/entitlement_service.dart';
import 'package:muzee/services/settings_manager.dart';
import 'package:muzee/utilities/flutter_bottom_sheet.dart';
import 'package:muzee/utilities/flutter_toast.dart';
import 'package:muzee/utilities/language_utils.dart';
import 'package:muzee/widgets/bottom_sheet_bar.dart';
import 'package:muzee/widgets/confirmation_dialog.dart';
import 'package:youtube_charts/youtube_charts.dart';

class SettingsController {
  final ValueNotifier<String> cacheSizeNotifier = ValueNotifier('0 B');

  Future<void> loadCacheSize() async {
    final size = await getCacheSize();
    cacheSizeNotifier.value = size;
  }

  Future<void> clearAppCache(BuildContext context) async {
    final cleared = await clearCache();
    if (context.mounted) {
      showToast(
        context,
        cleared ? '${context.l10n!.cacheMsg}!' : context.l10n!.error,
      );
      await loadCacheSize();
    }
  }

  void showCountryPicker(BuildContext context) {
    const availableCountries = YouTubeChartsCountry.values;
    final activeCountry = youtubeChartsCountryNotifier.value;

    showCustomBottomSheet(
      context,
      ListView.builder(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        padding: commonListViewBottomPadding,
        itemCount: availableCountries.length,
        itemBuilder: (context, index) {
          final country = availableCountries[index];

          return BottomSheetBar(country.displayName, () {
            youtubeChartsCountryNotifier.value = country;
            Hive.box('settings').put('youtubeChartsCountry', country.name);
            Navigator.pop(context);
          }, activeCountry == country);
        },
      ),
    );
  }

  void showLanguagePicker(BuildContext context) {
    final availableLanguages = appLanguages.toList();
    final activeLanguageCode = Localizations.localeOf(context).languageCode;
    final activeScriptCode = Localizations.localeOf(context).scriptCode;
    final activeLanguageFullCode = activeScriptCode != null
        ? '$activeLanguageCode-$activeScriptCode'
        : activeLanguageCode;

    showCustomBottomSheet(
      context,
      ListView.builder(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        padding: commonListViewBottomPadding,
        itemCount: availableLanguages.length,
        itemBuilder: (context, index) {
          final language = availableLanguages[index];
          final newLocale = getLocaleFromLanguageCode(language);
          final newLocaleFullCode = newLocale.scriptCode != null
              ? '${newLocale.languageCode}-${newLocale.scriptCode}'
              : newLocale.languageCode;

          return BottomSheetBar(
            getLanguageDisplayName(context, language),
            () {
              addOrUpdateData('settings', 'languageCode', newLocaleFullCode);
              Musify.updateAppState(context, newLocale: newLocale);
              showToast(context, context.l10n!.languageMsg);
              Navigator.pop(context);
            },
            activeLanguageFullCode == newLocaleFullCode,
          );
        },
      ),
    );
  }

  void toggleExternalRecommendations(BuildContext context, bool value) {
    addOrUpdateData('settings', 'externalRecommendations', value);
    externalRecommendations.value = value;
  }

  void showConfirmationDialog({
    required BuildContext context,
    required String confirmationMessage,
    required VoidCallback onSubmit,
    String? submitMessage,
    bool isDangerous = false,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ConfirmationDialog(
          submitMessage: submitMessage ?? context.l10n!.clear,
          confirmationMessage: confirmationMessage,
          isDangerous: isDangerous,
          onCancel: () => Navigator.of(context).pop(),
          onSubmit: () {
            Navigator.of(context).pop();
            onSubmit();
          },
        );
      },
    );
  }

  Future<void> backupUserData(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;

    try {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            icon: Icon(
              FluentIcons.info_24_regular,
              color: colorScheme.primary,
              size: 32,
            ),
            content: Text(
              context.l10n!.folderRestrictions,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: <Widget>[
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.l10n!.understand),
              ),
            ],
          );
        },
      );
      final result = await backupData(context);
      if (context.mounted) {
        showToast(
          context,
          result.message,
          icon: result.success ? null : FluentIcons.error_circle_24_regular,
        );
      }
    } catch (e, stackTrace) {
      logger.log('Error backing up data', error: e, stackTrace: stackTrace);
      if (context.mounted) {
        showToast(
          context,
          context.l10n!.error,
          icon: FluentIcons.error_circle_24_regular,
        );
      }
    }
  }

  Future<void> handleRestoreUserData(BuildContext context) async {
    if (!EntitlementService.isPremium.value) {
      await context.push('/settings/premium');
      return;
    }
    try {
      final result = await restoreData(context);
      if (context.mounted) {
        showToast(
          context,
          result.message,
          icon: result.success ? null : FluentIcons.error_circle_24_regular,
        );
      }
    } catch (e, str) {
      logger.log('Error restoring data', error: e, stackTrace: str);
      if (context.mounted) {
        showToast(
          context,
          context.l10n!.error,
          icon: FluentIcons.error_circle_24_regular,
        );
      }
    }
  }

  Future<void> handleBackupUserData(BuildContext context) async {
    if (!EntitlementService.isPremium.value) {
      await context.push('/settings/premium');
      return;
    }
    await backupUserData(context);
  }

  void handleClearSearchHistory(BuildContext context) {
    showConfirmationDialog(
      context: context,
      confirmationMessage: context.l10n!.clearSearchHistoryQuestion,
      onSubmit: () {
        searchHistoryNotifier.value = [];
        deleteData('user', 'searchHistory');
        showToast(context, '${context.l10n!.searchHistoryMsg}!');
      },
    );
  }

  void handleClearRecentlyPlayed(BuildContext context) {
    showConfirmationDialog(
      context: context,
      confirmationMessage: context.l10n!.clearRecentlyPlayedQuestion,
      onSubmit: () {
        userRecentlyPlayed = [];
        deleteData('user', 'recentlyPlayedSongs');
        showToast(context, '${context.l10n!.recentlyPlayedMsg}!');
      },
    );
  }
}
