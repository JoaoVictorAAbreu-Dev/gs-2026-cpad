import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Copia o protocolo para a pessoa colar onde quiser (WhatsApp, e-mail, 156).
/// Funciona offline e não envia nada a terceiros.
class CopyProtocolButton extends StatelessWidget {
  const CopyProtocolButton({super.key, required this.protocol});
  final String protocol;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      icon: const Icon(Icons.copy_outlined),
      label: const Text('Copiar protocolo'),
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: protocol));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('Protocolo $protocol copiado.')));
      },
    );
  }
}
