import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:dooja/api/api_client.dart';
import 'package:dooja/repo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test(
    'persists JWT, sends bearer and camelCase JSON, clears on 401',
    () async {
      final requests = <http.Request>[];
      final client = ApiClient(
        baseUrl: 'http://test/',
        client: MockClient((req) async {
          requests.add(req);
          return req.url.path.endsWith('/unauthorized')
              ? http.Response('', 401)
              : http.Response('{"success":true}', 200);
        }),
      );
      await client.saveToken('test-token');
      final restored = ApiClient();
      await restored.restore();
      expect(restored.token, 'test-token');
      await client.post('bookings', {'placeId': 'real-id', 'hours': 2});
      expect(requests.single.url.toString(), 'http://test/api/bookings');
      expect(requests.single.headers['Authorization'], 'Bearer test-token');
      expect(jsonDecode(requests.single.body), {
        'placeId': 'real-id',
        'hours': 2,
      });
      await expectLater(
        client.get('unauthorized'),
        throwsA(isA<ApiException>()),
      );
      expect(client.token, isNull);
      await restored.restore();
      expect(restored.token, isNull);
    },
  );

  test('failed request shows error and does not fabricate rows', () async {
    final repo = Repo.forTesting(
      ApiClient(
        baseUrl: 'http://test',
        client: MockClient(
          (_) async => http.Response('{"error":"offline"}', 503),
        ),
      ),
    );
    expect(repo.places, isEmpty);
    expect(repo.bookings, isEmpty);
    expect(repo.offers, isEmpty);
    expect(repo.reels, isEmpty);
    expect(repo.notifs, isEmpty);
    await repo.refresh();
    expect(repo.offline, isTrue);
    expect(repo.error, 'offline');
    expect(repo.places, isEmpty);
    expect(repo.ownerReqs, isEmpty);
  });

  test(
    'loads only server rows and uses booking numeric ID for cancellation',
    () async {
      var cancelled = false;
      final client = ApiClient(
        baseUrl: 'http://test',
        client: MockClient((req) async {
          final path = req.url.path;
          dynamic data;
          switch (path) {
            case '/api/auth/me':
              data = {
                'phone': '07700000001',
                'name': 'API user',
                'role': 'Customer',
                'points': 7,
                'governorate': 'بغداد',
                'area': '',
                'birth': '',
              };
            case '/api/places':
              data = [
                {
                  'id': 'venue-from-server',
                  'name': 'API venue',
                  'imageKey': 'padel',
                  'rating': 4.5,
                  'reviewCount': 2,
                  'price': 20000,
                  'unit': 'ساعة',
                  'kind': 'open',
                },
              ];
            case '/api/bookings':
              data = [
                {
                  'id': 42,
                  'code': 'DJ-SERVER',
                  'placeId': 'venue-from-server',
                  'day': '2026-11-10',
                  'time': '18:00',
                  'duration': '2 ساعة',
                  'hours': 2,
                  'people': 4,
                  'total': 40000,
                  'payMethod': 'كاش بالمكان',
                  'status': cancelled ? 'ملغي' : 'مؤكد',
                },
              ];
            case '/api/bookings/42/cancel':
              cancelled = true;
              data = {'status': 'ملغي'};
            default:
              data = [];
          }
          return http.Response(
            jsonEncode(data),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      await client.saveToken('test-token');
      final repo = Repo.forTesting(client);
      await repo.refresh();
      expect(repo.error, isNull);
      expect(repo.places.single.name, 'API venue');
      expect(repo.points, 7);
      expect(repo.bookings.single.id, 42);
      expect(repo.bookings.single.code, 'DJ-SERVER');
      expect(await repo.cancel(repo.bookings.single), isTrue);
      expect(cancelled, isTrue);
      expect(repo.bookings.single.status, 'ملغي');
    },
  );

  test(
    'availability is unknown/blocked until API loads and respects hours',
    () async {
      final repo = Repo.forTesting(
        ApiClient(
          baseUrl: 'http://test',
          client: MockClient(
            (_) async => http.Response(
              '{"closed":["22:00"],"booked":[{"time":"18:00","hours":2}]}',
              200,
            ),
          ),
        ),
      );
      expect(repo.occupied('x', '2026-11-10').length, 24);
      await repo.loadAvailability('x', '2026-11-10');
      expect(repo.occupied('x', '2026-11-10'), {18, 19, 22});
      expect(time24('8:00 م'), '20:00');
      expect(time24('12:00 ص'), '00:00');
    },
  );
}
