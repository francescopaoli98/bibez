import '../modelli/tipi.dart';
import 'calcoli.dart';

/// Scelte rapide per costruire un preventivo: fasi, consegne e vantaggi tra
/// cui toccare, diversi per tipo di lavoro. Tutto offline e gratis: il testo
/// si compone da modelli, senza AI.

const fasiPerTipo = {
  TipoLavoro.doppiaggio: [
    'Ascolto il testo e preparo la voce',
    'Registrazione',
    'Pulizia e montaggio dell\'audio',
    'Consegna dei file',
  ],
  TipoLavoro.codice: [
    'Capiamo insieme cosa ti serve',
    'Sviluppo',
    'Prove e correzioni',
    'Messa online e consegna',
  ],
  TipoLavoro.claude: [
    'Capiamo cosa vuoi ottenere',
    'Preparo e provo la soluzione',
    'Ti spiego come usarla',
    'Assistenza dopo la consegna',
  ],
  TipoLavoro.altro: [
    'Capiamo cosa ti serve',
    'Mi occupo io del lavoro',
    'Controllo finale',
    'Consegna',
  ],
};

const benefitPerTipo = {
  TipoLavoro.doppiaggio: [
    'Voce professionale e chiara',
    'Audio pulito, pronto da usare',
    'Consegna puntuale',
    'Una revisione inclusa',
  ],
  TipoLavoro.codice: [
    'Un lavoro chiaro e semplice da usare',
    'Funziona bene anche da telefono',
    'Assistenza dopo la consegna',
    'Prezzo chiaro, senza sorprese',
  ],
  TipoLavoro.claude: [
    'Risparmi tempo ogni giorno',
    'Soluzione su misura per te',
    'Ti insegno a usarla',
    'Nessun costo nascosto',
  ],
  TipoLavoro.altro: [
    'Risparmi tempo e pensieri',
    'Ti seguo io, passo passo',
    'Una persona di fiducia',
    'Prezzo chiaro, senza sorprese',
  ],
};

const consegnePreset = ['2 giorni', '1 settimana', '2 settimane', '1 mese'];

List<String> fasiDi(TipoLavoro tipo) =>
    fasiPerTipo[tipo] ?? fasiPerTipo[TipoLavoro.altro]!;

List<String> benefitDi(TipoLavoro tipo) =>
    benefitPerTipo[tipo] ?? benefitPerTipo[TipoLavoro.altro]!;

/// I tre testi del foglio, già composti.
class TestiPreventivo {
  const TestiPreventivo({
    required this.progetto,
    required this.comeLavoro,
    required this.benefit,
  });

  /// Un paragrafo: per chi, cosa e in quanto tempo.
  final String progetto;

  /// Le fasi, una per riga.
  final List<String> comeLavoro;

  /// I vantaggi per il cliente, uno per riga.
  final List<String> benefit;
}

/// Mette un punto in fondo se manca (e toglie spazi inutili).
String _conPunto(String testo) {
  final t = testo.trim();
  if (t.isEmpty) return t;
  return '.!?…'.contains(t[t.length - 1]) ? t : '$t.';
}

String _senzaVuoti(String s) => s.trim();

/// Compone i testi dal modello:
/// «Per Luca: sito vetrina. Consegna in 1 settimana.» più fasi e vantaggi.
TestiPreventivo componiTesti({
  required String progetto,
  String? cliente,
  required List<String> fasi,
  required String consegna,
  required List<String> benefit,
}) {
  final chi = (cliente == null || cliente.trim().isEmpty)
      ? ''
      : 'Per ${cliente.trim()}: ';
  final cosa = _conPunto(progetto);
  final quando = consegna.trim().isEmpty
      ? ''
      : ' Consegna in ${consegna.trim()}.';
  return TestiPreventivo(
    progetto: '$chi$cosa$quando'.trim(),
    comeLavoro: [
      for (final f in fasi)
        if (_senzaVuoti(f).isNotEmpty) _senzaVuoti(f),
    ],
    benefit: [
      for (final b in benefit)
        if (_senzaVuoti(b).isNotEmpty) _senzaVuoti(b),
    ],
  );
}

/// Il blocco del prezzo: prezzo pieno, sconto (se c'è) e totale.
class ContoPrezzo {
  const ContoPrezzo({
    required this.pieno,
    required this.totale,
    required this.scontoImporto,
    required this.scontoPercento,
  });

  final double pieno;
  final double totale;

  /// Quanto regali (0 se non c'è sconto).
  final double scontoImporto;

  /// Lo sconto in %, arrotondato (0 se non c'è).
  final int scontoPercento;

  bool get haSconto => scontoImporto > 0;
}

/// Calcola il conto dai prezzi del lavoro. Senza prezzo pieno si parte dal totale.
ContoPrezzo contoPrezzo({
  required double prezzoPieno,
  required double prezzoFinale,
}) {
  final pieno = prezzoPieno > prezzoFinale ? prezzoPieno : prezzoFinale;
  final regalo = scontoRegalato(pieno, prezzoFinale);
  return ContoPrezzo(
    pieno: pieno,
    totale: prezzoFinale,
    scontoImporto: regalo,
    scontoPercento: pieno > 0 ? (regalo / pieno * 100).round() : 0,
  );
}
