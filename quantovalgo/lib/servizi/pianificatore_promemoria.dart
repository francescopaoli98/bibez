import 'dart:async';

import 'stato_dati.dart';
import 'promemoria_servizio.dart';

/// Tiene allineate le notifiche del telefono con i pagamenti: ogni volta che i
/// dati cambiano ricalcola i promemoria e, solo se sono diversi da prima, li
/// riprogramma. Se l'utente esce o i promemoria sono spenti, li toglie.
class PianificatorePromemoria {
  PianificatorePromemoria({required this.dati, required this.servizio}) {
    dati.addListener(_aggiorna);
    _aggiorna();
  }

  final StatoDati dati;
  final ServizioPromemoria servizio;

  String? _ultimaFirma; // null = non ho ancora programmato nulla
  bool _permessoChiesto = false;
  Future<void> _coda = Future.value(); // un'operazione alla volta

  void _aggiorna() {
    if (!dati.caricato) {
      // Ha fatto uscire l'utente: via anche le sue notifiche
      if (_ultimaFirma != null && _ultimaFirma!.isNotEmpty) {
        _ultimaFirma = '';
        _coda = _coda.then((_) => servizio.programma(const []));
      }
      return;
    }

    final lista = dati.promemoriaDaProgrammare();
    final firma = [
      for (final p in lista)
        '${p.quando.millisecondsSinceEpoch}|${p.titolo}|${p.testo}',
    ].join('\n');
    if (firma == _ultimaFirma) return;
    _ultimaFirma = firma;

    _coda = _coda.then((_) async {
      // Il permesso si chiede una volta sola, e solo se c'è qualcosa da ricordare
      if (lista.isNotEmpty && !_permessoChiesto) {
        _permessoChiesto = true;
        await servizio.chiediPermesso();
      }
      await servizio.programma(lista);
    });
  }

  void dispose() => dati.removeListener(_aggiorna);
}
