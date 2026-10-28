import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantovalgo/widget/pulsante_lucido.dart';

void main() {
  testWidgets('Il pulsante si schiaccia mentre è premuto e poi torna normale',
      (tester) async {
    var premuti = 0;
    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: PulsanteLucido(etichetta: 'Prova', onPressed: () => premuti++),
      ),
    ));

    double scala() => tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;
    expect(scala(), 1);

    final dito = await tester.startGesture(tester.getCenter(find.text('Prova')));
    await tester.pump();
    expect(scala(), lessThan(1)); // schiacciato

    await dito.up();
    await tester.pumpAndSettle();
    expect(scala(), 1); // tornato su
    expect(premuti, 1);
  });

  testWidgets('Un pulsante spento non reagisce', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Center(child: PulsanteLucido(etichetta: 'Spento', onPressed: null)),
    ));
    expect(find.byType(AnimatedScale), findsNothing);
  });
}
