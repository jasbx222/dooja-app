import 'package:flutter/material.dart';
import '../dsl.dart';
import '../common.dart';
import '../app.dart';
import '../repo.dart';
import 'auth.dart';
import 'flow.dart';
import 'home.dart';
import 'place.dart';
import 'owner.dart';

(String, String) stColor(String st) => switch (st) {
      'مؤكد' => ('#E8F7EE', OK),
      'بالانتظار' => (PL, P),
      'بانتظار القبول' => (WRB, WR),
      'ملغي' => ('#FDECEC', RD),
      _ => (G, MU),
    };

class Bookings extends Scr {
  const Bookings({super.key});
  @override
  Widget view(c, s) {
    final t = s.get('t', 0);
    final up = repo.bookings.where((b) => ['مؤكد', 'بالانتظار', 'بانتظار القبول'].contains(b.status)).toList();
    final past = repo.bookings.where((b) => !up.contains(b)).toList();
    Widget bk(Booking b) {
      final p = repo.place(b.placeId);
      final stc = stColor(b.status);
      final acts = <Widget>[
        if (b.status == 'مؤكد') ...[btn('رمز الدخول', icon: 'qr-code', h: 40, tap: () => push(c, BookingDetail(b))), btn('إلغاء', kind: 'g', h: 40, w: 90, tap: () => cancelDialog(c, b))],
        if (b.status == 'بالانتظار' || b.status == 'بانتظار القبول') btn('تفاصيل', kind: 'g', h: 40, tap: () => push(c, BookingDetail(b))),
        if (b.status == 'مكتمل' && !b.rated) btn('قيّم تجربتك', icon: 'star', kind: 's', h: 40, tap: () => push(c, Rate(b))),
        if (b.status == 'مكتمل') btn('احجز مرة ثانية', kind: 'g', h: 40, tap: () => push(c, BookSlot(b.placeId))),
      ];
      return card([
        R([
          img(p.img, 72, 72, 14),
          F([R([T(p.name, 15, 800), tag(b.status, bg: stc.$1, c: stc.$2)], jc: 'sb', w: 'fill'), meta('calendar', '${b.day} · ${b.time}'), meta('users', '${b.people} أشخاص · ${fmt(b.total)} د.ع')], g: 5, w: 'fill'),
        ], g: 12, al: 's', w: 'fill', tap: () => push(c, BookingDetail(b))),
        if (acts.isNotEmpty) R(acts, g: 8, w: 'fill'),
      ], p: 12, g: 12);
    }

    final list = t == 0 ? up : past;
    return screen(c, [
      topbar('حجوزاتي', back: false),
      F([tabs(['القادمة', 'السابقة'], t, (i) => s.set('t', i))], w: 'fill', p: [4, 20]),
      if (list.isEmpty)
        F([BOX(h: 80, w: 1), F([I('calendar-check', 44, P)], al: 'c', jc: 'c', w: 110, h: 110, r: 32, bg: PL), Tn('ماكو حجوزات هنا', s: 20, w: 800, al: 'CENTER'), btn('اكتشف أماكن', icon: 'compass', w: 220, tap: () => onCustomerTab(c, 'الرئيسية'))], g: 16, al: 'c', w: 'fill')
      else
        F([for (final b in list) bk(b)], g: 12, w: 'fill', p: [8, 20]),
    ], nav: 'حجوزاتي');
  }
}

Future<void> cancelDialog(BuildContext c, Booking b) => openSheet(c, title: 'تلغي الحجز؟', top: 560, body: (sc, set) => [
      Tn('الإلغاء مجاني لحد 4 ساعات قبل الموعد. ${repo.place(b.placeId).name} · ${b.day} ${b.time}', s: 14, c: MU, w2: 'fill', lh: 22),
      R([btn('لا، خليه', kind: 'g', tap: () => Navigator.pop(sc)), btn('إلغاء الحجز', kind: 'd', tap: () { repo.cancel(b); Navigator.pop(sc); toast(c, 'انلغى الحجز ${b.code}'); })], g: 10, w: 'fill'),
    ]);

