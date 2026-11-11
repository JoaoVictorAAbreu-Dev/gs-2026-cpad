import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/alerts/presentation/alert_detail_screen.dart';
import '../features/alerts/presentation/alerts_screen.dart';
import '../features/home/home_screen.dart';
import '../features/indicators/indicators_screen.dart';
import '../features/map/map_screen.dart';
import '../features/onboarding/consent_screen.dart';
import '../features/reports/presentation/my_reports_screen.dart';
import '../features/reports/presentation/report_form_screen.dart';
import '../features/reports/presentation/report_success_screen.dart';
import '../features/settings/settings_controller.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/thresholds_screen.dart';
import 'shell.dart';

/// Nomes das rotas — use `context.goNamed(Routes.x)` em vez de strings soltas.
abstract final class Routes {
  static const home = 'home';
  static const indicators = 'indicators';
  static const map = 'map';
  static const alerts = 'alerts';
  static const alertDetail = 'alertDetail';
  static const settings = 'settings';
  static const thresholds = 'thresholds';
  static const consent = 'consent';
  static const myReports = 'myReports';
  static const newReport = 'newReport';
  static const reportSuccess = 'reportSuccess';
}

final _rootKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  // Lê só o campo que importa para o redirect; mudar tema não recria o router.
  final hasConsent = ref.watch(settingsProvider.select((s) => s.hasConsent));

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    redirect: (context, state) {
      final atConsent = state.matchedLocation == '/consentimento';
      if (!hasConsent && !atConsent) return '/consentimento';
      if (hasConsent && atConsent) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/consentimento',
        name: Routes.consent,
        builder: (context, state) => const ConsentScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/', name: Routes.home, builder: (context, state) => const HomeScreen()),
          ]),
          StatefulShellBranch(initialLocation: '/indicadores/recursos', routes: [
            GoRoute(
              path: '/indicadores/:aba',
              name: Routes.indicators,
              builder: (context, state) => IndicatorsScreen(
                tab: IndicatorTab.fromSlug(state.pathParameters['aba']),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/mapa', name: Routes.map, builder: (context, state) => const MapScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/alertas', name: Routes.alerts, builder: (context, state) => const AlertsScreen()),
          ]),
        ],
      ),
      // Telas empilhadas fora do shell (sem barra inferior).
      GoRoute(
        path: '/alertas/:id',
        name: Routes.alertDetail,
        parentNavigatorKey: _rootKey,
        builder: (context, state) => AlertDetailScreen(alertId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/ocorrencias',
        name: Routes.myReports,
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const MyReportsScreen(),
        routes: [
          GoRoute(
            path: 'nova',
            name: Routes.newReport,
            parentNavigatorKey: _rootKey,
            builder: (context, state) => ReportFormScreen(initialRegionId: state.uri.queryParameters['regiao']),
          ),
          GoRoute(
            path: ':protocol/enviada',
            name: Routes.reportSuccess,
            parentNavigatorKey: _rootKey,
            builder: (context, state) => ReportSuccessScreen(protocol: state.pathParameters['protocol']!),
          ),
        ],
      ),
      GoRoute(
        path: '/configuracoes',
        name: Routes.settings,
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'limiares',
            name: Routes.thresholds,
            parentNavigatorKey: _rootKey,
            builder: (context, state) => const ThresholdsScreen(),
          ),
        ],
      ),
    ],
  );
});
