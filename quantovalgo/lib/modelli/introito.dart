import 'tipi.dart';

/// Un guadagno veloce: soldi entrati senza dover creare un lavoro
/// (niente cliente, niente parti). Solo importo, giorno e una nota se vuoi.
/// Salvato in `utenti/{uid}/introiti/{id}`.
class Introito {
  const Introito({
    required this.id,
    required this.importo,
    required this.data,
    required this.creatoIl,
    this.nota = '',
  });

  final String id;

  /// Euro entrati (puro guadagno: non ha costi collegati).
  final double importo;

  /// Il giorno in cui sono entrati (solo la data).
  final DateTime data;

  /// Facoltativa: da dove arrivano (es. "Vendita usato").
  final String nota;
  final DateTime creatoIl;

  Introito copyWith({double? importo, DateTime? data, String? nota}) =>
      Introito(
        id: id,
        importo: importo ?? this.importo,
        data: data ?? this.data,
        nota: nota ?? this.nota,
        creatoIl: creatoIl,
      );

  Map<String, Object?> toMap() => {
    'importo': importo,
    'data': data,
    'nota': nota,
    'creatoIl': creatoIl,
  };

  factory Introito.fromMap(String id, Map<String, Object?> dati) {
    final data =
        leggiData(dati['data']) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return Introito(
      id: id,
      importo: leggiDouble(dati['importo']),
      data: DateTime(data.year, data.month, data.day),
      nota: dati['nota'] as String? ?? '',
      creatoIl:
          leggiData(dati['creatoIl']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
