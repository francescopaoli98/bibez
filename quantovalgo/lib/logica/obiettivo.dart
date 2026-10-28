import 'saldo.dart';

/// Obiettivo mensile, pareggio e tariffa minima di un mese.
///
/// L'obiettivo è **netto**: quello che resta dopo le tasse.
/// - **Netto dopo tasse** = saldo × (1 − tasse%) se il saldo è positivo
///   (se è negativo non ci sono tasse da pagare).
/// - **Avanzamento** = netto dopo tasse ÷ obiettivo.
/// - **Punto di pareggio** = i costi del mese: sotto, sei in negativo.
/// - **Tariffa minima oraria**: per chiudere il mese in obiettivo servono
///   obiettivo ÷ (1 − tasse%) di saldo, più i costi da coprire; diviso le ore
///   registrate nel mese dà quanto devi guadagnare ogni ora.
class PianoObiettivo {
  const PianoObiettivo({
    required this.saldoMese,
    required this.oreMese,
    required this.tasse,
    required this.obiettivoNetto,
  });

  final SaldoMese saldoMese;

  /// Ore registrate (cronometro e a mano) nel mese.
  final double oreMese;

  /// Tasse in %, tenute tra 0 e 99 per non dividere per zero.
  final double tasse;
  final double obiettivoNetto;

  double get _quotaNetta => 1 - tasse.clamp(0, 99) / 100;

  bool get haObiettivo => obiettivoNetto > 0;

  double get saldo => saldoMese.saldo;

  /// Tasse da mettere da parte sul saldo del mese (0 se il saldo non è positivo).
  double get importoTasse => saldo > 0 ? saldo * (1 - _quotaNetta) : 0;

  double get nettoDopoTasse => saldo - importoTasse;

  /// Da 0 a oltre 1 (1 = obiettivo raggiunto); vuoto senza obiettivo.
  double? get avanzamento => haObiettivo
      ? (nettoDopoTasse / obiettivoNetto).clamp(0, double.infinity)
      : null;

  /// Costi del mese: quanto devi incassare per non andare in negativo.
  double get pareggio => saldoMese.costi;

  /// Quanto manca per il pareggio (0 se l'hai già superato).
  double get manca =>
      pareggio > saldoMese.incassato ? pareggio - saldoMese.incassato : 0;

  /// Saldo che serve perché, tolte le tasse, restino l'obiettivo.
  double get saldoNecessario => obiettivoNetto / _quotaNetta;

  /// Incassi che servono: il saldo necessario più i costi da coprire.
  double get incassoNecessario => saldoNecessario + pareggio;

  /// Vuota se manca l'obiettivo o non ci sono ore registrate nel mese.
  double? get tariffaMinima =>
      haObiettivo && oreMese > 0 ? incassoNecessario / oreMese : null;
}
