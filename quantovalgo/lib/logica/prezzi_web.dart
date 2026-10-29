import '../modelli/tipi.dart';
import 'calcoli.dart';

/// Estrazione di una forbice di prezzo dai testi trovati sul web.
///
/// Regole (spiegate anche nel README):
/// 1. si prendono gli importi in euro scritti nei testi ("80 €", "€80",
///    "da 80 a 120 euro", "1.200 €");
/// 2. si scartano quelli fuori scala per quel tipo di lavoro e quelli che non
///    sono un prezzo a lavoro (all'ora, al mese, all'anno, al minuto);
/// 3. servono almeno [minImporti] importi da almeno [minFonti] siti diversi,
///    altrimenti la ricerca "non è affidabile";
/// 4. la forbice è dal 25° al 75° percentile (scarta gli estremi), arrotondata
///    a 5 €; se resta troppo larga (più di 8 volte) non è affidabile.

/// Importi plausibili per un tipo di lavoro: fuori da qui il numero si scarta.
class LimitiImporto {
  const LimitiImporto(this.minimo, this.massimo);
  final double minimo;
  final double massimo;
}

const limitiPerTipo = {
  TipoLavoro.doppiaggio: LimitiImporto(20, 3000),
  TipoLavoro.codice: LimitiImporto(30, 10000),
  TipoLavoro.claude: LimitiImporto(10, 3000),
  // "Altro" è per servizi di ogni genere (assistenza, consulenze...)
  TipoLavoro.altro: LimitiImporto(10, 5000),
};

/// Ricerca web possibile per ogni tipo tranne "A giornata" (guadagno fisso).
bool tipoCercabile(TipoLavoro tipo) => limitiPerTipo.containsKey(tipo);

const minImporti = 5;
const minFonti = 2;
const _larghezzaMassima = 8.0;

/// Numero scritto all'italiana o all'inglese: `1.200`, `1.200,50`, `25,5`, `25.50`.
double? _leggiImporto(String testo) {
  var t = testo.replaceAll(RegExp(r'\s'), '');
  if (t.isEmpty) return null;
  if (RegExp(r'^\d{1,3}(,\d{3})+(\.\d+)?$').hasMatch(t)) {
    t = t.replaceAll(',', ''); // all'inglese: 15,000 → 15000
  } else if (t.contains(',')) {
    t = t.replaceAll('.', '').replaceAll(',', '.');
  } else if (RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(t)) {
    t = t.replaceAll('.', ''); // 1.200 → 1200
  }
  return double.tryParse(t);
}

// Un numero: `1.200`, `1 200,50` (migliaia a gruppi di 3) oppure `80`, `25,5`, `25.50`.
// Gli spazi contano solo prima di tre cifre, così "10 80 €" non diventa 1080.
const _num =
    r'(?:\d{1,3}(?:[. ]\d{3})+(?:,\d{1,2})?|\d{1,3}(?:,\d{3})+(?:\.\d{1,2})?|\d+(?:[.,]\d{1,2})?)';

// "80 €", "80-120 €", "da 80 a 120 euro", "80 euro"
final _prima = RegExp(
  '($_num)(?:\\s*(?:-|–|—|a)\\s*($_num))?\\s*(?:€|euro\\b|eur\\b)',
  caseSensitive: false,
);

// "€80", "€ 80 - € 120"
final _dopo = RegExp(
  '(?:€|\\beur\\b)\\s*($_num)(?:\\s*(?:-|–|—)\\s*€?\\s*($_num))?',
  caseSensitive: false,
);

/// Parole che, subito dopo un importo, dicono che non è un prezzo a lavoro.
const _nonAProgetto = [
  '/h',
  '/hr',
  '/ora',
  "all'ora",
  "l'ora",
  'per ora',
  'orari',
  'hour',
  '/mese',
  'al mese',
  'mensil',
  'month',
  '/anno',
  "all'anno",
  'annu',
  'year',
  '/min',
  'al minuto',
  'per minuto',
  'per minute',
];

/// Tutti gli importi in euro scritti in [testo] (anche i due estremi di un
/// intervallo), esclusi quelli all'ora, al mese, all'anno o al minuto.
List<double> importiInEuro(String testo) {
  final trovati = <double>[];
  // Pezzi di testo già letti: una stessa frase non conta due volte
  final letti = <({int da, int a})>[];
  for (final regola in [_prima, _dopo]) {
    for (final m in regola.allMatches(testo)) {
      if (letti.any((l) => m.start < l.a && m.end > l.da)) continue;
      final fine = (m.end + 16).clamp(0, testo.length);
      final dopo = testo.substring(m.end, fine).toLowerCase();
      if (_nonAProgetto.any(dopo.contains)) continue;
      letti.add((da: m.start, a: m.end));
      for (final i in [1, 2]) {
        final gruppo = m.group(i);
        if (gruppo == null) continue;
        final valore = _leggiImporto(gruppo);
        if (valore != null && valore > 0) trovati.add(valore);
      }
    }
  }
  return trovati;
}

