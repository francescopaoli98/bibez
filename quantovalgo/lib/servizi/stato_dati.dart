import 'dart:async';

import 'package:flutter/widgets.dart';

import '../logica/calcoli.dart';
import '../logica/costi.dart';
import '../logica/costi.dart' as logica_costi;
import '../logica/giornate.dart';
import '../logica/ore.dart';
import '../logica/pagamenti.dart';
import '../logica/promemoria.dart';
import '../modelli/categoria.dart';
import '../modelli/cliente.dart';
import '../modelli/costo.dart';
import '../modelli/giornata.dart';
import '../modelli/impostazioni.dart';
import '../modelli/lavoro.dart';
import '../modelli/prezzo_mercato.dart';
import '../modelli/sessione_ore.dart';
import '../modelli/sottoprogetto.dart';
import '../modelli/tipi.dart';
import 'accesso.dart';
import 'archivio.dart';
import 'utente.dart';

/// Tiene in memoria i dati dell'utente connesso (lavori, sottoprogetti,
/// clienti, prezzi) e avvisa le schermate quando cambiano.
///
/// Si ascolta il cloud UNA volta sola per tutta l'app: le schermate leggono
/// da qui, quindi aprirne una nuova non costa letture in più. Quando
/// l'utente esce (o cambia) la memoria si svuota e si riparte.
class StatoDati extends ChangeNotifier {
  StatoDati({
    required ServizioAccesso accesso,
    required this._archivio,
    DateTime Function()? adesso,
  }) : adesso = adesso ?? DateTime.now {
    _ascoltoUtente = accesso.utente.listen(_cambioUtente);
  }

  final Archivio _archivio;
  late final StreamSubscription<Utente?> _ascoltoUtente;
  final List<StreamSubscription<Object?>> _ascolti = [];
  final Set<String> _arrivati = {};
  static const _totaleFlussi = 9;

  /// "Adesso" dell'app (sostituibile nei test).
  final DateTime Function() adesso;

  List<Lavoro> _lavori = const [];
  List<Sottoprogetto> _sottoprogetti = const [];
  List<Cliente> _clienti = const [];
  List<PrezzoMercato> _prezzi = const [];
  List<Costo> _costi = const [];
  List<Categoria> _categorie = const [];
  List<Giornata> _giornate = const [];
  List<SessioneOre> _sessioni = const [];
  Impostazioni _impostazioni = const Impostazioni();

  /// Valori di calcolo (sconti, fattori di competenza). Dal passo 8 si
  /// potranno cambiare da Impostazioni.
  ParametriPrezzo parametri = ParametriPrezzo.predefiniti;

  /// Vero se il cloud ha rifiutato un flusso (regole o database).
  bool problema = false;

  /// Vero dopo la prima risposta di tutti i flussi (anche dalla cache).
  bool get caricato => _arrivati.length == _totaleFlussi;

  /// Dal più recente al più vecchio.
  List<Lavoro> get lavori => _lavori;
  List<Cliente> get clienti => _clienti;
  List<Sottoprogetto> get sottoprogetti => _sottoprogetti;
  List<Costo> get costi => _costi;
  List<Categoria> get categorie => _categorie;
  List<Giornata> get giornate => _giornate;
  List<SessioneOre> get sessioni => _sessioni;
  Impostazioni get impostazioni => _impostazioni;

  // --- Ascolto ---

  void _cambioUtente(Utente? utente) {
    _fermaAscolti();
    _lavori = const [];
    _sottoprogetti = const [];
    _clienti = const [];
    _prezzi = const [];
    _costi = const [];
    _categorie = const [];
    _giornate = const [];
    _sessioni = const [];
    _impostazioni = const Impostazioni();
    _arrivati.clear();
    problema = false;

    if (utente != null) {
      _ascolta<Lavoro>('lavori', _archivio.lavori(), (v) {
        _lavori = [...v]..sort((a, b) => b.creatoIl.compareTo(a.creatoIl));
      });
      _ascolta<Sottoprogetto>('sottoprogetti', _archivio.sottoprogetti(), (v) {
        _sottoprogetti = [...v]
          ..sort((a, b) => a.creatoIl.compareTo(b.creatoIl));
      });
      _ascolta<Cliente>('clienti', _archivio.clienti(), (v) {
        _clienti = [
          ...v,
        ]..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
      });
      _ascolta<PrezzoMercato>('prezzi', _archivio.prezziMercato(), (v) {
        _prezzi = v;
      });
      _ascolta<Costo>('costi', _archivio.costi(), (v) {
        _costi = [
          ...v,
        ]..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
      });
      _ascolta<Categoria>('categorie', _archivio.categorie(), (v) {
        _categorie = [...v]..sort((a, b) => a.creatoIl.compareTo(b.creatoIl));
      });
      _ascolta<Giornata>('giornate', _archivio.giornate(), (v) {
        _giornate = [...v]..sort((a, b) => a.data.compareTo(b.data));
      });
      _ascolta<SessioneOre>('sessioni', _archivio.sessioni(), (v) {
        _sessioni = [...v]..sort((a, b) => b.inizio.compareTo(a.inizio));
      });
      _ascolta<Impostazioni>(
        'impostazioni',
        _archivio.impostazioni().map((i) => [i]),
        (v) => _impostazioni = v.single,
      );
    }
    notifyListeners();
  }

