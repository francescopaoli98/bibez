import 'tipi.dart';

/// Categoria di costo (es. "Doppiaggio", "Claude") con un colore a scelta.
/// Salvata in `utenti/{uid}/categorie/{id}`.
class Categoria {
  const Categoria({
    required this.id,
    required this.nome,
    required this.colore,
    required this.creatoIl,
  });

  final String id;
  final String nome;

  /// Posizione del colore nella tavolozza (`tema/palette_categorie.dart`).
  final int colore;
  final DateTime creatoIl;

  Categoria copyWith({String? nome, int? colore}) => Categoria(
    id: id,
    nome: nome ?? this.nome,
    colore: colore ?? this.colore,
    creatoIl: creatoIl,
  );

  Map<String, Object?> toMap() => {
    'nome': nome,
    'colore': colore,
    'creatoIl': creatoIl,
  };

  factory Categoria.fromMap(String id, Map<String, Object?> dati) => Categoria(
    id: id,
    nome: dati['nome'] as String? ?? '',
    colore: (dati['colore'] as num?)?.toInt() ?? 0,
    creatoIl:
        leggiData(dati['creatoIl']) ?? DateTime.fromMillisecondsSinceEpoch(0),
  );
}
