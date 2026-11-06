import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantovalgo/logica/introiti.dart';
import 'package:quantovalgo/modelli/costo.dart';
import 'package:quantovalgo/modelli/impostazioni.dart';
import 'package:quantovalgo/modelli/introito.dart';

import 'finti.dart';
import 'home_test.dart' show oggi, saldoGrande, schermoAlto, tocca;

Introito introito(double importo, DateTime data, {String nota = ''}) =>
    Introito(id: '', importo: importo, data: data, nota: nota, creatoIl: data);

void main() {
  group('Guadagni veloci: calcoli', () {
    test('la somma ignora importi nulli o negativi', () {
      final d = DateTime(2026, 10, 3);
      expect(
        totaleIntroiti([introito(50, d), introito(0, d), introito(-5, d)]),
        50,
      );
    });

    test('toMap e fromMap tengono importo, giorno e nota', () {
      final i = introito(42.5, DateTime(2026, 10, 3), nota: 'Vendita usato');
      final copia = Introito.fromMap('x', i.toMap());
      expect(copia.importo, 42.5);
      expect(copia.data, DateTime(2026, 10, 3));
      expect(copia.nota, 'Vendita usato');
    });
  });

  group('Guadagni veloci: nei conti', () {
    testWidgets('entrano nel saldo del mese, non in quello di un altro', (
      tester,
    ) async {
      schermoAlto(tester);
      final archivio = FintoArchivio()
        ..salvaIntroito(introito(120, DateTime(2026, 10, 5)))
        ..salvaIntroito(introito(80, DateTime(2026, 9, 28)));
      await avviaApp(tester, archivio: archivio, adesso: oggi);

      // Ottobre: solo i 120 € di ottobre
      expect(saldoGrande(tester), contains('120'));
    });

    testWidgets('dal guadagno si tolgono le spese del mese', (tester) async {
      schermoAlto(tester);
      final archivio = FintoArchivio()
        ..salvaIntroito(introito(100, DateTime(2026, 10, 5)))
        ..salvaCosto(
          Costo(
            id: '',
            nome: 'Internet',
            tipo: TipoCosto.fisso,
            importo: 30,
            inizio: DateTime(2026, 10),
            creatoIl: DateTime(2026, 10),
          ),
        );
      await avviaApp(tester, archivio: archivio, adesso: oggi);
      // 100 entrati − 30 di spesa fissa
      expect(saldoGrande(tester), contains('70'));
    });
  });

  group('Guadagni veloci: schermate', () {
    testWidgets('dalla Home aggiungo un guadagno e subito conta', (
      tester,
    ) async {
      schermoAlto(tester);
      final app = await avviaApp(tester, adesso: oggi);

      await tocca(tester, find.byKey(const Key('guadagno-veloce')));
      await tester.enterText(
        find.byKey(const Key('campo-importo-introito')),
        '75',
      );
      await tester.enterText(
        find.byKey(const Key('campo-nota-introito')),
        'Vendita usato',
      );
      await tocca(tester, find.byKey(const Key('salva-introito')));

      final salvati = app.archivio.tabellaIntroiti.elenco;
      expect(salvati, hasLength(1));
      expect(salvati.single.importo, 75);
      expect(salvati.single.nota, 'Vendita usato');
      // "Oggi" è il giorno di partenza
      expect(salvati.single.data, DateTime(2026, 10, 28));
      expect(saldoGrande(tester), contains('75'));
    });

    testWidgets('senza importo non salva e dice cosa manca', (tester) async {
      schermoAlto(tester);
      final app = await avviaApp(tester, adesso: oggi);

      await tocca(tester, find.byKey(const Key('guadagno-veloce')));
      await tocca(tester, find.byKey(const Key('salva-introito')));

      expect(find.text('Scrivi quanto hai preso'), findsOneWidget);
      expect(app.archivio.tabellaIntroiti.elenco, isEmpty);
    });

    testWidgets('"Ieri" mette il giorno prima', (tester) async {
      schermoAlto(tester);
      final app = await avviaApp(tester, adesso: oggi);

      await tocca(tester, find.byKey(const Key('guadagno-veloce')));
      await tester.enterText(
        find.byKey(const Key('campo-importo-introito')),
        '20',
      );
      await tocca(tester, find.text('Ieri'));
      await tocca(tester, find.byKey(const Key('salva-introito')));

      expect(
        app.archivio.tabellaIntroiti.elenco.single.data,
        DateTime(2026, 10, 27),
      );
    });

    testWidgets('dal menu Altro vedo l\'elenco, correggo e tolgo', (
      tester,
    ) async {
      schermoAlto(tester);
      final archivio = FintoArchivio()
        ..salvaIntroito(introito(50, DateTime(2026, 10, 10), nota: 'Mance'));
      await avviaApp(tester, archivio: archivio, adesso: oggi);

      await apriDalMenu(tester, 'Guadagni');
      expect(find.text('Mance'), findsOneWidget);
      expect(find.byKey(const Key('totale-introiti')), findsOneWidget);

      // Correggo l'importo
      await tocca(tester, find.text('Mance'));
      await tester.enterText(
        find.byKey(const Key('campo-importo-introito')),
        '65',
      );
      await tocca(tester, find.byKey(const Key('salva-introito')));
      expect(archivio.tabellaIntroiti.elenco.single.importo, 65);

      // Lo tolgo
      await tocca(tester, find.text('Mance'));
      await tocca(tester, find.text('Togli questo guadagno'));
      await tocca(tester, find.text('Togli'));
      expect(archivio.tabellaIntroiti.elenco, isEmpty);
      expect(find.text('Nessun guadagno veloce'), findsOneWidget);
    });

    testWidgets('contano anche per l\'obiettivo netto', (tester) async {
      schermoAlto(tester);
      final archivio = FintoArchivio()
        ..impostazioniSalvate = const Impostazioni(
          tasse: 20,
          obiettivoMensile: 1000,
        )
        ..salvaIntroito(introito(500, DateTime(2026, 10, 2)));
      await avviaApp(tester, archivio: archivio, adesso: oggi);

      await apriDalMenu(tester, 'Obiettivo');
      // 500 € lordi, tasse 20% → 400 € netti
      expect(find.textContaining('400'), findsWidgets);
    });
  });
}
