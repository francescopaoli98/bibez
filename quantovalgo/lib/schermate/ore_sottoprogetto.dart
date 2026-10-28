import 'package:flutter/material.dart';

import '../logica/formato.dart';
import '../logica/mesi.dart';
import '../modelli/sessione_ore.dart';
import '../modelli/sottoprogetto.dart';
import '../servizi/stato_dati.dart';
import '../tema/colori.dart';
import '../widget/carta_vetro.dart';
import '../widget/hero_laguna.dart';
import '../widget/pagina_secondaria.dart';
import '../widget/pulsante_lucido.dart';
import '../widget/sfera_lucida.dart';
import '../widget/stato_vuoto.dart';
import '../widget/stile_lucido.dart';
import '../widget/testo_cronometro.dart';
import 'cronometro_azioni.dart';
import 'foglio_sessione.dart';
import 'foglio_sottoprogetto.dart';

/// Le ore di un sottoprogetto: cronometro, ore a mano e sessioni registrate.
class OreSottoprogettoPagina extends StatefulWidget {
  const OreSottoprogettoPagina({super.key, required this.sottoprogettoId});

  final String sottoprogettoId;

  @override
  State<OreSottoprogettoPagina> createState() => _OreSottoprogettoPaginaState();
}

class _OreSottoprogettoPaginaState extends State<OreSottoprogettoPagina> {
  bool _inChiusura = false;

  @override
  Widget build(BuildContext context) {
    final sottoprogettoId = widget.sottoprogettoId;
    final dati = DatiScope.di(context);
    final sotto = dati.sottoprogetto(sottoprogettoId);

    // Eliminato mentre la pagina era aperta (o ne è sparito il progetto):
    // la pagina non ha più senso e si chiude da sola.
    if (sotto == null) {
      if (!_inChiusura) {
        _inChiusura = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.of(context).maybePop();
        });
      }
      return const PaginaSecondaria(titolo: '', figli: []);
    }

    final lavoro = dati.lavoro(sotto.lavoroId);
    final tema = Theme.of(context).textTheme;
    final acceso = dati.sessioneInCorso;
    final questoAcceso = acceso != null && acceso.sottoprogettoId == sotto.id;
    final altroAcceso = acceso != null && !questoAcceso;
    final altroNome = altroAcceso
        ? dati.sottoprogetto(acceso.sottoprogettoId)?.nome
        : null;

    final minutiInizialiTot = (sotto.ore * 60).round();
    final minutiRegistrati = dati.minutiRegistrati(sotto.id);
    final totale = minutiInizialiTot + minutiRegistrati;
    final oraGuadagno = totale > 0 ? sotto.utile / (totale / 60) : null;
    final sessioni = [
      for (final s in dati.sessioniDi(sotto.id))
        if (!s.inCorso) s,
    ];

    return PaginaSecondaria(
      titolo: sotto.nome,
      sottotitolo: lavoro?.nome,
      destra: SferaLucida(
        icona: Icons.edit_rounded,
        etichetta: 'Modifica sottoprogetto',
        onPressed: () => modificaSottoprogetto(
          context,
          lavoroId: sotto.lavoroId,
          esistente: sotto,
        ),
      ),
      figli: [
        HeroLaguna(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ore lavorate',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: ColoriLaguna.testoChiaro,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                durata(totale),
                style: const TextStyle(
                  fontSize: 44,
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
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _Dato(
                      etichetta: 'Iniziali',
                      valore: durata(minutiInizialiTot),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Dato(
                      etichetta: 'Registrate',
                      valore: durata(minutiRegistrati),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Dato(
                      etichetta: "All'ora",
                      valore: oraGuadagno == null
                          ? '—'
                          : '${euro(oraGuadagno)}/h',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        CartaVetro(
          colori: questoAcceso
              ? const [Color(0xFFFFF6C4), Color(0xFFFFE98F)]
              : const [Color(0xF2FFFFFF), Color(0xD9EEFCFC)],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (questoAcceso) ...[
                Text(
                  'Cronometro acceso dalle ${oraDelGiorno(acceso.inizio)}',
                  style: tema.labelMedium?.copyWith(
                    fontSize: 14,
                    color: ColoriLaguna.testoSecondario,
                  ),
                ),
                Center(
                  child: TestoCronometro(
                    inizio: acceso.inizio,
                    adesso: dati.adesso,
                    stile: const TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      color: ColoriLaguna.testo,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                PulsanteLucido(
                  etichetta: 'Ferma cronometro',
                  icona: Icons.stop_rounded,
                  stile: StileLucido.rosso,
                  altezza: 56,
                  onPressed: () => fermaCronometro(context, dati),
                ),
              ] else ...[
                PulsanteLucido(
                  etichetta: 'Avvia cronometro',
                  icona: Icons.play_arrow_rounded,
                  stile: StileLucido.verde,
                  altezza: 56,
                  onPressed: () => avviaCronometro(context, dati, sotto),
                ),
                if (altroAcceso) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Hai già un cronometro acceso su "${altroNome ?? 'un altro sottoprogetto'}": '
                    'se parti qui, si ferma e si salva.',
                    style: tema.labelMedium?.copyWith(
                      color: ColoriLaguna.testoSecondario,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        PulsanteLucido(
          etichetta: 'Aggiungi ore a mano',
          icona: Icons.edit_calendar_rounded,
          onPressed: () => modificaSessione(context, sottoprogetto: sotto),
        ),
        const SizedBox(height: 16),
        Semantics(
          header: true,
          child: Text('Sessioni registrate', style: tema.titleLarge),
        ),
        const SizedBox(height: 8),
        if (sessioni.isEmpty)
          const StatoVuoto(
            icona: Icons.timer_outlined,
            titolo: 'Nessuna sessione',
            testo: 'Avvia il cronometro oppure aggiungi le ore a mano.',
          )
        else
          for (final s in sessioni) ...[
            _RigaSessione(sessione: s, sotto: sotto),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

/// Casella trasparente dentro il riquadro grande.
class _Dato extends StatelessWidget {
  const _Dato({required this.etichetta, required this.valore});

  final String etichetta;
  final String valore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etichetta,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: ColoriLaguna.testoChiaro,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              valore,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RigaSessione extends StatelessWidget {
  const _RigaSessione({required this.sessione, required this.sotto});

  final SessioneOre sessione;
  final Sottoprogetto sotto;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    final fine = sessione.fine;
    return CartaVetro(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      onTap: () =>
          modificaSessione(context, sottoprogetto: sotto, esistente: sessione),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  descrizioneGiorno(sessione.inizio),
                  style: tema.titleMedium,
                ),
                Text(
                  sessione.manuale || fine == null
                      ? 'Inserite a mano'
                      : 'Cronometro · ${oraDelGiorno(sessione.inizio)}–${oraDelGiorno(fine)}',
                  style: tema.labelMedium?.copyWith(
                    color: ColoriLaguna.testoSecondario,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            durata(sessione.minuti),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
