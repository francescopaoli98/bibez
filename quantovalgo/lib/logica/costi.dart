import '../modelli/costo.dart';
import '../modelli/lavoro.dart';
import '../modelli/tipi.dart';
import 'mesi.dart';

/// Quanto pesa un costo in un certo mese.
///
/// - Abbonamento e fisso: l'importo, dal mese di inizio fino all'eventuale fine.
/// - Una tantum: il prezzo diviso i mesi (90 € ÷ 6 = 15 €/mese), a partire dal
///   mese dell'acquisto. Con 1 mese pesa tutto nel mese in cui l'hai pagato.
double quotaNelMese(Costo costo, DateTime mese) {
  final corrente = primoDelMese(mese);
  final trascorsi = differenzaMesi(primoDelMese(costo.inizio), corrente);
  if (trascorsi < 0) return 0; // non è ancora iniziato

  switch (costo.tipo) {
    case TipoCosto.unaTantum:
      final mesi = costo.mesi < 1 ? 1 : costo.mesi;
      return trascorsi < mesi ? costo.importo / mesi : 0;
    case TipoCosto.abbonamento:
    case TipoCosto.fisso:
      final fine = costo.fine;
      if (fine != null && corrente.isAfter(primoDelMese(fine))) return 0;
      return costo.importo;
  }
}

/// Totale dei costi di un mese.
double totaleCostiDelMese(Iterable<Costo> costi, DateTime mese) =>
    costi.fold<double>(0, (somma, c) => somma + quotaNelMese(c, mese));

/// Progetto con il peso che ha nella divisione di un costo.
class PesoProgetto {
  const PesoProgetto(this.lavoroId, this.ore);

  final String lavoroId;
  final double ore;
}

/// La parte di un costo che tocca a un progetto.
class Quota {
  const Quota({
    required this.lavoroId,
    required this.percentuale,
    required this.importo,
  });

  final String lavoroId;

  /// Da 0 a 100.
  final double percentuale;

  /// In euro, arrotondato ai centesimi.
  final double importo;
}

/// Divide [importo] tra i progetti: in proporzione alle ore lavorate; se
/// nessuno ha ore, in parti uguali. I centesimi avanzati vanno ai progetti
/// con il resto più grande, così la somma fa sempre esattamente [importo].
///
/// Esempio: 20 € con ore 11 / 7 / 2 → 11 € + 7 € + 2 €.
List<Quota> ripartisci(double importo, List<PesoProgetto> progetti) {
  if (progetti.isEmpty) return const [];

  final oreTotali = progetti.fold<double>(0, (s, p) => s + p.ore);
  final pesi = [for (final p in progetti) oreTotali > 0 ? p.ore : 1.0];
  final pesoTotale = pesi.fold<double>(0, (s, p) => s + p);

  final centesimiTotali = (importo * 100).round();
  final esatti = [for (final p in pesi) centesimiTotali * p / pesoTotale];
  final centesimi = [for (final e in esatti) e.floor()];

  // Distribuisce i centesimi mancanti a chi ha la parte decimale più alta.
  var mancanti = centesimiTotali - centesimi.fold<int>(0, (s, c) => s + c);
  final ordine = List.generate(progetti.length, (i) => i)
    ..sort(
      (a, b) => (esatti[b] - centesimi[b]).compareTo(esatti[a] - centesimi[a]),
    );
  for (final i in ordine) {
    if (mancanti <= 0) break;
    centesimi[i]++;
    mancanti--;
  }

  return [
    for (var i = 0; i < progetti.length; i++)
      Quota(
        lavoroId: progetti[i].lavoroId,
        percentuale: pesi[i] / pesoTotale * 100,
        importo: centesimi[i] / 100,
      ),
  ];
}

/// Progetti "attivi" in un mese: già creati e non ancora incassati
/// (oppure incassati proprio in quel mese). Solo loro si dividono i costi.
List<Lavoro> progettiAttivi(Iterable<Lavoro> lavori, DateTime mese) {
  final inizio = primoDelMese(mese);
  final fine = meseSuccessivo(mese);
  return [
    for (final l in lavori)
      if (l.creatoIl.isBefore(fine) &&
          (l.statoPagamento == StatoPagamento.daIncassare ||
              (l.dataIncasso != null && !l.dataIncasso!.isBefore(inizio))))
        l,
  ];
}