class BookingDetail extends Scr {
  final Booking b;
  const BookingDetail(this.b, {super.key});
  @override
  Widget view(c, s) {
    final p = repo.place(b.placeId);
    return screen(c, [
      topbar('حجزك', sub: b.code),
      F([
        card([F([S(qrSvg(b.code), 190, 190), Tn(b.status == 'مؤكد' ? 'اعرض الرمز عند الوصول' : 'حالة الحجز: ${b.status}', s: 14, w: 700, al: 'CENTER'), Tn('يتفعّل قبل الموعد بـ 30 دقيقة', s: 12, c: MU, al: 'CENTER')], g: 8, al: 'c', w: 'fill')], p: 20),
        card([
          R([T(p.name, 14, 700), T('المكان', 13, 400, MU)], jc: 'sb', w: 'fill'),
          R([T('${b.day.split(' ').take(2).join(' ')} · ${b.time}', 14, 700), T('الموعد', 13, 400, MU)], jc: 'sb', w: 'fill'),
          R([T('${b.people} أشخاص', 14, 700), T('الأشخاص', 13, 400, MU)], jc: 'sb', w: 'fill'),
          R([T('${fmt(b.total)} د.ع · ${b.pay}', 14, 700), T('الدفع', 13, 400, MU)], jc: 'sb', w: 'fill'),
        ], g: 12),
        R([btn('الاتجاهات', icon: 'navigation', kind: 's', h: 46, tap: () => toast(c, 'يفتح الخريطة على ${p.area}')), btn('اتصال', icon: 'phone', kind: 'g', h: 46, tap: () => toast(c, 'يتصل بـ ${p.phone}'))], g: 10, w: 'fill'),
        if (b.status != 'ملغي' && b.status != 'مكتمل')
          F([Tn('الإلغاء مجاني لحد 4 ساعات قبل الموعد', s: 12, c: MU, al: 'CENTER'), F([Tn('إلغاء الحجز', s: 14, w: 800, c: RD, al: 'CENTER')], tap: () => cancelDialog(c, b))], g: 6, al: 'c', w: 'fill'),
      ], g: 14, w: 'fill', p: [4, 20]),
    ]);
  }
}

class Rate extends Scr {
  final Booking b;
  const Rate(this.b, {super.key});
  @override
  Widget view(c, s) {
    final p = repo.place(b.placeId);
    final st = s.get('st', 4);
    final tags = s.get('tags', <String>{'نظيف', 'سعر مناسب', 'إضاءة قوية'});
    final ctl = s.ctl('t', 'الأرضية ممتازة والإضاءة قوية، الحجز كان سهل.');
    final busy = s.get('busy', false);
    const words = ['سيئة', 'مقبولة', 'زينة', 'حلوة', 'رهيبة'];
    return screen(c, [
      topbar('قيّم تجربتك'),
      F([
        R([img(p.img, 56, 56, 14), F([T(p.name, 15, 800), T('زرته ${b.day}', 12, 400, MU)], g: 2)], g: 12, al: 'c'),
        F([Tn('شلون كانت تجربتك؟', s: 17, w: 800, al: 'CENTER'), R([for (var i = 0; i < 5; i++) F([I('star', 38, i < st ? STAR : '#D9D6E3', i < st ? STAR : '#D9D6E3')], tap: () => s.set('st', i + 1))], g: 10, ltr: true), Tn(words[st - 1], s: 14, w: 700, c: P, al: 'CENTER')], g: 10, al: 'c', w: 'fill', p: [10, 0]),
        R([for (final l in ['نظيف', 'سعر مناسب', 'خدمة ممتازة', 'إضاءة قوية']) chip(l, tags.contains(l), null, 13, () { tags.contains(l) ? tags.remove(l) : tags.add(l); s.set('x', l); })], g: 8, wrap: true, w: 'fill'),
        F([N(TextField(controller: ctl, maxLines: 4, style: ts(14, 400, INK, lh: 22), cursorColor: col(P), decoration: const InputDecoration(isCollapsed: true, border: InputBorder.none)), fillW: true)], w: 'fill', h: 110, p: 14, r: 16, bg: G),
        R([img('padel', 72, 72, 14), img('football', 72, 72, 14), F([I('camera', 22, P), Tn('أضف', s: 11, w: 700, c: P, al: 'CENTER')], g: 4, al: 'c', jc: 'c', w: 72, h: 72, r: 14, bg: PL, sk: P, dash: true, tap: () => toast(c, 'اختار صور من المعرض'))], g: 10),
      ], g: 16, w: 'fill', p: [4, 20]),
    ], bottomBar: bottom([btn('أرسل التقييم · +20 نقطة', busy: busy, tap: () async {
      s.set('busy', true);
      await repo.lag(700);
      repo.addReview(b.placeId, st, ctl.text);
      b.rated = true;
      if (!c.mounted) return;
      Navigator.pop(c);
      toast(c, 'شكراً! انضافت 20 نقطة لحسابك');
    })]));
  }
}

