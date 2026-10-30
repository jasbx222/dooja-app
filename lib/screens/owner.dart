import 'package:flutter/material.dart';
import '../dsl.dart';
import '../common.dart';
import '../app.dart';
import '../repo.dart';
import 'home.dart' show MAPSVG, SvgFill;
import 'more.dart';
import 'place.dart';

N body(List<Widget?> k, {double g = 16, dynamic p = const [4, 20]}) => F(k, g: g, w: 'fill', p: p);
N steps(int n, String label, [int tot = 5]) => F([
      R([T(label, 14, 800), T('الخطوة $n من $tot', 12, 700, MU)], jc: 'sb', w: 'fill'),
      R([for (var i = 0; i < tot; i++) BOX(w: 'fill', h: 6, r: 3, bg: i < n ? P : G)], g: 6, w: 'fill'),
    ], g: 8, w: 'fill', p: [4, 20]);
N stat(String t, String v, [String? d, bool up = true, VoidCallback? tap]) => F([T(t, 12, 500, MU), T(v, 22, 800), if (d != null) T(d, 12, 700, up ? OK : RD)], g: 4, w: 'fill', p: 14, r: 18, bg: G, tap: tap);
N upbox(String t, {double h = 120, dynamic w = 'fill', VoidCallback? tap}) => F([I('image-plus', 26, P), Tn(t, s: 12, w: 700, c: P, al: 'CENTER')], g: 6, al: 'c', jc: 'c', w: w, h: h, r: 18, bg: BG, sk: '#C9B8F5', dash: true, tap: tap);

// ---------- 1 registration
class OIntro extends Scr {
  const OIntro({super.key});
  @override
  Widget view(c, s) => screen(c, [
        topbar('سجّل مشروعك'),
        body([
          img('padel', 350, 200, 24),
          T('خلي الناس تلگاك', 24, 800),
          Tn('سجّل مشروعك على ضوجة واستقبل حجوزات، انشر عروض وريلز، وشوف شلون يتفاعل وياك الناس.', s: 15, c: MU, lh: 24),
          for (final (i, a, b) in [('calendar-check', 'حجوزات مباشرة', 'بدون مكالمات ورسائل'), ('badge-percent', 'عروض بمدة محددة', 'توصل للناس القريبين منك'), ('chart-column', 'إحصائيات واضحة', 'مشاهدات، ضغطات وحجوزات')])
            R([I(i, 22, P), F([T(a, 15, 800), T(b, 13, 400, MU)], g: 2)], g: 12, al: 's', w: 'fill'),
          T('التسجيل مجاني ويتراجع خلال 24 ساعة', 12, 500, MU),
        ], g: 14),
      ], bottomBar: bottom([btn('يلا نبدي', tap: () => push(c, const OInfo()))]));
}

final reg = <String, dynamic>{'name': 'ملعب بادل لاونج', 'desc': 'ملعب بادل مغطى مع إضاءة ليلية وكافيه', 'cat': 'بادل'};

class OInfo extends Scr {
  const OInfo({super.key});
  @override
  Widget view(c, s) {
    final n = s.ctl('n', reg['name']), d = s.ctl('d', reg['desc']);
    final cat = s.get('cat', reg['cat'] as String);
    final logo = s.get('logo', false);
    final err = s.get<String?>('err', null);
    const cats = ['ملاعب', 'بادل', 'بليارد', 'ألعاب', 'كافيه', 'مطعم', 'منتجع', 'مسبح'];
    return screen(c, [
      topbar('معلومات المشروع'),
      steps(1, 'المعلومات الأساسية'),
      body([
        R([
          logo ? img('padel', 84, 84, 24) : F([I('camera', 24, P), T('الشعار', 11, 700, P)], g: 4, al: 'c', jc: 'c', w: 84, h: 84, r: 24, bg: BG, sk: '#C9B8F5', dash: true, tap: () => s.set('logo', true)),
          F([T('شعار المشروع', 15, 800), T('مربع، PNG أو JPG', 12, 400, MU)], g: 2),
        ], g: 14, al: 'c', w: 'fill'),
        inp('اسم المشروع', '', ctl: n),
        inp('وصف قصير', '', ctl: d),
        if (err != null) T(err, 12, 600, RD),
        T('القسم', 14, 700),
        R([for (final l in cats) chip(l, l == cat, null, 13, () => s.set('cat', l))], wrap: true, g: 8, w: 'fill'),
      ], g: 16),
    ], bottomBar: bottom([btn('التالي', tap: () {
      if (n.text.trim().length < 3) return s.set('err', 'اكتب اسم المشروع');
      reg['name'] = n.text.trim();
      reg['desc'] = d.text;
      reg['cat'] = cat;
      push(c, const OLoc());
    })]));
  }
}

