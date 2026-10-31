import 'package:flutter/material.dart';
import 'package:muzee/screens/settings/settings_controller.dart';
import 'package:muzee/screens/settings/settings_mobile_view.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final SettingsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SettingsController();
  }

  @override
  void dispose() {
    _controller.cacheSizeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // One layout for every width; the view caps its content at 720 dp.
    return SettingsMobileView(controller: _controller);
  }
}