class Offers extends Scr {
  const Offers({super.key});
  @override
  Widget view(c, s) {
    final ch = s.get('ch', 'الكل');
    final list = repo.offers.where((o) => ch == 'الكل' || (ch == 'ينتهي قريب' && o.exp.contains('بعد')) || o.cat == ch).toList();
    Widget oc(Offer o) => card([
          img(o.img, 318, 120, 14, [tag(o.disc, bg: P, c: WH, s: 13)], 'h', 10, 's'),
          R([F([T(o.place, 15, 800), meta('clock', o.exp)], g: 4), F([T('${fmt(o.newP)} د.ع', 16, 800, P), Tn(fmt(o.oldP), s: 12, c: MU, st: true)], g: 2, al: 'e')], jc: 'sb', w: 'fill'),
        ], p: 12, tap: () => push(c, OfferDetail(o)));
    return screen(c, [
      topbar('عروض وخصومات', back: Navigator.of(c).canPop()),
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: R([for (final (l, i) in [('الكل', null), ('ينتهي قريب', 'clock'), ('ملاعب', null), ('مطاعم', null), ('ألعاب', null)]) chip(l, ch == l, i, 13, () => s.set('ch', l))], g: 8, p: [4, 20])),
      F([for (final o in list) oc(o)], g: 12, w: 'fill', p: [8, 20]),
    ], nav: 'الرئيسية');
  }
}

class OfferDetail extends Scr {
  final Offer o;
  const OfferDetail(this.o, {super.key});
  @override
  Widget view(c, s) => screen(c, [
        img(o.img, 390, 230, 0, [status(true), F([iconbtn('arrow-right', tap: () => Navigator.pop(c))], w: 'fill', p: [4, 20])]),
        F([
          R([F([T(o.place, 20, 800), meta('map-pin', '${o.cat} · ${o.area}')], g: 4), tag(o.disc, bg: P, c: WH, s: 14)], jc: 'sb', al: 's', w: 'fill'),
          R([T('${fmt(o.newP)} د.ع', 24, 800, P), Tn('${fmt(o.oldP)} د.ع', s: 14, c: MU, st: true), T('لل${repo.place(o.placeId).unit}', 13, 400, MU)], g: 8, al: 'c'),
          R([R([I('clock', 18, WR), T(o.id == 'o1' ? 'باقي 4 أيام و 6 ساعات' : o.exp, 14, 700, WR)], g: 8)], jc: 's', w: 'fill', p: 12, r: 14, bg: WRB),
          F([T('الشروط', 16, 800), for (final t in ['من الأحد للخميس قبل 6 العصر', 'حجز واحد لكل مستخدم', 'ما ينجمع ويا عروض ثانية']) R([I('check', 16, P), Tn(t, s: 14, w2: 300)], g: 8, al: 's')], g: 10, w: 'fill'),
          F([T('شلون تستفاد', 16, 800), for (final (i, t) in [(1, 'اضغط "احجز بالعرض"'), (2, 'اختار موعد ضمن أوقات العرض'), (3, 'الخصم يتطبق تلقائي بالفاتورة')]) R([F([Tn('$i', s: 12, w: 800, c: P, al: 'CENTER')], al: 'c', jc: 'c', w: 24, h: 24, r: 12, bg: PL), Tn(t, s: 14, w2: 290)], g: 10, al: 'c')], g: 10, w: 'fill'),
        ], g: 16, w: 'fill', p: [16, 20]),
      ], bottomBar: bottom([R([iconbtn('share-2', s: 52, tap: () => toast(c, 'نسخنا رابط العرض')), btn('احجز بالعرض', icon: 'ticket-percent', tap: () => push(c, BookSlot(o.placeId, dur: 0, offer: o)))], g: 10, w: 'fill')]));
}

