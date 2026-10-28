import 'package:flutter/material.dart';

import '../tema/colori.dart';
import 'effetto_morbido.dart';

/// Pillola di una categoria: pallino colorato e nome. Se scelta ha il bordo
/// del suo colore e una spunta (il nome c'è sempre: il colore non basta).
/// Con [colore] nullo è la voce "Nessuna" (pallino vuoto).
class ChipCategoria extends StatelessWidget {
  const ChipCategoria({
    super.key,
    required this.etichetta,
    required this.colore,
    required this.selezionata,
    required this.onTap,
  });

  final String etichetta;
  final Color? colore;
  final bool selezionata;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bordo = selezionata
        ? (colore ?? ColoriLaguna.testoSecondario)
        : const Color(0xFF6FCBEF);

    return Semantics(
      container: true,
      button: true,
      selected: selezionata,
      label: etichetta,
      excludeSemantics: true,
      child: EffettoMorbido(
        scalaPremuto: 0.95,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40065A78),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Material(
              type: MaterialType.transparency,
              child: Ink(
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: bordo, width: selezionata ? 3 : 2),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFFFFF), Color(0xFFEAFAFF)],
                  ),
                ),
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colore,
                            border: colore == null
                                ? Border.all(
                                    color: ColoriLaguna.testoSecondario,
                                    width: 2,
                                  )
                                : Border.all(color: Colors.white, width: 1.5),
                            boxShadow: colore == null
                                ? null
                                : [
                                    BoxShadow(
                                      color: colore!.withValues(alpha: 0.5),
                                      blurRadius: 3,
                                    ),
                                  ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          etichetta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: ColoriLaguna.testo,
                          ),
                        ),
                        if (selezionata) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: ColoriLaguna.testo,
                          ),
                        ],
                      ],
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
