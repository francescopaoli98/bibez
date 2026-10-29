import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantovalgo/logica/apprendimento.dart';
import 'package:quantovalgo/logica/calcoli.dart';
import 'package:quantovalgo/logica/prezzi_web.dart';
import 'package:quantovalgo/modelli/impostazioni.dart';
import 'package:quantovalgo/modelli/lavoro.dart';
import 'package:quantovalgo/modelli/prezzo_mercato.dart';
import 'package:quantovalgo/modelli/sottoprogetto.dart';
import 'package:quantovalgo/modelli/tipi.dart';
import 'package:quantovalgo/servizi/aggiornamento_prezzi.dart';
import 'package:quantovalgo/servizi/ricerca_prezzi.dart';
import 'package:quantovalgo/servizi/stato_dati.dart';

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

const mercato = Forbice(80, 120); // centro 100 €

/// Lavoro incassato a [incassato] € (livello 3, relazione "nuovo": suggerito 80-120).
Lavoro incassato(
  double importo, {
  String id = '',
  DateTime? giorno,
  Relazione r = Relazione.nuovo,
  TipoLavoro tipo = TipoLavoro.doppiaggio,
}) => Lavoro(
  id: id,
  nome: 'L$importo',
  tipo: tipo,
  relazione: r,
  livello: 3,
  prezzoPieno: importo,
  prezzoFinale: importo,
  statoPagamento: StatoPagamento.incassato,
  dataIncasso: giorno ?? DateTime(2026, 10, 1),
  creatoIl: DateTime(2026, 9, 1),
);

CorrezioneTipo? calcola(List<Lavoro> l) => calcolaCorrezione(
  tipo: TipoLavoro.doppiaggio,
  mercato: mercato,
  incassati: l,
  importo: (x) => x.prezzoFinale,
  parametri: ParametriPrezzo.predefiniti,
);

PrezzoMercato prezzo(TipoLavoro t, {bool manuale = true, DateTime? quando}) =>
    PrezzoMercato(
      tipo: t,
      minimo: 80,
      massimo: 120,
      aggiornato: quando ?? DateTime(2026, 10, 1),
      manuale: manuale,
    );

ForbiceTrovata trovata() => const ForbiceTrovata(
  forbice: Forbice(90, 110),
  fonti: ['uno.it', 'due.com'],
  importi: 6,
  domanda: 'configurazione tablet anziani Italia prezzo euro',
);

