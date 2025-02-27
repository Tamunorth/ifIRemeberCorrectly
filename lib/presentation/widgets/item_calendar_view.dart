import 'dart:collection';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models.dart';
import '../theme.dart';

DateTime get _kToday => clock.now();
final DateTime _kEmptyDate = DateTime(0);

class ItemCalendarViewController with ChangeNotifier {
  ItemCalendarViewController({
    @visibleForTesting this.height = 324,
    DateTime? date,
  })  : _selectedDate = date ?? _kEmptyDate,
        _focusedDay = date ?? _kToday;

  final double height;
  final double weekDayHeight = kToolbarHeight * .75;

  DateTime get selectedDate => _selectedDate;
  DateTime _selectedDate;

  @visibleForTesting
  set selectedDate(DateTime date) {
    if (_selectedDate == date) {
      return;
    }
    _selectedDate = date;
    notifyListeners();
  }

  DateTime get focusedDay => _focusedDay;
  DateTime _focusedDay;

  @visibleForTesting
  set focusedDay(DateTime date) {
    if (_focusedDay == date) {
      return;
    }
    _focusedDay = date;
    notifyListeners();
  }

  @visibleForTesting
  bool get forcedUpdate => _forcedUpdate;
  bool _forcedUpdate = false;

  @visibleForTesting
  void forceUpdate(DateTime date) {
    _forcedUpdate = true;
    selectedDate = date;
  }

  bool get hasSelectedDate => _isSameMonth(selectedDate, focusedDay);

  List<ItemViewModel> get items => hasSelectedDate ? getItemsForDay(selectedDate) : getItemsForMonth(focusedDay);

  final LinkedHashMap<DateTime, List<ItemViewModel>> _items = LinkedHashMap<DateTime, List<ItemViewModel>>(
    equals: isSameDay,
    hashCode: (DateTime key) => key.day * 1000000 + key.month * 10000 + key.year,
  );

  final LinkedHashMap<DateTime, List<DateTime>> _itemsByMonth = LinkedHashMap<DateTime, List<DateTime>>(
    equals: _isSameMonth,
    hashCode: (DateTime key) => 1000000 + key.month * 10000 + key.year,
  );

  @visibleForTesting
  void onFocusDayChanged(DateTime date) => focusedDay = date;

  @visibleForTesting
  void onSelectedDayChanged(DateTime date) {
    onFocusDayChanged(date);
    forceUpdate(date);
  }

  void today() => onSelectedDayChanged(_kToday);

  void clearSelection() {
    onFocusDayChanged(DateTime(focusedDay.year, focusedDay.month));
    forceUpdate(_kEmptyDate);
  }

  @visibleForTesting
  void reset() {
    _forcedUpdate = false;
  }

  @visibleForTesting
  void populate(ItemViewModelList items) {
    _items.clear();
    _itemsByMonth.clear();
    for (final ItemViewModel item in items) {
      final DateTime date = item.date;
      _items[date] = <ItemViewModel>[...?_items[date], item];
      _itemsByMonth[date] = <DateTime>[...?_itemsByMonth[date], date];
    }
  }

  @visibleForTesting
  List<ItemViewModel> getItemsForDay(DateTime day) => _items[day] ?? <ItemViewModel>[];

  @visibleForTesting
  List<ItemViewModel> getItemsForMonth(DateTime month) {
    final List<DateTime> dates = _itemsByMonth[month] ?? <DateTime>[];
    return <ItemViewModel>{
      for (final DateTime date in dates) ...getItemsForDay(date),
    }.toList(growable: false);
  }
}

class ItemCalendarView extends StatefulWidget {
  const ItemCalendarView({
    super.key,
    required this.controller,
    required this.items,
  });

  final ItemCalendarViewController controller;
  final ItemViewModelList items;

  @override
  State<ItemCalendarView> createState() => _ItemCalendarViewState();
}

class _ItemCalendarViewState extends State<ItemCalendarView> {
  @override
  void initState() {
    super.initState();

    widget.controller
      ..populate(widget.items)
      ..addListener(_forceUpdate);
  }

  @override
  void didUpdateWidget(covariant ItemCalendarView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!listEquals(widget.items, oldWidget.items)) {
      widget.controller.populate(widget.items);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_forceUpdate);

