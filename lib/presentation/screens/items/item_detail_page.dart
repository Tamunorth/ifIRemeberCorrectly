import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iirc/core.dart';
import 'package:iirc/domain.dart';
import 'package:intl/intl.dart';

import '../../constants/app_routes.dart';
import '../../models.dart';
import '../../state.dart';
import '../../theme.dart';
import '../../utils.dart';
import '../../widgets.dart';
import 'create_item_page.dart';
import 'providers/item_provider.dart';
import 'providers/selected_item_provider.dart';
import 'update_item_page.dart';

class ItemDetailPage extends StatefulWidget {
  const ItemDetailPage({super.key, required this.id});

  final String id;

  static PageRoute<void> route({required String id}) {
    return MaterialPageRoute<void>(
      builder: (_) => ItemDetailPage(id: id),
      settings: const RouteSettings(name: AppRoutes.itemDetail),
    );
  }

  @override
  State<ItemDetailPage> createState() => ItemDetailPageState();
}

@visibleForTesting
class ItemDetailPageState extends State<ItemDetailPage> {
  static const Key dataViewKey = Key('dataViewKey');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WillPopScope(
        onWillPop: () async {
          ScaffoldMessenger.of(context).removeCurrentMaterialBanner(reason: MaterialBannerClosedReason.dismiss);
          return true;
        },
        child: Consumer(
          builder: (BuildContext context, WidgetRef ref, Widget? child) =>
              ref.watch(selectedItemStateProvider(widget.id)).when(
                    data: (ItemViewModel item) => _SelectedItemDataView(
                      key: dataViewKey,
                      item: item,
                      analytics: ref.read(analyticsProvider),
                    ),
                    error: ErrorView.new,
                    loading: () => child!,
                  ),
          child: const LoadingView(),
        ),
      ),
    );
  }
}

class _SelectedItemDataView extends StatelessWidget {
  const _SelectedItemDataView({super.key, required this.item, required this.analytics});

  final ItemViewModel item;
  final Analytics analytics;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = context.theme;

    return CustomScrollView(
      slivers: <Widget>[
        CustomAppBar(
          title: Text(context.l10n.informationCaption),
          actions: <Widget>[
            IconButton(
              onPressed: () {
                analytics.log(AnalyticsEvent.buttonClick('create item: ${AppRoutes.itemDetail}'));
                Navigator.of(context).pushAndRemoveUntil(
                  CreateItemPage.route(asModal: true, tag: item.tag),
                  (Route<void> route) => route.settings.name == AppRoutes.tagDetail,
                );
              },
              icon: const Icon(Icons.redo_outlined),
              color: theme.colorScheme.onSurface,
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () {
                analytics.log(AnalyticsEvent.buttonClick('edit item: ${item.id}'));
                Navigator.of(context).push(UpdateItemPage.route(item: item));
              },
              icon: const Icon(Icons.edit_outlined),
              color: theme.colorScheme.onSurface,
            ),
            const SizedBox(width: 4),
            Consumer(
              builder: (BuildContext context, WidgetRef ref, _) => IconButton(
                onPressed: () async {
                  unawaited(analytics.log(AnalyticsEvent.buttonClick('delete item: ${item.id}')));
                  final bool isOk = await showErrorChoiceBanner(
                    context,
                    message: context.l10n.areYouSureAboutThisMessage,
                  );
                  if (isOk) {
                    _onDelete(context, ref);
                  }
                },
                icon: const Icon(Icons.delete_forever_outlined),
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(width: 2),
          ],
          asSliver: true,
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              <Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: TagColorLabel(
                    tag: item.tag,
                    variant: TagColorLabelVariant.large,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    DateFormat.yMMMEd().format(item.date),
                    style: theme.textTheme.subtitle2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  item.description,
                  style: theme.textTheme.headline6,
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  void _onDelete(BuildContext context, WidgetRef ref) async {
    final AppSnackBar snackBar = context.snackBar;
    final L10n l10n = context.l10n;
    try {
      snackBar.loading();

      await ref.read(itemProvider).delete(item.path);

      snackBar.success(l10n.successfulMessage);
      return Navigator.pop(context);
    } catch (error, stackTrace) {
      AppLog.e(error, stackTrace);
      snackBar.error(l10n.genericErrorMessage);
    } finally {
      snackBar.hide();
    }
  }
}
