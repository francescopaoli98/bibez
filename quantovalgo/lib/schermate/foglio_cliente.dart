import 'package:flutter/material.dart';

import '../modelli/cliente.dart';
import '../modelli/tipi.dart';
import '../servizi/stato_dati.dart';
import '../widget/campo_testo.dart';
import '../widget/foglio_laguna.dart';
import '../widget/pulsante_lucido.dart';
import '../widget/selettore_relazione.dart';
import '../widget/stile_lucido.dart';

/// Apre il foglio per aggiungere o modificare un cliente.
Future<void> modificaCliente(BuildContext context, {Cliente? esistente}) {
  return mostraFoglio<void>(
    context,
    titolo: esistente == null ? 'Nuovo cliente' : 'Modifica cliente',
    costruttore: (_) => _FormCliente(esistente: esistente),
  );
}

class _FormCliente extends StatefulWidget {
  const _FormCliente({this.esistente});

  final Cliente? esistente;

  @override
  State<_FormCliente> createState() => _FormClienteState();
}

class _FormClienteState extends State<_FormCliente> {
  late final _nome = TextEditingController(text: widget.esistente?.nome);
  late Relazione _relazione = widget.esistente?.relazione ?? Relazione.nuovo;
  String? _erroreNome;

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  void _salva() {
    final nome = _nome.text.trim();
    final dati = DatiScope.leggi(context);

    // Due clienti con lo stesso nome confonderebbero i lavori.
    final omonimo = dati.clientePerNome(nome);
    final errore = nome.isEmpty
        ? 'Scrivi il nome'
        : (omonimo != null && omonimo.id != widget.esistente?.id
              ? 'Esiste già un cliente con questo nome'
              : null);
    setState(() => _erroreNome = errore);
    if (errore != null) return;

    final vecchio = widget.esistente;
    dati.salvaCliente(
      Cliente(
        id: vecchio?.id ?? '',
        nome: nome,
        relazione: _relazione,
        creatoIl: vecchio?.creatoIl ?? DateTime.now(),
      ),
    );
    Navigator.of(context).pop();
  }

  Future<void> _elimina() async {
    final navigatore = Navigator.of(context);
    final dati = DatiScope.leggi(context);
    final conferma = await chiediConferma(
      context,
      titolo: 'Eliminare il cliente?',
      testo: '"${widget.esistente!.nome}" sparirà dall\'elenco.',
      etichettaConferma: 'Elimina',
    );
    if (!conferma) return;
    dati.eliminaCliente(widget.esistente!.id);
    navigatore.pop();
  }

  @override
  Widget build(BuildContext context) {
    final dati = DatiScope.di(context);
    final esistente = widget.esistente;
    // Si può eliminare solo se non ha lavori (altrimenti restano "orfani").
    final haLavori =
        esistente != null && dati.lavoriDelCliente(esistente.id).isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CampoTesto(
          key: const Key('campo-nome'),
          controller: _nome,
          etichetta: 'Nome',
          suggerimento: 'Es. Luca',
          errore: _erroreNome,
          maiuscole: TextCapitalization.words,
          azioneTastiera: TextInputAction.done,
        ),
        const SizedBox(height: 12),
        SelettoreRelazione(
          valore: _relazione,
          parametri: dati.parametri,
          onCambia: (r) => setState(() => _relazione = r),
        ),
        const SizedBox(height: 16),
        PulsanteLucido(
          etichetta: 'Salva',
          stile: StileLucido.verde,
          altezza: 56,
          onPressed: _salva,
        ),
        if (esistente != null) ...[
          const SizedBox(height: 10),
          PulsanteLucido(
            etichetta: haLavori ? 'Ha dei lavori: non eliminabile' : 'Elimina',
            icona: Icons.delete_outline_rounded,
            stile: StileLucido.rosso,
            onPressed: haLavori ? null : _elimina,
          ),
        ],
      ],
    );
  }
}