    super.dispose();
  }

  void _forceUpdate() {
    if (widget.controller.forcedUpdate) {
      setState(() => widget.controller.reset());
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = context.theme;

    final TextStyle dayOfWeekTextStyle = theme.textTheme.labelSmall!.copyWith(
      color: theme.colorScheme.calenderViewColor,
      fontWeight: AppFontWeight.semibold,
    );

    return SliverPersistentHeader(
      delegate: _CustomSliverPersistentHeader(
        height: widget.controller.height,
        color: theme.colorScheme.surface,
        child: TableCalendar<ItemViewModel>(
          calendarFormat: CalendarFormat.month,
          startingDayOfWeek: StartingDayOfWeek.sunday,
          currentDay: _kToday,
          daysOfWeekHeight: kToolbarHeight * .75,
          headerVisible: false,
          sixWeekMonthsEnforced: true,
          daysOfWeekStyle: DaysOfWeekStyle(
            decoration: BoxDecoration(
              color: theme.colorScheme.calenderViewHeaderContainer,
            ),
            weekdayStyle: dayOfWeekTextStyle,
            weekendStyle: dayOfWeekTextStyle,
            dowTextFormatter: (DateTime day, dynamic locale) => DateFormat.E(locale).format(day).toUpperCase(),
          ),
          shouldFillViewport: true,
          firstDay: _kEmptyDate,
          lastDay: DateTime(_kToday.year + 2),
          selectedDayPredicate: (DateTime day) => isSameDay(widget.controller.selectedDate, day),
          onPageChanged: widget.controller.onFocusDayChanged,
          calendarBuilders: CalendarBuilders<ItemViewModel>(
            prioritizedBuilder: (BuildContext context, DateTime date, DateTime focusedDay) {
              final bool isSelected = isSameDay(date, focusedDay);
              final bool isToday = isSameDay(date, _kToday) && !isSelected;
              final bool isDisabled = date.month != focusedDay.month;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: isToday
                      ? theme.colorScheme.inverseSurface
                      : isSelected
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                  borderRadius: AppBorderRadius.c4,
                ),
                child: Center(
                  child: Text(
                    '${date.day}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: isDisabled ? AppFontWeight.regular : AppFontWeight.semibold,
                      color: isDisabled
                          ? theme.appTheme.hintColor.shade400
                          : isToday
                              ? theme.colorScheme.onInverseSurface
                              : isSelected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.inverseSurface,
                    ),
                  ),
                ),
              );
            },
            singleMarkerBuilder: (BuildContext context, DateTime day, ItemViewModel item) => _ItemMarker(
              key: ObjectKey(item.tag),
              tag: item.tag,
              isSelected: isSameDay(day, widget.controller.selectedDate),
            ),
          ),
          focusedDay: widget.controller.focusedDay,
          eventLoader: widget.controller.getItemsForDay,
          onDaySelected: (DateTime selectedDay, _) => widget.controller.onSelectedDayChanged(selectedDay),
        ),
      ),
    );
  }
}

class _ItemMarker extends StatelessWidget {
  const _ItemMarker({super.key, required this.isSelected, required this.tag});

  final bool isSelected;
  final TagViewModel tag;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = context.theme;

    return AnimatedContainer(
      duration: kThemeAnimationDuration,
      margin: const EdgeInsets.only(right: 2.0),
      constraints: BoxConstraints.tight(const Size.square(6)),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? theme.colorScheme.onInverseSurface : tag.backgroundColor,
        border: Border.all(color: tag.foregroundColor, width: isSelected ? 0 : .5),
      ),
    );
  }
}

extension CalendarViewColorSchemeExtensions on ColorScheme {
  Color get calenderViewHeaderContainer => brightness == Brightness.dark ? secondaryContainer : inverseSurface;

  List<Color> get calendarViewHeaderGradient => brightness == Brightness.dark
      ? List<Color>.filled(2, mutedBackground)
      : const <Color>[Colors.purpleAccent, Colors.blueAccent];

  Color get calenderViewColor => Colors.white;
}

class _CustomSliverPersistentHeader extends SliverPersistentHeaderDelegate {
  const _CustomSliverPersistentHeader({
    required this.height,
    required this.color,
    required this.child,
  });

  final double height;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context, _, __) => Material(
        color: color,
        elevation: 5,
        shadowColor: context.theme.shadowColor,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: child,
        ),
      );

  @override
  double get maxExtent => minExtent;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant _CustomSliverPersistentHeader oldDelegate) =>
      height != oldDelegate.height || color != oldDelegate.color || child != oldDelegate.child;
}

bool _isSameMonth(DateTime? a, DateTime? b) => a?.year == b?.year && a?.month == b?.month;
