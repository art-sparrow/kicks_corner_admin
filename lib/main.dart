// ignore_for_file: prefer_const_constructors, depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart'; // Import the provider package for state management and dynamic widget insertion in the add_product page
import 'package:kickscorner_admin/pages/services/test_provider.dart'; // Import the VariationProvider defined in test_provider
//import 'package:kickscorner_admin/pages/services/add_product.dart'; //Import the VariationProvider defined in the add_products screen
import 'package:kickscorner_admin/pages/onboardscreen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    // Wrap the MaterialApp with MultiProvider to handle scenarios where you have multiple providers for various screens
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VariationProvider()), // Add the provider used in the test_provider screen
        // ChangeNotifierProvider(create: (_) => VariationProvider()), // Add the provider used in the add_products screen
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      //hide the debug badge
      debugShowCheckedModeBanner: false,
      //show the onboard screen as the first page
      home: OnBoardScreen(),
    );
  }
}