import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'schermate/cancello_accesso.dart';
import 'schermate/errore_avvio.dart';
import 'servizi/accesso.dart';
import 'servizi/archivio.dart';
import 'servizi/servizi_app.dart';
import 'tema/tema_laguna.dart';

/// Radice dell'app. Nome provvisorio: QuantoValgo.
class QuantoValgoApp extends StatelessWidget {
  const QuantoValgoApp({
    super.key,
    required this.accesso,
    required this.archivio,
    this.erroreAvvio,
  });

  final ServizioAccesso accesso;
  final Archivio archivio;

  /// Se non nullo, Firebase non è partito: si mostra solo l'errore.
  final String? erroreAvvio;

  @override
  Widget build(BuildContext context) {
    return ServiziApp(
      accesso: accesso,
      archivio: archivio,
      child: MaterialApp(
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
        home: erroreAvvio != null
            ? ErroreAvvioPagina(dettagli: erroreAvvio!)
            : const CancelloAccesso(),
      ),
    );
  }
}
