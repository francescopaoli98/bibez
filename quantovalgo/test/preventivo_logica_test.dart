import 'package:flutter_test/flutter_test.dart';
import 'package:quantovalgo/logica/preventivo.dart';
import 'package:quantovalgo/modelli/preventivo.dart';
import 'package:quantovalgo/modelli/tipi.dart';

void main() {
  group('Testi dal modello', () {
    test('per chi, cosa e quando in un paragrafo solo', () {
      final t = componiTesti(
        progetto: 'Sito vetrina',
        cliente: 'Luca',
        fasi: ['Sviluppo', 'Consegna'],
        consegna: '1 settimana',
        benefit: ['Prezzo chiaro'],
      );
      expect(t.progetto, 'Per Luca: Sito vetrina. Consegna in 1 settimana.');
      expect(t.comeLavoro, ['Sviluppo', 'Consegna']);
      expect(t.benefit, ['Prezzo chiaro']);
    });

    test('senza cliente né consegna, e senza doppio punto', () {
      final t = componiTesti(
        progetto: 'Audiolibro «Il bosco».',
        fasi: const [],
        consegna: ' ',
        benefit: const [],
      );
      expect(t.progetto, 'Audiolibro «Il bosco».');
      expect(t.comeLavoro, isEmpty);
    });

    test('le righe vuote si scartano e gli spazi si tolgono', () {
      final t = componiTesti(
        progetto: '  Spot  ',
        fasi: ['  Registrazione ', '', '   '],
        consegna: '2 giorni',
        benefit: ['', ' Audio pulito '],
      );
      expect(t.progetto, 'Spot. Consegna in 2 giorni.');
      expect(t.comeLavoro, ['Registrazione']);
      expect(t.benefit, ['Audio pulito']);
    });

    test(
      'ogni tipo ha scelte rapide pronte (anche "A giornata" ripiega su Altro)',
      () {
        for (final t in [
          TipoLavoro.doppiaggio,
          TipoLavoro.codice,
          TipoLavoro.claude,
          TipoLavoro.altro,
          TipoLavoro.aGiornata,
        ]) {
          expect(fasiDi(t), isNotEmpty);
          expect(benefitDi(t), isNotEmpty);
        }
        expect(consegnePreset, contains('1 settimana'));
      },
    );
  });

  group('Conto del prezzo', () {
    test('1.000 → −30% → 700 €', () {
      final c = contoPrezzo(prezzoPieno: 1000, prezzoFinale: 700);
      expect(c.pieno, 1000);
      expect(c.totale, 700);
      expect(c.scontoImporto, 300);
      expect(c.scontoPercento, 30);
      expect(c.haSconto, isTrue);
    });

    test('senza prezzo pieno (o più basso del finale) non c\'è sconto', () {
      final a = contoPrezzo(prezzoPieno: 0, prezzoFinale: 450);
      expect(a.pieno, 450);
      expect(a.haSconto, isFalse);
      expect(a.scontoPercento, 0);

      final b = contoPrezzo(prezzoPieno: 300, prezzoFinale: 450);
      expect(b.pieno, 450);
      expect(b.haSconto, isFalse);
    });
  });

  group('Preventivo salvato', () {
    test('si rilegge uguale; stile sconosciuto → App', () {
      final p = Preventivo(
        id: 'p1',
        lavoroId: 'l1',
        cliente: 'Luca',
        progetto: 'Sito',
        fasi: const ['A', 'B'],
        consegna: '1 settimana',
        benefit: const ['X'],
        stile: StilePreventivo.gaming,
        prezzoPieno: 1000,
        prezzoFinale: 700,
        creatoIl: DateTime(2026, 11, 4),
      );
      final letto = Preventivo.fromMap('p1', p.toMap());
      expect(letto.cliente, 'Luca');
      expect(letto.fasi, ['A', 'B']);
      expect(letto.stile, StilePreventivo.gaming);
      expect(letto.prezzoFinale, 700);
      expect(letto.creatoIl, DateTime(2026, 11, 4));

      expect(StilePreventivo.da('boh'), StilePreventivo.app);
      expect(Preventivo.fromMap('x', const {}).fasi, isEmpty);
    });
  });
}