class OLoc extends Scr {
  const OLoc({super.key});
  @override
  Widget view(c, s) {
    final h = MediaQuery.of(c).size.height;
    final pos = s.get('pos', const Offset(173, 360));
    final near = s.ctl('near', 'قرب مطعم الساعة، شارع 14 رمضان');
    return Scaffold(
        backgroundColor: col(WH),
        resizeToAvoidBottomInset: false,
        body: Stack(children: [
          Positioned.fill(child: GestureDetector(onTapDown: (d) => s.set('pos', d.localPosition - const Offset(22, 40)), child: SvgFill(MAPSVG))),
          Positioned(left: pos.dx, top: pos.dy * (pos == const Offset(173, 360) ? h / 844 : 1), child: IgnorePointer(child: I('map-pin', 44, P, PL))),
          Positioned(left: 0, top: 0, child: F([status(), topbar('موقع المشروع')], w: 390, bg: WH)),
          Positioned(left: 330, bottom: 844 - 560 - 40 + (h - 844) * 0, child: iconbtn('crosshair', tap: () => s.set('pos', const Offset(173, 360)))),
          Positioned(left: 0, bottom: MediaQuery.of(c).viewInsets.bottom, child: F([
            F([BOX(w: 40, h: 5, r: 3, bg: '#D9D6E3')], w: 'fill', al: 'c'),
            T('الخطوة 2 من 5 · الموقع', 12, 700, MU),
            Tn('حرّك الخريطة وثبّت الدبوس على باب المشروع', s: 15, w: 700, lh: 22),
            inp('المحافظة', 'بغداد', icon: 'chevron-down'),
            inp('أقرب نقطة دالة', '', ctl: near),
            btn('ثبّت الموقع', tap: () => push(c, const OHours())),
          ], g: 14, w: 390, p: [12, 24, 30, 24], bg: WH, rr: [28, 28, 0, 0])),
        ]));
  }
}

class OHours extends Scr {
  const OHours({super.key});
  @override
  Widget view(c, s) {
    final days = s.get('days', <List<dynamic>>[['السبت', '4:00 م - 2:00 ص', true], ['الأحد - الخميس', '4:00 م - 1:00 ص', true], ['الجمعة', '4:00 م - 1:00 ص', false]]);
    Widget day(List<dynamic> d) => R([T(d[0], 14, 600), R([T(d[2] ? d[1] : 'مغلق', 13, 500, d[2] ? INK : MU), toggle(d[2], () { d[2] = !d[2]; s.set('x', DateTime.now()); })], g: 10, al: 'c')], jc: 'sb', w: 'fill', al: 'c', p: [8, 0]);
    return screen(c, [
      topbar('التواصل والدوام'),
      steps(3, 'التواصل والدوام'),
      body([
        inp('رقم الهاتف', '', icon: 'phone', ctl: s.ctl('ph', '0770 555 1234'), kb: TextInputType.phone),
        inp('واتساب', '', icon: 'message-circle', ctl: s.ctl('wa', '0770 555 1234'), kb: TextInputType.phone),
        inp('انستغرام', '', icon: 'instagram', ctl: s.ctl('ig', '@padel.lounge')),
        R([T('أوقات الدوام', 16, 800), F([T('نفس الوقت لكل الأيام', 12, 700, P)], tap: () { for (final d in days) { d[1] = days[0][1]; } s.set('x', 1); })], jc: 'sb', w: 'fill'),
        card([day(days[0]), divider(), day(days[1]), divider(), day(days[2])], g: 4, p: 0).wrapPad(),
      ], g: 14),
    ], bottomBar: bottom([btn('التالي', tap: () => push(c, const OMedia()))]));
  }
}

extension on N {
  N wrapPad() => this;
}

class OMedia extends Scr {
  const OMedia({super.key});
  @override
  Widget view(c, s) {
    final extra = s.get('extra', <String>[]);
    final video = s.get('video', false);
    return screen(c, [
      topbar('الصور والفيديو'),
      steps(4, 'الصور والفيديو'),
      body([
        Tn('أضف صور واضحة للمكان. أول صورة تصير الغلاف.', s: 14, c: MU, lh: 22),
        img('padel', 350, 170, 20, [tag('الغلاف', bg: WH, c: INK)], 'h', 12),
        R([img('friends', 111, 100, 16), img('cafe', 111, 100, 16), for (final e in extra) img(e, 111, 100, 16), upbox('أضف', h: 100, w: 111, tap: () { extra.add(['gaming', 'football', 'billiard'][extra.length % 3]); s.set('x', extra.length); })], g: 8, w: 'fill', wrap: true),
        T('فيديو تعريفي (اختياري)', 15, 800),
        R([F([I(video ? 'check' : 'video', 24, P)], al: 'c', jc: 'c', w: 64, h: 64, r: 16, bg: PL), F([T(video ? 'تم رفع الفيديو · 0:42' : 'حتى 60 ثانية', 14, 700), T('MP4 أو MOV', 12, 400, MU)], g: 2)], g: 12, al: 'c', w: 'fill', p: 14, r: 18, bg: G, tap: () => s.set('video', true)),
      ], g: 14),
    ], bottomBar: bottom([btn('التالي', tap: () => push(c, const OServices()))]));
  }
}

class OServices extends Scr {
  const OServices({super.key});
  @override
  Widget view(c, s) {
    final sv = repo.services;
    final fac = s.get('fac', <String>{'مواقف', 'واي فاي', 'كافيه'});
    final busy = s.get('busy', false);
    Widget svc(int i) => R([F([T(sv[i].$1, 15, 800), T('${fmt(sv[i].$2)} د.ع / ${sv[i].$3}', 13, 700, P)], g: 2), R([iconbtn('pencil', s: 36, tap: () => push(c, OEdit(i))), iconbtn('trash-2', s: 36, c: RD, tap: () { sv.removeAt(i); repo.touch(); })], g: 6)], jc: 'sb', al: 'c', w: 'fill', p: 14, r: 18, bg: G);
    return screen(c, [
      topbar('الخدمات والأسعار'),
      steps(5, 'الخدمات والأسعار'),
      body([
        for (var i = 0; i < sv.length; i++) svc(i),
        R([I('plus', 18, P), T('أضف خدمة', 14, 800, P)], g: 6, jc: 'c', w: 'fill', p: 14, r: 18, sk: '#C9B8F5', dash: true, tap: () => push(c, const OEdit(-1))),
        T('المرافق', 15, 800),
        R([for (final l in ['مواقف', 'واي فاي', 'كافيه', 'غرف تبديل', 'تكييف', 'مناسب للعوائل']) chip(l, fac.contains(l), null, 13, () { fac.contains(l) ? fac.remove(l) : fac.add(l); s.set('x', l); })], wrap: true, g: 8, w: 'fill'),
      ], g: 12),
    ], bottomBar: bottom([btn('أرسل للمراجعة', busy: busy, tap: () async {
      s.set('busy', true);
      await repo.lag(1000);
      repo.projectPending = true;
      if (c.mounted) resetTo(c, const OPending(), anim: true);
    })]));
  }
}

