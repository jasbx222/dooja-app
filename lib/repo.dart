import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'api/api_client.dart';

String fmt(int v) {
  final s = v.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

class Place {
  final String id, img, name, type, area, dist, rating, nRev, unit, cat, phone;
  final int price;
  String kind; // open | slots | full
  final bool featured;
  int followers;
  Place(
    this.id,
    this.img,
    this.name,
    this.type,
    this.area,
    this.dist,
    this.rating,
    this.nRev,
    this.price,
    this.unit,
    this.kind,
    this.cat, {
    this.featured = false,
    this.phone = '',
    this.followers = 0,
  });
  String get priceS => fmt(price);
}

class Review {
  int id = 0;
  final String name, ago, text;
  final int stars;
  final bool photos;
  String? reply;
  Review(
    this.name,
    this.ago,
    this.stars,
    this.text, {
    this.photos = false,
    this.reply,
  });
}

class Offer {
  final String id, img, place, disc, exp, cat, area;
  final int newP, oldP;
  final String placeId;
  int views, clicks, books;
  bool active;
  Offer(
    this.id,
    this.placeId,
    this.img,
    this.place,
    this.disc,
    this.newP,
    this.oldP,
    this.exp,
    this.cat,
    this.area, {
    this.views = 0,
    this.clicks = 0,
    this.books = 0,
    this.active = true,
  });
}

class Booking {
  int id = 0;
  int hours = 1;
  final String code, placeId, day, time, dur, pay;
  final int people, total;
  String status; // مؤكد | بالانتظار | بانتظار القبول | مكتمل | ملغي
  bool rated;
  Booking(
    this.code,
    this.placeId,
    this.day,
    this.time,
    this.dur,
    this.people,
    this.total,
    this.pay,
    this.status, {
    this.rated = false,
  });
}

class Reel {
  int id = 0;
  final String img, placeId, place, caption, offer;
  int likes;
  bool liked = false, saved = false;
  final List<(String, String, String, int)> comments;
  Reel(
    this.img,
    this.placeId,
    this.place,
    this.caption,
    this.offer,
    this.likes,
    this.comments,
  );
}

class OwnerReq {
  int id = 0;
  String code = "", day = "", time = "", placeId = "";
  int people = 0;
  final String img, name, when, pay;
  final int total;
  String status; // new | ok | past | rejected
  bool arrived = false;
  OwnerReq(this.img, this.name, this.when, this.pay, this.total, this.status);
}

class Notif {
  int id = 0;
  final String icon, title, body, ago;
  bool fresh;
  Notif(this.icon, this.title, this.body, this.ago, [this.fresh = false]);
}

enum Role { none, customer, owner }

class ShopCategory {
  final int id, sort;
  final String name, image;
  ShopCategory(this.id, this.name, this.image, this.sort);
}

class ShopProduct {
  final int id, price, stock, categoryId;
  final int? compareAt, discount;
  final String name, description, specs, category, image;
  final List<String> images;
  final bool available, featured;
  ShopProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.categoryId,
    required this.category,
    required this.image,
    required this.available,
    this.compareAt,
    this.discount,
    this.description = '',
    this.specs = '',
    this.images = const [],
    this.featured = false,
  });
}

class CartLine {
  final int id, productId, qty, unitPrice, lineTotal, stock;
  final String name, image;
  final bool priceChanged, available;
  CartLine(
    this.id,
    this.productId,
    this.name,
    this.image,
    this.qty,
    this.unitPrice,
    this.lineTotal,
    this.stock,
    this.priceChanged,
    this.available,
  );
}

class ShopArea {
  final int id, fee;
  final String governorate, area;
  final bool customFee;
  ShopArea(this.id, this.governorate, this.area, this.fee, this.customFee);
}

class ShopOrder {
  final int id, subtotal, discount, delivery, total;
  final String number, status, name, phone, governorate, area, address, notes, pay, createdAt;
  final List<CartLine> items;
  final List<(String, String, String)> history;
  ShopOrder(
    this.id,
    this.number,
    this.status,
    this.createdAt,
    this.name,
    this.phone,
    this.governorate,
    this.area,
    this.address,
    this.notes,
    this.subtotal,
    this.discount,
    this.delivery,
    this.total,
    this.pay,
    this.items,
    this.history,
  );
}

