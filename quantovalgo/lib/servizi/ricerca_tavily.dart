import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../logica/prezzi_web.dart';
import '../modelli/tipi.dart';
import 'ricerca_prezzi.dart';

/// Ricerca dei prezzi con Tavily (ricerca "basic": 1 credito, 1.000 gratis al mese).
/// Parte solo quando serve: dal pulsante "Cerca prezzi" o dall'aggiornamento
/// settimanale. La chiave la crea l'utente su tavily.com.
class RicercaTavily implements RicercaPrezzi {
  RicercaTavily({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static final _indirizzo = Uri.parse('https://api.tavily.com/search');

  @override
  Future<RisultatoRicerca> cerca(
    TipoLavoro tipo, {
    required String chiave,
    String? domanda,
  }) async {
    final limiti = limitiPerTipo[tipo];
    final scritta = domanda?.trim() ?? '';
    final base = scritta.isNotEmpty ? scritta : domandaPredefinita[tipo];
    if (base == null || limiti == null) {
      return const RicercaFallita(
        'Scrivi cosa vuoi cercare (per esempio "assistenza configurazione '
        'smartphone a domicilio"), oppure inserisci la forbice a mano.',
      );
    }
    final query = costruisciQuery(base);

    final http.Response risposta;
    try {
      risposta = await _client
          .post(
            _indirizzo,
            headers: {
              'Authorization': 'Bearer $chiave',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'query': query,
              'search_depth': 'basic', // 1 credito
              'max_results': 10,
              'include_answer': false,
              'include_raw_content': false,
            }),
          )
          .timeout(const Duration(seconds: 25));
    } on Exception {
      return const RicercaFallita(
        'Non riesco a raggiungere Tavily: controlla internet e riprova.',
      );
    }

    switch (risposta.statusCode) {
      case 200:
        // I byte si leggono come UTF-8: senza charset nell'intestazione il
        // pacchetto http userebbe Latin-1 e il simbolo € si romperebbe.
        return _leggi(
          utf8.decode(risposta.bodyBytes, allowMalformed: true),
          limiti,
          query,
        );
      case 401:
        return const RicercaFallita(
          'La chiave di Tavily non è valida. Controllala in Impostazioni.',
          serveChiave: true,
        );
      case 429:
        return const RicercaFallita(
          'Troppe richieste a Tavily: riprova tra qualche minuto.',
        );
      case 432:
      case 433:
        return const RicercaFallita(
          'Hai finito i crediti di Tavily per questo mese.',
        );
      default:
        return RicercaFallita(
          'Tavily ha risposto con un errore (${risposta.statusCode}).',
        );
    }
  }

  /// Dai risultati di Tavily alla forbice (o a "non affidabile").
  RisultatoRicerca _leggi(String corpo, LimitiImporto limiti, String query) {
    final Object? json;
    try {
      json = jsonDecode(corpo);
    } on FormatException {
      return const RicercaFallita('Risposta di Tavily non leggibile.');
    }
    final risultati = json is Map ? json['results'] : null;
    if (risultati is! List) return const RicercaNonAffidabile();

    final importiPerSito = <String, List<double>>{};
    for (final r in risultati) {
      if (r is! Map) continue;
      final sito = sitoDi('${r['url'] ?? ''}');
      final testo = '${r['title'] ?? ''}. ${r['content'] ?? ''}';
      importiPerSito.putIfAbsent(sito, () => []).addAll(importiInEuro(testo));
    }

    final trovata = forbiceDaFonti(importiPerSito, limiti);
    return trovata == null
        ? const RicercaNonAffidabile()
        : RicercaTrovata(
            ForbiceTrovata(
              forbice: trovata.forbice,
              fonti: trovata.fonti,
              importi: trovata.importi,
              domanda: query,
            ),
          );
  }
}