class OPending extends Scr {
  const OPending({super.key});
  @override
  void init(ScrSt s) => Future.delayed(const Duration(seconds: 6), () => s.set('stage', 2));
  @override
  Widget view(c, s) {
    final stage = s.get('stage', 1);
    Widget st(String t, String sub, bool done, [bool cur = false]) => R([
          F([I(done ? 'check' : 'clock', 16, done ? WH : (cur ? P : MU))], al: 'c', jc: 'c', w: 30, h: 30, r: 15, bg: done ? OK : (cur ? PL : G)),
          F([T(t, 15, cur || done ? 800 : 500, done || cur ? INK : MU), T(sub, 12, 400, MU)], g: 2),
        ], g: 12, al: 'c', w: 'fill');
    return screen(c, [
      topbar('حالة الطلب', back: false),
      BOX(w: 10, h: 30),
      body([
        F([ibox(stage == 2 ? 'circle-check' : 'hourglass', c: stage == 2 ? OK : P, bg: stage == 2 ? OKB : PL, s: 96), Tn(stage == 2 ? 'تفعّل مشروعك!' : 'مشروعك قيد المراجعة', s: 22, w: 800, al: 'CENTER'), Tn(stage == 2 ? '${reg['name']} صار يظهر للناس بالتطبيق.' : 'فريق ضوجة يراجع المعلومات خلال 24 ساعة. راح نبلغك بإشعار أول ما يتفعل.', s: 14, c: MU, al: 'CENTER', w2: 310, lh: 22)], g: 14, al: 'c', w: 'fill'),
        card([st('استلمنا الطلب', 'اليوم 6:40 م', true), st('مراجعة المعلومات والصور', stage == 2 ? 'تمت' : 'جاري الآن', stage == 2, stage == 1), st('تفعيل المشروع', 'يظهر للناس بالتطبيق', stage == 2)], g: 16),
      ], g: 24),
    ], bottomBar: bottom([stage == 2 ? btn('افتح لوحة المشروع', tap: () { repo.role = Role.owner; resetTo(c, const OwnerHome(), anim: true); }) : btn('عدّل الطلب', kind: 's', tap: () => push(c, const OInfo()))]));
  }
}

// ---------- 2 home & insights
class OwnerHome extends Scr {
  const OwnerHome({super.key});
  @override
  Widget view(c, s) {
    final reqs = repo.ownerReqs.where((r) => r.status == 'new').toList();
    Widget req(OwnerReq r) => R([
          R([img(r.img, 48, 48, 14), F([T(r.name, 14, 800), T(r.when.split(' · ').take(2).join(' · '), 12, 400, MU)], g: 2)], g: 10, al: 'c'),
          R([
            F([I('x', 18, RD)], al: 'c', jc: 'c', w: 38, h: 38, r: 19, bg: '#FDECEC', tap: () => rejectSheet(c, r)),
            F([I('check', 18, WH)], al: 'c', jc: 'c', w: 38, h: 38, r: 19, bg: P, tap: () { repo.accept(r); toast(c, 'قبلت حجز ${r.name}'); }),
          ], g: 8),
        ], jc: 'sb', al: 'c', w: 'fill');
    final cal = [('6 م', 'محجوز', true), ('7 م', 'محجوز', true), ('8 م', 'متاح', false), ('9 م', 'محجوز', true)];
    return screen(c, [
      R([
        R([img('padel', 44, 44, 14), F([T('ملعب بادل لاونج', 16, 800), R([BOX(w: 8, h: 8, r: 4, bg: OK), T('مفعّل · يستقبل حجوزات', 12, 500, MU)], g: 6, al: 'c')], g: 2)], g: 10, al: 'c'),
        iconbtn('bell', dot: repo.ownerNotifs.any((n) => n.fresh), tap: () => push(c, const Notifs(owner: true))),
      ], jc: 'sb', al: 'c', w: 'fill', p: [8, 20]),
      body([
        R([T('هلا ${repo.userName}', 22, 800), T('السبت 30 تشرين الأول', 12, 500, MU)], jc: 'sb', al: 'e', w: 'fill'),
        R([stat('حجوزات اليوم', '${repo.todayBookings}', '+${repo.todayBookings - 7} عن أمس', true, () => onOwnerTab(c, 'الحجوزات')), stat('دخل اليوم', '${fmt(repo.todayIncome)} د.ع')], g: 10, w: 'fill'),
        R([stat('مشاهدات الأسبوع', '4,320', '+18%', true, () => onOwnerTab(c, 'الإحصائيات')), stat('التقييم', '4.8', '312 تقييم', true, () => push(c, const OReviews()))], g: 10, w: 'fill'),
        R([T('طلبات بانتظارك', 17, 800), T('${reqs.length}', 13, 800, P)], jc: 'sb', w: 'fill', tap: () => onOwnerTab(c, 'الحجوزات')),
        if (reqs.isEmpty) card([Tn('ماكو طلبات جديدة هسه', s: 14, c: MU, al: 'CENTER', w2: 'fill')]) else card([for (var i = 0; i < reqs.length && i < 2; i++) ...[if (i > 0) divider(), req(reqs[i])]], g: 12),
        R([T('اليوم', 17, 800), F([T('عرض الجدول', 13, 700, P)], tap: () => push(c, const OCal()))], jc: 'sb', w: 'fill'),
        R([for (final (t, st, b) in cal) F([Tn(t, s: 13, w: 800, c: b ? WH : INK, al: 'CENTER'), Tn(st, s: 11, w: 500, c: b ? PL : MU, al: 'CENTER')], g: 2, al: 'c', w: 'fill', p: [10, 4], r: 14, bg: b ? P : G)], g: 8, w: 'fill'),
      ], g: 14),
    ], onavTab: 'الرئيسية');
  }
}

