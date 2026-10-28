import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:quantovalgo/app.dart';
import 'package:quantovalgo/modelli/cliente.dart';
import 'package:quantovalgo/modelli/lavoro.dart';
import 'package:quantovalgo/modelli/prezzo_mercato.dart';
import 'package:quantovalgo/modelli/sottoprogetto.dart';
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

/// Una "raccolta" in memoria che si comporta come Firestore: chi ascolta
/// riceve subito l'elenco attuale e poi ogni modifica.
class _Tabella<T> {
  final _righe = <String, T>{};
  final _flusso = StreamController<List<T>>.broadcast();

  List<T> get elenco => _righe.values.toList();

  Stream<List<T>> ascolta() async* {
    yield elenco;
    yield* _flusso.stream;
  }

  void metti(String id, T valore) {
    _righe[id] = valore;
    _flusso.add(elenco);
  }

  void togli(String id) {
    _righe.remove(id);
    _flusso.add(elenco);
  }
}

/// Archivio finto in memoria: registra i profili salvati e tiene i dati.
class FintoArchivio implements Archivio {
  final profiliSalvati = <String>[];
  StatoSincronizzazione stato = StatoSincronizzazione.sincronizzato;

  final tabellaLavori = _Tabella<Lavoro>();
  final tabellaSotto = _Tabella<Sottoprogetto>();
  final tabellaClienti = _Tabella<Cliente>();
  final tabellaPrezzi = _Tabella<PrezzoMercato>();
  int _contatore = 0;

  String _nuovoId(String id) => id.isEmpty ? 'id${++_contatore}' : id;

  // --- Profilo ---
  @override
  void assicuraProfilo(Utente utente) => profiliSalvati.add(utente.uid);

  @override
  Stream<StatoSincronizzazione> statoSincronizzazione(String uid) =>
      Stream.value(stato);

  // --- Lettura ---
  @override
  Stream<List<Lavoro>> lavori() => tabellaLavori.ascolta();
  @override
  Stream<List<Sottoprogetto>> sottoprogetti() => tabellaSotto.ascolta();
  @override
  Stream<List<Cliente>> clienti() => tabellaClienti.ascolta();
  @override
  Stream<List<PrezzoMercato>> prezziMercato() => tabellaPrezzi.ascolta();

  // --- Scrittura ---
  @override
  String salvaLavoro(Lavoro l) {
    final id = _nuovoId(l.id);
    tabellaLavori.metti(id, Lavoro.fromMap(id, l.toMap()));
    return id;
  }

  @override
  void eliminaLavoro(String id, {required List<String> idSottoprogetti}) {
    tabellaLavori.togli(id);
    idSottoprogetti.forEach(tabellaSotto.togli);
  }

  @override
  String salvaSottoprogetto(Sottoprogetto s) {
    final id = _nuovoId(s.id);
    tabellaSotto.metti(id, Sottoprogetto.fromMap(id, s.toMap()));
    return id;
  }

  @override
  void eliminaSottoprogetto(String id) => tabellaSotto.togli(id);

  @override
  String salvaCliente(Cliente c) {
    final id = _nuovoId(c.id);
    tabellaClienti.metti(id, Cliente.fromMap(id, c.toMap()));
    return id;
  }

  @override
  void eliminaCliente(String id) => tabellaClienti.togli(id);

  @override
  void salvaPrezzoMercato(PrezzoMercato p) =>
      tabellaPrezzi.metti(p.id, PrezzoMercato.fromMap(p.id, p.toMap()));
}

/// Avvia l'app con servizi finti e aspetta che si assesti.
Future<({FintoAccesso accesso, FintoArchivio archivio})> avviaApp(
  WidgetTester tester, {
  Utente? utente = utenteProva,
  String? erroreAvvio,
  FintoArchivio? archivio,
}) async {
  final accesso = FintoAccesso(iniziale: utente);
  final archivioUsato = archivio ?? FintoArchivio();
  await tester.pumpWidget(
    QuantoValgoApp(
      accesso: accesso,
      archivio: archivioUsato,
      erroreAvvio: erroreAvvio,
    ),
  );
  await tester.pumpAndSettle();
  return (accesso: accesso, archivio: archivioUsato);
}
