import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantovalgo/modelli/cliente.dart';
import 'package:quantovalgo/modelli/impostazioni.dart';
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

/// Un archivio con Luca (amico, −30%) e Radio locale (cliente nuovo).
FintoArchivio conClienti() {
  final a = FintoArchivio();
  a.salvaCliente(
    Cliente(
      id: '',
      nome: 'Radio locale',
      relazione: Relazione.nuovo,
      creatoIl: DateTime(2026, 1, 1),
    ),
  );
  a.salvaCliente(
    Cliente(
      id: '',
      nome: 'Luca',
      relazione: Relazione.amico,
      creatoIl: DateTime(2026, 2, 1),
    ),
  );
  return a;
}

/// Passo 3: porta il tempo a 5 h 45 (240 min + 7 scatti da 15) con la trasferta.
Future<void> cinqueOreEMezza(
  WidgetTester tester, {
  bool trasferta = true,
}) async {
  await tocca(tester, find.text('Mezza giornata'));
  for (var i = 0; i < 7; i++) {
    await tocca(tester, find.bySemanticsLabel('Più tempo'));
  }
  expect(
    tester.widget<Text>(find.byKey(const Key('tempo-scelto'))).data,
    '5 h 45',
  );
  if (trasferta) {
    await tocca(tester, find.byKey(const Key('interruttore-trasferta')));
  }
}