// All collections below are API response caches, never local seed data.
class Repo extends ChangeNotifier {
  static final Repo i = Repo._();
  Repo._() : api = ApiClient();
  @visibleForTesting
  Repo.forTesting(this.api);
  final ApiClient api;
  final _detailIds = <String>{};
  static const demoCustomer = '07700000001', demoOwner = '07700000002';
  Role role = Role.none;
  bool get authenticated => api.token != null;
  bool get isOwner => serverRole == 'Owner' || serverRole == 'Admin';
  String serverRole = '',
      phone = '',
      userName = '',
      gov = '',
      area = '',
      birth = '';
  int points = 0;
  bool homeLoaded = false, offline = false, loading = false;
  String? error;
  final interests = <String>{}; // Local-only preferences, no server endpoint.
  final settings = <String, bool>{
    'الحجوزات والتذكير': false,
    'العروض الجديدة': false,
    'ردود وتعليقات': false,
    'اقتراحات حسب نشاطي': false,
    'مشاركة موقعي': false,
    'الوضع الداكن': false,
  };
  final places = <Place>[];
  final ownerPlaces = <Place>[];
  String? selectedOwnerId;
  String? get ownerId => ownerPlaces.any((p) => p.id == selectedOwnerId)
      ? selectedOwnerId
      : ownerPlaces.isEmpty
      ? null
      : ownerPlaces.first.id;
  Place? get ownerPlace => ownerId == null ? null : place(ownerId!);
  final favs = <String>{}, follows = <String>{};
  final reviews = <String, List<Review>>{};
  final ownerReviews = <Review>[];
  final offers = <Offer>[], ownerOffers = <Offer>[];
  final reels = <Reel>[];
  final bookings = <Booking>[];
  final notifs = <Notif>[];
  bool shopEnabled = true, shopLoading = false;
  String? shopError;
  int shopDeliveryFee = 0, shopMinOrder = 0, shopPage = 1, shopTotal = 0;
  int cartSubtotal = 0, cartDiscount = 0;
  final shopCategories = <ShopCategory>[];
  final shopProducts = <ShopProduct>[];
  final cartLines = <CartLine>[];
  final cartWarnings = <String>[];
  final shopOrders = <ShopOrder>[];
  final payMethods = <(String, String)>[];
  final deliveryAreas = <ShopArea>[];
  ShopProduct? currentProduct;
  int get cartCount => cartLines.fold(0, (sum, line) => sum + line.qty);
  String media(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '${api.baseUrl.replaceAll(RegExp(r'/+$'), '')}$path';
  }
  List<Notif> get ownerNotifs => notifs;
  final ownerReqs = <OwnerReq>[];
  int todayBookings = 0, todayIncome = 0;
  final services = <(String, int, String)>[];
  final serviceIds = <int>[];
  final publicServices = <String, List<(String, int, String)>>{};
  final availability = <String, Map<String, dynamic>>{};
  final closedSlots = <Map<String, dynamic>>[];
  Place place(String id) => places.firstWhere((p) => p.id == id);
  bool hasPlace(String id) => places.any((p) => p.id == id);
  List<Review> reviewsOf(String id) => reviews[id] ?? const [];
  bool get isNewUser => userName == phone || userName.isEmpty;
  void touch() => notifyListeners();

