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

  group('Da recuperare per categoria', () {
    final claude = costo(TipoCosto.abbonamento, 20, inizio: DateTime(2026, 1));
    final microfono = costo(TipoCosto.unaTantum, 90, mesi: 6);
    final podcast = costo(TipoCosto.unaTantum, 40);
    final scrivania = costo(TipoCosto.unaTantum, 100); // senza categoria
    final internet = costo(TipoCosto.fisso, 30, inizio: DateTime(2026, 1));
    final costi = [claude, microfono, podcast, scrivania, internet];

    // Categorie qualsiasi, anche inventate da te
    String? categoriaDi(Costo c) => c == claude
        ? 'claude'
        : c == microfono
        ? 'doppiaggio'
        : c == podcast
        ? 'podcast'
        : null;
    const ordine = ['doppiaggio', 'claude', 'podcast'];

    List<GruppoRecupero> calcola(Map<String?, double> utile) =>
        gruppiDaRecuperare(
          costi: costi,
          categoriaDelCosto: categoriaDi,
          utileIncassato: utile,
          ordine: ordine,
          mese: ottobre,
        );

    test(
      'ogni categoria conta i propri costi, gli altri solo le una tantum',
      () {
        final g = calcola({});
        expect(
          [for (final x in g) x.categoriaId],
          ['doppiaggio', 'claude', 'podcast', null],
        );
        expect(
          [for (final x in g) x.totale],
          [90, 200, 40, 100],
        ); // l'internet fisso non conta
        expect(g.every((x) => x.recuperato == 0), isTrue);
      },
    );

    test('un costo si copre solo con i progetti della sua categoria (qualsiasi sia)', () {
      // 150 € di utile sul doppiaggio non toccano né Claude né Podcast
      final g = calcola({'doppiaggio': 150});
      expect(g.firstWhere((x) => x.categoriaId == 'claude').recuperato, 0);
      expect(g.firstWhere((x) => x.categoriaId == 'podcast').recuperato, 0);

      final conPodcast = calcola({'podcast': 25});
      final p = conPodcast.firstWhere((x) => x.categoriaId == 'podcast');
      expect(p.recuperato, 25);
      expect(p.residuo, 15);
      expect(p.avanzamento, closeTo(0.625, 1e-9));
      expect(
        conPodcast.firstWhere((x) => x.categoriaId == 'claude').recuperato,
        0,
      );
    });

    test('mai oltre il totale e mai sotto zero', () {
      final g = calcola({'claude': 999, 'doppiaggio': -50});
      expect(g.firstWhere((x) => x.categoriaId == 'claude').residuo, 0);
      expect(g.firstWhere((x) => x.categoriaId == 'doppiaggio').recuperato, 0);
    });

    test('gli altri costi si coprono con l\'utile che avanza', () {
      // Claude: costo 200, utile 260 → avanzano 60.
      // Progetti senza categoria (chiave null): 30. Totale che avanza: 90 su 100.
      final g = calcola({'claude': 260, null: 30});
      final altri = g.firstWhere((x) => x.categoriaId == null);
      expect(altri.recuperato, 90);
      expect(altri.residuo, 10);
    });

    test('l\'utile di una categoria non si usa due volte', () {
      // 200 € di utile Claude bastano giusto per il costo Claude
      final g = calcola({'claude': 200});
      expect(g.firstWhere((x) => x.categoriaId == null).recuperato, 0);
    });

    test('l\'utile di una categoria senza costi avanza per gli altri', () {
      final g = calcola({'negozio': 70}); // "negozio" non ha costi propri
      expect(g.firstWhere((x) => x.categoriaId == null).recuperato, 70);
    });

    test('senza costi non c\'è nessuna riga', () {
      expect(
        gruppiDaRecuperare(
          costi: const [],
          categoriaDelCosto: (_) => null,
          utileIncassato: {'claude': 10},
          ordine: const ['claude'],
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
