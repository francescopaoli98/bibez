import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantovalgo/modelli/costo.dart';
import 'package:quantovalgo/modelli/giornata.dart';
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

Future<void> tocca(WidgetTester tester, Finder cosa) async {
  await tester.tap(cosa);
  await tester.pumpAndSettle();
}

/// Il lavoro "Negozio con mamma": 30 € al giorno.
Lavoro negozio() => Lavoro(
  id: '',
  nome: 'Negozio con mamma',
  tipo: TipoLavoro.aGiornata,
  relazione: Relazione.nuovo,
  livello: 3,
  prezzoPieno: 0,
  prezzoFinale: 0,
  tariffaGiornaliera: 30,
  creatoIl: DateTime(2026, 10, 1),
);

Giornata giornata(String lavoroId, DateTime data, [double importo = 30]) =>
    Giornata(
      id: '',
      lavoroId: lavoroId,
      data: data,
      importo: importo,
      creatoIl: DateTime(2026, 10, 1),
    );

void main() {
  testWidgets('Nuovo lavoro "A giornata": solo nome e guadagno al giorno', (
    tester,
  ) async {
    schermoAlto(tester);
    final app = await avviaApp(tester, adesso: oggi);
    await tocca(tester, find.bySemanticsLabel('Nuovo lavoro'));

    await tocca(tester, find.text('A giornata'));
    // I campi dei lavori normali spariscono
    expect(find.text('Il tuo livello'), findsNothing);
    expect(find.text('Prezzo di mercato'), findsNothing);
    expect(find.text('Chi è il cliente?'), findsNothing);
    expect(find.text('Guadagno netto al giorno (€)'), findsOneWidget);

    await scrivi(tester, 'campo-nome', 'Negozio con mamma');
    await tocca(tester, find.text('Salva lavoro'));

    final lavoro = app.archivio.tabellaLavori.elenco.single;
    expect(lavoro.tipo, TipoLavoro.aGiornata);
    expect(lavoro.tariffaGiornaliera, 30); // il valore di partenza
    expect(app.archivio.tabellaSotto.elenco, isEmpty); // nessun "Lavoro intero"

    // Si apre la pagina del progetto, senza giornate
    expect(find.text('A giornata · 30 € al giorno'), findsOneWidget);
    expect(find.text('Nessuna giornata a ottobre'), findsOneWidget);
    expect(find.text('Sottoprogetti'), findsNothing);
  });

  testWidgets('Il guadagno al giorno si può cambiare', (tester) async {
    schermoAlto(tester);
    final app = await avviaApp(tester, adesso: oggi);
    await tocca(tester, find.bySemanticsLabel('Nuovo lavoro'));
    await tocca(tester, find.text('A giornata'));
    await scrivi(tester, 'campo-nome', 'Mercatino');
    await scrivi(tester, 'campo-tariffa', '45,5');
    await tocca(tester, find.text('Salva lavoro'));
    expect(app.archivio.tabellaLavori.elenco.single.tariffaGiornaliera, 45.5);
  });

  testWidgets('Validazione: nome e importo obbligatori', (tester) async {
    schermoAlto(tester);
    final app = await avviaApp(tester, adesso: oggi);
    await tocca(tester, find.bySemanticsLabel('Nuovo lavoro'));
    await tocca(tester, find.text('A giornata'));
    await scrivi(tester, 'campo-tariffa', '0');
    await tocca(tester, find.text('Salva lavoro'));
    expect(find.text('Scrivi il nome del lavoro'), findsOneWidget);
    expect(find.text('Scrivi un importo'), findsOneWidget);
    expect(app.archivio.tabellaLavori.elenco, isEmpty);
  });

  testWidgets(
    'Schema: lun–ven per 5 giorni dal 28 ottobre = 5 giornate, 150 €',
    (tester) async {
      schermoAlto(tester);
      final archivio = FintoArchivio();
      final id = archivio.salvaLavoro(negozio());
      await avviaApp(tester, archivio: archivio, adesso: oggi);

      await tocca(tester, find.text('Negozio con mamma'));
      await tocca(tester, find.text('+ Aggiungi'));

      // Lo schema di partenza (lun–ven, 10 giorni) si adatta a 5
      await scrivi(tester, 'campo-numero-giorni', '5');
      expect(
        find.text('5 giornate · 150 €\ndal 28 ottobre al 3 novembre'),
        findsOneWidget,
      );
      expect(find.text('Aggiungi 5 giornate'), findsOneWidget);

      await tocca(tester, find.text('Aggiungi 5 giornate'));

      final salvate = archivio.tabellaGiornate.elenco
        ..sort((a, b) => a.data.compareTo(b.data));
      expect(
        [for (final g in salvate) '${g.data.day}/${g.data.month}'],
        ['28/10', '29/10', '30/10', '2/11', '3/11'],
      );
      expect(salvate.every((g) => g.importo == 30 && g.lavoroId == id), isTrue);

      // Pagina del progetto: solo il 28 è "fatto" (oggi), gli altri 4 sono in programma
      expect(find.text('+30 €'), findsWidgets); // guadagno netto
      // Nella casella "In programma" del riquadro blu ci sono 4 giornate
      final casella = find.ancestor(
        of: find.text('In programma').first,
        matching: find.byType(Column),
      );
      expect(
        find.descendant(of: casella.first, matching: find.text('4')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Sabato e domenica si escludono; si scelgono solo alcuni giorni',
    (tester) async {
      schermoAlto(tester);
      final archivio = FintoArchivio();
      archivio.salvaLavoro(negozio());
      await avviaApp(tester, archivio: archivio, adesso: oggi);
      await tocca(tester, find.text('Negozio con mamma'));
      await tocca(tester, find.text('+ Aggiungi'));

      // Solo martedì, giovedì e sabato per 3 giorni: gio 29, sab 31, mar 3
      await tocca(tester, find.text('Lun–Ven')); // spegne la scorciatoia
      for (final nome in ['lunedì', 'mercoledì', 'venerdì']) {
        await tocca(
          tester,
          find.bySemanticsLabel(nome),
        ); // toglie lun, mer, ven
      }
      await tocca(tester, find.bySemanticsLabel('sabato')); // aggiunge sabato
      await scrivi(tester, 'campo-numero-giorni', '3');
      expect(
        find.text('3 giornate · 90 €\ndal 29 ottobre al 3 novembre'),
        findsOneWidget,
      );

      await tocca(tester, find.text('Aggiungi 3 giornate'));
      final date = [
        for (final g in archivio.tabellaGiornate.elenco)
          '${g.data.day}/${g.data.month}',
      ]..sort();
      expect(date, ['29/10', '3/11', '31/10']..sort());
    },
  );

  testWidgets('Dal calendario un giorno passa da intero a mezza a tolto', (
    tester,
  ) async {
    schermoAlto(tester);
    final archivio = FintoArchivio();
    archivio.salvaLavoro(negozio());
    await avviaApp(tester, archivio: archivio, adesso: oggi);
    await tocca(tester, find.text('Negozio con mamma'));
    await tocca(tester, find.text('+ Aggiungi'));
    await scrivi(tester, 'campo-numero-giorni', '3'); // 28, 29, 30 ottobre

    // Un tocco sul 29: da intero a mezza giornata (½)
    await tocca(tester, find.bySemanticsLabel('giovedì 29 ottobre, scelto'));
    expect(find.text('½'), findsOneWidget);
    expect(
      find.text('2 intere + 1 mezza · 75 €\ndal 28 ottobre al 30 ottobre'),
      findsOneWidget,
    );
    // Secondo tocco: tolto (il giorno è in ferie)
    await tocca(
      tester,
      find.bySemanticsLabel('giovedì 29 ottobre, scelto, mezza giornata'),
    );
    expect(find.text('½'), findsNothing);
    expect(
      find.text('2 giornate · 60 €\ndal 28 ottobre al 30 ottobre'),
      findsOneWidget,
    );
    // Terzo tocco: ci ripenso, torna intero
    await tocca(tester, find.bySemanticsLabel('giovedì 29 ottobre'));
    expect(
      find.text('3 giornate · 90 €\ndal 28 ottobre al 30 ottobre'),
      findsOneWidget,
    );

    // Tolgo il 29 (due tocchi) e salvo: restano 2 giornate
    await tocca(tester, find.bySemanticsLabel('giovedì 29 ottobre, scelto'));
    await tocca(
      tester,
      find.bySemanticsLabel('giovedì 29 ottobre, scelto, mezza giornata'),
    );
    await tocca(tester, find.text('Aggiungi 2 giornate'));
    expect(archivio.tabellaGiornate.elenco, hasLength(2));
  });

  testWidgets('Schema con mezze giornate: ognuna vale metà', (tester) async {
    schermoAlto(tester);
    final archivio = FintoArchivio();
    archivio.salvaLavoro(negozio());
    await avviaApp(tester, archivio: archivio, adesso: oggi);
    await tocca(tester, find.text('Negozio con mamma'));
    await tocca(tester, find.text('+ Aggiungi'));

    await tocca(tester, find.text('Mezze giornate'));
    await scrivi(tester, 'campo-numero-giorni', '4'); // 28, 29, 30 ott e 2 nov
    expect(
      find.text('4 mezze · 60 €\ndal 28 ottobre al 2 novembre'),
      findsOneWidget,
    );
    expect(find.text('½'), findsWidgets);

    await tocca(tester, find.text('Aggiungi 4 giornate'));
    final salvate = archivio.tabellaGiornate.elenco;
    expect(salvate, hasLength(4));
    expect(salvate.every((g) => g.mezza && g.importo == 15), isTrue);
  });

  testWidgets('Intere e mezze insieme: il totale tiene conto di tutte', (
    tester,
  ) async {
    schermoAlto(tester);
    final archivio = FintoArchivio();
    archivio.salvaLavoro(negozio());
    await avviaApp(tester, archivio: archivio, adesso: oggi);
    await tocca(tester, find.text('Negozio con mamma'));
    await tocca(tester, find.text('+ Aggiungi'));
    await scrivi(tester, 'campo-numero-giorni', '3');
    await tocca(tester, find.bySemanticsLabel('giovedì 29 ottobre, scelto'));
    await tocca(tester, find.text('Aggiungi 3 giornate'));

    final giornate = archivio.tabellaGiornate.elenco
      ..sort((a, b) => a.data.compareTo(b.data));
    expect([for (final g in giornate) g.mezza], [false, true, false]);
    expect([for (final g in giornate) g.importo], [30, 15, 30]);

    // Pagina del progetto: 2,5 giornate (le fatte: 28; il 29 e il 30 in programma)
    expect(find.text('+30 €'), findsWidgets); // solo il 28 è fatto
    await tocca(tester, find.bySemanticsLabel('Mese successivo'));
    await tocca(tester, find.bySemanticsLabel('Mese precedente'));
    expect(find.text('2,5 giornate a ottobre'), findsOneWidget);
    expect(find.text('+75 €'), findsOneWidget);
  });

  testWidgets(
    'Singola mezza giornata: importo di partenza = metà, ritoccabile',
    (tester) async {
      schermoAlto(tester);
      final archivio = FintoArchivio();
      archivio.salvaLavoro(negozio());
      await avviaApp(tester, archivio: archivio, adesso: oggi);
      await tocca(tester, find.text('Negozio con mamma'));

      await tocca(
        tester,
        find.bySemanticsLabel(
          'martedì 27 ottobre, libero: tocca per aggiungere',
        ),
      );
      String importoNelCampo() => tester
          .widget<TextField>(
            find.descendant(
              of: find.byKey(const Key('campo-importo-giornata')),
              matching: find.byType(TextField),
            ),
          )
          .controller!
          .text;
      expect(importoNelCampo(), '30'); // di partenza: intera

      await tocca(tester, find.text('Mezza giornata'));
      expect(importoNelCampo(), '15'); // la metà
      await tocca(tester, find.text('Giornata intera'));
      expect(importoNelCampo(), '30'); // di nuovo intera
      await tocca(tester, find.text('Mezza giornata'));
      await tocca(tester, find.text('Aggiungi'));

      final g = archivio.tabellaGiornate.elenco.single;
      expect(g.mezza, isTrue);
      expect(g.importo, 15);
      expect(find.text('mezza giornata a ottobre'), findsOneWidget);
      expect(find.text('+15 €'), findsWidgets);
      expect(find.text('½'), findsOneWidget);

      // Quel giorno la mezza giornata ha dato 20 €: si ritocca
      await tocca(
        tester,
        find.bySemanticsLabel(
          'martedì 27 ottobre, mezza giornata, 15 €: tocca per modificare',
        ),
      );
      expect(find.text('Mezza giornata'), findsOneWidget);
      await scrivi(tester, 'campo-importo-giornata', '20');
      await tocca(tester, find.text('Salva'));
      final dopo = archivio.tabellaGiornate.elenco.single;
      expect(dopo.mezza, isTrue);
      expect(dopo.importo, 20);
    },
  );

  testWidgets('La tariffa decimale dà una metà arrotondata ai centesimi', (
    tester,
  ) async {
    schermoAlto(tester);
    final archivio = FintoArchivio();
    final lavoro = negozio();
    archivio.salvaLavoro(
      Lavoro(
        id: '',
        nome: 'Mercatino',
        tipo: TipoLavoro.aGiornata,
        relazione: lavoro.relazione,
        livello: 3,
        prezzoPieno: 0,
        prezzoFinale: 0,
        tariffaGiornaliera: 45.5,
        creatoIl: DateTime(2026, 10, 1),
      ),
    );
    await avviaApp(tester, archivio: archivio, adesso: oggi);
    await tocca(tester, find.text('Mercatino'));
    await tocca(
      tester,
      find.bySemanticsLabel('martedì 27 ottobre, libero: tocca per aggiungere'),
    );
    await tocca(tester, find.text('Mezza giornata'));
    await tocca(tester, find.text('Aggiungi'));
    expect(archivio.tabellaGiornate.elenco.single.importo, 22.75);
  });

  testWidgets('"Fino al" e importo diverso dal valore di partenza', (
    tester,
  ) async {
    schermoAlto(tester);
    final archivio = FintoArchivio();
    archivio.salvaLavoro(negozio());
    await avviaApp(tester, archivio: archivio, adesso: oggi);
    await tocca(tester, find.text('Negozio con mamma'));
    await tocca(tester, find.text('+ Aggiungi'));

    await tocca(tester, find.text('Tutti'));
    await tocca(tester, find.text('Fino al'));
    // Il giorno finale parte a oggi + 14 giorni: 11 novembre → 15 giornate
    expect(
      find.text('15 giornate · 450 €\ndal 28 ottobre al 11 novembre'),
      findsOneWidget,
    );

    await scrivi(tester, 'campo-importo-giornate', '40');
    expect(
      find.text('15 giornate · 600 €\ndal 28 ottobre al 11 novembre'),
      findsOneWidget,
    );
    await tocca(tester, find.text('Aggiungi 15 giornate'));
    expect(
      archivio.tabellaGiornate.elenco.every((g) => g.importo == 40),
      isTrue,
    );
  });

  testWidgets(
    'Un giorno già registrato non si duplica e non conta nel numero',
    (tester) async {
      schermoAlto(tester);
      final archivio = FintoArchivio();
      final id = archivio.salvaLavoro(negozio());
      archivio.salvaGiornata(giornata(id, DateTime(2026, 10, 28)));
      await avviaApp(tester, archivio: archivio, adesso: oggi);
      await tocca(tester, find.text('Negozio con mamma'));
      await tocca(tester, find.text('+ Aggiungi'));
      await scrivi(
        tester,
        'campo-numero-giorni',
        '2',
      ); // il 28 c'è già: restano 29 e 30

      expect(
        find.text('2 giornate · 60 €\ndal 29 ottobre al 30 ottobre'),
        findsOneWidget,
      );
      await tocca(tester, find.text('Aggiungi 2 giornate'));
      expect(archivio.tabellaGiornate.elenco, hasLength(3)); // 28 + 29 + 30
    },
  );

  testWidgets('Senza giorni scelti non si può aggiungere', (tester) async {
    schermoAlto(tester);
    final archivio = FintoArchivio();
    archivio.salvaLavoro(negozio());
    await avviaApp(tester, archivio: archivio, adesso: oggi);
    await tocca(tester, find.text('Negozio con mamma'));
    await tocca(tester, find.text('+ Aggiungi'));

    await scrivi(tester, 'campo-numero-giorni', 'abc');
    expect(find.text('Scrivi da 1 a 366'), findsOneWidget);
    expect(find.text('Nessuna giornata scelta'), findsOneWidget);
    await tocca(tester, find.text('Aggiungi'));
    expect(archivio.tabellaGiornate.elenco, isEmpty);
  });

  testWidgets(
    'Singola giornata dal calendario: aggiungi, cambia importo, togli',
    (tester) async {
      schermoAlto(tester);
      final archivio = FintoArchivio();
      archivio.salvaLavoro(negozio());
      await avviaApp(tester, archivio: archivio, adesso: oggi);
      await tocca(tester, find.text('Negozio con mamma'));

      // Aggiungo il 27 (ieri): importo di partenza 30 €
      await tocca(
        tester,
        find.bySemanticsLabel(
          'martedì 27 ottobre, libero: tocca per aggiungere',
        ),
      );
      expect(find.text('martedì 27 ottobre'), findsOneWidget);
      await tocca(tester, find.text('Aggiungi'));
      expect(archivio.tabellaGiornate.elenco.single.importo, 30);
      expect(find.text('1 giornata a ottobre'), findsOneWidget);

      // Quel giorno ho preso 40 €
      await tocca(
        tester,
        find.bySemanticsLabel('martedì 27 ottobre, 30 €: tocca per modificare'),
      );
      await scrivi(tester, 'campo-importo-giornata', '40');
      await tocca(tester, find.text('Salva'));
      expect(archivio.tabellaGiornate.elenco.single.importo, 40);
      expect(find.text('+40 €'), findsWidgets);

      // Lo tolgo
      await tocca(
        tester,
        find.bySemanticsLabel('martedì 27 ottobre, 40 €: tocca per modificare'),
      );
      await tocca(tester, find.text('Togli questa giornata'));
      await tocca(tester, find.widgetWithText(TextButton, 'Togli'));
      expect(archivio.tabellaGiornate.elenco, isEmpty);
    },
  );

  testWidgets(
    'Mesi diversi: il calendario segue il mese e il totale è del mese',
    (tester) async {
      schermoAlto(tester);
      final archivio = FintoArchivio();
      final id = archivio.salvaLavoro(negozio());
      for (final giorno in [29, 30]) {
        archivio.salvaGiornata(giornata(id, DateTime(2026, 10, giorno)));
      }
      archivio.salvaGiornata(giornata(id, DateTime(2026, 11, 2), 40));
      await avviaApp(tester, archivio: archivio, adesso: oggi);
      await tocca(tester, find.text('Negozio con mamma'));

      expect(find.text('2 giornate a ottobre'), findsOneWidget);
      await tocca(tester, find.bySemanticsLabel('Mese successivo'));
      expect(find.text('1 giornata a novembre'), findsOneWidget);
      expect(find.text('+40 €'), findsOneWidget);
      await tocca(tester, find.bySemanticsLabel('Mese precedente'));
      await tocca(tester, find.bySemanticsLabel('Mese precedente'));
      expect(find.text('Nessuna giornata a settembre'), findsOneWidget);
    },
  );

  testWidgets('Il guadagno conta solo le giornate già fatte', (tester) async {
    schermoAlto(tester);
    final archivio = FintoArchivio();
    final id = archivio.salvaLavoro(negozio());
    archivio.salvaGiornata(giornata(id, DateTime(2026, 10, 26))); // fatta
    archivio.salvaGiornata(giornata(id, DateTime(2026, 10, 28))); // oggi: fatta
    archivio.salvaGiornata(
      giornata(id, DateTime(2026, 10, 29)),
    ); // domani: in programma
    await avviaApp(tester, archivio: archivio, adesso: oggi);

    // Home: riga del lavoro con 60 € (2 giornate fatte)
    expect(find.text('A giornata · 30 € al giorno'), findsOneWidget);
    expect(find.text('+60 €'), findsOneWidget);
  });

  testWidgets('Il negozio non prende quote dei costi condivisi', (
    tester,
  ) async {
    schermoAlto(tester);
    final archivio = FintoArchivio();
    archivio.salvaLavoro(negozio());
    final normale = archivio.salvaLavoro(
      Lavoro(
        id: '',
        nome: 'Il bosco',
        tipo: TipoLavoro.doppiaggio,
        relazione: Relazione.nuovo,
        livello: 3,
        prezzoPieno: 0,
        prezzoFinale: 0,
        creatoIl: DateTime(2026, 1, 1),
      ),
    );
    archivio.salvaSottoprogetto(
      Sottoprogetto(
        id: '',
        lavoroId: normale,
        nome: 'P',
        ricavo: 0,
        costiDiretti: 0,
        ore: 5,
        creatoIl: DateTime(2026),
      ),
    );
    archivio.salvaCosto(
      Costo(
        id: '',
        nome: 'Claude',
        tipo: TipoCosto.abbonamento,
        importo: 20,
        inizio: DateTime(2026, 1),
        creatoIl: DateTime(2026),
      ),
    );
    await avviaApp(tester, archivio: archivio, adesso: oggi);
    await tocca(tester, find.text('Costi').last);

    // Tutti i 20 € vanno al solo progetto normale
    expect(find.text('Abbonamento · usato su 1 progetto'), findsOneWidget);
    expect(find.text('Il bosco 20 €'), findsOneWidget);
    expect(find.textContaining('Negozio'), findsNothing);
  });

  testWidgets('Eliminare il lavoro toglie anche le sue giornate', (
    tester,
  ) async {
    schermoAlto(tester);
    final archivio = FintoArchivio();
    final id = archivio.salvaLavoro(negozio());
    archivio.salvaGiornata(giornata(id, DateTime(2026, 10, 27)));
    archivio.salvaGiornata(giornata(id, DateTime(2026, 10, 28)));
    await avviaApp(tester, archivio: archivio, adesso: oggi);
    await tocca(tester, find.text('Negozio con mamma'));

    await tocca(tester, find.text('Elimina progetto'));
    await tocca(tester, find.widgetWithText(TextButton, 'Elimina'));
    expect(archivio.tabellaLavori.elenco, isEmpty);
    expect(archivio.tabellaGiornate.elenco, isEmpty);
  });

  testWidgets('Modifica: si cambia il nome e la tariffa, non il tipo', (
    tester,
  ) async {
    schermoAlto(tester);
    final archivio = FintoArchivio();
    final id = archivio.salvaLavoro(negozio());
    archivio.salvaGiornata(giornata(id, DateTime(2026, 10, 27)));
    await avviaApp(tester, archivio: archivio, adesso: oggi);
    await tocca(tester, find.text('Negozio con mamma'));

    await tocca(tester, find.bySemanticsLabel('Modifica lavoro'));
    expect(find.text('Doppiaggio'), findsNothing); // il tipo non si cambia
    expect(find.text('A giornata'), findsOneWidget);
    await scrivi(tester, 'campo-tariffa', '35');
    await tocca(tester, find.text('Salva modifiche'));

    expect(archivio.tabellaLavori.elenco.single.tariffaGiornaliera, 35);
    // Le giornate già inserite restano a 30 €
    expect(archivio.tabellaGiornate.elenco.single.importo, 30);
    expect(find.text('A giornata · 35 € al giorno'), findsOneWidget);
  });
}