  static String str(Map m, String k) => (m[k] ?? '').toString();
  static int intVal(Map m, String k) => (m[k] as num?)?.toInt() ?? 0;
  static List<Map<String, dynamic>> rows(dynamic data) =>
      (data as List).map((x) => Map<String, dynamic>.from(x as Map)).toList();
  static Place parsePlace(Map m) => Place(
    str(m, 'id'),
    str(m, 'imageKey'),
    str(m, 'name'),
    str(m, 'type'),
    str(m, 'area'),
    str(m, 'dist'),
    str(m, 'rating'),
    str(m, 'reviewCount'),
    intVal(m, 'price'),
    str(m, 'unit'),
    str(m, 'kind'),
    str(m, 'category'),
    featured: m['featured'] == true,
    phone: str(m, 'phone'),
    followers: intVal(m, 'followers'),
  );
  static Review parseReview(Map m) => Review(
    str(m, 'name'),
    str(m, 'ago'),
    intVal(m, 'stars'),
    str(m, 'text'),
    photos: m['hasPhotos'] == true,
    reply: m['reply'] as String?,
  )..id = intVal(m, 'id');
  static Offer parseOffer(Map m) => Offer(
    str(m, 'id'),
    str(m, 'placeId'),
    str(m, 'imageKey'),
    str(m, 'title'),
    str(m, 'disc'),
    intVal(m, 'newPrice'),
    intVal(m, 'oldPrice'),
    str(m, 'expiryText'),
    str(m, 'category'),
    str(m, 'area'),
    views: intVal(m, 'views'),
    clicks: intVal(m, 'clicks'),
    books: intVal(m, 'books'),
    active: m['active'] == true,
  );
  static Booking parseBooking(Map m) =>
      Booking(
          str(m, 'code'),
          str(m, 'placeId'),
          str(m, 'day'),
          str(m, 'time'),
          str(m, 'duration'),
          intVal(m, 'people'),
          intVal(m, 'total'),
          str(m, 'payMethod'),
          str(m, 'status'),
          rated: m['rated'] == true,
        )
        ..id = intVal(m, 'id')
        ..hours = intVal(m, 'hours');
  static OwnerReq parseRequest(Map m) =>
      OwnerReq(
          str(m['place'] as Map? ?? {}, 'imageKey'),
          str(m['user'] as Map? ?? {}, 'name'),
          '${str(m, 'day')} · ${str(m, 'time')} · ${str(m, 'duration')} · ${intVal(m, 'people')} أشخاص',
          str(m, 'payMethod'),
          intVal(m, 'total'),
          switch (str(m, 'status')) {
            'مؤكد' => 'ok',
            'مكتمل' => 'past',
            'ملغي' => 'rejected',
            _ => 'new',
          },
        )
        ..id = intVal(m, 'id')
        ..arrived = m['arrived'] == true
        ..day = str(m, 'day')
        ..time = str(m, 'time')
        ..placeId = str(m, 'placeId')
        ..code = str(m, 'code')
        ..people = intVal(m, 'people');
  void profile(Map m) {
    phone = str(m, 'phone');
    userName = str(m, 'name');
    gov = str(m, 'governorate');
    area = str(m, 'area');
    birth = str(m, 'birth');
    points = intVal(m, 'points');
    serverRole = str(m, 'role');
    role = isOwner ? Role.owner : Role.customer;
  }

  Future<void> initialize() async {
    try {
      await api.restore();
      if (authenticated) {
        profile(await api.get('auth/me') as Map);
        await _mergeGuest();
      }
    } catch (e) {
      await api.clearToken();
      error = e.toString();
    }
    if (!authenticated) {
      try {
        await _loadGuest();
      } catch (e) {
        shopError = e.toString();
      }
    }
    await refresh();
  }

  void _clearData() {
    places.clear();
    ownerPlaces.clear();
    favs.clear();
    follows.clear();
    reviews.clear();
    ownerReviews.clear();
    offers.clear();
    ownerOffers.clear();
    reels.clear();
    bookings.clear();
    notifs.clear();
    ownerReqs.clear();
    services.clear();
    serviceIds.clear();
    publicServices.clear();
    availability.clear();
    closedSlots.clear();
    todayBookings = 0;
    todayIncome = 0;
  }

