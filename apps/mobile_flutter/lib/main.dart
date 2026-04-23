import 'package:flutter/material.dart';

import 'app/app.dart';
import 'services/session_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SessionService.load();
  runApp(const AlitaptapApp());
}
