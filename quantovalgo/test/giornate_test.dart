import 'package:flutter_test/flutter_test.dart';
import 'package:quantovalgo/logica/giornate.dart';
import 'package:quantovalgo/modelli/giornata.dart';
import 'package:quantovalgo/modelli/lavoro.dart';
import 'package:quantovalgo/modelli/tipi.dart';

void main() {
  // Lunedì 26 ottobre 2026
  final lunedi = DateTime(2026, 10, 26);

  String giorno(DateTime d) => '${d.day}/${d.month}';

  group('Schema dei giorni', () {
    test('lun–ven per 5 giorni dal lunedì → lun…ven', () {
      final g = giorniDelloSchema(
        dal: lunedi,
        giorniSettimana: lunediVenerdi,
        numeroGiorni: 5,
      );
      expect(g.map(giorno), ['26/10', '27/10', '28/10', '29/10', '30/10']);
    });

    test('il weekend si salta e il conteggio conta solo i giorni scelti', () {
      // 7 giorni lavorati lun–ven dal giovedì: gio, ven, lun, mar, mer, gio, ven
      final g = giorniDelloSchema(
        dal: DateTime(2026, 10, 29),
        giorniSettimana: lunediVenerdi,
        numeroGiorni: 7,
      );
      expect(g.map(giorno), [
        '29/10',
        '30/10',
        '2/11',
        '3/11',
        '4/11',
        '5/11',
        '6/11',
      ]);
    });

    test('con "fino al" si ferma a quel giorno, compreso', () {
      final g = giorniDelloSchema(
        dal: lunedi,
        giorniSettimana: tuttiIGiorni,
        fino: DateTime(2026, 10, 29),
      );
      expect(g.map(giorno), ['26/10', '27/10', '28/10', '29/10']);
    });

    test('con numero e data vince il limite che arriva prima', () {
      final g = giorniDelloSchema(
        dal: lunedi,
        giorniSettimana: tuttiIGiorni,
        numeroGiorni: 10,
        fino: DateTime(2026, 10, 28),
      );
      expect(g, hasLength(3));
    });

    test('solo alcuni giorni: lun, mer e sab', () {
      final g = giorniDelloSchema(
        dal: lunedi,
        giorniSettimana: {1, 3, 6},
        fino: DateTime(2026, 11, 8),
      );
      expect(g.map(giorno), [
        '26/10',
        '28/10',
        '31/10',
        '2/11',
        '4/11',
        '7/11',
      ]);
    });

    test('il giorno di partenza conta se è tra quelli scelti', () {
      final sabato = DateTime(2026, 10, 31);
      expect(
        giorniDelloSchema(
          dal: sabato,
          giorniSettimana: lunediVenerdi,
          numeroGiorni: 1,
        ).single,
        DateTime(2026, 11, 2), // lunedì: il sabato non è scelto
      );
      expect(
        giorniDelloSchema(
          dal: sabato,
          giorniSettimana: lunediSabato,
          numeroGiorni: 1,
        ).single,
        sabato,
      );
    });

    test('i giorni esclusi si saltano e non contano nel numero', () {
      final g = giorniDelloSchema(
        dal: lunedi,
        giorniSettimana: lunediVenerdi,
        numeroGiorni: 3,
        esclusi: {DateTime(2026, 10, 26), DateTime(2026, 10, 27)},
      );
      expect(g.map(giorno), ['28/10', '29/10', '30/10']);
    });

    test('nessun giorno o nessun limite → nessuna giornata', () {
      expect(
        giorniDelloSchema(dal: lunedi, giorniSettimana: {}, numeroGiorni: 5),
        isEmpty,
      );
      expect(
        giorniDelloSchema(dal: lunedi, giorniSettimana: tuttiIGiorni),
        isEmpty,
      );
      expect(
        giorniDelloSchema(
          dal: lunedi,
          giorniSettimana: tuttiIGiorni,
          numeroGiorni: 0,
        ),
        isEmpty,
      );
    });

    test('c\'è un tetto di sicurezza (circa un anno)', () {
      final g = giorniDelloSchema(
        dal: lunedi,
        giorniSettimana: tuttiIGiorni,
        numeroGiorni: 100000,
      );
      expect(g, hasLength(maxGiorniSchema));
    });

    test('il cambio d\'ora non sposta i giorni', () {
      // Il 25 ottobre 2026 in Italia finisce l'ora legale
      final g = giorniDelloSchema(
        dal: DateTime(2026, 10, 24),
        giorniSettimana: tuttiIGiorni,
        numeroGiorni: 4,
      );
      expect(g.map(giorno), ['24/10', '25/10', '26/10', '27/10']);
      expect(g.every((d) => d.hour == 0), isTrue);
    });
  });

  group('Giornate', () {
    Giornata g(DateTime data, double importo) => Giornata(
      id: 'x',
      lavoroId: 'l',
      data: data,
      importo: importo,
      creatoIl: DateTime(2026),
    );

    test('30 € al giorno per 10 giorni = 300 €', () {
      final tutte = [
        for (var i = 0; i < 10; i++) g(DateTime(2026, 10, 1 + i), 30),
      ];
      expect(totaleGiornate(tutte), 300);
    });

    test('una giornata è fatta dal suo giorno in poi (anche se è oggi)', () {
      final adesso = DateTime(2026, 10, 28, 15, 30);
      expect(giornataFatta(g(DateTime(2026, 10, 27), 30), adesso), isTrue);
      expect(giornataFatta(g(DateTime(2026, 10, 28), 30), adesso), isTrue);
      expect(giornataFatta(g(DateTime(2026, 10, 29), 30), adesso), isFalse);
    });

    test('salvataggio e lettura tengono solo il giorno', () {
      final letta = Giornata.fromMap(
        'a',
        g(DateTime(2026, 10, 28, 18, 45), 40).toMap(),
      );
      expect(letta.data, DateTime(2026, 10, 28));
      expect(letta.importo, 40);
    });

    test('il lavoro a giornata ricorda la tariffa', () {
      final lavoro = Lavoro(
        id: 'n',
        nome: 'Negozio',
        tipo: TipoLavoro.aGiornata,
        relazione: Relazione.nuovo,
        livello: 3,
        prezzoPieno: 0,
        prezzoFinale: 0,
        tariffaGiornaliera: 30,
        creatoIl: DateTime(2026),
      );
      final letto = Lavoro.fromMap('n', lavoro.toMap());
      expect(letto.tipo, TipoLavoro.aGiornata);
      expect(letto.tariffaGiornaliera, 30);
    });
  });
}
