import 'tipi.dart';

/// Categoria di costo (es. "Doppiaggio", "Claude") con un colore a scelta.
/// Salvata in `utenti/{uid}/categorie/{id}`.
class Categoria {
  const Categoria({
    required this.id,
    required this.nome,
    required this.colore,
    required this.creatoIl,
    this.tipoLavoro,
  });

  final String id;
  final String nome;

  /// Posizione del colore nella tavolozza (`tema/palette_categorie.dart`).
  final int colore;
  final DateTime creatoIl;

  /// Tipo di lavoro con cui si recuperano i costi di questa categoria
  /// (es. la categoria "Claude" → progetti Claude). Vuoto = tutti i progetti.
  final TipoLavoro? tipoLavoro;

  Categoria copyWith({
    String? nome,
    int? colore,
    TipoLavoro? Function()? tipoLavoro,
  }) => Categoria(
    id: id,
    nome: nome ?? this.nome,
    colore: colore ?? this.colore,
    creatoIl: creatoIl,
    tipoLavoro: tipoLavoro != null ? tipoLavoro() : this.tipoLavoro,
  );

  Map<String, Object?> toMap() => {
    'nome': nome,
    'colore': colore,
    'tipoLavoro': tipoLavoro?.name,
    'creatoIl': creatoIl,
  };

  factory Categoria.fromMap(String id, Map<String, Object?> dati) => Categoria(
    id: id,
    nome: dati['nome'] as String? ?? '',
    colore: (dati['colore'] as num?)?.toInt() ?? 0,
    // Senza il campo (categorie vecchie) vale "tutti i progetti"
    tipoLavoro: dati['tipoLavoro'] == null
        ? null
        : TipoLavoro.da(dati['tipoLavoro']),
    creatoIl:
        leggiData(dati['creatoIl']) ?? DateTime.fromMillisecondsSinceEpoch(0),
  );
}