  Future<void> refresh() async {
    if (loading) return;
    loading = true;
    error = null;
    touch();
    try {
      final all = <Place>[];
      for (var page = 1; page <= 10000; page++) {
        final batch = rows(await api.get('places?page=$page&pageSize=100'))
            .map(parsePlace)
            .toList();
        all.addAll(batch);
        if (batch.length < 100) break;
      }
      _clearData();
      places.addAll(all);
      offers.addAll(rows(await api.get('offers')).map(parseOffer));
      final rs = rows(await api.get('reels'));
      for (final m in rs) {
        final comments = rows(await api.get('reels/${m['id']}/comments'));
        reels.add(
          Reel(
            str(m, 'imageKey'),
            str(m, 'placeId'),
            str(m['place'] as Map? ?? {}, 'name'),
            str(m, 'caption'),
            str(m, 'offerText'),
            intVal(m, 'likes'),
            comments
                .map(
                  (x) => (
                    str(x, 'name'),
                    str(x, 'text'),
                    str(x, 'createdAt'),
                    intVal(x, 'likes'),
                  ),
                )
                .toList(),
          )..id = intVal(m, 'id'),
        );
      }
      if (authenticated) {
        profile(await api.get('auth/me') as Map);
        final bookingRows = rows(await api.get('bookings'));
        bookings.addAll(bookingRows.map(parseBooking));
        for (final m in bookingRows) {
          if (!hasPlace(str(m, 'placeId')) && m['place'] is Map)
            places.add(parsePlace(m['place'] as Map));
        }
        favs.addAll(rows(await api.get('favorites')).map((m) => str(m, 'id')));
        follows.addAll(
          rows(await api.get('places/following')).map((m) => str(m, 'id')),
        );
        notifs.addAll(
          rows(await api.get('notifications')).map(
            (m) => Notif(
              str(m, 'icon'),
              str(m, 'title'),
              str(m, 'body'),
              str(m, 'createdAt'),
              m['fresh'] == true,
            )..id = intVal(m, 'id'),
          ),
        );
        if (isOwner) {
          ownerPlaces.addAll(
            rows(await api.get('owner/places')).map(parsePlace),
          );
          for (final p in ownerPlaces) {
            if (!hasPlace(p.id)) places.add(p);
          }
          ownerReqs.addAll(
            rows(await api.get('owner/bookings')).map(parseRequest),
          );
          ownerOffers.addAll(
            rows(await api.get('owner/offers')).map(parseOffer),
          );
          ownerReviews.addAll(
            rows(await api.get('owner/reviews')).map(parseReview),
          );
          final dashboard = await api.get('owner/dashboard') as Map;
          todayBookings = intVal(dashboard, 'todayBookings');
          todayIncome = intVal(dashboard, 'todayIncome');
          await loadOwnerServices();
        }
      }
      for (final id in _detailIds.where(hasPlace).toList()) {
        reviews[id] = rows(
          await api.get('reviews?placeId=${Uri.encodeComponent(id)}'),
        ).map(parseReview).toList();
        publicServices[id] = rows(await api.get('places/$id/services'))
            .map((m) => (str(m, 'name'), intVal(m, 'price'), str(m, 'unit')))
            .toList();
      }
      homeLoaded = true;
      offline = false;
      try {
        await _syncCart();
      } catch (e) {
        shopError = e.toString();
      }
    } catch (e) {
      _clearData();
      error = e.toString();
      offline = true;
      homeLoaded = true;
    } finally {
      loading = false;
      touch();
    }
  }

  Future<bool> run(Future<void> Function() action, {bool reload = true}) async {
    try {
      error = null;
      await action();
      if (reload) await refresh();
      touch();
      return error == null;
    } catch (e) {
      error = e.toString();
      touch();
      return false;
    }
  }

  Future<void> requestOtp(String ph) async {
    await api.post('auth/request-otp', {'phone': ph});
  }

  Future<Role> login(String ph, String code) async {
    final m = await api.post('auth/verify', {'phone': ph, 'code': code}) as Map;
    await api.saveToken(str(m, 'token'));
    profile(m['user'] as Map);
    await _mergeGuest();
    await refresh();
    return role;
  }

  Future<void> logout() async {
    await api.clearToken();
    role = Role.none;
    serverRole = '';
    phone = '';
    userName = '';
    gov = '';
    area = '';
    birth = '';
    points = 0;
    interests.clear();
    _detailIds.clear();
    _clearData();
    homeLoaded = false;
    touch();
    await refresh();
  }

  Future<bool> saveProfile({
    String? name,
    String? governorate,
    String? location,
    String? birthday,
  }) => run(() async {
    profile(
      await api.put('auth/me', {
        'name': name ?? userName,
        'governorate': governorate ?? gov,
        'area': location ?? area,
        'birth': birthday ?? birth,
      }) as Map,
    );
  });
  Future<bool> toggleFav(String id) => run(() async {
    await api.post('favorites/$id/toggle');
  });
  Future<bool> toggleFollow(String id) => run(() async {
    await api.post('places/$id/follow');
  });
  Future<void> loadPlace(String id) async {
    _detailIds.add(id);
    await run(() async {
      final p = parsePlace(await api.get('places/$id') as Map);
      places.removeWhere((x) => x.id == id);
      places.add(p);
      reviews[id] = rows(
        await api.get('reviews?placeId=${Uri.encodeComponent(id)}'),
      ).map(parseReview).toList();
      publicServices[id] = rows(await api.get('places/$id/services'))
          .map((m) => (str(m, 'name'), intVal(m, 'price'), str(m, 'unit')))
          .toList();
    }, reload: false);
  }

