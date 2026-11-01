import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'finti.dart';

void main() {
  testWidgets('L\'app si apre sulla Home, senza barra in basso', (
    tester,
  ) async {
    await avviaApp(tester);

    expect(find.text('Ciao Francesco'), findsOneWidget);
    expect(find.text('Questo mese ti resta'), findsOneWidget);
    expect(find.text('Nuovo lavoro'), findsOneWidget);
    // Le vecchie schede non ci sono più: tutto sta in "Altro"
    expect(find.text('Preventivi'), findsNothing);
    expect(find.text('Progetti'), findsNothing);
  });

  testWidgets('"Altro" apre sei tasselli e ognuno apre la sua pagina', (
    tester,
  ) async {
    await avviaApp(tester);

    // Siamo già nel menu: si tocca il tassello e si torna indietro
    Future<void> apriEChiudi(String voce, String titolo) async {
      await tester.tap(find.text(voce));
      await tester.pumpAndSettle();
      expect(find.text(titolo), findsWidgets);
      await tester.tap(find.bySemanticsLabel('Indietro'));
      await tester.pumpAndSettle(); // torna al menu
    }

    await tester.tap(find.bySemanticsLabel('Altro'));
    await tester.pumpAndSettle();
    expect(find.text('Cosa cerchi?'), findsOneWidget);

    await apriEChiudi('Lavori', 'Lavori');
    await apriEChiudi('Spese', 'Spese');
    await apriEChiudi('Clienti', 'Clienti');
    await apriEChiudi('Obiettivo', 'Obiettivo');
    await apriEChiudi('Preventivi', 'Preventivi');
    await apriEChiudi('Impostazioni', 'Impostazioni');
  });

  testWidgets(
    'Il pulsante verde apre Nuovo lavoro e Indietro torna alla Home',
    (tester) async {
      await avviaApp(tester);

      await tester.tap(find.bySemanticsLabel('Nuovo lavoro'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsWidgets);

      await tester.tap(find.bySemanticsLabel('Indietro'));
      await tester.pumpAndSettle();
      expect(find.text('Questo mese ti resta'), findsOneWidget);
    },
  );
}