  void _ascolta<T>(
    String nome,
    Stream<List<T>> flusso,
    void Function(List<T>) salva,
  ) {
    _ascolti.add(
      flusso.listen(
        (valori) {
          salva(valori);
          _arrivati.add(nome);
          notifyListeners();
        },
        onError: (Object errore) {
          debugPrint('Flusso "$nome" in errore: $errore');
          problema = true;
          _arrivati.add(nome); // non restare in attesa per sempre
          notifyListeners();
        },
      ),
    );
  }

  void _fermaAscolti() {
    for (final a in _ascolti) {
      a.cancel();
    }
    _ascolti.clear();
  }

  @override
  void dispose() {
    _ascoltoUtente.cancel();
    _fermaAscolti();
    super.dispose();
  }

  // --- Letture comode ---

  Lavoro? lavoro(String id) => _lavori.where((l) => l.id == id).firstOrNull;

  Cliente? cliente(String? id) =>
      id == null ? null : _clienti.where((c) => c.id == id).firstOrNull;

  /// Cerca un cliente per nome, senza badare a maiuscole e spazi ai bordi.
  Cliente? clientePerNome(String nome) {
    final cercato = nome.trim().toLowerCase();
    if (cercato.isEmpty) return null;
    return _clienti
        .where((c) => c.nome.trim().toLowerCase() == cercato)
        .firstOrNull;
  }

  Sottoprogetto? sottoprogetto(String id) =>
      _sottoprogetti.where((s) => s.id == id).firstOrNull;

  List<Sottoprogetto> sottoprogettiDi(String lavoroId) =>
      _sottoprogetti.where((s) => s.lavoroId == lavoroId).toList();

  /// Numeri di un progetto. Per un lavoro "A giornata" l'utile è la somma delle
  /// giornate già fatte (dal loro giorno in poi): niente costi né ore.
  RiepilogoLavoro riepilogoDi(String lavoroId) {
    if (lavoro(lavoroId)?.tipo == TipoLavoro.aGiornata) {
      return RiepilogoLavoro(
        ricavi: totaleGiornate(giornateFatte(lavoroId)),
        costi: 0,
        ore: 0,
      );
    }
    // Ricavi e costi dai sottoprogetti; le ore sono quelle iniziali scritte a
    // mano più quelle registrate (cronometro e inserimento a mano).
    final dalleParti = riepilogo(sottoprogettiDi(lavoroId));
    return RiepilogoLavoro(
      ricavi: dalleParti.ricavi,
      costi: dalleParti.costi,
      ore:
          dalleParti.ore +
          oreDaMinuti(minutiConclusi(sessioniDelLavoro(lavoroId))),
    );
  }

  // --- Pagamenti ---

  /// Quanto aspettarsi da un progetto (ricavi dei sottoprogetti o prezzo finale).
  double importoDi(Lavoro lavoro) =>
      importoDaIncassare(riepilogoDi(lavoro.id).ricavi, lavoro.prezzoFinale);

  /// Progetti ancora da incassare: prima i più in ritardo, poi per scadenza,
  /// in fondo quelli senza scadenza.
  List<Lavoro> get lavoriDaIncassare {
    final ora = adesso();
    final elenco = [
      for (final l in _lavori)
        if (daIncassare(l)) l,
    ];
    elenco.sort((a, b) {
      final ritardoA = giorniRitardo(a, ora);
      final ritardoB = giorniRitardo(b, ora);
      if (ritardoA != ritardoB) return ritardoB.compareTo(ritardoA);
      final sa = a.scadenza;
      final sb = b.scadenza;
      if (sa != null && sb != null) return sa.compareTo(sb);
      if (sa != null) return -1; // chi ha una scadenza viene prima
      if (sb != null) return 1;
      return a.creatoIl.compareTo(b.creatoIl);
    });
    return elenco;
  }

