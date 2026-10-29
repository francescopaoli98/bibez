import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quantovalgo/logica/prezzi_web.dart';
import 'package:quantovalgo/modelli/tipi.dart';
import 'package:quantovalgo/servizi/ricerca_prezzi.dart';
import 'package:quantovalgo/servizi/ricerca_tavily.dart';

/// Risposta come quella vera di Tavily: byte UTF-8, senza charset dichiarato.
http.Response utf8Response(String corpo, int codice) =>
    http.Response.bytes(utf8.encode(corpo), codice);

void main() {
  group('Importi in euro nei testi', () {
    test('forme diverse di scrivere un importo', () {
      expect(importiInEuro('costa 80 € all\'ora'), [80]);
      expect(importiInEuro('Solo €80 a progetto'), [80]);
      expect(importiInEuro('circa 1.200 euro'), [1200]);
      expect(importiInEuro('25,50 € a pagina'), [25.5]);
      expect(importiInEuro('prezzo 25.50 EUR'), [25.5]);
      expect(importiInEuro('1 200 € il pacchetto'), [1200]);
    });

    test('gli intervalli danno tutti e due gli estremi', () {
      expect(importiInEuro('da 80 a 120 euro'), [80, 120]);
      expect(importiInEuro('50-100 €'), [50, 100]);
      expect(importiInEuro('€50 - €100'), [50, 100]);
    });

    test('numeri senza euro non contano (anni, clienti, ore)', () {
      expect(importiInEuro('nel 2024 oltre 500 clienti in 10 ore'), isEmpty);
      // Niente numeri incollati: "10 80 €" è 80, non 1080
      expect(importiInEuro('dopo 10 80 €'), [80]);
    });
  });

  group('Forbice dai siti', () {
    const l = LimitiImporto(20, 3000);

    test('dal 25° al 75° percentile, a multipli di 5', () {
      final t = forbiceDaFonti({
        'a.it': [80, 100, 120],
        'b.com': [90, 110],
      }, l)!;
      expect(t.forbice.minimo, 90);
      expect(t.forbice.massimo, 110);
      expect(t.importi, 5);
      expect(t.fonti, ['a.it', 'b.com']);
    });

    test('gli importi fuori scala si scartano', () {
      final t = forbiceDaFonti({
        'a.it': [80, 100, 120, 5, 90000],
        'b.com': [90, 110],
      }, l)!;
      expect(t.importi, 5); // 5 € e 90.000 € non contano
      expect(t.forbice.minimo, 90);
    });

    test('pochi importi: non affidabile', () {
      expect(
        forbiceDaFonti({
          'a.it': [80, 100],
          'b.com': [90, 110],
        }, l),
        isNull,
      );
    });

    test('un solo sito: non affidabile', () {
      expect(
        forbiceDaFonti({
          'a.it': [80, 90, 100, 110, 120, 130],
        }, l),
        isNull,
      );
    });

    test('forbice troppo larga o schiacciata: non affidabile', () {
      expect(
        forbiceDaFonti({
          'a.it': [20, 20, 25],
          'b.com': [2500, 2800, 3000],
        }, l),
        isNull,
      );
      expect(
        forbiceDaFonti({
          'a.it': [100, 100, 100],
          'b.com': [100, 100],
        }, l),
        isNull,
      );
    });

    test('il sito si legge dall\'indirizzo, senza www', () {
      expect(sitoDi('https://www.esempio.it/tariffe?x=1'), 'esempio.it');
      expect(sitoDi('https://blog.esempio.com/a'), 'blog.esempio.com');
    });
  });

  group('Client Tavily', () {
    String corpo(List<Map<String, String>> risultati) =>
        jsonEncode({'results': risultati});

    final buoni = corpo([
      {
        'url': 'https://www.uno.it/a',
        'title': 'Tariffe doppiatori',
        'content': 'Un audiolibro costa da 80 a 120 euro. Spot: 100 €',
      },
      {
        'url': 'https://due.com/b',
        'title': 'Quanto costa una voce',
        'content': 'In media 90 € per un testo breve e €110 per uno lungo',
      },
    ]);

    test('manda la domanda giusta, con la chiave, in modalità basic', () async {
      late http.Request vista;
      final ricerca = RicercaTavily(
        client: MockClient((r) async {
          vista = r;
          return utf8Response(buoni, 200);
        }),
      );
      final esito = await ricerca.cerca(
        TipoLavoro.doppiaggio,
        chiave: 'tvly-prova',
      );

      expect(vista.method, 'POST');
      expect(vista.url.toString(), 'https://api.tavily.com/search');
      expect(vista.headers['Authorization'], 'Bearer tvly-prova');
      final corpoInviato = jsonDecode(vista.body) as Map;
      expect(corpoInviato['search_depth'], 'basic');
      expect(corpoInviato['query'], contains('doppiatore'));
      expect(corpoInviato['include_answer'], false);

      expect(esito, isA<RicercaTrovata>());
      final t = (esito as RicercaTrovata).trovata;
      expect(t.fonti, ['due.com', 'uno.it']);
      expect(t.forbice.minimo, lessThan(t.forbice.massimo));
      expect(esito.consumaCredito, isTrue);
    });

    test(
      'risposta senza numeri utili: non affidabile (usa un credito)',
      () async {
        final ricerca = RicercaTavily(
          client: MockClient(
            (_) async => http.Response(
              corpo([
                {
                  'url': 'https://uno.it',
                  'title': 'Ciao',
                  'content': 'Niente prezzi',
                },
              ]),
              200,
            ),
          ),
        );
        final esito = await ricerca.cerca(TipoLavoro.codice, chiave: 'k');
        expect(esito, isA<RicercaNonAffidabile>());
        expect(esito.consumaCredito, isTrue);
      },
    );

    test('errori: chiave, troppe richieste, crediti finiti, altro', () async {
      Future<RisultatoRicerca> con(int codice) => RicercaTavily(
        client: MockClient((_) async => http.Response('{}', codice)),
      ).cerca(TipoLavoro.codice, chiave: 'k');

      final chiave = await con(401) as RicercaFallita;
      expect(chiave.serveChiave, isTrue);
      expect(chiave.consumaCredito, isFalse);
      expect((await con(429) as RicercaFallita).messaggio, contains('Troppe'));
      expect((await con(432) as RicercaFallita).messaggio, contains('crediti'));
      expect((await con(433) as RicercaFallita).messaggio, contains('crediti'));
      expect((await con(500) as RicercaFallita).messaggio, contains('500'));
    });

    test('senza internet lo dice e non usa crediti', () async {
      final ricerca = RicercaTavily(
        client: MockClient((_) async => throw http.ClientException('offline')),
      );
      final esito = await ricerca.cerca(TipoLavoro.claude, chiave: 'k');
      expect(esito, isA<RicercaFallita>());
      expect((esito as RicercaFallita).messaggio, contains('internet'));
    });

    test('tipi senza ricerca (Altro) non chiamano Tavily', () async {
      var chiamato = false;
      final ricerca = RicercaTavily(
        client: MockClient((_) async {
          chiamato = true;
          return http.Response('{}', 200);
        }),
      );
      final esito = await ricerca.cerca(TipoLavoro.altro, chiave: 'k');
      expect(esito, isA<RicercaFallita>());
      expect(chiamato, isFalse);
    });
  });
}
