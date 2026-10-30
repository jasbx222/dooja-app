// Mock repository: realistic Iraqi data, simulated latency, in-memory state.
import 'dart:math';
import 'package:flutter/foundation.dart';

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
  Place(this.id, this.img, this.name, this.type, this.area, this.dist, this.rating, this.nRev, this.price, this.unit, this.kind, this.cat, {this.featured = false, this.phone = '0770 555 1234', this.followers = 2400});
  String get priceS => fmt(price);
}

class Review {
  final String name, ago, text;
  final int stars;
  final bool photos;
  String? reply;
  Review(this.name, this.ago, this.stars, this.text, {this.photos = false, this.reply});
}

class Offer {
  final String id, img, place, disc, exp, cat, area;
  final int newP, oldP;
  final String placeId;
  int views, clicks, books;
  bool active;
  Offer(this.id, this.placeId, this.img, this.place, this.disc, this.newP, this.oldP, this.exp, this.cat, this.area, {this.views = 0, this.clicks = 0, this.books = 0, this.active = true});
}

class Booking {
  final String code, placeId, day, time, dur, pay;
  final int people, total;
  String status; // مؤكد | بالانتظار | بانتظار القبول | مكتمل | ملغي
  bool rated;
  Booking(this.code, this.placeId, this.day, this.time, this.dur, this.people, this.total, this.pay, this.status, {this.rated = false});
}

class Reel {
  final String img, placeId, place, caption, offer;
  int likes;
  bool liked = false, saved = false;
  final List<(String, String, String, int)> comments;
  Reel(this.img, this.placeId, this.place, this.caption, this.offer, this.likes, this.comments);
}

class OwnerReq {
  final String img, name, when, pay;
  final int total;
  String status; // new | ok | past | rejected
  bool arrived = false;
  OwnerReq(this.img, this.name, this.when, this.pay, this.total, this.status);
}

class Notif {
  final String icon, title, body, ago;
  bool fresh;
  Notif(this.icon, this.title, this.body, this.ago, [this.fresh = false]);
}

enum Role { none, customer, owner }

class Repo extends ChangeNotifier {
  static final Repo i = Repo._();
  Repo._();

  static const demoCustomer = '07700000001', demoOwner = '07700000002', otpCode = '1234';
  Role role = Role.none;
  String phone = '';
  String userName = 'حسين علي';
  String gov = 'بغداد';
  String area = 'المنصور';
  String birth = '12 / 05 / 2001';
  int points = 1240;
  bool homeLoaded = false;
  bool offline = false;
  final Set<String> interests = {'ملاعب', 'بادل', 'ألعاب إلكترونية', 'فعاليات'};
  final Map<String, bool> settings = {'الحجوزات والتذكير': true, 'العروض الجديدة': true, 'ردود وتعليقات': false, 'اقتراحات حسب نشاطي': true, 'مشاركة موقعي': true, 'الوضع الداكن': false};

  Future<void> lag([int ms = 600]) => Future.delayed(Duration(milliseconds: ms + Random().nextInt(300)));

