import '../modelli/sottoprogetto.dart';
import '../modelli/tipi.dart';

/// Forbice di prezzo: minimo e massimo, in euro.
class Forbice {
  const Forbice(this.minimo, this.massimo);

  final double minimo;
  final double massimo;
}

/// Valori modificabili che entrano nel calcolo del prezzo.
/// Ora sono quelli di partenza; dal passo 8 si cambiano in Impostazioni.
class ParametriPrezzo {
  const ParametriPrezzo({
    required this.scontoRelazione,
    required this.correzioneLivello,
  });

  /// Sconto in % per relazione.
  final Map<Relazione, int> scontoRelazione;

  /// Correzione in % del prezzo per livello di competenza (1-5).
  final Map<int, int> correzioneLivello;

  static const predefiniti = ParametriPrezzo(
    scontoRelazione: {
      Relazione.nuovo: 0,
      Relazione.consigliato: 10,
      Relazione.amico: 30,
      Relazione.famiglia: 50,
    },
    // Livello 1 = −20%, 3 = 0%, 5 = +20%; il 2 e il 4 a metà strada.
    correzioneLivello: {1: -20, 2: -10, 3: 0, 4: 10, 5: 20},
  );

  int sconto(Relazione relazione) => scontoRelazione[relazione] ?? 0;
  int correzione(int livello) => correzioneLivello[livello] ?? 0;
}

/// Prezzo suggerito = forbice di mercato × fattore competenza × (1 − sconto).
/// Esempio: mercato 80-120 €, livello 3, amico −30% → 56-84 €.
Forbice prezzoSuggerito({
  required Forbice mercato,
  required int livello,
  required Relazione relazione,
  ParametriPrezzo parametri = ParametriPrezzo.predefiniti,
}) {
  final fattore =
      (1 + parametri.correzione(livello) / 100) *
      (1 - parametri.sconto(relazione) / 100);
  return Forbice(mercato.minimo * fattore, mercato.massimo * fattore);
}

/// Prezzo pieno meno lo sconto della relazione.
double prezzoConSconto(
  double prezzoPieno,
  Relazione relazione, [
  ParametriPrezzo parametri = ParametriPrezzo.predefiniti,
]) => prezzoPieno * (1 - parametri.sconto(relazione) / 100);

/// Sconto regalato = prezzo pieno − prezzo finale (mai negativo).
double scontoRegalato(double prezzoPieno, double prezzoFinale) =>
    prezzoPieno > prezzoFinale ? prezzoPieno - prezzoFinale : 0;

/// Numeri di un progetto, sommando i suoi sottoprogetti.
class RiepilogoLavoro {
  const RiepilogoLavoro({
    required this.ricavi,
    required this.costi,
    required this.ore,
  });

  final double ricavi;
  final double costi;
  final double ore;

  /// Utile progetto = somma degli utili dei sottoprogetti.
  double get utile => ricavi - costi;

  /// Guadagno all'ora = utile ÷ ore (nullo se non ci sono ore).
  double? get guadagnoOra => ore > 0 ? utile / ore : null;
}

RiepilogoLavoro riepilogo(Iterable<Sottoprogetto> sottoprogetti) {
  var ricavi = 0.0, costi = 0.0, ore = 0.0;
  for (final s in sottoprogetti) {
    ricavi += s.ricavo;
    costi += s.costiDiretti;
    ore += s.ore;
  }
  return RiepilogoLavoro(ricavi: ricavi, costi: costi, ore: ore);
}
