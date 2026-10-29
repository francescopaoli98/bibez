import 'tipi.dart';

/// Un lavoro (progetto). Salvato in `utenti/{uid}/lavori/{id}`.
class Lavoro {
  const Lavoro({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.relazione,
    required this.livello,
    required this.prezzoPieno,
    required this.prezzoFinale,
    required this.creatoIl,
    this.clienteId,
    this.categoriaId,
    this.tariffaGiornaliera,
    this.statoPagamento = StatoPagamento.daIncassare,
    this.scadenza,
    this.dataIncasso,
    this.richiestoIl,
    this.domandaRicerca,
  });

  final String id;
  final String nome;
  final TipoLavoro tipo;

  /// Cliente (può mancare). La relazione è quella di questo lavoro.
  final String? clienteId;
  final Relazione relazione;

  /// Categoria del progetto (la stessa lista dei costi): i costi di una
  /// categoria si recuperano solo con i progetti della stessa categoria.
  /// Vuota (null) = non scelta: segue il tipo di lavoro, se una categoria ha
  /// "I progetti di tipo X ne fanno parte". Testo vuoto ('') = hai scelto
  /// "Nessuna" di proposito.
  final String? categoriaId;

  /// Livello di competenza per questo lavoro, da 1 a 5.
  final int livello;

  /// Prezzo di listino e prezzo realmente concordato (dopo lo sconto).
  final double prezzoPieno;
  final double prezzoFinale;

  /// Solo lavori "A giornata": guadagno netto di una giornata (es. 30 €).
  /// È l'importo di partenza delle nuove giornate; ognuna poi può cambiarlo.
  final double? tariffaGiornaliera;

  // Pagamento (si usa dal passo 7)
  final StatoPagamento statoPagamento;

  /// Entro quando il cliente deve pagare (vuota = nessuna scadenza).
  final DateTime? scadenza;

  /// Giorno in cui l'hai incassato (solo se incassato).
  final DateTime? dataIncasso;

  /// Giorno in cui hai chiesto il pagamento (consegna o fattura). Da qui si
  /// contano i giorni che un cliente impiega a pagare. Vuoto = giorno in cui
  /// hai creato il lavoro.
  final DateTime? richiestoIl;

  /// Cosa hai cercato sul web per il prezzo di questo lavoro (vuota = la
  /// domanda di partenza del tipo). Resta qui per rifare la stessa ricerca.
  final String? domandaRicerca;

  final DateTime creatoIl;

  Lavoro copyWith({
    String? nome,
    TipoLavoro? tipo,
    String? Function()? clienteId,
    String? Function()? categoriaId,
    Relazione? relazione,
    int? livello,
    double? prezzoPieno,
    double? prezzoFinale,
    double? tariffaGiornaliera,
    StatoPagamento? statoPagamento,
    DateTime? Function()? scadenza,
    DateTime? Function()? dataIncasso,
    DateTime? Function()? richiestoIl,
    String? Function()? domandaRicerca,
  }) => Lavoro(
    id: id,
    nome: nome ?? this.nome,
    tipo: tipo ?? this.tipo,
    clienteId: clienteId != null ? clienteId() : this.clienteId,
    categoriaId: categoriaId != null ? categoriaId() : this.categoriaId,
    relazione: relazione ?? this.relazione,
    livello: livello ?? this.livello,
    prezzoPieno: prezzoPieno ?? this.prezzoPieno,
    prezzoFinale: prezzoFinale ?? this.prezzoFinale,
    tariffaGiornaliera: tariffaGiornaliera ?? this.tariffaGiornaliera,
    statoPagamento: statoPagamento ?? this.statoPagamento,
    scadenza: scadenza != null ? scadenza() : this.scadenza,
    dataIncasso: dataIncasso != null ? dataIncasso() : this.dataIncasso,
    richiestoIl: richiestoIl != null ? richiestoIl() : this.richiestoIl,
    domandaRicerca: domandaRicerca != null
        ? domandaRicerca()
        : this.domandaRicerca,
    creatoIl: creatoIl,
  );

  Map<String, Object?> toMap() => {
    'nome': nome,
    'tipo': tipo.name,
    'clienteId': clienteId,
    'categoriaId': categoriaId,
    'relazione': relazione.name,
    'livello': livello,
    'prezzoPieno': prezzoPieno,
    'prezzoFinale': prezzoFinale,
    'tariffaGiornaliera': tariffaGiornaliera,
    'statoPagamento': statoPagamento.name,
    'scadenza': scadenza,
    'dataIncasso': dataIncasso,
    'richiestoIl': richiestoIl,
    'domandaRicerca': domandaRicerca,
    'creatoIl': creatoIl,
  };

  factory Lavoro.fromMap(String id, Map<String, Object?> dati) => Lavoro(
    id: id,
    nome: dati['nome'] as String? ?? '',
    tipo: TipoLavoro.da(dati['tipo']),
    clienteId: dati['clienteId'] as String?,
    categoriaId: dati['categoriaId'] as String?,
    relazione: Relazione.da(dati['relazione']),
    livello: ((dati['livello'] as num?)?.toInt() ?? 3).clamp(1, 5),
    prezzoPieno: leggiDouble(dati['prezzoPieno']),
    prezzoFinale: leggiDouble(dati['prezzoFinale']),
    tariffaGiornaliera: (dati['tariffaGiornaliera'] as num?)?.toDouble(),
    statoPagamento: StatoPagamento.da(dati['statoPagamento']),
    scadenza: leggiData(dati['scadenza']),
    dataIncasso: leggiData(dati['dataIncasso']),
    richiestoIl: leggiData(dati['richiestoIl']),
    domandaRicerca: dati['domandaRicerca'] as String?,
    creatoIl:
        leggiData(dati['creatoIl']) ?? DateTime.fromMillisecondsSinceEpoch(0),
  );
}