N barChart(List<int> vals, List<String> lab, int hi) {
  final m = vals.reduce((a, b) => a > b ? a : b);
  return R([for (var i = 0; i < vals.length; i++) F([BOX(w: 26, h: (110 * vals[i] / m).roundToDouble(), r: 8, bg: i == hi ? P : PL), Tn(lab[i], s: 11, w: 500, c: MU, al: 'CENTER')], g: 6, al: 'c', jc: 'e', w: 'fill')], al: 'e', w: 'fill', h: 140, g: 6);
}

class OInsights extends Scr {
  const OInsights({super.key});
  @override
  Widget view(c, s) {
    final per = s.get('per', 0);
    final mul = [1.0, 4.1, 11.8][per];
    String sc(int v) => fmt((v * mul).round());
    Widget row(String t, String v, double w) => F([R([T(t, 13, 600), T(v, 13, 800)], jc: 'sb', w: 'fill'), F([BOX(w: w, h: 8, r: 4, bg: P)], d: 'h', w: 'fill', h: 8, r: 4, bg: G)], g: 6, w: 'fill');
    final vals = [[9, 12, 10, 14, 22, 18, 11], [40, 52, 47, 58, 90, 77, 44], [120, 150, 140, 170, 260, 230, 130]][per];
    return screen(c, [
      topbar('الإحصائيات', back: false),
      F([R([for (var i = 0; i < 3; i++) chip(['7 أيام', '30 يوم', '3 أشهر'][i], i == per, null, 13, () => s.set('per', i))], g: 8)], w: 'fill', p: [0, 20]),
      body([
        R([stat('مشاهدات', sc(4320), '+18%'), stat('ضغطات', sc(1140), '+9%'), stat('حجوزات', sc(86), '-4%', false)], g: 8, w: 'fill'),
        card([R([T('الحجوزات حسب اليوم', 15, 800), T('الخميس الأعلى', 12, 700, P)], jc: 'sb', w: 'fill'), barChart(vals, ['سبت', 'أحد', 'اثنين', 'ثلاثاء', 'خميس', 'جمعة', 'أربعاء'], 4)], g: 14),
        card([T('منين يجون الناس؟', 15, 800), row('اختارلي', '38%', 118), row('البحث', '27%', 84), row('الريلز', '21%', 65), row('العروض', '14%', 43)], g: 12),
        R([T('أداء العروض', 15, 800, P), I('chevron-left', 18, P)], g: 6, jc: 'c', w: 'fill', p: 12, r: 16, bg: PL, tap: () => push(c, const OOffPerf())),
      ], g: 14),
    ], onavTab: 'الإحصائيات');
  }
}

class OOffPerf extends Scr {
  const OOffPerf({super.key});
  @override
  Widget view(c, s) {
    final t = s.get('t', 0);
    final list = repo.ownerOffers.where((o) => t == 0 ? o.active : t == 2 ? !o.active : false).toList();
    return screen(c, [
      topbar('أداء العروض'),
      F([tabs(['فعّالة', 'مجدولة', 'منتهية'], t, (i) => s.set('t', i))], w: 'fill', p: [4, 20]),
      body([
        if (list.isEmpty) F([BOX(h: 60, w: 1), Tn('ماكو عروض هنا', s: 16, w: 700, c: MU, al: 'CENTER')], al: 'c', w: 'fill'),
        for (final o in list)
          card([
            R([img(o.img, 64, 64, 14), F([R([T(o.place, 15, 800), tag(o.active ? 'فعّال' : 'متوقف', bg: o.active ? OKB : G, c: o.active ? OK : MU)], g: 8, al: 'c'), T(o.exp, 12, 400, MU)], g: 4)], g: 12, al: 'c', w: 'fill'),
            R([for (final (v, l) in [(fmt(o.views), 'مشاهدة'), (fmt(o.clicks), 'ضغطة'), (fmt(o.books), 'حجز')]) F([Tn(v, s: 16, w: 800, al: 'CENTER'), Tn(l, s: 11, w: 500, c: MU, al: 'CENTER')], g: 2, al: 'c', w: 'fill')], w: 'fill', p: [10, 0], r: 14, bg: G),
          ], p: 14, g: 12, tap: () { o.active = !o.active; repo.touch(); toast(c, o.active ? 'رجّعت العرض فعّال' : 'وقّفت العرض'); }),
      ], g: 12),
    ], onavTab: 'الإحصائيات');
  }
}

