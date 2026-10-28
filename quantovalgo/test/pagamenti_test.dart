import 'package:flutter_test/flutter_test.dart';
import 'package:quantovalgo/logica/pagamenti.dart';
import 'package:quantovalgo/logica/promemoria.dart';
import 'package:quantovalgo/modelli/cliente.dart';
import 'package:quantovalgo/modelli/lavoro.dart';
import 'package:quantovalgo/modelli/tipi.dart';

Lavoro lavoro({
  String id = 'l',
  String nome = 'Radio locale',
  String? clienteId,
  DateTime? scadenza,
  DateTime? incasso,
  DateTime? richiesto,
  DateTime? creato,
  StatoPagamento stato = StatoPagamento.daIncassare,
  TipoLavoro tipo = TipoLavoro.altro,
}) => Lavoro(
  id: id,
  nome: nome,
  clienteId: clienteId,
  tipo: tipo,
  relazione: Relazione.nuovo,
  livello: 3,
  prezzoPieno: 0,
  prezzoFinale: 0,
  statoPagamento: stato,
  scadenza: scadenza,
  dataIncasso: incasso,
  richiestoIl: richiesto,
  creatoIl: creato ?? DateTime(2026, 10, 1),
);

void main() {
  statisticheEPromemoria();
  final oggi = DateTime(2026, 10, 28, 15, 30);

  group('Ritardo', () {
    test('scadenza superata e non incassato: 18 giorni di ritardo (esempio del brief)', () {
      final l = lavoro(scadenza: DateTime(2026, 10, 10));
      expect(inRitardo(l, oggi), isTrue);
      expect(giorniRitardo(l, oggi), 18);
    });

    test('il giorno della scadenza non è ancora ritardo', () {
      final l = lavoro(scadenza: DateTime(2026, 10, 28));
      expect(inRitardo(l, oggi), isFalse);
      expect(giorniRitardo(l, oggi), 0);
      expect(inRitardo(l, DateTime(2026, 10, 29, 0, 5)), isTrue);
    });

    test('senza scadenza o già incassato non è mai in ritardo', () {
      expect(inRitardo(lavoro(), oggi), isFalse);
      expect(
        inRitardo(
          lavoro(scadenza: DateTime(2026, 9), stato: StatoPagamento.incassato),
          oggi,
        ),
        isFalse,
      );
    });

    test('i lavori a giornata non hanno pagamenti', () {
      final l = lavoro(scadenza: DateTime(2026, 9), tipo: TipoLavoro.aGiornata);
      expect(haPagamento(l), isFalse);
      expect(daIncassare(l), isFalse);
      expect(inRitardo(l, oggi), isFalse);
    });

    test('i giorni si contano bene anche col cambio d\'ora', () {
      // L'ora legale finisce il 25 ottobre 2026
      expect(giorniTra(DateTime(2026, 10, 24), DateTime(2026, 10, 26)), 2);
      expect(giorniTra(DateTime(2026, 3, 28), DateTime(2026, 3, 30)), 2);
    });
  });

  group('Giorni per pagare', () {
    test('dalla richiesta all\'incasso', () {
      final l = lavoro(
        richiesto: DateTime(2026, 10, 1),
        incasso: DateTime(2026, 10, 10),
        stato: StatoPagamento.incassato,
      );
      expect(giorniPerPagare(l), 9); // "Luca paga in ~9 giorni"
    });

    test('senza data di richiesta si parte dalla creazione del lavoro', () {
      final l = lavoro(
        creato: DateTime(2026, 10, 6, 18),
        incasso: DateTime(2026, 10, 10),
        stato: StatoPagamento.incassato,
      );
      expect(giorniPerPagare(l), 4); // "Marta paga in ~4 giorni"
    });

    test('mai negativi; niente se non è incassato', () {
      expect(
        giorniPerPagare(
          lavoro(
            richiesto: DateTime(2026, 10, 20),
            incasso: DateTime(2026, 10, 10),
            stato: StatoPagamento.incassato,
          ),
        ),
        0,
      );
      expect(giorniPerPagare(lavoro()), isNull);
      expect(
        giorniPerPagare(lavoro(stato: StatoPagamento.incassato)), // senza data
        isNull,
      );
    });

    test('media: (9 + 4) ÷ 2 = 6,5 giorni', () {
      final lavori = [
        lavoro(
          richiesto: DateTime(2026, 10, 1),
          incasso: DateTime(2026, 10, 10),
          stato: StatoPagamento.incassato,
        ),
        lavoro(
          richiesto: DateTime(2026, 10, 6),
          incasso: DateTime(2026, 10, 10),
          stato: StatoPagamento.incassato,
        ),
        lavoro(), // non incassato: non conta
      ];
      expect(mediaGiorniPerPagare(lavori), 6.5);
      expect(mediaGiorniPerPagare([lavoro()]), isNull);
    });
  });

  group('Importi e scadenze', () {
    test('importo da incassare: ricavi dei sottoprogetti, altrimenti prezzo finale', () {
      expect(importoDaIncassare(700, 650), 700);
      expect(importoDaIncassare(0, 650), 650);
      expect(importoDaIncassare(0, 0), 0);
    });

    test('scadenza a +30 giorni, anche a cavallo di mese e d\'anno', () {
      expect(
        scadenzaDopo(DateTime(2026, 10, 28, 9), 30),
        DateTime(2026, 11, 27),
      );
      expect(scadenzaDopo(DateTime(2026, 12, 20), 15), DateTime(2027, 1, 4));
    });
  });

  test('i campi di pagamento si salvano e si leggono', () {
    final l = lavoro(
      scadenza: DateTime(2026, 11, 10),
      incasso: DateTime(2026, 11, 2),
      richiesto: DateTime(2026, 10, 5),
      stato: StatoPagamento.incassato,
    );
    final letto = Lavoro.fromMap('l', l.toMap());
    expect(letto.scadenza, DateTime(2026, 11, 10));
    expect(letto.dataIncasso, DateTime(2026, 11, 2));
    expect(letto.richiestoIl, DateTime(2026, 10, 5));
    expect(letto.statoPagamento, StatoPagamento.incassato);
    // copyWith può cambiare e togliere la scadenza
    expect(l.copyWith(scadenza: () => null).scadenza, isNull);
    expect(l.copyWith(scadenza: () => DateTime(2027)).scadenza, DateTime(2027));
    expect(l.copyWith().scadenza, DateTime(2026, 11, 10));
  });
}

