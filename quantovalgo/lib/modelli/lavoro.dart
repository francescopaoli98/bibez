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
    this.statoPagamento = StatoPagamento.daIncassare,
    this.scadenza,
    this.dataIncasso,
  });

  final String id;
  final String nome;
  final TipoLavoro tipo;

  /// Cliente (può mancare). La relazione è quella di questo lavoro.
  final String? clienteId;
  final Relazione relazione;

  /// Livello di competenza per questo lavoro, da 1 a 5.
  final int livello;

  /// Prezzo di listino e prezzo realmente concordato (dopo lo sconto).
  final double prezzoPieno;
  final double prezzoFinale;

  // Pagamento (si usa dal passo 7)
  final StatoPagamento statoPagamento;
  final DateTime? scadenza;
  final DateTime? dataIncasso;

  final DateTime creatoIl;

  Lavoro copyWith({
    String? nome,
    TipoLavoro? tipo,
    String? Function()? clienteId,
    Relazione? relazione,
    int? livello,
    double? prezzoPieno,
    double? prezzoFinale,
    StatoPagamento? statoPagamento,
  }) => Lavoro(
    id: id,
    nome: nome ?? this.nome,
    tipo: tipo ?? this.tipo,
    clienteId: clienteId != null ? clienteId() : this.clienteId,
    relazione: relazione ?? this.relazione,
    livello: livello ?? this.livello,
    prezzoPieno: prezzoPieno ?? this.prezzoPieno,
    prezzoFinale: prezzoFinale ?? this.prezzoFinale,
    statoPagamento: statoPagamento ?? this.statoPagamento,
    scadenza: scadenza,
    dataIncasso: dataIncasso,
    creatoIl: creatoIl,
  );

  Map<String, Object?> toMap() => {
    'nome': nome,
    'tipo': tipo.name,
    'clienteId': clienteId,
    'relazione': relazione.name,
    'livello': livello,
    'prezzoPieno': prezzoPieno,
    'prezzoFinale': prezzoFinale,
    'statoPagamento': statoPagamento.name,
    'scadenza': scadenza,
    'dataIncasso': dataIncasso,
    'creatoIl': creatoIl,
  };

  factory Lavoro.fromMap(String id, Map<String, Object?> dati) => Lavoro(
    id: id,
    nome: dati['nome'] as String? ?? '',
    tipo: TipoLavoro.da(dati['tipo']),
    clienteId: dati['clienteId'] as String?,
    relazione: Relazione.da(dati['relazione']),
    livello: ((dati['livello'] as num?)?.toInt() ?? 3).clamp(1, 5),
    prezzoPieno: leggiDouble(dati['prezzoPieno']),
    prezzoFinale: leggiDouble(dati['prezzoFinale']),
    statoPagamento: StatoPagamento.da(dati['statoPagamento']),
    scadenza: leggiData(dati['scadenza']),
    dataIncasso: leggiData(dati['dataIncasso']),
    creatoIl:
        leggiData(dati['creatoIl']) ?? DateTime.fromMillisecondsSinceEpoch(0),
  );
}
