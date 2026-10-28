import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'schermate/cancello_accesso.dart';
import 'schermate/errore_avvio.dart';
import 'servizi/accesso.dart';
import 'servizi/archivio.dart';
import 'servizi/servizi_app.dart';
import 'servizi/stato_dati.dart';
import 'tema/tema_laguna.dart';

/// Radice dell'app. Nome provvisorio: QuantoValgo.
class QuantoValgoApp extends StatefulWidget {
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
  State<QuantoValgoApp> createState() => _QuantoValgoAppState();
}

class _QuantoValgoAppState extends State<QuantoValgoApp> {
  /// I dati dell'utente: uno solo per tutta la vita dell'app. Se Firebase non
  /// è partito non si crea, così non si tocca il database.
  late final StatoDati? _dati = widget.erroreAvvio != null
      ? null
      : StatoDati(accesso: widget.accesso, archivio: widget.archivio);

  @override
  void dispose() {
    _dati?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp(
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
      home: widget.erroreAvvio != null
          ? ErroreAvvioPagina(dettagli: widget.erroreAvvio!)
          : const CancelloAccesso(),
    );

    return ServiziApp(
      accesso: widget.accesso,
      archivio: widget.archivio,
      child: _dati == null ? app : DatiScope(dati: _dati, child: app),
    );
  }
}
