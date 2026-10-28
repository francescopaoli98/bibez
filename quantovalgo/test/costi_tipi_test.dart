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

/// Un progetto con una parte (ore e utile a piacere).
String progetto(
  FintoArchivio a,
  String nome,
  TipoLavoro tipo, {
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

/// Categoria "Claude" legata ai progetti Claude e abbonamento da 20 €/mese da gennaio.
void abbonamentoClaude(
  FintoArchivio a, {
  TipoLavoro? tipo = TipoLavoro.claude,
}) {
  final cat = a.salvaCategoria(
    Categoria(
      id: '',
      nome: 'Claude',
      colore: 8,
      tipoLavoro: tipo,
      creatoIl: DateTime(2026),
    ),
  );
  a.salvaCosto(
    Costo(
      id: '',
      nome: 'Abbonamento Claude',
      tipo: TipoCosto.abbonamento,
      importo: 20,
      inizio: DateTime(2026, 1, 10),
      categoriaId: cat,
      creatoIl: DateTime(2026),
    ),
  );
}

void main() {
  testWidgets('Un costo Claude si divide solo tra i progetti Claude', (
    tester,
  ) async {
    schermoAlto(tester);
    final a = FintoArchivio();
    progetto(a, 'Assistente', TipoLavoro.claude, ore: 3);
    progetto(a, 'Chatbot', TipoLavoro.claude, ore: 1, giorno: 2);
    progetto(a, 'Il bosco', TipoLavoro.doppiaggio, ore: 20, giorno: 3);
    abbonamentoClaude(a);
    await avviaApp(tester, archivio: a, adesso: oggi);
    await tocca(tester, find.text('Costi').last);

    // 3 h : 1 h → 15 € e 5 €; il doppiaggio (20 h) non prende niente
    expect(
      find.text('Abbonamento · usato su 2 progetti Claude'),
      findsOneWidget,
    );
    expect(find.text('Assistente 15 €'), findsOneWidget);
    expect(find.text('Chatbot 5 €'), findsOneWidget);
    expect(find.textContaining('Il bosco'), findsNothing);
    expect(find.text('Tutto assegnato'), findsOneWidget);

    // Nella pagina di un progetto Claude c'è la sua quota; nel doppiaggio no
    await tocca(tester, find.text('Progetti').last);
    await tocca(tester, find.text('Il bosco'));
    expect(find.textContaining('Costi condivisi'), findsNothing);
  });

  testWidgets(
    'Senza la categoria collegata il costo resta per tutti i progetti',
    (tester) async {
      schermoAlto(tester);
      final a = FintoArchivio();
      progetto(a, 'Assistente', TipoLavoro.claude, ore: 1);
      progetto(a, 'Il bosco', TipoLavoro.doppiaggio, ore: 1, giorno: 2);
      abbonamentoClaude(a, tipo: null);
      await avviaApp(tester, archivio: a, adesso: oggi);
      await tocca(tester, find.text('Costi').last);

      expect(find.text('Abbonamento · usato su 2 progetti'), findsOneWidget);
      expect(find.text('Assistente 10 €'), findsOneWidget);
      expect(find.text('Il bosco 10 €'), findsOneWidget);
    },
  );

  testWidgets('Senza progetti Claude il costo si accumula da recuperare', (
    tester,
  ) async {
    schermoAlto(tester);
    final a = FintoArchivio();
    progetto(a, 'Il bosco', TipoLavoro.doppiaggio, ore: 5);
    abbonamentoClaude(a);
    await avviaApp(tester, archivio: a, adesso: oggi);
    await tocca(tester, find.text('Costi').last);

    expect(
      find.text(
        'Abbonamento · nessun progetto Claude attivo: si accumula da recuperare',
      ),
      findsOneWidget,
    );
    expect(find.text('Da assegnare'), findsOneWidget);
    // Da gennaio a ottobre: 10 mesi × 20 € restano da recuperare con i progetti Claude
    expect(find.text('Da recuperare'), findsOneWidget);
    expect(find.text('Da recuperare 200 € di 200 €'), findsOneWidget);
    expect(
      find.text('Si copre solo con l\'utile dei progetti Claude incassati'),
      findsOneWidget,
    );
  });

  testWidgets(
    'Solo l\'utile dei progetti Claude incassati copre il costo Claude',
    (tester) async {
      schermoAlto(tester);
      final a = FintoArchivio();
      progetto(a, 'Chatbot', TipoLavoro.claude, ricavo: 120, incassato: true);
      progetto(
        a,
        'Il bosco',
        TipoLavoro.doppiaggio,
        ricavo: 500,
        incassato: true,
        giorno: 2,
      );
      abbonamentoClaude(a);
      await avviaApp(tester, archivio: a, adesso: oggi);
      await tocca(tester, find.text('Costi').last);

      // 200 € di costo, coperti per 120 € dal progetto Claude; i 500 € del
      // doppiaggio non servono a coprire Claude
      expect(find.text('Da recuperare 80 € di 200 €'), findsOneWidget);
    },
  );

  testWidgets('Più tipi: una riga ciascuna, più "Altri costi"', (tester) async {
    schermoAlto(tester);
    final a = FintoArchivio();
    progetto(a, 'Chatbot', TipoLavoro.claude, ricavo: 50, incassato: true);
    progetto(
      a,
      'Il bosco',
      TipoLavoro.doppiaggio,
      ricavo: 300,
      incassato: true,
      giorno: 2,
    );
    abbonamentoClaude(a);
    final dop = a.salvaCategoria(
      Categoria(
        id: '',
        nome: 'Doppiaggio',
        colore: 6,
        tipoLavoro: TipoLavoro.doppiaggio,
        creatoIl: DateTime(2026, 1, 2),
      ),
    );
    a.salvaCosto(
      Costo(
        id: '',
        nome: 'Microfono',
        tipo: TipoCosto.unaTantum,
        importo: 90,
        mesi: 6,
        inizio: DateTime(2026, 10, 5),
        categoriaId: dop,
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

    // Doppiaggio: 90 € coperti dai 300 € di utile (ne avanzano 210)
    expect(find.text('Da recuperare 0 € di 90 €'), findsOneWidget);
    // Claude: 200 € di costo, 50 € recuperati
    expect(find.text('Da recuperare 150 € di 200 €'), findsOneWidget);
    // Altri: 150 € di scrivania, coperti da quello che avanza dal doppiaggio
    expect(find.text('Altri costi'), findsOneWidget);
    expect(find.text('Da recuperare 0 € di 150 €'), findsOneWidget);
    expect(
      find.text(
        'Si copre con l\'utile che avanza dagli altri progetti incassati',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Categoria: si sceglie con quali progetti si recupera', (
    tester,
  ) async {
    schermoAlto(tester);
    final a = FintoArchivio();
    await avviaApp(tester, archivio: a, adesso: oggi);
    await tocca(tester, find.text('Costi').last);
    await tocca(tester, find.text('Gestisci categorie'));
    await tocca(tester, find.text('+ Nuova categoria'));

    expect(
      find.text(
        'I costi di questa categoria si dividono tra tutti i progetti.',
      ),
      findsOneWidget,
    );
    await scrivi(tester, 'campo-nome-categoria', 'Assistente AI');
    await tocca(tester, find.text('Claude'));
    expect(
      find.text(
        'I costi di questa categoria pesano e si recuperano solo con i progetti Claude.',
      ),
      findsOneWidget,
    );
    await tocca(tester, find.text('Salva').last);

    expect(a.tabellaCategorie.elenco.single.tipoLavoro, TipoLavoro.claude);
    expect(find.text('Turchese · 0 costi · progetti Claude'), findsOneWidget);

    // E si può tornare a "Tutti"
    await tocca(tester, find.text('Turchese · 0 costi · progetti Claude'));
    await tocca(tester, find.text('Tutti'));
    await tocca(tester, find.text('Salva').last);
    expect(a.tabellaCategorie.elenco.single.tipoLavoro, isNull);
  });

  testWidgets('Le categorie di partenza sono già legate al loro tipo', (
    tester,
  ) async {
    schermoAlto(tester);
    final a = FintoArchivio();
    await avviaApp(tester, archivio: a, adesso: oggi);
    await tocca(tester, find.text('Costi').last);
    await tocca(tester, find.text('Gestisci categorie'));
    await tocca(tester, find.text('Aggiungi quelle di partenza'));

    final tipi = {
      for (final c in a.tabellaCategorie.elenco) c.nome: c.tipoLavoro,
    };
    expect(tipi, {
      'Doppiaggio': TipoLavoro.doppiaggio,
      'Codice': TipoLavoro.codice,
      'Claude': TipoLavoro.claude,
      'Generale': null,
    });
    expect(find.text('Viola · 0 costi · progetti Claude'), findsOneWidget);
    expect(find.text('Grigio · 0 costi · tutti i progetti'), findsOneWidget);
  });

  testWidgets('Il modulo del costo ricorda con quali progetti si recupera', (
    tester,
  ) async {
    schermoAlto(tester);
    final a = FintoArchivio();
    a.salvaCategoria(
      Categoria(
        id: '',
        nome: 'Claude',
        colore: 8,
        tipoLavoro: TipoLavoro.claude,
        creatoIl: DateTime(2026),
      ),
    );
    a.salvaCategoria(
      Categoria(
        id: '',
        nome: 'Generale',
        colore: 9,
        creatoIl: DateTime(2026, 1, 2),
      ),
    );
    await avviaApp(tester, archivio: a, adesso: oggi);
    await tocca(tester, find.text('Costi').last);
    await tocca(tester, find.text('Aggiungi costo'));

    expect(find.textContaining('Pesa e si recupera solo con'), findsNothing);
    await tocca(tester, find.widgetWithText(InkWell, 'Claude').first);
    expect(
      find.text('Pesa e si recupera solo con i progetti Claude.'),
      findsOneWidget,
    );
    await tocca(tester, find.widgetWithText(InkWell, 'Generale').first);
    expect(find.textContaining('Pesa e si recupera solo con'), findsNothing);
  });

  testWidgets(
    'I lavori a giornata restano fuori dai costi anche con categoria "Altro"',
    (tester) async {
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
          creatoIl: DateTime(2026, 1, 1),
        ),
      );
      progetto(a, 'Lavoretto', TipoLavoro.altro, ore: 1, giorno: 2);
      final cat = a.salvaCategoria(
        Categoria(
          id: '',
          nome: 'Varie',
          colore: 9,
          tipoLavoro: TipoLavoro.altro,
          creatoIl: DateTime(2026),
        ),
      );
      a.salvaCosto(
        Costo(
          id: '',
          nome: 'Cancelleria',
          tipo: TipoCosto.abbonamento,
          importo: 10,
          inizio: DateTime(2026, 1),
          categoriaId: cat,
          creatoIl: DateTime(2026),
        ),
      );
      await avviaApp(tester, archivio: a, adesso: oggi);
      await tocca(tester, find.text('Costi').last);

      expect(find.text('Lavoretto 10 €'), findsOneWidget);
      expect(find.textContaining('Negozio'), findsNothing);
    },
  );
}
