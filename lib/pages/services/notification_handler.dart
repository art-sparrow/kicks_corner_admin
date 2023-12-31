import 'package:flutter_local_notifications/flutter_local_notifications.dart';

//first go to AndroidManifest.xml and add the meta data and intent filter
//under their respective sections
/* <meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="you_can_name_it_whatever1"
    />
<intent-filter>
    <action android:name="FLUTTER_NOTIFICATION_CLICK"/>
    <category android:name="android.intent.category.DEFAULT"/>
</intent-filter> */

//Also ensure you have added an app icon in the "res/drawable" folder before defining it as a "var androidInitialize" asset
//Components of a LocalNotification are 3 on Android and iOS --> Drawable icon, Title and Body.

class LocalNotification{
  static Future initialize (FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin)async{
    //var androidInitialize = const AndroidInitializationSettings("mipmap/ic_launcher"); //uses default flutter icon
    var androidInitialize = const AndroidInitializationSettings("shoe_icon"); //add a custom icon to the res/drawable/shoe_icon.png and reference it here

    DarwinInitializationSettings initializationSettingsDarwin = const DarwinInitializationSettings();

    var initializationsSettings = InitializationSettings(
      android: androidInitialize, iOS: initializationSettingsDarwin
    );

    await flutterLocalNotificationsPlugin.initialize(initializationsSettings);
  }

  static Future showBigTextNotification({
      var id = 0,
      required String title,
      required String body,
      var payload,
      required FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
    })async{
      AndroidNotificationDetails androidNotificationDetails = const AndroidNotificationDetails(
        'you_can_name_it_whatever1',
        'channel_name',
        playSound: true,
        importance: Importance.max,
        priority: Priority.high
      );

      const DarwinNotificationDetails darwinNotificationDetails = DarwinNotificationDetails(
        presentSound: false
      );

      var not = NotificationDetails(
        android: androidNotificationDetails,
        iOS: darwinNotificationDetails,
      );

      await flutterLocalNotificationsPlugin.show(0, title, body, not);
    }
}