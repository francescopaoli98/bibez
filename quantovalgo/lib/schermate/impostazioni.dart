import 'package:flutter/material.dart';

import '../logica/formato.dart';
import '../modelli/tipi.dart';
import '../servizi/archivio.dart';
import '../servizi/servizi_app.dart';
import '../servizi/stato_dati.dart';
import '../tema/colori.dart';
import '../widget/carta_vetro.dart';
import '../widget/pagina_secondaria.dart';
import 'foglio_chiave.dart';
import 'foglio_numero.dart';

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
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => _esci(context),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Esci'),
                style: TextButton.styleFrom(
                  foregroundColor: ColoriLaguna.negativo,
                  textStyle: tema.labelLarge?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _CartaPromemoria(),
        const SizedBox(height: 16),
        const _SezioneTasseObiettivo(),
        const SizedBox(height: 16),
        const _SezioneRicerca(),
        const SizedBox(height: 16),
        const _SezioneSconti(),
        const SizedBox(height: 16),
        const _SezioneLivelli(),
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

/// Interruttore dei promemoria dei pagamenti (notifiche sul telefono).
class _CartaPromemoria extends StatelessWidget {
  const _CartaPromemoria();

  @override
  Widget build(BuildContext context) {
    final dati = DatiScope.di(context);
    final tema = Theme.of(context).textTheme;

    return CartaVetro(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Promemoria pagamenti', style: tema.titleMedium),
                const SizedBox(height: 2),
                Text(
                  'Una notifica alle 9 il giorno prima della scadenza, il '
                  'giorno stesso e poi ogni 3 giorni di ritardo.',
                  style: tema.bodyMedium?.copyWith(
                    color: ColoriLaguna.testoSecondario,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            key: const Key('interruttore-promemoria'),
            value: dati.impostazioni.promemoria,
            onChanged: (acceso) => dati.salvaImpostazioni(
              dati.impostazioni.copyWith(promemoria: acceso),
            ),
          ),
        ],
      ),
    );
  }
}

/// Una riga "nome … valore" che si tocca per cambiare il valore.
class _RigaValore extends StatelessWidget {
  const _RigaValore({
    required this.chiave,
    required this.nome,
    required this.valore,
    required this.onTap,
  });

  final Key chiave;
  final String nome;
  final String valore;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    return InkWell(
      key: chiave,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Expanded(child: Text(nome, style: tema.titleMedium)),
            Text(
              valore,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              color: ColoriLaguna.testoSecondario,
            ),
          ],
        ),
      ),
    );
  }
}

/// Più righe in una sola scheda, separate da una linea sottile.
class _Gruppo extends StatelessWidget {
  const _Gruppo({required this.righe});

  final List<Widget> righe;

  @override
  Widget build(BuildContext context) {
    return CartaVetro(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            children: [
              for (var i = 0; i < righe.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 14, endIndent: 14),
                righe[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Titolo di sezione con una riga di spiegazione.
class _TitoloSezione extends StatelessWidget {
  const _TitoloSezione(this.titolo, this.spiegazione);

  final String titolo;
  final String spiegazione;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(header: true, child: Text(titolo, style: tema.titleLarge)),
          Text(
            spiegazione,
            style: tema.bodyMedium?.copyWith(
              color: ColoriLaguna.testoSecondario,
            ),
          ),
        ],
      ),
    );
  }
}

/// Cambia l'obiettivo mensile netto (0 = nessun obiettivo).
/// Usata da Impostazioni e dalla pagina Obiettivo.
Future<void> modificaObiettivo(BuildContext context) async {
  final dati = DatiScope.leggi(context);
  final nuovo = await chiediNumero(
    context,
    titolo: 'Obiettivo mensile',
    etichetta: 'Quanto vuoi guadagnare netto al mese (€)',
    iniziale: dati.impostazioni.obiettivoMensile,
    massimo: 1000000,
    aiuto: 'È il netto, dopo le tasse. Scrivi 0 per non avere un obiettivo.',
  );
  if (nuovo != null) {
    dati.salvaImpostazioni(dati.impostazioni.copyWith(obiettivoMensile: nuovo));
  }
}

/// Tasse e obiettivo mensile netto.
class _SezioneTasseObiettivo extends StatelessWidget {
  const _SezioneTasseObiettivo();

  @override
  Widget build(BuildContext context) {
    final dati = DatiScope.di(context);
    final i = dati.impostazioni;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _TitoloSezione(
          'Tasse e obiettivo',
          'Servono per il netto e per la tariffa minima.',
        ),
        _Gruppo(
          righe: [
            _RigaValore(
              chiave: const Key('riga-tasse'),
              nome: 'Tasse',
              valore: percentuale(i.tasse),
              onTap: () async {
                final nuove = await chiediNumero(
                  context,
                  titolo: 'Tasse',
                  etichetta: 'Percentuale di tasse (%)',
                  iniziale: i.tasse,
                  massimo: 99,
                  aiuto: 'Si toglie dal saldo del mese per avere il netto.',
                );
                if (nuove != null) {
                  dati.salvaImpostazioni(
                    dati.impostazioni.copyWith(tasse: nuove),
                  );
                }
              },
            ),
            _RigaValore(
              chiave: const Key('riga-obiettivo'),
              nome: 'Obiettivo mensile netto',
              valore: i.obiettivoMensile > 0
                  ? euro(i.obiettivoMensile)
                  : 'Non scelto',
              onTap: () => modificaObiettivo(context),
            ),
          ],
        ),
      ],
    );
  }
}

