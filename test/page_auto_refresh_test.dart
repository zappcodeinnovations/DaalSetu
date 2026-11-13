import 'dart:async';

import 'package:daalsetu/widgets/page_auto_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('polls visible empty pages and cancels on disposal', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: PageAutoRefresh(
          onRefresh: () async {
            calls++;
          },
          child: const Text('No offers'),
        ),
      ),
    );
    expect(calls, 1);
    await tester.pump(const Duration(seconds: 10));
    expect(calls, 2);
    expect(find.text('No offers'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 20));
    expect(calls, 2);
  });

  testWidgets('hidden bottom tabs stop polling and refresh when selected', (
    tester,
  ) async {
    var calls = 0;
    late StateSetter update;
    var active = false;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return TickerMode(
              enabled: active,
              child: PageAutoRefresh(
                onRefresh: () async {
                  calls++;
                },
                child: const Text('Contracts'),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 20));
    expect(calls, 0);
    update(() => active = true);
    await tester.pump();
    expect(calls, 1);
    update(() => active = false);
    await tester.pump();
    await tester.pump(const Duration(seconds: 20));
    expect(calls, 1);
  });

  testWidgets('pauses in background and refreshes on resume', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: PageAutoRefresh(
          onRefresh: () async {
            calls++;
          },
          child: const Text('Profile'),
        ),
      ),
    );
    expect(calls, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 20));
    expect(calls, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(calls, 2);
  });

  testWidgets('does not overlap slow requests and recovers after errors', (
    tester,
  ) async {
    var calls = 0;
    final pending = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: PageAutoRefresh(
          onRefresh: () async {
            calls++;
            if (calls == 1) await pending.future;
            if (calls == 2) throw Exception('offline');
          },
          child: const Text('Last successful offers'),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 30));
    expect(calls, 1);
    pending.complete();
    await tester.pump();
    await tester.pump(const Duration(seconds: 10));
    expect(calls, 2);
    expect(find.text('Last successful offers'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
    expect(calls, 3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('covered routes stop polling and refresh immediately on return', (
    tester,
  ) async {
    var calls = 0;
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        navigatorObservers: [pageRefreshRouteObserver],
        home: PageAutoRefresh(
          onRefresh: () async {
            calls++;
          },
          child: const Text('Offers'),
        ),
      ),
    );
    expect(calls, 1);
    unawaited(
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Edit offer')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 20));
    expect(calls, 1);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(calls, 2);
  });

  testWidgets('only selected offer tab refreshes', (tester) async {
    final calls = [0, 0];
    late TabController tabs;
    await tester.pumpWidget(
      MaterialApp(
        home: DefaultTabController(
          length: 2,
          child: Builder(
            builder: (context) {
              tabs = DefaultTabController.of(context);
              return Column(
                children: [
                  for (var i = 0; i < 2; i++)
                    PageAutoRefresh(
                      tabIndex: i,
                      onRefresh: () async {
                        calls[i]++;
                      },
                      child: Text('Tab $i'),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
    expect(calls, [1, 0]);
    tabs.index = 1;
    await tester.pump();
    expect(calls, [1, 1]);
    await tester.pump(const Duration(seconds: 10));
    expect(calls, [1, 2]);
  });
}