// ---------- 3 bookings
Future<void> rejectSheet(BuildContext c, OwnerReq r) {
  var sel = 0, alt = 0;
  const opts = ['الموعد ممتلئ', 'صيانة بالملعب', 'سبب ثاني'];
  const alts = ['9:00 م', '10:00 م', 'الأحد 8:00 م'];
  return openSheet(c, title: 'سبب الرفض', top: 330, body: (sc, set) => [
        T('الزبون يوصله السبب مع اقتراح موعد ثاني', 13, 400, MU),
        for (var i = 0; i < 3; i++) R([T(opts[i], 15, 500), radio(sel == i)], jc: 'sb', w: 'fill', al: 'c', p: [10, 0], tap: () => set(() => sel = i)),
        F([T('اقترح موعد بديل', 13, 700), R([for (var i = 0; i < 3; i++) chip(alts[i], alt == i, null, 13, () => set(() => alt = i))], g: 8)], g: 8, w: 'fill'),
        btn('رفض الحجز', kind: 'd', tap: () { repo.reject(r); Navigator.pop(sc); toast(c, 'انرفض الحجز ودزّينا للزبون موعد ${alts[alt]}'); }),
      ]);
}

class OBookings extends Scr {
  const OBookings({super.key});
  @override
  Widget view(c, s) {
    final t = s.get('t', 0);
    final st = ['new', 'ok', 'past'][t];
    final list = repo.ownerReqs.where((r) => r.status == st || (t == 2 && r.status == 'rejected')).toList();
    final nNew = repo.ownerReqs.where((r) => r.status == 'new').length;
    Widget b(OwnerReq r) {
      final act = r.status == 'new';
      final label = switch (r.status) { 'new' => 'بانتظار القبول', 'ok' => r.arrived ? 'وصل' : 'مؤكد', 'rejected' => 'مرفوض', _ => 'مكتمل' };
      return card([
        R([R([img(r.img, 48, 48, 14), F([T(r.name, 15, 800), T(r.when, 12, 400, MU)], g: 2)], g: 10, al: 'c'), tag(label, bg: act ? WRB : r.status == 'rejected' ? '#FDECEC' : OKB, c: act ? WR : r.status == 'rejected' ? RD : OK)], jc: 'sb', al: 'c', w: 'fill'),
        R([meta('wallet', r.pay, INK, 13), T('${fmt(r.total)} د.ع', 14, 800, P)], jc: 'sb', w: 'fill'),
        if (act) R([btn('رفض', kind: 'g', h: 42, tap: () => rejectSheet(c, r)), btn('قبول', h: 42, tap: () { repo.accept(r); toast(c, 'قبلت حجز ${r.name}'); })], g: 10, w: 'fill'),
      ], p: 14, g: 12);
    }

    return screen(c, [
      topbar('الحجوزات', back: false, right: iconbtn('scan-line', tap: () => push(c, const OScan()))),
      F([tabs(['جديدة ($nNew)', 'مؤكدة', 'سابقة'], t, (i) => s.set('t', i))], w: 'fill', p: [4, 20]),
      body([
        if (list.isEmpty) F([BOX(h: 60, w: 1), Tn('ماكو حجوزات هنا', s: 16, w: 700, c: MU, al: 'CENTER')], al: 'c', w: 'fill'),
        for (final r in list) b(r),
        if (t == 0) for (final r in repo.ownerReqs.where((r) => r.status == 'ok').take(1)) b(r),
      ], g: 12),
    ], onavTab: 'الحجوزات');
  }
}

class OScan extends Scr {
  const OScan({super.key});
  @override
  void init(ScrSt s) => Future.delayed(const Duration(milliseconds: 1500), () => s.set('found', true));
  @override
  Widget view(c, s) {
    final found = s.get('found', false);
    final r = repo.ownerReqs.firstWhere((x) => x.status == 'ok' && !x.arrived, orElse: () => repo.ownerReqs.first);
    final h = MediaQuery.of(c).size.height;
    return Scaffold(
        backgroundColor: col(INK),
        body: Stack(children: [
          Positioned.fill(child: Image.asset('assets/img/padel.jpg', fit: BoxFit.cover)),
          Positioned.fill(child: ColoredBox(color: col('#111111B3'))),
          Positioned(left: 0, top: 0, child: F([status(true), R([iconbtn('x', bg: '#FFFFFF26', c: WH, sk: null, tap: () => Navigator.pop(c)), T('تسجيل وصول الزبون', 17, 800, WH), BOX(w: 40, h: 40)], jc: 'sb', al: 'c', w: 'fill', p: [8, 20])], w: 390)),
          Positioned(left: 75, top: 230 * h / 844, child: BOX(w: 240, h: 240, r: 28, sk: found ? '#22C55E' : WH, skw: 3)),
          Positioned(left: 45, top: 490 * h / 844, child: Tn(found ? 'لگينا الحجز ✓' : 'وجّه الكاميرا على رمز QR بحجز الزبون', s: 14, w: 500, c: WH, al: 'CENTER', w2: 300)),
          if (found)
            Positioned(left: 20, bottom: 30, child: F([
              R([R([img(r.img, 48, 48, 14), F([T('${r.name} · 4 أشخاص', 15, 800), T(r.when.split(' · ').take(2).join(' · '), 12, 400, MU)], g: 2)], g: 10, al: 'c'), tag(r.pay.contains('مدفوع') ? 'مدفوع' : 'كاش', bg: OKB, c: OK)], jc: 'sb', al: 'c', w: 'fill'),
              btn('تأكيد الوصول', icon: 'check', tap: () { repo.arrive(r); Navigator.pop(c); toast(c, 'تم تسجيل وصول ${r.name}'); }),
            ], g: 14, w: 350, p: 16, r: 24, bg: WH)),
        ]));
  }
}