/// Sconto per ogni relazione col cliente.
class _SezioneSconti extends StatelessWidget {
  const _SezioneSconti();

  @override
  Widget build(BuildContext context) {
    final dati = DatiScope.di(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _TitoloSezione(
          'Sconti per relazione',
          'Si applicano ai nuovi prezzi; i progetti già fatti restano come sono.',
        ),
        _Gruppo(
          righe: [
            for (final r in Relazione.values)
              _RigaValore(
                chiave: Key('riga-sconto-${r.name}'),
                nome: r.etichetta,
                valore: percentuale(dati.parametri.sconto(r)),
                onTap: () async {
                  final nuovo = await chiediNumero(
                    context,
                    titolo: 'Sconto · ${r.etichetta}',
                    etichetta: 'Sconto (%)',
                    iniziale: dati.parametri.sconto(r).toDouble(),
                    massimo: 100,
                    intero: true,
                  );
                  if (nuovo != null) {
                    final i = dati.impostazioni;
                    dati.salvaImpostazioni(
                      i.copyWith(
                        scontoRelazione: {
                          ...i.scontoRelazione,
                          r: nuovo.round(),
                        },
                      ),
                    );
                  }
                },
              ),
          ],
        ),
      ],
    );
  }
}

/// Correzione del prezzo per livello di competenza.
class _SezioneLivelli extends StatelessWidget {
  const _SezioneLivelli();

  @override
  Widget build(BuildContext context) {
    final dati = DatiScope.di(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _TitoloSezione(
          'Prezzo per livello',
          'Quanto alzare o abbassare la forbice di mercato in base al tuo livello.',
        ),
        _Gruppo(
          righe: [
            for (var livello = 1; livello <= 5; livello++)
              _RigaValore(
                chiave: Key('riga-livello-$livello'),
                nome: 'Livello $livello',
                valore: percentuale(
                  dati.parametri.correzione(livello),
                  conSegno: true,
                ),
                onTap: () async {
                  final nuovo = await chiediNumero(
                    context,
                    titolo: 'Livello $livello',
                    etichetta: 'Correzione del prezzo (%)',
                    iniziale: dati.parametri.correzione(livello).toDouble(),
                    minimo: -90,
                    massimo: 200,
                    intero: true,
                    aiuto: 'Con segno meno il prezzo scende, con più sale.',
                  );
                  if (nuovo != null) {
                    final i = dati.impostazioni;
                    dati.salvaImpostazioni(
                      i.copyWith(
                        correzioneLivello: {
                          ...i.correzioneLivello,
                          livello: nuovo.round(),
                        },
                      ),
                    );
                  }
                },
              ),
          ],
        ),
      ],
    );
  }
}

/// Ricerca dei prezzi sul web (Tavily): chiave, aggiornamento settimanale e
/// quante ricerche hai già usato questo mese.
class _SezioneRicerca extends StatelessWidget {
  const _SezioneRicerca();

  @override
  Widget build(BuildContext context) {
    final dati = DatiScope.di(context);
    final tema = Theme.of(context).textTheme;
    final i = dati.impostazioni;
    final conChiave = i.chiaveTavily.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _TitoloSezione(
          'Ricerca prezzi',
          'Cerca sul web i prezzi di mercato (Tavily, gratis). Parte solo '
              'quando premi "Cerca prezzi" o se accendi l\'aggiornamento.',
        ),
        _Gruppo(
          righe: [
            _RigaValore(
              chiave: const Key('riga-chiave'),
              nome: 'Chiave Tavily',
              valore: conChiave ? 'Inserita' : 'Non inserita',
              onTap: () => modificaChiaveTavily(context),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aggiorna ogni settimana',
                          style: tema.titleMedium,
                        ),
                        Text(
                          conChiave
                              ? 'Solo le forbici trovate dal web; quelle scritte '
                                    'a mano non si toccano. Parte quando apri l\'app.'
                              : 'Prima inserisci la chiave.',
                          style: tema.bodyMedium?.copyWith(
                            color: ColoriLaguna.testoSecondario,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    key: const Key('interruttore-aggiorna-prezzi'),
                    value: i.aggiornaPrezzi && conChiave,
                    onChanged: conChiave
                        ? (acceso) => dati.salvaImpostazioni(
                            i.copyWith(aggiornaPrezzi: acceso),
                          )
                        : null,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ricerche questo mese',
                      style: tema.titleMedium,
                    ),
                  ),
                  Text(
                    '${dati.ricercheDelMese} su ${StatoDati.limiteRicercheMese}',
                    key: const Key('ricerche-del-mese'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
