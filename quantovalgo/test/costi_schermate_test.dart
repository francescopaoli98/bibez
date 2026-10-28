import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantovalgo/logica/mesi.dart';
import 'package:quantovalgo/modelli/categoria.dart';
import 'package:quantovalgo/modelli/costo.dart';
import 'package:quantovalgo/modelli/lavoro.dart';
import 'package:quantovalgo/modelli/sottoprogetto.dart';
import 'package:quantovalgo/modelli/tipi.dart';

import 'finti.dart';

void schermoAlto(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 3600);
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

/// Tre progetti attivi con ore 11 / 7 / 2: come nel mockup, Claude 20 € = 11 + 7 + 2.
FintoArchivio archivioConTreProgetti() {
  final a = FintoArchivio();
  void progetto(String nome, double ore, int giorno) {
    final id = a.salvaLavoro(
      Lavoro(
        id: '',
        nome: nome,
        tipo: TipoLavoro.altro,
        relazione: Relazione.nuovo,
        livello: 3,
        prezzoPieno: 0,
        prezzoFinale: 0,
        creatoIl: DateTime(2026, 1, giorno),
      ),
    );
    a.salvaSottoprogetto(
      Sottoprogetto(
        id: '',
        lavoroId: id,
        nome: 'Parte',
        ricavo: 0,
        costiDiretti: 0,
        ore: ore,
        creatoIl: DateTime(2026),
      ),
    );
  }

  progetto('Il bosco', 11, 1);
  progetto('Sito per Marta', 7, 2);
  progetto('Spot radio', 2, 3);
  return a;
}