class Reels extends Scr {
  final int start;
  const Reels({super.key, this.start = 0});
  @override
  Widget view(c, s) {
    final pc = s.get('pc', PageController(initialPage: start));
    final tab = s.get('tab', 1);
    final list = tab == 0 ? repo.reels.where((r) => repo.follows.contains(r.placeId)).toList() : repo.reels;
    final hh = MediaQuery.of(c).size.height;
    Widget page(Reel r) {
      final side = F([
        for (final (i, n, f, tp) in [
          ('heart', kfmt(r.likes + (r.liked ? 1 : 0)), r.liked ? '#E5484D' : null, () { r.liked = !r.liked; repo.touch(); }),
          ('message-circle', '${r.comments.length + (r.place == 'ملعب بادل لاونج' && r.img == 'reel' ? 83 : 0)}', null, () => commentsSheet(c, r)),
          ('bookmark', 'حفظ', r.saved ? WH : null, () { r.saved = !r.saved; repo.touch(); toast(c, r.saved ? 'انحفظ بالمفضلة' : 'انشال من المحفوظات'); }),
          ('share-2', 'مشاركة', null, () => toast(c, 'نسخنا رابط الريل')),
        ])
          F([I(i, 28, WH, f), Tn(n, s: 12, w: 700, c: WH, al: 'CENTER')], g: 4, al: 'c', tap: tp),
      ], g: 20, al: 'c');
      final follow = repo.follows.contains(r.placeId);
      final info = F([
        R([F([Tn(r.place.characters.first, s: 14, w: 800, c: P, al: 'CENTER')], al: 'c', jc: 'c', w: 38, h: 38, r: 19, bg: WH), T(r.place, 15, 800, WH), R([T(follow ? 'متابَع' : 'متابعة', 12, 800, WH)], g: 4, r: 10, p: [5, 10], sk: WH, tap: () => repo.toggleFollow(r.placeId))], g: 8, al: 'c', tap: () => push(c, Details(r.placeId))),
        Tn(r.caption, s: 14, c: WH, w2: 290, lh: 21),
        R([R([I('ticket-percent', 16, WH), T(r.offer, 13, 700, WH)], g: 6, p: [8, 12], r: 12, bg: '#FFFFFF33')], g: 8),
        btn('احجز هالنشاط', icon: 'calendar-check', w: 300, h: 46, tap: () => push(c, BookSlot(r.placeId))),
      ], g: 12);
      return Stack(children: [
        Positioned.fill(child: Image.asset('assets/img/${r.img}.jpg', fit: BoxFit.cover)),
        Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [col('#11111100'), col('#111111CC')])))),
        Positioned(left: 334, top: 380 * hh / 844, child: side),
        Positioned(left: 20, top: 560 * hh / 844, child: info),
      ]);
    }

    return Scaffold(
        backgroundColor: col(INK),
        body: Stack(children: [
          if (list.isEmpty)
            Center(child: Tn('تابع أماكن حتى تشوف ريلزهم هنا', s: 15, w: 700, c: WH))
          else
            PageView(controller: pc, scrollDirection: Axis.vertical, children: [for (final r in list) page(r)]),
          Column(children: [
            status(true),
            R([R([if (Navigator.of(c).canPop()) F([I('arrow-right', 22, WH)], tap: () => Navigator.pop(c)), T('ريلز ضوجة', 18, 800, WH)], g: 10), R([F([T('متابَعين', 14, tab == 0 ? 800 : 500, tab == 0 ? WH : '#FFFFFFAA')], tap: () => s.set('tab', 0)), F([T('لك', 14, tab == 1 ? 800 : 500, tab == 1 ? WH : '#FFFFFFAA')], tap: () => s.set('tab', 1))], g: 14)], jc: 'sb', w: 'fill', p: [8, 20]),
          ]),
          Positioned(left: 0, bottom: 0, child: navbar(c, 'الرئيسية')),
        ]));
  }
}

Future<void> commentsSheet(BuildContext c, Reel r) {
  final ctl = TextEditingController();
  Widget cm((String, String, String, int) x) => R([
        avatar(x.$1, 34, 13),
        F([R([T(x.$1, 13, 700), T(x.$3, 11, 400, MU)], g: 6), Tn(x.$2, s: 14, w2: 250, lh: 21), T('رد', 12, 700, MU)], g: 4),
        F([I('heart', 16, MU), T('${x.$4}', 11, 400, MU)], al: 'c', g: 2),
      ], g: 10, al: 's', w: 'fill', jc: 'sb');
  final extra = r.img == 'reel' ? 83 : 0;
  return openSheet(c, title: 'التعليقات (${r.comments.length + extra})', top: 380, body: (sc, set) => [
        Expanded(child: SingleChildScrollView(child: F([for (final x in r.comments) cm(x)], g: 16, w: 'fill'))),
        R([
          R([N(field(ctl, 'اكتب تعليق...', 14), fillW: true)], g: 8, bg: G, r: 22, h: 46, w: 'fill', p: [0, 16]),
          F([I('send', 20, WH)], al: 'c', jc: 'c', w: 46, h: 46, r: 23, bg: P, tap: () {
            if (ctl.text.trim().isEmpty) return;
            set(() => r.comments.insert(0, (repo.userName.split(' ').first, ctl.text.trim(), 'الآن', 0)));
            ctl.clear();
            repo.touch();
          }),
        ], g: 10, w: 'fill', al: 'c'),
      ]);
}

