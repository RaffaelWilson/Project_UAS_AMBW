import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAwc9ez7Ct40cWbk34987p9vLgMDkrz0wA",
        authDomain: "project-uas-ambw.firebaseapp.com",
        projectId: "project-uas-ambw",
        storageBucket: "project-uas-ambw.firebasestorage.app",
        messagingSenderId: "775707019446",
        appId: "1:775707019446:web:2273940db76411037e3e17",
      ),
    );

    await _messaging.requestPermission();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Pesan masuk: ${message.notification?.title}');
    });
  }

  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  static Future<void> sendNotification(String token, String title, String body) async {
    // This would typically be done from a server
    // For demo purposes, we'll just print the notification
    print('Sending notification to $token: $title - $body');
  }
}