// ---------------------------------------------------------------------------
// Statistiche dei clienti e promemoria
// ---------------------------------------------------------------------------

Cliente cliente(String id, String nome) => Cliente(
  id: id,
  nome: nome,
  relazione: Relazione.nuovo,
  creatoIl: DateTime(2026),
);

void statisticheEPromemoria() {
  final oggi = DateTime(2026, 10, 28, 15, 30);

  group('Statistiche dei clienti', () {
    test('quanto ha dato, in quanti giorni e se è in ritardo', () {
      final luca = cliente('luca', 'Luca');
      final radio = cliente('radio', 'Radio locale');
      final lavori = [
        // Luca: due incassati (9 e 3 giorni), uno ancora da incassare nei tempi
        lavoro(
          id: 'a',
          clienteId: 'luca',
          richiesto: DateTime(2026, 10, 1),
          incasso: DateTime(2026, 10, 10),
          stato: StatoPagamento.incassato,
        ),
        lavoro(
          id: 'b',
          clienteId: 'luca',
          richiesto: DateTime(2026, 10, 7),
          incasso: DateTime(2026, 10, 10),
          stato: StatoPagamento.incassato,
        ),
        lavoro(id: 'c', clienteId: 'luca', scadenza: DateTime(2026, 11, 20)),
        // Radio locale: in ritardo di 18 giorni
        lavoro(id: 'd', clienteId: 'radio', scadenza: DateTime(2026, 10, 10)),
        // Un lavoro a giornata del negozio non conta come pagamento
        lavoro(id: 'e', clienteId: 'radio', tipo: TipoLavoro.aGiornata),
      ];
      final stat = statisticheClienti(
        clienti: [luca, radio],
        lavori: lavori,
        importo: (l) =>
            const {'a': 700.0, 'b': 210.0, 'c': 100.0, 'd': 120.0}[l.id] ?? 0,
        adesso: oggi,
      );

      final l = stat[0];
      expect(l.cliente.nome, 'Luca');
      expect(l.lavori, 3);
      expect(l.incassato, 910);
      expect(l.giorniMedi, 6); // (9 + 3) ÷ 2
      expect(l.ritardatario, isFalse);

      final r = stat[1];
      expect(r.lavori, 1); // il lavoro a giornata non conta
      expect(r.incassato, 0);
      expect(r.giorniMedi, isNull);
      expect(r.ritardatario, isTrue);
      expect(r.lavoriInRitardo, 1);
      expect(r.importoInRitardo, 120);
      expect(r.maxGiorniRitardo, 18);
    });

    test('un cliente senza lavori ha tutto a zero', () {
      final stat = statisticheClienti(
        clienti: [cliente('x', 'Nuovo')],
        lavori: const [],
        importo: (_) => 0,
        adesso: oggi,
      );
      expect(stat.single.lavori, 0);
      expect(stat.single.giorniMedi, isNull);
      expect(stat.single.ritardatario, isFalse);
    });
  });

  group('Promemoria', () {
    List<Promemoria> calcola(
      List<Lavoro> lavori, {
      DateTime? adesso,
      int massimo = 60,
    }) => promemoriaPagamenti(
      lavori: lavori,
      importo: (_) => 700,
      cliente: (l) => l.clienteId == null ? '' : 'Luca',
      adesso: adesso ?? oggi,
      massimo: massimo,
    );

    String giorno(DateTime d) => '${d.day}/${d.month} ${d.hour}:00';

    test(
      'prima della scadenza: il giorno prima e il giorno stesso, alle 9',
      () {
        final p = calcola([
          lavoro(
            nome: 'Il bosco',
            clienteId: 'luca',
            scadenza: DateTime(2026, 11, 10),
          ),
        ]);
        expect(
          [for (final x in p.take(2)) giorno(x.quando)],
          ['9/11 9:00', '10/11 9:00'],
        );
        expect(p[0].titolo, 'Domani scade un pagamento');
        expect(p[0].testo, '«Il bosco» (Luca): 700 €');
        expect(p[1].titolo, 'Oggi scade un pagamento');
      },
    );

    test('dopo la scadenza: ogni 3 giorni di ritardo, 5 volte', () {
      final p = calcola([lavoro(scadenza: DateTime(2026, 11, 10))]);
      final ritardi = p
          .where((x) => x.titolo == 'Pagamento in ritardo')
          .toList();
      expect(
        [for (final x in ritardi) giorno(x.quando)],
        ['13/11 9:00', '16/11 9:00', '19/11 9:00', '22/11 9:00', '25/11 9:00'],
      );
      expect(
        ritardi.first.testo,
        '«Radio locale»: 700 € · ritardo di 3 giorni',
      );
      expect(ritardi.last.testo.endsWith('ritardo di 15 giorni'), isTrue);
    });

    test('un pagamento già in ritardo riceve solo i promemoria futuri', () {
      // Scaduto il 25: oggi è il 28 → restano 28+... (+3 = 28 alle 9:00 è già passato)
      final p = calcola([lavoro(scadenza: DateTime(2026, 10, 25))]);
      expect(
        [for (final x in p) giorno(x.quando)],
        [
          '31/10 9:00', // +6
          '3/11 9:00', // +9
          '6/11 9:00', // +12
          '9/11 9:00', // +15
        ],
      );
    });

    test(
      'senza scadenza, incassati e lavori a giornata non hanno promemoria',
      () {
        expect(calcola([lavoro()]), isEmpty);
        expect(
          calcola([
            lavoro(
              scadenza: DateTime(2026, 11, 10),
              stato: StatoPagamento.incassato,
            ),
          ]),
          isEmpty,
        );
        expect(
          calcola([
            lavoro(
              scadenza: DateTime(2026, 11, 10),
              tipo: TipoLavoro.aGiornata,
            ),
          ]),
          isEmpty,
        );
      },
    );

    test('con più lavori si ordinano nel tempo e si tiene il massimo', () {
      final lavori = [
        lavoro(id: 'tardi', nome: 'Tardi', scadenza: DateTime(2026, 12, 20)),
        lavoro(id: 'presto', nome: 'Presto', scadenza: DateTime(2026, 11, 2)),
      ];
      final p = calcola(lavori);
      expect(p.first.testo.contains('Presto'), isTrue);
      expect([for (final x in p) x.id], List.generate(p.length, (i) => i + 1));
      for (var i = 1; i < p.length; i++) {
        expect(p[i].quando.isBefore(p[i - 1].quando), isFalse);
      }
      expect(calcola(lavori, massimo: 3), hasLength(3));
    });

    test('nessuna notifica nel passato, nemmeno di poco', () {
      final p = calcola(
        [lavoro(scadenza: DateTime(2026, 10, 28))],
        adesso: DateTime(2026, 10, 28, 9, 0), // le 9 sono già "adesso"
      );
      expect(p.first.quando, DateTime(2026, 10, 31, 9));
    });

    test('il cliente mancante non lascia parentesi vuote', () {
      final p = calcola([lavoro(scadenza: DateTime(2026, 11, 10))]);
      expect(p.first.testo, '«Radio locale»: 700 €');
    });
  });
}
