import 'tipi.dart';

/// Una giornata di un lavoro "A giornata" (es. un giorno al negozio): una data
/// e il guadagno netto di quel giorno. Salvata in `utenti/{uid}/giornate/{id}`.
class Giornata {
  const Giornata({
    required this.id,
    required this.lavoroId,
    required this.data,
    required this.importo,
    required this.creatoIl,
  });

  final String id;
  final String lavoroId;

  /// Solo il giorno (ore a zero).
  final DateTime data;

  /// Guadagno netto di questa giornata, in euro.
  final double importo;
  final DateTime creatoIl;

  Giornata copyWith({double? importo}) => Giornata(
    id: id,
    lavoroId: lavoroId,
    data: data,
    importo: importo ?? this.importo,
    creatoIl: creatoIl,
  );

  Map<String, Object?> toMap() => {
    'lavoroId': lavoroId,
    'data': data,
    'importo': importo,
    'creatoIl': creatoIl,
  };

  factory Giornata.fromMap(String id, Map<String, Object?> dati) {
    final data =
        leggiData(dati['data']) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return Giornata(
      id: id,
      lavoroId: dati['lavoroId'] as String? ?? '',
      data: DateTime(data.year, data.month, data.day),
      importo: leggiDouble(dati['importo']),
      creatoIl:
          leggiData(dati['creatoIl']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
