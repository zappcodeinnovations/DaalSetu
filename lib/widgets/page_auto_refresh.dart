import 'dart:async';

import 'package:flutter/material.dart';

final pageRefreshRouteObserver = RouteObserver<ModalRoute<dynamic>>();

/// Polls only the visible page, without replacing its content or scroll state.
class PageAutoRefresh extends StatefulWidget {
  const PageAutoRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.interval = const Duration(seconds: 10),
    this.tabIndex,
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final Duration interval;
  final int? tabIndex;

  @override
  State<PageAutoRefresh> createState() => _PageAutoRefreshState();
}

class _PageAutoRefreshState extends State<PageAutoRefresh>
    with WidgetsBindingObserver, RouteAware {
  Timer? _timer;
  ModalRoute<dynamic>? _route;
  TabController? _tabs;
  bool _refreshing = false;
  bool _visible = false;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
    _timer = Timer.periodic(widget.interval, (_) => _refresh());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (_route != route) {
      pageRefreshRouteObserver.unsubscribe(this);
      _route = route;
      if (route != null) pageRefreshRouteObserver.subscribe(this, route);
    }
    final tabs = widget.tabIndex == null
        ? null
        : DefaultTabController.maybeOf(context);
    if (_tabs != tabs) {
      _tabs?.removeListener(_visibilityChanged);
      _tabs = tabs;
      _tabs?.addListener(_visibilityChanged);
    }
    _visibilityChanged();
  }

  void _visibilityChanged() {
    final visible =
        TickerMode.valuesOf(context).enabled &&
        (widget.tabIndex == null || _tabs?.index == widget.tabIndex);
    final becameVisible = visible && !_visible;
    _visible = visible;
    if (becameVisible) {
      // Run after build; GetX controllers may already be doing their first load.
      WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    }
  }

  Future<void> _refresh() async {
    if (!mounted ||
        !_foreground ||
        !_visible ||
        _refreshing ||
        (_route != null && !_route!.isCurrent)) {
      return;
    }
    _refreshing = true;
    try {
      await widget.onRefresh();
    } catch (error) {
      // Keep the last successful data; manual refresh retains its error UI.
      debugPrint('Page auto-refresh failed: $error');
    } finally {
      _refreshing = false;
    }
  }

  @override
  void didPopNext() => _refresh();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) _refresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabs?.removeListener(_visibilityChanged);
    pageRefreshRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