class OCal extends Scr {
  const OCal({super.key});
  @override
  Widget view(c, s) {
    final d = s.get('d', 0);
    final court = s.get('court', 0);
    const days = [('سبت', '30'), ('أحد', '31'), ('اثنين', '1'), ('ثلاثاء', '2'), ('أربعاء', '3')];
    final base = [('6:00 م', 'محجوز · حسين', 'b'), ('7:00 م', 'محجوز · زيد', 'b'), ('8:00 م', 'متاح', 'f'), ('9:00 م', 'بانتظار القبول', 'h'), ('10:00 م', 'مغلق للصيانة', 'x'), ('11:00 م', 'متاح', 'f')];
    final slots = [
      for (var i = 0; i < base.length; i++)
        repo.closed.contains(base[i].$1) ? (base[i].$1, 'مغلق للصيانة', 'x') : (base[i].$3 == 'x' ? (base[i].$1, 'متاح', 'f') : ((d + court + i) % 4 == 3 && d + court > 0 ? (base[i].$1, 'متاح', 'f') : base[i]))
    ];
    Widget sl((String, String, String) x) {
      final (bg, cc) = {'b': (P, WH), 'f': (G, INK), 'x': ('#FDECEC', RD), 'h': (WRB, WR)}[x.$3]!;
      return R([T(x.$1, 14, 800, cc), T(x.$2, 12, 600, cc)], jc: 'sb', w: 'fill', p: [14, 16], r: 14, bg: bg, tap: () {
        if (x.$3 == 'f') { repo.closed.add(x.$1); repo.touch(); toast(c, 'سكّرت ${x.$1}'); }
        else if (x.$3 == 'x') { repo.closed.remove(x.$1); repo.touch(); toast(c, 'فتحت ${x.$1}'); }
        else if (x.$3 == 'h') { onOwnerTab(c, 'الحجوزات'); }
      });
    }

    return screen(c, [
      topbar('المواعيد', back: Navigator.of(c).canPop(), right: iconbtn('settings', tap: () => push(c, const OEdit(0)))),
      R([for (var i = 0; i < 5; i++) F([Tn(days[i].$1, s: 11, w: 500, c: i == d ? PL : MU, al: 'CENTER'), Tn(days[i].$2, s: 17, w: 800, c: i == d ? WH : INK, al: 'CENTER')], g: 2, al: 'c', w: 'fill', p: [10, 0], r: 16, bg: i == d ? P : G, tap: () => s.set('d', i))], g: 8, w: 'fill', p: [4, 20]),
      body([
        R([T('ملعب ${court + 1}', 15, 800), R([chip('ملعب 1', court == 0, null, 13, () => s.set('court', 0)), chip('ملعب 2', court == 1, null, 13, () => s.set('court', 1))], g: 6)], jc: 'sb', al: 'c', w: 'fill'),
        for (final x in slots) sl(x),
        R([I('plus', 18, P), T('أضف وقت أو سكّر وقت', 14, 800, P)], g: 6, jc: 'c', w: 'fill', p: 12, tap: () => toast(c, 'اضغط على أي وقت متاح حتى تسكّره')),
      ], g: 8),
    ], onavTab: 'الحجوزات');
  }
}

// ---------- 4 content
Future<void> postSheet(BuildContext c) => openSheet(c, title: 'شنو تريد تنشر؟', top: 430, body: (sc, set) {
      Widget it(String i, String t, String s2, Widget to) => R([ibox(i), F([T(t, 15, 800), T(s2, 12, 400, MU)], g: 2)], g: 12, al: 'c', w: 'fill', p: [12, 0], tap: () { Navigator.pop(sc); push(c, to); });
      return [
        it('badge-percent', 'عرض جديد', 'خصم أو باقة بمدة محددة', const OOffer()),
        it('video', 'ريل', 'فيديو قصير حتى 60 ثانية', const OReel()),
        it('image-plus', 'صور للمعرض', 'تنضاف لصفحة المشروع', const OMedia()),
        it('calendar-clock', 'سكّر أوقات', 'صيانة أو حجز خاص', const OCal()),
      ];
    });

class OOffer extends Scr {
  const OOffer({super.key});
  @override
  Widget view(c, s) {
    final t = s.ctl('t', 'خصم 25% بعد 12 بالليل'), dc = s.ctl('d', '25%');
    final kind = s.get('k', 'نسبة خصم');
    final home = s.get('home', true);
    final pic = s.get('pic', false);
    final busy = s.get('busy', false);
    return screen(c, [
      topbar('عرض جديد'),
      body([
        pic ? img('padel', 350, 150, 18) : upbox('صورة العرض', h: 150, tap: () => s.set('pic', true)),
        inp('عنوان العرض', '', ctl: t),
        T('نوع العرض', 14, 700),
        R([for (final l in ['نسبة خصم', 'مبلغ ثابت', 'باقة']) chip(l, kind == l, null, 13, () => s.set('k', l))], g: 8),
        R([inp('الخصم', '', ctl: dc, kb: TextInputType.number), inp('يطبق على', 'ساعة ملعب', icon: 'chevron-down')], g: 10, w: 'fill'),
        T('المدة', 14, 700),
        R([inp('من', '30 تشرين الأول', icon: 'calendar'), inp('إلى', '6 تشرين الثاني', icon: 'calendar')], g: 10, w: 'fill'),
        R([F([T('يظهر بالرئيسية للقريبين', 14, 600), T('ضمن 5 كم من المشروع', 12, 400, MU)], g: 2), toggle(home, () => s.set('home', !home))], jc: 'sb', al: 'c', w: 'fill'),
      ], g: 12),
    ], bottomBar: bottom([btn('انشر العرض', busy: busy, tap: () async {
      s.set('busy', true);
      await repo.lag(800);
      final pct = int.tryParse(dc.text.replaceAll(RegExp(r'\D'), '')) ?? 25;
      repo.createOffer(t.text.trim().isEmpty ? 'عرض جديد' : t.text.trim(), pct.clamp(1, 90), 'ساعة ملعب');
      if (!c.mounted) return;
      Navigator.pop(c);
      toast(c, 'انتشر العرض، يظهر هسه للزبائن');
    })]));
  }
}

