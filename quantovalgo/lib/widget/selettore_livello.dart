import 'package:flutter/material.dart';

import '../tema/colori.dart';
import 'carta_vetro.dart';
import 'effetto_morbido.dart';

/// "Il tuo livello": cinque foglie da toccare, da 1 a 5.
class SelettoreLivello extends StatelessWidget {
  const SelettoreLivello({
    super.key,
    required this.livello,
    required this.onCambia,
  });

  final int livello;
  final ValueChanged<int> onCambia;

  static const _descrizioni = {
    1: 'principiante',
    2: 'in crescita',
    3: 'intermedio',
    4: 'esperto',
    5: 'al top',
  };

  @override
  Widget build(BuildContext context) {
    return CartaVetro(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            liveRegion: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Il tuo livello',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                Text(
                  '$livello su 5 · ${_descrizioni[livello]}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ColoriLaguna.testoSecondario,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var n = 1; n <= 5; n++)
                Semantics(
                  container: true,
                  button: true,
                  selected: n == livello,
                  label: 'Livello $n su 5',
                  excludeSemantics: true,
                  child: EffettoMorbido(
                    scalaPremuto: 0.8,
                    child: InkResponse(
                      onTap: () => onCambia(n),
                      radius: 26,
                      // Area toccabile di 52×48: più del minimo di 44
                      child: SizedBox(
                        width: 52,
                        height: 48,
                        child: Icon(
                          n <= livello ? Icons.eco_rounded : Icons.eco_outlined,
                          size: 32,
                          color: n <= livello
                              ? const Color(0xFF3FA81F)
                              : const Color(0xFF4F7482),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
