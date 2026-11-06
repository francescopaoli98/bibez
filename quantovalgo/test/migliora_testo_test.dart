import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quantovalgo/logica/migliora_testo.dart';
import 'package:quantovalgo/modelli/tipi.dart';
import 'package:quantovalgo/servizi/migliora_testo.dart';
import 'package:quantovalgo/servizi/migliora_testo_claude.dart';

const originali = TestiDaMigliorare(
  tipo: TipoLavoro.codice,
  progetto: 'Sito vetrina',
  fasi: ['Capiamo cosa ti serve', 'Sviluppo', 'Consegna'],
  benefit: ['Prezzo chiaro', 'Assistenza dopo la consegna'],
  consegna: '1 settimana',
);

/// Una risposta dell'API con [json] come testo del modello.
Map<String, Object?> rispostaCon(Object json, {String? stop}) => {
  'stop_reason': stop ?? 'end_turn',
  'content': [
    {'type': 'thinking', 'thinking': ''},
    {'type': 'text', 'text': json is String ? json : jsonEncode(json)},
  ],
};

const buona = {
  'progetto': 'Realizzo un sito vetrina curato per presentare la tua attività.',
  'fasi': ['Capiamo insieme cosa ti serve', 'Sviluppo il sito', 'Lo consegno'],
  'benefit': ['Prezzo chiaro, senza sorprese', 'Ti seguo anche dopo'],
};

