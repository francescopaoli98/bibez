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
    this.chiaveTavily = '',
    this.chiaveClaude = '',
    this.aggiornaPrezzi = false,
    this.ricercheMese = '',
    this.ricercheUsate = 0,
    this.tariffaOraria = tariffaOrariaPredefinita,
    this.rimborsoKm = rimborsoKmPredefinito,
  });

  static const tassePredefinite = 22.0;

  /// Quanto vale un'ora del tuo tempo, di partenza (€).
  static const tariffaOrariaPredefinita = 25.0;

  /// Rimborso per ogni km di trasferta, di partenza (€).
  static const rimborsoKmPredefinito = 0.30;

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

  /// Chiave di Tavily per cercare i prezzi sul web (vuota = ricerca spenta).
  /// La crea l'utente su tavily.com; sta nel suo cloud privato.
  final String chiaveTavily;

  /// Chiave dell'API di Claude (Anthropic) per "Migliora il testo con l'AI"
  /// (vuota = AI spenta). La crea l'utente; sta nel suo cloud privato.
  final String chiaveClaude;

  /// Aggiorna da solo, una volta a settimana, le forbici trovate dal web
  /// (quelle scritte a mano non si toccano). Parte quando si apre l'app.
  final bool aggiornaPrezzi;

  /// Mese (`2026-10`) a cui si riferisce [ricercheUsate].
  final String ricercheMese;

  /// Ricerche fatte in quel mese: ognuna usa 1 credito di Tavily.
  final int ricercheUsate;

  /// Quanto vale un'ora del tuo tempo (€): serve a calcolare quanto chiedere
  /// da ore di lavoro.
  final double tariffaOraria;

  /// Quanto chiedere per ogni km di trasferta (andata e ritorno contati).
  final double rimborsoKm;

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
    String? chiaveTavily,
    String? chiaveClaude,
    bool? aggiornaPrezzi,
    String? ricercheMese,
    int? ricercheUsate,
    double? tariffaOraria,
    double? rimborsoKm,
  }) => Impostazioni(
    promemoria: promemoria ?? this.promemoria,
    tasse: tasse ?? this.tasse,
    obiettivoMensile: obiettivoMensile ?? this.obiettivoMensile,
    scontoRelazione: scontoRelazione ?? this.scontoRelazione,
    correzioneLivello: correzioneLivello ?? this.correzioneLivello,
    chiaveTavily: chiaveTavily ?? this.chiaveTavily,
    chiaveClaude: chiaveClaude ?? this.chiaveClaude,
    aggiornaPrezzi: aggiornaPrezzi ?? this.aggiornaPrezzi,
    ricercheMese: ricercheMese ?? this.ricercheMese,
    ricercheUsate: ricercheUsate ?? this.ricercheUsate,
    tariffaOraria: tariffaOraria ?? this.tariffaOraria,
    rimborsoKm: rimborsoKm ?? this.rimborsoKm,
  );

  Map<String, Object?> toMap() => {
    'promemoria': promemoria,
    'tasse': tasse,
    'obiettivoMensile': obiettivoMensile,
    'sconti': {for (final e in scontoRelazione.entries) e.key.name: e.value},
    'correzioni': {
      for (final e in correzioneLivello.entries) '${e.key}': e.value,
    },
    'chiaveTavily': chiaveTavily,
    'chiaveClaude': chiaveClaude,
    'aggiornaPrezzi': aggiornaPrezzi,
    'ricercheMese': ricercheMese,
    'ricercheUsate': ricercheUsate,
    'tariffaOraria': tariffaOraria,
    'rimborsoKm': rimborsoKm,
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
      chiaveTavily: dati['chiaveTavily'] is String
          ? (dati['chiaveTavily'] as String).trim()
          : '',
      chiaveClaude: dati['chiaveClaude'] is String
          ? (dati['chiaveClaude'] as String).trim()
          : '',
      aggiornaPrezzi: dati['aggiornaPrezzi'] as bool? ?? false,
      ricercheMese: dati['ricercheMese'] is String
          ? dati['ricercheMese'] as String
          : '',
      ricercheUsate: intero(dati['ricercheUsate'], 0),
      tariffaOraria: dati['tariffaOraria'] is num
          ? (dati['tariffaOraria'] as num).toDouble()
          : tariffaOrariaPredefinita,
      rimborsoKm: dati['rimborsoKm'] is num
          ? (dati['rimborsoKm'] as num).toDouble()
          : rimborsoKmPredefinito,
    );
  }
}
