/// Quanto chiedere partendo dal tempo che ci metti.
///
/// - **Tuo tempo** = ore × tariffa oraria.
/// - **Sconto** = una percentuale (quella della relazione) sul **solo tempo**.
/// - **Trasferta** = km (andata e ritorno) × rimborso al km, **senza sconto**:
///   è una spesa vera, non un regalo.
/// - **Consigliato** = il totale arrotondato ai 5 € più vicini.
class PrezzoDaOre {
  const PrezzoDaOre({
    required this.minuti,
    required this.tariffaOraria,
    required this.scontoPercento,
    this.km = 0,
    this.rimborsoKm = 0,
  });

  final int minuti;
  final double tariffaOraria;

  /// Sconto in % sul tempo (0-100).
  final int scontoPercento;
  final double km;
  final double rimborsoKm;

  double get ore => minuti / 60;

  /// Il tuo tempo, senza sconto.
  double get tempo => ore * tariffaOraria;

  /// Quanto togli al tempo per lo sconto.
  double get sconto => tempo * scontoPercento / 100;

  /// La spesa dello spostamento.
  double get trasferta => km * rimborsoKm;

  /// Il conto esatto, prima di arrotondare.
  double get totale => tempo - sconto + trasferta;

  /// Quanto chiedere: il totale al multiplo di 5 € più vicino (mai sotto 5 €
  /// se c'è qualcosa da pagare).
  double get consigliato {
    if (totale <= 0) return 0;
    final arrotondato = (totale / 5).round() * 5.0;
    return arrotondato < 5 ? 5 : arrotondato;
  }

  /// Prezzo senza sconto: tempo + trasferta (serve a contare gli sconti regalati).
  double get prezzoPieno => tempo + trasferta;

  /// Le righe del conto, in euro interi, che sommate danno **esattamente**
  /// [prezzo] (la differenza finisce in `arrotondamento`).
  RigheConto righe(double prezzo) {
    final t = tempo.roundToDouble();
    final s = sconto.roundToDouble();
    final tr = trasferta.roundToDouble();
    return RigheConto(
      tempo: t,
      sconto: s,
      trasferta: tr,
      arrotondamento: prezzo - (t - s + tr),
    );
  }

  /// Quanto ti resta all'ora, tolta la trasferta, se chiedi [prezzo].
  double? restaAllOra(double prezzo) =>
      minuti > 0 ? (prezzo - trasferta) / ore : null;
}

/// Quattro righe che sommate fanno il prezzo: tempo − sconto + trasferta ± arrotondamento.
class RigheConto {
  const RigheConto({
    required this.tempo,
    required this.sconto,
    required this.trasferta,
    required this.arrotondamento,
  });

  final double tempo;
  final double sconto;
  final double trasferta;
  final double arrotondamento;
}
