/// I numeri di un mese per la Home.
///
/// - **Incassato**: progetti segnati incassati in quel mese + giornate del
///   negozio fatte in quel mese.
/// - **Costi**: costi condivisi del mese (abbonamenti, una tantum, fissi) più i
///   costi diretti dei progetti incassati nel mese.
/// - **Saldo** = incassato − costi (in positivo o in negativo).
/// - **Guadagno all'ora**: utile dei progetti incassati nel mese ÷ le loro ore
///   (le giornate non hanno ore, quindi non contano qui).
/// - **Regalato**: sconti dei progetti creati nel mese (prezzo pieno − applicato).
class SaldoMese {
  const SaldoMese({
    required this.incassato,
    required this.costiCondivisi,
    required this.costiDiretti,
    required this.utileProgetti,
    required this.oreProgetti,
    required this.regalato,
  });

  final double incassato;
  final double costiCondivisi;
  final double costiDiretti;

  /// Utile (ricavi − costi diretti) dei progetti con ore incassati nel mese.
  final double utileProgetti;
  final double oreProgetti;
  final double regalato;

  double get costi => costiCondivisi + costiDiretti;

  double get saldo => incassato - costi;

  /// Nullo se nei progetti incassati non ci sono ore registrate.
  double? get guadagnoOra =>
      oreProgetti > 0 ? utileProgetti / oreProgetti : null;
}
