import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dooja/app.dart';
import 'package:dooja/dsl.dart';
import 'package:dooja/repo.dart';
import 'package:dooja/screens/auth.dart';
import 'package:dooja/screens/home.dart';
import 'package:dooja/screens/more.dart';
import 'package:dooja/screens/owner.dart';
import 'package:dooja/screens/place.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('Plex');
    for (final f in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      loader.addFont(rootBundle.load('assets/fonts/IBMPlexSansArabic-$f.ttf'));
    }
    await loader.load();
    await loadIcons();
  });
  testWidgets('empty API snapshots render without seeded rows or exceptions', (
    tester,
  ) async {
    repo.homeLoaded = true;
    onCustomerTab = (_, __) {};
    onOwnerTab = (_, __) {};
    for (final widget in <Widget>[
      const CreateAccount(),
      const Home(),
      const Search(),
      const Category('بادل'),
      const MapView(),
      const Bookings(),
      const Offers(),
      const Reels(),
      const Favs(),
      const Notifs(),
      const OwnerHome(),
      const OBookings(),
      const OInsights(),
      const OOffPerf(),
      const OProject(),
      const OServices(),
      const OScan(),
      const OCal(),
      const Group(),
      const Rewards(),
      const Details('missing'),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          builder: (c, child) => DesignCanvas(
            Directionality(textDirection: TextDirection.rtl, child: child!),
          ),
          home: widget,
        ),
      );
      await tester.pump();
      expect(
        tester.takeException(),
        isNull,
        reason: widget.runtimeType.toString(),
      );
      if (widget is Reels) {
        expect(find.text('الريلز قريباً'), findsOneWidget);
      }
      if (widget is CreateAccount) {
        expect(find.text('أنشئ حسابك'), findsOneWidget);
      }
      await tester.pumpWidget(const SizedBox());
    }
  });
}
