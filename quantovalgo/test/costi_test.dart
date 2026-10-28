import 'package:flutter_test/flutter_test.dart';
import 'package:quantovalgo/logica/costi.dart';
import 'package:quantovalgo/logica/mesi.dart';
import 'package:quantovalgo/modelli/costo.dart';
import 'package:quantovalgo/modelli/lavoro.dart';
import 'package:quantovalgo/modelli/tipi.dart';

Costo costo(
  TipoCosto tipo,
  double importo, {
  DateTime? inizio,
  int mesi = 1,
  DateTime? fine,
}) => Costo(
  id: 'c',
  nome: 'x',
  tipo: tipo,
  importo: importo,
  mesi: mesi,
  inizio: inizio ?? DateTime(2026, 10, 5),
  fine: fine,
  creatoIl: DateTime(2026),
);

Lavoro lavoro(
  String id, {
  DateTime? creato,
  StatoPagamento stato = StatoPagamento.daIncassare,
  DateTime? incasso,
}) => Lavoro(
  id: id,
  nome: id,
  tipo: TipoLavoro.altro,
  relazione: Relazione.nuovo,
  livello: 3,
  prezzoPieno: 0,
  prezzoFinale: 0,
  creatoIl: creato ?? DateTime(2026, 9, 1),
  statoPagamento: stato,
  dataIncasso: incasso,
);

