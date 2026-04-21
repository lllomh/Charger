import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'providers/battery_provider.dart';
import 'screens/charger_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WakelockPlus.enable();
  _initForegroundTask();
  runApp(const ChargerApp());
}

void _initForegroundTask() {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'charger_fg_channel',
      channelName: 'Charger Animation',
      channelDescription: 'Keeps the charging animation running',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
    ),
    iosNotificationOptions: const IOSNotificationOptions(),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(10000),
      autoRunOnBoot: false,
    ),
  );
}

class ChargerApp extends StatelessWidget {
  const ChargerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BatteryProvider()..initialize(),
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        title: '电能波动',
        home: ChargerScreen(),
      ),
    );
  }
}
