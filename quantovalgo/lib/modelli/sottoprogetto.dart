import 'tipi.dart';

/// Una parte di un lavoro (es. Registrazione, Revisione, Montaggio).
/// Salvato in `utenti/{uid}/sottoprogetti/{id}`.
class Sottoprogetto {
  const Sottoprogetto({
    required this.id,
    required this.lavoroId,
    required this.nome,
    required this.ricavo,
    required this.costiDiretti,
    required this.ore,
    required this.creatoIl,
  });

  final String id;
  final String lavoroId;
  final String nome;

  /// Quanto incassi per questa parte.
  final double ricavo;

  /// Costi solo di questa parte (non abbonamenti o attrezzatura).
  final double costiDiretti;

  /// Ore inserite a mano. Dal passo 5 si sommano a quelle del cronometro.
  final double ore;

  final DateTime creatoIl;

  /// Utile = ricavo − costi diretti.
  double get utile => ricavo - costiDiretti;

  Sottoprogetto copyWith({
    String? nome,
    double? ricavo,
    double? costiDiretti,
    double? ore,
  }) => Sottoprogetto(
    id: id,
    lavoroId: lavoroId,
    nome: nome ?? this.nome,
    ricavo: ricavo ?? this.ricavo,
    costiDiretti: costiDiretti ?? this.costiDiretti,
    ore: ore ?? this.ore,
    creatoIl: creatoIl,
  );

  Map<String, Object?> toMap() => {
    'lavoroId': lavoroId,
    'nome': nome,
    'ricavo': ricavo,
    'costiDiretti': costiDiretti,
    'ore': ore,
    'creatoIl': creatoIl,
  };

  factory Sottoprogetto.fromMap(String id, Map<String, Object?> dati) =>
      Sottoprogetto(
        id: id,
        lavoroId: dati['lavoroId'] as String? ?? '',
        nome: dati['nome'] as String? ?? '',
        ricavo: leggiDouble(dati['ricavo']),
        costiDiretti: leggiDouble(dati['costiDiretti']),
        ore: leggiDouble(dati['ore']),
        creatoIl:
            leggiData(dati['creatoIl']) ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}