class OReel extends Scr {
  const OReel({super.key});
  @override
  Widget view(c, s) {
    final d = s.ctl('d', 'ليلة البطولة الأسبوعية، احجز مكانك قبل لا يمتلي');
    final bookBtn = s.get('b', true);
    final busy = s.get('busy', false);
    return Scaffold(
        backgroundColor: col(INK),
        resizeToAvoidBottomInset: false,
        body: Stack(children: [
          Positioned.fill(child: Image.asset('assets/img/reel.jpg', fit: BoxFit.cover)),
          Positioned(left: 0, top: 0, child: F([status(true), R([iconbtn('x', bg: '#FFFFFF26', c: WH, sk: null, tap: () => Navigator.pop(c)), T('ريل جديد', 17, 800, WH), T('0:24', 13, 700, WH)], jc: 'sb', al: 'c', w: 'fill', p: [8, 20])], w: 390)),
          Positioned(left: 0, bottom: MediaQuery.of(c).viewInsets.bottom, child: F([
            F([BOX(w: 40, h: 5, r: 3, bg: '#D9D6E3')], w: 'fill', al: 'c'),
            inp('الوصف', '', ctl: d),
            R([T('اربط بعرض', 14, 600), R([T(repo.ownerOffers.first.place.length > 14 ? 'خصم 25%' : repo.ownerOffers.first.place, 13, 700, P), I('chevron-left', 16, MU)], g: 4)], jc: 'sb', w: 'fill'),
            R([T('زر الحجز على الريل', 14, 600), toggle(bookBtn, () => s.set('b', !bookBtn))], jc: 'sb', al: 'c', w: 'fill'),
            btn('انشر', busy: busy, tap: () async {
              s.set('busy', true);
              await repo.lag(1200);
              repo.postReel(d.text.trim());
              if (!c.mounted) return;
              Navigator.pop(c);
              toast(c, 'انتشر الريل بريلز ضوجة');
            }),
          ], g: 14, w: 390, p: [12, 24, 30, 24], bg: WH, rr: [28, 28, 0, 0])),
        ]));
  }
}

class OProject extends Scr {
  const OProject({super.key});
  @override
  Widget view(c, s) {
    final unreplied = repo.ownerReviews.where((r) => r.reply == null).length;
    Widget it(String i, String t, [String? v, VoidCallback? tap]) => R([R([I(i, 20, INK), T(t, 15, 500)], g: 12), R([if (v != null) T(v, 13, 400, MU), I('chevron-left', 18, MU)], g: 6)], jc: 'sb', w: 'fill', p: [14, 0], tap: tap);
    return screen(c, [
      topbar('مشروعي', back: false, right: F([T('معاينة', 13, 800, P)], tap: () => push(c, const Details('p1')))),
      body([
        img('padel', 350, 150, 22),
        R([F([T('ملعب بادل لاونج', 19, 800), meta('map-pin', 'بادل · المنصور، بغداد')], g: 4), tag('مفعّل', bg: OKB, c: OK)], jc: 'sb', al: 'c', w: 'fill'),
        F([
          it('file-text', 'المعلومات والوصف', null, () => push(c, const OInfo())), divider(),
          it('image-plus', 'الصور والفيديو', '12 صورة', () => push(c, const OMedia())), divider(),
          it('tag', 'الخدمات والأسعار', '${repo.services.length} خدمات', () => push(c, const OServices())), divider(),
          it('clock', 'أوقات الدوام', null, () => push(c, const OHours())), divider(),
          it('phone', 'التواصل', null, () => push(c, const OHours())), divider(),
          it('map-pin', 'الموقع', null, () => push(c, const OLoc())),
        ], w: 'fill'),
        F([
          it('star', 'التقييمات', unreplied > 0 ? '$unreplied بدون رد' : null, () => push(c, const OReviews())), divider(),
          it('users', 'الموظفين والصلاحيات', 'قريباً', () => push(c, const OStaff())), divider(),
          it('repeat', 'التبديل لحساب الزبون', null, () { repo.role = Role.customer; onCustomerTab(c, 'الرئيسية'); }),
        ], w: 'fill'),
        F([R([I('log-out', 20, RD), T('تسجيل الخروج', 15, 700, RD)], g: 10, p: [8, 0], tap: () { repo.logout(); onCustomerTab(c, '__login'); })], w: 'fill'),
      ], g: 14),
    ], onavTab: 'مشروعي');
  }
}

