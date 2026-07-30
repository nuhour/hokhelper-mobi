import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/widgets/app_list_footer.dart';

class _IncrementalList extends StatefulWidget {
  const _IncrementalList({required this.total});

  final int total;

  @override
  State<_IncrementalList> createState() => _IncrementalListState();
}

class _IncrementalListState extends State<_IncrementalList> {
  static const _pageSize = 20;
  int _visible = _pageSize;

  @override
  Widget build(BuildContext context) {
    final shown = _visible.clamp(0, widget.total);
    return ListView.builder(
      itemCount: shown + 1,
      itemBuilder: (context, index) {
        if (index == shown) {
          return AppListFooter(
            hasMore: shown < widget.total,
            onLoadMore: () => setState(() => _visible += _pageSize),
          );
        }
        return SizedBox(height: 60, child: Text('Item $index'));
      },
    );
  }
}

void main() {
  testWidgets('loads more when the footer scrolls into view', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: _IncrementalList(total: 50))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Item 0'), findsOneWidget);
    expect(find.text('Item 20'), findsNothing);

    await tester.drag(find.byType(ListView), const Offset(0, -1300));
    await tester.pumpAndSettle();

    expect(find.text('Item 20'), findsOneWidget);
  });

  testWidgets('shows the end label when everything is visible', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: _IncrementalList(total: 24))),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pumpAndSettle();

    expect(find.text('No more content'), findsOneWidget);
  });

  testWidgets('works at the end of a Column inside SingleChildScrollView', (
    tester,
  ) async {
    var loads = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    for (var index = 0; index < 20 + loads * 10; index++)
                      SizedBox(height: 60, child: Text('Row $index')),
                    AppListFooter(
                      hasMore: loads < 2,
                      onLoadMore: () => setState(() => loads += 1),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 页脚在首屏外：未触发加载。
    expect(loads, 0);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -900),
    );
    await tester.pumpAndSettle();
    expect(loads, greaterThan(0));

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -4000),
    );
    await tester.pumpAndSettle();
    expect(loads, 2);
    expect(find.text('No more content'), findsOneWidget);
  });
}
