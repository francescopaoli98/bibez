import '../modelli/lavoro.dart';
import '../modelli/tipi.dart';
import 'calcoli.dart';

/// Autoapprendimento dei prezzi, gratis e senza AI.
///
/// Per ogni lavoro **incassato** di un tipo si confronta il prezzo che l'app
/// avrebbe suggerito (centro della forbice di mercato, con livello e relazione
/// di quel lavoro) con quanto hai davvero incassato. Lo scarto medio degli
/// ultimi [lavoriConsiderati] sposta la forbice di quel tipo, al massimo di
/// ±[correzioneMassima]. Se lo scarto medio supera [sogliaAvviso] compare un
/// avviso in Home.
///
/// Lo scarto si misura sulla forbice **di partenza** (quella di mercato, senza
/// correzione): così la correzione non si mangia da sola e non oscilla.
const lavoriConsiderati = 5;
const lavoriMinimi = 3;
const correzioneMassima = 0.15;
const sogliaAvviso = 0.20;

class CorrezioneTipo {
  const CorrezioneTipo({
    required this.tipo,
    required this.lavori,
    required this.scartoMedio,
  });

  final TipoLavoro tipo;

  /// Quanti lavori sono stati contati (da 3 a 5).
  final int lavori;

  /// Scarto medio tra incassato e suggerito: 0,27 = incassi il 27% in più.
  final double scartoMedio;

  /// Quanto spostare la forbice: lo scarto, ma entro ±15%.
  double get correzione =>
      scartoMedio.clamp(-correzioneMassima, correzioneMassima);

  /// Scarto così grande che conviene guardare la forbice di mercato.
  bool get daAvvisare => scartoMedio.abs() > sogliaAvviso;
}

/// Calcola la correzione di un tipo, o null se i lavori incassati non bastano.
/// [incassati] sono già i lavori incassati di quel tipo; [importo] dice quanto
/// è stato incassato per ognuno.
CorrezioneTipo? calcolaCorrezione({
  required TipoLavoro tipo,
  required Forbice mercato,
  required Iterable<Lavoro> incassati,
  required double Function(Lavoro) importo,
  required ParametriPrezzo parametri,
}) {
  final recenti = incassati.toList()
    ..sort(
      (a, b) =>
          (b.dataIncasso ?? b.creatoIl).compareTo(a.dataIncasso ?? a.creatoIl),
    );

  final scarti = <double>[];
  for (final l in recenti.take(lavoriConsiderati)) {
    final suggerito = prezzoSuggerito(
      mercato: mercato,
      livello: l.livello,
      relazione: l.relazione,
      parametri: parametri,
    );
    final centro = (suggerito.minimo + suggerito.massimo) / 2;
    final incassato = importo(l);
    if (centro <= 0 || incassato <= 0) continue;
    scarti.add(incassato / centro - 1);
  }
  if (scarti.length < lavoriMinimi) return null;

  return CorrezioneTipo(
    tipo: tipo,
    lavori: scarti.length,
    scartoMedio: scarti.fold<double>(0, (a, b) => a + b) / scarti.length,
  );
}

/// La forbice di mercato spostata della correzione.
Forbice forbiceCorretta(Forbice mercato, CorrezioneTipo? correzione) {
  final f = 1 + (correzione?.correzione ?? 0);
  return Forbice(mercato.minimo * f, mercato.massimo * f);
}