  double get totaleDaIncassare =>
      lavoriDaIncassare.fold<double>(0, (somma, l) => somma + importoDi(l));

  int get numeroInRitardo {
    final ora = adesso();
    return lavoriDaIncassare.where((l) => inRitardo(l, ora)).length;
  }

  /// Segna il progetto come incassato nel giorno [giorno] (di solito oggi).
  void segnaIncassato(Lavoro lavoro, DateTime giorno) => _archivio.salvaLavoro(
    lavoro.copyWith(
      statoPagamento: StatoPagamento.incassato,
      dataIncasso: () => soloData(giorno),
    ),
  );

  /// Torna a "da incassare" (se hai segnato per sbaglio).
  void riapriPagamento(Lavoro lavoro) => _archivio.salvaLavoro(
    lavoro.copyWith(
      statoPagamento: StatoPagamento.daIncassare,
      dataIncasso: () => null,
    ),
  );

  /// Cambia la scadenza (null = nessuna scadenza).
  void impostaScadenza(Lavoro lavoro, DateTime? scadenza) =>
      _archivio.salvaLavoro(
        lavoro.copyWith(
          scadenza: () => scadenza == null ? null : soloData(scadenza),
        ),
      );

  /// Cambia il giorno in cui hai chiesto il pagamento (null = giorno di creazione).
  void impostaRichiesta(Lavoro lavoro, DateTime? giorno) =>
      _archivio.salvaLavoro(
        lavoro.copyWith(
          richiestoIl: () => giorno == null ? null : soloData(giorno),
        ),
      );

  /// Come pagano i clienti (una riga per cliente).
  List<StatisticheCliente> statisticheDeiClienti() => statisticheClienti(
    clienti: _clienti,
    lavori: _lavori,
    importo: importoDi,
    adesso: adesso(),
  );

  /// Giorni medi che i clienti impiegano a pagare (vuoto se nessun incasso).
  double? get giorniMediPerPagare =>
      mediaGiorniPerPagare(_lavori.where(haPagamento));

  /// Le notifiche da programmare (nessuna se i promemoria sono spenti).
  List<Promemoria> promemoriaDaProgrammare() {
    if (!_impostazioni.promemoria) return const [];
    return promemoriaPagamenti(
      lavori: _lavori,
      importo: importoDi,
      cliente: (l) => cliente(l.clienteId)?.nome ?? '',
      adesso: adesso(),
    );
  }

  // --- Ore ---

  List<SessioneOre> sessioniDi(String sottoprogettoId) =>
      _sessioni.where((s) => s.sottoprogettoId == sottoprogettoId).toList();

  List<SessioneOre> sessioniDelLavoro(String lavoroId) =>
      _sessioni.where((s) => s.lavoroId == lavoroId).toList();

  /// Il cronometro acceso (uno solo alla volta), se c'è.
  SessioneOre? get sessioneInCorso =>
      _sessioni.where((s) => s.inCorso).firstOrNull;

  /// Minuti registrati su un sottoprogetto (cronometro e inserimento a mano).
  int minutiRegistrati(String sottoprogettoId) =>
      minutiConclusi(sessioniDi(sottoprogettoId));

  /// Ore di un sottoprogetto: quelle iniziali scritte a mano più le registrate.
  double oreDelSottoprogetto(Sottoprogetto s) =>
      s.ore + oreDaMinuti(minutiRegistrati(s.id));

  /// Accende il cronometro su un sottoprogetto. Se ce n'era già uno acceso lo
  /// ferma prima e lo restituisce, così la schermata può dirlo.
  ({SessioneOre sessione, bool salvata})? avviaCronometro(Sottoprogetto s) {
    final precedente = sessioneInCorso;
    final fermata = precedente == null ? null : _concludi(precedente);
    _archivio.salvaSessione(
      SessioneOre(
        id: '',
        sottoprogettoId: s.id,
        lavoroId: s.lavoroId,
        inizio: adesso(),
        creatoIl: adesso(),
      ),
    );
    return fermata;
  }

  /// Ferma il cronometro acceso. Sotto il minuto non si salva (e `salvata`
  /// è falso). Senza cronometro acceso restituisce null.
  ({SessioneOre sessione, bool salvata})? fermaCronometro() {
    final acceso = sessioneInCorso;
    return acceso == null ? null : _concludi(acceso);
  }

