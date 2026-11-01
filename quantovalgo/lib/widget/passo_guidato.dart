import 'package:flutter/material.dart';

import '../tema/colori.dart';
import 'pulsante_lucido.dart';
import 'sfera_lucida.dart';
import 'sfondo_laguna.dart';
import 'stile_lucido.dart';

/// Una schermata del percorso guidato: sfondo Laguna, un titolo grande, i
/// puntini del passo e, in basso, un solo pulsante verde.
/// Con [chiudi] il primo pulsante è una X che torna alla Home.
class PassoGuidato extends StatelessWidget {
  const PassoGuidato({
    super.key,
    required this.titolo,
    required this.figli,
    this.sottotitolo,
    this.passo,
    this.chiudi = false,
    this.azione,
    this.onAzione,
  });

  final String titolo;
  final String? sottotitolo;
  final List<Widget> figli;

  /// Passo corrente da 1 a 3 (vuoto: niente puntini).
  final int? passo;
  final bool chiudi;

  /// Testo e azione del pulsante verde in basso (vuoti: nessun pulsante).
  final String? azione;
  final VoidCallback? onAzione;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    return SfondoLaguna(
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: [
              Row(
                children: [
                  SferaLucida(
                    icona: chiudi
                        ? Icons.close_rounded
                        : Icons.arrow_back_rounded,
                    etichetta: chiudi ? 'Chiudi' : 'Indietro',
                    dimensione: 48,
                    onPressed: () => chiudi
                        ? Navigator.of(context).popUntil((r) => r.isFirst)
                        : Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: passo == null
                        ? const SizedBox.shrink()
                        : _Puntini(passo: passo!),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 18),
              Semantics(
                header: true,
                child: Text(
                  titolo,
                  style: const TextStyle(
                    fontSize: 36,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    color: ColoriLaguna.testo,
                  ),
                ),
              ),
              if (sottotitolo != null) ...[
                const SizedBox(height: 6),
                Text(
                  sottotitolo!,
                  style: tema.titleMedium?.copyWith(
                    color: ColoriLaguna.testoSecondario,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              ...figli,
            ],
          ),
        ),
        bottomNavigationBar: onAzione == null
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(45, 8, 45, 18),
                  child: PulsanteLucido(
                    etichetta: azione ?? 'Avanti',
                    stile: StileLucido.verde,
                    altezza: 64,
                    onPressed: onAzione,
                  ),
                ),
              ),
      ),
    );
  }
}

/// Tre puntini: quello del passo corrente è una barretta più lunga.
class _Puntini extends StatelessWidget {
  const _Puntini({required this.passo});

  final int passo;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Passo $passo di 3',
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 1; i <= 3; i++) ...[
            if (i > 1) const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: i == passo ? 28 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: i == passo
                    ? const Color(0xFF0A4C86)
                    : const Color(0x4D0A4C86),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
