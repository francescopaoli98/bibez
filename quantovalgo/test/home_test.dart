import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantovalgo/modelli/costo.dart';
import 'package:quantovalgo/modelli/giornata.dart';
import 'package:quantovalgo/modelli/impostazioni.dart';
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

/// La cifra grande nell'anello (l'unico testo da 52 punti).
String saldoGrande(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .firstWhere((t) => t.style?.fontSize == 52)
    .data!;

/// Progetto incassato il [incasso] con un solo sottoprogetto.
void incassato(
  FintoArchivio a,
  String nome, {
  required DateTime incasso,
  required double ricavo,
  double costi = 0,
  double ore = 0,
  double prezzoPieno = 0,
  DateTime? creato,
}) {
  final id = a.salvaLavoro(
    Lavoro(
      id: '',
      nome: nome,
      tipo: TipoLavoro.altro,
      relazione: Relazione.nuovo,
      livello: 3,
      prezzoPieno: prezzoPieno,
      prezzoFinale: ricavo,
      statoPagamento: StatoPagamento.incassato,
      dataIncasso: incasso,
      creatoIl: creato ?? incasso,
    ),
  );
  a.salvaSottoprogetto(
    Sottoprogetto(
      id: '',
      lavoroId: id,
      nome: 'Parte unica',
      ricavo: ricavo,
      costiDiretti: costi,
      ore: ore,
      creatoIl: incasso,
    ),
  );
}

void main() {
  testWidgets('Anello: quanto ti resta, incassato e spese', (tester) async {
    schermoAlto(tester);
    final archivio = FintoArchivio();
    // Ottobre: 300 incassati con 50 di costi diretti e 5 ore
    incassato(
      archivio,
      'Spot',
      incasso: DateTime(2026, 10, 12),
      ricavo: 300,
      costi: 50,
      ore: 5,
    );
    // Abbonamento da ottobre: 20 € di costi condivisi
    archivio.salvaCosto(
      Costo(
        id: '',
        nome: 'Software audio',
        tipo: TipoCosto.abbonamento,
        importo: 20,
        inizio: DateTime(2026, 10, 3),
        creatoIl: DateTime(2026),
      ),
    );
    await avviaApp(tester, archivio: archivio, adesso: oggi);

    expect(find.text('Ciao Francesco'), findsOneWidget);
    expect(find.text('ottobre 2026'), findsOneWidget);
    expect(find.text('Questo mese ti resta'), findsOneWidget);
    expect(saldoGrande(tester), '+230 €'); // 300 − 50 − 20
    expect(find.text('Incassato 300 €'), findsOneWidget);
    expect(
      find.text('Spese 70 €'),
      findsOneWidget,
    ); // 50 diretti + 20 condivisi
    // Senza obiettivo l'anello non dice una percentuale
    expect(find.text('Il mese in dettaglio'), findsOneWidget);
  });

  testWidgets('Con un obiettivo l\'anello dice a che punto sei', (
    tester,
  ) async {
    schermoAlto(tester);
    final archivio = FintoArchivio();
    archivio.salvaImpostazioni(
      const Impostazioni().copyWith(obiettivoMensile: 1000),
    );
    incassato(archivio, 'Spot', incasso: DateTime(2026, 10, 12), ricavo: 1000);
    await avviaApp(tester, archivio: archivio, adesso: oggi);

    // Saldo 1.000, tasse 22% → netto 780 su 1.000
    expect(find.text('78% del tuo obiettivo'), findsOneWidget);
  });

  testWidgets('Il mese si sceglie da un foglio, solo indietro nel tempo', (
    tester,
  ) async {
    schermoAlto(tester);
    final archivio = FintoArchivio();
    incassato(archivio, 'Vecchio', incasso: DateTime(2026, 9, 15), ricavo: 100);
    incassato(archivio, 'Nuovo', incasso: DateTime(2026, 10, 15), ricavo: 40);
    await avviaApp(tester, archivio: archivio, adesso: oggi);

    expect(saldoGrande(tester), '+40 €');

    await tocca(tester, find.byKey(const Key('scegli-mese')));
    // Dodici mesi, dal corrente all'indietro: niente futuro
    expect(find.text('ottobre 2026'), findsWidgets);
    expect(find.text('novembre 2026'), findsNothing);
    await tocca(tester, find.byKey(const Key('mese-2026-9')));

    expect(find.text('settembre 2026'), findsOneWidget);
    expect(saldoGrande(tester), '+100 €');

    // Tornando al mese corrente
    await tocca(tester, find.byKey(const Key('scegli-mese')));
    await tocca(tester, find.byKey(const Key('mese-2026-10')));
    expect(saldoGrande(tester), '+40 €');
  });

  testWidgets('Un mese in negativo: costi senza incassi', (tester) async {
    schermoAlto(tester);
    final archivio = FintoArchivio();
    archivio.salvaCosto(
      Costo(
        id: '',
        nome: 'Microfono',
        tipo: TipoCosto.unaTantum,
        importo: 90,
        inizio: DateTime(2026, 10, 5),
        creatoIl: DateTime(2026),
      ),
    );
    await avviaApp(tester, archivio: archivio, adesso: oggi);

    expect(saldoGrande(tester), '−90 €');
    expect(find.text('Spese 90 €'), findsOneWidget);
  });

  testWidgets('Le giornate già fatte contano nel loro mese, le future no', (
    tester,
  ) async {
    schermoAlto(tester);
    final archivio = FintoArchivio();
    final id = archivio.salvaLavoro(
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
    for (final giorno in [DateTime(2026, 10, 26), DateTime(2026, 10, 29)]) {
      archivio.salvaGiornata(
        Giornata(
          id: '',
          lavoroId: id,
          data: giorno,
          importo: 30,
          creatoIl: DateTime(2026, 10, 1),
        ),
      );
    }
    await avviaApp(tester, archivio: archivio, adesso: oggi);

    // Solo il 26 è già fatto; il 29 è in programma
    expect(saldoGrande(tester), '+30 €');
    expect(find.text('Incassato 30 €'), findsOneWidget);
  });

  testWidgets('Toccando l\'anello: il mese in dettaglio, con i regali', (
    tester,
  ) async {
    schermoAlto(tester);
    final archivio = FintoArchivio();
    incassato(
      archivio,
      'Spot',
      incasso: DateTime(2026, 10, 20),
      ricavo: 700,
      costi: 100,
      ore: 10,
      prezzoPieno: 1000,
      creato: DateTime(2026, 10, 2),
    );
    await avviaApp(tester, archivio: archivio, adesso: oggi);

    await tocca(
      tester,
      find.bySemanticsLabel('Il tuo mese, tocca per i dettagli'),
    );
    expect(find.text('Il mese di ottobre'), findsOneWidget);
    expect(find.text('Incassato'), findsOneWidget);
    expect(find.text('Sconti regalati'), findsOneWidget);
    expect(find.text('300 €'), findsOneWidget); // 1.000 − 700
    expect(find.text('60 €/h'), findsOneWidget); // utile 600 ÷ 10 h

    // Il mese prima non ha progetti creati: regali a zero, niente €/h
    await tocca(tester, find.bySemanticsLabel('Mese precedente'));
    expect(find.text('0 €'), findsWidgets);
  });

  testWidgets(
    'Ti devono: segno di spunta per incassare, e l\'elenco completo',
    (tester) async {
      schermoAlto(tester);
      final archivio = FintoArchivio();
      archivio.salvaLavoro(
        Lavoro(
          id: '',
          nome: 'Radio',
          tipo: TipoLavoro.altro,
          relazione: Relazione.nuovo,
          livello: 3,
          prezzoPieno: 450,
          prezzoFinale: 450,
          scadenza: DateTime(2026, 10, 10),
          creatoIl: DateTime(2026, 10, 1),
        ),
      );
      await avviaApp(tester, archivio: archivio, adesso: oggi);

      expect(find.text('Ti devono'), findsOneWidget);
      expect(find.text('Radio · 450 €'), findsOneWidget);
      expect(find.text('In ritardo di 18 giorni'), findsOneWidget);

      // Toccando "Ti devono" si apre l'elenco completo
      await tocca(tester, find.byKey(const Key('ti-devono')));
      expect(find.text('Da incassare'), findsWidgets);
      await tocca(tester, find.bySemanticsLabel('Indietro'));

      // Un tocco sulla spunta e non ti deve più niente
      await tocca(tester, find.bySemanticsLabel('Segna incassato Radio'));
      expect(
        archivio.tabellaLavori.elenco.single.statoPagamento,
        StatoPagamento.incassato,
      );
      expect(find.text('Nessuno ti deve soldi'), findsOneWidget);
    },
  );

  testWidgets('Toccando una riga di "Ti devono" si apre il lavoro', (
    tester,
  ) async {
    schermoAlto(tester);
    final archivio = FintoArchivio();
    archivio.salvaLavoro(
      Lavoro(
        id: '',
        nome: 'Radio',
        tipo: TipoLavoro.altro,
        relazione: Relazione.nuovo,
        livello: 3,
        prezzoPieno: 450,
        prezzoFinale: 450,
        creatoIl: DateTime(2026, 10, 1),
      ),
    );
    await avviaApp(tester, archivio: archivio, adesso: oggi);

    await tocca(tester, find.text('Radio · 450 €'));
    expect(find.text('Mi hanno pagato'), findsOneWidget);
    expect(find.text('Senza scadenza'), findsOneWidget);
  });
}