void main() {
  final ottobre = DateTime(2026, 10);

  group('Quota di un costo nel mese (numeri del brief)', () {
    test('attrezzatura 90 € ÷ 6 mesi = 15 €/mese', () {
      final microfono = costo(TipoCosto.unaTantum, 90, mesi: 6);
      expect(quotaNelMese(microfono, ottobre), 15);
      expect(quotaNelMese(microfono, DateTime(2027, 3)), 15); // sesto mese
      expect(quotaNelMese(microfono, DateTime(2027, 4)), 0); // finito
      expect(
        quotaNelMese(microfono, DateTime(2026, 9)),
        0,
      ); // non ancora comprato
    });

    test(
      'una tantum "tutto nel mese": pesa tutto solo nel mese dell\'acquisto',
      () {
        final cuffie = costo(TipoCosto.unaTantum, 120);
        expect(quotaNelMese(cuffie, ottobre), 120);
        expect(quotaNelMese(cuffie, DateTime(2026, 11)), 0);
        expect(quotaNelMese(cuffie, DateTime(2026, 9)), 0);
      },
    );

    test('abbonamento e fisso pesano ogni mese dall\'inizio', () {
      final claude = costo(
        TipoCosto.abbonamento,
        20,
        inizio: DateTime(2026, 8, 20),
      );
      expect(quotaNelMese(claude, DateTime(2026, 7)), 0);
      expect(quotaNelMese(claude, DateTime(2026, 8)), 20);
      expect(quotaNelMese(claude, DateTime(2027, 5)), 20);
    });

    test('un abbonamento disdetto smette dopo l\'ultimo mese', () {
      final software = costo(
        TipoCosto.abbonamento,
        12,
        inizio: DateTime(2026, 1, 1),
        fine: DateTime(2026, 10, 14),
      );
      expect(quotaNelMese(software, ottobre), 12);
      expect(quotaNelMese(software, DateTime(2026, 11)), 0);
    });

    test('costi del mese: 20 + 12 + 15 = 47 €', () {
      final costi = [
        costo(TipoCosto.abbonamento, 20),
        costo(TipoCosto.abbonamento, 12),
        costo(TipoCosto.unaTantum, 90, mesi: 6),
      ];
      expect(totaleCostiDelMese(costi, ottobre), 47);
    });
  });

  group('Divisione tra i progetti', () {
    test('Claude 20 € con ore 11 / 7 / 2 → 11 + 7 + 2 €', () {
      final q = ripartisci(20, const [
        PesoProgetto('bosco', 11),
        PesoProgetto('sito', 7),
        PesoProgetto('spot', 2),
      ]);
      expect([for (final x in q) x.importo], [11, 7, 2]);
      expect(q.first.percentuale, closeTo(55, 1e-9));
    });

    test('senza ore si divide in parti uguali', () {
      final q = ripartisci(30, const [
        PesoProgetto('a', 0),
        PesoProgetto('b', 0),
        PesoProgetto('c', 0),
      ]);
      expect([for (final x in q) x.importo], [10, 10, 10]);
    });

    test(
      'i centesimi avanzati non si perdono: la somma fa sempre l\'importo',
      () {
        for (final importo in [10.0, 20.0, 15.0, 0.01, 99.99, 12.5]) {
          final q = ripartisci(importo, const [
            PesoProgetto('a', 3),
            PesoProgetto('b', 3),
            PesoProgetto('c', 3),
          ]);
          final somma = q.fold<double>(0, (s, x) => s + x.importo);
          expect(
            (somma * 100).round(),
            (importo * 100).round(),
            reason: 'importo $importo',
          );
          expect(
            q.fold<double>(0, (s, x) => s + x.percentuale),
            closeTo(100, 1e-9),
          );
        }
      },
    );

    test('senza progetti non c\'è nessuna quota', () {
      expect(ripartisci(20, const []), isEmpty);
    });
  });

  group('Progetti attivi nel mese', () {
    test('contano quelli creati e non ancora incassati', () {
      final attivi = progettiAttivi([
        lavoro('vecchio'),
        lavoro('futuro', creato: DateTime(2026, 11, 2)),
        lavoro(
          'chiuso-prima',
          stato: StatoPagamento.incassato,
          incasso: DateTime(2026, 9, 20),
        ),
        lavoro(
          'chiuso-in-ottobre',
          stato: StatoPagamento.incassato,
          incasso: DateTime(2026, 10, 3),
        ),
      ], ottobre);
      expect([for (final l in attivi) l.id], ['vecchio', 'chiuso-in-ottobre']);
    });
  });

  group('Costo sostenuto fino a un mese', () {
    test('una tantum: il prezzo intero dopo l\'acquisto, niente prima', () {
      final microfono = costo(TipoCosto.unaTantum, 90, mesi: 6);
      expect(costoSostenutoFinoA(microfono, DateTime(2026, 9)), 0);
      expect(costoSostenutoFinoA(microfono, ottobre), 90);
      expect(costoSostenutoFinoA(microfono, DateTime(2027, 6)), 90);
    });

    test('abbonamento: la somma dei mesi pagati (gen–ott = 10 × 20 €)', () {
      final claude = costo(
        TipoCosto.abbonamento,
        20,
        inizio: DateTime(2026, 1, 15),
      );
      expect(costoSostenutoFinoA(claude, ottobre), 200);
      expect(costoSostenutoFinoA(claude, DateTime(2025, 12)), 0);
    });

    test('un abbonamento disdetto smette di crescere', () {
      final claude = costo(
        TipoCosto.abbonamento,
        20,
        inizio: DateTime(2026, 1),
        fine: DateTime(2026, 3, 10),
      );
      expect(
        costoSostenutoFinoA(claude, DateTime(2026, 12)),
        60,
      ); // gen, feb, mar
    });
  });

  group('Da recuperare per tipo', () {
    final claude = costo(TipoCosto.abbonamento, 20, inizio: DateTime(2026, 1));
    final doppiaggio = costo(TipoCosto.unaTantum, 90, mesi: 6);
    final generico = costo(TipoCosto.unaTantum, 100);
    final internet = costo(TipoCosto.fisso, 30, inizio: DateTime(2026, 1));
    final costi = [claude, doppiaggio, generico, internet];

    TipoLavoro? tipoDi(Costo c) => c == claude
        ? TipoLavoro.claude
        : c == doppiaggio
        ? TipoLavoro.doppiaggio
        : null;

    List<GruppoRecupero> calcola(Map<TipoLavoro, double> utile) =>
        gruppiDaRecuperare(
          costi: costi,
          tipoDelCosto: tipoDi,
          utileIncassatoPerTipo: utile,
          mese: ottobre,
        );

    test('ogni tipo conta i propri costi, gli altri solo le una tantum', () {
      final g = calcola({});
      expect(
        [for (final x in g) x.tipo],
        [TipoLavoro.doppiaggio, TipoLavoro.claude, null],
      );
      expect(
        [for (final x in g) x.totale],
        [90, 200, 100],
      ); // l'internet fisso non conta
      expect(g.every((x) => x.recuperato == 0), isTrue);
    });

    test('i costi Claude si coprono solo con i progetti Claude', () {
      // 150 € di utile sul doppiaggio non toccano il costo Claude
      final g = calcola({TipoLavoro.doppiaggio: 150});
      final cla = g.firstWhere((x) => x.tipo == TipoLavoro.claude);
      expect(cla.recuperato, 0);
      expect(cla.residuo, 200);

      final conClaude = calcola({TipoLavoro.claude: 120});
      final cla2 = conClaude.firstWhere((x) => x.tipo == TipoLavoro.claude);
      expect(cla2.recuperato, 120);
      expect(cla2.residuo, 80);
      expect(cla2.avanzamento, closeTo(0.6, 1e-9));
    });

    test('mai oltre il totale e mai sotto zero', () {
      final g = calcola({TipoLavoro.claude: 999, TipoLavoro.doppiaggio: -50});
      expect(g.firstWhere((x) => x.tipo == TipoLavoro.claude).residuo, 0);
      expect(
        g.firstWhere((x) => x.tipo == TipoLavoro.doppiaggio).recuperato,
        0,
      );
    });

    test('gli altri costi si coprono con l\'utile che avanza', () {
      // Claude: costo 200, utile 260 → avanzano 60; doppiaggio: 90 con utile 0
      // Codice non ha costi: tutto il suo utile (30) avanza → 90 per gli altri
      final g = calcola({TipoLavoro.claude: 260, TipoLavoro.codice: 30});
      final altri = g.firstWhere((x) => x.tipo == null);
      expect(altri.recuperato, 90);
      expect(altri.residuo, 10);
    });

    test('l\'utile di un tipo non si usa due volte', () {
      // 200 € di utile Claude bastano giusto per il costo Claude: per gli altri non avanza nulla
      final g = calcola({TipoLavoro.claude: 200});
      expect(g.firstWhere((x) => x.tipo == null).recuperato, 0);
    });

    test('senza costi non c\'è nessun gruppo', () {
      expect(
        gruppiDaRecuperare(
          costi: const [],
          tipoDelCosto: (_) => null,
          utileIncassatoPerTipo: {TipoLavoro.claude: 10},
          mese: ottobre,
        ),
        isEmpty,
      );
    });
  });

  group('Mesi', () {
    test('nomi e passaggio d\'anno', () {
      expect(nomeMeseAnno(DateTime(2026, 10, 28)), 'ottobre 2026');
      expect(meseSuccessivo(DateTime(2026, 12)), DateTime(2027, 1));
      expect(mesePrecedente(DateTime(2026, 1)), DateTime(2025, 12));
      expect(differenzaMesi(DateTime(2026, 10), DateTime(2027, 3)), 5);
    });
  });
}
