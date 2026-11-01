import 'package:flutter/material.dart';

import '../modelli/cliente.dart';
import '../modelli/tipi.dart';
import '../servizi/stato_dati.dart';
import '../tema/colori.dart';
import '../widget/carta_vetro.dart';
import '../widget/passo_guidato.dart';
import 'bozza_lavoro.dart';
import 'foglio_cliente.dart';
import 'nuovo_tempo.dart';

/// Passo 2 di "Nuovo lavoro": per chi è? Lo sconto lo decide la relazione.
class PassoChi extends StatelessWidget {
  const PassoChi({super.key, required this.bozza});

  final BozzaLavoro bozza;

  static const _colori = [
    Color(0xFF0F72A8),
    Color(0xFFC44A22),
    Color(0xFF5A8F2A),
    Color(0xFF6B5B95),
    Color(0xFFB36B00),
  ];

  void _avanti(BuildContext context, BozzaLavoro b) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => PassoTempo(bozza: b)));
  }

  @override
  Widget build(BuildContext context) {
    final dati = DatiScope.di(context);
    final tema = Theme.of(context).textTheme;
    // I più recenti per primi
    final clienti = [...dati.clienti]
      ..sort((a, b) => b.creatoIl.compareTo(a.creatoIl));

    String sottoDi(Cliente c) {
      final sconto = dati.parametri.sconto(c.relazione);
      final chi = c.relazione == Relazione.nuovo
          ? 'Cliente nuovo'
          : c.relazione.breve;
      return sconto == 0 ? '$chi · prezzo pieno' : '$chi · sconto $sconto%';
    }

    Widget riga({
      required Widget avatar,
      required String nome,
      required String sotto,
      required VoidCallback onTap,
      Key? chiave,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CartaVetro(
        key: chiave,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: onTap,
        child: Row(
          children: [
            avatar,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nome, style: tema.titleLarge),
                  Text(
                    sotto,
                    style: tema.labelMedium?.copyWith(
                      fontSize: 15,
                      color: ColoriLaguna.testoSecondario,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return PassoGuidato(
      titolo: 'Per chi è?',
      sottotitolo: 'Lo sconto lo scelgo io, in base a chi è.',
      passo: 2,
      figli: [
        for (final c in clienti)
          riga(
            chiave: Key('chi-${c.nome}'),
            avatar: Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _colori[c.nome.hashCode.abs() % _colori.length],
              ),
              child: Text(
                c.nome.isEmpty ? '?' : c.nome.characters.first.toUpperCase(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            nome: c.nome,
            sotto: sottoDi(c),
            onTap: () => _avanti(
              context,
              bozza.copyWith(clienteId: () => c.id, relazione: c.relazione),
            ),
          ),
        riga(
          chiave: const Key('chi-nuova'),
          avatar: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: ColoriLaguna.testoSecondario, width: 2),
            ),
            child: const Icon(Icons.add_rounded, size: 28),
          ),
          nome: 'Una persona nuova',
          sotto: 'Ci metti nome e relazione',
          onTap: () async {
            final nuova = await modificaCliente(context);
            if (nuova != null && context.mounted) {
              _avanti(
                context,
                bozza.copyWith(
                  clienteId: () => nuova.id,
                  relazione: nuova.relazione,
                ),
              );
            }
          },
        ),
        Align(
          child: TextButton(
            key: const Key('chi-nessuno'),
            onPressed: () => _avanti(
              context,
              bozza.copyWith(clienteId: () => null, relazione: Relazione.nuovo),
            ),
            child: const Text('Senza cliente'),
          ),
        ),
      ],
    );
  }
}