  final places = <Place>[
    Place('p1', 'padel', 'ملعب بادل لاونج', 'بادل', 'المنصور', '1.5 كم', '4.8', '312', 20000, 'ساعة', 'slots', 'بادل'),
    Place('p2', 'football', 'ملعب الشعب الخماسي', 'ملاعب', 'الشعب', '4.2 كم', '4.5', '188', 30000, 'ساعة', 'open', 'ملاعب'),
    Place('p3', 'billiard', 'قصر البليارد', 'بليارد', 'الكرادة', '2.5 كم', '4.6', '140', 8000, 'ساعة', 'full', 'بليارد'),
    Place('p4', 'gaming', 'Game Zone', 'ألعاب', 'زيونة', '3.1 كم', '4.7', '265', 5000, 'ساعة', 'open', 'ألعاب إلكترونية'),
    Place('p5', 'pool', 'منتجع الريم', 'منتجعات', 'الجادرية', '6 كم', '4.9', '540', 25000, 'شخص', 'open', 'منتزهات ومنتجعات', featured: true),
    Place('p6', 'cafe', 'كافيه ليالي', 'كافيه', 'عرصات الهندية', '3.8 كم', '4.7', '410', 6000, 'شخص', 'open', 'كافيهات', featured: true),
    Place('p7', 'food', 'مطعم بيت بغداد', 'مطاعم', 'الكرادة', '2.9 كم', '4.6', '820', 18000, 'شخص', 'open', 'مطاعم'),
    Place('p8', 'padel', 'بادل كلوب الجادرية', 'بادل', 'الجادرية', '3.4 كم', '4.7', '96', 25000, 'ساعة', 'open', 'بادل'),
    Place('p9', 'football', 'نادي الزوراء للبادل', 'بادل', 'الحارثية', '5.0 كم', '4.4', '61', 18000, 'ساعة', 'slots', 'بادل'),
    Place('p10', 'pool', 'مسبح الأمواج', 'مسابح', 'اليرموك', '4.6 كم', '4.5', '133', 10000, 'شخص', 'open', 'مسابح'),
    Place('p11', 'friends', 'مهرجان ليالي بغداد', 'فعاليات', 'الزوراء', '5.5 كم', '4.8', '77', 15000, 'تذكرة', 'slots', 'فعاليات'),
    Place('p12', 'gaming', 'كيدز لاند', 'أنشطة عائلية', 'المنصور', '1.9 كم', '4.6', '58', 7000, 'طفل', 'open', 'أنشطة عائلية'),
  ];
  Place place(String id) => places.firstWhere((p) => p.id == id);

  final favs = <String>{'p1', 'p5'};
  final follows = <String>{'p4', 'p6'};
  void toggleFav(String id) { favs.contains(id) ? favs.remove(id) : favs.add(id); notifyListeners(); }
  void toggleFollow(String id) { follows.contains(id) ? follows.remove(id) : follows.add(id); notifyListeners(); }

  final reviews = <String, List<Review>>{
    'p1': [
      Review('علي حسين', 'قبل يومين', 5, 'الأرضية ممتازة والإضاءة قوية، الحجز من التطبيق كان سهل جداً.', photos: true, reply: 'تسلم علي، ننتظرك مرة لخ!'),
      Review('زينب كريم', 'قبل أسبوع', 4, 'مكان مرتب، بس الموقف يزدحم بالليل. الأسعار مناسبة.'),
      Review('مصطفى عادل', 'قبل أسبوعين', 5, 'أحلى سهرة بادل ويا الشباب، الكافتيريا ممتازة.'),
    ],
  };
  List<Review> reviewsOf(String id) => reviews.putIfAbsent(id, () => [
        Review('سجاد فلاح', 'قبل 3 أيام', 5, 'تجربة حلوة والتعامل راقي، أكيد نرجع.'),
        Review('نور الهدى', 'قبل أسبوع', 4, 'المكان نظيف ومرتب، بس الزحمة بالويكند.'),
      ]);
  void addReview(String placeId, int stars, String text) {
    reviewsOf(placeId).insert(0, Review(userName, 'الآن', stars, text, photos: true));
    points += 20;
    notifyListeners();
  }

  // owner reviews (for ملعب بادل لاونج)
  final ownerReviews = <Review>[
    Review('علي حسين', 'قبل يومين', 3, 'المكان حلو بس الإضاءة بالملعب الثاني ضعيفة شوية.'),
    Review('سارة محمد', 'قبل يومين', 5, 'أفضل ملعب بادل ببغداد، الحجز كان سهل جداً', reply: 'تسلمين سارة، ننتظرك مرة ثانية'),
    Review('أحمد ستار', 'قبل 4 أيام', 4, 'ملعب ممتاز، بس نتمنى تزيدون أوقات الصبح.'),
  ];
  void reply(Review r, String t) { r.reply = t; notifyListeners(); }

