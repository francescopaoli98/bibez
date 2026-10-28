import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantovalgo/modelli/cliente.dart';
import 'package:quantovalgo/modelli/lavoro.dart';
import 'package:quantovalgo/modelli/tipi.dart';

import 'finti.dart';

// Mercoledì 28 ottobre 2026: "oggi" fisso per tutti i test
DateTime oggi() => DateTime(2026, 10, 28, 10);

void schermoAlto(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 4200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> tocca(WidgetTester tester, Finder cosa) async {
  await tester.tap(cosa);
  await tester.pumpAndSettle();
}

/// Un progetto da [prezzo] euro, con i dati di pagamento che servono al test.
String progetto(
  FintoArchivio a,
  String nome, {
  double prezzo = 200,
  String? clienteId,
  DateTime? scadenza,
  DateTime? richiesto,
  DateTime? incasso,
}) => a.salvaLavoro(
  Lavoro(
    id: '',
    nome: nome,
    tipo: TipoLavoro.altro,
    clienteId: clienteId,
    relazione: Relazione.nuovo,
    livello: 3,
    prezzoPieno: prezzo,
    prezzoFinale: prezzo,
    statoPagamento: incasso == null
        ? StatoPagamento.daIncassare
        : StatoPagamento.incassato,
    scadenza: scadenza,
    richiestoIl: richiesto,
    dataIncasso: incasso,
    creatoIl: DateTime(2026, 10, 1),
  ),
);

Lavoro nelDatabase(FintoArchivio a, String nome) =>
    a.tabellaLavori.elenco.firstWhere((l) => l.nome == nome);

void main() {
  group('Scheda Pagamento del progetto', () {
    testWidgets('Segna incassato, poi Annulla riporta a da incassare', (
      tester,
    ) async {
      schermoAlto(tester);
      final archivio = FintoArchivio();
      progetto(archivio, 'Spot', scadenza: DateTime(2026, 11, 10));
      await avviaApp(tester, archivio: archivio, adesso: oggi);

      await tocca(tester, find.text('Spot'));
      expect(find.text('Da incassare'), findsOneWidget);

      await tocca(tester, find.text('Segna incassato'));
      final l = nelDatabase(archivio, 'Spot');
      expect(l.statoPagamento, StatoPagamento.incassato);
      expect(l.dataIncasso, DateTime(2026, 10, 28));
      expect(find.text('Incassato'), findsOneWidget);
      expect(
        find.textContaining('Incassato il 28 ottobre 2026'),
        findsOneWidget,
      );

      await tocca(tester, find.text('Annulla'));
      final dopo = nelDatabase(archivio, 'Spot');
      expect(dopo.statoPagamento, StatoPagamento.daIncassare);
      expect(dopo.dataIncasso, isNull);
    });

    testWidgets('In ritardo: la pillola dice di quanti giorni', (tester) async {
      schermoAlto(tester);
      final archivio = FintoArchivio();
      progetto(archivio, 'Spot', scadenza: DateTime(2026, 10, 10));
      await avviaApp(tester, archivio: archivio, adesso: oggi);

      await tocca(tester, find.text('Spot'));
      expect(find.text('In ritardo di 18 giorni'), findsOneWidget);
    });

    testWidgets('Scadenza: scorciatoia, nessuna, e "Riporta a da incassare"', (
      tester,
    ) async {
      schermoAlto(tester);
      final archivio = FintoArchivio();
      progetto(archivio, 'Spot');
      await avviaApp(tester, archivio: archivio, adesso: oggi);

      await tocca(tester, find.text('Spot'));
      expect(find.text('Nessuna scadenza'), findsOneWidget);

      await tocca(tester, find.byKey(const Key('scadenza-7')));
      expect(nelDatabase(archivio, 'Spot').scadenza, DateTime(2026, 11, 4));
      expect(find.text('Scadenza: 4 novembre 2026'), findsOneWidget);

      await tocca(tester, find.byKey(const Key('scadenza-nessuna')));
      expect(nelDatabase(archivio, 'Spot').scadenza, isNull);

      // Incassato e poi riaperto
      await tocca(tester, find.text('Segna incassato'));
      await tocca(tester, find.text('Riporta a da incassare'));
      expect(
        nelDatabase(archivio, 'Spot').statoPagamento,
        StatoPagamento.daIncassare,
      );
    });

    testWidgets('Giorni impiegati a pagare, dal giorno della richiesta', (
      tester,
    ) async {
      schermoAlto(tester);
      final archivio = FintoArchivio();
      progetto(
        archivio,
        'Spot',
        richiesto: DateTime(2026, 10, 1),
        incasso: DateTime(2026, 10, 11),
      );
      await avviaApp(tester, archivio: archivio, adesso: oggi);

      await tocca(tester, find.text('Spot'));
      expect(find.textContaining('pagato dopo 10 giorni'), findsOneWidget);
      expect(find.text('Richiesto il 1 ottobre 2026'), findsOneWidget);
    });
  });

  group('Da incassare e Clienti', () {
    testWidgets('La pagina Da incassare mette prima chi è in ritardo', (
      tester,
    ) async {
      schermoAlto(tester);
      final archivio = FintoArchivio();
      progetto(archivio, 'Alfa', scadenza: DateTime(2026, 11, 20));
      progetto(archivio, 'Beta', scadenza: DateTime(2026, 10, 10));
      await avviaApp(tester, archivio: archivio, adesso: oggi);

      await tocca(tester, find.text('Clienti'));
      expect(find.text('2 lavori · 1 in ritardo'), findsOneWidget);
      await tocca(tester, find.text('Vedi'));

      expect(find.text('Da incassare'), findsWidgets);
      expect(
        tester.getTopLeft(find.text('Beta')).dy,
        lessThan(tester.getTopLeft(find.text('Alfa')).dy),
      );

      // Un tocco sul segno di spunta incassa subito
      await tocca(tester, find.bySemanticsLabel('Segna incassato Beta'));
      expect(
        nelDatabase(archivio, 'Beta').statoPagamento,
        StatoPagamento.incassato,
      );
      expect(find.text('1 lavoro'), findsOneWidget);
    });

    testWidgets('Clienti: media giorni, migliori, ritardatari e messaggio', (
      tester,
    ) async {
      schermoAlto(tester);
      String? copiato;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (chiamata) async {
          if (chiamata.method == 'Clipboard.setData') {
            copiato = (chiamata.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      final archivio = FintoArchivio();
      final luca = archivio.salvaCliente(
        Cliente(
          id: '',
          nome: 'Luca',
          relazione: Relazione.nuovo,
          creatoIl: DateTime(2026),
        ),
      );
      progetto(
        archivio,
        'Radio',
        prezzo: 300,
        clienteId: luca,
        richiesto: DateTime(2026, 10, 1),
        incasso: DateTime(2026, 10, 11),
      );
      progetto(
        archivio,
        'Spot',
        clienteId: luca,
        scadenza: DateTime(2026, 10, 10),
      );
      await avviaApp(tester, archivio: archivio, adesso: oggi);

      await tocca(tester, find.text('Clienti'));
      expect(find.text('Pagano in media'), findsOneWidget);
      expect(find.text('10 giorni'), findsOneWidget);
      expect(find.text('I migliori'), findsOneWidget);
      expect(find.text('Paga in media in 10 giorni'), findsOneWidget);
      expect(find.text('Ritardatari'), findsOneWidget);
      expect(
        find.text('1 lavoro in ritardo · fino a 18 giorni'),
        findsOneWidget,
      );

      await tocca(tester, find.text('Copia promemoria'));
      expect(
        copiato,
        'Ciao Luca, ti ricordo il pagamento di «Spot»: 200 € '
        '(scaduto il 10 ottobre 2026). Grazie!',
      );
      expect(
        find.text('Messaggio copiato: incollalo dove vuoi'),
        findsOneWidget,
      );
    });

    testWidgets('Senza ritardi non compaiono i Ritardatari', (tester) async {
      schermoAlto(tester);
      final archivio = FintoArchivio();
      progetto(archivio, 'Spot', scadenza: DateTime(2026, 11, 20));
      await avviaApp(tester, archivio: archivio, adesso: oggi);

      await tocca(tester, find.text('Clienti'));
      expect(find.text('Ritardatari'), findsNothing);
      expect(find.text('I migliori'), findsNothing);
      expect(find.text('—'), findsOneWidget); // nessuno ha ancora pagato
    });
  });

  group('Promemoria', () {
    testWidgets('Si programmano con la scadenza e spariscono se incassi', (
      tester,
    ) async {
      schermoAlto(tester);
      final archivio = FintoArchivio();
      final finto = FintoPromemoria();
      progetto(archivio, 'Spot', scadenza: DateTime(2026, 11, 5));
      await avviaApp(
        tester,
        archivio: archivio,
        adesso: oggi,
        promemoria: finto,
      );

      expect(finto.programmati, isNotEmpty);
      expect(finto.programmati.first.quando, DateTime(2026, 11, 4, 9));
      expect(finto.permessiChiesti, 1);

      await tocca(tester, find.text('Spot'));
      await tocca(tester, find.text('Segna incassato'));
      expect(finto.programmati, isEmpty);
      // Il permesso si chiede una sola volta
      expect(finto.permessiChiesti, 1);
    });

    testWidgets('Senza scadenze non chiede il permesso né programma nulla', (
      tester,
    ) async {
      schermoAlto(tester);
      final archivio = FintoArchivio();
      final finto = FintoPromemoria();
      progetto(archivio, 'Spot');
      await avviaApp(
        tester,
        archivio: archivio,
        adesso: oggi,
        promemoria: finto,
      );

      expect(finto.permessiChiesti, 0);
      expect(finto.programmati, isEmpty);
    });

    testWidgets('L\'interruttore in Impostazioni li spegne e li riaccende', (
      tester,
    ) async {
      schermoAlto(tester);
      final archivio = FintoArchivio();
      final finto = FintoPromemoria();
      progetto(archivio, 'Spot', scadenza: DateTime(2026, 11, 5));
      await avviaApp(
        tester,
        archivio: archivio,
        adesso: oggi,
        promemoria: finto,
      );
      expect(finto.programmati, isNotEmpty);

      await tocca(tester, find.bySemanticsLabel('Impostazioni'));
      expect(find.text('Promemoria pagamenti'), findsOneWidget);

      await tocca(tester, find.byKey(const Key('interruttore-promemoria')));
      expect(archivio.impostazioniSalvate.promemoria, isFalse);
      expect(finto.programmati, isEmpty);

      await tocca(tester, find.byKey(const Key('interruttore-promemoria')));
      expect(archivio.impostazioniSalvate.promemoria, isTrue);
      expect(finto.programmati, isNotEmpty);
    });
  });
}