class Favs extends Scr {
  const Favs({super.key});
  @override
  Widget view(c, s) {
    final t = s.get('t', 0);
    final places = repo.places.where((p) => repo.favs.contains(p.id)).toList();
    final follows = repo.places.where((p) => repo.follows.contains(p.id)).toList();
    final saved = repo.reels.where((r) => r.saved).toList();
    Widget follow(Place p, String? nw) => R([R([img(p.img, 52, 52, 26), F([T(p.name, 14, 800), T('${p.type} · ${p.area}', 12, 400, MU)], g: 2)], g: 10, al: 'c', tap: () => push(c, Details(p.id))), nw != null ? tag(nw, icon: 'bell') : F([T('متابَع', 12, 700, MU)], tap: () => repo.toggleFollow(p.id))], jc: 'sb', w: 'fill', al: 'c');
    Widget empty(String icon, String title, String sub) => F([
          BOX(w: 10, h: 120),
          F([
            F([I(icon, 44, P)], al: 'c', jc: 'c', w: 110, h: 110, r: 32, bg: PL),
            Tn(title, s: 20, w: 800, al: 'CENTER'),
            Tn(sub, s: 14, c: MU, al: 'CENTER', w2: 290, lh: 22),
            btn('اكتشف أماكن', icon: 'compass', w: 220, tap: () => onCustomerTab(c, 'الرئيسية')),
          ], g: 16, al: 'c', w: 'fill'),
        ], w: 'fill');
    final followsW = [T('المشاريع اللي تتابعها', 16, 800), card([for (var i = 0; i < follows.length; i++) ...[if (i > 0) divider(), follow(follows[i], follows[i].id == 'p4' ? 'عرض جديد' : null)]], g: 12)];
    return screen(c, [
      topbar('المفضلة', back: false),
      F([tabs(['الأماكن', 'المشاريع المتابَعة', 'الريلز'], t, (i) => s.set('t', i))], w: 'fill', p: [4, 20]),
      if (t == 0)
        places.isEmpty
            ? empty('heart', 'بعدك ما حفظت أي مكان', 'اضغط على القلب بأي مكان يعجبك حتى تلگاه هنا بسرعة')
            : F([for (final p in places) rowcard(c, p), if (follows.isNotEmpty) ...followsW], g: 12, w: 'fill', p: [8, 20]),
      if (t == 1) follows.isEmpty ? empty('store', 'ما تتابع أي مشروع', 'تابع الأماكن حتى توصلك عروضهم وريلزهم') : F(followsW, g: 12, w: 'fill', p: [8, 20]),
      if (t == 2)
        saved.isEmpty
            ? empty('bookmark', 'ما حفظت ريلز', 'اضغط حفظ على أي ريل حتى تلگاه هنا')
            : F([R([for (final r in saved) img(r.img, 108, 180, 16, [T(r.place, 12, 800, WH)], 'v', 10, 's', 'e', 0, null, () => push(c, Reels(start: repo.reels.indexOf(r))))], g: 9, wrap: true, w: 'fill')], w: 'fill', p: [8, 20]),
    ], nav: 'المفضلة');
  }
}

class Rewards extends Scr {
  const Rewards({super.key});
  @override
  Widget view(c, s) {
    final pts = repo.points;
    final toGold = (1500 - pts).clamp(0, 1500);
    final done = repo.bookings.where((b) => b.status == 'مؤكد').length;
    Widget ch(String icon, String t, String sub, int cur, int tot, int p) => card([
          R([R([F([I(icon, 22, P)], al: 'c', jc: 'c', w: 44, h: 44, r: 14, bg: PL), F([T(t, 15, 800), T(sub, 12, 400, MU)], g: 2)], g: 12, al: 'c'), T('+$p', 14, 800, P)], jc: 'sb', w: 'fill'),
          R([F([BOX(w: (250 * cur.clamp(0, tot) / tot).roundToDouble(), h: 8, r: 4, bg: P)], d: 'h', w: 250, h: 8, r: 4, bg: G), T('${cur.clamp(0, tot)}/$tot', 12, 700)], g: 10, al: 'c', jc: 'sb', w: 'fill'),
        ], p: 14, g: 12);
    return screen(c, [
      topbar('المكافآت', back: Navigator.of(c).canPop()),
      F([
        F([
          R([F([T('نقاطك', 14, 500, PL), T(fmt(pts), 34, 800, WH)], g: 2), F([MARK(70, WH, WH)])], jc: 'sb', al: 'c', w: 'fill'),
          R([T(toGold == 0 ? 'المستوى الذهبي' : 'المستوى الفضي', 13, 700, WH), T(toGold == 0 ? 'وصلت للذهبي!' : 'باقي $toGold نقطة للذهبي', 12, 400, PL)], jc: 'sb', w: 'fill'),
          LayoutBuilder(builder: (_, bc) => F([BOX(w: bc.maxWidth * (pts / 1500).clamp(0, 1), h: 8, r: 4, bg: WH)], d: 'h', w: 'fill', h: 8, r: 4, bg: '#FFFFFF40')),
        ], g: 12, w: 'fill', p: 20, r: 24, bg: P),
        R([
          for (final (i, t) in [('ticket', 'استبدل النقاط'), ('user-plus', 'ادعُ صديق'), ('medal', 'الإنجازات')])
            F([I(i, 22, P), Tn(t, s: 12, w: 700, al: 'CENTER')], g: 6, al: 'c', w: 'fill', p: [14, 4], r: 16, bg: G, tap: () => toast(c, i == 'ticket' ? 'كل 1000 نقطة = 10,000 د.ع خصم' : i == 'user-plus' ? 'كود دعوتك: HUSSEIN500' : '6 إنجازات من 20')),
        ], g: 10, w: 'fill'),
        R([T('تحديات الأسبوع', 17, 800), T('تنتهي بعد 3 أيام', 12, 400, MU)], jc: 'sb', w: 'fill'),
        ch('dribbble', 'العب 3 مرات بالملاعب', 'احجز 3 مرات هالأسبوع', 1 + done.clamp(0, 2), 3, 150),
        ch('star', 'قيّم مكانين', 'بعد زيارتك', repo.bookings.where((b) => b.rated).length, 2, 40),
        ch('compass', 'جرّب قسم جديد', 'أول مرة تحجز بليارد', 0, 1, 80),
      ], g: 14, w: 'fill', p: [4, 20]),
    ], nav: 'حسابي');
  }
}

