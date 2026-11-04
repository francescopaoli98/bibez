import 'tipi.dart';

/// Come si presenta il foglio del preventivo. Le chiavi (`name`) finiscono nel
/// database: non rinominarle.
enum StilePreventivo {
  /// Tema Laguna: turchese e lucido.
  app('App'),

  /// Foglio bianco, carattere con le grazie, blu navy.
  professionale('Professionale'),

  /// Sfondo scuro, carattere da terminale, verde.
  informatico('Informatico'),

  /// Viola scuro con bordi neon.
  gaming('Gaming');

  const StilePreventivo(this.etichetta);
  final String etichetta;

  static StilePreventivo da(Object? chiave) => values.firstWhere(
    (s) => s.name == chiave,
    orElse: () => StilePreventivo.app,
  );
}

/// Un preventivo da mandare a un cliente. Salvato in
/// `utenti/{uid}/preventivi/{id}` quando lo salvi come immagine o lo condividi.
///
/// Nome del cliente e prezzi sono "fotografati" al momento: il preventivo
/// resta quello che hai mandato anche se poi cambi il lavoro.
class Preventivo {
  const Preventivo({
    required this.id,
    required this.lavoroId,
    required this.progetto,
    required this.fasi,
    required this.consegna,
    required this.benefit,
    required this.stile,
    required this.prezzoPieno,
    required this.prezzoFinale,
    required this.creatoIl,
    this.cliente,
  });

  final String id;
  final String lavoroId;

  /// Per chi (nome del cliente, se c'era).
  final String? cliente;

  /// Cosa fai, in poche parole.
  final String progetto;

  /// Come lavori: le fasi, una per riga.
  final List<String> fasi;

  /// Entro quando consegni (`1 settimana`, `2 settimane`...).
  final String consegna;

  /// Cosa ci guadagna il cliente, una voce per riga.
  final List<String> benefit;
  final StilePreventivo stile;

  /// Prezzo senza sconto e prezzo che chiedi davvero.
  final double prezzoPieno;
  final double prezzoFinale;
  final DateTime creatoIl;

  Preventivo copyWith({
    String? id,
    StilePreventivo? stile,
    String? progetto,
    List<String>? fasi,
    String? consegna,
    List<String>? benefit,
  }) => Preventivo(
    id: id ?? this.id,
    lavoroId: lavoroId,
    cliente: cliente,
    progetto: progetto ?? this.progetto,
    fasi: fasi ?? this.fasi,
    consegna: consegna ?? this.consegna,
    benefit: benefit ?? this.benefit,
    stile: stile ?? this.stile,
    prezzoPieno: prezzoPieno,
    prezzoFinale: prezzoFinale,
    creatoIl: creatoIl,
  );

  Map<String, Object?> toMap() => {
    'lavoroId': lavoroId,
    'cliente': cliente,
    'progetto': progetto,
    'fasi': fasi,
    'consegna': consegna,
    'benefit': benefit,
    'stile': stile.name,
    'prezzoPieno': prezzoPieno,
    'prezzoFinale': prezzoFinale,
    'creatoIl': creatoIl,
  };

  factory Preventivo.fromMap(String id, Map<String, Object?> dati) {
    List<String> elenco(Object? v) =>
        ((v as List?) ?? const []).whereType<String>().toList();
    return Preventivo(
      id: id,
      lavoroId: dati['lavoroId'] as String? ?? '',
      cliente: dati['cliente'] as String?,
      progetto: dati['progetto'] as String? ?? '',
      fasi: elenco(dati['fasi']),
      consegna: dati['consegna'] as String? ?? '',
      benefit: elenco(dati['benefit']),
      stile: StilePreventivo.da(dati['stile']),
      prezzoPieno: leggiDouble(dati['prezzoPieno']),
      prezzoFinale: leggiDouble(dati['prezzoFinale']),
      creatoIl:
          leggiData(dati['creatoIl']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