  Future<bool> addReview(
    String placeId,
    int stars,
    String text,
    int bookingId,
  ) => run(() async {
    await api.post('reviews', {
      'placeId': placeId,
      'stars': stars,
      'text': text,
      'bookingId': bookingId,
    });
    await loadPlace(placeId);
  });
  Future<bool> reply(Review r, String text) => run(() async {
    await api.post('reviews/${r.id}/reply', {'text': text});
  });
  Future<bool> toggleOffer(Offer o) => run(() async {
    await api.post('owner/offers/${o.id}/toggle');
  });
  Future<bool> createOffer(
    String title,
    int pct,
    String to, {
    String? expiresOn,
  }) => run(() async {
    final p = ownerPlace;
    if (p == null) throw const ApiException('اختار مشروعاً أولاً');
    await api.post('owner/offers', {
      'placeId': p.id,
      'title': title,
      'disc': 'خصم $pct%',
      'newPrice': (p.price * (100 - pct) / 100).round(),
      'oldPrice': p.price,
      'expiryText': expiresOn ?? '',
      'expiresOn': expiresOn,
      'active': true,
    });
  });
  Future<bool> viewOffer(Offer o) => run(() async {
    await api.get('offers/${o.id}');
  }, reload: false);
  Future<bool> clickOffer(Offer o) => run(() async {
    await api.post('offers/${o.id}/click');
  }, reload: false);
  Future<bool> postReel(String caption) => run(() async {
    final p = ownerPlace;
    if (p == null) throw const ApiException('اختار مشروعاً أولاً');
    await api.post('reels', {
      'placeId': p.id,
      'caption': caption,
      'imageKey': p.img,
      'offerText': '',
    });
  });
  Future<bool> likeReel(Reel r) => run(() async {
    final m = await api.post('reels/${r.id}/like') as Map;
    r.liked = m['liked'] == true;
    r.likes = intVal(m, 'likes');
  }, reload: false);
  Future<bool> comment(Reel r, String text) => run(() async {
    await api.post('reels/${r.id}/comments', {'text': text});
    final cs = rows(await api.get('reels/${r.id}/comments'));
    r.comments
      ..clear()
      ..addAll(
        cs.map(
          (x) => (
            str(x, 'name'),
            str(x, 'text'),
            str(x, 'createdAt'),
            intVal(x, 'likes'),
          ),
        ),
      );
  }, reload: false);
  Future<Booking> book({
    required String placeId,
    required String day,
    required String time,
    required String dur,
    required int people,
    required int total,
    required String pay,
    bool wait = false,
    String? offerId,
  }) async {
    final b = parseBooking(
      await api.post('bookings', {
        'placeId': placeId,
        'day': day,
        'time': time24(time),
        'hours': dur == 'ساعة'
            ? 1
            : dur == 'ساعتين'
            ? 2
            : 3,
        'people': people,
        'payMethod': pay,
        'wait': wait,
        'offerId': offerId,
      }) as Map,
    );
    await refresh();
    return b;
  }

  Future<bool> cancel(Booking b) => run(() async {
    final m = await api.post('bookings/${b.id}/cancel') as Map;
    b.status = str(m, 'status');
  });
  Future<bool> accept(OwnerReq r) => status(r, 'مؤكد');
  Future<bool> reject(OwnerReq r) => status(r, 'ملغي');
  Future<bool> status(OwnerReq r, String status) => run(() async {
    await api.post('owner/bookings/${r.id}/status', {'status': status});
  });
  Future<bool> arrive(OwnerReq r) => run(() async {
    await api.post('owner/bookings/${r.id}/arrive');
  });
  Future<bool> readNotif(Notif n) => run(() async {
    await api.post('notifications/${n.id}/read');
    n.fresh = false;
  }, reload: false);
  Future<bool> readAll() => run(() async {
    await api.post('notifications/read-all');
    for (final n in notifs) {
      n.fresh = false;
    }
  }, reload: false);
  Future<void> loadOwnerServices() async {
    services.clear();
    serviceIds.clear();
    if (ownerId == null) return;
    for (final m in rows(await api.get('owner/services/$ownerId'))) {
      services.add((str(m, 'name'), intVal(m, 'price'), str(m, 'unit')));
      serviceIds.add(intVal(m, 'id'));
    }
  }

