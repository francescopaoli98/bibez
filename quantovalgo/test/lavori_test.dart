import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantovalgo/modelli/cliente.dart';
import 'package:quantovalgo/modelli/lavoro.dart';
import 'package:quantovalgo/modelli/tipi.dart';

import 'finti.dart';

/// Schermo molto alto: tutti i campi sono visibili senza scorrere.
void schermoAlto(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 3200);
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

/// Apre "Nuovo lavoro" con il + verde della barra.
Future<void> apriNuovoLavoro(WidgetTester tester) =>
    tocca(tester, find.bySemanticsLabel('Nuovo lavoro'));

void main() {
  testWidgets('Lavoro nuovo: forbice a mano, prezzo suggerito e salvataggio', (
    tester,
  ) async {
    schermoAlto(tester);
    final app = await avviaApp(tester);
    await apriNuovoLavoro(tester);

    // Senza forbice il prezzo suggerito non c'è
    expect(find.text('Da inserire'), findsOneWidget);

    // Inserisco la forbice del doppiaggio: 80 – 120 €
    await tocca(tester, find.text('Inserisci forbice'));
    await scrivi(tester, 'campo-minimo', '80');
    await scrivi(tester, 'campo-massimo', '120');
    await tocca(tester, find.text('Salva forbice'));
    // Compare due volte: forbice di mercato e prezzo suggerito (relazione nuova = nessuno sconto)
    expect(find.text('80 – 120 €'), findsNWidgets(2));
    expect(app.archivio.tabellaPrezzi.elenco.single.minimo, 80);

    // Livello 3 + amico (−30%) → 56 – 84 €, regali 24 – 36 €
    await tocca(tester, find.text('Amico'));
    expect(find.text('56 – 84 €'), findsOneWidget);
    expect(find.text('Regali circa 24 – 36 €'), findsOneWidget);

    // Il livello 5 alza il prezzo del 20%: 67 – 101 €
    await tocca(tester, find.bySemanticsLabel('Livello 5 su 5'));
    expect(find.text('67 – 101 €'), findsOneWidget);

    await scrivi(tester, 'campo-nome', 'Audiolibro «Il bosco»');
    await scrivi(tester, 'campo-cliente', 'Luca');
    await scrivi(tester, 'campo-pieno', '1000');

    // Il prezzo finale si calcola da solo: 1.000 − 30% = 700
    final finale = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('campo-finale')),
        matching: find.byType(TextField),
      ),
    );
    expect(finale.controller!.text, '700');

    await tocca(tester, find.text('Salva lavoro'));

    // Si apre il progetto: +700 € (sottoprogetto "Lavoro intero"), 300 € regalati
    expect(find.text('Audiolibro «Il bosco»'), findsWidgets);
    expect(find.text('+700 €'), findsWidgets);
    expect(find.text('Lavoro intero'), findsOneWidget);
    expect(find.text('Regali 300 €'), findsOneWidget);
    expect(find.text('Sconto Amico −30%'), findsOneWidget);

    // Salvati: lavoro, cliente (nuovo, con la relazione scelta) e sottoprogetto
    final lavoro = app.archivio.tabellaLavori.elenco.single;
    expect(lavoro.tipo, TipoLavoro.doppiaggio);
    expect(lavoro.livello, 5);
    expect(lavoro.relazione, Relazione.amico);
    expect(lavoro.prezzoPieno, 1000);
    expect(lavoro.prezzoFinale, 700);
    final cliente = app.archivio.tabellaClienti.elenco.single;
    expect(cliente.nome, 'Luca');
    expect(cliente.relazione, Relazione.amico);
    expect(lavoro.clienteId, cliente.id);
    expect(app.archivio.tabellaSotto.elenco.single.ricavo, 700);
  });

  testWidgets('Il nome è obbligatorio e un numero sbagliato viene segnalato', (
    tester,
  ) async {
    schermoAlto(tester);
    final app = await avviaApp(tester);
    await apriNuovoLavoro(tester);

    await tocca(tester, find.text('Salva lavoro'));
    expect(find.text('Scrivi il nome del lavoro'), findsOneWidget);

    await scrivi(tester, 'campo-nome', 'Prova');
    await scrivi(tester, 'campo-pieno', '12,5,7');
    await tocca(tester, find.text('Salva lavoro'));
    expect(find.text('Numero non valido'), findsOneWidget);
    expect(app.archivio.tabellaLavori.elenco, isEmpty);
  });

  testWidgets('Sottoprogetti: utile del progetto e guadagno all\'ora', (
    tester,
  ) async {
    schermoAlto(tester);
    final app = await avviaApp(tester);
    await apriNuovoLavoro(tester);
    await scrivi(tester, 'campo-nome', 'Il bosco');
    await tocca(
      tester,
      find.text('Salva lavoro'),
    ); // senza prezzo: nessuna parte
    expect(find.text('Nessun sottoprogetto'), findsOneWidget);

    Future<void> aggiungi(
      String nome,
      String ricavo,
      String costi,
      String ore,
    ) async {
      await tocca(tester, find.text('+ Aggiungi'));
      await scrivi(tester, 'campo-nome', nome);
      await scrivi(tester, 'campo-ricavo', ricavo);
      await scrivi(tester, 'campo-costi', costi);
      await scrivi(tester, 'campo-ore', ore);
      await tocca(tester, find.text('Salva'));
    }

    // I numeri del brief: 340 + 80 + 100 = +520 €, 20 h → 26 €/h
    await aggiungi('Registrazione', '400', '60', '9');
    await aggiungi('Revisione', '120', '40', '4');
    await aggiungi('Montaggio', '180', '80', '7');

    expect(find.text('+520 €'), findsOneWidget); // saldo del progetto
    expect(find.text('+340 €'), findsOneWidget);
    expect(find.text('+80 €'), findsOneWidget);
    expect(find.text('+100 €'), findsOneWidget);
    expect(find.text('26 €/h'), findsOneWidget);
    expect(find.text('In positivo'), findsOneWidget);
    expect(find.text('9 h · incasso 400 € · costi 60 €'), findsOneWidget);
    expect(app.archivio.tabellaSotto.elenco, hasLength(3));

    // Modifica: cambio i costi della revisione e il saldo si aggiorna
    await tocca(
      tester,
      find.text('Revisione'),
    ); // apre le ore del sottoprogetto
    await tocca(tester, find.bySemanticsLabel('Modifica sottoprogetto'));
    await scrivi(tester, 'campo-costi', '200');
    await tocca(tester, find.text('Salva'));
    await tocca(tester, find.bySemanticsLabel('Indietro'));
    expect(find.text('−80 €'), findsOneWidget); // revisione: 120 − 200
    expect(find.text('+360 €'), findsOneWidget); // 340 − 80 + 100
  });

  testWidgets('Si elimina un sottoprogetto e poi tutto il progetto', (
    tester,
  ) async {
    schermoAlto(tester);
    final app = await avviaApp(tester);
    await apriNuovoLavoro(tester);
    await scrivi(tester, 'campo-nome', 'Da buttare');
    await scrivi(tester, 'campo-pieno', '100');
    await tocca(tester, find.text('Salva lavoro'));
    expect(app.archivio.tabellaSotto.elenco, hasLength(1));

    await tocca(tester, find.text('Lavoro intero'));
    await tocca(tester, find.bySemanticsLabel('Modifica sottoprogetto'));
    await tocca(tester, find.text('Elimina'));
    await tocca(tester, find.widgetWithText(TextButton, 'Elimina')); // conferma
    expect(app.archivio.tabellaSotto.elenco, isEmpty);

    // Annullando la conferma il progetto resta
    await tocca(tester, find.text('Elimina progetto'));
    await tocca(tester, find.text('Annulla'));
    expect(app.archivio.tabellaLavori.elenco, hasLength(1));

    await tocca(tester, find.text('Elimina progetto'));
    await tocca(tester, find.widgetWithText(TextButton, 'Elimina'));
    expect(app.archivio.tabellaLavori.elenco, isEmpty);
    expect(
      find.text('Ancora nessun progetto'),
      findsOneWidget,
    ); // di nuovo in Home
  });

  testWidgets('I progetti compaiono in Home e nella scheda Progetti', (
    tester,
  ) async {
    schermoAlto(tester);
    final archivio = FintoArchivio();
    archivio.salvaLavoro(
      Lavoro(
        id: '',
        nome: 'Spot radio',
        tipo: TipoLavoro.doppiaggio,
        relazione: Relazione.nuovo,
        livello: 3,
        prezzoPieno: 0,
        prezzoFinale: 0,
        creatoIl: DateTime(2026, 10, 1),
      ),
    );
    await avviaApp(tester, archivio: archivio);

    expect(find.text('Spot radio'), findsOneWidget); // Home
    expect(find.text('Doppiaggio · Nuovo'), findsOneWidget);

    await tocca(tester, find.text('Progetti').last);
    expect(find.text('Spot radio'), findsOneWidget);
  });

  testWidgets('Clienti: si crea, si modifica e si elimina', (tester) async {
    schermoAlto(tester);
    final app = await avviaApp(tester);
    await tocca(tester, find.text('Clienti')); // pulsante in Home
    expect(find.text('Nessun cliente'), findsOneWidget);

    await tocca(tester, find.text('+ Nuovo'));
    await scrivi(tester, 'campo-nome', 'Marta');
    await tocca(tester, find.text('Consigliato'));
    await tocca(tester, find.text('Salva'));
    expect(find.text('Consigliato −10% · 0 lavori'), findsOneWidget);
    expect(
      app.archivio.tabellaClienti.elenco.single.relazione,
      Relazione.consigliato,
    );

    // Un nome già usato (anche con le maiuscole diverse) non è accettato
    await tocca(tester, find.text('+ Nuovo'));
    await scrivi(tester, 'campo-nome', ' marta ');
    await tocca(tester, find.text('Salva'));
    expect(find.text('Esiste già un cliente con questo nome'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10)); // chiude il foglio
    await tester.pumpAndSettle();

    // Modifica: Marta diventa amica
    await tocca(tester, find.text('Marta'));
    await tocca(tester, find.text('Amico'));
    await tocca(tester, find.text('Salva'));
    expect(find.text('Amico −30% · 0 lavori'), findsOneWidget);

    // Eliminazione
    await tocca(tester, find.text('Marta'));
    await tocca(tester, find.text('Elimina'));
    await tocca(tester, find.widgetWithText(TextButton, 'Elimina'));
    expect(app.archivio.tabellaClienti.elenco, isEmpty);
  });

  testWidgets('Un cliente con dei lavori non si può eliminare', (tester) async {
    schermoAlto(tester);
    final archivio = FintoArchivio();
    final idCliente = archivio.salvaCliente(
      Cliente(
        id: '',
        nome: 'Luca',
        relazione: Relazione.amico,
        creatoIl: DateTime(2026),
      ),
    );
    archivio.salvaLavoro(
      Lavoro(
        id: '',
        nome: 'Sito',
        tipo: TipoLavoro.codice,
        clienteId: idCliente,
        relazione: Relazione.amico,
        livello: 3,
        prezzoPieno: 500,
        prezzoFinale: 350,
        creatoIl: DateTime(2026),
      ),
    );
    await avviaApp(tester, archivio: archivio);
    await tocca(tester, find.text('Clienti'));

    expect(find.text('Amico −30% · 1 lavoro'), findsOneWidget);
    expect(find.text('350 €'), findsOneWidget); // totale dei suoi lavori

    await tocca(tester, find.text('Luca'));
    expect(find.text('Ha dei lavori: non eliminabile'), findsOneWidget);
  });

  testWidgets('Quando si esce i dati si svuotano', (tester) async {
    schermoAlto(tester);
    final archivio = FintoArchivio();
    archivio.salvaLavoro(
      Lavoro(
        id: '',
        nome: 'Privato',
        tipo: TipoLavoro.altro,
        relazione: Relazione.nuovo,
        livello: 3,
        prezzoPieno: 0,
        prezzoFinale: 0,
        creatoIl: DateTime(2026),
      ),
    );
    final app = await avviaApp(tester, archivio: archivio);
    expect(find.text('Privato'), findsOneWidget);

    await tocca(tester, find.bySemanticsLabel('Impostazioni'));
    await tocca(tester, find.text('Esci'));
    expect(find.text('Accedi con Google'), findsOneWidget);
    expect(find.text('Privato'), findsNothing);

    // Rientrando i dati tornano
    await tocca(tester, find.text('Accedi con Google'));
    expect(app.accesso.accessiRichiesti, 1);
    expect(find.text('Privato'), findsOneWidget);
  });
}
