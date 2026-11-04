import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantovalgo/modelli/cliente.dart';
import 'package:quantovalgo/modelli/lavoro.dart';
import 'package:quantovalgo/modelli/preventivo.dart';
import 'package:quantovalgo/modelli/sottoprogetto.dart';
import 'package:quantovalgo/modelli/tipi.dart';
import 'package:quantovalgo/schermate/preventivo_anteprima.dart';

import 'finti.dart';

// Mercoledì 28 ottobre 2026: "oggi" fisso per tutti i test
DateTime oggi() => DateTime(2026, 10, 28, 10);

void schermoAlto(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 5200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> tocca(WidgetTester tester, Finder cosa) async {
  await tester.tap(cosa);
  await tester.pumpAndSettle();
}

Future<void> scrivi(WidgetTester tester, String chiave, String testo) async {
  await tester.enterText(
    find.descendant(
      of: find.byKey(Key(chiave)),
      matching: find.byType(TextField),
    ),
    testo,
  );
  await tester.pump();
}

/// Il PNG vero non si fa nei test: tre byte finti al suo posto.
void catturaFinta() {
  catturaPng = (_) async => Uint8List.fromList([1, 2, 3]);
  addTearDown(
    () => catturaPng = (_) => throw StateError('cattura non prevista'),
  );
}

/// Sito vetrina per Luca: 1.000 € di listino, 700 € dopo lo sconto amico.
FintoArchivio conLavoro() {
  final a = FintoArchivio();
  final luca = a.salvaCliente(
    Cliente(
      id: '',
      nome: 'Luca',
      relazione: Relazione.amico,
      creatoIl: DateTime(2026, 1, 1),
    ),
  );
  final id = a.salvaLavoro(
    Lavoro(
      id: '',
      nome: 'Sito vetrina',
      tipo: TipoLavoro.codice,
      clienteId: luca,
      relazione: Relazione.amico,
      livello: 3,
      prezzoPieno: 1000,
      prezzoFinale: 700,
      creatoIl: DateTime(2026, 10, 1),
    ),
  );
  a.salvaSottoprogetto(
    Sottoprogetto(
      id: '',
      lavoroId: id,
      nome: 'Lavoro intero',
      ricavo: 700,
      costiDiretti: 0,
      ore: 0,
      creatoIl: DateTime(2026, 10, 1),
    ),
  );
  return a;
}

/// Dal menu: Preventivi → Nuovo preventivo → il lavoro → le domande.
Future<void> apriDomande(WidgetTester tester) async {
  await apriDalMenu(tester, 'Preventivi');
  await tocca(tester, find.byKey(const Key('nuovo-preventivo')));
  await tocca(tester, find.byKey(const Key('per-lavoro-Sito vetrina')));
}

void main() {
  testWidgets('Senza preventivi né lavori: elenco vuoto e un invito', (
    tester,
  ) async {
    schermoAlto(tester);
    await avviaApp(tester, adesso: oggi);
    await apriDalMenu(tester, 'Preventivi');
    expect(find.text('Nessun preventivo'), findsOneWidget);

    await tocca(tester, find.byKey(const Key('nuovo-preventivo')));
    expect(
      find.text('Prima crea un lavoro: il preventivo parte da lì.'),
      findsOneWidget,
    );
  });

  testWidgets('"A giornata" non ha preventivo', (tester) async {
    schermoAlto(tester);
    final a = FintoArchivio();
    a.salvaLavoro(
      Lavoro(
        id: '',
        nome: 'Negozio',
        tipo: TipoLavoro.aGiornata,
        relazione: Relazione.nuovo,
        livello: 3,
        prezzoPieno: 0,
        prezzoFinale: 0,
        tariffaGiornaliera: 30,
        creatoIl: DateTime(2026, 10, 1),
      ),
    );
    await avviaApp(tester, archivio: a, adesso: oggi);
    await apriDalMenu(tester, 'Preventivi');
    await tocca(tester, find.byKey(const Key('nuovo-preventivo')));
    expect(find.byKey(const Key('per-lavoro-Negozio')), findsNothing);
    expect(
      find.text('Prima crea un lavoro: il preventivo parte da lì.'),
      findsOneWidget,
    );
  });

  group('Domande e anteprima', () {
    testWidgets('Le risposte di partenza compongono il testo e il prezzo', (
      tester,
    ) async {
      schermoAlto(tester);
      await avviaApp(tester, archivio: conLavoro(), adesso: oggi);
      await apriDomande(tester);

      expect(find.text('Cosa scrivo?'), findsOneWidget);
      await tocca(tester, find.text('Vedi il preventivo'));

      // Stile App: i titoli del brief
      expect(find.text('PROGETTO'), findsOneWidget);
      expect(find.text('COME LAVORO'), findsOneWidget);
      expect(find.text('COSA CI GUADAGNI'), findsOneWidget);
      expect(
        find.text('Per Luca: Sito vetrina. Consegna in 1 settimana.'),
        findsOneWidget,
      );
      expect(find.text('Sviluppo'), findsOneWidget);
      expect(find.text('Messa online e consegna'), findsOneWidget);
      expect(
        find.text('Assistenza dopo la consegna'),
        findsNothing,
      ); // solo i primi due vantaggi
      expect(find.text('Un lavoro chiaro e semplice da usare'), findsOneWidget);
      // Prezzo: 1.000 → −30% → 700 €
      expect(find.text('Prezzo pieno'), findsOneWidget);
      expect(find.text('1.000 €'), findsOneWidget);
      expect(find.text('Sconto −30%'), findsOneWidget);
      expect(find.text('−300 €'), findsOneWidget);
      expect(find.text('Totale'), findsOneWidget);
      expect(find.text('700 €'), findsOneWidget);
    });

    testWidgets('I quattro stili hanno i loro titoli', (tester) async {
      schermoAlto(tester);
      await avviaApp(tester, archivio: conLavoro(), adesso: oggi);
      await apriDomande(tester);
      await tocca(tester, find.text('Vedi il preventivo'));

      await tocca(tester, find.byKey(const Key('stile-professionale')));
      expect(find.text('Progetto'), findsOneWidget);
      expect(find.text('Modalità di lavoro'), findsOneWidget);
      expect(find.text('Vantaggi per te'), findsOneWidget);
      expect(find.text('PROGETTO'), findsNothing);

      await tocca(tester, find.byKey(const Key('stile-informatico')));
      expect(find.text('// progetto'), findsOneWidget);
      expect(find.text('// metodo'), findsOneWidget);
      expect(find.text('// benefit'), findsOneWidget);
      expect(find.text('total = 700 €'), findsOneWidget);

      await tocca(tester, find.byKey(const Key('stile-gaming')));
      expect(find.text('MISSIONE'), findsOneWidget);
      expect(find.text('STRATEGIA'), findsOneWidget);
      expect(find.text('BOTTINO'), findsOneWidget);
      expect(find.text('PREZZO FINALE'), findsOneWidget);

      await tocca(tester, find.byKey(const Key('stile-app')));
      expect(find.text('COME LAVORO'), findsOneWidget);
    });

    testWidgets('Si tolgono voci, se ne aggiungono e si cambia la consegna', (
      tester,
    ) async {
      schermoAlto(tester);
      await avviaApp(tester, archivio: conLavoro(), adesso: oggi);
      await apriDomande(tester);

      // Tolgo una fase pronta, ne aggiungo una mia
      await tocca(tester, find.byKey(const Key('fase-Prove e correzioni')));
      await scrivi(tester, 'campo-nuova-fase', 'Formazione di un\'ora');
      await tocca(tester, find.bySemanticsLabel('Aggiungi fase'));
      // Un vantaggio mio e uno pronto in più
      await tocca(
        tester,
        find.byKey(const Key('benefit-Assistenza dopo la consegna')),
      );
      await scrivi(tester, 'campo-nuovo-benefit', 'Ti rispondo sempre');
      await tocca(tester, find.bySemanticsLabel('Aggiungi vantaggio'));
      // Consegna a scelta rapida
      await tocca(tester, find.byKey(const Key('consegna-2 settimane')));
      await scrivi(tester, 'campo-progetto', 'Sito per il ristorante');

      await tocca(tester, find.text('Vedi il preventivo'));
      expect(
        find.text('Per Luca: Sito per il ristorante. Consegna in 2 settimane.'),
        findsOneWidget,
      );
      expect(find.text('Prove e correzioni'), findsNothing);
      expect(find.text('Formazione di un\'ora'), findsOneWidget);
      expect(find.text('Assistenza dopo la consegna'), findsOneWidget);
      expect(find.text('Ti rispondo sempre'), findsOneWidget);
    });
  });

  group('Salvare e condividere', () {
    testWidgets(
      'Salva PNG: va in galleria e il preventivo entra nell\'elenco',
      (tester) async {
        schermoAlto(tester);
        catturaFinta();
        final archivio = conLavoro();
        final esportazione = FintaEsportazione();
        await avviaApp(
          tester,
          archivio: archivio,
          adesso: oggi,
          esportazione: esportazione,
        );
        await apriDomande(tester);
        await tocca(tester, find.text('Vedi il preventivo'));
        await tocca(tester, find.byKey(const Key('stile-gaming')));

        await tocca(tester, find.text('Salva PNG'));
        expect(
          esportazione.salvati.single.nome,
          'preventivo-sito-vetrina-2026-10-28',
        );
        expect(esportazione.salvati.single.byte, 3);
        expect(find.text('Salvato nella galleria'), findsOneWidget);

        final p = archivio.tabellaPreventivi.elenco.single;
        expect(p.lavoroId, archivio.tabellaLavori.elenco.single.id);
        expect(p.cliente, 'Luca');
        expect(p.stile, StilePreventivo.gaming);
        expect(p.prezzoPieno, 1000);
        expect(p.prezzoFinale, 700);
        expect(p.consegna, '1 settimana');
        expect(p.fasi.first, 'Capiamo insieme cosa ti serve');

        // Cambiando stile e salvando ancora si aggiorna lo stesso preventivo
        await tocca(tester, find.byKey(const Key('stile-informatico')));
        await tocca(tester, find.text('Salva PNG'));
        expect(archivio.tabellaPreventivi.elenco, hasLength(1));
        expect(
          archivio.tabellaPreventivi.elenco.single.stile,
          StilePreventivo.informatico,
        );
        expect(esportazione.salvati, hasLength(2));
      },
    );

    testWidgets('Condividi: apre la condivisione con un testo breve', (
      tester,
    ) async {
      schermoAlto(tester);
      catturaFinta();
      final archivio = conLavoro();
      final esportazione = FintaEsportazione();
      await avviaApp(
        tester,
        archivio: archivio,
        adesso: oggi,
        esportazione: esportazione,
      );
      await apriDomande(tester);
      await tocca(tester, find.text('Vedi il preventivo'));

      await tocca(tester, find.text('Condividi'));
      expect(
        esportazione.condivisi.single.testo,
        'Preventivo «Sito vetrina»: 700 €',
      );
      expect(esportazione.condivisi.single.byte, 3);
      expect(archivio.tabellaPreventivi.elenco, hasLength(1));
    });

    testWidgets('Senza permesso lo dice e non salva nulla', (tester) async {
      schermoAlto(tester);
      catturaFinta();
      final archivio = conLavoro();
      final esportazione = FintaEsportazione()..permessoConcesso = false;
      await avviaApp(
        tester,
        archivio: archivio,
        adesso: oggi,
        esportazione: esportazione,
      );
      await apriDomande(tester);
      await tocca(tester, find.text('Vedi il preventivo'));

      await tocca(tester, find.text('Salva PNG'));
      expect(
        find.textContaining('Non sono riuscito a salvarlo'),
        findsOneWidget,
      );
      expect(archivio.tabellaPreventivi.elenco, isEmpty);
    });

    testWidgets('Il miglioramento con l\'AI c\'è ma è spento', (tester) async {
      schermoAlto(tester);
      await avviaApp(tester, archivio: conLavoro(), adesso: oggi);
      await apriDomande(tester);
      await tocca(tester, find.text('Vedi il preventivo'));

      expect(find.text('Migliora il testo con l\'AI'), findsOneWidget);
      expect(find.textContaining('Non parte mai da solo'), findsOneWidget);
    });
  });

  group('Elenco e lavoro', () {
    testWidgets('Un preventivo fatto si riapre, si rivede e si elimina', (
      tester,
    ) async {
      schermoAlto(tester);
      catturaFinta();
      final archivio = conLavoro();
      await avviaApp(
        tester,
        archivio: archivio,
        adesso: oggi,
        esportazione: FintaEsportazione(),
      );
      await apriDomande(tester);
      await tocca(tester, find.text('Vedi il preventivo'));
      await tocca(tester, find.text('Salva PNG'));
      await tornaAllaHome(tester);

      // Il tassello del menu lo conta
      await tester.tap(find.bySemanticsLabel('Altro'));
      await tester.pumpAndSettle();
      expect(find.text('1 fatti'), findsOneWidget);
      await tocca(tester, find.text('Preventivi'));
      expect(find.text('Luca · 700 € · 28 ottobre 2026 · App'), findsOneWidget);

      // Si riapre l'anteprima e si possono cambiare le risposte
      await tocca(tester, find.text('Sito vetrina'));
      expect(find.text('PROGETTO'), findsOneWidget);
      await tocca(tester, find.byKey(const Key('cambia-risposte')));
      expect(find.text('Cosa scrivo?'), findsOneWidget);
      await tocca(tester, find.byKey(const Key('consegna-1 mese')));
      await tocca(tester, find.text('Vedi il preventivo'));
      expect(
        find.text('Per Luca: Sito vetrina. Consegna in 1 mese.'),
        findsOneWidget,
      );
      await tocca(tester, find.text('Salva PNG'));
      expect(archivio.tabellaPreventivi.elenco, hasLength(1)); // aggiornato
      expect(archivio.tabellaPreventivi.elenco.single.consegna, '1 mese');

      // Eliminazione dall'elenco, con conferma
      await tornaAllaHome(tester);
      await apriDalMenu(tester, 'Preventivi');
      await tocca(
        tester,
        find.bySemanticsLabel('Elimina il preventivo Sito vetrina'),
      );
      await tocca(tester, find.widgetWithText(TextButton, 'Elimina'));
      expect(archivio.tabellaPreventivi.elenco, isEmpty);
      expect(find.text('Nessun preventivo'), findsOneWidget);
    });

    testWidgets('Dal lavoro si fa il preventivo con una riga', (tester) async {
      schermoAlto(tester);
      await avviaApp(tester, archivio: conLavoro(), adesso: oggi);
      await apriLavoroPerNome(tester, 'Sito vetrina', dettagli: false);

      await tocca(tester, find.byKey(const Key('fai-preventivo')));
      expect(find.text('Cosa scrivo?'), findsOneWidget);
      // Già compilato con il lavoro
      final progetto = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const Key('campo-progetto')),
          matching: find.byType(TextField),
        ),
      );
      expect(progetto.controller!.text, 'Sito vetrina');
    });

    testWidgets('Eliminando il lavoro spariscono anche i suoi preventivi', (
      tester,
    ) async {
      schermoAlto(tester);
      catturaFinta();
      final archivio = conLavoro();
      await avviaApp(
        tester,
        archivio: archivio,
        adesso: oggi,
        esportazione: FintaEsportazione(),
      );
      await apriDomande(tester);
      await tocca(tester, find.text('Vedi il preventivo'));
      await tocca(tester, find.text('Condividi'));
      expect(archivio.tabellaPreventivi.elenco, hasLength(1));
      await tornaAllaHome(tester);

      await apriLavoroPerNome(tester, 'Sito vetrina');
      await tocca(tester, find.text('Elimina progetto'));
      await tocca(tester, find.widgetWithText(TextButton, 'Elimina'));
      expect(archivio.tabellaLavori.elenco, isEmpty);
      expect(archivio.tabellaPreventivi.elenco, isEmpty);
    });
  });
}
