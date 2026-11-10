import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:maltto/firebase_options.dart';
import 'package:maltto/src/app/dependencies.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(createApp());
}