/// Quanto è costato un costo dall'inizio fino a [mese] compreso.
/// - Una tantum: il prezzo intero, se l'acquisto è già avvenuto.
/// - Abbonamento e fisso: la somma dei mesi pagati.
double costoSostenutoFinoA(Costo costo, DateTime mese) {
  final ultimo = primoDelMese(mese);
  final primo = primoDelMese(costo.inizio);
  if (ultimo.isBefore(primo)) return 0;
  if (costo.tipo == TipoCosto.unaTantum) return costo.importo;

  // Un mese alla volta (con un tetto di sicurezza di 50 anni)
  var somma = 0.0;
  final mesi = differenzaMesi(primo, ultimo).clamp(0, 600);
  for (var i = 0; i <= mesi; i++) {
    somma += quotaNelMese(costo, DateTime(primo.year, primo.month + i));
  }
  return somma;
}

/// Costi di una stessa categoria, che si recuperano con i progetti di quella
/// categoria. [categoriaId] vuoto = gli "altri costi", senza categoria.
class GruppoRecupero {
  const GruppoRecupero({
    required this.categoriaId,
    required this.totale,
    required this.recuperato,
  });

  final String? categoriaId;

  /// Quanto è costato in tutto.
  final double totale;

  /// Quanto ne hanno già coperto i progetti incassati (mai più del totale).
  final double recuperato;

  double get residuo => totale - recuperato;

  /// Da 0 a 1, per la barra di avanzamento.
  double get avanzamento => totale <= 0 ? 0 : recuperato / totale;
}

/// "Da recuperare", una riga per categoria.
///
/// - I costi di una categoria contano **tutti** i mesi pagati e si coprono
///   **solo** con l'utile dei progetti incassati della stessa categoria. I mesi
///   senza progetti di quella categoria non si perdono: restano da recuperare.
/// - Gli "altri costi" (senza categoria) contano solo gli acquisti una tantum;
///   si coprono con quello che avanza: l'utile in più delle categorie che hanno
///   già coperto i propri costi, più l'utile dei progetti senza costi di
///   categoria (anche quelli senza categoria). L'utile non si usa due volte.
///
/// - [categoriaDelCosto]: id della categoria del costo, o null se non ne ha.
/// - [utileIncassato]: utile (ricavi − costi diretti) dei progetti incassati,
///   per categoria; la chiave null raccoglie i progetti senza categoria.
/// - [ordine]: ordine delle righe (di solito la creazione delle categorie).
List<GruppoRecupero> gruppiDaRecuperare({
  required Iterable<Costo> costi,
  required String? Function(Costo) categoriaDelCosto,
  required Map<String?, double> utileIncassato,
  required List<String> ordine,
  required DateTime mese,
}) {
  final perCategoria = <String, double>{};
  var altri = 0.0;
  for (final c in costi) {
    final categoria = categoriaDelCosto(c);
    if (categoria != null) {
      perCategoria[categoria] =
          (perCategoria[categoria] ?? 0) + costoSostenutoFinoA(c, mese);
    } else if (c.tipo == TipoCosto.unaTantum) {
      altri += costoSostenutoFinoA(c, mese);
    }
  }

  double utileDi(String? categoria) {
    final utile = utileIncassato[categoria] ?? 0;
    return utile < 0 ? 0 : utile;
  }

  final gruppi = <GruppoRecupero>[];
  var avanzo = 0.0; // utile che non serve ai costi della propria categoria
  final viste = <String?>{};
  for (final id in [...ordine, ...perCategoria.keys]) {
    if (!viste.add(id)) continue;
    final totale = perCategoria[id] ?? 0;
    final utile = utileDi(id);
    if (totale <= 0) {
      avanzo += utile;
      continue;
    }
    final recuperato = utile > totale ? totale : utile;
    avanzo += utile - recuperato;
    gruppi.add(
      GruppoRecupero(categoriaId: id, totale: totale, recuperato: recuperato),
    );
  }
  // Utile di categorie non elencate e dei progetti senza categoria
  for (final categoria in utileIncassato.keys) {
    if (categoria == null || !viste.contains(categoria)) {
      avanzo += utileDi(categoria);
    }
  }
  if (altri > 0) {
    gruppi.add(
      GruppoRecupero(
        categoriaId: null,
        totale: altri,
        recuperato: avanzo > altri ? altri : avanzo,
      ),
    );
  }
  return gruppi;
}
