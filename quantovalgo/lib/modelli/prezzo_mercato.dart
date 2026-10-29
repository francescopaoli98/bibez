import '../logica/prezzi_web.dart';
import 'tipi.dart';

/// Forbice di prezzo di mercato per un tipo di lavoro.
/// Salvato in `utenti/{uid}/prezziMercato/{tipo}`: un solo documento per tipo.
class PrezzoMercato {
  const PrezzoMercato({
    required this.tipo,
    required this.minimo,
    required this.massimo,
    required this.aggiornato,
    this.fonti = const [],
    this.manuale = true,
    this.domanda = '',
    this.riferimenti = const [],
  });

  final TipoLavoro tipo;
  final double minimo;
  final double massimo;
  final DateTime aggiornato;

  /// Siti da cui arriva la forbice (dal passo 9, ricerca web).
  final List<String> fonti;

  /// Vero se l'hai inserita tu a mano.
  final bool manuale;

  /// Cosa è stato cercato sul web (vuota se la forbice è a mano). Serve a
  /// rifare la stessa ricerca nell'aggiornamento settimanale.
  final String domanda;

  /// I prezzi di riferimento trovati sul web, con sito e link, per poterli
  /// rivedere anche dopo (vuoti se la forbice è a mano).
  final List<PrezzoTrovato> riferimenti;

  String get id => tipo.name;

  Map<String, Object?> toMap() => {
    'tipo': tipo.name,
    'minimo': minimo,
    'massimo': massimo,
    'aggiornato': aggiornato,
    'fonti': fonti,
    'manuale': manuale,
    'domanda': domanda,
    'riferimenti': [for (final r in riferimenti) r.toMap()],
  };

  factory PrezzoMercato.fromMap(
    String id,
    Map<String, Object?> dati,
  ) => PrezzoMercato(
    tipo: TipoLavoro.da(dati['tipo'] ?? id),
    minimo: leggiDouble(dati['minimo']),
    massimo: leggiDouble(dati['massimo']),
    aggiornato:
        leggiData(dati['aggiornato']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    fonti: ((dati['fonti'] as List?) ?? const []).whereType<String>().toList(),
    manuale: dati['manuale'] as bool? ?? true,
    domanda: dati['domanda'] as String? ?? '',
    riferimenti: [
      for (final r in (dati['riferimenti'] as List?) ?? const [])
        if (r is Map) PrezzoTrovato.fromMap(r),
    ],
  );
}
