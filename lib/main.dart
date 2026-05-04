import 'package:flutter/material.dart';
import 'app.dart';
import 'data/notification_service.dart';
import 'data/settings_service.dart';
import 'tutorial/tutorial_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SettingsService.instance.init();
  await NotificationService.instance.init();

  await TutorialService.instance.init();
  runApp(const KoviraApp());
}
