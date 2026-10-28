import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantovalgo/logica/calcoli.dart';
import 'package:quantovalgo/logica/obiettivo.dart';
import 'package:quantovalgo/logica/saldo.dart';
import 'package:quantovalgo/modelli/costo.dart';
import 'package:quantovalgo/modelli/impostazioni.dart';
import 'package:quantovalgo/modelli/lavoro.dart';
import 'package:quantovalgo/modelli/sessione_ore.dart';
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

Future<void> scriviNumero(WidgetTester tester, String testo) async {
  await tester.enterText(
    find.descendant(
      of: find.byKey(const Key('campo-numero')),
      matching: find.byType(TextField),
    ),
    testo,
  );
  await tester.pump();
}

PianoObiettivo piano({
  double incassato = 0,
  double costi = 0,
  double ore = 0,
  double tasse = 22,
  double obiettivo = 1500,
}) => PianoObiettivo(
  saldoMese: SaldoMese(
    incassato: incassato,
    costiCondivisi: costi,
    costiDiretti: 0,
    utileProgetti: 0,
    oreProgetti: 0,
    regalato: 0,
  ),
  oreMese: ore,
  tasse: tasse,
  obiettivoNetto: obiettivo,
);

void main() {
  group('Calcoli di obiettivo, pareggio e tariffa', () {
    test('netto dopo tasse: 1.240 con tasse 22% → 967,20', () {
      final p = piano(incassato: 1890, costi: 650);
      expect(p.saldo, 1240);
      expect(p.importoTasse, closeTo(272.8, 0.001));
      expect(p.nettoDopoTasse, closeTo(967.2, 0.001));
      expect(p.avanzamento, closeTo(967.2 / 1500, 0.0001));
    });

    test('con saldo negativo non ci sono tasse', () {
      final p = piano(incassato: 100, costi: 300);
      expect(p.saldo, -200);
      expect(p.importoTasse, 0);
      expect(p.nettoDopoTasse, -200);
      expect(p.avanzamento, 0); // mai sotto zero
    });

    test('pareggio: i costi, e quanto manca per coprirli', () {
      expect(piano(incassato: 400, costi: 650).manca, 250);
      expect(piano(incassato: 900, costi: 650).manca, 0);
      expect(piano(costi: 650).pareggio, 650);
    });

    test('tariffa minima: (obiettivo netto ÷ 0,78 + costi) ÷ ore', () {
      final p = piano(costi: 650, ore: 52);
      expect(p.saldoNecessario, closeTo(1923.08, 0.01));
      expect(p.incassoNecessario, closeTo(2573.08, 0.01));
      expect(p.tariffaMinima, closeTo(49.48, 0.01));
    });

    test('senza ore o senza obiettivo la tariffa è vuota', () {
      expect(piano(ore: 0).tariffaMinima, isNull);
      expect(piano(ore: 10, obiettivo: 0).tariffaMinima, isNull);
      expect(piano(obiettivo: 0).avanzamento, isNull);
    });

    test('tasse al 100% non rompono i conti', () {
      final p = piano(incassato: 100, ore: 1, tasse: 100);
      expect(p.nettoDopoTasse.isFinite, isTrue);
      expect(p.tariffaMinima!.isFinite, isTrue);
    });
  });

  group('Impostazioni salvate', () {
    test('Dati vecchi o vuoti: valori di partenza', () {
      final i = Impostazioni.fromMap({'promemoria': false});
      expect(i.promemoria, isFalse);
      expect(i.tasse, 22);
      expect(i.obiettivoMensile, 0);
      expect(i.parametriPrezzo.sconto(Relazione.amico), 30);
      expect(i.parametriPrezzo.correzione(5), 20);
    });

    test('Quello che si salva si rilegge uguale', () {
      final i = const Impostazioni().copyWith(
        tasse: 25.5,
        obiettivoMensile: 1500,
        scontoRelazione: {...scontiPredefiniti, Relazione.amico: 40},
        correzioneLivello: {...correzioniPredefinite, 1: -30},
      );
      final letto = Impostazioni.fromMap(i.toMap());
      expect(letto.tasse, 25.5);
      expect(letto.obiettivoMensile, 1500);
      expect(letto.parametriPrezzo.sconto(Relazione.amico), 40);
      expect(letto.parametriPrezzo.sconto(Relazione.famiglia), 50);
      expect(letto.parametriPrezzo.correzione(1), -30);
      expect(letto.parametriPrezzo.correzione(3), 0);
    });
  });

  group('Schermate', () {
    testWidgets('Modifico tasse, sconto e livello da Impostazioni', (
      tester,
    ) async {
      schermoAlto(tester);
      final archivio = FintoArchivio();
      await avviaApp(tester, archivio: archivio, adesso: oggi);
      await tocca(tester, find.bySemanticsLabel('Impostazioni'));

      expect(find.text('22%'), findsOneWidget);
      await tocca(tester, find.byKey(const Key('riga-tasse')));
      await scriviNumero(tester, '25');
      await tocca(tester, find.text('Salva'));
      expect(archivio.impostazioniSalvate.tasse, 25);
      expect(find.text('25%'), findsOneWidget);

      await tocca(tester, find.byKey(const Key('riga-sconto-amico')));
      await scriviNumero(tester, '40');
      await tocca(tester, find.text('Salva'));
      expect(
        archivio.impostazioniSalvate.parametriPrezzo.sconto(Relazione.amico),
        40,
      );
      expect(find.text('40%'), findsOneWidget);

      await tocca(tester, find.byKey(const Key('riga-livello-1')));
      await scriviNumero(tester, '-30');
      await tocca(tester, find.text('Salva'));
      expect(archivio.impostazioniSalvate.parametriPrezzo.correzione(1), -30);
      expect(find.text('−30%'), findsOneWidget);
    });

    testWidgets('Un valore fuori scala non si salva e spiega perché', (
      tester,
    ) async {
      schermoAlto(tester);
      final archivio = FintoArchivio();
      await avviaApp(tester, archivio: archivio, adesso: oggi);
      await tocca(tester, find.bySemanticsLabel('Impostazioni'));

      await tocca(tester, find.byKey(const Key('riga-tasse')));
      await scriviNumero(tester, '150');
      await tocca(tester, find.text('Salva'));
      expect(find.text('Scrivi un numero da 0 a 99'), findsOneWidget);
      expect(archivio.impostazioniSalvate.tasse, 22);
    });

    testWidgets('Lo sconto cambiato vale nei nuovi prezzi (Clienti)', (
      tester,
    ) async {
      schermoAlto(tester);
      final archivio = FintoArchivio();
      archivio.salvaImpostazioni(
        const Impostazioni().copyWith(
          scontoRelazione: {...scontiPredefiniti, Relazione.amico: 45},
        ),
      );
      archivio.salvaLavoro(
        Lavoro(
          id: '',
          nome: 'Sito',
          tipo: TipoLavoro.codice,
          relazione: Relazione.amico,
          livello: 3,
          prezzoPieno: 500,
          prezzoFinale: 275,
          creatoIl: DateTime(2026, 10, 1),
        ),
      );
      await avviaApp(tester, archivio: archivio, adesso: oggi);
      expect(find.textContaining('Amico −45%'), findsOneWidget);
    });

    testWidgets('Obiettivo: avanzamento netto, pareggio e tariffa oraria', (
      tester,
    ) async {
      schermoAlto(tester);
      final archivio = FintoArchivio();
      archivio.salvaImpostazioni(
        const Impostazioni().copyWith(obiettivoMensile: 1500),
      );
      // Ottobre: 2.000 incassati, 500 di costi condivisi, 50 ore registrate
      final id = archivio.salvaLavoro(
        Lavoro(
          id: '',
          nome: 'Spot',
          tipo: TipoLavoro.altro,
          relazione: Relazione.nuovo,
          livello: 3,
          prezzoPieno: 2000,
          prezzoFinale: 2000,
          statoPagamento: StatoPagamento.incassato,
          dataIncasso: DateTime(2026, 10, 12),
          creatoIl: DateTime(2026, 10, 1),
        ),
      );
      archivio.salvaSottoprogetto(
        Sottoprogetto(
          id: '',
          lavoroId: id,
          nome: 'Tutto',
          ricavo: 2000,
          costiDiretti: 0,
          ore: 0,
          creatoIl: DateTime(2026, 10, 1),
        ),
      );
      archivio.salvaCosto(
        Costo(
          id: '',
          nome: 'Software',
          tipo: TipoCosto.abbonamento,
          importo: 500,
          inizio: DateTime(2026, 10, 1),
          creatoIl: DateTime(2026),
        ),
      );
      archivio.salvaSessione(
        SessioneOre(
          id: '',
          sottoprogettoId: 'x',
          lavoroId: id,
          inizio: DateTime(2026, 10, 5, 9),
          fine: DateTime(2026, 10, 5, 9).add(const Duration(minutes: 3000)),
          minuti: 3000,
          manuale: true,
          creatoIl: DateTime(2026, 10, 5),
        ),
      );
      await avviaApp(tester, archivio: archivio, adesso: oggi);

      await tocca(tester, find.text('Obiettivo'));
      // Saldo 1.500, tasse 22% = 330, netto 1.170 su 1.500 = 78%
      expect(find.text('78%'), findsOneWidget);
      expect(find.text('Netto 1.170 € su 1.500 €'), findsOneWidget);
      expect(find.text('330 €'), findsOneWidget);
      expect(
        find.text('Costi coperti: sei sopra il pareggio di 1.500 €.'),
        findsOneWidget,
      );
      // (1.500 ÷ 0,78 + 500) ÷ 50 h
      expect(find.text('48,46 €/h'), findsOneWidget);
    });

    testWidgets('Obiettivo: imposto da zero e senza ore la tariffa è vuota', (
      tester,
    ) async {
      schermoAlto(tester);
      final archivio = FintoArchivio();
      await avviaApp(tester, archivio: archivio, adesso: oggi);

      await tocca(tester, find.text('Obiettivo'));
      expect(find.text('Imposta obiettivo'), findsOneWidget);
      expect(
        find.text("Imposta l'obiettivo mensile per calcolarla."),
        findsOneWidget,
      );

      await tocca(tester, find.byKey(const Key('cambia-obiettivo')));
      await scriviNumero(tester, '1500');
      await tocca(tester, find.text('Salva'));
      expect(archivio.impostazioniSalvate.obiettivoMensile, 1500);
      expect(find.text('Cambia obiettivo'), findsOneWidget);
      expect(
        find.text(
          'Registra le ore del mese (cronometro o a mano) per calcolarla.',
        ),
        findsOneWidget,
      );
    });
  });
}