  Future<bool> saveService(int index, (String, int, String) value) =>
      run(() async {
        if (ownerId == null) throw const ApiException('اختار مشروعاً أولاً');
        final body = {
          'placeId': ownerId,
          'name': value.$1,
          'price': value.$2,
          'unit': value.$3,
        };
        if (index >= 0 && index < serviceIds.length) {
          await api.put('owner/services/${serviceIds[index]}', body);
        } else {
          await api.post('owner/services', body);
        }
      });
  Future<bool> deleteService(int index) => run(() async {
    await api.delete('owner/services/${serviceIds[index]}');
  });
  Future<bool> savePlace(Map<String, dynamic> data, {String? id}) =>
      run(() async {
        if (id == null) {
          await api.post('owner/places', data);
        } else {
          await api.put('owner/places/$id', data);
        }
      });
  Future<void> loadAvailability(String id, String day) async {
    final key = '$id/$day';
    await run(() async {
      availability[key] = Map<String, dynamic>.from(
        await api.get('places/$id/availability?day=$day') as Map,
      );
    }, reload: false);
  }

  Set<int> occupied(String id, String day) {
    final a = availability['$id/$day'];
    if (a == null) return {for (var h = 0; h < 24; h++) h};
    final hours = <int>{};
    for (final t in a['closed'] as List) {
      hours.add(int.parse(t.toString().split(':').first));
    }
    for (final b in a['booked'] as List) {
      final h = int.parse(b['time'].toString().split(':').first);
      for (var i = 0; i < (b['hours'] as num).toInt(); i++) {
        hours.add(h + i);
      }
    }
    return hours;
  }

  Future<void> loadClosed(String day) async {
    if (ownerId == null) return;
    await run(() async {
      closedSlots
        ..clear()
        ..addAll(
          rows(await api.get('owner/closed-slots/$ownerId'))
              .where((x) => x['day'] == day),
        );
    }, reload: false);
    await loadAvailability(ownerId!, day);
  }

  Future<bool> toggleClosed(String day, String time) => run(() async {
    if (ownerId == null) throw const ApiException('اختار مشروعاً أولاً');
    final match = closedSlots
        .where((x) => x['day'] == day && x['time'] == time)
        .toList();
    if (match.isEmpty) {
      await api.post('owner/closed-slots', {
        'placeId': ownerId,
        'day': day,
        'time': time,
      });
    } else {
      await api.delete('owner/closed-slots/${match.first['id']}');
    }
    await loadClosed(day);
  }, reload: false);

  ShopProduct _product(Map m, {bool full = false}) => ShopProduct(
    id: intVal(m, 'id'),
    name: str(m, 'name'),
    price: intVal(m, 'price'),
    stock: intVal(m, 'stock'),
    categoryId: intVal(m, 'categoryId'),
    category: str(m, 'category'),
    image: str(m, 'imageUrl'),
    available: m['available'] == true,
    compareAt: m['compareAtPrice'] == null ? null : intVal(m, 'compareAtPrice'),
    discount: m['discountPercent'] == null ? null : intVal(m, 'discountPercent'),
    description: full ? str(m, 'description') : '',
    specs: full ? str(m, 'specs') : '',
    images: full ? ((m['images'] as List?) ?? []).map((e) => e.toString()).toList() : [str(m, 'imageUrl')],
    featured: m['featured'] == true,
  );

  void _readCart(Map m) {
    cartLines
      ..clear()
      ..addAll(rows(m['items']).map((x) => CartLine(intVal(x, 'id'), intVal(x, 'productId'), str(x, 'name'), str(x, 'imageUrl'), intVal(x, 'qty'), intVal(x, 'unitPrice'), intVal(x, 'lineTotal'), intVal(x, 'stock'), x['priceChanged'] == true, x['available'] == true)));
    cartSubtotal = intVal(m, 'subtotal');
    cartDiscount = intVal(m, 'discount');
    cartWarnings
      ..clear()
      ..addAll(((m['warnings'] as List?) ?? []).map((e) => '$e'));
  }

