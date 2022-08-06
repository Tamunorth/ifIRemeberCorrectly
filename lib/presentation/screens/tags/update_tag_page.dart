import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iirc/core.dart';
import 'package:iirc/domain.dart';

import '../../utils.dart';
import '../../widgets.dart';
import 'providers/tag_provider.dart';
import 'tag_entry_form.dart';

class UpdateTagPage extends StatelessWidget {
  const UpdateTagPage({super.key, required this.tag});

  static PageRoute<void> route({required TagModel tag}) {
    return MaterialPageRoute<void>(builder: (_) => UpdateTagPage(tag: tag));
  }

  final TagModel tag;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: Text(context.l10n.updateTagCaption),
      ),
      body: TagEntryForm(
        initialValue: TagEntryData(
          title: tag.title,
          description: tag.description,
          color: tag.color,
        ),
        type: TagEntryType.update,
        onSaved: _onSubmit(context),
      ),
    );
  }

  TagEntryValueSaved _onSubmit(BuildContext context) {
    final AppSnackBar snackBar = context.snackBar;
    final L10n l10n = context.l10n;
    return (WidgetRef ref, TagEntryData data) async {
      try {
        snackBar.loading();

        await ref.read(tagProvider).update(UpdateTagData(
              id: tag.id,
              path: tag.path,
              title: data.title,
              description: data.description,
              color: data.color,
            ));

        snackBar.success(l10n.successfulMessage);
        return Navigator.pop(context);
      } catch (error, stackTrace) {
        AppLog.e(error, stackTrace);
        snackBar.error(l10n.genericErrorMessage);
      } finally {
        snackBar.hide();
      }
    };
  }
}
