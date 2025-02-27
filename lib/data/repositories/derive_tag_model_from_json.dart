import 'package:clock/clock.dart';

import '../../domain/models/tag.dart';
import '../network/firebase/models.dart';
import 'derive_date_from_timestamp.dart';

Future<TagModel> deriveTagModelFromJson(String id, String path, DynamicMap data) async => TagModel(
      id: id,
      path: path,
      title: data['title'] as String,
      description: data['description'] as String,
      color: data['color'] as int,
      createdAt: data['createdAt'] != null ? deriveDateFromTimestamp(data['createdAt'] as CloudTimestamp) : clock.now(),
      updatedAt: data['updatedAt'] != null ? deriveDateFromTimestamp(data['updatedAt'] as CloudTimestamp) : null,
    );