  ShopOrder _order(Map m) => ShopOrder(
    intVal(m, 'id'),
    str(m, 'number'),
    str(m, 'status'),
    str(m, 'createdAt'),
    str(m, 'customerName'),
    str(m, 'phone'),
    str(m, 'governorate'),
    str(m, 'area'),
    str(m, 'address'),
    str(m, 'notes'),
    intVal(m, 'subtotal'),
    intVal(m, 'discount'),
    intVal(m, 'deliveryFee'),
    intVal(m, 'total'),
    str(m, 'payMethod'),
    rows(m['items']).map((x) => CartLine(0, intVal(x, 'productId'), str(x, 'name'), '', intVal(x, 'qty'), intVal(x, 'unitPrice'), intVal(x, 'lineTotal'), 0, false, true)).toList(),
    ((m['history'] as List?) ?? []).map((e) {
      final x = Map<String, dynamic>.from(e as Map);
      return (str(x, 'status'), str(x, 'note'), str(x, 'createdAt'));
    }).toList(),
  );

  Future<void> _syncCart() async {
    if (!authenticated) return;
    _readCart(await api.get('cart') as Map);
  }

  Future<void> _saveGuest() async {
    await api.storage.write(key: 'dooja.guestCart', value: jsonEncode(cartLines.map((l) => {'productId': l.productId, 'qty': l.qty}).toList()));
  }

