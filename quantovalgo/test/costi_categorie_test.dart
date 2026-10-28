import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantovalgo/modelli/categoria.dart';
import 'package:quantovalgo/modelli/costo.dart';
import 'package:quantovalgo/modelli/lavoro.dart';
import 'package:quantovalgo/modelli/sottoprogetto.dart';
import 'package:quantovalgo/modelli/tipi.dart';

import 'finti.dart';

// Mercoledì 28 ottobre 2026
DateTime oggi() => DateTime(2026, 10, 28, 10);

void schermoAlto(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 4800);
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

String categoria(
  FintoArchivio a,
  String nome, {
  int colore = 0,
  TipoLavoro? tipo,
  int giorno = 1,
}) => a.salvaCategoria(
  Categoria(
    id: '',
    nome: nome,
    colore: colore,
    tipoLavoro: tipo,
    creatoIl: DateTime(2026, 1, giorno),
  ),
);

String progetto(
  FintoArchivio a,
  String nome,
  TipoLavoro tipo, {
  String? categoriaId,
  double ore = 0,
  double ricavo = 0,
  bool incassato = false,
  int giorno = 1,
}) {
  final id = a.salvaLavoro(
    Lavoro(
      id: '',
      nome: nome,
      tipo: tipo,
      categoriaId: categoriaId,
      relazione: Relazione.nuovo,
      livello: 3,
      prezzoPieno: 0,
      prezzoFinale: 0,
      statoPagamento: incassato
          ? StatoPagamento.incassato
          : StatoPagamento.daIncassare,
      dataIncasso: incassato ? DateTime(2026, 10, 20) : null,
      creatoIl: DateTime(2026, 1, giorno),
    ),
  );
  a.salvaSottoprogetto(
    Sottoprogetto(
      id: '',
      lavoroId: id,
      nome: 'Parte',
      ricavo: ricavo,
      costiDiretti: 0,
      ore: ore,
      creatoIl: DateTime(2026),
    ),
  );
  return id;
}

void abbonamento(
  FintoArchivio a,
  String nome,
  double importo, {
  String? categoriaId,
}) => a.salvaCosto(
  Costo(
    id: '',
    nome: nome,
    tipo: TipoCosto.abbonamento,
    importo: importo,
    inizio: DateTime(2026, 1, 10),
    categoriaId: categoriaId,
    creatoIl: DateTime(2026),
  ),
);

