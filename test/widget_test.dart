import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:p2p_transfer/main.dart';

void main() {
  testWidgets('P2P App boot test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: P2PApp()));
    expect(find.byType(P2PApp), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 3500));
  });
}
