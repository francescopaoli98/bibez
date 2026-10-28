import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantovalgo/modelli/costo.dart';
import 'package:quantovalgo/modelli/lavoro.dart';
import 'package:quantovalgo/modelli/sessione_ore.dart';
import 'package:quantovalgo/modelli/sottoprogetto.dart';
import 'package:quantovalgo/modelli/tipi.dart';

import 'finti.dart';

void schermoAlto(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 4200);
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

/// Un progetto "Il bosco" con due parti: Registrazione (2 h iniziali) e Revisione.
({
  FintoArchivio archivio,
  String lavoro,
  String registrazione,
  String revisione,
})
archivioDiProva() {
  final a = FintoArchivio();
  final lavoro = a.salvaLavoro(
    Lavoro(
      id: '',
      nome: 'Il bosco',
      tipo: TipoLavoro.doppiaggio,
      relazione: Relazione.nuovo,
      livello: 3,
      prezzoPieno: 0,
      prezzoFinale: 0,
      creatoIl: DateTime(2026, 10, 1),
    ),
  );
  String parte(String nome, double ricavo, double costi, double ore) =>
      a.salvaSottoprogetto(
        Sottoprogetto(
          id: '',
          lavoroId: lavoro,
          nome: nome,
          ricavo: ricavo,
          costiDiretti: costi,
          ore: ore,
          creatoIl: DateTime(2026, 10, 1),
        ),
      );
  return (
    archivio: a,
    lavoro: lavoro,
    registrazione: parte('Registrazione', 400, 60, 2),
    revisione: parte('Revisione', 120, 40, 0),
  );
}