void main() {
  group('Richiesta', () {
    test('usa il modello piccolo e non manda parametri vietati', () {
      final corpo = corpoRichiesta(originali);
      expect(corpo['model'], 'claude-haiku-5-5');
      // Su Haiku 5.5 questi parametri danno errore 400
      for (final vietato in [
        'temperature',
        'top_p',
        'top_k',
        'budget_tokens',
      ]) {
        expect(jsonEncode(corpo), isNot(contains(vietato)));
      }
      expect((corpo['output_config'] as Map)['effort'], 'low');
    });

    test('manda i testi e la consegna come solo contesto', () {
      final corpo = corpoRichiesta(originali);
      final messaggio = (corpo['messages'] as List).single as Map;
      final dati = jsonDecode(messaggio['content'] as String) as Map;
      expect(dati['progetto'], 'Sito vetrina');
      expect(dati['fasi'], hasLength(3));
      expect(dati['tipo_di_lavoro'], TipoLavoro.codice.etichetta);
      expect(dati['consegna_non_da_riscrivere'], '1 settimana');
    });
  });

  group('Lettura della risposta', () {
    test('una risposta buona diventa la proposta', () {
      final t = leggiRisposta(rispostaCon(buona), originali: originali);
      expect(t, isNotNull);
      expect(t!.progetto, startsWith('Realizzo un sito vetrina'));
      expect(t.fasi, hasLength(3));
      expect(t.benefit, hasLength(2));
    });

    test('toglie il recinto del codice e i pallini davanti alle voci', () {
      final testo =
          '```json\n${jsonEncode({
            ...buona,
            'fasi': ['- Capiamo insieme', '2. Sviluppo', '• Consegna'],
          })}\n```';
      final t = leggiRisposta(rispostaCon(testo), originali: originali);
      expect(t!.fasi, ['Capiamo insieme', 'Sviluppo', 'Consegna']);
    });

    test('rifiuto, testo vuoto o non JSON: nessuna proposta', () {
      expect(
        leggiRisposta(
          rispostaCon(buona, stop: 'refusal'),
          originali: originali,
        ),
        isNull,
      );
      expect(leggiRisposta({'content': []}, originali: originali), isNull);
      expect(
        leggiRisposta(rispostaCon('ecco il testo!'), originali: originali),
        isNull,
      );
    });

    test('campi mancanti o di tipo sbagliato: nessuna proposta', () {
      for (final rotta in <Map<String, Object?>>[
        {'fasi': buona['fasi'], 'benefit': buona['benefit']},
        {...buona, 'progetto': 5},
        {...buona, 'fasi': 'una sola'},
        {...buona, 'benefit': <String>[]},
      ]) {
        expect(leggiRisposta(rispostaCon(rotta), originali: originali), isNull);
      }
    });

    test('voci sparite o righe troppo lunghe: nessuna proposta', () {
      expect(
        leggiRisposta(
          rispostaCon({
            ...buona,
            'fasi': ['Una sola'],
          }),
          originali: originali,
        ),
        isNull,
      );
      expect(
        leggiRisposta(
          rispostaCon({
            ...buona,
            'benefit': ['x' * 200, 'ok'],
          }),
          originali: originali,
        ),
        isNull,
      );
    });
  });

  group('Servizio verso Claude', () {
    MiglioraTestoClaude con(
      Future<http.Response> Function(http.Request) risposta,
    ) => MiglioraTestoClaude(client: MockClient(risposta));

    http.Response ok(Object corpo, [int codice = 200]) => http.Response.bytes(
      utf8.encode(jsonEncode(corpo)),
      codice,
      headers: {'content-type': 'application/json'},
    );

    test(
      'manda chiave e versione nelle intestazioni e legge la proposta',
      () async {
        late http.Request vista;
        final esito = await con((r) async {
          vista = r;
          return ok(rispostaCon(buona));
        }).migliora(originali, chiave: 'sk-ant-prova');

        expect(vista.url.toString(), 'https://api.anthropic.com/v1/messages');
        expect(vista.headers['x-api-key'], 'sk-ant-prova');
        expect(vista.headers['anthropic-version'], versioneApiAi);
        expect(esito, isA<MiglioramentoRiuscito>());
      },
    );

    test('gli accenti arrivano interi', () async {
      final esito = await con(
        (_) async => ok(rispostaCon({...buona, 'progetto': 'Più semplice: €'})),
      ).migliora(originali, chiave: 'sk-ant-prova');
      expect(
        (esito as MiglioramentoRiuscito).testi.progetto,
        'Più semplice: €',
      );
    });

    test('401: la chiave non va, si riapre il foglio chiave', () async {
      final esito = await con((_) async => ok({'type': 'error'}, 401))
          .migliora(originali, chiave: 'sk-ant-x');
      expect(esito, isA<MiglioramentoFallito>());
      expect((esito as MiglioramentoFallito).serveChiave, isTrue);
    });

    test('credito finito (400 con messaggio): lo dice', () async {
      final esito = await con(
        (_) async => ok({
          'type': 'error',
          'error': {
            'type': 'invalid_request_error',
            'message': 'Your credit balance is too low to access the API.',
          },
        }, 400),
      ).migliora(originali, chiave: 'sk-ant-x');
      expect((esito as MiglioramentoFallito).messaggio, contains('credito'));
      expect(esito.serveChiave, isFalse);
    });

    test('429, 500 e rete assente: messaggi chiari, il testo resta', () async {
      final troppe = await con((_) async => ok({'type': 'error'}, 429))
          .migliora(originali, chiave: 'sk-ant-x');
      expect((troppe as MiglioramentoFallito).messaggio, contains('Troppe'));

      final guasto = await con((_) async => ok({'type': 'error'}, 529))
          .migliora(originali, chiave: 'sk-ant-x');
      expect((guasto as MiglioramentoFallito).messaggio, contains('occupato'));

      final offline = await con(
        (_) async => throw http.ClientException('niente rete'),
      ).migliora(originali, chiave: 'sk-ant-x');
      expect((offline as MiglioramentoFallito).messaggio, contains('internet'));
    });

    test(
      '200 con testo inutilizzabile: errore gentile, non un crash',
      () async {
        final esito = await con((_) async => ok(rispostaCon('niente JSON qui')))
            .migliora(originali, chiave: 'sk-ant-x');
        expect(esito, isA<MiglioramentoFallito>());
      },
    );
  });
}
