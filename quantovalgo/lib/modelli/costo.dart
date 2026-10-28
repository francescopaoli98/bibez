import 'tipi.dart';

/// Tipo di costo. Le chiavi (`name`) finiscono nel database.
enum TipoCosto {
  /// Si paga ogni mese e si divide tra i progetti (es. Claude, software).
  abbonamento('Abbonamento'),

  /// Si paga una volta (es. un microfono): o tutto nel mese, o spalmato.
  unaTantum('Una tantum'),

  /// Spesa fissa mensile che non si divide tra i progetti (es. internet).
  fisso('Fisso');

  const TipoCosto(this.etichetta);
  final String etichetta;

  static TipoCosto da(Object? chiave) => values.firstWhere(
    (t) => t.name == chiave,
    orElse: () => TipoCosto.abbonamento,
  );
}

/// Un costo. Salvato in `utenti/{uid}/costi/{id}`.
class Costo {
  const Costo({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.importo,
    required this.inizio,
    required this.creatoIl,
    this.mesi = 1,
    this.fine,
    this.categoriaId,
  });

  final String id;
  final String nome;
  final TipoCosto tipo;

  /// Abbonamento e fisso: importo di ogni mese.
  /// Una tantum: prezzo totale pagato.
  final double importo;

  /// Solo una tantum: su quanti mesi si spalma (1 = tutto nel mese).
  final int mesi;

  /// Abbonamento e fisso: primo mese. Una tantum: data dell'acquisto.
  final DateTime inizio;

  /// Abbonamento e fisso: ultimo mese in cui si paga (vuoto = ancora attivo).
  final DateTime? fine;

  final String? categoriaId;
  final DateTime creatoIl;

  /// Vero se il costo si divide tra i progetti (tutti tranne i fissi).
  bool get siDivideTraProgetti => tipo != TipoCosto.fisso;

  Costo copyWith({
    String? nome,
    TipoCosto? tipo,
    double? importo,
    int? mesi,
    DateTime? inizio,
    DateTime? Function()? fine,
    String? Function()? categoriaId,
  }) => Costo(
    id: id,
    nome: nome ?? this.nome,
    tipo: tipo ?? this.tipo,
    importo: importo ?? this.importo,
    mesi: mesi ?? this.mesi,
    inizio: inizio ?? this.inizio,
    fine: fine != null ? fine() : this.fine,
    categoriaId: categoriaId != null ? categoriaId() : this.categoriaId,
    creatoIl: creatoIl,
  );

  Map<String, Object?> toMap() => {
    'nome': nome,
    'tipo': tipo.name,
    'importo': importo,
    'mesi': mesi,
    'inizio': inizio,
    'fine': fine,
    'categoriaId': categoriaId,
    'creatoIl': creatoIl,
  };

  factory Costo.fromMap(String id, Map<String, Object?> dati) => Costo(
    id: id,
    nome: dati['nome'] as String? ?? '',
    tipo: TipoCosto.da(dati['tipo']),
    importo: leggiDouble(dati['importo']),
    mesi: ((dati['mesi'] as num?)?.toInt() ?? 1).clamp(1, 120),
    inizio: leggiData(dati['inizio']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    fine: leggiData(dati['fine']),
    categoriaId: dati['categoriaId'] as String?,
    creatoIl:
        leggiData(dati['creatoIl']) ?? DateTime.fromMillisecondsSinceEpoch(0),
  );
}
