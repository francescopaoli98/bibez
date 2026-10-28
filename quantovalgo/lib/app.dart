import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'schermate/guscio.dart';
import 'tema/tema_laguna.dart';

/// Radice dell'app. Nome provvisorio: QuantoValgo.
class QuantoValgoApp extends StatelessWidget {
  const QuantoValgoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuantoValgo',
      debugShowCheckedModeBanner: false,
      theme: creaTemaLaguna(),
      // App solo in italiano
      locale: const Locale('it', 'IT'),
      supportedLocales: const [Locale('it', 'IT')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const Guscio(),
    );
  }
}
