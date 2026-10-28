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

Future<void> tocca(WidgetTester tester, Finder cosa) async {
  await tester.tap(cosa);
  await tester.pumpAndSettle();
}

/// Il saldo grande del riquadro in alto (l'unico testo da 48 punti).
String saldoGrande(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .firstWhere((t) => t.style?.fontSize == 48)
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
  testWidgets('Saldo del mese: incassato − costi, e guadagno all\'ora', (
    tester,
  ) async {
    schermoAlto(tester);
    final archivio = FintoArchivio();
    // Ottobre: 300 incassati con 50 di costi diretti e 5 ore → utile 250 → 50 €/h
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

    expect(find.text('ottobre 2026'), findsOneWidget);
    expect(find.text('+230 €'), findsOneWidget); // 300 − 50 − 20
    expect(find.text('In positivo'), findsOneWidget);
    expect(find.text('300 €'), findsOneWidget); // incassato
    expect(
      find.text('70 €'),
      findsOneWidget,
    ); // costi: 50 diretti + 20 condivisi
    expect(find.text('50 €/h'), findsOneWidget);
  });

  testWidgets('Le frecce portano ai mesi passati, ma non nel futuro', (
    tester,
  ) async {
    schermoAlto(tester);
    final archivio = FintoArchivio();
    incassato(archivio, 'Vecchio', incasso: DateTime(2026, 9, 15), ricavo: 100);
    incassato(archivio, 'Nuovo', incasso: DateTime(2026, 10, 15), ricavo: 40);
    await avviaApp(tester, archivio: archivio, adesso: oggi);

    // Mese corrente: solo l'incasso di ottobre, e la freccia avanti è spenta
    expect(saldoGrande(tester), '+40 €');
    await tocca(tester, find.bySemanticsLabel('Mese successivo'));
    expect(find.text('ottobre 2026'), findsOneWidget);

    await tocca(tester, find.bySemanticsLabel('Mese precedente'));
    expect(find.text('settembre 2026'), findsOneWidget);
    expect(saldoGrande(tester), '+100 €');

    await tocca(tester, find.bySemanticsLabel('Mese successivo'));
    expect(find.text('ottobre 2026'), findsOneWidget);
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

    expect(find.text('−90 €'), findsOneWidget);
    expect(find.text('In negativo'), findsOneWidget);
    expect(
      find.text('—'),
      findsOneWidget,
    ); // niente ore: niente guadagno all'ora
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
    expect(find.text('+30 €'), findsWidgets);
    expect(find.text('+60 €'), findsNothing);
  });

  testWidgets('Sconti regalati dei progetti creati nel mese', (tester) async {
    schermoAlto(tester);
    final archivio = FintoArchivio();
    incassato(
      archivio,
      'Spot',
      incasso: DateTime(2026, 10, 20),
      ricavo: 700,
      prezzoPieno: 1000,
      creato: DateTime(2026, 10, 2),
    );
    await avviaApp(tester, archivio: archivio, adesso: oggi);

    expect(find.text('Sconti regalati in ottobre: 300 €'), findsOneWidget);

    // Nel mese prima non c'è nessun progetto creato: il riquadro sparisce
    await tocca(tester, find.bySemanticsLabel('Mese precedente'));
    expect(find.textContaining('Sconti regalati'), findsNothing);
  });

  testWidgets('Il riquadro Da incassare della Home porta alla lista', (
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
        scadenza: DateTime(2026, 10, 10),
        creatoIl: DateTime(2026, 10, 1),
      ),
    );
    await avviaApp(tester, archivio: archivio, adesso: oggi);

    expect(find.text('1 lavoro · 1 in ritardo'), findsOneWidget);
    await tocca(tester, find.text('Vedi'));
    expect(find.text('In ritardo di 18 giorni'), findsOneWidget);
  });
}
