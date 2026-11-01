import 'package:flutter_test/flutter_test.dart';
import 'package:quantovalgo/logica/prezzo_da_ore.dart';
import 'package:quantovalgo/modelli/impostazioni.dart';

void main() {
  // Il caso vero: 5 h 45 per amici (−30%), 20 km, 25 € l'ora, 0,30 € al km
  const amici = PrezzoDaOre(
    minuti: 345,
    tariffaOraria: 25,
    scontoPercento: 30,
    km: 20,
    rimborsoKm: 0.30,
  );

  test('il conto del caso degli amici: tempo, sconto, trasferta', () {
    expect(amici.ore, 5.75);
    expect(amici.tempo, closeTo(143.75, 0.001));
    expect(amici.sconto, closeTo(43.125, 0.001));
    expect(amici.trasferta, closeTo(6, 0.001));
    expect(amici.totale, closeTo(106.625, 0.001));
  });

  test('si chiede una cifra tonda: 105 €', () {
    expect(amici.consigliato, 105);
    expect(amici.prezzoPieno, closeTo(149.75, 0.001));
  });

  test('le righe del conto sommano esattamente al prezzo', () {
    final r = amici.righe(105);
    expect(r.tempo, 144);
    expect(r.sconto, 43);
    expect(r.trasferta, 6);
    expect(r.arrotondamento, -2);
    expect(r.tempo - r.sconto + r.trasferta + r.arrotondamento, 105);

    // Anche con una cifra scelta a mano
    final mano = amici.righe(120);
    expect(
      mano.tempo - mano.sconto + mano.trasferta + mano.arrotondamento,
      120,
    );
  });

  test('a te restano circa 17 € all\'ora (la trasferta non conta)', () {
    expect(amici.restaAllOra(105)!, closeTo(17.22, 0.01));
  });

  test('lo sconto vale solo sul tempo, non sulla trasferta', () {
    const senza = PrezzoDaOre(
      minuti: 60,
      tariffaOraria: 25,
      scontoPercento: 50,
      km: 10,
      rimborsoKm: 0.3,
    );
    expect(senza.tempo, 25);
    expect(senza.sconto, 12.5);
    expect(senza.trasferta, 3);
    expect(senza.totale, 15.5);
  });

  test('senza sconto né trasferta: ore × tariffa', () {
    const base = PrezzoDaOre(minuti: 120, tariffaOraria: 25, scontoPercento: 0);
    expect(base.totale, 50);
    expect(base.consigliato, 50);
    expect(base.prezzoPieno, 50);
  });

  test('arrotonda ai 5 € più vicini, con un minimo di 5 €', () {
    PrezzoDaOre t(int minuti) =>
        PrezzoDaOre(minuti: minuti, tariffaOraria: 25, scontoPercento: 0);
    expect(t(15).totale, 6.25);
    expect(t(15).consigliato, 5);
    expect(t(30).totale, 12.5);
    expect(t(30).consigliato, 15); // 12,5 arrotonda per eccesso a 15
    expect(t(45).consigliato, 20); // 18,75
    expect(
      const PrezzoDaOre(
        minuti: 1,
        tariffaOraria: 25,
        scontoPercento: 0,
      ).consigliato,
      5,
    );
  });

  test('senza tempo non si può dire quanto resta all\'ora', () {
    const zero = PrezzoDaOre(minuti: 0, tariffaOraria: 25, scontoPercento: 0);
    expect(zero.consigliato, 0);
    expect(zero.restaAllOra(100), isNull);
  });

  test(
    'Impostazioni: tariffa 25 € e 0,30 € al km di partenza, e si salvano',
    () {
      const i = Impostazioni();
      expect(i.tariffaOraria, 25);
      expect(i.rimborsoKm, 0.30);

      final cambiata = i.copyWith(tariffaOraria: 30, rimborsoKm: 0.4);
      final letta = Impostazioni.fromMap(cambiata.toMap());
      expect(letta.tariffaOraria, 30);
      expect(letta.rimborsoKm, 0.4);

      // Dati vecchi senza questi campi
      final vecchia = Impostazioni.fromMap({'promemoria': true});
      expect(vecchia.tariffaOraria, 25);
      expect(vecchia.rimborsoKm, 0.30);
    },
  );
}