class Notifs extends Scr {
  final bool owner;
  const Notifs({super.key, this.owner = false});
  @override
  Widget view(c, s) {
    final list = owner ? repo.ownerNotifs : repo.notifs;
    Widget nt(Notif n) => R([
          F([I(n.icon, 20, P)], al: 'c', jc: 'c', w: 42, h: 42, r: 14, bg: PL),
          F([T(n.title, 14, 800), Tn(n.body, s: 13, c: MU, w2: 250, lh: 20), T(n.ago, 11, 400, MU)], g: 3),
          if (n.fresh && !owner) BOX(w: 8, h: 8, r: 4, bg: P),
        ], g: 12, al: 's', w: 'fill', p: [14, 20], bg: n.fresh ? BG : WH, tap: () {
          n.fresh = false;
          repo.touch();
          if (owner) {
            if (n.icon == 'calendar-check') onOwnerTab(c, 'الحجوزات');
            if (n.icon == 'star') push(c, const OReviews());
            if (n.icon == 'trending-up' || n.icon == 'hourglass') push(c, const OOffPerf());
          } else {
            if (n.icon == 'calendar-check' || n.icon == 'hourglass') onCustomerTab(c, 'حجوزاتي');
            if (n.icon == 'badge-percent') push(c, const Offers());
            if (n.icon == 'trophy') push(c, const Rewards());
          }
        });
    final fresh = list.where((n) => n.ago.contains('قبل') || n.ago == 'الآن').toList();
    final older = list.where((n) => !fresh.contains(n)).toList();
    return screen(c, [
      topbar('الإشعارات', right: owner ? null : F([T('قراءة الكل', 12, 700, P)], tap: () { for (final n in list) { n.fresh = false; } repo.touch(); })),
      if (!owner) F([T('اليوم', 13, 700, MU)], w: 'fill', p: [8, 20]),
      for (final n in (owner ? list : fresh)) nt(n),
      if (!owner) F([T('هذا الأسبوع', 13, 700, MU)], w: 'fill', p: [8, 20]),
      if (!owner) for (final n in older) nt(n),
    ]);
  }
}

