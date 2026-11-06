import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../logica/migliora_testo.dart';
import 'migliora_testo.dart';

/// Migliora i testi con Claude (API di Anthropic). Serve la chiave che l'utente
/// crea su console.anthropic.com: è a consumo, ma un miglioramento costa una
/// frazione di centesimo.
class MiglioraTestoClaude implements MiglioraTesto {
  MiglioraTestoClaude({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  static final _indirizzo = Uri.parse('https://api.anthropic.com/v1/messages');

  @override
  Future<EsitoMiglioramento> migliora(
    TestiDaMigliorare testi, {
    required String chiave,
  }) async {
    final http.Response risposta;
    try {
      risposta = await _client
          .post(
            _indirizzo,
            headers: {
              'x-api-key': chiave,
              'anthropic-version': versioneApiAi,
              'content-type': 'application/json',
            },
            body: jsonEncode(corpoRichiesta(testi)),
          )
          .timeout(const Duration(seconds: 45));
    } on Exception {
      return const MiglioramentoFallito(
        'Non riesco a raggiungere Claude: controlla internet e riprova.',
      );
    }

    // I byte si leggono come UTF-8 (altrimenti accenti e € si rompono)
    final corpo = utf8.decode(risposta.bodyBytes, allowMalformed: true);

    switch (risposta.statusCode) {
      case 200:
        final Object? json;
        try {
          json = jsonDecode(corpo);
        } on FormatException {
          return _nonValida;
        }
        if (json is! Map<String, Object?>) return _nonValida;
        final testiNuovi = leggiRisposta(json, originali: testi);
        return testiNuovi == null
            ? _nonValida
            : MiglioramentoRiuscito(testiNuovi);
      case 401:
      case 403:
        return const MiglioramentoFallito(
          'La chiave di Claude non è valida. Controllala in Impostazioni.',
          serveChiave: true,
        );
      case 402:
        return _creditoFinito;
      case 429:
        return const MiglioramentoFallito(
          'Troppe richieste a Claude: riprova tra qualche minuto.',
        );
      case 400:
        // Il credito finito arriva come errore 400 con un messaggio
        if (corpo.toLowerCase().contains('credit balance')) {
          return _creditoFinito;
        }
        return MiglioramentoFallito(
          'Claude non ha accettato la richiesta (${risposta.statusCode}).',
        );
      default:
        if (risposta.statusCode >= 500) {
          return const MiglioramentoFallito(
            'Claude è occupato in questo momento: riprova tra poco.',
          );
        }
        return MiglioramentoFallito(
          'Claude ha risposto con un errore (${risposta.statusCode}).',
        );
    }
  }

  static const _nonValida = MiglioramentoFallito(
    'Claude ha risposto, ma il testo non era usabile. Riprova: il tuo testo '
    'è rimasto com\'era.',
  );

  static const _creditoFinito = MiglioramentoFallito(
    'Il credito del tuo account Anthropic è finito. Ricaricalo su '
    'console.anthropic.com e riprova.',
  );
}
