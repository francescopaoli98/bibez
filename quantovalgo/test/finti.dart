import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:quantovalgo/app.dart';
import 'package:quantovalgo/modelli/categoria.dart';
import 'package:quantovalgo/modelli/cliente.dart';
import 'package:quantovalgo/modelli/costo.dart';
import 'package:quantovalgo/modelli/giornata.dart';
import 'package:quantovalgo/modelli/impostazioni.dart';
import 'package:quantovalgo/modelli/lavoro.dart';
import 'package:quantovalgo/modelli/prezzo_mercato.dart';
import 'package:quantovalgo/modelli/sessione_ore.dart';
import 'package:quantovalgo/modelli/sottoprogetto.dart';
import 'package:quantovalgo/servizi/accesso.dart';
import 'package:quantovalgo/logica/promemoria.dart';
import 'package:quantovalgo/servizi/archivio.dart';
import 'package:quantovalgo/modelli/tipi.dart';
import 'package:quantovalgo/servizi/promemoria_servizio.dart';
import 'package:quantovalgo/servizi/ricerca_prezzi.dart';
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
  final tabellaCosti = _Tabella<Costo>();
  final tabellaCategorie = _Tabella<Categoria>();
  final tabellaGiornate = _Tabella<Giornata>();
  final tabellaSessioni = _Tabella<SessioneOre>();
  var impostazioniSalvate = const Impostazioni();
  final _flussoImpostazioni = StreamController<Impostazioni>.broadcast();
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
  @override
  Stream<List<Costo>> costi() => tabellaCosti.ascolta();
  @override
  Stream<List<Categoria>> categorie() => tabellaCategorie.ascolta();
  @override
  Stream<List<Giornata>> giornate() => tabellaGiornate.ascolta();
  @override
  Stream<List<SessioneOre>> sessioni() => tabellaSessioni.ascolta();
  @override
  Stream<Impostazioni> impostazioni() async* {
    yield impostazioniSalvate;
    yield* _flussoImpostazioni.stream;
  }

  // --- Scrittura ---
  @override
  String salvaLavoro(Lavoro l) {
    final id = _nuovoId(l.id);
    tabellaLavori.metti(id, Lavoro.fromMap(id, l.toMap()));
    return id;
  }

  @override
  void eliminaLavoro(
    String id, {
    required List<String> idSottoprogetti,
    List<String> idGiornate = const [],
    List<String> idSessioni = const [],
  }) {
    tabellaLavori.togli(id);
    idSottoprogetti.forEach(tabellaSotto.togli);
    idGiornate.forEach(tabellaGiornate.togli);
    idSessioni.forEach(tabellaSessioni.togli);
  }

  @override
  String salvaSottoprogetto(Sottoprogetto s) {
    final id = _nuovoId(s.id);
    tabellaSotto.metti(id, Sottoprogetto.fromMap(id, s.toMap()));
    return id;
  }

  @override
  void eliminaSottoprogetto(String id, {List<String> idSessioni = const []}) {
    tabellaSotto.togli(id);
    idSessioni.forEach(tabellaSessioni.togli);
  }

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

  @override
  String salvaCosto(Costo c) {
    final id = _nuovoId(c.id);
    tabellaCosti.metti(id, Costo.fromMap(id, c.toMap()));
    return id;
  }

  @override
  void eliminaCosto(String id) => tabellaCosti.togli(id);

  @override
  String salvaCategoria(Categoria c) {
    final id = _nuovoId(c.id);
    tabellaCategorie.metti(id, Categoria.fromMap(id, c.toMap()));
    return id;
  }

  @override
  void eliminaCategoria(String id) => tabellaCategorie.togli(id);

  @override
  void salvaImpostazioni(Impostazioni i) {
    impostazioniSalvate = i;
    _flussoImpostazioni.add(i);
  }

  @override
  String salvaSessione(SessioneOre s) {
    final id = _nuovoId(s.id);
    tabellaSessioni.metti(id, SessioneOre.fromMap(id, s.toMap()));
    return id;
  }

  @override
  void eliminaSessione(String id) => tabellaSessioni.togli(id);

  @override
  String salvaGiornata(Giornata g) {
    final id = _nuovoId(g.id);
    tabellaGiornate.metti(id, Giornata.fromMap(id, g.toMap()));
    return id;
  }

  @override
  void salvaGiornate(List<Giornata> giornate) =>
      giornate.forEach(salvaGiornata);

  @override
  void eliminaGiornata(String id) => tabellaGiornate.togli(id);
}

/// Notifiche finte: ricordano solo l'ultima programmazione.
class FintoPromemoria implements ServizioPromemoria {
  List<Promemoria> programmati = const [];
  int programmazioni = 0;
  int permessiChiesti = 0;
  bool permessoConcesso = true;

  @override
  Future<bool> chiediPermesso() async {
    permessiChiesti++;
    return permessoConcesso;
  }

  @override
  Future<void> programma(List<Promemoria> promemoria) async {
    programmazioni++;
    programmati = promemoria;
  }
}

/// Ricerca prezzi finta: risponde quello che le dici e ricorda le richieste.
class FintaRicerca implements RicercaPrezzi {
  FintaRicerca(this.esito);

  RisultatoRicerca esito;
  final richieste = <({TipoLavoro tipo, String chiave, String? domanda})>[];

  @override
  Future<RisultatoRicerca> cerca(
    TipoLavoro tipo, {
    required String chiave,
    String? domanda,
  }) async {
    richieste.add((tipo: tipo, chiave: chiave, domanda: domanda));
    return esito;
  }
}

/// Avvia l'app con servizi finti e aspetta che si assesti.
Future<({FintoAccesso accesso, FintoArchivio archivio})> avviaApp(
  WidgetTester tester, {
  Utente? utente = utenteProva,
  String? erroreAvvio,
  FintoArchivio? archivio,
  DateTime Function()? adesso,
  ServizioPromemoria? promemoria,
  RicercaPrezzi? ricerca,
}) async {
  final accesso = FintoAccesso(iniziale: utente);
  final archivioUsato = archivio ?? FintoArchivio();
  await tester.pumpWidget(
    QuantoValgoApp(
      accesso: accesso,
      archivio: archivioUsato,
      erroreAvvio: erroreAvvio,
      adesso: adesso,
      promemoria: promemoria,
      ricerca: ricerca,
    ),
  );
  await tester.pumpAndSettle();
  return (accesso: accesso, archivio: archivioUsato);
}