class OEdit extends Scr {
  final int idx;
  const OEdit(this.idx, {super.key});
  @override
  Widget view(c, s) {
    final sv = idx >= 0 && idx < repo.services.length ? repo.services[idx] : ('', 0, 'ساعة');
    final n = s.ctl('n', sv.$1), p = s.ctl('p', sv.$2 == 0 ? '' : fmt(sv.$2)), pk = s.ctl('pk', '25,000 د.ع');
    final peak = s.get('peak', <String>{'الخميس', 'الجمعة'});
    final avail = s.get('av', true);
    void save() {
      final pr = int.tryParse(p.text.replaceAll(RegExp(r'\D'), '')) ?? 0;
      if (n.text.trim().isEmpty || pr == 0) { toast(c, 'اكتب اسم الخدمة والسعر'); return; }
      final v = (n.text.trim(), pr, sv.$3);
      if (idx >= 0 && idx < repo.services.length) { repo.services[idx] = v; } else { repo.services.add(v); }
      repo.touch();
      Navigator.pop(c);
      toast(c, 'انحفظت التغييرات');
    }

    return screen(c, [
      topbar('الخدمات والأسعار', right: F([T('احفظ', 14, 800, P)], tap: save)),
      body([
        inp('اسم الخدمة', 'مثلاً: ساعة ملعب', ctl: n),
        R([inp('السعر (د.ع)', '20,000', ctl: p, kb: TextInputType.number), inp('لكل', sv.$3, icon: 'chevron-down')], g: 10, w: 'fill'),
        inp('سعر وقت الذروة', '', ctl: pk),
        T('أوقات الذروة', 14, 700),
        R([for (final l in ['الخميس', 'الجمعة', 'بعد 9 م']) chip(l, peak.contains(l), null, 13, () { peak.contains(l) ? peak.remove(l) : peak.add(l); s.set('x', l); })], g: 8),
        R([F([T('متاحة للحجز', 14, 600), T('تظهر للزبائن بصفحة المشروع', 12, 400, MU)], g: 2), toggle(avail, () => s.set('av', !avail))], jc: 'sb', al: 'c', w: 'fill'),
        R([I('info', 16, MU), T('تغيير السعر ما يأثر على الحجوزات المؤكدة', 12, 500, MU)], g: 6, al: 'c'),
      ], g: 14),
    ], bottomBar: bottom([btn('احفظ التغييرات', tap: save)]));
  }
}

class OReviews extends Scr {
  const OReviews({super.key});
  @override
  Widget view(c, s) {
    final ch = s.get('ch', 0);
    final all = repo.ownerReviews;
    final list = switch (ch) { 0 => all.where((r) => r.reply == null).toList(), 2 => all.where((r) => r.stars == 5).toList(), 3 => all.where((r) => r.stars < 3).toList(), _ => all };
    Widget rv(Review r) {
      final ctl = s.ctl('r${all.indexOf(r)}', r.stars < 4 ? 'شكراً على ملاحظتك، صلّحنا الإضاءة' : 'تسلم، ننتظرك مرة ثانية');
      return card([
        R([R([avatar(r.name), F([T(r.name, 14, 800), T(r.ago, 11, 400, MU)], g: 2)], g: 10, al: 'c'), rating('${r.stars}.0')], jc: 'sb', al: 'c', w: 'fill'),
        Tn(r.text, s: 13, lh: 21, w2: 'fill'),
        r.reply != null
            ? F([T('ردّك', 12, 800, P), Tn(r.reply!, s: 13, lh: 20, w2: 'fill')], g: 4, w: 'fill', p: 12, r: 14, bg: BG)
            : inp('اكتب رد', '', ctl: ctl, lead: F([I('send', 18, P)], tap: () { repo.reply(r, ctl.text.trim()); toast(c, 'انضاف ردّك'); })),
      ], p: 14, g: 10);
    }

    final nNo = all.where((r) => r.reply == null).length;
    return screen(c, [
      topbar('التقييمات'),
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: R([for (var i = 0; i < 4; i++) chip(['بدون رد ($nNo)', 'الكل', '5 نجوم', 'أقل من 3'][i], ch == i, null, 13, () => s.set('ch', i))], g: 8, p: [4, 20])),
      body([
        if (list.isEmpty) F([BOX(h: 60, w: 1), Tn('رديت على كل التقييمات 👏', s: 16, w: 700, c: MU, al: 'CENTER')], al: 'c', w: 'fill'),
        for (final r in list) rv(r),
      ], g: 12),
    ], onavTab: 'مشروعي');
  }
}

class OStaff extends Scr {
  const OStaff({super.key});
  @override
  Widget view(c, s) {
    final perms = s.get('pm', <String, bool>{'قبول ورفض الحجوزات': true, 'مسح QR الوصول': true, 'نشر عروض وريلز': false, 'تعديل الأسعار': false, 'مشاهدة الدخل': false});
    Widget m(String n, String r) => R([R([avatar(n, 40), F([T(n, 14, 800), T(r, 12, 400, MU)], g: 2)], g: 10, al: 'c'), I('chevron-left', 18, MU)], jc: 'sb', al: 'c', w: 'fill');
    return screen(c, [
      topbar('الموظفين والصلاحيات'),
      body([
        R([I('info', 18, WR), T('هذي الميزة قريباً. تكدر تجهّز الفريق من هسه.', 13, 600, WR)], g: 8, al: 'c', w: 'fill', p: 12, r: 14, bg: WRB),
        card([m('أبو علي (أنت)', 'المالك · كل الصلاحيات'), divider(), m('كرار', 'مشرف حجوزات')], g: 12),
        T('صلاحيات كرار', 15, 800),
        card([for (final e in perms.entries) R([T(e.key, 14, 500), toggle(e.value, () { perms[e.key] = !e.value; s.set('x', e.key); })], jc: 'sb', al: 'c', w: 'fill', p: [6, 0])], g: 2, p: 16),
      ], g: 14),
    ], bottomBar: bottom([btn('ادعُ موظف', icon: 'user-plus', kind: 's', tap: () => toast(c, 'دعوة الموظفين قريباً'))]));
  }
}
