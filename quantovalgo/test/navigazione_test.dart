import 'package:flutter_test/flutter_test.dart';
import 'package:quantovalgo/app.dart';

void main() {
  testWidgets('L\'app si apre sulla Home', (tester) async {
    await tester.pumpWidget(const QuantoValgoApp());
    await tester.pumpAndSettle();

    expect(find.text('QuantoValgo'), findsOneWidget);
    expect(find.text('Saldo del mese'), findsOneWidget);
  });

  testWidgets('La barra in basso cambia scheda', (tester) async {
    await tester.pumpWidget(const QuantoValgoApp());

    for (final nome in ['Progetti', 'Preventivi', 'Costi']) {
      // Il testo compare anche nella barra: si tocca quello della barra.
      await tester.tap(find.text(nome).last);
      await tester.pumpAndSettle();
      expect(find.text(nome), findsWidgets);
    }

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Saldo del mese'), findsOneWidget);
  });

  testWidgets('Il + apre Nuovo lavoro e Indietro torna alla Home', (tester) async {
    await tester.pumpWidget(const QuantoValgoApp());

    await tester.tap(find.bySemanticsLabel('Nuovo lavoro'));
    await tester.pumpAndSettle();
    expect(find.text('Nuovo lavoro'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Indietro'));
    await tester.pumpAndSettle();
    expect(find.text('Saldo del mese'), findsOneWidget);
  });

  testWidgets('Dalla Home si aprono Clienti, Obiettivo e Impostazioni', (tester) async {
    await tester.pumpWidget(const QuantoValgoApp());

    Future<void> apriEChiudi(Future<void> Function() tocca, String titolo) async {
      await tocca();
      await tester.pumpAndSettle();
      expect(find.text(titolo), findsWidgets);
      await tester.tap(find.bySemanticsLabel('Indietro'));
      await tester.pumpAndSettle();
    }

    await apriEChiudi(() => tester.tap(find.text('Clienti')), 'Clienti');
    await apriEChiudi(() => tester.tap(find.text('Obiettivo')), 'Obiettivo');
    await apriEChiudi(
      () => tester.tap(find.bySemanticsLabel('Impostazioni')),
      'Impostazioni',
    );
  });
}
