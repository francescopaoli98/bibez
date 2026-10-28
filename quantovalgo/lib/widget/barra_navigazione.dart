import 'package:flutter/material.dart';

import '../tema/colori.dart';
import 'effetto_morbido.dart';
import 'sfera_lucida.dart';
import 'stile_lucido.dart';

/// Una voce della barra in basso.
class _Voce {
  const _Voce(this.etichetta, this.icona);
  final String etichetta;
  final IconData icona;
}

const _voci = [
  _Voce('Home', Icons.home_rounded),
  _Voce('Progetti', Icons.work_outline_rounded),
  _Voce('Preventivi', Icons.description_outlined),
  _Voce('Costi', Icons.euro_rounded),
];

/// Barra di navigazione in basso: Home, Progetti, Preventivi, Costi
/// e il pulsante verde "+" per un nuovo lavoro.
class BarraNavigazione extends StatelessWidget {
  const BarraNavigazione({
    super.key,
    required this.indice,
    required this.onSelezionato,
    required this.onNuovoLavoro,
  });

  final int indice;
  final ValueChanged<int> onSelezionato;
  final VoidCallback onNuovoLavoro;

  @override
  Widget build(BuildContext context) {
    // Spazio extra per la barra di gesti di Android
    final margineBasso = MediaQuery.paddingOf(context).bottom;

    return Container(
      height: 84 + margineBasso,
      padding: EdgeInsets.fromLTRB(14, 8, 14, 12 + margineBasso),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Colors.white)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xF7FFFFFF), Color(0xEBECFBFC)],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x38065A78),
            blurRadius: 20,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < _voci.length; i++)
            _VoceBarra(
              voce: _voci[i],
              selezionata: i == indice,
              onTap: () => onSelezionato(i),
            ),
          SferaLucida(
            icona: Icons.add_rounded,
            etichetta: 'Nuovo lavoro',
            stile: StileLucido.verde,
            dimensione: 58,
            onPressed: onNuovoLavoro,
          ),
        ],
      ),
    );
  }
}

class _VoceBarra extends StatelessWidget {
  const _VoceBarra({
    required this.voce,
    required this.selezionata,
    required this.onTap,
  });

  final _Voce voce;
  final bool selezionata;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      selected: selezionata,
      label: voce.etichetta,
      excludeSemantics: true,
      child: EffettoMorbido(
        scalaPremuto: 0.9,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 56, minHeight: 44),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _IconaVoce(icona: voce.icona, selezionata: selezionata),
                const SizedBox(height: 2),
                Text(
                  voce.etichetta,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selezionata ? FontWeight.w800 : FontWeight.w700,
                    color: selezionata
                        ? ColoriLaguna.testo
                        : ColoriLaguna.testoSecondario,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Icona della voce: se selezionata sta dentro una pillola blu lucida.
class _IconaVoce extends StatelessWidget {
  const _IconaVoce({required this.icona, required this.selezionata});

  final IconData icona;
  final bool selezionata;

  @override
  Widget build(BuildContext context) {
    if (!selezionata) {
      return SizedBox(
        width: 52,
        height: 32,
        child: Icon(icona, size: 24, color: ColoriLaguna.testoSecondario),
      );
    }

    const stile = StileLucido.blu;
    return Container(
      width: 52,
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: stile.bordo, width: 2),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: stile.sfumatura,
          stops: StileLucido.stop,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66053C64),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Riflesso a capsula
          Positioned(
            left: 6,
            right: 6,
            top: 2,
            height: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.8),
                    Colors.white.withValues(alpha: 0.1),
                  ],
                ),
              ),
            ),
          ),
          Icon(
            icona,
            size: 22,
            color: Colors.white,
            shadows: [
              Shadow(
                color: stile.ombraTesto,
                blurRadius: 1,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
