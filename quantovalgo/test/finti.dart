import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:quantovalgo/app.dart';
import 'package:quantovalgo/servizi/accesso.dart';
import 'package:quantovalgo/servizi/archivio.dart';
import 'package:quantovalgo/servizi/utente.dart';

const utenteProva = Utente(
  uid: 'u1',
  nome: 'Francesco Prova',
  email: 'prova@example.com',
);

/// Accesso finto: niente Firebase, si controlla tutto dal test.
class FintoAccesso implements ServizioAccesso {
  FintoAccesso({Utente? iniziale}) : _corrente = iniziale;

  Utente? _corrente;
  final _flusso = StreamController<Utente?>.broadcast();

  /// Se valorizzato, il prossimo accesso fallisce con questo errore.
  ErroreAccesso? erroreProssimoAccesso;
  int accessiRichiesti = 0;
  int uscite = 0;

  @override
  Stream<Utente?> get utente async* {
    yield _corrente; // come Firebase: subito il valore attuale
    yield* _flusso.stream;
  }

  @override
  Utente? get utenteCorrente => _corrente;

  @override
  Future<void> accediConGoogle() async {
    accessiRichiesti++;
    final errore = erroreProssimoAccesso;
    if (errore != null) throw errore;
    _corrente = utenteProva;
    _flusso.add(_corrente);
  }

  @override
  Future<void> esci() async {
    uscite++;
    _corrente = null;
    _flusso.add(null);
  }
}

/// Archivio finto: registra i profili salvati.
class FintoArchivio implements Archivio {
  final profiliSalvati = <String>[];
  StatoSincronizzazione stato = StatoSincronizzazione.sincronizzato;

  @override
  void assicuraProfilo(Utente utente) => profiliSalvati.add(utente.uid);

  @override
  Stream<StatoSincronizzazione> statoSincronizzazione(String uid) =>
      Stream.value(stato);
}

/// Avvia l'app con servizi finti e aspetta che si assesti.
Future<({FintoAccesso accesso, FintoArchivio archivio})> avviaApp(
  WidgetTester tester, {
  Utente? utente = utenteProva,
  String? erroreAvvio,
}) async {
  final accesso = FintoAccesso(iniziale: utente);
  final archivio = FintoArchivio();
  await tester.pumpWidget(
    QuantoValgoApp(
      accesso: accesso,
      archivio: archivio,
      erroreAvvio: erroreAvvio,
    ),
  );
  await tester.pumpAndSettle();
  return (accesso: accesso, archivio: archivio);
}
