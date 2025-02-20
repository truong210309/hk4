import 'package:fe/pages/HomePage.dart';
import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  AwesomeNotifications().initialize(
    null, // Use default app icon
    [
      NotificationChannel(
        channelKey: 'auction_channel',
        channelName: 'Auction Notifications',
        channelDescription: 'Notifications for auction updates',
        defaultColor: Color(0xFF9D50DD),
        ledColor: Colors.white,
        importance: NotificationImportance.High,
        playSound: true,
      ),
      NotificationChannel(
        channelKey: 'payment_channel',
        channelName: 'Payment Notifications',
        channelDescription: 'Notifications for payment success',
        importance: NotificationImportance.High,
        playSound: true,
        ledColor: Colors.white,
      ),
      NotificationChannel(
        channelKey: 'otp_channel',
        channelName: 'OTP Notifications',
        channelDescription: 'Notifications for OTP verification',
        defaultColor: Color(0xFF9D50DD),
        ledColor: Colors.white,
        importance: NotificationImportance.High,
        playSound: true,
      ),
    ],
    debug: true, // Enable debug mode for logs
  );

  requestNotificationPermissions(); // Request permissions before running app
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Homepage(),
    );
  }
}

// Request notification permissions
void requestNotificationPermissions() async {
  bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
  if (!isAllowed) {
    await AwesomeNotifications().requestPermissionToSendNotifications();
  }
}