  final offers = <Offer>[
    Offer('o1', 'p2', 'football', 'ملعب الشعب الخماسي', 'خصم 25%', 30000, 40000, 'ينتهي 5 تشرين الثاني', 'ملاعب', 'الشعب'),
    Offer('o2', 'p7', 'food', 'مطعم بيت بغداد', 'عرض 1+1', 18000, 36000, 'ينتهي بعد 3 أيام', 'مطاعم', 'الكرادة'),
    Offer('o3', 'p4', 'gaming', 'Game Zone', 'ساعة مجانية', 15000, 20000, 'كل خميس', 'ألعاب', 'زيونة'),
  ];
  final ownerOffers = <Offer>[
    Offer('m1', 'p1', 'padel', 'خصم 25% بعد 12 بالليل', 'فعّال', 15000, 20000, 'ينتهي بعد 4 أيام', 'بادل', 'المنصور', views: 2140, clicks: 310, books: 42),
    Offer('m2', 'p1', 'friends', 'باقة الأصحاب', 'فعّال', 30000, 35000, 'ينتهي بعد 9 أيام', 'بادل', 'المنصور', views: 980, clicks: 120, books: 11),
    Offer('m3', 'p1', 'food', 'ساعة مجانية للطلاب', 'متوقف', 0, 20000, 'وقفته يوم الخميس', 'بادل', 'المنصور', views: 640, clicks: 58, books: 6, active: false),
  ];
  void createOffer(String title, int pct, String to) {
    final p = place('p1');
    final np = (p.price * (100 - pct) / 100).round();
    ownerOffers.insert(0, Offer('m${ownerOffers.length + 1}', 'p1', 'padel', title, 'فعّال', np, p.price, 'ينتهي 6 تشرين الثاني', 'بادل', 'المنصور'));
    offers.insert(0, Offer('o${offers.length + 1}', 'p1', 'padel', p.name, 'خصم $pct%', np, p.price, 'ينتهي 6 تشرين الثاني', 'بادل', 'المنصور'));
    notifyListeners();
  }

  final reels = <Reel>[
    Reel('reel', 'p1', 'ملعب بادل لاونج', 'سهرة بادل بالمنصور، الإضاءة الجديدة تجنن', 'خصم 10% قبل 9 بالليل', 1200, [
      ('حيدر', 'وين بالضبط؟ قرب الساعة؟', '5د', 12),
      ('مريم', 'يكدرون بنات يحجزون بأوقات خاصة؟', '12د', 8),
      ('ملعب بادل لاونج', 'اي عدنا أوقات عائلية كل جمعة الصبح', '10د', 20),
    ]),
    Reel('gaming', 'p4', 'Game Zone', 'بطولة FIFA كل خميس، الجائزة 100 ألف', 'ساعة مجانية كل خميس', 8100, [('كرار', 'شلون أسجل بالبطولة؟', '1س', 4)]),
    Reel('cafe', 'p6', 'كافيه ليالي', 'جلسة مسائية على الشط ويا أطيب شاي', 'خصم 15% للطلاب', 5600, [('سارة', 'المكان يجنن 😍', '2س', 9)]),
  ];
  void postReel(String caption) {
    reels.insert(0, Reel('padel', 'p1', 'ملعب بادل لاونج', caption, 'خصم 25%', 0, []));
    notifyListeners();
  }

  int _code = 4821;
  final bookings = <Booking>[
    Booking('DJ-4821', 'p1', 'السبت 31 تشرين الأول', '8:00 م', 'ساعتين', 4, 31500, 'كاش بالمكان', 'مؤكد'),
    Booking('DJ-4790', 'p3', 'الأحد 1 تشرين الثاني', '9:00 م', 'ساعتين', 4, 16000, 'كاش بالمكان', 'بالانتظار'),
    Booking('DJ-4802', 'p5', 'الجمعة 6 تشرين الثاني', '10:00 ص', '3 ساعات', 4, 100000, 'زين كاش', 'بانتظار القبول'),
    Booking('DJ-4610', 'p4', 'الخميس 22 تشرين الأول', '7:00 م', 'ساعة', 3, 15000, 'كاش بالمكان', 'مكتمل'),
    Booking('DJ-4555', 'p2', 'الجمعة 16 تشرين الأول', '6:00 م', 'ساعتين', 10, 60000, 'بطاقة', 'مكتمل', rated: true),
  ];
  Future<Booking> book({required String placeId, required String day, required String time, required String dur, required int people, required int total, required String pay, bool wait = false}) async {
    await lag(900);
    _code += 7;
    final b = Booking('DJ-$_code', placeId, day, time, dur, people, total, pay, wait ? 'بالانتظار' : 'مؤكد');
    bookings.insert(0, b);
    if (!wait) points += 45;
    notifs.insert(0, Notif(wait ? 'hourglass' : 'calendar-check', wait ? 'سجّلناك بالانتظار' : 'تم تأكيد حجزك', '${place(placeId).name} · $day $time', 'الآن', true));
    notifyListeners();
    return b;
  }
  void cancel(Booking b) { b.status = 'ملغي'; notifyListeners(); }

