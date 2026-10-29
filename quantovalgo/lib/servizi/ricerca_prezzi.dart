import '../logica/prezzi_web.dart';
import '../modelli/tipi.dart';

/// Esito di una ricerca dei prezzi di mercato sul web.
sealed class RisultatoRicerca {
  const RisultatoRicerca();

  /// Vero se la ricerca ha usato un credito di Tavily.
  bool get consumaCredito;
}

/// Trovata una forbice affidabile.
class RicercaTrovata extends RisultatoRicerca {
  const RicercaTrovata(this.trovata);

  final ForbiceTrovata trovata;

  @override
  bool get consumaCredito => true;
}

/// La ricerca è andata a buon fine ma i numeri non bastano o non sono coerenti:
/// l'app lo dice e lascia scrivere la forbice a mano.
class RicercaNonAffidabile extends RisultatoRicerca {
  const RicercaNonAffidabile([this.esito]);

  /// Perché non è affidabile, con i numeri (vuoto se non si sa).
  final EsitoForbice? esito;

  /// Spiegazione in italiano di cosa è andato storto.
  String get spiegazione {
    final e = esito;
    if (e == null || e.motivo == null) {
      return 'Ho cercato, ma i prezzi trovati sono pochi o troppo diversi '
          'tra loro per fidarmi.';
    }
    String soldi(double v) => '${v.round()}';
    return switch (e.motivo!) {
      MotivoNonAffidabile.nessunPrezzo =>
        'Nelle pagine trovate non ci sono prezzi in euro che sembrino quelli '
            'di questo lavoro.',
      MotivoNonAffidabile.pochiPrezzi =>
        'Ho trovato solo ${e.importi} ${e.importi == 1 ? 'prezzo' : 'prezzi'} '
            '(ne servono almeno $minImporti).',
      MotivoNonAffidabile.unSoloSito =>
        'I ${e.importi} prezzi trovati arrivano da un solo sito '
            '(ne servono almeno $minFonti diversi).',
      MotivoNonAffidabile.troppoDiversi =>
        'Ho trovato ${e.importi} prezzi da ${e.siti} siti, ma vanno da '
            '${soldi(e.minimo!)} a ${soldi(e.massimo!)} €: troppo diversi tra '
            'loro per fidarmi.',
      MotivoNonAffidabile.tuttiUguali =>
        'I prezzi trovati sono quasi tutti uguali: non fanno una forbice.',
    };
  }

  @override
  bool get consumaCredito => true;
}

/// La ricerca non è partita o è fallita (chiave, internet, crediti finiti...).
class RicercaFallita extends RisultatoRicerca {
  const RicercaFallita(this.messaggio, {this.serveChiave = false});

  /// Spiegazione in italiano, da mostrare così com'è.
  final String messaggio;

  /// Vero se il problema è la chiave: ha senso mandare in Impostazioni.
  final bool serveChiave;

  @override
  bool get consumaCredito => false;
}

/// Cerca sul web il prezzo di mercato di un tipo di lavoro. Un'interfaccia
/// sola, così i test usano una versione finta e l'app usa Tavily.
abstract interface class RicercaPrezzi {
  /// [domanda] è cosa cercare (scritta dall'utente); se manca si usa quella di
  /// partenza del tipo. Per "Altro" una domanda ci vuole.
  Future<RisultatoRicerca> cerca(
    TipoLavoro tipo, {
    required String chiave,
    String? domanda,
  });
}
