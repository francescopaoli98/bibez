import '../logica/calcoli.dart';
import 'tipi.dart';

/// Impostazioni dell'utente. Salvate in `utenti/{uid}/impostazioni/generali`
/// (un solo documento). Un valore mancante vale quello di partenza, quindi i
/// dati vecchi si leggono senza problemi.
class Impostazioni {
  const Impostazioni({
    this.promemoria = true,
    this.tasse = tassePredefinite,
    this.obiettivoMensile = 0,
    this.scontoRelazione = scontiPredefiniti,
    this.correzioneLivello = correzioniPredefinite,
  });

  static const tassePredefinite = 22.0;

  /// Promemoria dei pagamenti con notifiche sul telefono.
  final bool promemoria;

  /// Tasse in % (22 = 22%), tolte dal saldo per avere il netto.
  final double tasse;

  /// Quanto vuoi guadagnare **netto** al mese, dopo le tasse (0 = non scelto).
  final double obiettivoMensile;

  /// Sconto in % per ogni relazione col cliente.
  final Map<Relazione, int> scontoRelazione;

  /// Correzione in % del prezzo per livello di competenza (1-5).
  final Map<int, int> correzioneLivello;

  /// I valori che entrano nel calcolo del prezzo suggerito.
  ParametriPrezzo get parametriPrezzo => ParametriPrezzo(
    scontoRelazione: scontoRelazione,
    correzioneLivello: correzioneLivello,
  );

  Impostazioni copyWith({
    bool? promemoria,
    double? tasse,
    double? obiettivoMensile,
    Map<Relazione, int>? scontoRelazione,
    Map<int, int>? correzioneLivello,
  }) => Impostazioni(
    promemoria: promemoria ?? this.promemoria,
    tasse: tasse ?? this.tasse,
    obiettivoMensile: obiettivoMensile ?? this.obiettivoMensile,
    scontoRelazione: scontoRelazione ?? this.scontoRelazione,
    correzioneLivello: correzioneLivello ?? this.correzioneLivello,
  );

  Map<String, Object?> toMap() => {
    'promemoria': promemoria,
    'tasse': tasse,
    'obiettivoMensile': obiettivoMensile,
    'sconti': {for (final e in scontoRelazione.entries) e.key.name: e.value},
    'correzioni': {
      for (final e in correzioneLivello.entries) '${e.key}': e.value,
    },
  };

  factory Impostazioni.fromMap(Map<String, Object?> dati) {
    final sconti = dati['sconti'];
    final correzioni = dati['correzioni'];
    int intero(Object? valore, int predefinito) =>
        valore is num ? valore.round() : predefinito;

    return Impostazioni(
      promemoria: dati['promemoria'] as bool? ?? true,
      tasse: dati['tasse'] is num
          ? (dati['tasse'] as num).toDouble()
          : tassePredefinite,
      obiettivoMensile: dati['obiettivoMensile'] is num
          ? (dati['obiettivoMensile'] as num).toDouble()
          : 0,
      scontoRelazione: {
        for (final r in Relazione.values)
          r: intero(
            sconti is Map ? sconti[r.name] : null,
            scontiPredefiniti[r]!,
          ),
      },
      correzioneLivello: {
        for (var livello = 1; livello <= 5; livello++)
          livello: intero(
            correzioni is Map ? correzioni['$livello'] : null,
            correzioniPredefinite[livello]!,
          ),
      },
    );
  }
}
