import 'package:flutter/material.dart';

import '../servizi/accesso.dart';
import '../servizi/servizi_app.dart';
import '../tema/colori.dart';
import '../widget/carta_vetro.dart';
import '../widget/logo_sole.dart';
import '../widget/pulsante_lucido.dart';
import '../widget/sfondo_laguna.dart';

/// Schermata di accesso: un solo pulsante, "Accedi con Google".
class LoginPagina extends StatefulWidget {
  const LoginPagina({super.key});

  @override
  State<LoginPagina> createState() => _LoginPaginaState();
}

class _LoginPaginaState extends State<LoginPagina> {
  bool _inCorso = false;
  ErroreAccesso? _errore;

  Future<void> _accedi() async {
    setState(() {
      _inCorso = true;
      _errore = null;
    });
    try {
      await ServiziApp.di(context).accesso.accediConGoogle();
      // Se va bene, il "cancello" vede il nuovo utente e cambia schermata.
    } on ErroreAccesso catch (e) {
      if (mounted) setState(() => _errore = e);
    } finally {
      if (mounted) setState(() => _inCorso = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;

    return SfondoLaguna(
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LogoSole(dimensione: 88),
                  const SizedBox(height: 16),
                  Semantics(
                    header: true,
                    child: Text(
                      'QuantoValgo',
                      style: tema.headlineMedium?.copyWith(fontSize: 34),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Quanto valgo, quanto spendo, come sto',
                    textAlign: TextAlign.center,
                    style: tema.bodyLarge?.copyWith(
                      color: ColoriLaguna.testoSecondario,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: PulsanteLucido(
                      etichetta: _inCorso
                          ? 'Accesso in corso…'
                          : 'Accedi con Google',
                      icona: Icons.login_rounded,
                      altezza: 56,
                      onPressed: _inCorso ? null : _accedi,
                    ),
                  ),
                  if (_errore != null) ...[
                    const SizedBox(height: 16),
                    _CartaErrore(errore: _errore!),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'I tuoi dati restano nel tuo account Google e si vedono anche senza internet.',
                    textAlign: TextAlign.center,
                    style: tema.bodyMedium?.copyWith(
                      color: ColoriLaguna.testoSecondario,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CartaErrore extends StatelessWidget {
  const _CartaErrore({required this.errore});

  final ErroreAccesso errore;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: true, // il lettore di schermo legge l'errore appena compare
      child: CartaVetro(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: ColoriLaguna.negativo,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    errore.messaggio,
                    style: tema.bodyMedium?.copyWith(
                      color: ColoriLaguna.negativo,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            if (errore.dettagli != null) ...[
              const SizedBox(height: 8),
              // Testo tecnico, selezionabile per poterlo copiare e mandarlo
              SelectableText(
                errore.dettagli!,
                style: tema.labelMedium?.copyWith(
                  color: ColoriLaguna.testoSecondario,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
