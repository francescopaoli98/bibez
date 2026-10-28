import 'package:flutter/material.dart';

import '../logica/giornate.dart';
import '../logica/mesi.dart';
import '../tema/colori.dart';
import 'carta_vetro.dart';
import 'effetto_morbido.dart';

/// Come si presenta un giorno nel calendario.
enum StatoGiorno {
  /// Giorno libero.
  normale,

  /// Verde: giornata fatta o scelta.
  verde,

  /// Blu: giornata in programma o già presente.
  blu,
}

/// Calendario di un mese: giorni da toccare, lunedì per primo.
/// I giorni verdi e blu sono quelli segnati; "oggi" ha un anello.
class CalendarioGiorni extends StatelessWidget {
  const CalendarioGiorni({
    super.key,
    required this.mese,
    required this.oggi,
    required this.onTapGiorno,
    this.verdi = const {},
    this.blu = const {},
    this.mezze = const {},
    this.etichettaGiorno,
  });

  /// Primo giorno del mese da mostrare.
  final DateTime mese;
  final DateTime oggi;
  final Set<DateTime> verdi;
  final Set<DateTime> blu;

  /// Giorni da segnare con "½" (mezza giornata), in aggiunta al colore.
  final Set<DateTime> mezze;
  final ValueChanged<DateTime> onTapGiorno;

  /// Nome del giorno per i lettori di schermo (es. "28 ottobre, giornata").
  final String Function(DateTime giorno, StatoGiorno stato)? etichettaGiorno;

  static const _iniziali = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];

  StatoGiorno _stato(DateTime g) => verdi.contains(g)
      ? StatoGiorno.verde
      : blu.contains(g)
      ? StatoGiorno.blu
      : StatoGiorno.normale;

  @override
  Widget build(BuildContext context) {
    final primo = primoDelMese(mese);
    final giorniDelMese = DateUtils.getDaysInMonth(primo.year, primo.month);
    final vuotiPrima = primo.weekday - 1; // lunedì = 0 celle vuote
    final righe = ((vuotiPrima + giorniDelMese) / 7).ceil();
    final oggiSolo = soloData(oggi);

    return CartaVetro(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
      child: Column(
        children: [
          // Iniziali dei giorni: il nome completo sta in ogni cella
          ExcludeSemantics(
            child: Row(
              children: [
                for (final i in _iniziali)
                  Expanded(
                    child: Center(
                      child: Text(
                        i,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: ColoriLaguna.testoSecondario,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          for (var r = 0; r < righe; r++)
            Row(
              children: [
                for (var c = 0; c < 7; c++)
                  Expanded(
                    child: _cella(
                      primo,
                      r * 7 + c - vuotiPrima + 1,
                      giorniDelMese,
                      oggiSolo,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _cella(
    DateTime primo,
    int numero,
    int giorniDelMese,
    DateTime oggiSolo,
  ) {
    if (numero < 1 || numero > giorniDelMese) return const SizedBox(height: 48);
    final giorno = DateTime(primo.year, primo.month, numero);
    final stato = _stato(giorno);
    return _CellaGiorno(
      numero: numero,
      stato: stato,
      eOggi: giorno == oggiSolo,
      mezza: mezze.contains(giorno),
      etichetta:
          etichettaGiorno?.call(giorno, stato) ?? descrizioneGiorno(giorno),
      onTap: () => onTapGiorno(giorno),
    );
  }
}

class _CellaGiorno extends StatelessWidget {
  const _CellaGiorno({
    required this.numero,
    required this.stato,
    required this.eOggi,
    required this.mezza,
    required this.etichetta,
    required this.onTap,
  });

  final int numero;
  final StatoGiorno stato;
  final bool eOggi;
  final bool mezza;
  final String etichetta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (colori, testo) = switch (stato) {
      StatoGiorno.verde => (
        const [Color(0xFF1A8F2E), Color(0xFF0F6B2E)],
        Colors.white,
      ),
      StatoGiorno.blu => (
        const [Color(0xFF0F72A8), Color(0xFF0C5F8F)],
        Colors.white,
      ),
      StatoGiorno.normale => (
        const [Color(0xFFFFFFFF), Color(0xFFEAFAFF)],
        ColoriLaguna.testo,
      ),
    };
    final colorato = stato != StatoGiorno.normale;

    return Semantics(
      container: true,
      button: true,
      selected: colorato,
      label: etichetta,
      excludeSemantics: true,
      child: EffettoMorbido(
        scalaPremuto: 0.85,
        child: InkResponse(
          onTap: onTap,
          radius: 26,
          // Cella di 48 px di altezza: sopra il minimo di 44
          child: SizedBox(
            height: 48,
            child: Center(
              child: _ConBadge(
                mezza: mezza,
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: colori,
                    ),
                    border: eOggi
                        ? Border.all(color: ColoriLaguna.testo, width: 2.5)
                        : Border.all(
                            color: colorato
                                ? Colors.white
                                : const Color(0xFFB8E4F2),
                            width: 1.5,
                          ),
                    boxShadow: colorato
                        ? const [
                            BoxShadow(
                              color: Color(0x40065A78),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    '$numero',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: testo,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Aggiunge in alto a destra il segno "½" delle mezze giornate.
class _ConBadge extends StatelessWidget {
  const _ConBadge({required this.mezza, required this.child});

  final bool mezza;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!mezza) return child;
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          child,
          Positioned(
            top: -2,
            right: -4,
            child: Container(
              width: 21,
              height: 21,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFE27A),
                border: Border.all(color: const Color(0xFF9A6400), width: 1.5),
              ),
              child: const Text(
                '½',
                style: TextStyle(
                  fontSize: 13,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF3A2400),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
