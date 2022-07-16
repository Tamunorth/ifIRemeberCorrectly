import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iirc/screens.dart';
import 'package:mocktail/mocktail.dart';

import 'utils.dart';

void main() {
  testWidgets('Smoke test', (WidgetTester tester) async {
    final Finder menuPage = find.byType(MenuPage);

    when(() => mockRepositories.items.fetch()).thenAnswer((_) async* {});
    when(() => mockRepositories.tags.fetch()).thenAnswer((_) async* {});

    addTearDown(() => mockRepositories.reset());

    await tester.pumpWidget(createApp());

    await tester.pump();

    expect(find.byKey(const Key('TESTING')), findsOneWidget);
    expect(find.text('IIRC'), findsOneWidget);
    expect(menuPage, findsOneWidget);
    expect(find.byType(HomePage).descendantOf(menuPage), findsOneWidget);
    expect(find.byType(TagsPage).descendantOf(menuPage), findsOneWidget);
  });
}