class Group extends Scr {
  final Booking? b;
  const Group([this.b]);
  @override
  Widget view(c, s) {
    final b = this.b ?? repo.bookings.firstWhere((x) => x.status == 'مؤكد', orElse: () => repo.bookings.first);
    final p = repo.place(b.placeId);
    final mem = s.get('mem', <(String, String, bool)>[('أنت (المنظّم)', 'دفع حصته', true), ('حسن', 'دفع حصته', true), ('مصطفى', 'وافق', true), ('كرار', 'بانتظار الرد', false)]);
    final eq = s.get('eq', true);
    final share = (b.total / b.people).round();
    Widget m((String, String, bool) x) => R([R([avatar(x.$1, 38), T(x.$1, 14, 700)], g: 10, al: 'c'), R([T(x.$2, 12, 700, x.$3 ? OK : MU), I(x.$3 ? 'circle-check' : 'clock', 16, x.$3 ? OK : MU)], g: 4)], jc: 'sb', w: 'fill', al: 'c');
    return screen(c, [
      topbar('طلعة جماعية', sub: '${b.day.split(' ').first} ${b.time} · ${p.type}'),
      F([
        card([R([img(p.img, 60, 60, 14), F([T(p.name, 15, 800), T('${b.dur} · ${fmt(b.total)} د.ع', 12, 400, MU)], g: 2)], g: 12, al: 'c', w: 'fill')], p: 12),
        R([T('الأصحاب (${mem.where((x) => x.$3).length} من ${mem.length})', 16, 800), F([T('+ أضف', 14, 800, P)], tap: () { mem.add(('صديق ${mem.length}', 'بانتظار الرد', false)); s.set('x', mem.length); })], jc: 'sb', w: 'fill'),
        card([for (var i = 0; i < mem.length; i++) ...[if (i > 0) divider(), m(mem[i])]], g: 12),
        F([
          T('تقسيم المبلغ', 16, 800),
          R([chip('بالتساوي', eq, null, 13, () => s.set('eq', true)), chip('مبالغ مخصصة', !eq, null, 13, () => s.set('eq', false))], g: 8),
          R([T(eq ? 'حصة كل واحد' : 'حصتك (المنظّم)', 14, 400, MU), T('${fmt(eq ? share : (b.total - share * (mem.length - 1)).clamp(0, b.total))} د.ع', 16, 800, P)], jc: 'sb', w: 'fill', p: 14, r: 14, bg: G),
        ], g: 10, w: 'fill'),
        R([I('link', 18, P), Tn('dooja.app/g/${b.code.substring(3)}', s: 14, w: 700, c: P, w2: 'fill', al: 'LEFT'), F([I('copy', 18, P)], tap: () => toast(c, 'نسخنا رابط الدعوة'))], g: 8, w: 'fill', p: 14, r: 14, bg: PL),
      ], g: 14, w: 'fill', p: [4, 20]),
    ], bottomBar: bottom([btn('شارك الدعوة', icon: 'share-2', tap: () => toast(c, 'دزّينا الدعوة لأصحابك'))]));
  }
}

class Profile extends Scr {
  const Profile({super.key});
  @override
  Widget view(c, s) {
    Widget it(String i, String t, [String? v, VoidCallback? tap]) => R([R([I(i, 20, INK), T(t, 15, 500)], g: 12), R([if (v != null) T(v, 13, 400, MU), I('chevron-left', 18, MU)], g: 6)], jc: 'sb', w: 'fill', p: [14, 0], tap: tap ?? () => toast(c, 'قريباً'));
    final upcoming = repo.bookings.where((b) => b.status == 'مؤكد').length;
    return screen(c, [
      topbar('حسابي', back: false, right: iconbtn('settings', tap: () => push(c, const Settings()))),
      F([
        R([R([avatar(repo.userName, 64, 24), F([T(repo.userName, 18, 800), T('${phoneFmt(repo.phone.isEmpty ? Repo.demoCustomer : repo.phone)} · ${repo.gov}', 13, 400, MU)], g: 4)], g: 14, al: 'c'), F([T('تعديل', 13, 800, P)], tap: () => push(c, const Edit()))], jc: 'sb', al: 'c', w: 'fill'),
        R([
          for (final (a, b, tp) in [('${repo.bookings.length + 7}', 'حجز', () => onCustomerTab(c, 'حجوزاتي')), (fmt(repo.points), 'نقطة', () => push(c, const Rewards())), ('${repo.follows.length + 6}', 'متابَع', () => onCustomerTab(c, 'المفضلة'))])
            F([Tn(a, s: 18, w: 800, al: 'CENTER'), Tn(b, s: 12, c: MU, al: 'CENTER')], g: 2, al: 'c', w: 'fill', tap: tp),
        ], w: 'fill', p: 14, r: 18, bg: G),
        F([
          it('calendar-check', 'حجوزاتي', '$upcoming قادم', () => onCustomerTab(c, 'حجوزاتي')), divider(),
          it('users', 'طلعاتي الجماعية', null, () => push(c, const Group())), divider(),
          it('star', 'تقييماتي', null, () => push(c, Reviews('p1'))), divider(),
          it('user-plus', 'ادعُ أصحابك', '500 نقطة', () => push(c, const Rewards())), divider(),
          it('store', 'سجّل مشروعك على ضوجة', null, () => push(c, const OIntro())),
        ], w: 'fill'),
        F([
          it('globe', 'اللغة', 'العربية', () => toast(c, 'الإنكليزي والكردي قريباً')), divider(),
          it('map-pin', 'المحافظة', repo.gov, () => push(c, const Gov(fromSettings: true))), divider(),
          it('circle-help', 'المساعدة والدعم', null, () => toast(c, 'فريق الدعم: 0780 000 3652 · واتساب')),
        ], w: 'fill'),
      ], g: 16, w: 'fill', p: [4, 20]),
    ], nav: 'حسابي');
  }
}

