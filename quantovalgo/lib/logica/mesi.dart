// Funzioni sui mesi. Un mese si rappresenta con il suo primo giorno.

DateTime primoDelMese(DateTime data) => DateTime(data.year, data.month);

DateTime meseSuccessivo(DateTime mese) => DateTime(mese.year, mese.month + 1);

DateTime mesePrecedente(DateTime mese) => DateTime(mese.year, mese.month - 1);

/// Quanti mesi passano da [da] ad [a] (negativo se [a] viene prima).
int differenzaMesi(DateTime da, DateTime a) =>
    (a.year - da.year) * 12 + (a.month - da.month);

const _nomiMesi = [
  'gennaio',
  'febbraio',
  'marzo',
  'aprile',
  'maggio',
  'giugno',
  'luglio',
  'agosto',
  'settembre',
  'ottobre',
  'novembre',
  'dicembre',
];

/// `ottobre`
String nomeMese(DateTime data) => _nomiMesi[data.month - 1];

/// `ottobre 2026`
String nomeMeseAnno(DateTime data) => '${nomeMese(data)} ${data.year}';

const _nomiGiorni = [
  'lunedì',
  'martedì',
  'mercoledì',
  'giovedì',
  'venerdì',
  'sabato',
  'domenica',
];

/// `mercoledì` (lunedì = 1 … domenica = 7, come `DateTime.weekday`)
String nomeGiorno(int giornoSettimana) => _nomiGiorni[giornoSettimana - 1];

/// `mercoledì 28 ottobre`
String descrizioneGiorno(DateTime data) =>
    '${nomeGiorno(data.weekday)} ${data.day} ${nomeMese(data)}';
