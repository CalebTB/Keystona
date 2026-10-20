import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/core/router/app_shell.dart';
import 'package:keystona/core/theme/aurora_sizes.dart';
import 'package:keystona/core/widgets/confirm_dialog.dart';
import 'package:keystona/core/widgets/empty_state.dart';
import 'package:keystona/core/widgets/error_view.dart';
import 'package:keystona/core/widgets/loading_skeleton_card.dart';
import 'package:keystona/core/widgets/offline_banner.dart';
import 'package:keystona/core/widgets/snackbar_service.dart';
import 'package:keystona/core/widgets/status_badge.dart';
import 'package:keystona/services/providers/service_providers.dart';

import '../support/responsive_harness.dart';

const _long =
    'Keep the papers that protect your home in one place, and get a heads-up '
    'before anything expires.';

class _Snack extends StatelessWidget {
  const _Snack();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => SnackbarService.showUndo(
            context,
            message: 'Washer deleted',
            subtitle: 'Warranty kept in Docs. Undo within 5 seconds.',
            onUndo: () {},
          ),
          child: const Text('show'),
        ),
      ),
    );
  }
}

void main() {
  testResponsive(
    'AppTabBar',
    () => Scaffold(
      body: const SizedBox.expand(),
      bottomNavigationBar: AppTabBar(currentIndex: 3, onTap: (_) {}),
    ),
  );

  testWidgets('AppTabBar meets height, touch target and tap callback',
      (tester) async {
    var tapped = -1;
    await pumpScreen(
      tester,
      () => Scaffold(
        bottomNavigationBar: AppTabBar(currentIndex: 0, onTap: (i) => tapped = i),
      ),
      viewport: kViewports[1],
    );
    final size = tester.getSize(find.byType(AppTabBar));
    expect(size.height, greaterThanOrEqualTo(AuroraSizes.tabBarHeight));
    expect(
      tester.getSize(find.text('Docs').first).height,
      greaterThan(0),
    );
    await tester.tap(find.text('Tasks'));
    expect(tapped, 2);
  });

  testResponsive(
    'EmptyState with actions',
    () => const Scaffold(
      body: EmptyState(
        icon: Icons.description_outlined,
        title: 'Your vault is ready',
        subtitle: _long,
        actionLabel: 'Add a document',
        onAction: _noop,
        accent: true,
        secondaryLabel: 'Scan with camera',
        onSecondary: _noop,
      ),
    ),
  );

  testResponsive(
    'EmptyStateHero',
    () => const Scaffold(
      body: EmptyStateHero(
        icon: Icons.home_outlined,
        title: 'Welcome',
        subtitle: _long,
        actionLabel: 'Start',
        onAction: _noop,
      ),
    ),
  );

  testResponsive(
    'EmptyStateCta',
    () => const Scaffold(
      body: SingleChildScrollView(
        child: EmptyStateCta(
          icon: Icons.add,
          title: 'Add your first system',
          subtitle: _long,
          actionLabel: 'Add system',
          onAction: _noop,
        ),
      ),
    ),
  );

  testResponsive(
    'ErrorView full',
    () => const Scaffold(
      body: ErrorView(
        title: 'We couldn’t load your documents',
        message: 'Your files are safe. Check your connection, or give it '
            'another try.',
        onRetry: _noop,
        emergencyLinkLabel: 'Need Emergency? It works offline',
        onEmergency: _noop,
      ),
    ),
  );

  testResponsive(
    'ErrorView message only',
    () => const Scaffold(body: ErrorView(message: 'Something went wrong.')),
  );

  testResponsive(
    'OfflineBanner',
    () => const Scaffold(
      body: Column(children: [OfflineBanner(lastSynced: '2:14 pm')]),
    ),
    wrap: (child) => ProviderScope(
      overrides: [
        isOnlineProvider.overrideWith((ref) => Stream.value(false)),
      ],
      child: child,
    ),
  );

  testResponsive(
    'StatusBadge variants',
    () => Scaffold(
      body: Wrap(
        children: [
          StatusBadge.active('On track'),
          StatusBadge.success('Done Nov 6'),
          StatusBadge.overdue('9 days behind'),
          StatusBadge.warning('\$1,740 left'),
          StatusBadge.neutral('Draft'),
        ],
      ),
    ),
  );

  testResponsive(
    'LoadingSkeletonCard',
    () => Scaffold(
      body: ListView(
        children: const [
          LoadingSkeletonCard(height: AuroraSizes.buttonHeightLg),
          LoadingSkeletonCard(height: AuroraSizes.buttonHeight, width: AuroraSizes.switchWidth),
        ],
      ),
    ),
  );

  testResponsive('Snackbar launcher', _Snack.new);

  for (final viewport in activeViewports) {
    for (final scale in scalesFor(viewport)) {
      testWidgets('Snackbar with Undo @ ${viewport.name}, text x$scale',
          (tester) async {
        await pumpScreen(tester, _Snack.new, viewport: viewport, textScale: scale);
        await tester.tap(find.text('show'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('Washer deleted'), findsOneWidget);
        final undo = tester.getSize(find.widgetWithText(TextButton, 'Undo'));
        expect(undo.height, greaterThanOrEqualTo(AuroraSizes.minTouch));
        expect(tester.takeException(), isNull);
      });

      testWidgets('ConfirmDialog @ ${viewport.name}, text x$scale',
          (tester) async {
        await pumpScreen(
          tester,
          () => Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => ConfirmDialog.show(
                  context,
                  title: 'Delete the washer?',
                  message: 'This also removes what’s attached to it.',
                  confirmLabel: 'Delete washer',
                  onConfirm: () {},
                  details: const Text('2 reminders · 3 photos · Service history'),
                ),
                child: const Text('open'),
              ),
            ),
          ),
          viewport: viewport,
          textScale: scale,
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(find.text('Delete the washer?'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('ConfirmDialog returns true on confirm and runs callback',
      (tester) async {
    bool? result;
    var confirmed = false;
    await pumpScreen(
      tester,
      () => Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await ConfirmDialog.show(
                context,
                title: 'Delete?',
                message: 'Gone.',
                confirmLabel: 'Delete',
                onConfirm: () => confirmed = true,
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
      viewport: kViewports[1],
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
    expect(confirmed, isTrue);
  });
}

void _noop() {}
