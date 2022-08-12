import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iirc/core.dart';
import 'package:iirc/domain.dart';

import '../../constants/app_routes.dart';
import '../../state.dart';
import '../calendar/calendar_page.dart';
import '../insights/insights_page.dart';
import '../items/create_item_page.dart';
import '../items/items_page.dart';
import '../more/more_page.dart';
import 'menu_page_item_provider.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  static PageRoute<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => const MenuPage(),
      settings: const RouteSettings(name: AppRoutes.menu),
    );
  }

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> with SingleTickerProviderStateMixin {
  static const Key dataViewKey = Key('dataViewKey');
  late final TabController tabController = TabController(
    vsync: this,
    length: MenuPageItem.values.length,
    initialIndex: MenuPageItem.defaultPage.index,
  );

  @override
  Widget build(BuildContext context) => ProviderScope(
        overrides: <Override>[
          menuPageItemProvider.overrideWithValue(tabController),
        ],
        child: Consumer(
          builder: (BuildContext context, WidgetRef ref, _) => _MenuPageDataView(
            key: dataViewKey,
            analytics: ref.read(registryProvider).get(),
            controller: ref.read(menuPageItemProvider),
          ),
        ),
      );
}

class _MenuPageDataView extends StatefulWidget {
  const _MenuPageDataView({super.key, required this.analytics, required this.controller});

  final Analytics analytics;
  final TabController controller;

  @override
  State<_MenuPageDataView> createState() => _MenuPageDataViewState();
}

class _MenuPageDataViewState extends State<_MenuPageDataView> {
  Map<MenuPageItem, _TabRouteView> get _tabRouteViews => <MenuPageItem, _TabRouteView>{
        MenuPageItem.items: _TabRouteView(
          L10n.current.itemsCaption,
          const Icon(Icons.list_outlined),
          const ItemsPage(key: PageStorageKey<String>('items')),
        ),
        MenuPageItem.calendar: _TabRouteView(
          L10n.current.calendarCaption,
          const Icon(Icons.calendar_today_outlined),
          const CalendarPage(key: PageStorageKey<String>('calendar')),
        ),
        MenuPageItem.insights: _TabRouteView(
          L10n.current.insightsCaption,
          const Icon(Icons.insights_outlined),
          const InsightsPage(key: PageStorageKey<String>('insights')),
        ),
        MenuPageItem.more: _TabRouteView(
          L10n.current.moreCaption,
          const Icon(Icons.more_horiz),
          const MorePage(key: PageStorageKey<String>('more')),
        ),
      };

  late final Map<MenuPageItem, GlobalKey> _destinationKeys = <MenuPageItem, GlobalKey>{
    for (MapEntry<MenuPageItem, _TabRouteView> item in _tabRouteViews.entries)
      item.key: GlobalKey(debugLabel: item.key.toString()),
  };

  int get currentIndex => widget.controller.index;

  @override
  void initState() {
    super.initState();

    widget.controller.addListener(_tabAnalyticLogger);
    _tabAnalyticLogger();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_tabAnalyticLogger);

    super.dispose();
  }

  void _tabAnalyticLogger() =>
      widget.analytics.setCurrentScreen('${AppRoutes.menu}/${MenuPageItem.values[currentIndex]}');

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: ValueListenableBuilder<double>(
        valueListenable: widget.controller.animation!,
        builder: (BuildContext context, double value, Widget? child) => Stack(
          children: <Widget>[
            for (MapEntry<MenuPageItem, _TabRouteView> item in _tabRouteViews.entries)
              Positioned(
                left: (item.key.index - value) * width,
                bottom: 0,
                top: 0,
                width: width,
                child: KeyedSubtree(
                  key: _destinationKeys[item.key],
                  child: Material(
                    type: MaterialType.transparency,
                    child: _tabRouteViews[item.key]!.widget,
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: widget.controller,
        builder: (BuildContext context, _) => BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: currentIndex,
          onTap: (int index) => widget.controller.navigateToItem(MenuPageItem.values[index]),
          items: <BottomNavigationBarItem>[
            for (final _TabRouteView item in _tabRouteViews.values)
              BottomNavigationBarItem(icon: item.icon, label: item.title),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: widget.controller,
        builder: (BuildContext context, _) {
          final MenuPageItem menuItem = MenuPageItem.values[currentIndex];
          final Route<void> Function(Object?)? routeBuilder = menuItem.floatingActionButtonRouteBuilder;

          return AnimatedScale(
            scale: routeBuilder != null ? 1 : 0,
            duration: const Duration(milliseconds: 250),
            child: Consumer(
              builder: (BuildContext context, WidgetRef ref, _) => FloatingActionButton(
                onPressed: () => Navigator.of(context).push<void>(
                  routeBuilder!(ref.read(calendarStateProvider)),
                ),
                child: const Icon(Icons.add_outlined),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TabRouteView {
  const _TabRouteView(this.title, this.icon, this.widget);

  final String title;
  final Widget icon;
  final Widget widget;
}

extension on MenuPageItem {
  Route<void> Function(Object? param)? get floatingActionButtonRouteBuilder {
    switch (this) {
      case MenuPageItem.calendar:
        return (Object? date) {
          if (date is! DateTime) {
            throw ArgumentError('Expected a DateTime');
          }
          return CreateItemPage.route(asModal: true, date: date);
        };
      case MenuPageItem.items:
        return (_) => CreateItemPage.route();
      case MenuPageItem.insights:
      case MenuPageItem.more:
      default:
        return null;
    }
  }
}
