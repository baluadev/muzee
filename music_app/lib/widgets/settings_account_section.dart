import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:muzee/extensions/l10n.dart';
import 'package:muzee/main.dart' show logger;
import 'package:muzee/services/cloud_backup_service.dart';
import 'package:muzee/services/data_manager.dart';
import 'package:muzee/services/firebase/remote_config_service.dart';
import 'package:muzee/services/google_account_service.dart';
import 'package:muzee/services/settings_manager.dart';
import 'package:muzee/utilities/flutter_toast.dart';
import 'package:muzee/widgets/confirmation_dialog.dart';
import 'package:muzee/widgets/tubify_components.dart';

/// Google account and cloud backup. Hidden unless Remote Config's
/// `login_google` is on (always shown in debug builds).
class SettingsAccountSection extends StatefulWidget {
  const SettingsAccountSection({super.key});

  @override
  State<SettingsAccountSection> createState() => _SettingsAccountSectionState();
}

class _SettingsAccountSectionState extends State<SettingsAccountSection> {
  final _accounts = GoogleAccountService.instance;
  bool _working = false;

  Future<void> _signIn() async {
    final ok = await _accounts.signIn();
    // Closing the Google page (null) is not a failure worth a message.
    if (ok == false && mounted) {
      showToast(
        context,
        context.l10n!.signInFailed,
        icon: FluentIcons.error_circle_24_regular,
      );
    }
  }

  Future<void> _run(
    Future<String> Function(String email) task,
    String failure,
  ) async {
    final email = _accounts.account.value?.email;
    if (email == null || _working) return;
    setState(() => _working = true);
    try {
      final message = await task(email);
      if (mounted) showToast(context, message);
    } catch (e, stackTrace) {
      logger.log('Cloud backup task failed', error: e, stackTrace: stackTrace);
      if (mounted) {
        showToast(context, failure, icon: FluentIcons.error_circle_24_regular);
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _backup() {
    final l10n = context.l10n!;
    return _run((email) async {
      await CloudBackupService.instance.backup(email);
      return l10n.cloudBackupDone;
    }, l10n.cloudBackupFailed);
  }

  void _confirmRestore() {
    final l10n = context.l10n!;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => ConfirmationDialog(
        confirmationMessage: l10n.cloudRestoreConfirm,
        submitMessage: l10n.cloudRestore,
        isDangerous: true,
        onCancel: () => Navigator.pop(dialogContext),
        onSubmit: () {
          Navigator.pop(dialogContext);
          _run((email) async {
            final restored = await CloudBackupService.instance.restore(email);
            return restored ? l10n.cloudRestoreDone : l10n.cloudRestoreEmpty;
          }, l10n.cloudRestoreFailed);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n!;
    return ValueListenableBuilder<bool>(
      valueListenable: RemoteConfigService.instance.loginGoogleEnabled,
      builder: (context, enabled, _) {
        if (!enabled) return const SizedBox.shrink();
        return ValueListenableBuilder<GoogleAccount?>(
          valueListenable: _accounts.account,
          builder: (context, account, _) {
            if (account == null) {
              return TubifySettingsSection(
                title: l10n.account,
                children: [
                  ValueListenableBuilder<bool>(
                    valueListenable: _accounts.busy,
                    builder: (context, busy, _) => TubifySettingsTile(
                      title: l10n.signInWithGoogle,
                      icon: FluentIcons.person_add_24_regular,
                      trailing: busy ? const _Spinner() : null,
                      onTap: busy ? null : _signIn,
                    ),
                  ),
                ],
              );
            }
            return TubifySettingsSection(
              title: l10n.account,
              children: [
                TubifySettingsTile(
                  title: account.name ?? account.email,
                  icon: FluentIcons.person_24_filled,
                  trailing: account.pictureUrl == null
                      ? null
                      : CircleAvatar(
                          radius: 14,
                          backgroundImage: NetworkImage(account.pictureUrl!),
                        ),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: personalizeWithYouTube,
                  builder: (context, on, _) => TubifySettingsTile(
                    title: l10n.personalizeWithYouTube,
                    subtitle: l10n.personalizeWithYouTubeDescription,
                    icon: FluentIcons.sparkle_24_regular,
                    trailing: Switch(
                      value: on,
                      onChanged: (value) {
                        personalizeWithYouTube.value = value;
                        addOrUpdateData(
                          'settings',
                          'personalizeWithYouTube',
                          value,
                        );
                      },
                    ),
                  ),
                ),
                TubifySettingsTile(
                  title: l10n.cloudBackup,
                  icon: FluentIcons.cloud_arrow_up_24_regular,
                  trailing: _working ? const _Spinner() : null,
                  onTap: _working ? null : _backup,
                ),
                TubifySettingsTile(
                  title: l10n.cloudRestore,
                  icon: FluentIcons.cloud_arrow_down_24_regular,
                  onTap: _working ? null : _confirmRestore,
                ),
                TubifySettingsTile(
                  title: l10n.signOut,
                  icon: FluentIcons.sign_out_24_regular,
                  onTap: _working ? null : _accounts.signOut,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 18,
    height: 18,
    child: CircularProgressIndicator(strokeWidth: 2),
  );
}
