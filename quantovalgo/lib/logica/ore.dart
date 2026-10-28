import '../modelli/sessione_ore.dart';
import 'mesi.dart';

/// Minuti tra due momenti, arrotondati al minuto più vicino (mai negativi).
int minutiTra(DateTime inizio, DateTime fine) {
  final secondi = fine.difference(inizio).inSeconds;
  return secondi <= 0 ? 0 : (secondi / 60).round();
}

/// Un cronometro fermato dopo meno di mezzo minuto (0 minuti) non si salva.
bool sessioneTroppoBreve(int minuti) => minuti < 1;

/// Massimo di una sessione inserita a mano: un giorno intero.
const maxMinutiSessione = 24 * 60;

/// Ore (decimali) di un certo numero di minuti.
double oreDaMinuti(num minuti) => minuti / 60;

/// Minuti totali delle sessioni già concluse (il cronometro acceso non conta
/// finché non lo fermi).
int minutiConclusi(Iterable<SessioneOre> sessioni) => sessioni
    .where((s) => !s.inCorso)
    .fold<int>(0, (somma, s) => somma + s.minuti);

/// Minuti delle sessioni concluse che cadono in un certo mese
/// (conta il giorno di inizio).
int minutiDelMese(Iterable<SessioneOre> sessioni, DateTime mese) {
  final cercato = primoDelMese(mese);
  return minutiConclusi(
    sessioni.where((s) => primoDelMese(s.inizio) == cercato),
  );
}
