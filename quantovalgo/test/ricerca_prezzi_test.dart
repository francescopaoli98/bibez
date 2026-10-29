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
      expect(importiInEuro('costa 80 € a lavoro'), [80]);
      expect(importiInEuro('Solo €80 a progetto'), [80]);
      expect(importiInEuro('circa 1.200 euro'), [1200]);
      expect(importiInEuro('25,50 € a pagina'), [25.5]);
      expect(importiInEuro('prezzo 25.50 EUR'), [25.5]);
      expect(importiInEuro('1 200 € il pacchetto'), [1200]);
    });

    test('EUR davanti e migliaia all\'inglese (come nei siti stranieri)', () {
      expect(importiInEuro('EUR 500 per sito'), [500]);
      expect(importiInEuro('da EUR 15,000 a 60,000 euro'), [15000, 60000]);
      expect(importiInEuro('costa 1,500 €'), [1500]);
    });

    test('prezzi all\'ora, al mese, all\'anno o al minuto non sono prezzi a lavoro', () {
      expect(importiInEuro('50 € all\'ora'), isEmpty);
      expect(importiInEuro('250 euro/h per le agenzie'), isEmpty);
      expect(importiInEuro('da 30 a 70 euro l\'ora'), isEmpty);
      expect(importiInEuro('100 € mensili di assistenza'), isEmpty);
      expect(importiInEuro('300€ all\'anno di manutenzione'), isEmpty);
      expect(importiInEuro('1 € al minuto'), isEmpty);
      expect(importiInEuro('EUR 40 per hour'), isEmpty);
      // ...ma il prezzo a lavoro nella stessa frase resta
      expect(importiInEuro('sito base 960 euro, poi 50 € all\'ora'), [960]);
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

  group('Domanda personalizzata', () {
    test('aggiunge da sola Italia, prezzo ed euro se mancano', () {
      expect(
        costruisciQuery('assistenza configurazione smartphone'),
        'assistenza configurazione smartphone Italia prezzo euro',
      );
    });

    test('non ripete quello che hai già scritto', () {
      expect(
        costruisciQuery('quanto costa un tablet configurato in Italia, euro'),
        'quanto costa un tablet configurato in Italia, euro',
      );
      expect(
        costruisciQuery('tariffe tecnico a domicilio'),
        'tariffe tecnico a domicilio Italia euro',
      );
    });

    test('spazi e a capo in più si ripuliscono', () {
      expect(
        costruisciQuery('  consulenza   acquisto\nelettronica '),
        'consulenza acquisto elettronica Italia prezzo euro',
      );
    });

    test('ogni tipo ha idee da toccare; Altro non ha domanda di partenza', () {
      for (final t in [
        TipoLavoro.doppiaggio,
        TipoLavoro.codice,
        TipoLavoro.claude,
        TipoLavoro.altro,
      ]) {
        expect(suggerimentiPerTipo[t], isNotEmpty);
      }
      expect(domandaPredefinita.containsKey(TipoLavoro.altro), isFalse);
      expect(tipoCercabile(TipoLavoro.altro), isTrue);
      expect(tipoCercabile(TipoLavoro.aGiornata), isFalse);
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

    test('"Altro" senza domanda non chiama Tavily; con domanda sì', () async {
      var chiamate = 0;
      late http.Request vista;
      final ricerca = RicercaTavily(
        client: MockClient((r) async {
          chiamate++;
          vista = r;
          return utf8Response(buoni, 200);
        }),
      );
      final senza = await ricerca.cerca(TipoLavoro.altro, chiave: 'k');
      expect(senza, isA<RicercaFallita>());
      expect((senza as RicercaFallita).messaggio, contains('Scrivi cosa'));
      expect(chiamate, 0);

      final con = await ricerca.cerca(
        TipoLavoro.altro,
        chiave: 'k',
        domanda: 'configurazione tablet anziani',
      );
      expect(chiamate, 1);
      expect(
        (jsonDecode(vista.body) as Map)['query'],
        'configurazione tablet anziani Italia prezzo euro',
      );
      expect(con, isA<RicercaTrovata>());
      expect(
        (con as RicercaTrovata).trovata.domanda,
        'configurazione tablet anziani Italia prezzo euro',
      );
    });

    test(
      'con una domanda tua usa quella, non quella di partenza del tipo',
      () async {
        late http.Request vista;
        final ricerca = RicercaTavily(
          client: MockClient((r) async {
            vista = r;
            return utf8Response(buoni, 200);
          }),
        );
        await ricerca.cerca(
          TipoLavoro.doppiaggio,
          chiave: 'k',
          domanda: 'voce per centralino telefonico',
        );
        final query = (jsonDecode(vista.body) as Map)['query'] as String;
        expect(query, startsWith('voce per centralino telefonico'));
        expect(query, isNot(contains('audiolibro')));
      },
    );
  });
}
