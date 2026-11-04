import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'esportazione.dart';

/// Esportazione vera: galleria (pacchetto gal) e condivisione di Android
/// (share_plus). Niente servizi esterni, niente costi.
class EsportazioneReale implements ServizioEsportazione {
  @override
  Future<bool> salvaInGalleria(Uint8List png, String nome) async {
    try {
      // Il permesso lo chiede il pacchetto, se serve
      await Gal.putImageBytes(png, name: nome, album: 'QuantoValgo');
      return true;
    } on GalException catch (e) {
      debugPrint('Immagine non salvata: ${e.type}');
      return false;
    } catch (e) {
      debugPrint('Immagine non salvata: $e');
      return false;
    }
  }

  @override
  Future<void> condividi(Uint8List png, String nome, {String? testo}) async {
    // Android condivide file veri: si scrive il PNG in una cartella temporanea
    final cartella = await getTemporaryDirectory();
    final file = File('${cartella.path}/$nome.png');
    await file.writeAsBytes(png, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        text: testo,
        title: nome,
      ),
    );
  }
}