void main() {
  // Orologio che i test spostano a mano: mercoledì 28 ottobre 2026, ore 10
  var ora = DateTime(2026, 10, 28, 10);
  DateTime adesso() => ora;
  setUp(() => ora = DateTime(2026, 10, 28, 10));

  /// Apre il progetto "Il bosco" dalla Home.
  Future<void> apriProgetto(WidgetTester tester) =>
      tocca(tester, find.text('Il bosco').first);

  testWidgets('Cronometro: avvia, corre, ferma e salva i minuti', (
    tester,
  ) async {
    schermoAlto(tester);
    final p = archivioDiProva();
    await avviaApp(tester, archivio: p.archivio, adesso: adesso);
    await apriProgetto(tester);
    expect(find.text('2 h · incasso 400 € · costi 60 €'), findsOneWidget);

    await tocca(
      tester,
      find.bySemanticsLabel('Avvia cronometro su Registrazione'),
    );
    final acceso = p.archivio.tabellaSessioni.elenco.single;
    expect(acceso.inCorso, isTrue);
    expect(acceso.sottoprogettoId, p.registrazione);
    expect(acceso.lavoroId, p.lavoro);
    expect(acceso.inizio, ora);
    // Il tasto della riga diventa "ferma"
    expect(
      find.bySemanticsLabel('Ferma cronometro di Registrazione'),
      findsOneWidget,
    );

    // Torno alla Home: la banda in basso mostra il cronometro
    await tocca(tester, find.bySemanticsLabel('Indietro'));
    expect(find.text('00:00:00'), findsOneWidget);

    // Passa 1 ora e 5 minuti
    ora = ora.add(const Duration(hours: 1, minutes: 5));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('01:05:00'), findsOneWidget);

    await tocca(tester, find.text('Ferma'));
    expect(find.text('Salvati 1 h 5 min su "Registrazione"'), findsOneWidget);
    final salvata = p.archivio.tabellaSessioni.elenco.single;
    expect(salvata.inCorso, isFalse);
    expect(salvata.minuti, 65);
    expect(salvata.fine, ora);
    expect(salvata.manuale, isFalse);
    expect(find.text('01:05:00'), findsNothing); // la banda è sparita

    // Le ore del sottoprogetto: 2 h iniziali + 1 h 5 min registrate
    await apriProgetto(tester);
    expect(find.text('3 h 5 min · incasso 400 € · costi 60 €'), findsOneWidget);
  });

  testWidgets('Sotto il minuto il cronometro non si salva', (tester) async {
    schermoAlto(tester);
    final p = archivioDiProva();
    await avviaApp(tester, archivio: p.archivio, adesso: adesso);
    await apriProgetto(tester);

    await tocca(tester, find.bySemanticsLabel('Avvia cronometro su Revisione'));
    ora = ora.add(const Duration(seconds: 20));
    await tocca(tester, find.bySemanticsLabel('Ferma cronometro di Revisione'));

    expect(find.text('Meno di un minuto: non salvato'), findsOneWidget);
    expect(p.archivio.tabellaSessioni.elenco, isEmpty);
  });

  testWidgets('Avviando un secondo cronometro il primo si ferma e si salva', (
    tester,
  ) async {
    schermoAlto(tester);
    final p = archivioDiProva();
    await avviaApp(tester, archivio: p.archivio, adesso: adesso);
    await apriProgetto(tester);

    await tocca(
      tester,
      find.bySemanticsLabel('Avvia cronometro su Registrazione'),
    );
    ora = ora.add(const Duration(minutes: 30));
    await tocca(tester, find.bySemanticsLabel('Avvia cronometro su Revisione'));

    expect(
      find.text('Fermato "Registrazione": salvati 30 min'),
      findsOneWidget,
    );
    final sessioni = p.archivio.tabellaSessioni.elenco;
    expect(sessioni, hasLength(2));
    final prima = sessioni.firstWhere(
      (s) => s.sottoprogettoId == p.registrazione,
    );
    final seconda = sessioni.firstWhere(
      (s) => s.sottoprogettoId == p.revisione,
    );
    expect(prima.minuti, 30);
    expect(prima.inCorso, isFalse);
    expect(seconda.inCorso, isTrue); // uno solo acceso alla volta
  });

  testWidgets('Un cronometro acceso si ritrova riaprendo l\'app', (
    tester,
  ) async {
    schermoAlto(tester);
    final p = archivioDiProva();
    // Come se l'app fosse stata chiusa 2 ore fa con il cronometro acceso
    p.archivio.salvaSessione(
      SessioneOre(
        id: '',
        sottoprogettoId: p.registrazione,
        lavoroId: p.lavoro,
        inizio: DateTime(2026, 10, 28, 8),
        creatoIl: DateTime(2026, 10, 28, 8),
      ),
    );
    await avviaApp(tester, archivio: p.archivio, adesso: adesso);

    expect(find.text('02:00:00'), findsOneWidget);
    expect(find.text('Registrazione'), findsOneWidget); // nella banda

    // Dalla banda si arriva alla pagina del sottoprogetto
    await tocca(tester, find.text('Registrazione'));
    expect(find.text('Cronometro acceso dalle 08:00'), findsOneWidget);
    await tocca(tester, find.text('Ferma cronometro'));
    expect(p.archivio.tabellaSessioni.elenco.single.minuti, 120);
  });

  testWidgets('Pagina delle ore: ore a mano, anche con decimali', (
    tester,
  ) async {
    schermoAlto(tester);
    final p = archivioDiProva();
    await avviaApp(tester, archivio: p.archivio, adesso: adesso);
    await apriProgetto(tester);
    await tocca(tester, find.text('Registrazione'));

    expect(find.text('Nessuna sessione'), findsOneWidget);
    expect(find.text('2 h'), findsWidgets); // ore lavorate = iniziali

    await tocca(tester, find.text('Aggiungi ore a mano'));
    await scrivi(tester, 'campo-ore-sessione', '1');
    await scrivi(tester, 'campo-minuti-sessione', '30');
    await tocca(tester, find.text('Aggiungi'));

    final s = p.archivio.tabellaSessioni.elenco.single;
    expect(s.minuti, 90);
    expect(s.manuale, isTrue);
    expect(s.inizio, DateTime(2026, 10, 28, 12)); // oggi, a mezzogiorno
    expect(s.sottoprogettoId, p.registrazione);
    expect(s.lavoroId, p.lavoro);
    expect(find.text('mercoledì 28 ottobre'), findsOneWidget);
    expect(find.text('Inserite a mano'), findsOneWidget);
    expect(find.text('3 h 30 min'), findsOneWidget); // hero: 2 h + 1 h 30
    expect(find.text('1 h 30 min'), findsWidgets);

    // Anche "1,5" ore vale 90 minuti
    await tocca(tester, find.text('Aggiungi ore a mano'));
    await scrivi(tester, 'campo-ore-sessione', '1,5');
    await tocca(tester, find.text('Aggiungi'));
    expect(p.archivio.tabellaSessioni.elenco.map((x) => x.minuti), [90, 90]);
  });

  testWidgets(
    'Le ore a mano si scrivono per un altro giorno e si controllano',
    (tester) async {
      schermoAlto(tester);
      final p = archivioDiProva();
      await avviaApp(tester, archivio: p.archivio, adesso: adesso);
      await apriProgetto(tester);
      await tocca(tester, find.text('Revisione'));

      await tocca(tester, find.text('Aggiungi ore a mano'));
      await tocca(tester, find.text('Aggiungi')); // niente scritto
      expect(find.text('Scrivi almeno 1 minuto'), findsOneWidget);
      await scrivi(tester, 'campo-ore-sessione', '25');
      await tocca(tester, find.text('Aggiungi'));
      expect(find.text('Al massimo 24 ore in una sessione'), findsOneWidget);
      // Le lettere non entrano nel campo; "1,2,3" sì, ma non è un numero
      await scrivi(tester, 'campo-ore-sessione', '1,2,3');
      await tocca(tester, find.text('Aggiungi'));
      expect(find.text('Numero non valido'), findsOneWidget);
      expect(p.archivio.tabellaSessioni.elenco, isEmpty);
    },
  );

  testWidgets('Una sessione si corregge e si toglie', (tester) async {
    schermoAlto(tester);
    final p = archivioDiProva();
    p.archivio.salvaSessione(
      SessioneOre(
        id: '',
        sottoprogettoId: p.revisione,
        lavoroId: p.lavoro,
        inizio: DateTime(2026, 10, 27, 14, 5),
        fine: DateTime(2026, 10, 27, 15, 35),
        minuti: 90,
        creatoIl: DateTime(2026, 10, 27),
      ),
    );
    await avviaApp(tester, archivio: p.archivio, adesso: adesso);
    await apriProgetto(tester);
    await tocca(tester, find.text('Revisione'));

    expect(find.text('Cronometro · 14:05–15:35'), findsOneWidget);
    expect(find.text('martedì 27 ottobre'), findsOneWidget);

    // Correggo: erano 2 ore (resta l'orario di inizio)
    await tocca(tester, find.text('martedì 27 ottobre'));
    await scrivi(tester, 'campo-ore-sessione', '2');
    await scrivi(tester, 'campo-minuti-sessione', '0');
    await tocca(tester, find.text('Salva'));
    final corretta = p.archivio.tabellaSessioni.elenco.single;
    expect(corretta.minuti, 120);
    expect(corretta.inizio, DateTime(2026, 10, 27, 14, 5));
    expect(corretta.manuale, isFalse);

    // Tolgo
    await tocca(tester, find.text('martedì 27 ottobre'));
    await tocca(tester, find.text('Togli questa sessione'));
    await tocca(tester, find.widgetWithText(TextButton, 'Togli'));
    expect(p.archivio.tabellaSessioni.elenco, isEmpty);
    expect(find.text('Nessuna sessione'), findsOneWidget);
  });

  testWidgets('Il guadagno all\'ora tiene conto delle ore registrate', (
    tester,
  ) async {
    schermoAlto(tester);
    final p = archivioDiProva();
    // Utile 340 + 80 = 420 €; ore: 2 iniziali + 3 registrate = 5 h → 84 €/h
    p.archivio.salvaSessione(
      SessioneOre(
        id: '',
        sottoprogettoId: p.revisione,
        lavoroId: p.lavoro,
        inizio: DateTime(2026, 10, 20, 9),
        fine: DateTime(2026, 10, 20, 12),
        minuti: 180,
        creatoIl: DateTime(2026, 10, 20),
      ),
    );
    await avviaApp(tester, archivio: p.archivio, adesso: adesso);
    await apriProgetto(tester);

    expect(find.text('84 €/h'), findsOneWidget);
    expect(find.text('+420 €'), findsWidgets);
    // Nella pagina del sottoprogetto: Revisione ha utile 80 € su 3 h
    await tocca(tester, find.text('Revisione'));
    expect(find.text('26,67 €/h'), findsOneWidget);
  });

  testWidgets('Il cronometro acceso non conta finché non lo fermi', (
    tester,
  ) async {
    schermoAlto(tester);
    final p = archivioDiProva();
    p.archivio.salvaSessione(
      SessioneOre(
        id: '',
        sottoprogettoId: p.registrazione,
        lavoroId: p.lavoro,
        inizio: DateTime(2026, 10, 28, 8),
        creatoIl: DateTime(2026, 10, 28, 8),
      ),
    );
    await avviaApp(tester, archivio: p.archivio, adesso: adesso);
    await apriProgetto(tester);
    expect(find.text('2 h · incasso 400 € · costi 60 €'), findsOneWidget);
  });

  testWidgets('Costi condivisi: pesano le ore registrate nel mese', (
    tester,
  ) async {
    schermoAlto(tester);
    final a = FintoArchivio();
    final ids = <String, String>{};
    for (final nome in ['Il bosco', 'Sito per Marta']) {
      final l = a.salvaLavoro(
        Lavoro(
          id: '',
          nome: nome,
          tipo: TipoLavoro.altro,
          relazione: Relazione.nuovo,
          livello: 3,
          prezzoPieno: 0,
          prezzoFinale: 0,
          creatoIl: DateTime(2026, 1, nome == 'Il bosco' ? 1 : 2),
        ),
      );
      ids[nome] = a.salvaSottoprogetto(
        Sottoprogetto(
          id: '',
          lavoroId: l,
          nome: 'Parte',
          ricavo: 0,
          costiDiretti: 0,
          ore: nome == 'Il bosco'
              ? 1
              : 9, // ore iniziali: ignorate se ci sono ore del mese
          creatoIl: DateTime(2026),
        ),
      );
      a.salvaSessione(
        SessioneOre(
          id: '',
          sottoprogettoId: ids[nome]!,
          lavoroId: l,
          inizio: DateTime(2026, 10, 10, 9),
          fine: DateTime(
            2026,
            10,
            10,
            9,
          ).add(Duration(minutes: nome == 'Il bosco' ? 180 : 60)),
          minuti: nome == 'Il bosco' ? 180 : 60, // 3 h contro 1 h
          creatoIl: DateTime(2026, 10, 10),
        ),
      );
    }
    a.salvaCosto(
      Costo(
        id: '',
        nome: 'Claude',
        tipo: TipoCosto.abbonamento,
        importo: 20,
        inizio: DateTime(2026, 1),
        creatoIl: DateTime(2026),
      ),
    );
    await avviaApp(tester, archivio: a, adesso: adesso);
    await tocca(tester, find.text('Costi').last);

    // 3 h : 1 h → 15 € e 5 €, non secondo le ore iniziali (1 : 9)
    expect(find.text('Il bosco 15 €'), findsOneWidget);
    expect(find.text('Sito per Marta 5 €'), findsOneWidget);

    // A novembre nessuno ha ore registrate: si guardano le ore totali (4 h : 10 h)
    await tocca(tester, find.bySemanticsLabel('Mese successivo'));
    expect(find.text('Sito per Marta 14,29 €'), findsOneWidget);
    expect(find.text('Il bosco 5,71 €'), findsOneWidget);
  });

  testWidgets('Eliminando sottoprogetto e progetto spariscono anche le ore', (
    tester,
  ) async {
    schermoAlto(tester);
    final p = archivioDiProva();
    SessioneOre sessione(String sotto) => SessioneOre(
      id: '',
      sottoprogettoId: sotto,
      lavoroId: p.lavoro,
      inizio: DateTime(2026, 10, 20, 9),
      fine: DateTime(2026, 10, 20, 10),
      minuti: 60,
      creatoIl: DateTime(2026, 10, 20),
    );
    p.archivio.salvaSessione(sessione(p.registrazione));
    p.archivio.salvaSessione(sessione(p.revisione));
    p.archivio.salvaSessione(
      SessioneOre(
        id: '',
        sottoprogettoId: p.revisione,
        lavoroId: p.lavoro,
        inizio: DateTime(2026, 10, 28, 9),
        creatoIl: DateTime(2026, 10, 28, 9),
      ),
    ); // cronometro acceso
    await avviaApp(tester, archivio: p.archivio, adesso: adesso);
    expect(find.text('01:00:00'), findsOneWidget); // banda visibile

    await apriProgetto(tester);
    // Tolgo "Revisione": se ne vanno le sue 2 sessioni (anche quella accesa)
    await tocca(tester, find.text('Revisione'));
    await tocca(tester, find.bySemanticsLabel('Modifica sottoprogetto'));
    await tocca(tester, find.text('Elimina'));
    await tocca(tester, find.widgetWithText(TextButton, 'Elimina'));
    expect(p.archivio.tabellaSessioni.elenco.map((s) => s.sottoprogettoId), [
      p.registrazione,
    ]);
    // La pagina delle ore si è chiusa da sola: si è di nuovo sul progetto
    expect(find.text('Registrazione'), findsOneWidget);

    // Tolgo tutto il progetto: se ne vanno anche le ultime ore
    await tocca(tester, find.text('Elimina progetto'));
    await tocca(tester, find.widgetWithText(TextButton, 'Elimina'));
    expect(p.archivio.tabellaSessioni.elenco, isEmpty);
  });
}
