import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'app/app.dart';
import 'features/notifications/local_notification_service.dart';

import 'package:camera/camera.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init timezone database
  tz.initializeTimeZones();

  // Auto-detect device timezone (e.g. "Asia/Jakarta", "America/Los_Angeles")
  final String timeZoneName = await FlutterTimezone.getLocalTimezone();
  final cameras = await availableCameras();

  // Set local timezone for tz package
  tz.setLocalLocation(tz.getLocation(timeZoneName));

  await LocalNotificationService.instance.init();

  runApp(RuangBelajarApp(cameras: cameras));
}