import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'schermate/cancello_accesso.dart';
import 'schermate/errore_avvio.dart';
import 'servizi/accesso.dart';
import 'servizi/archivio.dart';
import 'servizi/aggiornamento_prezzi.dart';
import 'servizi/pianificatore_promemoria.dart';
import 'servizi/promemoria_servizio.dart';
import 'servizi/ricerca_prezzi.dart';
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
    this.adesso,
    this.promemoria,
    this.ricerca,
  });

  final ServizioAccesso accesso;
  final Archivio archivio;

  /// Se non nullo, Firebase non è partito: si mostra solo l'errore.
  final String? erroreAvvio;

  /// Orologio dell'app: serve solo ai test per fissare "oggi".
  final DateTime Function()? adesso;

  /// Notifiche del telefono per i promemoria (vuoto: niente notifiche).
  final ServizioPromemoria? promemoria;

  /// Ricerca dei prezzi sul web (Tavily). Vuota: niente ricerca.
  final RicercaPrezzi? ricerca;

  @override
  State<QuantoValgoApp> createState() => _QuantoValgoAppState();
}

class _QuantoValgoAppState extends State<QuantoValgoApp> {
  /// I dati dell'utente: uno solo per tutta la vita dell'app. Se Firebase non
  /// è partito non si crea, così non si tocca il database.
  late final StatoDati? _dati = widget.erroreAvvio != null
      ? null
      : StatoDati(
          accesso: widget.accesso,
          archivio: widget.archivio,
          adesso: widget.adesso,
        );

  /// Riprogramma le notifiche ogni volta che cambiano i pagamenti.
  late final PianificatorePromemoria? _pianificatore =
      _dati == null || widget.promemoria == null
      ? null
      : PianificatorePromemoria(dati: _dati, servizio: widget.promemoria!);

  /// Aggiorna ogni settimana le forbici trovate dal web (se acceso in Impostazioni).
  late final AggiornamentoPrezzi? _aggiornamentoPrezzi =
      _dati == null || widget.ricerca == null
      ? null
      : AggiornamentoPrezzi(dati: _dati, ricerca: widget.ricerca!);

  @override
  void initState() {
    super.initState();
    // Si creano subito (sono "late")
    _pianificatore;
    _aggiornamentoPrezzi;
  }

  @override
  void dispose() {
    _pianificatore?.dispose();
    _aggiornamentoPrezzi?.dispose();
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
      ricerca: widget.ricerca,
      child: _dati == null ? app : DatiScope(dati: _dati, child: app),
    );
  }
}