  Future<void> _loadGuest() async {
    final raw = await api.storage.read(key: 'dooja.guestCart');
    cartLines.clear();
    if (raw == null || raw.isEmpty) return;
    final saved = (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    cartWarnings.clear();
    var subtotal = 0, discount = 0;
    for (final item in saved) {
      try {
        final product = _product(await api.get('shop/products/${item['productId']}') as Map, full: true);
        final qty = (item['qty'] as num).toInt();
        if (qty > product.stock) cartWarnings.add('المتوفر من ${product.name} هو ${product.stock}');
        final line = product.price * qty;
        subtotal += line;
        if (product.compareAt != null && product.compareAt! > product.price) discount += (product.compareAt! - product.price) * qty;
        cartLines.add(CartLine(0, product.id, product.name, product.image, qty, product.price, line, product.stock, false, product.available));
      } catch (_) {
        cartWarnings.add('منتج في السلة لم يعد متاحاً');
      }
    }
    cartSubtotal = subtotal;
    cartDiscount = discount;
  }

  Future<void> _mergeGuest() async {
    final raw = await api.storage.read(key: 'dooja.guestCart');
    if (raw == null || raw.isEmpty) return;
    final items = jsonDecode(raw) as List;
    if (items.isEmpty) return;
    await api.post('cart/merge', {'items': items});
    await api.storage.delete(key: 'dooja.guestCart');
  }

  Future<void> openStore({String q = '', int? categoryId, String sort = 'latest', int? minPrice, int? maxPrice, bool discounted = false, int page = 1}) async {
    shopLoading = true;
    shopError = null;
    touch();
    try {
      final settings = await api.get('shop/settings') as Map;
      shopEnabled = settings['enabled'] == true;
      shopDeliveryFee = intVal(settings, 'deliveryFee');
      shopMinOrder = intVal(settings, 'minOrder');
      payMethods
        ..clear()
        ..addAll(rows(settings['paymentMethods']).map((m) => (str(m, 'code'), str(m, 'name'))));
      deliveryAreas
        ..clear()
        ..addAll(rows(settings['areas']).map((m) => ShopArea(intVal(m, 'id'), str(m, 'governorate'), str(m, 'area'), m['fee'] == null ? shopDeliveryFee : intVal(m, 'fee'), m['fee'] != null)));
      shopCategories
        ..clear()
        ..addAll(rows(await api.get('shop/categories')).map((m) => ShopCategory(intVal(m, 'id'), str(m, 'name'), str(m, 'imageUrl'), intVal(m, 'sortOrder'))));
      final query = [
        'page=$page',
        'pageSize=20',
        if (q.isNotEmpty) 'q=${Uri.encodeQueryComponent(q)}',
        if (categoryId != null) 'categoryId=$categoryId',
        'sort=$sort',
        if (minPrice != null) 'minPrice=$minPrice',
        if (maxPrice != null) 'maxPrice=$maxPrice',
        if (discounted) 'discounted=true',
      ].join('&');
      final pageBody = await api.get('shop/products?$query') as Map;
      shopEnabled = pageBody['enabled'] == true;
      shopPage = intVal(pageBody, 'page');
      shopTotal = intVal(pageBody, 'total');
      final batch = rows(pageBody['items']).map(_product).toList();
      if (page <= 1) shopProducts.clear();
      shopProducts.addAll(batch);
      if (authenticated) {
        await _syncCart();
      } else {
        await _loadGuest();
      }
    } catch (e) {
      shopError = e.toString();
      if (page <= 1) shopProducts.clear();
    } finally {
      shopLoading = false;
      touch();
    }
  }

  Future<void> openProduct(int id) async {
    shopError = null;
    currentProduct = null;
    touch();
    try {
      currentProduct = _product(await api.get('shop/products/$id') as Map, full: true);
    } catch (e) {
      shopError = e.toString();
    }
    touch();
  }

  Future<String?> addToCart(int productId, int qty) async {
    try {
      if (!authenticated) {
        final product = currentProduct?.id == productId ? currentProduct! : _product(await api.get('shop/products/$productId') as Map, full: true);
        final have = cartLines.where((l) => l.productId == productId).fold(0, (s, l) => s + l.qty);
        if (have + qty > product.stock) return 'المتوفر من ${product.name} هو ${product.stock} فقط';
        await _loadGuest();
        final next = (cartLines.where((l) => l.productId == productId).fold(0, (s, l) => s + l.qty)) + qty;
        cartLines.removeWhere((l) => l.productId == productId);
        cartLines.add(CartLine(0, product.id, product.name, product.image, next, product.price, product.price * next, product.stock, false, product.available));
        cartSubtotal = cartLines.fold(0, (s, l) => s + l.lineTotal);
        await _saveGuest();
        touch();
        return null;
      }
      _readCart(await api.post('cart/items', {'productId': productId, 'qty': qty}) as Map);
      touch();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> setCartQty(int productId, int qty) async {
    try {
      if (!authenticated) {
        if (qty <= 0) cartLines.removeWhere((l) => l.productId == productId);
        else {
          final i = cartLines.indexWhere((l) => l.productId == productId);
          if (i < 0) return 'المنتج غير موجود في السلة';
          final line = cartLines[i];
          if (qty > line.stock) return 'المتوفر ${line.stock} فقط';
          cartLines[i] = CartLine(0, line.productId, line.name, line.image, qty, line.unitPrice, line.unitPrice * qty, line.stock, line.priceChanged, line.available);
        }
        cartSubtotal = cartLines.fold(0, (s, l) => s + l.lineTotal);
        await _saveGuest();
        touch();
        return null;
      }
      _readCart(await api.put('cart/items/$productId', {'productId': productId, 'qty': qty}) as Map);
      touch();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> loadOrders() async {
    if (!authenticated) {
      shopOrders.clear();
      touch();
      return;
    }
    shopOrders
      ..clear()
      ..addAll(rows(await api.get('orders')).map(_order));
    touch();
  }

  Future<(ShopOrder?, String?)> checkout({required String name, required String phone, required String governorate, required String area, required String address, required String notes, required String payMethod, required String idempotencyKey}) async {
    try {
      final data = await api.request('POST', 'orders', {
        'name': name,
        'phone': phone,
        'governorate': governorate,
        'area': area,
        'address': address,
        'notes': notes,
        'payMethod': payMethod,
        'idempotencyKey': idempotencyKey,
      });
      final order = _order(data as Map);
      cartLines.clear();
      await loadOrders();
      return (order, null);
    } catch (e) {
      return (null, e.toString());
    }
  }

  Future<String?> cancelOrder(int id) async {
    try {
      await api.post('orders/$id/cancel');
      await loadOrders();
      await _syncCart();
      touch();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final repo = Repo.i;
String phoneFmt(String p) => p.length == 11
    ? '${p.substring(0, 4)} ${p.substring(4, 7)} ${p.substring(7)}'
    : p;
String kfmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : '$n';
String isoDay([int offset = 0]) {
  final d = DateTime.now().add(Duration(days: offset));
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

String time24(String time) {
  if (!time.contains('م') && !time.contains('ص')) return time;
  final parts = time.split(' ').first.split(':');
  var h = int.parse(parts.first) % 12;
  if (time.contains('م')) h += 12;
  return '${h.toString().padLeft(2, '0')}:${parts.length > 1 ? parts[1] : '00'}';
}