void main() {
  testWidgets('Vale per ogni categoria, anche una inventata: "Podcast"', (
    tester,
  ) async {
    schermoAlto(tester);
    final a = FintoArchivio();
    final podcast = categoria(a, 'Podcast', colore: 7);
    final claude = categoria(a, 'Claude', colore: 8, giorno: 2);
    progetto(
      a,
      'Puntata pilota',
      TipoLavoro.altro,
      categoriaId: podcast,
      ore: 3,
    );
    progetto(
      a,
      'Seconda serie',
      TipoLavoro.altro,
      categoriaId: podcast,
      ore: 1,
      giorno: 2,
    );
    progetto(
      a,
      'Chatbot',
      TipoLavoro.claude,
      categoriaId: claude,
      ore: 9,
      giorno: 3,
    );
    abbonamento(a, 'Hosting podcast', 20, categoriaId: podcast);
    await avviaApp(tester, archivio: a, adesso: oggi);
    await tocca(tester, find.text('Costi').last);

    // 3 h : 1 h → 15 € e 5 €: il progetto Claude non prende niente
    expect(
      find.text('Abbonamento · usato su 2 progetti «Podcast»'),
      findsOneWidget,
    );
    expect(find.text('Puntata pilota 15 €'), findsOneWidget);
    expect(find.text('Seconda serie 5 €'), findsOneWidget);
    expect(find.textContaining('Chatbot'), findsNothing);
    expect(find.text('Tutto assegnato'), findsOneWidget);
  });

  testWidgets(
    'Il costo di una categoria non finisce su progetti di altre categorie',
    (tester) async {
      schermoAlto(tester);
      final a = FintoArchivio();
      final claude = categoria(a, 'Claude', colore: 8);
      final doppiaggio = categoria(a, 'Doppiaggio', colore: 6, giorno: 2);
      progetto(a, 'Assistente', TipoLavoro.claude, categoriaId: claude, ore: 1);
      progetto(
        a,
        'Il bosco',
        TipoLavoro.doppiaggio,
        categoriaId: doppiaggio,
        ore: 50,
        giorno: 2,
      );
      abbonamento(a, 'Claude Pro', 20, categoriaId: claude);
      await avviaApp(tester, archivio: a, adesso: oggi);
      await tocca(tester, find.text('Costi').last);

      expect(find.text('Assistente 20 €'), findsOneWidget);
      expect(find.textContaining('Il bosco'), findsNothing);
    },
  );

  testWidgets(
    'Senza categoria il costo è generale: lo dividono tutti i progetti',
    (tester) async {
      schermoAlto(tester);
      final a = FintoArchivio();
      final claude = categoria(a, 'Claude');
      progetto(a, 'Assistente', TipoLavoro.claude, categoriaId: claude, ore: 1);
      progetto(
        a,
        'Il bosco',
        TipoLavoro.doppiaggio,
        ore: 1,
        giorno: 2,
      ); // senza categoria
      abbonamento(a, 'Internet fibra', 30);
      await avviaApp(tester, archivio: a, adesso: oggi);
      await tocca(tester, find.text('Costi').last);

      expect(find.text('Abbonamento · usato su 2 progetti'), findsOneWidget);
      expect(find.text('Assistente 15 €'), findsOneWidget);
      expect(find.text('Il bosco 15 €'), findsOneWidget);
    },
  );

  testWidgets(
    'Progetti senza categoria scelta seguono il tipo collegato (come prima)',
    (tester) async {
      schermoAlto(tester);
      final a = FintoArchivio();
      final claude = categoria(a, 'Claude', colore: 8, tipo: TipoLavoro.claude);
      progetto(
        a,
        'Assistente',
        TipoLavoro.claude,
        ore: 1,
      ); // nessuna categoria scelta
      progetto(a, 'Il bosco', TipoLavoro.doppiaggio, ore: 1, giorno: 2);
      abbonamento(a, 'Claude Pro', 20, categoriaId: claude);
      await avviaApp(tester, archivio: a, adesso: oggi);
      await tocca(tester, find.text('Costi').last);

      expect(find.text('Assistente 20 €'), findsOneWidget);
      expect(find.textContaining('Il bosco'), findsNothing);
    },
  );

  testWidgets('Nessun progetto nella categoria: da assegnare e si accumula', (
    tester,
  ) async {
    schermoAlto(tester);
    final a = FintoArchivio();
    final podcast = categoria(a, 'Podcast', colore: 7);
    progetto(a, 'Il bosco', TipoLavoro.doppiaggio, ore: 5);
    abbonamento(a, 'Hosting podcast', 20, categoriaId: podcast);
    await avviaApp(tester, archivio: a, adesso: oggi);
    await tocca(tester, find.text('Costi').last);

    expect(
      find.text(
        'Abbonamento · nessun progetto «Podcast» attivo: si accumula da recuperare',
      ),
      findsOneWidget,
    );
    expect(find.text('Da assegnare'), findsOneWidget);
    // Da gennaio a ottobre: 10 mesi × 20 €
    expect(find.text('Da recuperare 200 € di 200 €'), findsOneWidget);
    expect(find.text('Podcast'), findsWidgets);
    expect(
      find.text('Si copre solo con l\'utile dei progetti «Podcast» incassati'),
      findsOneWidget,
    );
  });

  testWidgets(
    'Ogni categoria si copre solo con l\'utile dei suoi progetti incassati',
    (tester) async {
      schermoAlto(tester);
      final a = FintoArchivio();
      final claude = categoria(a, 'Claude', colore: 8);
      final doppiaggio = categoria(a, 'Doppiaggio', colore: 6, giorno: 2);
      final podcast = categoria(a, 'Podcast', colore: 7, giorno: 3);
      progetto(
        a,
        'Chatbot',
        TipoLavoro.claude,
        categoriaId: claude,
        ricavo: 120,
        incassato: true,
      );
      progetto(
        a,
        'Il bosco',
        TipoLavoro.doppiaggio,
        categoriaId: doppiaggio,
        ricavo: 500,
        incassato: true,
        giorno: 2,
      );
      progetto(
        a,
        'Puntata',
        TipoLavoro.altro,
        categoriaId: podcast,
        ricavo: 10,
        incassato: true,
        giorno: 3,
      );
      abbonamento(
        a,
        'Claude Pro',
        20,
        categoriaId: claude,
      ); // 200 € dall'inizio
      abbonamento(a, 'Hosting', 20, categoriaId: podcast); // 200 €
      a.salvaCosto(
        Costo(
          id: '',
          nome: 'Microfono',
          tipo: TipoCosto.unaTantum,
          importo: 90,
          mesi: 6,
          inizio: DateTime(2026, 10, 5),
          categoriaId: doppiaggio,
          creatoIl: DateTime(2026),
        ),
      );
      await avviaApp(tester, archivio: a, adesso: oggi);
      await tocca(tester, find.text('Costi').last);

      // Claude: 120 di utile su 200 → restano 80. I 500 € del doppiaggio non servono.
      expect(find.text('Da recuperare 80 € di 200 €'), findsOneWidget);
      // Podcast: 10 di utile su 200 → restano 190
      expect(find.text('Da recuperare 190 € di 200 €'), findsOneWidget);
      // Doppiaggio: 500 coprono i 90 € del microfono
      expect(find.text('Da recuperare 0 € di 90 €'), findsOneWidget);
    },
  );

  testWidgets('Gli altri costi si coprono con l\'utile che avanza', (
    tester,
  ) async {
    schermoAlto(tester);
    final a = FintoArchivio();
    final doppiaggio = categoria(a, 'Doppiaggio', colore: 6);
    progetto(
      a,
      'Il bosco',
      TipoLavoro.doppiaggio,
      categoriaId: doppiaggio,
      ricavo: 300,
      incassato: true,
    );
    a.salvaCosto(
      Costo(
        id: '',
        nome: 'Microfono',
        tipo: TipoCosto.unaTantum,
        importo: 90,
        inizio: DateTime(2026, 10, 5),
        categoriaId: doppiaggio,
        creatoIl: DateTime(2026),
      ),
    );
    a.salvaCosto(
      Costo(
        id: '',
        nome: 'Scrivania',
        tipo: TipoCosto.unaTantum,
        importo: 150,
        inizio: DateTime(2026, 10, 6),
        creatoIl: DateTime(2026),
      ),
    );
    await avviaApp(tester, archivio: a, adesso: oggi);
    await tocca(tester, find.text('Costi').last);

    // 300 − 90 = 210 avanzano per la scrivania (150 €): coperta
    expect(find.text('Altri costi'), findsOneWidget);
    expect(find.text('Da recuperare 0 € di 150 €'), findsOneWidget);
    expect(
      find.text(
        'Si copre con l\'utile che avanza dagli altri progetti incassati',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'Un lavoro a giornata con una sua categoria prende i costi di quella categoria',
    (tester) async {
      schermoAlto(tester);
      final a = FintoArchivio();
      final negozio = categoria(a, 'Negozio', colore: 4);
      a.salvaLavoro(
        Lavoro(
          id: '',
          nome: 'Negozio con mamma',
          tipo: TipoLavoro.aGiornata,
          categoriaId: negozio,
          relazione: Relazione.nuovo,
          livello: 3,
          prezzoPieno: 0,
          prezzoFinale: 0,
          tariffaGiornaliera: 30,
          creatoIl: DateTime(2026, 1, 1),
        ),
      );
      progetto(a, 'Il bosco', TipoLavoro.doppiaggio, ore: 5, giorno: 2);
      abbonamento(a, 'Registratore di cassa', 10, categoriaId: negozio);
      abbonamento(a, 'Internet', 30); // generale: il negozio non lo prende
      await avviaApp(tester, archivio: a, adesso: oggi);
      await tocca(tester, find.text('Costi').last);

      expect(
        find.text('Negozio con mamma 10 €'),
        findsOneWidget,
      ); // solo il suo costo
      expect(
        find.text('Il bosco 30 €'),
        findsOneWidget,
      ); // l'internet, tutto al bosco
    },
  );

  testWidgets(
    'Una categoria cancellata: costi e progetti diventano "senza categoria"',
    (tester) async {
      schermoAlto(tester);
      final a = FintoArchivio();
      final podcast = categoria(a, 'Podcast', colore: 7);
      progetto(a, 'Puntata', TipoLavoro.altro, categoriaId: podcast, ore: 1);
      progetto(a, 'Il bosco', TipoLavoro.doppiaggio, ore: 1, giorno: 2);
      abbonamento(a, 'Hosting', 20, categoriaId: podcast);
      a.tabellaCategorie.togli(podcast);
      await avviaApp(tester, archivio: a, adesso: oggi);
      await tocca(tester, find.text('Costi').last);

      // Ora è un costo generale: lo dividono tutti i progetti
      expect(find.text('Abbonamento · usato su 2 progetti'), findsOneWidget);
      expect(find.text('Puntata 10 €'), findsOneWidget);
      expect(find.text('Il bosco 10 €'), findsOneWidget);
    },
  );

  testWidgets(
    'Nuovo progetto: si sceglie la categoria, di partenza quella del tipo',
    (tester) async {
      schermoAlto(tester);
      final a = FintoArchivio();
      final claude = categoria(a, 'Claude', colore: 8, tipo: TipoLavoro.claude);
      final podcast = categoria(a, 'Podcast', colore: 7, giorno: 2);
      await avviaApp(tester, archivio: a, adesso: oggi);
      await tocca(tester, find.bySemanticsLabel('Nuovo lavoro'));

      expect(find.text('Categoria dei costi'), findsOneWidget);
      expect(
        find.text(
          'Senza categoria: prende una parte dei costi generali (quelli senza categoria).',
        ),
        findsOneWidget,
      );

      // Scegliendo il tipo Claude la categoria Claude si seleziona da sola
      await tocca(tester, find.text('Claude').first);
      expect(
        find.text(
          'I costi della categoria «Claude» si recuperano con questo progetto.',
        ),
        findsOneWidget,
      );

      // …ma la si può cambiare: dopo la scelta non cambia più da sola
      await tocca(tester, find.widgetWithText(InkWell, 'Podcast').first);
      await tocca(tester, find.text('Doppiaggio'));
      expect(
        find.text(
          'I costi della categoria «Podcast» si recuperano con questo progetto.',
        ),
        findsOneWidget,
      );

      await scrivi(tester, 'campo-nome', 'Assistente');
      await tocca(tester, find.text('Salva lavoro'));
      final lavoro = a.tabellaLavori.elenco.single;
      expect(lavoro.categoriaId, podcast);
      expect(lavoro.tipo, TipoLavoro.doppiaggio);
      expect(claude, isNotEmpty);
    },
  );

  testWidgets(
    'Modifica: si parte dalla categoria vera e "Nessuna" vuol dire nessuna',
    (tester) async {
      schermoAlto(tester);
      final a = FintoArchivio();
      final claude = categoria(a, 'Claude', colore: 8, tipo: TipoLavoro.claude);
      progetto(
        a,
        'Assistente',
        TipoLavoro.claude,
        ore: 1,
      ); // senza scelta: segue il tipo
      abbonamento(a, 'Claude Pro', 20, categoriaId: claude);
      await avviaApp(tester, archivio: a, adesso: oggi);
      await tocca(tester, find.text('Assistente'));
      expect(find.text('Categoria: Claude'), findsOneWidget);

      await tocca(tester, find.bySemanticsLabel('Modifica lavoro'));
      expect(
        find.text(
          'I costi della categoria «Claude» si recuperano con questo progetto.',
        ),
        findsOneWidget,
      );
      await tocca(tester, find.widgetWithText(InkWell, 'Nessuna').first);
      await tocca(tester, find.text('Salva modifiche'));

      // "Nessuna" è una scelta: non torna la categoria del tipo
      expect(a.tabellaLavori.elenco.single.categoriaId, '');
      expect(find.textContaining('Categoria:'), findsNothing);
      await tocca(tester, find.bySemanticsLabel('Indietro'));
      await tocca(tester, find.text('Costi').last);
      expect(
        find.text(
          'Abbonamento · nessun progetto «Claude» attivo: si accumula da recuperare',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('La pagina del progetto dice la sua categoria', (tester) async {
    schermoAlto(tester);
    final a = FintoArchivio();
    final podcast = categoria(a, 'Podcast', colore: 7);
    progetto(a, 'Puntata', TipoLavoro.altro, categoriaId: podcast, ore: 1);
    progetto(a, 'Il bosco', TipoLavoro.doppiaggio, ore: 1, giorno: 2);
    await avviaApp(tester, archivio: a, adesso: oggi);
    await tocca(tester, find.text('Puntata'));
    expect(find.text('Categoria: Podcast'), findsOneWidget);
    await tocca(tester, find.bySemanticsLabel('Indietro'));
    await tocca(tester, find.text('Il bosco'));
    expect(find.textContaining('Categoria:'), findsNothing);
  });

  testWidgets(
    'Gestione categorie: uso (costi e progetti) e collegamento al tipo',
    (tester) async {
      schermoAlto(tester);
      final a = FintoArchivio();
      final podcast = categoria(a, 'Podcast', colore: 7);
      progetto(a, 'Puntata', TipoLavoro.altro, categoriaId: podcast);
      progetto(a, 'Seconda', TipoLavoro.altro, categoriaId: podcast, giorno: 2);
      abbonamento(a, 'Hosting', 20, categoriaId: podcast);
      await avviaApp(tester, archivio: a, adesso: oggi);
      await tocca(tester, find.text('Costi').last);
      await tocca(tester, find.text('Gestisci categorie'));

      expect(find.text('Rosa · 1 costo · 2 progetti'), findsOneWidget);

      await tocca(tester, find.text('Rosa · 1 costo · 2 progetti'));
      expect(
        find.text('La categoria si sceglie progetto per progetto.'),
        findsOneWidget,
      );
      await tocca(tester, find.text('Claude'));
      expect(
        find.textContaining(
          'I progetti Claude ne fanno parte, se non scegli un',
        ),
        findsOneWidget,
      );
      await tocca(tester, find.text('Salva').last);
      expect(a.tabellaCategorie.elenco.single.tipoLavoro, TipoLavoro.claude);
    },
  );

  testWidgets(
    'Categorie di partenza: Doppiaggio, Codice, Claude, già collegate al tipo',
    (tester) async {
      schermoAlto(tester);
      final a = FintoArchivio();
      await avviaApp(tester, archivio: a, adesso: oggi);
      await tocca(tester, find.text('Costi').last);
      await tocca(tester, find.text('Gestisci categorie'));
      await tocca(tester, find.text('Aggiungi quelle di partenza'));

      expect(
        {for (final c in a.tabellaCategorie.elenco) c.nome: c.tipoLavoro},
        {
          'Doppiaggio': TipoLavoro.doppiaggio,
          'Codice': TipoLavoro.codice,
          'Claude': TipoLavoro.claude,
        },
      );
      expect(find.text('Viola · 0 costi · 0 progetti'), findsOneWidget);
    },
  );

  testWidgets('Il modulo del costo ricorda la regola per qualsiasi categoria', (
    tester,
  ) async {
    schermoAlto(tester);
    final a = FintoArchivio();
    categoria(a, 'Podcast', colore: 7);
    await avviaApp(tester, archivio: a, adesso: oggi);
    await tocca(tester, find.text('Costi').last);
    await tocca(tester, find.text('Aggiungi costo'));

    expect(find.textContaining('Pesa e si recupera solo con'), findsNothing);
    await tocca(tester, find.widgetWithText(InkWell, 'Podcast').first);
    expect(
      find.text(
        'Pesa e si recupera solo con i progetti della categoria «Podcast».',
      ),
      findsOneWidget,
    );
    await tocca(tester, find.widgetWithText(InkWell, 'Nessuna').first);
    expect(find.textContaining('Pesa e si recupera solo con'), findsNothing);
  });
}
