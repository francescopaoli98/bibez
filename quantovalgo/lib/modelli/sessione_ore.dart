import 'tipi.dart';

/// Un periodo di lavoro su un sottoprogetto, da cronometro o inserito a mano.
/// Salvata in `utenti/{uid}/sessioni/{id}`.
///
/// Un cronometro acceso è una sessione con [fine] vuota: salvandola nel cloud
/// continua a correre anche se chiudi l'app o il telefono si spegne.
class SessioneOre {
  const SessioneOre({
    required this.id,
    required this.sottoprogettoId,
    required this.lavoroId,
    required this.inizio,
    required this.creatoIl,
    this.fine,
    this.minuti = 0,
    this.manuale = false,
  });

  final String id;
  final String sottoprogettoId;

  /// Il progetto a cui appartiene il sottoprogetto (comodo per i totali).
  final String lavoroId;
  final DateTime inizio;

  /// Vuota se il cronometro è ancora acceso.
  final DateTime? fine;

  /// Durata in minuti (0 finché il cronometro corre).
  final int minuti;

  /// Vero se l'hai inserita a mano, falso se viene dal cronometro.
  final bool manuale;
  final DateTime creatoIl;

  bool get inCorso => fine == null;

  SessioneOre copyWith({DateTime? inizio, DateTime? fine, int? minuti}) =>
      SessioneOre(
        id: id,
        sottoprogettoId: sottoprogettoId,
        lavoroId: lavoroId,
        inizio: inizio ?? this.inizio,
        fine: fine ?? this.fine,
        minuti: minuti ?? this.minuti,
        manuale: manuale,
        creatoIl: creatoIl,
      );

  Map<String, Object?> toMap() => {
    'sottoprogettoId': sottoprogettoId,
    'lavoroId': lavoroId,
    'inizio': inizio,
    'fine': fine,
    'minuti': minuti,
    'manuale': manuale,
    'creatoIl': creatoIl,
  };

  factory SessioneOre.fromMap(
    String id,
    Map<String, Object?> dati,
  ) => SessioneOre(
    id: id,
    sottoprogettoId: dati['sottoprogettoId'] as String? ?? '',
    lavoroId: dati['lavoroId'] as String? ?? '',
    inizio: leggiData(dati['inizio']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    fine: leggiData(dati['fine']),
    minuti: (dati['minuti'] as num?)?.toInt() ?? 0,
    manuale: dati['manuale'] as bool? ?? false,
    creatoIl:
        leggiData(dati['creatoIl']) ?? DateTime.fromMillisecondsSinceEpoch(0),
  );
}
