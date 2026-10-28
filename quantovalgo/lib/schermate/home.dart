import 'package:flutter/material.dart';

import '../widget/hero_laguna.dart';
import '../widget/logo_sole.dart';
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
      sinistra: const LogoSole(),
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
