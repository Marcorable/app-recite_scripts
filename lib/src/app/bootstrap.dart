import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:maltto/firebase_options.dart';
import 'package:maltto/src/app/dependencies.dart';

typedef FirebaseInitializer = Future<void> Function();
typedef AppRunner = void Function(Widget app);

Future<void> bootstrap({
  FirebaseInitializer initializeFirebase = _initializeFirebase,
  AppRunner runApplication = runApp,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  runApplication(createApp());
}

Future<void> _initializeFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}
