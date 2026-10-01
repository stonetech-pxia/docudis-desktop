import 'package:docudis/anonymize/anonymize_service.dart';
import 'package:docudis/anonymize/engine/ner_model.dart';
import 'package:docudis/anonymize/input/text_extractor.dart';
import 'package:docudis/anonymize/providers.dart';
import 'package:docudis/anonymize/storage/record_store.dart';
import 'package:docudis/app.dart';
import 'package:docudis/preferences.dart';
import 'package:docudis/theme/clay_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// No model and no files: the shell is under test, not the engine.
class _NoModelService extends AnonymizeService {
  _NoModelService()
    : super(
        store: RecordStore(),
        extractor: TextExtractor(),
        dictionaryTerms: () async => const [],
        neverHideTerms: () async => const [],
        listOnly: () => false,
      );

  @override
  Future<NerModel?> nerModel() async => null;
}

Future<void> pumpApp(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({'app_locale': 'en'});
  final preferences = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        anonymizeServiceProvider.overrideWithValue(_NoModelService()),
        recordsProvider.overrideWith((ref) async => const []),
      ],
      child: const DocudisApp(),
    ),
  );
  await tester.pumpAndSettle();
}

int shownTab(WidgetTester tester) =>
    tester.widget<IndexedStack>(find.byType(IndexedStack).first).index!;

void main() {
  testWidgets('wide window uses the side bar and switches tabs', (
    tester,
  ) async {
    await pumpApp(tester, const Size(1100, 760));

    expect(find.byType(ClaySideNav), findsOneWidget);
    expect(find.byType(ClayNavBar), findsNothing);
    expect(shownTab(tester), 0);

    await tester.tap(
      find.descendant(
        of: find.byType(ClaySideNav),
        matching: find.text('History'),
      ),
    );
    await tester.pumpAndSettle();
    expect(shownTab(tester), 1);

    await tester.tap(
      find.descendant(
        of: find.byType(ClaySideNav),
        matching: find.text('Settings'),
      ),
    );
    await tester.pumpAndSettle();
    expect(shownTab(tester), 3);

    await tester.tap(
      find.descendant(
        of: find.byType(ClaySideNav),
        matching: find.text('Dictionary'),
      ),
    );
    await tester.pumpAndSettle();
    expect(shownTab(tester), 2);
  });

  testWidgets('narrow window narrows the side bar to icons', (tester) async {
    await pumpApp(tester, const Size(760, 600));

    final rail = tester.widget<ClaySideNav>(find.byType(ClaySideNav));
    expect(rail.compact, isTrue);
    expect(find.byType(ClayNavBar), findsNothing);

    await tester.tap(find.byTooltip('History'));
    await tester.pumpAndSettle();
    expect(shownTab(tester), 1);
  });

  testWidgets('resizing keeps the selected tab', (tester) async {
    await pumpApp(tester, const Size(1100, 760));
    await tester.tap(
      find.descendant(
        of: find.byType(ClaySideNav),
        matching: find.text('Settings'),
      ),
    );
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(760, 600);
    await tester.pumpAndSettle();

    expect(
      tester.widget<ClaySideNav>(find.byType(ClaySideNav)).compact,
      isTrue,
    );
    expect(shownTab(tester), 3);
  });
}
