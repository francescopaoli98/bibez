import 'package:flutter_test/flutter_test.dart';
import 'package:quantovalgo/logica/formato.dart';
import 'package:quantovalgo/logica/ore.dart';
import 'package:quantovalgo/modelli/sessione_ore.dart';

SessioneOre sessione(DateTime inizio, int minuti, {bool inCorso = false}) =>
    SessioneOre(
      id: 'x',
      sottoprogettoId: 's',
      lavoroId: 'l',
      inizio: inizio,
      fine: inCorso ? null : inizio.add(Duration(minutes: minuti)),
      minuti: minuti,
      creatoIl: DateTime(2026),
    );

void main() {
  group('Minuti', () {
    final inizio = DateTime(2026, 10, 28, 10);

    test('minuti tra due momenti, arrotondati', () {
      expect(
        minutiTra(inizio, inizio.add(const Duration(hours: 1, minutes: 5))),
        65,
      );
      expect(minutiTra(inizio, inizio.add(const Duration(seconds: 89))), 1);
      expect(minutiTra(inizio, inizio.add(const Duration(seconds: 90))), 2);
      expect(minutiTra(inizio, inizio.add(const Duration(seconds: 29))), 0);
      expect(minutiTra(inizio, inizio.subtract(const Duration(minutes: 5))), 0);
    });

    test('sotto il minuto la sessione è troppo breve', () {
      expect(sessioneTroppoBreve(0), isTrue);
      expect(sessioneTroppoBreve(1), isFalse);
    });

    test('9 + 4 + 7 ore del brief = 20 h', () {
      expect(oreDaMinuti(9 * 60 + 4 * 60 + 7 * 60), 20);
    });
  });

  group('Totali delle sessioni', () {
    final ottobre = DateTime(2026, 10, 5, 9);
    final sessioni = [
      sessione(ottobre, 60),
      sessione(DateTime(2026, 10, 31, 23), 30), // conta il giorno di inizio
      sessione(DateTime(2026, 11, 2, 9), 120),
      sessione(
        DateTime(2026, 10, 28, 8),
        0,
        inCorso: true,
      ), // cronometro acceso
    ];

    test('il cronometro acceso non conta finché non lo fermi', () {
      expect(minutiConclusi(sessioni), 210);
    });

    test('minuti di un mese', () {
      expect(minutiDelMese(sessioni, DateTime(2026, 10)), 90);
      expect(minutiDelMese(sessioni, DateTime(2026, 11, 20)), 120);
      expect(minutiDelMese(sessioni, DateTime(2026, 12)), 0);
    });

    test('si salva e si legge, anche il cronometro acceso', () {
      final acceso = sessione(ottobre, 0, inCorso: true);
      final letto = SessioneOre.fromMap('a', acceso.toMap());
      expect(letto.inCorso, isTrue);
      expect(letto.minuti, 0);
      expect(letto.manuale, isFalse);
      final finito = SessioneOre.fromMap('b', sessione(ottobre, 45).toMap());
      expect(finito.inCorso, isFalse);
      expect(finito.minuti, 45);
    });
  });

  group('Formato', () {
    test('durata', () {
      expect(durata(0), '0 min');
      expect(durata(45), '45 min');
      expect(durata(60), '1 h');
      expect(durata(90), '1 h 30 min');
      expect(durata(9 * 60), '9 h');
      expect(durata(-5), '0 min');
    });

    test('cronometro e ora', () {
      expect(cronometro(Duration.zero), '00:00:00');
      expect(
        cronometro(const Duration(hours: 1, minutes: 5, seconds: 9)),
        '01:05:09',
      );
      expect(cronometro(const Duration(hours: 26)), '26:00:00');
      expect(cronometro(const Duration(seconds: -3)), '00:00:00');
      expect(oraDelGiorno(DateTime(2026, 10, 28, 9, 5)), '09:05');
    });
  });
}
