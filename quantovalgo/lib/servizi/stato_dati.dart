import 'dart:async';

import 'package:flutter/widgets.dart';

import '../logica/calcoli.dart';
import '../logica/costi.dart';
import '../logica/giornate.dart';
import '../modelli/categoria.dart';
import '../modelli/cliente.dart';
import '../modelli/costo.dart';
import '../modelli/giornata.dart';
import '../modelli/lavoro.dart';
import '../modelli/prezzo_mercato.dart';
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
  static const _totaleFlussi = 7;

  /// "Adesso" dell'app (sostituibile nei test).
  final DateTime Function() adesso;

  List<Lavoro> _lavori = const [];
  List<Sottoprogetto> _sottoprogetti = const [];
  List<Cliente> _clienti = const [];
  List<PrezzoMercato> _prezzi = const [];
  List<Costo> _costi = const [];
  List<Categoria> _categorie = const [];
  List<Giornata> _giornate = const [];

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
  List<Costo> get costi => _costi;
  List<Categoria> get categorie => _categorie;
  List<Giornata> get giornate => _giornate;

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
    return riepilogo(sottoprogettiDi(lavoroId));
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
    final quote = ripartisci(importo, [
      // I lavori a giornata hanno un guadagno netto fisso: non prendono quote
      for (final l in progettiAttivi(
        _lavori.where((l) => l.tipo != TipoLavoro.aGiornata),
        mese,
      ))
        PesoProgetto(l.id, riepilogoDi(l.id).ore),
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

  /// Costi una tantum ancora da recuperare con i progetti incassati.
  DaRecuperare daRecuperareOra() {
    var utileIncassato = 0.0;
    for (final l in _lavori) {
      // Le giornate si incassano nel giorno stesso: contano quelle già fatte
      if (l.statoPagamento == StatoPagamento.incassato ||
          l.tipo == TipoLavoro.aGiornata) {
        utileIncassato += riepilogoDi(l.id).utile;
      }
    }
    return daRecuperare(costi: _costi, utileIncassato: utileIncassato);
  }

  // --- Scritture (restituiscono subito, anche offline) ---

  String salvaLavoro(Lavoro lavoro) => _archivio.salvaLavoro(lavoro);

  void eliminaLavoro(String id) => _archivio.eliminaLavoro(
    id,
    idSottoprogetti: [for (final s in sottoprogettiDi(id)) s.id],
    idGiornate: [for (final g in giornateDi(id)) g.id],
  );

  String salvaSottoprogetto(Sottoprogetto s) => _archivio.salvaSottoprogetto(s);
  void eliminaSottoprogetto(String id) => _archivio.eliminaSottoprogetto(id);

  String salvaCliente(Cliente c) => _archivio.salvaCliente(c);
  void eliminaCliente(String id) => _archivio.eliminaCliente(id);

  void salvaPrezzoMercato(PrezzoMercato p) => _archivio.salvaPrezzoMercato(p);

  String salvaCosto(Costo c) => _archivio.salvaCosto(c);
  void eliminaCosto(String id) => _archivio.eliminaCosto(id);

  String salvaCategoria(Categoria c) => _archivio.salvaCategoria(c);
  void eliminaCategoria(String id) => _archivio.eliminaCategoria(id);

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