void main() {
  group('Autoapprendimento: correzione dai lavori incassati', () {
    test('incassi come il suggerito: nessuno scarto', () {
      final c = calcola([incassato(100), incassato(100), incassato(100)])!;
      expect(c.scartoMedio, closeTo(0, 0.0001));
      expect(c.correzione, closeTo(0, 0.0001));
      expect(c.daAvvisare, isFalse);
    });

    test('con meno di 3 lavori non si impara nulla', () {
      expect(calcola([incassato(150), incassato(150)]), isNull);
    });

    test('incassando il 10% in più la forbice sale del 10%', () {
      final c = calcola([incassato(110), incassato(110), incassato(110)])!;
      expect(c.scartoMedio, closeTo(0.10, 0.0001));
      expect(c.correzione, closeTo(0.10, 0.0001));
      expect(c.daAvvisare, isFalse);
    });

    test('la correzione si ferma a ±15%, e sopra il 20% scatta l\'avviso', () {
      final su = calcola([incassato(130), incassato(130), incassato(130)])!;
      expect(su.scartoMedio, closeTo(0.30, 0.0001));
      expect(su.correzione, 0.15);
      expect(su.daAvvisare, isTrue);

      final giu = calcola([incassato(60), incassato(60), incassato(60)])!;
      expect(giu.correzione, -0.15);
      expect(giu.daAvvisare, isTrue);
    });

    test('si guardano solo gli ultimi 5 incassati', () {
      final vecchi = [
        for (var i = 0; i < 4; i++)
          incassato(300, giorno: DateTime(2026, 1, 1 + i)),
      ];
      final recenti = [
        for (var i = 0; i < 5; i++)
          incassato(100, giorno: DateTime(2026, 10, 1 + i)),
      ];
      final c = calcola([...vecchi, ...recenti])!;
      expect(c.lavori, 5);
      expect(c.scartoMedio, closeTo(0, 0.0001));
    });

    test('lo sconto della relazione non conta come scarto', () {
      // Amico −30%: il suggerito è 56-84 (centro 70). Incassando 70 non c'è scarto.
      final c = calcola([
        incassato(70, r: Relazione.amico),
        incassato(70, r: Relazione.amico),
        incassato(70, r: Relazione.amico),
      ])!;
      expect(c.scartoMedio, closeTo(0, 0.0001));
    });

    test('lavori senza importo si saltano', () {
      expect(calcola([incassato(0), incassato(0), incassato(100)]), isNull);
    });

    test('forbice corretta: si sposta dello stesso percentuale', () {
      final c = calcola([incassato(110), incassato(110), incassato(110)]);
      final f = forbiceCorretta(mercato, c);
      expect(f.minimo, closeTo(88, 0.001));
      expect(f.massimo, closeTo(132, 0.001));
      expect(forbiceCorretta(mercato, null).minimo, 80);
    });
  });

  group('Impostazioni della ricerca', () {
    test('si salvano e si rileggono; dati vecchi: ricerca spenta', () {
      final i = const Impostazioni().copyWith(
        chiaveTavily: 'tvly-abc',
        aggiornaPrezzi: true,
        ricercheMese: '2026-10',
        ricercheUsate: 4,
      );
      final letto = Impostazioni.fromMap(i.toMap());
      expect(letto.chiaveTavily, 'tvly-abc');
      expect(letto.aggiornaPrezzi, isTrue);
      expect(letto.ricercheUsate, 4);

      final vecchio = Impostazioni.fromMap({'promemoria': true});
      expect(vecchio.chiaveTavily, '');
      expect(vecchio.aggiornaPrezzi, isFalse);
      expect(vecchio.ricercheUsate, 0);
    });
  });

  group('Schermate della ricerca prezzi', () {
    Future<FintoArchivio> conChiave({bool settimanale = false}) async {
      final a = FintoArchivio();
      a.salvaImpostazioni(
        const Impostazioni().copyWith(
          chiaveTavily: 'tvly-prova-123456',
          aggiornaPrezzi: settimanale,
        ),
      );
      return a;
    }

    testWidgets('Senza chiave il pulsante manda a Impostazioni', (
      tester,
    ) async {
      schermoAlto(tester);
      final ricerca = FintaRicerca(RicercaTrovata(trovata()));
      await avviaApp(tester, ricerca: ricerca, adesso: oggi);

      await tocca(tester, find.bySemanticsLabel('Nuovo lavoro'));
      await tocca(tester, find.text('Cerca prezzi'));
      expect(find.text('Serve la chiave di Tavily'), findsOneWidget);
      expect(ricerca.richieste, isEmpty);

      await tocca(tester, find.text('Vai a Impostazioni'));
      expect(find.text('Chiave Tavily'), findsOneWidget);
    });

    testWidgets(
      'Trovata: si vede la forbice, "Usa questa" la salva con le fonti',
      (tester) async {
        schermoAlto(tester);
        final archivio = await conChiave();
        final ricerca = FintaRicerca(RicercaTrovata(trovata()));
        await avviaApp(
          tester,
          archivio: archivio,
          ricerca: ricerca,
          adesso: oggi,
        );

        await tocca(tester, find.bySemanticsLabel('Nuovo lavoro'));
        await tocca(tester, find.text('Cerca prezzi'));
        expect(ricerca.richieste.single.tipo, TipoLavoro.doppiaggio);
        expect(ricerca.richieste.single.chiave, 'tvly-prova-123456');
        expect(find.text('90 – 110 €'), findsOneWidget);
        expect(find.textContaining('uno.it, due.com'), findsOneWidget);
        // Finché non scegli, non si salva nulla
        expect(archivio.tabellaPrezzi.elenco, isEmpty);

        await tocca(tester, find.text('Usa questa forbice'));
        final p = archivio.tabellaPrezzi.elenco.single;
        expect(p.tipo, TipoLavoro.doppiaggio);
        expect(p.minimo, 90);
        expect(p.massimo, 110);
        expect(p.manuale, isFalse);
        expect(p.fonti, ['uno.it', 'due.com']);
        expect(p.aggiornato, oggi());
        expect(find.textContaining('Da ricerca web (2 siti)'), findsOneWidget);
        // Contata come ricerca fatta
        expect(archivio.impostazioniSalvate.ricercheUsate, 1);
        expect(archivio.impostazioniSalvate.ricercheMese, '2026-10');
      },
    );

    testWidgets('"Non usarla" lascia tutto com\'è', (tester) async {
      schermoAlto(tester);
      final archivio = await conChiave();
      await avviaApp(
        tester,
        archivio: archivio,
        ricerca: FintaRicerca(RicercaTrovata(trovata())),
        adesso: oggi,
      );
      await tocca(tester, find.bySemanticsLabel('Nuovo lavoro'));
      await tocca(tester, find.text('Cerca prezzi'));
      await tocca(tester, find.text('Non usarla'));
      expect(archivio.tabellaPrezzi.elenco, isEmpty);
    });

    testWidgets('Non affidabile: lo dice e propone la forbice a mano', (
      tester,
    ) async {
      schermoAlto(tester);
      final archivio = await conChiave();
      await avviaApp(
        tester,
        archivio: archivio,
        ricerca: FintaRicerca(
          const RicercaNonAffidabile(
            EsitoForbice.no(
              MotivoNonAffidabile.pochiPrezzi,
              importi: 3,
              siti: 2,
            ),
          ),
        ),
        adesso: oggi,
      );
      await tocca(tester, find.bySemanticsLabel('Nuovo lavoro'));
      await tocca(tester, find.text('Cerca prezzi'));
      expect(find.text('Numeri non affidabili'), findsOneWidget);
      // Dice perché, con i numeri
      expect(
        find.textContaining('Ho trovato solo 3 prezzi (ne servono almeno 5).'),
        findsOneWidget,
      );
      // Ha usato un credito di Tavily anche se non ha trovato niente di buono
      expect(archivio.impostazioniSalvate.ricercheUsate, 1);

      await tocca(tester, find.text('Scrivi la forbice'));
      expect(find.byKey(const Key('campo-minimo')), findsOneWidget);
    });

    testWidgets('Errore: messaggio chiaro e nessun credito contato', (
      tester,
    ) async {
      schermoAlto(tester);
      final archivio = await conChiave();
      await avviaApp(
        tester,
        archivio: archivio,
        ricerca: FintaRicerca(
          const RicercaFallita(
            'Hai finito i crediti di Tavily per questo mese.',
          ),
        ),
        adesso: oggi,
      );
      await tocca(tester, find.bySemanticsLabel('Nuovo lavoro'));
      await tocca(tester, find.text('Cerca prezzi'));
      expect(find.text('Ricerca non riuscita'), findsOneWidget);
      expect(
        find.text('Hai finito i crediti di Tavily per questo mese.'),
        findsOneWidget,
      );
      expect(archivio.impostazioniSalvate.ricercheUsate, 0);
    });

    testWidgets('Al limite mensile non parte nemmeno la ricerca', (
      tester,
    ) async {
      schermoAlto(tester);
      final archivio = FintoArchivio();
      archivio.salvaImpostazioni(
        const Impostazioni().copyWith(
          chiaveTavily: 'tvly-prova-123456',
          ricercheMese: '2026-10',
          ricercheUsate: StatoDati.limiteRicercheMese,
        ),
      );
      final ricerca = FintaRicerca(RicercaTrovata(trovata()));
      await avviaApp(
        tester,
        archivio: archivio,
        ricerca: ricerca,
        adesso: oggi,
      );
      await tocca(tester, find.bySemanticsLabel('Nuovo lavoro'));
      await tocca(tester, find.text('Cerca prezzi'));
      expect(find.text('Limite del mese raggiunto'), findsOneWidget);
      expect(ricerca.richieste, isEmpty);
    });

    testWidgets('Il contatore riparte da zero col mese nuovo', (tester) async {
      schermoAlto(tester);
      final archivio = FintoArchivio();
      archivio.salvaImpostazioni(
        const Impostazioni().copyWith(
          chiaveTavily: 'tvly-prova-123456',
          ricercheMese: '2026-09',
          ricercheUsate: 49,
        ),
      );
      final app = await avviaApp(tester, archivio: archivio, adesso: oggi);
      expect(app.archivio.impostazioniSalvate.ricercheUsate, 49);
      await tocca(tester, find.bySemanticsLabel('Impostazioni'));
      expect(
        tester.widget<Text>(find.byKey(const Key('ricerche-del-mese'))).data,
        '0 su 50',
      );
    });

    testWidgets('Ricerca personalizzata: "Altro" chiede cosa cercare, poi cerca '
        'e il lavoro si ricorda la domanda', (tester) async {
      schermoAlto(tester);
      final archivio = await conChiave();
      final ricerca = FintaRicerca(RicercaTrovata(trovata()));
      await avviaApp(
        tester,
        archivio: archivio,
        ricerca: ricerca,
        adesso: oggi,
      );
      await tocca(tester, find.bySemanticsLabel('Nuovo lavoro'));
      await tocca(tester, find.text('Altro'));

      // Per "Altro" non c'è una domanda di partenza: senza testo non parte
      await tocca(tester, find.text('Cerca prezzi'));
      expect(find.text('Scrivi cosa vuoi cercare'), findsOneWidget);
      expect(ricerca.richieste, isEmpty);

      // Si può toccare un'idea, e l'anteprima mostra cosa verrà cercato davvero
      await tocca(
        tester,
        find.text(
          'assistenza informatica privati costo intervento a domicilio',
        ),
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('anteprima-domanda'))).data,
        'Cercherò: «assistenza informatica privati costo intervento a domicilio '
        'Italia euro»',
      );

      // ...oppure si scrive a mano
      await scrivi(tester, 'campo-domanda', 'configurazione tablet anziani');
      await tocca(tester, find.text('Cerca prezzi'));
      expect(ricerca.richieste.single.tipo, TipoLavoro.altro);
      expect(ricerca.richieste.single.domanda, 'configurazione tablet anziani');
      expect(find.byKey(const Key('domanda-cercata')), findsOneWidget);

      await tocca(tester, find.text('Usa questa forbice'));
      expect(archivio.tabellaPrezzi.elenco.single.tipo, TipoLavoro.altro);

      // Salvando il lavoro la domanda resta con lui
      await scrivi(tester, 'campo-nome', 'Amici: cellulare e tablet');
      await tocca(tester, find.text('Salva lavoro'));
      final salvato = archivio.tabellaLavori.elenco.single;
      expect(salvato.tipo, TipoLavoro.altro);
      expect(salvato.domandaRicerca, 'configurazione tablet anziani');
    });

    testWidgets('La domanda parte da quella del tipo e la tua non viene '
        'cambiata dal tipo', (tester) async {
      schermoAlto(tester);
      final archivio = await conChiave();
      await avviaApp(
        tester,
        archivio: archivio,
        ricerca: FintaRicerca(RicercaTrovata(trovata())),
        adesso: oggi,
      );
      await tocca(tester, find.bySemanticsLabel('Nuovo lavoro'));
      String campo() => tester
          .widget<TextField>(
            find.descendant(
              of: find.byKey(const Key('campo-domanda')),
              matching: find.byType(TextField),
            ),
          )
          .controller!
          .text;

      expect(campo(), domandaPredefinita[TipoLavoro.doppiaggio]);
      await tocca(tester, find.text('Codice'));
      expect(campo(), domandaPredefinita[TipoLavoro.codice]);

      await scrivi(tester, 'campo-domanda', 'sito per ristorante');
      await tocca(tester, find.text('Claude'));
      expect(campo(), 'sito per ristorante'); // l'hai scritta tu: resta

      // Se è quella di partenza non si salva nel lavoro
      await tocca(tester, find.text('Codice'));
      await scrivi(
        tester,
        'campo-domanda',
        domandaPredefinita[TipoLavoro.codice]!,
      );
      await scrivi(tester, 'campo-nome', 'Sito');
      await tocca(tester, find.text('Salva lavoro'));
      expect(archivio.tabellaLavori.elenco.single.domandaRicerca, isNull);
    });

    testWidgets('Modificando un lavoro si ritrova la domanda e la data '
        '"Richiesto il" non si perde', (tester) async {
      schermoAlto(tester);
      final archivio = await conChiave();
      archivio.salvaLavoro(
        Lavoro(
          id: '',
          nome: 'Amici',
          tipo: TipoLavoro.altro,
          relazione: Relazione.amico,
          livello: 3,
          prezzoPieno: 100,
          prezzoFinale: 70,
          richiestoIl: DateTime(2026, 10, 20),
          domandaRicerca: 'configurazione tablet anziani',
          creatoIl: DateTime(2026, 10, 1),
        ),
      );
      await avviaApp(
        tester,
        archivio: archivio,
        ricerca: FintaRicerca(RicercaTrovata(trovata())),
        adesso: oggi,
      );
      await tocca(tester, find.text('Amici'));
      await tocca(tester, find.bySemanticsLabel('Modifica lavoro'));
      expect(find.text('configurazione tablet anziani'), findsOneWidget);

      await tocca(tester, find.text('Salva modifiche'));
      final l = archivio.tabellaLavori.elenco.single;
      expect(l.richiestoIl, DateTime(2026, 10, 20));
      expect(l.domandaRicerca, 'configurazione tablet anziani');
    });

    testWidgets('Impostazioni: chiave e aggiornamento settimanale', (
      tester,
    ) async {
      schermoAlto(tester);
      final archivio = FintoArchivio();
      await avviaApp(tester, archivio: archivio, adesso: oggi);
      await tocca(tester, find.bySemanticsLabel('Impostazioni'));

      expect(find.text('Non inserita'), findsOneWidget);
      expect(find.text('Prima inserisci la chiave.'), findsOneWidget);

      await tocca(tester, find.byKey(const Key('riga-chiave')));
      await scrivi(tester, 'campo-chiave', 'chiave-sbagliata');
      await tocca(tester, find.text('Salva chiave'));
      expect(find.text('La chiave di Tavily inizia con tvly-'), findsOneWidget);

      // Incollata con spazi e a capo: si ripulisce
      await scrivi(tester, 'campo-chiave', '  tvly-dev-abcdef123456\n');
      await tocca(tester, find.text('Salva chiave'));
      expect(
        archivio.impostazioniSalvate.chiaveTavily,
        'tvly-dev-abcdef123456',
      );
      expect(find.text('Inserita'), findsOneWidget);

      await tocca(
        tester,
        find.byKey(const Key('interruttore-aggiorna-prezzi')),
      );
      expect(archivio.impostazioniSalvate.aggiornaPrezzi, isTrue);

      // Togliendo la chiave si spegne anche l'aggiornamento
      await tocca(tester, find.byKey(const Key('riga-chiave')));
      await tocca(tester, find.text('Togli la chiave'));
      expect(archivio.impostazioniSalvate.chiaveTavily, '');
      expect(archivio.impostazioniSalvate.aggiornaPrezzi, isFalse);
    });
  });

  group('Aggiornamento settimanale', () {
    Future<(StatoDati, FintoArchivio, FintaRicerca)> preparato({
      required bool acceso,
      Map<TipoLavoro, PrezzoMercato> prezzi = const {},
    }) async {
      final archivio = FintoArchivio();
      archivio.salvaImpostazioni(
        const Impostazioni().copyWith(
          chiaveTavily: 'tvly-prova-123456',
          aggiornaPrezzi: acceso,
        ),
      );
      for (final p in prezzi.values) {
        archivio.salvaPrezzoMercato(p);
      }
      final dati = StatoDati(
        accesso: FintoAccesso(iniziale: utenteProva),
        archivio: archivio,
        adesso: oggi,
      );
      // Aspetta che arrivino tutti i flussi
      for (var i = 0; i < 20 && !dati.caricato; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      return (dati, archivio, FintaRicerca(RicercaTrovata(trovata())));
    }

    test('spento: non cerca nulla', () async {
      final (dati, _, ricerca) = await preparato(acceso: false);
      final agg = AggiornamentoPrezzi(dati: dati, ricerca: ricerca);
      await agg.fatto;
      expect(ricerca.richieste, isEmpty);
      agg.dispose();
      dati.dispose();
    });

    test('acceso: cerca i tipi senza forbice e salva dal web', () async {
      final (dati, archivio, ricerca) = await preparato(acceso: true);
      final agg = AggiornamentoPrezzi(dati: dati, ricerca: ricerca);
      await agg.fatto;
      expect(
        ricerca.richieste.map((r) => r.tipo).toSet(),
        domandaPredefinita.keys.toSet(),
      );
      expect(archivio.tabellaPrezzi.elenco.length, domandaPredefinita.length);
      expect(archivio.tabellaPrezzi.elenco.every((p) => !p.manuale), isTrue);
      // Un credito per ricerca
      expect(
        archivio.impostazioniSalvate.ricercheUsate,
        domandaPredefinita.length,
      );
      agg.dispose();
      dati.dispose();
    });

    test('le forbici scritte a mano non si toccano; quelle web si '
        'aggiornano dopo 7 giorni', () async {
      final (dati, archivio, ricerca) = await preparato(
        acceso: true,
        prezzi: {
          TipoLavoro.doppiaggio: prezzo(TipoLavoro.doppiaggio),
          TipoLavoro.codice: prezzo(
            TipoLavoro.codice,
            manuale: false,
            quando: DateTime(2026, 10, 25), // 3 giorni fa: ancora fresca
          ),
          TipoLavoro.claude: prezzo(
            TipoLavoro.claude,
            manuale: false,
            quando: DateTime(2026, 10, 10), // vecchia di 18 giorni
          ),
        },
      );
      final agg = AggiornamentoPrezzi(dati: dati, ricerca: ricerca);
      await agg.fatto;
      expect(ricerca.richieste.map((r) => r.tipo), [TipoLavoro.claude]);
      expect(
        archivio.tabellaPrezzi.elenco
            .firstWhere((p) => p.tipo == TipoLavoro.claude)
            .aggiornato,
        oggi(),
      );
      agg.dispose();
      dati.dispose();
    });
  });

  group('Aggiornamento settimanale con domanda personalizzata', () {
    test(
      'rifà la stessa ricerca dell\'ultima volta, anche per "Altro"',
      () async {
        final archivio = FintoArchivio();
        archivio.salvaImpostazioni(
          const Impostazioni().copyWith(
            chiaveTavily: 'tvly-prova-123456',
            aggiornaPrezzi: true,
          ),
        );
        archivio.salvaPrezzoMercato(
          PrezzoMercato(
            tipo: TipoLavoro.altro,
            minimo: 80,
            massimo: 120,
            aggiornato: DateTime(2026, 10, 1), // vecchia di 27 giorni
            manuale: false,
            domanda: 'configurazione tablet anziani Italia prezzo euro',
          ),
        );
        final dati = StatoDati(
          accesso: FintoAccesso(iniziale: utenteProva),
          archivio: archivio,
          adesso: oggi,
        );
        for (var i = 0; i < 20 && !dati.caricato; i++) {
          await Future<void>.delayed(Duration.zero);
        }
        final ricerca = FintaRicerca(RicercaTrovata(trovata()));
        final agg = AggiornamentoPrezzi(dati: dati, ricerca: ricerca);
        await agg.fatto;

        final altro = ricerca.richieste.where(
          (r) => r.tipo == TipoLavoro.altro,
        );
        expect(
          altro.single.domanda,
          'configurazione tablet anziani Italia prezzo euro',
        );
        agg.dispose();
        dati.dispose();
      },
    );

    test('"Altro" senza una ricerca di prima non si cerca da solo', () async {
      final archivio = FintoArchivio();
      archivio.salvaImpostazioni(
        const Impostazioni().copyWith(
          chiaveTavily: 'tvly-prova-123456',
          aggiornaPrezzi: true,
        ),
      );
      final dati = StatoDati(
        accesso: FintoAccesso(iniziale: utenteProva),
        archivio: archivio,
        adesso: oggi,
      );
      for (var i = 0; i < 20 && !dati.caricato; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      final ricerca = FintaRicerca(RicercaTrovata(trovata()));
      final agg = AggiornamentoPrezzi(dati: dati, ricerca: ricerca);
      await agg.fatto;
      expect(ricerca.richieste.any((r) => r.tipo == TipoLavoro.altro), isFalse);
      agg.dispose();
      dati.dispose();
    });
  });

  group('Prezzo suggerito con l\'apprendimento', () {
    testWidgets('Lavori incassati sopra il mercato spostano il prezzo e '
        'compare l\'avviso in Home', (tester) async {
      schermoAlto(tester);
      final archivio = FintoArchivio();
      archivio.salvaPrezzoMercato(prezzo(TipoLavoro.doppiaggio));
      for (var i = 0; i < 3; i++) {
        final id = archivio.salvaLavoro(
          incassato(130, giorno: DateTime(2026, 10, 1 + i)),
        );
        archivio.salvaSottoprogetto(
          Sottoprogetto(
            id: '',
            lavoroId: id,
            nome: 'Tutto',
            ricavo: 130,
            costiDiretti: 0,
            ore: 1,
            creatoIl: DateTime(2026, 10, 1),
          ),
        );
      }
      await avviaApp(tester, archivio: archivio, adesso: oggi);

      // Scarto medio +30% (sopra il 20%): avviso in Home
      expect(
        find.textContaining('Doppiaggio: incassi in media il 30% in più'),
        findsOneWidget,
      );

      // Il prezzo suggerito usa la forbice spostata del massimo, +15%: 92 – 138 €
      await tocca(tester, find.bySemanticsLabel('Nuovo lavoro'));
      expect(find.text('92 – 138 €'), findsOneWidget);
      expect(
        find.textContaining('Corretta del +15% sui tuoi ultimi 3 lavori'),
        findsOneWidget,
      );
    });
  });
}
