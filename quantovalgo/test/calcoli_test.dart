import 'package:flutter_test/flutter_test.dart';
import 'package:quantovalgo/logica/calcoli.dart';
import 'package:quantovalgo/logica/formato.dart';
import 'package:quantovalgo/modelli/sottoprogetto.dart';
import 'package:quantovalgo/modelli/tipi.dart';

Sottoprogetto sotto(double ricavo, double costi, double ore) => Sottoprogetto(
  id: 'x',
  lavoroId: 'l',
  nome: 'n',
  ricavo: ricavo,
  costiDiretti: costi,
  ore: ore,
  creatoIl: DateTime(2026),
);

void main() {
  group('Prezzo suggerito (numeri del brief)', () {
    const mercato = Forbice(80, 120);

    test('mercato 80-120, livello 3, amico −30% → 56-84 €', () {
      final p = prezzoSuggerito(
        mercato: mercato,
        livello: 3,
        relazione: Relazione.amico,
      );
      expect(p.minimo, closeTo(56, 1e-9));
      expect(p.massimo, closeTo(84, 1e-9));
    });

    test('livello 1 = −20%, livello 5 = +20%', () {
      final basso = prezzoSuggerito(
        mercato: mercato,
        livello: 1,
        relazione: Relazione.nuovo,
      );
      final alto = prezzoSuggerito(
        mercato: mercato,
        livello: 5,
        relazione: Relazione.nuovo,
      );
      expect(basso.minimo, closeTo(64, 1e-9));
      expect(alto.massimo, closeTo(144, 1e-9));
    });

    test('sconti di partenza: 0, 10, 30, 50 %', () {
      const p = ParametriPrezzo.predefiniti;
      expect([for (final r in Relazione.values) p.sconto(r)], [0, 10, 30, 50]);
    });

    test('prezzo pieno 1.000 € con amico → 700 €, regalati 300 €', () {
      final finale = prezzoConSconto(1000, Relazione.amico);
      expect(finale, closeTo(700, 1e-9));
      expect(scontoRegalato(1000, finale), closeTo(300, 1e-9));
    });

    test('lo sconto regalato non è mai negativo', () {
      expect(scontoRegalato(100, 150), 0);
    });
  });

  group('Riepilogo progetto (numeri del brief)', () {
    test('340 + 80 + 100 = +520 €, 20 h → 26 €/h', () {
      final r = riepilogo([
        sotto(400, 60, 9), // Registrazione: +340
        sotto(120, 40, 4), // Revisione: +80
        sotto(180, 80, 7), // Montaggio: +100
      ]);
      expect(r.ricavi, 700);
      expect(r.costi, 180);
      expect(r.utile, 520);
      expect(r.ore, 20);
      expect(r.guadagnoOra, 26);
    });

    test('senza ore il guadagno all\'ora non c\'è', () {
      expect(riepilogo([sotto(100, 0, 0)]).guadagnoOra, isNull);
      expect(riepilogo(const []).utile, 0);
    });

    test('utile sottoprogetto = ricavo − costi', () {
      expect(sotto(400, 60, 9).utile, 340);
    });
  });

  group('Formato', () {
    test('euro all\'italiana', () {
      expect(euro(1240), '1.240 €');
      expect(euro(0), '0 €');
      expect(euro(12.5), '12,50 €');
      expect(euro(-35), '−35 €');
      expect(euro(520, conSegno: true), '+520 €');
      expect(euro(-35, conSegno: true), '−35 €');
      expect(euro(1234567), '1.234.567 €');
    });

    test('forbice e ore', () {
      expect(euroForbice(55.6, 84.2), '56 – 84 €');
      expect(ore(9), '9 h');
      expect(ore(7.5), '7,5 h');
    });

    test('lettura dei numeri scritti a mano', () {
      expect(leggiNumero('12,5'), 12.5);
      expect(leggiNumero(' 1 000 € '), 1000);
      expect(leggiNumero('abc'), isNull);
      expect(leggiNumero(''), isNull);
      expect(leggiNumero('-5'), isNull);
      expect(numeroPerCampo(700), '700');
      expect(numeroPerCampo(12.5), '12,5');
    });
  });
}
