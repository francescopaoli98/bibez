import 'package:flutter/material.dart';

import '../tema/colori.dart';
import '../widget/carta_vetro.dart';
import '../widget/sfondo_laguna.dart';

/// Mostrata se Firebase non parte (di solito manca google-services.json).
class ErroreAvvioPagina extends StatelessWidget {
  const ErroreAvvioPagina({super.key, required this.dettagli});

  final String dettagli;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    return SfondoLaguna(
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: CartaVetro(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Il cloud non è configurato', style: tema.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      'Manca il file google-services.json oppure non è valido. '
                      'Rifai la compilazione con il file giusto in android/app/.',
                      style: tema.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    SelectableText(
                      dettagli,
                      style: tema.labelMedium?.copyWith(
                        color: ColoriLaguna.testoSecondario,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
