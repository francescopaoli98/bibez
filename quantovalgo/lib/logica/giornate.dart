import '../modelli/giornata.dart';

/// Toglie l'ora: lascia solo il giorno.
DateTime soloData(DateTime d) => DateTime(d.year, d.month, d.day);

/// Giorni della settimana come in `DateTime`: lunedì = 1 … domenica = 7.
const lunediVenerdi = {1, 2, 3, 4, 5};
const lunediSabato = {1, 2, 3, 4, 5, 6};
const tuttiIGiorni = {1, 2, 3, 4, 5, 6, 7};

/// Massimo di giorni che uno schema può creare in una volta (circa un anno).
const maxGiorniSchema = 366;

/// I giorni scelti da uno schema: parte da [dal] e prende i giorni della
/// settimana indicati, fino a [numeroGiorni] giorni (di quelli scelti)
/// oppure fino al giorno [fino] compreso. Se danno entrambi, vince il primo
/// limite raggiunto. Senza nessun limite non crea nulla.
///
/// I giorni in [esclusi] (es. già registrati) si saltano e non contano nel
/// numero: con "10 giorni" ottieni 10 giorni nuovi.
///
/// Esempio: dal lunedì, lun–ven, 5 giorni → lun, mar, mer, gio, ven.
List<DateTime> giorniDelloSchema({
  required DateTime dal,
  required Set<int> giorniSettimana,
  int? numeroGiorni,
  DateTime? fino,
  Set<DateTime> esclusi = const {},
}) {
  if (giorniSettimana.isEmpty || (numeroGiorni == null && fino == null)) {
    return const [];
  }
  final tetto = (numeroGiorni ?? maxGiorniSchema).clamp(0, maxGiorniSchema);
  final ultimo = fino == null ? null : soloData(fino);

  final giorni = <DateTime>[];
  var giorno = soloData(dal);
  // Il limite sui giorni controllati evita cicli infiniti se i dati sono strani
  for (var controllati = 0; controllati < 4 * maxGiorniSchema; controllati++) {
    if (giorni.length >= tetto) break;
    if (ultimo != null && giorno.isAfter(ultimo)) break;
    if (giorniSettimana.contains(giorno.weekday) && !esclusi.contains(giorno)) {
      giorni.add(giorno);
    }
    giorno = DateTime(giorno.year, giorno.month, giorno.day + 1);
  }
  return giorni;
}

/// Una giornata è "fatta" (e il guadagno incassato) dal suo giorno in poi.
bool giornataFatta(Giornata giornata, DateTime adesso) =>
    !giornata.data.isAfter(soloData(adesso));

/// Totale in euro di un insieme di giornate.
double totaleGiornate(Iterable<Giornata> giornate) =>
    giornate.fold<double>(0, (somma, g) => somma + g.importo);

/// Quante giornate "intere" valgono queste: una mezza giornata conta 0,5.
double numeroGiornate(Iterable<Giornata> giornate) =>
    giornate.fold<double>(0, (somma, g) => somma + (g.mezza ? 0.5 : 1));

/// Importo di partenza di una mezza giornata: metà di quello intero
/// (arrotondato al centesimo).
double importoMezzaGiornata(double importoIntero) =>
    (importoIntero * 50).round() / 100;
