import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:muzee/constants/app_constants.dart';
import 'package:muzee/constants/version.dart';
import 'package:muzee/extensions/l10n.dart';
import 'package:muzee/main.dart';
import 'package:muzee/screens/settings/settings_controller.dart';
import 'package:muzee/services/data_manager.dart';
import 'package:muzee/services/monetization/entitlement_service.dart';
import 'package:muzee/services/router_service.dart';
import 'package:muzee/services/settings_manager.dart';
import 'package:muzee/theme/neo/neo_colors.dart';
import 'package:muzee/utilities/language_utils.dart';
import 'package:muzee/utilities/url_launcher.dart';
import 'package:muzee/widgets/settings_account_section.dart';
import 'package:muzee/widgets/settings_monetization_section.dart';
import 'package:muzee/widgets/tubify_components.dart';
import 'package:youtube_charts/youtube_charts.dart';

/// Settings, opened full screen from the Home header. One layout for every
/// width (capped on tablets).
class SettingsMobileView extends StatefulWidget {
  const SettingsMobileView({super.key, required this.controller});
  final SettingsController controller;

  @override
  State<SettingsMobileView> createState() => _SettingsMobileViewState();
}

class _SettingsMobileViewState extends State<SettingsMobileView> {
  @override
  void initState() {
    super.initState();
    widget.controller.loadCacheSize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n!.settings)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.viewPaddingOf(context).bottom + 24,
            ),
            children: <Widget>[
              const SettingsMonetizationSection(),
              _buildPlaybackSection(context),
              const SettingsAccountSection(),
              _buildPreferencesSection(context),
              _buildDataSection(context),
              _buildAboutSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _switch(bool value, ValueChanged<bool> onChanged) =>
      // Colors come from the theme's switchTheme (a check in the thumb when
      // on, an outlined track when off).
      Switch(value: value, onChanged: onChanged);

  Widget _buildPlaybackSection(BuildContext context) {
    final l10n = context.l10n!;
    return TubifySettingsSection(
      title: l10n.playbackSection,
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: playNextSongAutomatically,
          builder: (_, value, __) => TubifySettingsTile(
            title: l10n.automaticSongPicker,
            subtitle: l10n.automaticSongPickerDescription,
            icon: FluentIcons.wand_24_regular,
            trailing: _switch(
              value,
              (_) => audioHandler.changeAutoPlayNextStatus(),
            ),
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: externalRecommendations,
          builder: (_, value, __) => TubifySettingsTile(
            title: l10n.externalRecommendations,
            subtitle: l10n.externalRecommendationsDescription,
            icon: FluentIcons.thumb_like_24_regular,
            trailing: _switch(
              value,
              (value) => widget.controller.toggleExternalRecommendations(
                context,
                value,
              ),
            ),
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: useProxy,
          builder: (_, value, __) => TubifySettingsTile(
            title: l10n.useProxy,
            icon: FluentIcons.globe_shield_24_regular,
            trailing: _switch(value, (value) {
              useProxy.value = value;
              addOrUpdateData('settings', 'useProxy', value);
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildPreferencesSection(BuildContext context) {
    final l10n = context.l10n!;
    return TubifySettingsSection(
      title: l10n.preferences,
      children: [
        ValueListenableBuilder<YouTubeChartsCountry>(
          valueListenable: youtubeChartsCountryNotifier,
          builder: (context, country, _) => TubifySettingsTile(
            title: l10n.country,
            icon: FluentIcons.earth_24_regular,
            trailingText: country.displayName,
            onTap: () => widget.controller.showCountryPicker(context),
          ),
        ),
        TubifySettingsTile(
          title: l10n.language,
          icon: FluentIcons.local_language_24_regular,
          trailingText: getLanguageDisplayName(
            context,
            Localizations.localeOf(context).languageCode,
          ),
          onTap: () => widget.controller.showLanguagePicker(context),
        ),
      ],
    );
  }

  Widget _buildDataSection(BuildContext context) {
    final l10n = context.l10n!;
    return ValueListenableBuilder<bool>(
      valueListenable: EntitlementService.isPremium,
      builder: (context, premium, _) {
        // Backup to a file is a Premium benefit: free users see the badge
        // (the tap opens Muzee Premium).
        final badge = premium ? null : const _PremiumBadge();
        return TubifySettingsSection(
          title: l10n.dataSection,
          children: [
            TubifySettingsTile(
              title: l10n.backupUserData,
              icon: FluentIcons.archive_24_regular,
              trailing: badge,
              onTap: () => widget.controller.handleBackupUserData(context),
            ),
            TubifySettingsTile(
              title: l10n.restoreUserData,
              icon: FluentIcons.archive_arrow_back_24_regular,
              trailing: badge,
              onTap: () => widget.controller.handleRestoreUserData(context),
            ),
            ValueListenableBuilder<String>(
              valueListenable: widget.controller.cacheSizeNotifier,
              builder: (context, cacheSize, _) => TubifySettingsTile(
                title: l10n.clearCache,
                icon: FluentIcons.broom_24_regular,
                trailingText: cacheSize,
                trailing: const SizedBox.shrink(),
                onTap: () => widget.controller.clearAppCache(context),
              ),
            ),
            TubifySettingsTile(
              title: l10n.clearSearchHistory,
              icon: FluentIcons.search_24_regular,
              onTap: () => widget.controller.handleClearSearchHistory(context),
            ),
            TubifySettingsTile(
              title: l10n.clearRecentlyPlayed,
              icon: FluentIcons.history_dismiss_24_regular,
              onTap: () => widget.controller.handleClearRecentlyPlayed(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    final l10n = context.l10n!;
    return TubifySettingsSection(
      title: l10n.others,
      children: [
        TubifySettingsTile(
          title: l10n.termsOfService,
          icon: FluentIcons.document_text_24_regular,
          onTap: () => launchURL(Uri.parse(termsOfServiceUrl)),
        ),
        TubifySettingsTile(
          title: l10n.privacyPolicy,
          icon: FluentIcons.shield_24_regular,
          onTap: () => launchURL(Uri.parse(privacyPolicyUrl)),
        ),
        TubifySettingsTile(
          title: l10n.version,
          icon: FluentIcons.info_24_regular,
          trailingText: appVersion,
        ),
        if (kDebugMode)
          TubifySettingsTile(
            title: 'Design system',
            icon: FluentIcons.color_24_regular,
            onTap: () => NavigationManager.router.push(
              NavigationManager.designSystemPath,
            ),
          ),
      ],
    );
  }
}

class _PremiumBadge extends StatelessWidget {
  const _PremiumBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: context.neo.accentSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        context.l10n!.premiumBadge,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: context.neo.onAccentSoft),
      ),
    );
  }
}