void main() {
  final adesso = DateTime.now();
  final meseCorrente = primoDelMese(adesso);

  testWidgets('Costo nuovo: abbonamento diviso tra i progetti (11 + 7 + 2 €)', (
    tester,
  ) async {
    schermoAlto(tester);
    final app = await avviaApp(tester, archivio: archivioConTreProgetti());
    await tocca(tester, find.text('Costi').last);
    expect(find.text('Nessun costo'), findsOneWidget);

    await tocca(tester, find.text('Aggiungi costo'));
    await scrivi(tester, 'campo-nome', 'Abbonamento Claude');
    await scrivi(tester, 'campo-importo', '20');
    await tocca(tester, find.text('Salva'));

    final costo = app.archivio.tabellaCosti.elenco.single;
    expect(costo.tipo, TipoCosto.abbonamento);
    expect(costo.importo, 20);

    // Scheda: totale del mese, suddivisione per progetto e pillola
    expect(find.text('20 €'), findsOneWidget); // hero
    expect(find.text('20 €/mese'), findsOneWidget);
    expect(find.text('Abbonamento · usato su 3 progetti'), findsOneWidget);
    expect(find.text('Il bosco 11 €'), findsOneWidget);
    expect(find.text('Sito per Marta 7 €'), findsOneWidget);
    expect(find.text('Spot radio 2 €'), findsOneWidget);
    expect(find.text('Tutto assegnato'), findsOneWidget);
  });

  testWidgets(
    'Una tantum: tutto nel mese oppure spalmato (90 € ÷ 6 = 15 €/mese)',
    (tester) async {
      schermoAlto(tester);
      final app = await avviaApp(tester, archivio: archivioConTreProgetti());
      await tocca(tester, find.text('Costi').last);

      // Microfono 90 € spalmato su 6 mesi
      await tocca(tester, find.text('Aggiungi costo'));
      await scrivi(tester, 'campo-nome', 'Microfono');
      await tocca(tester, find.text('Una tantum'));
      await scrivi(tester, 'campo-importo', '90');
      await tocca(tester, find.text('Su più mesi'));
      await scrivi(tester, 'campo-mesi', '6');
      expect(find.text('Pesa 15 € al mese per 6 mesi'), findsOneWidget);
      await tocca(tester, find.text('Salva'));

      expect(find.text('15 €/mese'), findsOneWidget);
      expect(
        find.text('Acquisto da 90 €, spalmato su 6 mesi (mese 1 di 6)'),
        findsOneWidget,
      );

      // Cuffie 120 € tutto nel mese: nessun "/mese"
      await tocca(tester, find.text('Aggiungi costo'));
      await scrivi(tester, 'campo-nome', 'Cuffie');
      await tocca(tester, find.text('Una tantum'));
      await scrivi(tester, 'campo-importo', '120');
      await tocca(tester, find.text('Salva'));

      expect(find.text('120 €'), findsWidgets);
      expect(
        find.text('Acquisto da 120 €, tutto in questo mese'),
        findsOneWidget,
      );
      expect(
        find.text('135 €'),
        findsOneWidget,
      ); // 15 + 120 nel totale del mese

      // I mesi successivi: il microfono pesa ancora, le cuffie no
      await tocca(tester, find.bySemanticsLabel('Mese successivo'));
      expect(find.text('15 €'), findsWidgets);
      expect(
        find.text('Cuffie'),
        findsOneWidget,
      ); // ora nella lista "non in questo mese"
      expect(find.text('Non in questo mese'), findsOneWidget);
      expect(app.archivio.tabellaCosti.elenco, hasLength(2));
    },
  );

  testWidgets(
    'Da recuperare: costi una tantum meno l\'utile dei progetti incassati',
    (tester) async {
      schermoAlto(tester);
      final archivio = archivioConTreProgetti();
      archivio.salvaCosto(
        Costo(
          id: '',
          nome: 'Microfono',
          tipo: TipoCosto.unaTantum,
          importo: 90,
          mesi: 6,
          inizio: adesso,
          creatoIl: DateTime(2026),
        ),
      );
      await avviaApp(tester, archivio: archivio);
      await tocca(tester, find.text('Costi').last);

      expect(find.text('Da recuperare 90 € di 90 €'), findsOneWidget);
    },
  );

  testWidgets('Categorie: di partenza, nuova con colore, uso nel costo', (
    tester,
  ) async {
    schermoAlto(tester);
    final app = await avviaApp(tester, archivio: archivioConTreProgetti());
    await tocca(tester, find.text('Costi').last);

    // Categorie di partenza con un tocco
    await tocca(tester, find.text('Gestisci categorie'));
    await tocca(tester, find.text('Aggiungi quelle di partenza'));
    expect(
      [for (final c in app.archivio.tabellaCategorie.elenco) c.nome],
      ['Doppiaggio', 'Codice', 'Claude', 'Generale'],
    );
    expect(
      find.text('Rosso · 0 costi · progetti Doppiaggio'),
      findsOneWidget,
    ); // Doppiaggio

    // Nuova categoria con colore scelto dalla tavolozza
    await tocca(tester, find.text('+ Nuova categoria'));
    await scrivi(tester, 'campo-nome-categoria', 'Podcast');
    await tocca(tester, find.bySemanticsLabel('Rosa'));
    await tocca(tester, find.text('Salva'));
    final podcast = app.archivio.tabellaCategorie.elenco.last;
    expect(podcast.nome, 'Podcast');
    expect(podcast.colore, 7); // Rosa

    // Un nome già usato non passa
    await tocca(tester, find.text('+ Nuova categoria'));
    await scrivi(tester, 'campo-nome-categoria', ' doppiaggio ');
    await tocca(tester, find.text('Salva'));
    expect(
      find.text('Esiste già una categoria con questo nome'),
      findsOneWidget,
    );
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10)); // chiude anche l'elenco
    await tester.pumpAndSettle();

    // Un costo con la categoria "Doppiaggio"
    await tocca(tester, find.text('Aggiungi costo'));
    await scrivi(tester, 'campo-nome', 'Microfono');
    await scrivi(tester, 'campo-importo', '15');
    await tocca(tester, find.widgetWithText(InkWell, 'Doppiaggio').first);
    await tocca(tester, find.text('Salva'));

    final doppiaggio = app.archivio.tabellaCategorie.elenco.first;
    expect(app.archivio.tabellaCosti.elenco.single.categoriaId, doppiaggio.id);
    expect(find.text('Per categoria'), findsOneWidget);
    expect(find.text('Doppiaggio 15 €'), findsOneWidget);
  });

  testWidgets(
    'Nuova categoria creata dal modulo del costo si sceglie da sola',
    (tester) async {
      schermoAlto(tester);
      final app = await avviaApp(tester, archivio: archivioConTreProgetti());
      await tocca(tester, find.text('Costi').last);

      await tocca(tester, find.text('Aggiungi costo'));
      await scrivi(tester, 'campo-nome', 'Software audio');
      await scrivi(tester, 'campo-importo', '12');
      await tocca(tester, find.text('+ Nuova'));
      await scrivi(tester, 'campo-nome-categoria', 'Studio');
      await tocca(
        tester,
        find.text('Salva').last,
      ); // salva la categoria (foglio in primo piano)
      // Il foglio del costo è di nuovo in primo piano, con la categoria scelta
      expect(find.text('Nuovo costo'), findsOneWidget);
      await tocca(tester, find.text('Salva')); // salva il costo

      final categoria = app.archivio.tabellaCategorie.elenco.single;
      expect(app.archivio.tabellaCosti.elenco.single.categoriaId, categoria.id);
    },
  );

  testWidgets('Validazione del costo e costo fisso (non diviso)', (
    tester,
  ) async {
    schermoAlto(tester);
    final app = await avviaApp(tester, archivio: archivioConTreProgetti());
    await tocca(tester, find.text('Costi').last);

    await tocca(tester, find.text('Aggiungi costo'));
    await tocca(tester, find.text('Salva'));
    expect(find.text('Scrivi un nome'), findsOneWidget);
    expect(find.text('Scrivi un importo'), findsOneWidget);
    expect(app.archivio.tabellaCosti.elenco, isEmpty);

    await scrivi(tester, 'campo-nome', 'Internet');
    await tocca(tester, find.text('Fisso'));
    await scrivi(tester, 'campo-importo', '30');
    await tocca(tester, find.text('Salva'));

    expect(
      find.text('Costo fisso · non si divide tra i progetti'),
      findsOneWidget,
    );
    expect(find.text('Da assegnare'), findsNothing);
    expect(find.text('Tutto assegnato'), findsNothing); // nulla da assegnare
    expect(app.archivio.tabellaCosti.elenco.single.tipo, TipoCosto.fisso);
  });

  testWidgets('Senza progetti attivi il costo resta "Da assegnare"', (
    tester,
  ) async {
    schermoAlto(tester);
    await avviaApp(tester);
    await tocca(tester, find.text('Costi').last);

    await tocca(tester, find.text('Aggiungi costo'));
    await scrivi(tester, 'campo-nome', 'Abbonamento Claude');
    await scrivi(tester, 'campo-importo', '20');
    await tocca(tester, find.text('Salva'));

    expect(find.text('Da assegnare'), findsOneWidget);
    expect(find.text('Abbonamento · nessun progetto attivo'), findsOneWidget);
  });

  testWidgets('Modifica e disdetta di un abbonamento, poi eliminazione', (
    tester,
  ) async {
    schermoAlto(tester);
    final archivio = archivioConTreProgetti();
    archivio.salvaCosto(
      Costo(
        id: '',
        nome: 'Software audio',
        tipo: TipoCosto.abbonamento,
        importo: 12,
        inizio: DateTime(2026, 1, 10),
        creatoIl: DateTime(2026),
      ),
    );
    final app = await avviaApp(tester, archivio: archivio);
    await tocca(tester, find.text('Costi').last);

    await tocca(tester, find.text('Software audio'));
    await scrivi(tester, 'campo-importo', '15');
    await tocca(tester, find.text('Salva'));
    expect(app.archivio.tabellaCosti.elenco.single.importo, 15);

    // Disdetto: smette dal mese dopo, questo mese pesa ancora
    await tocca(tester, find.text('Software audio'));
    await tocca(tester, find.byType(Switch));
    await tocca(tester, find.text('Salva'));
    final disdetto = app.archivio.tabellaCosti.elenco.single;
    expect(disdetto.fine, isNotNull);
    expect(find.text('15 €/mese'), findsOneWidget);
    await tocca(tester, find.bySemanticsLabel('Mese successivo'));
    expect(find.text('Software audio'), findsOneWidget);
    expect(find.text('Abbonamento · disdetto'), findsOneWidget);

    // Eliminazione
    await tocca(tester, find.text('Software audio'));
    await tocca(tester, find.text('Elimina'));
    await tocca(tester, find.widgetWithText(TextButton, 'Elimina'));
    expect(app.archivio.tabellaCosti.elenco, isEmpty);
  });

  testWidgets('Il progetto mostra la sua quota dei costi condivisi', (
    tester,
  ) async {
    schermoAlto(tester);
    final archivio = archivioConTreProgetti();
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
    await avviaApp(tester, archivio: archivio);

    await tocca(tester, find.text('Il bosco'));
    expect(
      find.text('Costi condivisi di ${nomeMese(meseCorrente)}: 11 €'),
      findsOneWidget,
    );
    expect(find.text('−11 €'), findsOneWidget); // utile 0 meno la quota
  });

  testWidgets('Categoria eliminata: i costi restano, senza categoria', (
    tester,
  ) async {
    schermoAlto(tester);
    final archivio = archivioConTreProgetti();
    final cat = archivio.salvaCategoria(
      Categoria(
        id: '',
        nome: 'Doppiaggio',
        colore: 6,
        creatoIl: DateTime(2026),
      ),
    );
    archivio.salvaCosto(
      Costo(
        id: '',
        nome: 'Microfono',
        tipo: TipoCosto.abbonamento,
        importo: 15,
        inizio: DateTime(2026, 1),
        categoriaId: cat,
        creatoIl: DateTime(2026),
      ),
    );
    final app = await avviaApp(tester, archivio: archivio);
    await tocca(tester, find.text('Costi').last);
    expect(find.text('Doppiaggio 15 €'), findsOneWidget);

    await tocca(tester, find.text('Gestisci categorie'));
    await tocca(tester, find.text('Rosso · 1 costo · tutti i progetti'));
    await tocca(tester, find.text('Elimina'));
    await tocca(tester, find.widgetWithText(TextButton, 'Elimina'));
    expect(app.archivio.tabellaCategorie.elenco, isEmpty);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.text('Microfono'), findsOneWidget); // il costo c'è ancora
    expect(find.text('Per categoria'), findsNothing); // ma senza categoria
  });
}