  ({SessioneOre sessione, bool salvata}) _concludi(SessioneOre acceso) {
    final fine = adesso();
    final minuti = minutiTra(acceso.inizio, fine);
    if (sessioneTroppoBreve(minuti)) {
      _archivio.eliminaSessione(acceso.id);
      return (sessione: acceso, salvata: false);
    }
    final conclusa = acceso.copyWith(fine: fine, minuti: minuti);
    _archivio.salvaSessione(conclusa);
    return (sessione: conclusa, salvata: true);
  }

  /// Tutte le giornate di un lavoro, dalla più vecchia.
  List<Giornata> giornateDi(String lavoroId) =>
      _giornate.where((g) => g.lavoroId == lavoroId).toList();

  /// Giornate già arrivate (oggi compreso): il guadagno è incassato.
  List<Giornata> giornateFatte(String lavoroId) => [
    for (final g in giornateDi(lavoroId))
      if (giornataFatta(g, adesso())) g,
  ];

  /// Giornate in programma (dopo oggi).
  List<Giornata> giornateInProgramma(String lavoroId) => [
    for (final g in giornateDi(lavoroId))
      if (!giornataFatta(g, adesso())) g,
  ];

  List<Lavoro> lavoriDelCliente(String clienteId) =>
      _lavori.where((l) => l.clienteId == clienteId).toList();

  /// Forbice di mercato salvata per quel tipo (null se non c'è ancora).
  PrezzoMercato? mercatoPer(TipoLavoro tipo) =>
      _prezzi.where((p) => p.tipo == tipo).firstOrNull;

  Categoria? categoria(String? id) =>
      id == null ? null : _categorie.where((c) => c.id == id).firstOrNull;

  /// Quanti costi usano una categoria.
  int costiDellaCategoria(String categoriaId) =>
      _costi.where((c) => c.categoriaId == categoriaId).length;

  /// Totale dei costi di un mese.
  double costiDelMese(DateTime mese) => totaleCostiDelMese(_costi, mese);

  /// Come si divide un costo tra i progetti attivi del mese:
  /// in proporzione alle ore lavorate (parti uguali se nessuno ha ore).
  /// Vuoto per i costi fissi o se non c'è nessun progetto attivo.
  List<Quota> quoteDelCosto(Costo costo, DateTime mese) {
    if (!costo.siDivideTraProgetti) return const [];
    final importo = quotaNelMese(costo, mese);
    if (importo <= 0) return const [];
    // Un costo con categoria lo dividono solo i progetti della stessa
    // categoria. Un costo senza categoria lo dividono tutti i progetti, tranne
    // i lavori "A giornata" (guadagno netto fisso, senza costi generali).
    final categoriaDelCosto = categoria(costo.categoriaId);
    final attivi = progettiAttivi(
      _lavori.where(
        (l) => categoriaDelCosto == null
            ? l.tipo != TipoLavoro.aGiornata
            : categoriaDelLavoro(l)?.id == categoriaDelCosto.id,
      ),
      mese,
    ).toList();

    // Peso = ore registrate in quel mese. Se nel mese non ce ne sono, si
    // guardano le ore totali del progetto (anche quelle iniziali); se non ce
    // ne sono nemmeno quelle, si divide in parti uguali.
    final oreDelMese = {
      for (final l in attivi)
        l.id: oreDaMinuti(minutiDelMese(sessioniDelLavoro(l.id), mese)),
    };
    final usaOreDelMese = oreDelMese.values.any((o) => o > 0);
    final quote = ripartisci(importo, [
      for (final l in attivi)
        PesoProgetto(
          l.id,
          usaOreDelMese ? oreDelMese[l.id]! : riepilogoDi(l.id).ore,
        ),
    ]);
    // Dalla quota più grande alla più piccola (a parità, resta l'ordine dei progetti)
    return [...quote]..sort((a, b) => b.importo.compareTo(a.importo));
  }

  /// Quanto dei costi condivisi del mese tocca a un progetto.
  double quotaCostiDelLavoro(String lavoroId, DateTime mese) {
    var somma = 0.0;
    for (final costo in _costi) {
      for (final q in quoteDelCosto(costo, mese)) {
        if (q.lavoroId == lavoroId) somma += q.importo;
      }
    }
    return somma;
  }

  /// Colore del progetto nelle barre (stabile: segue l'ordine di creazione).
  int indiceColoreProgetto(String lavoroId) {
    final ordinati = [..._lavori]
      ..sort((a, b) => a.creatoIl.compareTo(b.creatoIl));
    final posizione = ordinati.indexWhere((l) => l.id == lavoroId);
    return posizione < 0 ? 0 : posizione;
  }