/// Forbice trovata sul web, con i siti da cui arriva.
class ForbiceTrovata {
  const ForbiceTrovata({
    required this.forbice,
    required this.fonti,
    required this.importi,
    this.domanda = '',
  });

  final Forbice forbice;
  final List<String> fonti;

  /// Quanti importi sono stati usati.
  final int importi;

  /// La domanda mandata al web (vuota se non si sa).
  final String domanda;
}

/// Percentile con interpolazione lineare su una lista già ordinata.
double _percentile(List<double> ordinati, double p) {
  final posizione = (ordinati.length - 1) * p;
  final sotto = posizione.floor();
  final sopra = posizione.ceil();
  return ordinati[sotto] +
      (ordinati[sopra] - ordinati[sotto]) * (posizione - sotto);
}

/// Arrotonda al multiplo di 5 più vicino.
double _a5(double v) => (v / 5).round() * 5.0;

/// Calcola la forbice da `sito → importi trovati`. Null se i dati non bastano.
ForbiceTrovata? forbiceDaFonti(
  Map<String, List<double>> importiPerSito,
  LimitiImporto limiti,
) {
  final tenuti = <String, List<double>>{};
  for (final e in importiPerSito.entries) {
    final buoni = [
      for (final v in e.value)
        if (v >= limiti.minimo && v <= limiti.massimo) v,
    ];
    if (buoni.isNotEmpty) tenuti[e.key] = buoni;
  }
  final tutti = [for (final v in tenuti.values) ...v]..sort();
  if (tutti.length < minImporti || tenuti.length < minFonti) return null;

  final minimo = _a5(_percentile(tutti, 0.25));
  final massimo = _a5(_percentile(tutti, 0.75));
  if (minimo <= 0 || massimo <= minimo) return null;
  if (massimo / minimo > _larghezzaMassima) return null;

  return ForbiceTrovata(
    forbice: Forbice(minimo, massimo),
    fonti: tenuti.keys.toList()..sort(),
    importi: tutti.length,
  );
}

/// Il sito di un indirizzo, senza "www.": `https://www.esempio.it/a` → `esempio.it`.
String sitoDi(String indirizzo) {
  final host = Uri.tryParse(indirizzo)?.host ?? '';
  final pulito = host.startsWith('www.') ? host.substring(4) : host;
  return pulito.isEmpty ? indirizzo : pulito;
}

/// Cosa si cerca di partenza per ogni tipo (modificabile da chi usa l'app).
/// "Altro" non ha una domanda di partenza: la scrive l'utente.
const domandaPredefinita = {
  TipoLavoro.doppiaggio: 'doppiatore professionista audiolibro spot radio voce',
  TipoLavoro.codice: 'sito web vetrina freelance a progetto',
  TipoLavoro.claude: "chatbot o automazione con intelligenza artificiale per una piccola impresa",
};

/// Idee da toccare sotto il campo di ricerca, per tipo.
const suggerimentiPerTipo = {
  TipoLavoro.doppiaggio: [
    'audiolibro prezzo per ora di registrato',
    'doppiaggio spot radio locale',
    'voce per video aziendale',
  ],
  TipoLavoro.codice: [
    'sito web vetrina freelance',
    'negozio online e-commerce piccolo',
    'app mobile semplice freelance',
  ],
  TipoLavoro.claude: [
    'chatbot per piccola impresa',
    "automazione con intelligenza artificiale",
  ],
  // Provate dal vivo: danno prezzi del servizio a intervento (40-50 € e 20-35 €)
  TipoLavoro.altro: [
    'assistenza informatica privati costo intervento a domicilio',
    'servizio installazione e configurazione tablet costo',
  ],
};

/// Prepara la domanda da mandare al web: aggiunge da sola le parole che fanno
/// uscire prezzi italiani in euro (Italia, prezzo, euro) se mancano.
///
/// `assistenza configurazione smartphone` →
/// `assistenza configurazione smartphone Italia prezzo euro`
String costruisciQuery(String domanda) {
  var q = domanda.trim().replaceAll(RegExp(r'\s+'), ' ');
  final minuscola = q.toLowerCase();
  bool ha(List<String> parole) => parole.any(minuscola.contains);
  if (!ha(['italia', 'italian'])) q += ' Italia';
  if (!ha(['prezzo', 'prezzi', 'costo', 'costi', 'costa', 'tariff'])) {
    q += ' prezzo';
  }
  if (!ha(['euro', '€'])) q += ' euro';
  return q;
}