  final notifs = <Notif>[
    Notif('calendar-check', 'تم قبول حجزك', 'ملعب بادل لاونج · السبت 8:00 م', 'قبل 5 دقايق', true),
    Notif('hourglass', 'صار عندك مكان', 'انلغى حجز بقصر البليارد، أكّد خلال 10 دقايق', 'قبل 20 دقيقة', true),
    Notif('badge-percent', 'عرض جديد من Game Zone', 'ساعة مجانية كل خميس', 'الأربعاء'),
    Notif('trophy', 'قربت تخلص التحدي', 'باقي حجز واحد وتاخذ 150 نقطة', 'الثلاثاء'),
    Notif('message-circle', 'رد على تقييمك', 'ملعب بادل لاونج رد على تقييمك', 'الاثنين'),
  ];

  // owner
  final ownerReqs = <OwnerReq>[
    OwnerReq('friends', 'حسين علي', 'السبت 8:00 م · ساعتين · 4 أشخاص', 'زين كاش · مدفوع', 31500, 'new'),
    OwnerReq('football', 'مصطفى كريم', 'الأحد 10:00 م · ساعة', 'نقداً بالمكان', 20000, 'new'),
    OwnerReq('cafe', 'علي ناظم', 'الاثنين 9:00 م · ساعتين · 6 أشخاص', 'نقداً بالمكان', 35000, 'new'),
    OwnerReq('gaming', 'زيد حيدر', 'الأحد 11:00 م · ساعة', 'بطاقة · مدفوع', 20000, 'ok'),
    OwnerReq('padel', 'عباس محمد', 'الخميس 7:00 م · ساعتين', 'نقداً بالمكان', 35000, 'past'),
  ];
  int todayBookings = 9, todayIncome = 185000;
  void accept(OwnerReq r) { r.status = 'ok'; todayBookings++; notifyListeners(); }
  void reject(OwnerReq r) { r.status = 'rejected'; notifyListeners(); }
  void arrive(OwnerReq r) { r.arrived = true; todayIncome += r.total; notifyListeners(); }
  final ownerNotifs = <Notif>[
    Notif('calendar-check', 'طلب حجز جديد', 'حسين علي · السبت 8:00 م · 4 أشخاص', 'قبل 3 دقايق', true),
    Notif('star', 'تقييم جديد 3 نجوم', 'علي حسين كتب تقييم، رد عليه', 'قبل ساعة', true),
    Notif('circle-check', 'تفعّل مشروعك', 'ملعب بادل لاونج صار يظهر للناس', 'أمس'),
    Notif('trending-up', 'عرضك ماشي زين', 'خصم 25% جاب 42 حجز هالأسبوع', 'الخميس'),
    Notif('hourglass', 'العرض قرب يخلص', 'باقة الأصحاب تنتهي بعد يومين', 'الأربعاء'),
  ];
  final services = <(String, int, String)>[('ساعة ملعب', 20000, 'ساعة'), ('باقة ساعتين', 35000, 'باقة'), ('تأجير مضارب', 3000, 'مضرب')];
  final closed = <String>{'10:00 م'};
  bool projectPending = false;

  Future<Role> login(String ph) async {
    await lag();
    phone = ph;
    role = ph == demoOwner ? Role.owner : Role.customer;
    userName = role == Role.owner ? 'أبو علي' : 'حسين علي';
    notifyListeners();
    return role;
  }
  bool get isNewUser => phone != demoCustomer && phone != demoOwner;
  void logout() { role = Role.none; homeLoaded = false; notifyListeners(); }
  void touch() => notifyListeners();
}

final repo = Repo.i;
String phoneFmt(String p) => p.length == 11 ? '${p.substring(0, 4)} ${p.substring(4, 7)} ${p.substring(7)}' : p;
String kfmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : '$n';