  /// Categoria di un progetto: quella scelta, oppure (per i progetti senza
  /// scelta) la prima categoria che nel suo modulo ha "I progetti di tipo X ne
  /// fanno parte". Vuota se non ce n'è nessuna.
  Categoria? categoriaDelLavoro(Lavoro lavoro) {
    // Id vuoto = hai scelto "Nessuna": niente categoria, nemmeno quella del tipo
    if (lavoro.categoriaId == '') return null;
    return categoria(lavoro.categoriaId) ?? categoriaPredefinita(lavoro.tipo);
  }

  /// La categoria che ha "I progetti di tipo X ne fanno parte da soli".
  Categoria? categoriaPredefinita(TipoLavoro tipo) =>
      _categorie.where((c) => c.tipoLavoro == tipo).firstOrNull;

  /// Quanti progetti hanno una categoria.
  int lavoriDellaCategoria(String categoriaId) =>
      _lavori.where((l) => categoriaDelLavoro(l)?.id == categoriaId).length;

  /// "Da recuperare" una riga per categoria, più gli altri costi: ogni riga si
  /// copre con l'utile dei progetti incassati della stessa categoria.
  List<GruppoRecupero> gruppiDaRecuperare() {
    final utilePerCategoria = <String?, double>{};
    for (final l in _lavori) {
      // Le giornate si incassano nel giorno stesso: contano quelle già fatte
      if (l.statoPagamento == StatoPagamento.incassato ||
          l.tipo == TipoLavoro.aGiornata) {
        final id = categoriaDelLavoro(l)?.id;
        utilePerCategoria[id] =
            (utilePerCategoria[id] ?? 0) + riepilogoDi(l.id).utile;
      }
    }
    return logica_costi.gruppiDaRecuperare(
      costi: _costi,
      // Un costo con una categoria cancellata conta come senza categoria
      categoriaDelCosto: (c) => categoria(c.categoriaId)?.id,
      utileIncassato: utilePerCategoria,
      ordine: [for (final c in _categorie) c.id],
      mese: adesso(),
    );
  }

  // --- Scritture (restituiscono subito, anche offline) ---

  String salvaLavoro(Lavoro lavoro) => _archivio.salvaLavoro(lavoro);

  void eliminaLavoro(String id) => _archivio.eliminaLavoro(
    id,
    idSottoprogetti: [for (final s in sottoprogettiDi(id)) s.id],
    idGiornate: [for (final g in giornateDi(id)) g.id],
    idSessioni: [for (final s in sessioniDelLavoro(id)) s.id],
  );

  String salvaSottoprogetto(Sottoprogetto s) => _archivio.salvaSottoprogetto(s);
  void eliminaSottoprogetto(String id) => _archivio.eliminaSottoprogetto(
    id,
    idSessioni: [for (final s in sessioniDi(id)) s.id],
  );

  String salvaCliente(Cliente c) => _archivio.salvaCliente(c);
  void eliminaCliente(String id) => _archivio.eliminaCliente(id);

  void salvaPrezzoMercato(PrezzoMercato p) => _archivio.salvaPrezzoMercato(p);

  String salvaCosto(Costo c) => _archivio.salvaCosto(c);
  void eliminaCosto(String id) => _archivio.eliminaCosto(id);

  String salvaCategoria(Categoria c) => _archivio.salvaCategoria(c);
  void eliminaCategoria(String id) => _archivio.eliminaCategoria(id);

  void salvaImpostazioni(Impostazioni i) => _archivio.salvaImpostazioni(i);

  String salvaSessione(SessioneOre s) => _archivio.salvaSessione(s);
  void eliminaSessione(String id) => _archivio.eliminaSessione(id);

  String salvaGiornata(Giornata g) => _archivio.salvaGiornata(g);
  void salvaGiornate(List<Giornata> giornate) =>
      _archivio.salvaGiornate(giornate);
  void eliminaGiornata(String id) => _archivio.eliminaGiornata(id);
}

/// Rende [StatoDati] disponibile a tutte le schermate. Sta sopra il
/// Navigator, quindi lo vedono anche le pagine aperte con `push`.
class DatiScope extends InheritedNotifier<StatoDati> {
  const DatiScope({super.key, required StatoDati dati, required super.child})
    : super(notifier: dati);

  /// Per `build`: la schermata si ridisegna quando i dati cambiano.
  static StatoDati di(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<DatiScope>();
    assert(scope != null, 'DatiScope non trovato sopra questo widget');
    return scope!.notifier!;
  }

  /// Per i gestori di tocco: legge i dati senza iscriversi ai cambi.
  static StatoDati leggi(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<DatiScope>();
    assert(scope != null, 'DatiScope non trovato sopra questo widget');
    return scope!.notifier!;
  }
}
