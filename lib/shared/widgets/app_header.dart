import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/theme/pulso_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import 'pulso_logo.dart';

/// Cabeçalho das abas: território + data do último dado + acesso a Configurações.
class AppHeader extends ConsumerWidget implements PreferredSizeWidget {
  const AppHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latest = ref.watch(reservoirProvider).valueOrNull?.data.latest.date;
    final text = Theme.of(context).textTheme;
    return AppBar(
      titleSpacing: PulsoSpacing.screen,
      title: Row(
        children: [
          const PulsoMark(size: 30),
          const SizedBox(width: PulsoSpacing.md12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RMSP · Sistema Cantareira', style: text.titleMedium, overflow: TextOverflow.ellipsis),
                if (latest != null)
                  Text(
                    'Dados até ${Fmt.date(latest)}',
                    style: text.bodyMedium?.copyWith(color: context.pulso.muted),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Configurações e privacidade',
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => context.pushNamed(Routes.settings),
        ),
        const SizedBox(width: PulsoSpacing.sm),
      ],
    );
  }
}
