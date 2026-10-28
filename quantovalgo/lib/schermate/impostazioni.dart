import 'package:flutter/material.dart';

import '../servizi/archivio.dart';
import '../servizi/servizi_app.dart';
import '../tema/colori.dart';
import '../widget/carta_vetro.dart';
import '../widget/pagina_secondaria.dart';
import '../widget/pulsante_lucido.dart';
import '../widget/stato_vuoto.dart';

/// Impostazioni: per ora account Google, stato di sincronizzazione e uscita.
/// (Sconti, tasse e promemoria arrivano nel passo 8.)
class ImpostazioniPagina extends StatelessWidget {
  const ImpostazioniPagina({super.key});

  Future<void> _esci(BuildContext context) async {
    final servizi = ServiziApp.di(context);
    // Prima torno alla schermata iniziale, poi esco: altrimenti questa
    // pagina resterebbe aperta sopra al login.
    Navigator.of(context).popUntil((r) => r.isFirst);
    await servizi.accesso.esci();
  }

  @override
  Widget build(BuildContext context) {
    final servizi = ServiziApp.di(context);
    final utente = servizi.accesso.utenteCorrente;
    final tema = Theme.of(context).textTheme;

    return PaginaSecondaria(
      titolo: 'Impostazioni',
      figli: [
        CartaVetro(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Account Google',
                style: tema.labelMedium?.copyWith(
                  color: ColoriLaguna.testoSecondario,
                ),
              ),
              const SizedBox(height: 4),
              Text(utente?.nome ?? 'Senza nome', style: tema.titleLarge),
              if (utente?.email != null)
                Text(
                  utente!.email!,
                  style: tema.bodyMedium?.copyWith(
                    color: ColoriLaguna.testoSecondario,
                  ),
                ),
              if (utente != null) ...[
                const SizedBox(height: 12),
                _StatoSync(
                  stato: servizi.archivio.statoSincronizzazione(utente.uid),
                ),
              ],
              const SizedBox(height: 16),
              PulsanteLucido(
                etichetta: 'Esci',
                icona: Icons.logout_rounded,
                onPressed: () => _esci(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const StatoVuoto(
          icona: Icons.tune_rounded,
          titolo: 'Altre impostazioni in arrivo',
          testo: 'Qui regolerai sconti, tasse e promemoria.',
        ),
      ],
    );
  }
}

/// Riga che dice se i dati sono allineati col cloud (icona + testo,
/// non solo colore).
class _StatoSync extends StatelessWidget {
  const _StatoSync({required this.stato});

  final Stream<StatoSincronizzazione> stato;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<StatoSincronizzazione>(
      stream: stato,
      builder: (context, istantanea) {
        final (colore, icona, testo) = switch (istantanea.data) {
          StatoSincronizzazione.sincronizzato => (
            ColoriLaguna.positivo,
            Icons.cloud_done_rounded,
            'Dati sincronizzati col cloud',
          ),
          StatoSincronizzazione.problema => (
            ColoriLaguna.negativo,
            Icons.error_outline_rounded,
            'Il cloud rifiuta i dati: controlla le regole di Firestore',
          ),
          _ => (
            const Color(0xFF8A5A00),
            Icons.cloud_off_rounded,
            'Dati sul telefono, in attesa del cloud',
          ),
        };
        return Semantics(
          liveRegion: true,
          child: Row(
            children: [
              Icon(icona, color: colore),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  testo,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: colore, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
