import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:maltto/firebase_options.dart';
import 'package:maltto/src/app/dependencies.dart';
import 'package:maltto/src/infrastructure/app_check/firebase_app_check_service.dart';
import 'package:maltto/src/infrastructure/telemetry/firebase_telemetry.dart';

typedef FirebaseInitializer = Future<void> Function();
typedef AppCheckInitializer = Future<void> Function();
typedef TelemetryInitializer = Future<void> Function();
typedef AppRunner = void Function(Widget app);

Future<void> bootstrap({
  FirebaseInitializer initializeFirebase = _initializeFirebase,
  AppCheckInitializer initializeAppCheck = initializeFirebaseAppCheck,
  TelemetryInitializer initializeTelemetry = initializeFirebaseTelemetry,
  AppRunner runApplication = runApp,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  await initializeAppCheck();
  await initializeTelemetry();
  runApplication(createApp());
}

Future<void> _initializeFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}
