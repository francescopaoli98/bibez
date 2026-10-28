import 'package:flutter/material.dart';

import '../widget/hero_laguna.dart';
import '../widget/pulsante_lucido.dart';
import '../widget/sfera_lucida.dart';
import '../widget/stato_vuoto.dart';
import '../tema/colori.dart';
import 'clienti.dart';
import 'impostazioni.dart';
import 'obiettivo.dart';
import 'scheda.dart';

/// Home: saldo del mese e accesso a Clienti, Obiettivo e Impostazioni.
/// (I numeri veri arrivano nei passi successivi.)
class HomePagina extends StatelessWidget {
  const HomePagina({super.key});

  void _apri(BuildContext context, Widget pagina) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => pagina));
  }

  @override
  Widget build(BuildContext context) {
    return Scheda(
      titolo: 'QuantoValgo',
      // Pallino sole accanto al nome, come nel mockup
      sinistra: const ExcludeSemantics(child: _LogoSole()),
      destra: SferaLucida(
        icona: Icons.settings_rounded,
        etichetta: 'Impostazioni',
        onPressed: () => _apri(context, const ImpostazioniPagina()),
      ),
      figli: [
        const HeroLaguna(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Saldo del mese',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: ColoriLaguna.testoChiaro,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '0 €',
                style: TextStyle(
                  fontSize: 48,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  color: ColoriLaguna.cifraHero,
                  shadows: [
                    Shadow(
                      color: Color(0x73002838),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: PulsanteLucido(
                etichetta: 'Clienti',
                icona: Icons.people_alt_rounded,
                onPressed: () => _apri(context, const ClientiPagina()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PulsanteLucido(
                etichetta: 'Obiettivo',
                icona: Icons.flag_rounded,
                onPressed: () => _apri(context, const ObiettivoPagina()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Progetti', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const StatoVuoto(
          icona: Icons.work_outline_rounded,
          titolo: 'Ancora nessun progetto',
          testo: 'Premi il + verde per registrare il primo lavoro.',
        ),
      ],
    );
  }
}

/// Pallino giallo "sole" del logo.
class _LogoSole extends StatelessWidget {
  const _LogoSole();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.4),
          colors: [Color(0xFFFFF6B0), Color(0xFFFFC93C), Color(0xFFF08A18)],
          stops: [0.0, 0.45, 1.0],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66C86400),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
    );
  }
}
