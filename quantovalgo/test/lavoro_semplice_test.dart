import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantovalgo/modelli/costo.dart';
import 'package:quantovalgo/modelli/lavoro.dart';
import 'package:quantovalgo/modelli/sottoprogetto.dart';
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

/// Un lavoro da 800 € per Luca, scaduto il 10 ottobre, con le parti indicate
/// come `(nome, ricavo, ore)`.
String lavoro(
  FintoArchivio a, {
  List<(String, double, double)> parti = const [('Sviluppo', 800, 12)],
  StatoPagamento stato = StatoPagamento.daIncassare,
  DateTime? scadenza,
}) {
  final id = a.salvaLavoro(
    Lavoro(
      id: '',
      nome: 'Sito vetrina',
      tipo: TipoLavoro.codice,
      relazione: Relazione.nuovo,
      livello: 3,
      prezzoPieno: 800,
      prezzoFinale: 800,
      statoPagamento: stato,
      dataIncasso: stato == StatoPagamento.incassato
          ? DateTime(2026, 10, 12)
          : null,
      scadenza: scadenza ?? DateTime(2026, 10, 10),
      richiestoIl: DateTime(2026, 10, 1),
      creatoIl: DateTime(2026, 10, 1),
    ),
  );
  for (final p in parti) {
    a.salvaSottoprogetto(
      Sottoprogetto(
        id: '',
        lavoroId: id,
        nome: p.$1,
        ricavo: p.$2,
        costiDiretti: 0,
        ore: p.$3,
        creatoIl: DateTime(2026, 10, 1),
      ),
    );
  }
  return id;
}