void main() {
  group('Il percorso in tre domande', () {
    testWidgets('Passo 1: cinque tasselli e una X per uscire', (tester) async {
      schermoAlto(tester);
      await avviaApp(tester, adesso: oggi);
      await tocca(tester, find.bySemanticsLabel('Nuovo lavoro'));

      expect(find.text('Che lavoro è?'), findsOneWidget);
      for (final t in [
        'Doppiaggio',
        'Codice',
        'Claude',
        'A giornata',
        'Altro',
      ]) {
        expect(find.text(t), findsOneWidget);
      }
      expect(find.bySemanticsLabel('Passo 1 di 3'), findsOneWidget);
    });

    testWidgets('Il caso degli amici: 5 h 45, trasferta 20 km → chiedi 105 €', (
      tester,
    ) async {
      schermoAlto(tester);
      final archivio = conClienti();
      await avviaApp(tester, archivio: archivio, adesso: oggi);
      await tocca(tester, find.bySemanticsLabel('Nuovo lavoro'));
      await tocca(tester, find.text('Altro'));

      // Passo 2: Luca è un amico, sconto 30%
      expect(find.text('Per chi è?'), findsOneWidget);
      expect(find.text('Amico · sconto 30%'), findsOneWidget);
      expect(find.text('Cliente nuovo · prezzo pieno'), findsOneWidget);
      await tocca(tester, find.byKey(const Key('chi-Luca')));

      // Passo 3
      expect(find.text('Quanto tempo ci metti?'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('tempo-scelto'))).data,
        '1 h',
      );
      await cinqueOreEMezza(tester);
      expect(find.text('20 km andata e ritorno · 6 €'), findsOneWidget);
      await tocca(tester, find.text('Quanto chiedo?'));

      // Il prezzo giusto, con il conto
      expect(find.text('Per Luca chiedi'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('prezzo-giusto'))).data,
        '105 €',
      );
      expect(find.text('5 h 45 min × 25 € l\'ora'), findsOneWidget);
      expect(find.text('144 €'), findsOneWidget);
      expect(find.text('Sconto amico'), findsOneWidget);
      expect(find.text('−43 €'), findsOneWidget);
      expect(find.text('+6 €'), findsOneWidget);
      expect(find.text('Arrotondo'), findsOneWidget);
      expect(find.text('−2 €'), findsOneWidget);
      expect(find.text('A te restano circa 17 € all\'ora'), findsOneWidget);

      // Si crea il lavoro
      await tocca(tester, find.text('Va bene, crea il lavoro'));
      final luca = archivio.tabellaClienti.elenco.firstWhere(
        (c) => c.nome == 'Luca',
      );
      final lavoro = archivio.tabellaLavori.elenco.single;
      expect(lavoro.nome, 'Lavoro per Luca');
      expect(lavoro.tipo, TipoLavoro.altro);
      expect(lavoro.clienteId, luca.id);
      expect(lavoro.relazione, Relazione.amico);
      expect(lavoro.prezzoFinale, 105);
      expect(lavoro.prezzoPieno, 150); // tempo + trasferta senza sconto
      final parte = archivio.tabellaSotto.elenco.single;
      expect(parte.nome, 'Lavoro intero');
      expect(parte.ricavo, 105);
      expect(
        parte.costiDiretti,
        closeTo(6, 0.001),
      ); // la benzina non è guadagno
      expect(parte.ore, 5.75);

      // Si apre la pagina del lavoro, e Indietro porta dritto alla Home
      expect(find.text('Mi hanno pagato'), findsOneWidget);
      expect(find.text('105 €'), findsWidgets);
      await tester.tap(find.bySemanticsLabel('Indietro'));
      await tester.pumpAndSettle();
      expect(find.text('Questo mese ti resta'), findsOneWidget);
    });

    testWidgets('Senza trasferta e senza cliente: niente sconto né trasferta', (
      tester,
    ) async {
      schermoAlto(tester);
      final archivio = conClienti();
      await avviaApp(tester, archivio: archivio, adesso: oggi);
      await tocca(tester, find.bySemanticsLabel('Nuovo lavoro'));
      await tocca(tester, find.text('Doppiaggio'));
      await tocca(tester, find.byKey(const Key('chi-nessuno')));

      await cinqueOreEMezza(tester, trasferta: false);
      await tocca(tester, find.text('Quanto chiedo?'));

      // 5,75 h × 25 € = 143,75 → 145 €
      expect(find.text('Chiedi'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('prezzo-giusto'))).data,
        '145 €',
      );
      expect(find.textContaining('Sconto'), findsNothing);
      expect(find.text('Trasferta'), findsNothing);

      await tocca(tester, find.text('Va bene, crea il lavoro'));
      final lavoro = archivio.tabellaLavori.elenco.single;
      expect(lavoro.nome, 'Doppiaggio');
      expect(lavoro.clienteId, isNull);
      expect(lavoro.relazione, Relazione.nuovo);
      expect(archivio.tabellaSotto.elenco.single.costiDiretti, 0);
    });

    testWidgets('Cambia la cifra e il nome: si salva quello che hai scelto', (
      tester,
    ) async {
      schermoAlto(tester);
      final archivio = conClienti();
      await avviaApp(tester, archivio: archivio, adesso: oggi);
      await tocca(tester, find.bySemanticsLabel('Nuovo lavoro'));
      await tocca(tester, find.text('Codice'));
      await tocca(tester, find.byKey(const Key('chi-Luca')));
      await tocca(tester, find.text('Quanto chiedo?')); // 1 ora, di partenza

      // 25 − 30% = 17,5 → 20 €
      expect(
        tester.widget<Text>(find.byKey(const Key('prezzo-giusto'))).data,
        '20 €',
      );

      await tocca(tester, find.byKey(const Key('cambia-cifra')));
      await scrivi(tester, 'campo-numero', '40');
      await tocca(tester, find.text('Salva'));
      expect(
        tester.widget<Text>(find.byKey(const Key('prezzo-giusto'))).data,
        '40 €',
      );
      expect(find.text('Cifra scelta da te'), findsOneWidget);

      await scrivi(tester, 'campo-nome', 'Sito per Luca');
      await tocca(tester, find.text('Va bene, crea il lavoro'));
      final lavoro = archivio.tabellaLavori.elenco.single;
      expect(lavoro.nome, 'Sito per Luca');
      expect(lavoro.prezzoFinale, 40);
      expect(archivio.tabellaSotto.elenco.single.ricavo, 40);
    });

    testWidgets('Una persona nuova si crea al volo e il percorso prosegue', (
      tester,
    ) async {
      schermoAlto(tester);
      final archivio = FintoArchivio();
      await avviaApp(tester, archivio: archivio, adesso: oggi);
      await tocca(tester, find.bySemanticsLabel('Nuovo lavoro'));
      await tocca(tester, find.text('Claude'));

      await tocca(tester, find.byKey(const Key('chi-nuova')));
      await scrivi(tester, 'campo-nome', 'Marta');
      await tocca(tester, find.text('Famiglia'));
      await tocca(tester, find.text('Salva'));

      final marta = archivio.tabellaClienti.elenco.single;
      expect(marta.nome, 'Marta');
      expect(marta.relazione, Relazione.famiglia);
      expect(find.text('Quanto tempo ci metti?'), findsOneWidget);

      await tocca(tester, find.text('Quanto chiedo?'));
      expect(find.text('Per Marta chiedi'), findsOneWidget);
      expect(find.text('Sconto famiglia'), findsOneWidget);
    });

    testWidgets('Trasferta: i km si cambiano toccando la riga', (tester) async {
      schermoAlto(tester);
      await avviaApp(tester, archivio: conClienti(), adesso: oggi);
      await tocca(tester, find.bySemanticsLabel('Nuovo lavoro'));
      await tocca(tester, find.text('Altro'));
      await tocca(tester, find.byKey(const Key('chi-nessuno')));

      await tocca(tester, find.byKey(const Key('km-trasferta')));
      await scrivi(tester, 'campo-numero', '30');
      await tocca(tester, find.text('Salva'));
      expect(find.text('30 km andata e ritorno · 9 €'), findsOneWidget);
    });

    testWidgets('A giornata: si va al modulo breve del negozio', (
      tester,
    ) async {
      schermoAlto(tester);
      await avviaApp(tester, adesso: oggi);
      await tocca(tester, find.bySemanticsLabel('Nuovo lavoro'));
      await tocca(tester, find.text('A giornata'));
      expect(find.text('Guadagno netto al giorno (€)'), findsOneWidget);
    });

    testWidgets(
      '"Non lo so: guarda i prezzi di mercato" apre il modulo con tipo e cliente già scelti',
      (tester) async {
        schermoAlto(tester);
        await avviaApp(tester, archivio: conClienti(), adesso: oggi);
        await tocca(tester, find.bySemanticsLabel('Nuovo lavoro'));
        await tocca(tester, find.text('Codice'));
        await tocca(tester, find.byKey(const Key('chi-Luca')));
        await tocca(tester, find.text('Non lo so: guarda i prezzi di mercato'));

        expect(find.text('Prezzo di mercato'), findsOneWidget);
        final cliente = tester.widget<TextField>(
          find.descendant(
            of: find.byKey(const Key('campo-cliente')),
            matching: find.byType(TextField),
          ),
        );
        expect(cliente.controller!.text, 'Luca');
        // L'amico ha già lo sconto scelto
        expect(find.text('Con sconto amico (−30%) chiedi'), findsOneWidget);
      },
    );

    testWidgets('Tariffa oraria e rimborso al km si cambiano da Impostazioni', (
      tester,
    ) async {
      schermoAlto(tester);
      final archivio = FintoArchivio();
      await avviaApp(tester, archivio: archivio, adesso: oggi);
      await apriDalMenu(tester, 'Impostazioni');

      expect(find.text('25 €/h'), findsOneWidget);
      expect(find.text('0,30 €'), findsOneWidget);

      await tocca(tester, find.byKey(const Key('riga-tariffa')));
      await scrivi(tester, 'campo-numero', '30');
      await tocca(tester, find.text('Salva'));
      expect(archivio.impostazioniSalvate.tariffaOraria, 30);
      expect(find.text('30 €/h'), findsOneWidget);

      await tocca(tester, find.byKey(const Key('riga-km')));
      await scrivi(tester, 'campo-numero', '0,4');
      await tocca(tester, find.text('Salva'));
      expect(archivio.impostazioniSalvate.rimborsoKm, 0.4);
      expect(find.text('0,40 €'), findsOneWidget);
    });

    testWidgets('La tariffa scelta in Impostazioni cambia il prezzo', (
      tester,
    ) async {
      schermoAlto(tester);
      final archivio = FintoArchivio();
      archivio.salvaImpostazioni(
        const Impostazioni().copyWith(tariffaOraria: 40, rimborsoKm: 0.5),
      );
      await avviaApp(tester, archivio: archivio, adesso: oggi);
      await tocca(tester, find.bySemanticsLabel('Nuovo lavoro'));
      await tocca(tester, find.text('Altro'));
      await tocca(tester, find.byKey(const Key('chi-nessuno')));
      await tocca(tester, find.text('Quanto chiedo?')); // 1 ora

      expect(
        tester.widget<Text>(find.byKey(const Key('prezzo-giusto'))).data,
        '40 €',
      );
      expect(find.text('1 h × 40 € l\'ora'), findsOneWidget);
    });
  });
}