class Edit extends Scr {
  const Edit({super.key});
  @override
  Widget view(c, s) {
    final n = s.ctl('n', repo.userName), b = s.ctl('b', repo.birth), a = s.ctl('a', '${repo.gov} · ${repo.area}');
    final busy = s.get('busy', false);
    return screen(c, [
      topbar('تعديل الحساب'),
      F([
        F([F([F([Tn(repo.userName.characters.first, s: 32, w: 800, c: P, al: 'CENTER')], al: 'c', jc: 'c', w: 96, h: 96, r: 48, bg: PL), F([I('camera', 16, WH)], al: 'c', jc: 'c', w: 32, h: 32, r: 16, bg: P, ab: [64, 64], tap: () => toast(c, 'اختار صورة'))], w: 96, h: 96)], w: 'fill', al: 'c'),
        inp('الاسم', '', ctl: n),
        inp('رقم الموبايل', phoneFmt(repo.phone.isEmpty ? Repo.demoCustomer : repo.phone), lead: F([T('تغيير', 13, 700, P)], tap: () => toast(c, 'نرسلك رمز تحقق للرقم الجديد'))),
        inp('تاريخ الميلاد', '', icon: 'calendar', ctl: b),
        inp('المحافظة والمنطقة', '', icon: 'map-pin', ctl: a),
      ], g: 18, w: 'fill', p: [8, 20]),
    ], bottomBar: bottom([btn('احفظ', busy: busy, tap: () async {
      s.set('busy', true);
      await repo.lag(500);
      repo.userName = n.text.trim().isEmpty ? repo.userName : n.text.trim();
      repo.birth = b.text;
      repo.touch();
      if (!c.mounted) return;
      Navigator.pop(c);
      toast(c, 'انحفظت التغييرات');
    })]));
  }
}

class Settings extends Scr {
  const Settings({super.key});
  @override
  Widget view(c, s) {
    final st = repo.settings;
    Widget row(String t, String? sub) => R([F([T(t, 15, 500), if (sub != null) T(sub, 12, 400, MU)], g: 2), toggle(st[t]!, () { if (t == 'الوضع الداكن') { toast(c, 'الوضع الداكن قريباً'); return; } st[t] = !st[t]!; repo.touch(); })], jc: 'sb', w: 'fill', al: 'c', p: [12, 0]);
    return screen(c, [
      topbar('الإعدادات'),
      F([
        T('الإشعارات', 13, 700, MU), row('الحجوزات والتذكير', null), row('العروض الجديدة', null), row('ردود وتعليقات', null),
        T('الخصوصية', 13, 700, MU), row('اقتراحات حسب نشاطي', 'نستخدم حجوزاتك السابقة حتى نقترحلك'), row('مشاركة موقعي', 'لعرض الأماكن القريبة'),
        T('المظهر', 13, 700, MU), row('الوضع الداكن', 'قريباً'),
        divider(),
        R([I('log-out', 20, RD), T('تسجيل الخروج', 15, 700, RD)], g: 10, p: [8, 0], tap: () { repo.logout(); resetTo(c, const Login(), anim: true); }),
        F([T('حذف الحساب', 13, 500, MU)], tap: () => toast(c, 'بالحساب التجريبي ما ينحذف')),
      ], g: 10, w: 'fill', p: [4, 20]),
    ]);
  }
}

class Offline extends Scr {
  const Offline({super.key});
  @override
  Widget view(c, s) {
    final busy = s.get('busy', false);
    return screen(c, [
      BOX(w: 10, h: 180),
      F([
        F([I('wifi-off', 44, P)], al: 'c', jc: 'c', w: 110, h: 110, r: 32, bg: PL),
        Tn('ماكو اتصال بالإنترنت', s: 20, w: 800, al: 'CENTER'),
        Tn('تأكد من الواي فاي أو البيانات وحاول مرة ثانية. حجوزاتك المحفوظة تكدر تشوفها بدون نت.', s: 14, c: MU, al: 'CENTER', w2: 300, lh: 22),
        btn('حاول مرة ثانية', icon: 'refresh-cw', w: 220, busy: busy, tap: () async {
          s.set('busy', true);
          await repo.lag(900);
          repo.offline = false;
          repo.homeLoaded = false;
          if (c.mounted) onCustomerTab(c, 'الرئيسية');
        }),
        F([Tn('افتح حجوزاتي', s: 14, w: 700, c: P, al: 'CENTER')], tap: () { repo.offline = false; onCustomerTab(c, 'حجوزاتي'); }),
      ], g: 16, al: 'c', w: 'fill'),
    ], nav: 'الرئيسية');
  }
}