void main() {
  group('Un lavoro in una vista', () {
    testWidgets('Quanto ti devono, in ritardo, e un solo pulsante', (
      tester,
    ) async {
      schermoAlto(tester);
      final archivio = FintoArchivio();
      lavoro(archivio);
      await avviaApp(tester, archivio: archivio, adesso: oggi);
      await apriLavoroPerNome(tester, 'Sito vetrina', dettagli: false);

      expect(find.text('Ti devono'), findsOneWidget);
      expect(find.text('800 €'), findsOneWidget);
      expect(find.text('In ritardo di 18 giorni'), findsOneWidget);
      expect(find.text('Scadeva il 10 ottobre 2026'), findsOneWidget);
      expect(find.text('Mi hanno pagato'), findsOneWidget);
    });

    testWidgets(
      '"Mi hanno pagato" incassa, con Annulla; poi si può riportare',
      (tester) async {
        schermoAlto(tester);
        final archivio = FintoArchivio();
        lavoro(archivio);
        await avviaApp(tester, archivio: archivio, adesso: oggi);
        await apriLavoroPerNome(tester, 'Sito vetrina', dettagli: false);

        await tocca(tester, find.text('Mi hanno pagato'));
        final l = archivio.tabellaLavori.elenco.single;
        expect(l.statoPagamento, StatoPagamento.incassato);
        expect(l.dataIncasso, DateTime(2026, 10, 28));
        expect(find.text('Incassato'), findsWidgets);
        expect(
          find.textContaining('Incassato il 28 ottobre 2026'),
          findsOneWidget,
        );
        expect(find.text('Mi hanno pagato'), findsNothing);

        // L'Annulla della barretta riporta tutto com'era
        await tocca(tester, find.text('Annulla'));
        expect(
          archivio.tabellaLavori.elenco.single.statoPagamento,
          StatoPagamento.daIncassare,
        );
        expect(find.text('Mi hanno pagato'), findsOneWidget);

        // Incassato di nuovo, poi riportato a mano
        await tocca(tester, find.text('Mi hanno pagato'));
        await tocca(tester, find.text('Riporta a da incassare'));
        expect(
          archivio.tabellaLavori.elenco.single.statoPagamento,
          StatoPagamento.daIncassare,
        );
      },
    );

    testWidgets(
      'Un lavoro già incassato mostra quanto ci ha messo il cliente',
      (tester) async {
        schermoAlto(tester);
        final archivio = FintoArchivio();
        lavoro(archivio, stato: StatoPagamento.incassato);
        await avviaApp(tester, archivio: archivio, adesso: oggi);
        await apriLavoroPerNome(tester, 'Sito vetrina', dettagli: false);

        expect(
          find.text('Incassato il 12 ottobre 2026 · pagato dopo 11 giorni'),
          findsOneWidget,
        );
        expect(find.text('Cambia la scadenza'), findsNothing);
      },
    );

    testWidgets('Cambia la scadenza da un foglio', (tester) async {
      schermoAlto(tester);
      final archivio = FintoArchivio();
      lavoro(archivio);
      await avviaApp(tester, archivio: archivio, adesso: oggi);
      await apriLavoroPerNome(tester, 'Sito vetrina', dettagli: false);

      await tocca(tester, find.byKey(const Key('cambia-scadenza')));
      await tocca(tester, find.byKey(const Key('scadenza-7')));
      expect(
        archivio.tabellaLavori.elenco.single.scadenza,
        DateTime(2026, 11, 4),
      );
      expect(find.text('Scade il 4 novembre 2026'), findsOneWidget);
      expect(find.text('In ritardo di 18 giorni'), findsNothing);
    });

    testWidgets('Ore e "Ti resta": cifre vere e cronometro con un tocco', (
      tester,
    ) async {
      schermoAlto(tester);
      final archivio = FintoArchivio();
      lavoro(archivio);
      await avviaApp(tester, archivio: archivio, adesso: oggi);
      await apriLavoroPerNome(tester, 'Sito vetrina', dettagli: false);

      expect(find.text('12 h'), findsOneWidget);
      expect(find.text('+800 €'), findsOneWidget);
      expect(find.text('circa 67 € all\'ora'), findsOneWidget);

      await tocca(tester, find.text('Avvia'));
      expect(archivio.tabellaSessioni.elenco.single.inCorso, isTrue);
      expect(find.text('Ferma'), findsOneWidget);

      await tocca(tester, find.text('Ferma'));
      expect(find.text('Avvia'), findsOneWidget);
    });

    testWidgets('Con più parti il cronometro manda a sceglierne una', (
      tester,
    ) async {
      schermoAlto(tester);
      final archivio = FintoArchivio();
      lavoro(
        archivio,
        parti: [('Registrazione', 500, 5), ('Montaggio', 300, 2)],
      );
      await avviaApp(tester, archivio: archivio, adesso: oggi);
      await apriLavoroPerNome(tester, 'Sito vetrina', dettagli: false);

      expect(find.text('7 h'), findsOneWidget);
      await tocca(tester, find.text('Scegli la parte'));
      // Si apre la pagina completa, dove ogni parte ha il suo cronometro
      expect(find.text('Registrazione'), findsOneWidget);
      expect(find.text('Montaggio'), findsOneWidget);
    });

    testWidgets('Senza parti il pulsante dice "Aggiungi" e porta ai dettagli', (
      tester,
    ) async {
      schermoAlto(tester);
      final archivio = FintoArchivio();
      lavoro(archivio, parti: const []);
      await avviaApp(tester, archivio: archivio, adesso: oggi);
      await apriLavoroPerNome(tester, 'Sito vetrina', dettagli: false);

      expect(find.text('senza ore registrate'), findsOneWidget);
      await tocca(tester, find.text('Aggiungi'));
      expect(find.text('Nessun sottoprogetto'), findsOneWidget);
    });

    testWidgets('"Tutti i dettagli" apre la pagina completa', (tester) async {
      schermoAlto(tester);
      final archivio = FintoArchivio();
      lavoro(archivio);
      await avviaApp(tester, archivio: archivio, adesso: oggi);
      await apriLavoroPerNome(tester, 'Sito vetrina', dettagli: false);

      await tocca(tester, find.byKey(const Key('tutti-i-dettagli')));
      expect(find.text('Sottoprogetti'), findsOneWidget);
      expect(find.text('Pagamento'), findsOneWidget);
    });
  });

  group('Menu "Altro"', () {
    testWidgets('Ogni tassello dice già un numero vivo', (tester) async {
      schermoAlto(tester);
      final archivio = FintoArchivio();
      lavoro(archivio);
      archivio.salvaCosto(
        Costo(
          id: '',
          nome: 'Software',
          tipo: TipoCosto.abbonamento,
          importo: 60,
          inizio: DateTime(2026, 10, 1),
          creatoIl: DateTime(2026),
        ),
      );
      await avviaApp(tester, archivio: archivio, adesso: oggi);
      await tocca(tester, find.bySemanticsLabel('Altro'));

      expect(find.text('Cosa cerchi?'), findsOneWidget);
      expect(find.text('1 in tutto'), findsOneWidget);
      expect(find.text('60 € questo mese'), findsOneWidget);
      expect(find.text('da impostare'), findsOneWidget); // obiettivo
      expect(find.text('1 in tutto'), findsOneWidget);
    });
  });
}
