import '../logica/prezzi_web.dart';
import '../modelli/tipi.dart';
import 'ricerca_prezzi.dart';
import 'stato_dati.dart';

/// Aggiorna da solo le forbici di mercato trovate dal web, una volta a
/// settimana. Parte solo se l'hai acceso in Impostazioni, c'è la chiave Tavily
/// e hai aperto l'app (non gira in background). Le forbici scritte a mano non
/// si toccano. Ogni tipo si prova una volta sola per apertura dell'app.
class AggiornamentoPrezzi {
  AggiornamentoPrezzi({required this.dati, required this.ricerca}) {
    dati.addListener(controlla);
    controlla();
  }

  final StatoDati dati;
  final RicercaPrezzi ricerca;

  final _provati = <TipoLavoro>{};
  bool _inCorso = false;

  /// Cosa è finito in questa apertura (serve ai test per aspettare).
  Future<void> _ultima = Future.value();
  Future<void> get fatto => _ultima;

  void controlla() {
    if (_inCorso || !dati.caricato) return;
    final i = dati.impostazioni;
    if (!i.aggiornaPrezzi || i.chiaveTavily.isEmpty) return;

    // Si rifà la ricerca di prima (anche quella personalizzata); per un tipo
    // senza forbice si parte dalla domanda di partenza, se ce n'è una.
    final da = [
      for (final t in TipoLavoro.values)
        if (tipoCercabile(t) &&
            !_provati.contains(t) &&
            dati.prezzoDaAggiornare(t) &&
            (domandaPredefinita.containsKey(t) ||
                (dati.mercatoPer(t)?.domanda.isNotEmpty ?? false)))
          t,
    ];
    if (da.isEmpty) return;

    _inCorso = true;
    _ultima = _aggiorna(da);
  }

  Future<void> _aggiorna(List<TipoLavoro> tipi) async {
    try {
      for (final tipo in tipi) {
        _provati.add(tipo);
        if (!dati.puoCercare) break;
        final esito = await ricerca.cerca(
          tipo,
          chiave: dati.impostazioni.chiaveTavily,
          domanda: dati.mercatoPer(tipo)?.domanda,
        );
        if (esito.consumaCredito) dati.registraRicerca();
        if (esito is RicercaTrovata) {
          dati.salvaForbiceDaRicerca(tipo, esito.trovata);
        }
      }
    } finally {
      _inCorso = false;
    }
  }

  void dispose() => dati.removeListener(controlla);
}
