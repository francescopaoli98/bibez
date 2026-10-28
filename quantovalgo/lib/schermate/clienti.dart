import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../logica/formato.dart';
import '../logica/mesi.dart';
import '../logica/pagamenti.dart';
import '../modelli/cliente.dart';
import '../servizi/stato_dati.dart';
import '../tema/colori.dart';
import '../widget/carta_vetro.dart';
import '../widget/pagina_secondaria.dart';
import '../widget/pulsante_lucido.dart';
import '../widget/riga_progetto.dart';
import '../widget/riquadro_da_incassare.dart';
import '../widget/sfera_lucida.dart';
import '../widget/stato_vuoto.dart';
import '../widget/stile_lucido.dart';
import 'foglio_cliente.dart';

/// Clienti: quanto pagano e in quanto tempo, i migliori, chi è in ritardo
/// (con un messaggio pronto da copiare) e l'elenco completo.
class ClientiPagina extends StatelessWidget {
  const ClientiPagina({super.key});

  @override
  Widget build(BuildContext context) {
    final dati = DatiScope.di(context);
    final tema = Theme.of(context).textTheme;
    final statistiche = dati.statisticheDeiClienti();
    final media = dati.giorniMediPerPagare;

    // I migliori: chi ha dato di più (solo se ha già pagato qualcosa)
    final migliori = [
      for (final s in statistiche)
        if (s.incassato > 0) s,
    ]..sort((a, b) => b.incassato.compareTo(a.incassato));
    final ritardatari = [
      for (final s in statistiche)
        if (s.ritardatario) s,
    ]..sort((a, b) => b.maxGiorniRitardo.compareTo(a.maxGiorniRitardo));

    return PaginaSecondaria(
      titolo: 'Clienti',
      sottotitolo: 'Chi ti porta di più e chi paga tardi',
      figli: [
        Row(
          children: [
            Expanded(
              child: _Numero(
                etichetta: 'Clienti',
                valore: '${dati.clienti.length}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Numero(
                etichetta: 'Pagano in media',
                valore: media == null ? '—' : giorniInTesto(media),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        RiquadroDaIncassare(dati: dati),
        if (migliori.isNotEmpty) ...[
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Text('I migliori', style: tema.titleLarge),
          ),
          const SizedBox(height: 8),
          for (final s in migliori.take(3)) ...[
            _RigaMigliore(statistiche: s),
            const SizedBox(height: 8),
          ],
        ],
        if (ritardatari.isNotEmpty) ...[
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Text('Ritardatari', style: tema.titleLarge),
          ),
          const SizedBox(height: 8),
          for (final s in ritardatari) ...[
            _RigaRitardatario(statistiche: s, dati: dati),
            const SizedBox(height: 8),
          ],
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: Text('Tutti i clienti', style: tema.titleLarge)),
            PulsanteLucido(
              etichetta: '+ Nuovo',
              onPressed: () => modificaCliente(context),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (dati.clienti.isEmpty)
          const StatoVuoto(
            icona: Icons.people_alt_rounded,
            titolo: 'Nessun cliente',
            testo: 'Si creano da soli con un nuovo lavoro, o con "+ Nuovo".',
          )
        else
          for (final c in dati.clienti) ...[
            _RigaCliente(cliente: c, dati: dati),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

/// `5 giorni`, `1 giorno` (la media si arrotonda).
String giorniInTesto(double giorni) {
  final n = giorni.round();
  return '$n ${n == 1 ? 'giorno' : 'giorni'}';
}

/// Un cliente tra i migliori: quanto ha pagato e in quanto tempo.
class _RigaMigliore extends StatelessWidget {
  const _RigaMigliore({required this.statistiche});

  final StatisticheCliente statistiche;

  @override
  Widget build(BuildContext context) {
    final s = statistiche;
    final tema = Theme.of(context).textTheme;
    return CartaVetro(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const IconaSfera(icona: Icons.star_rounded, stile: StileLucido.oro),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.cliente.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tema.titleMedium,
                ),
                Text(
                  s.giorniMedi == null
                      ? 'Ancora nessun pagamento'
                      : 'Paga in media in ${giorniInTesto(s.giorniMedi!)}',
                  style: tema.labelMedium?.copyWith(
                    color: ColoriLaguna.testoSecondario,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            euro(s.incassato),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: ColoriLaguna.positivo,
            ),
          ),
        ],
      ),
    );
  }
}

/// Un cliente in ritardo: quanto deve e un messaggio pronto da inviare.
class _RigaRitardatario extends StatelessWidget {
  const _RigaRitardatario({required this.statistiche, required this.dati});

  final StatisticheCliente statistiche;
  final StatoDati dati;

  /// "Ciao Luca, ti ricordo il pagamento di 300 € per «Spot» (scaduto il
  /// 10 ottobre 2026). Grazie!" — con più lavori, un elenco.
  String _messaggio() {
    final ora = dati.adesso();
    final righe = [
      for (final l in dati.lavoriDelCliente(statistiche.cliente.id))
        if (inRitardo(l, ora))
          '«${l.nome}»: ${euro(dati.importoDi(l))} (scaduto il ${dataLunga(l.scadenza!)})',
    ];
    final saluto = 'Ciao ${statistiche.cliente.nome}, ';
    if (righe.length == 1) {
      return '${saluto}ti ricordo il pagamento di ${righe.single}. Grazie!';
    }
    return '${saluto}ti ricordo questi pagamenti:\n${righe.map((r) => '• $r').join('\n')}\nGrazie!';
  }

  Future<void> _copia(BuildContext context) async {
    final messaggi = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: _messaggio()));
    messaggi
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Messaggio copiato: incollalo dove vuoi')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final s = statistiche;
    final tema = Theme.of(context).textTheme;
    return CartaVetro(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  s.cliente.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tema.titleMedium,
                ),
              ),
              Text(
                euro(s.importoInRitardo),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: ColoriLaguna.negativo,
                ),
              ),
            ],
          ),
          Text(
            '${s.lavoriInRitardo} ${s.lavoriInRitardo == 1 ? 'lavoro' : 'lavori'} in ritardo'
            ' · fino a ${s.maxGiorniRitardo} ${s.maxGiorniRitardo == 1 ? 'giorno' : 'giorni'}',
            style: tema.labelMedium?.copyWith(
              color: ColoriLaguna.testoSecondario,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          PulsanteLucido(
            etichetta: 'Copia promemoria',
            icona: Icons.copy_rounded,
            altezza: 44,
            onPressed: () => _copia(context),
          ),
        ],
      ),
    );
  }
}

