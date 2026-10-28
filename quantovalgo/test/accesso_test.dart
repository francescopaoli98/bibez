import 'package:flutter_test/flutter_test.dart';
import 'package:quantovalgo/servizi/accesso.dart';
import 'package:quantovalgo/servizi/archivio.dart';

import 'finti.dart';

void main() {
  testWidgets('Senza utente si vede il login, non l\'app', (tester) async {
    await avviaApp(tester, utente: null);

    expect(find.text('Accedi con Google'), findsOneWidget);
    expect(find.text('Saldo del mese'), findsNothing);
  });

  testWidgets('Con l\'utente già salvato si apre direttamente la Home', (
    tester,
  ) async {
    final servizi = await avviaApp(tester);

    expect(find.text('Saldo del mese'), findsOneWidget);
    expect(find.text('Accedi con Google'), findsNothing);
    // Il profilo viene creato/aggiornato nel cloud
    expect(servizi.archivio.profiliSalvati, ['u1']);
  });

  testWidgets('Accedi con Google porta alla Home', (tester) async {
    final servizi = await avviaApp(tester, utente: null);

    await tester.tap(find.text('Accedi con Google'));
    await tester.pumpAndSettle();

    expect(servizi.accesso.accessiRichiesti, 1);
    expect(find.text('Saldo del mese'), findsOneWidget);
    expect(servizi.archivio.profiliSalvati, ['u1']);
  });

  testWidgets('Un errore di accesso viene spiegato e si può riprovare', (
    tester,
  ) async {
    final servizi = await avviaApp(tester, utente: null);
    servizi.accesso.erroreProssimoAccesso = const ErroreAccesso(
      'Serve internet per il primo accesso.',
    );

    await tester.tap(find.text('Accedi con Google'));
    await tester.pumpAndSettle();

    expect(find.text('Serve internet per il primo accesso.'), findsOneWidget);
    expect(find.text('Saldo del mese'), findsNothing);

    // Riprovando senza errore si entra
    servizi.accesso.erroreProssimoAccesso = null;
    await tester.tap(find.text('Accedi con Google'));
    await tester.pumpAndSettle();
    expect(find.text('Saldo del mese'), findsOneWidget);
  });

  testWidgets('Impostazioni mostra l\'account e Esci riporta al login', (
    tester,
  ) async {
    final servizi = await avviaApp(tester);

    await tester.tap(find.bySemanticsLabel('Impostazioni'));
    await tester.pumpAndSettle();
    expect(find.text('Francesco Prova'), findsOneWidget);
    expect(find.text('prova@example.com'), findsOneWidget);
    expect(find.text('Dati sincronizzati col cloud'), findsOneWidget);

    await tester.tap(find.text('Esci'));
    await tester.pumpAndSettle();

    expect(servizi.accesso.uscite, 1);
    expect(find.text('Accedi con Google'), findsOneWidget);
    expect(
      find.text('Impostazioni'),
      findsNothing,
    ); // la pagina non resta aperta
  });

  testWidgets('Offline lo stato dice che i dati sono sul telefono', (
    tester,
  ) async {
    final accessoArchivio = await avviaApp(tester);
    accessoArchivio.archivio.stato = StatoSincronizzazione.inAttesa;

    await tester.tap(find.bySemanticsLabel('Impostazioni'));
    await tester.pumpAndSettle();

    expect(find.text('Dati sul telefono, in attesa del cloud'), findsOneWidget);
  });

  testWidgets('Se il cloud rifiuta i dati lo dice chiaramente', (tester) async {
    final servizi = await avviaApp(tester);
    servizi.archivio.stato = StatoSincronizzazione.problema;

    await tester.tap(find.bySemanticsLabel('Impostazioni'));
    await tester.pumpAndSettle();

    expect(
      find.text('Il cloud rifiuta i dati: controlla le regole di Firestore'),
      findsOneWidget,
    );
  });

  testWidgets('Se Firebase non parte si spiega il problema', (tester) async {
    await avviaApp(tester, erroreAvvio: 'No Firebase App');

    expect(find.text('Il cloud non è configurato'), findsOneWidget);
    expect(find.text('No Firebase App'), findsOneWidget);
  });
}