class _Numero extends StatelessWidget {
  const _Numero({required this.etichetta, required this.valore});

  final String etichetta;
  final String valore;

  @override
  Widget build(BuildContext context) {
    return CartaVetro(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etichetta,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: ColoriLaguna.testoSecondario,
            ),
          ),
          Text(
            valore,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _RigaCliente extends StatelessWidget {
  const _RigaCliente({required this.cliente, required this.dati});

  final Cliente cliente;
  final StatoDati dati;

  @override
  Widget build(BuildContext context) {
    final lavori = dati.lavoriDelCliente(cliente.id);
    final totale = lavori.fold<double>(0, (somma, l) => somma + l.prezzoFinale);
    final sconto = dati.parametri.sconto(cliente.relazione);
    final tema = Theme.of(context).textTheme;

    return CartaVetro(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      onTap: () => modificaCliente(context, esistente: cliente),
      child: Row(
        children: [
          const IconaSfera(icona: Icons.person_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cliente.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tema.titleMedium,
                ),
                Text(
                  '${sconto == 0 ? cliente.relazione.breve : '${cliente.relazione.breve} −$sconto%'}'
                  ' · ${lavori.length} ${lavori.length == 1 ? 'lavoro' : 'lavori'}',
                  style: tema.labelMedium?.copyWith(
                    color: ColoriLaguna.testoSecondario,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (totale > 0) ...[
            const SizedBox(width: 8),
            Text(
              euro(totale),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: coloreImporto(totale),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
