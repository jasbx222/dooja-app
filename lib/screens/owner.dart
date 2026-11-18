import 'package:flutter/material.dart';

import '../dsl.dart';
import '../common.dart';
import '../app.dart';
import '../repo.dart';
import 'home.dart' show rowcard;
import 'more.dart';

N body(List<Widget?> k, {double g = 16, dynamic p = const [4, 20]}) =>
    F(k, g: g, w: 'fill', p: p);
N stat(String t, String v) =>
    F([T(t, 12, 500, MU), T(v, 22, 800)], g: 4, w: 'fill', p: 14, r: 18, bg: G);
Widget ownerSelector(BuildContext c) => F(
  [
    if (repo.ownerPlaces.isEmpty) T('ما عندك مشاريع مسجلة', 14, 600, MU),
    for (final p in repo.ownerPlaces)
      chip(p.name, p.id == repo.ownerId, null, 13, () async {
        repo.selectedOwnerId = p.id;
        await repo.refresh();
      }),
  ],
  g: 8,
  w: 'fill',
  p: [4, 20],
);
Widget noIntegration(BuildContext c, String title, String message) =>
    screen(c, [
      topbar(title),
      body([Tn(message, s: 16, c: MU, lh: 26)]),
    ]);

class OIntro extends Scr {
  const OIntro({super.key});
  @override
  Widget view(c, s) => noIntegration(
    c,
    'سجّل مشروعك',
    'حتى تسجّل مشروعك على ضوجة تواصل ويا إدارة ضوجة، وهي تفعّل لك حساب صاحب المكان.',
  );
}

class OInfo extends Scr {
  const OInfo({super.key});
  @override
  Widget view(c, s) {
    if (!repo.isOwner) return const OIntro().view(c, s);
    final p = repo.ownerPlace;
    final creating = s.get('new', false) || p == null;
    final key = creating ? 'new' : p.id;
    final n = s.ctl('n$key', creating ? '' : p.name),
        a = s.ctl('a$key', creating ? '' : p.area),
        cat = s.ctl('cat$key', creating ? '' : p.cat),
        price = s.ctl('price$key', creating ? '' : p.price.toString()),
        unit = s.ctl('unit$key', creating ? 'ساعة' : p.unit),
        phone = s.ctl('phone$key', creating ? repo.phone : p.phone);
    return screen(
      c,
      [
        topbar(creating ? 'مشروع جديد' : 'تعديل المشروع'),
        ownerSelector(c),
        body([
          inp('اسم المشروع', '', ctl: n),
          inp('المنطقة', '', ctl: a),
          inp('القسم / النوع', '', ctl: cat),
          inp('السعر بالدينار', '', ctl: price, kb: TextInputType.number),
          inp('الوحدة', '', ctl: unit),
          inp('الهاتف', '', ctl: phone),
          Tn('صورة المشروع تتغير من إدارة ضوجة.', s: 13, c: MU),
          if (!creating)
            btn('إنشاء مشروع آخر', kind: 'g', tap: () => s.set('new', true)),
        ]),
      ],
      bottomBar: bottom([
        btn(
          'حفظ',
          tap: () async {
            final pr = int.tryParse(price.text);
            if (n.text.trim().isEmpty ||
                a.text.trim().isEmpty ||
                cat.text.trim().isEmpty ||
                pr == null ||
                pr < 0) {
              toast(c, 'املأ الاسم والمنطقة والقسم والسعر');
              return;
            }
            final ok = await apiAction(
              c,
              repo.savePlace({
                'name': n.text.trim(),
                'type': cat.text.trim(),
                'area': a.text.trim(),
                'category': cat.text.trim(),
                'price': pr,
                'unit': unit.text.trim(),
                'imageKey': creating ? 'padel' : p.img,
                'phone': phone.text.trim(),
                'kind': creating ? 'open' : p.kind,
              }, id: creating ? null : p.id),
              'انحفظ المشروع',
            );
            if (ok && c.mounted) Navigator.maybePop(c);
          },
        ),
      ]),
    );
  }
}

class OwnerHome extends Scr {
  const OwnerHome({super.key});
  @override
  Widget view(c, s) => screen(c, [
    topbar(
      'هلا ${repo.userName}',
      back: false,
      right: iconbtn('bell', tap: () => push(c, const Notifs(owner: true))),
    ),
    ownerSelector(c),
    body([
      R(
        [
          stat('حجوزات اليوم', '${repo.todayBookings}'),
          stat('دخل اليوم', '${fmt(repo.todayIncome)} د.ع'),
        ],
        g: 10,
        w: 'fill',
      ),
      T('طلبات بانتظارك', 18, 800),
      if (repo.ownerReqs.where((r) => r.status == 'new').isEmpty)
        T('ماكو طلبات جديدة', 14, 500, MU),
      for (final r in repo.ownerReqs.where((r) => r.status == 'new').take(4))
        requestCard(c, r),
      btn('المواعيد', kind: 'g', tap: () => push(c, const OCal())),
      btn('تحديث', kind: 'g', tap: () => repo.refresh()),
    ]),
  ], onavTab: 'الرئيسية');
}

Widget requestCard(BuildContext c, OwnerReq r) => card(
  [
    R([T(r.name, 15, 800), T(r.code, 12, 600, P)], jc: 'sb', w: 'fill'),
    Tn(r.when, s: 13, c: MU),
    T('${fmt(r.total)} د.ع · ${r.pay}', 14, 600),
    T(
      switch (r.status) {
        'new' => 'بانتظار القبول',
        'ok' => r.arrived ? 'وصل' : 'مؤكد',
        'rejected' => 'ملغي',
        _ => 'مكتمل',
      },
      13,
      700,
      P,
    ),
    if (r.status == 'new')
      R(
        [
          btn('رفض', kind: 'g', tap: () => rejectSheet(c, r)),
          btn('قبول', tap: () => apiAction(c, repo.accept(r), 'تم قبول الحجز')),
        ],
        g: 8,
        w: 'fill',
      ),
    if (r.status == 'ok')
      R(
        [
          if (!r.arrived)
            btn(
              'تسجيل الوصول',
              kind: 'g',
              tap: () => apiAction(c, repo.arrive(r), 'تم تسجيل الوصول'),
            ),
          btn(
            'إكمال',
            tap: () => apiAction(c, repo.status(r, 'مكتمل'), 'تم إكمال الحجز'),
          ),
        ],
        g: 8,
        w: 'fill',
      ),
  ],
  g: 10,
  p: 14,
);

class OBookings extends Scr {
  const OBookings({super.key});
  @override
  Widget view(c, s) {
    final tab = s.get('tab', 0);
    final list = repo.ownerReqs
        .where(
          (r) => tab == 0
              ? r.status == 'new'
              : tab == 1
              ? r.status == 'ok'
              : r.status == 'past' || r.status == 'rejected',
        )
        .toList();
    return screen(c, [
      topbar(
        'الحجوزات',
        back: false,
        right: iconbtn('scan-line', tap: () => push(c, const OScan())),
      ),
      F(
        [
          tabs(['جديدة', 'مؤكدة', 'سابقة'], tab, (i) => s.set('tab', i)),
        ],
        w: 'fill',
        p: 20,
      ),
      body([
        if (list.isEmpty) T('ماكو حجوزات هنا', 14, 500, MU),
        for (final r in list) requestCard(c, r),
        btn('تحديث', kind: 'g', tap: () => repo.refresh()),
      ]),
    ], onavTab: 'الحجوزات');
  }
}

Future<void> rejectSheet(BuildContext c, OwnerReq r) => openSheet(
  c,
  title: 'إلغاء الحجز',
  body: (sc, set) => [
    Tn('يتغير الحجز إلى ملغي ويوصل للزبون إشعار.', s: 14, c: MU),
    btn(
      'تأكيد الإلغاء',
      kind: 'd',
      tap: () async {
        if (await apiAction(c, repo.reject(r), 'تم إلغاء الحجز') && sc.mounted)
          Navigator.pop(sc);
      },
    ),
  ],
);

class OScan extends Scr {
  const OScan({super.key});
  @override
  Widget view(c, s) {
    final code = s.ctl('code');
    final matches = repo.ownerReqs
        .where(
          (r) =>
              r.code.toLowerCase() == code.text.trim().toLowerCase() &&
              r.status == 'ok',
        )
        .toList();
    return screen(c, [
      topbar('تسجيل الوصول'),
      body([
        Tn('اكتب رمز الحجز اللي يعرضه الزبون حتى تسجّل وصوله.', s: 14, c: MU),
        inp('رمز الحجز', 'DJ-...', ctl: code),
        btn('بحث', tap: () => s.set('search', true)),
        if (s.get('search', false)) ...[
          if (matches.isEmpty) T('ما لقينا حجز مؤكد بهذا الرمز', 14, 600, MU),
          for (final r in matches) requestCard(c, r),
        ],
      ]),
    ]);
  }
}

const _wd = ['الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
String _hh(int h) => '${(h % 24).toString().padLeft(2, '0')}:00';
int _hourOf(String t) => int.tryParse(time24(t).split(':').first.trim()) ?? -1;

/// One hour of the day as the owner sees it.
class _Slot {
  final int h;
  final String state; // free | closed | booked | pending | past
  final OwnerReq? start; // booking that starts at this hour
  final OwnerReq? cont; // booking that started earlier and still runs
  const _Slot(this.h, this.state, {this.start, this.cont});
}

List<OwnerReq> _dayReqs(String? id, String date) => id == null
    ? <OwnerReq>[]
    : (repo.ownerReqs
          .where((r) => r.placeId == id && r.day == date && r.status != 'rejected')
          .toList()
        ..sort((x, y) => _hourOf(x.time).compareTo(_hourOf(y.time))));

List<_Slot> _slots(String id, String date, DateTime now) {
  final today = date == isoDay();
  final reqs = _dayReqs(id, date);
  final a = repo.availability['$id/$date'];
  // Hours the server says are taken, even if the booking is not in the
  // owner's loaded list (the list holds the latest 200 bookings only).
  final taken = <int>{};
  for (final b in (a?['booked'] as List? ?? const [])) {
    final h = _hourOf(b['time'].toString());
    for (var i = 0; i < ((b['hours'] as num?)?.toInt() ?? 1); i++) {
      taken.add(h + i);
    }
  }
  return [
    for (var h = 0; h < 24; h++)
      () {
        OwnerReq? start, cont;
        for (final r in reqs) {
          final s = _hourOf(r.time);
          if (s == h) start ??= r;
          if (s < h && h < s + r.hours) cont ??= r;
        }
        final b = start ?? cont;
        final closed = repo.closedSlots.any(
          (x) => x['day'] == date && x['time'] == _hh(h),
        );
        final state = b != null
            ? (b.status == 'new' ? 'pending' : 'booked')
            : taken.contains(h)
            ? 'booked'
            : closed
            ? 'closed'
            : today && h <= now.hour
            ? 'past'
            : 'free';
        return _Slot(h, state, start: start, cont: cont);
      }(),
  ];
}

(String, String, String) _look(String state) => switch (state) {
  'booked' => ('محجوز', OK, OKB),
  'pending' => ('بانتظار قبولك', WR, WRB),
  'closed' => ('مغلق', RD, '#FDECEC'),
  'past' => ('انتهى', MU, G),
  _ => ('متاح', P, PL),
};

class OCal extends Scr {
  const OCal({super.key});
  @override
  void init(ScrSt s) {
    if (repo.ownerId != null) repo.loadClosed(isoDay());
  }

  @override
  Widget view(c, s) {
    final day = s.get('day', 0), date = isoDay(day);
    final id = repo.ownerId;
    final now = DateTime.now();
    final loaded = id != null && repo.availability['$id/$date'] != null;
    final slots = loaded ? _slots(id, date, now) : <_Slot>[];
    int count(String st) => slots.where((x) => x.state == st).length;
    final dayReqs = _dayReqs(id, date);
    final free = [for (final x in slots) if (x.state == 'free') _hh(x.h)];
    final closed = [for (final x in slots) if (x.state == 'closed') _hh(x.h)];

    Future<void> pick(int i) async {
      s.set('day', i);
      await repo.loadClosed(isoDay(i));
    }

    return screen(c, [
      topbar(
        'المواعيد',
        right: iconbtn(
          'refresh-cw',
          tap: () async {
            await repo.refresh();
            await repo.loadClosed(date);
          },
        ),
      ),
      ownerSelector(c),
      // Next 7 days, each with its number of bookings.
      N(
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: R([
            for (var i = 0; i < 7; i++)
              () {
                final d = now.add(Duration(days: i));
                final n = _dayReqs(id, isoDay(i)).length;
                final on = i == day;
                return F(
                  [
                    T(i == 0 ? 'اليوم' : i == 1 ? 'باچر' : _wd[d.weekday - 1], 11, 600, on ? WH : MU),
                    T('${d.day}', 20, 800, on ? WH : INK),
                    n > 0
                        ? F([T('$n', 10, 800, on ? P : WH)], al: 'c', jc: 'c', w: 18, h: 18, r: 9, bg: on ? WH : P)
                        : BOX(w: 18, h: 18),
                  ],
                  g: 4,
                  al: 'c',
                  w: 62,
                  p: [10, 0],
                  r: 18,
                  bg: on ? P : WH,
                  sk: on ? null : LN,
                  tap: () => pick(i),
                );
              }(),
          ], g: 8),
        ),
        fillW: true,
        hasFill: true,
      ),
      body([
        if (id == null)
          T('اختار مشروعاً أولاً', 14, 600, MU)
        else if (!loaded)
          btn('تحميل المواعيد', tap: () => repo.loadClosed(date))
        else ...[
          // Summary of the chosen day.
          R(
            [
              for (final st in ['free', 'booked', 'pending', 'closed'])
                () {
                  final l = _look(st);
                  return F(
                    [T('${count(st)}', 20, 800, l.$2), T(l.$1, 11, 600, l.$2)],
                    g: 2,
                    al: 'c',
                    w: 'fill',
                    p: [10, 4],
                    r: 14,
                    bg: l.$3,
                  );
                }(),
            ],
            g: 8,
            w: 'fill',
          ),
          R(
            [
              btn(
                'إغلاق المتاح',
                icon: 'lock',
                kind: 'g',
                h: 44,
                tap: free.isEmpty
                    ? () => toast(c, 'ماكو أوقات متاحة بهذا اليوم')
                    : () => confirmBulk(c, date, free, true),
              ),
              btn(
                'فتح المغلق',
                icon: 'circle-check',
                kind: 'g',
                h: 44,
                tap: closed.isEmpty
                    ? () => toast(c, 'ماكو أوقات مغلقة بهذا اليوم')
                    : () => confirmBulk(c, date, closed, false),
              ),
            ],
            g: 8,
            w: 'fill',
          ),
          if (dayReqs.isNotEmpty) ...[
            R([T('حجوزات هذا اليوم', 16, 800), T('${dayReqs.length}', 13, 700, MU)], jc: 'sb', w: 'fill'),
            for (final r in dayReqs) bookingRow(c, r),
          ],
          R([T('الأوقات', 16, 800)], w: 'fill'),
          Tn(
            'شغّل المفتاح حتى يصير الوقت متاح للحجز، وطفّيه حتى تغلقه. اضغط على الوقت المحجوز حتى تشوف الحجز.',
            s: 12,
            c: MU,
            lh: 20,
          ),
          if (count('past') > 0)
            Tn('${count('past')} ساعة من اليوم فاتت وما تنعرض.', s: 12, c: MU),
          for (final part in const [
            ('الصبح', 6, 12),
            ('الظهر', 12, 17),
            ('المسا', 17, 24),
            ('بعد نص الليل', 0, 6),
          ])
            if (slots.any((x) => x.h >= part.$2 && x.h < part.$3 && x.state != 'past'))
              F(
                [
                  T(part.$1, 13, 700, MU),
                  for (final x in slots.where(
                    (x) => x.h >= part.$2 && x.h < part.$3 && x.state != 'past',
                  ))
                    _slotRow(c, date, x),
                ],
                g: 8,
                w: 'fill',
              ),
        ],
      ]),
    ], onavTab: 'الحجوزات');
  }
}

N bookingRow(BuildContext c, OwnerReq r) {
  final l = _look(r.status == 'new' ? 'pending' : 'booked');
  final h = _hourOf(r.time);
  final label = r.status == 'past'
      ? 'مكتمل'
      : r.status == 'ok' && r.arrived
      ? 'وصل'
      : l.$1;
  return card(
    [
      R(
        [
          F([T(_hh(h), 15, 800), T('إلى ${_hh(h + r.hours)}', 11, 500, MU)], g: 2, w: 60),
          F(
            [
              T(r.name.isEmpty ? 'زبون' : r.name, 15, 800),
              T('${r.people} أشخاص · ${fmt(r.total)} د.ع', 12, 500, MU),
            ],
            g: 4,
            w: 'fill',
          ),
          tag(label, bg: l.$3, c: l.$2),
        ],
        g: 12,
        w: 'fill',
        al: 'c',
      ),
    ],
    p: 12,
    tap: () => bookingSheet(c, r),
  );
}

N _slotRow(BuildContext c, String date, _Slot x) {
  final l = _look(x.state);
  final b = x.start ?? x.cont;
  final canToggle = x.state == 'free' || x.state == 'closed';
  final past = x.state == 'past';
  return R(
    [
      BOX(w: 4, h: 36, r: 2, bg: l.$2),
      F([T(_hh(x.h), 15, 800, past ? MU : INK), T('إلى ${_hh(x.h + 1)}', 11, 500, MU)], g: 2, w: 56),
      F(
        [
          if (b != null) ...[
            T(b.name.isEmpty ? 'زبون' : b.name, 14, 700),
            T(
              x.start == null
                  ? 'تكملة الحجز من ${_hh(_hourOf(b.time))}'
                  : '${b.people} أشخاص · ${b.hours} ساعة',
              11,
              500,
              MU,
            ),
          ] else ...[
            T(l.$1, 13, 700, l.$2),
            T(
              switch (x.state) {
                'free' => 'الزبائن يكدرون يحجزونه',
                'closed' => 'ما يظهر للزبائن',
                'past' => 'الوقت فات',
                _ => 'محجوز',
              },
              11,
              500,
              MU,
            ),
          ],
        ],
        g: 2,
        w: 'fill',
      ),
      if (canToggle)
        toggle(
          x.state == 'free',
          () => apiAction(
            c,
            repo.setClosed(date, [_hh(x.h)], x.state == 'free'),
            x.state == 'free' ? 'انغلق ${_hh(x.h)}' : 'صار ${_hh(x.h)} متاح',
          ),
        )
      else if (b != null)
        tag(l.$1, bg: l.$3, c: l.$2),
    ],
    g: 12,
    w: 'fill',
    al: 'c',
    p: [10, 12],
    r: 16,
    bg: past ? G : WH,
    sk: past ? null : LN,
    tap: b != null ? () => bookingSheet(c, b) : null,
  );
}

Future<void> bookingSheet(BuildContext c, OwnerReq r) => openSheet(
  c,
  title: 'تفاصيل الحجز',
  top: 300,
  body: (sc, set) => [
    if (r.phone.isNotEmpty) meta('phone', r.phone, INK, 14),
    requestCard(c, r),
  ],
);

Future<void> confirmBulk(BuildContext c, String date, List<String> times, bool close) => openSheet(
  c,
  title: close ? 'تغلق كل الأوقات المتاحة؟' : 'تفتح كل الأوقات المغلقة؟',
  top: 540,
  body: (sc, set) => [
    Tn(
      close
          ? '${times.length} وقت بيوم $date راح تنغلق وما يكدر أحد يحجزها. الحجوزات الموجودة تبقى مثل ما هي.'
          : '${times.length} وقت بيوم $date راح ترجع متاحة للحجز.',
      s: 14,
      c: MU,
      lh: 24,
    ),
    btn(
      close ? 'إغلاق ${times.length} وقت' : 'فتح ${times.length} وقت',
      kind: close ? 'd' : 'p',
      tap: () async {
        final ok = await apiAction(
          c,
          repo.setClosed(date, times, close),
          close ? 'انغلقت الأوقات' : 'رجعت الأوقات متاحة',
        );
        if (ok && sc.mounted) Navigator.pop(sc);
      },
    ),
  ],
);

class OInsights extends Scr {
  const OInsights({super.key});
  @override
  Widget view(c, s) => screen(c, [
    topbar('الإحصائيات', back: false),
    body([
      R(
        [
          stat('حجوزات اليوم', '${repo.todayBookings}'),
          stat('دخل اليوم', '${fmt(repo.todayIncome)} د.ع'),
        ],
        g: 8,
        w: 'fill',
      ),
      R(
        [
          stat('المشاريع', '${repo.ownerPlaces.length}'),
          stat(
            'طلبات معلقة',
            '${repo.ownerReqs.where((r) => r.status == 'new').length}',
          ),
        ],
        g: 8,
        w: 'fill',
      ),
      Tn('الدخل محسوب من الحجوزات المكتملة أو اللي وصل أصحابها.', s: 14, c: MU),
      btn('أداء العروض', tap: () => push(c, const OOffPerf())),
      btn('تحديث', kind: 'g', tap: () => repo.refresh()),
    ]),
  ], onavTab: 'الإحصائيات');
}

class OOffPerf extends Scr {
  const OOffPerf({super.key});
  @override
  Widget view(c, s) => screen(c, [
    topbar('أداء العروض'),
    body([
      if (repo.ownerOffers.isEmpty) T('ماكو عروض', 14, 500, MU),
      for (final o in repo.ownerOffers)
        card(
          [
            T(o.place, 16, 800),
            T(o.exp, 13, 500, MU),
            R(
              [
                stat('مشاهدات', '${o.views}'),
                stat('ضغطات', '${o.clicks}'),
                stat('حجوزات', '${o.books}'),
              ],
              g: 6,
              w: 'fill',
            ),
            btn(
              o.active ? 'إيقاف' : 'تفعيل',
              kind: 'g',
              tap: () => apiAction(c, repo.toggleOffer(o), 'تم تحديث العرض'),
            ),
          ],
          g: 12,
          p: 14,
        ),
      btn('عرض جديد', tap: () => push(c, const OOffer())),
    ]),
  ], onavTab: 'الإحصائيات');
}

Future<void> postSheet(BuildContext c) => openSheet(
  c,
  title: 'نشر وإدارة',
  body: (sc, set) => [
    btn(
      'عرض جديد',
      tap: () {
        Navigator.pop(sc);
        push(c, const OOffer());
      },
    ),
    btn(
      'المواعيد',
      kind: 'g',
      tap: () {
        Navigator.pop(sc);
        push(c, const OCal());
      },
    ),
  ],
);

class OOffer extends Scr {
  const OOffer({super.key});
  @override
  Widget view(c, s) {
    final title = s.ctl('title'), pct = s.ctl('pct'), end = s.ctl('end');
    return screen(
      c,
      [
        topbar('عرض جديد'),
        ownerSelector(c),
        body([
          inp('العنوان', '', ctl: title),
          inp('نسبة الخصم', '1 - 90', ctl: pct, kb: TextInputType.number),
          inp('تاريخ الانتهاء (اختياري)', 'YYYY-MM-DD', ctl: end),
          Tn(
            'السعر محسوب من سعر المشروع المحدد. لا توجد مواعيد أو شروط تلقائية مخفية.',
            s: 13,
            c: MU,
          ),
        ]),
      ],
      bottomBar: bottom([
        btn(
          'نشر',
          tap: () async {
            final p = int.tryParse(pct.text);
            if (title.text.trim().isEmpty ||
                p == null ||
                p < 1 ||
                p > 90 ||
                (end.text.isNotEmpty && DateTime.tryParse(end.text) == null)) {
              toast(c, 'تأكد من العنوان ونسبة الخصم والتاريخ');
              return;
            }
            if (await apiAction(
                  c,
                  repo.createOffer(
                    title.text.trim(),
                    p,
                    '',
                    expiresOn: end.text.isEmpty ? null : end.text,
                  ),
                  'انتشر العرض',
                ) &&
                c.mounted)
              Navigator.pop(c);
          },
        ),
      ]),
    );
  }
}

class OProject extends Scr {
  const OProject({super.key});
  @override
  Widget view(c, s) => screen(c, [
    topbar('مشروعي', back: false),
    ownerSelector(c),
    body([
      if (repo.ownerPlace != null) rowcard(c, repo.ownerPlace!),
      btn('المعلومات / إنشاء مشروع', tap: () => push(c, const OInfo())),
      btn('الخدمات والأسعار', kind: 'g', tap: () => push(c, const OServices())),
      btn('المواعيد', kind: 'g', tap: () => push(c, const OCal())),
      btn('التقييمات', kind: 'g', tap: () => push(c, const OReviews())),
      btn('حساب الزبون', kind: 'g', tap: () => onCustomerTab(c, 'الرئيسية')),
      btn(
        'تسجيل الخروج',
        kind: 'g',
        tap: () async {
          await repo.logout();
          if (c.mounted) onCustomerTab(c, '__login');
        },
      ),
    ]),
  ], onavTab: 'مشروعي');
}

class OServices extends Scr {
  const OServices({super.key});
  @override
  Widget view(c, s) => screen(c, [
    topbar('الخدمات والأسعار'),
    ownerSelector(c),
    body([
      if (repo.services.isEmpty) T('ماكو خدمات', 14, 500, MU),
      for (var i = 0; i < repo.services.length; i++)
        card(
          [
            T(repo.services[i].$1, 16, 800),
            T(
              '${fmt(repo.services[i].$2)} د.ع / ${repo.services[i].$3}',
              14,
              600,
              P,
            ),
            R(
              [
                btn('تعديل', kind: 'g', tap: () => push(c, OEdit(i))),
                btn(
                  'حذف',
                  kind: 'd',
                  tap: () => apiAction(c, repo.deleteService(i), 'تم الحذف'),
                ),
              ],
              g: 8,
              w: 'fill',
            ),
          ],
          g: 10,
          p: 14,
        ),
      if (repo.ownerId != null)
        btn('أضف خدمة', tap: () => push(c, const OEdit(-1))),
    ]),
  ]);
}

class OEdit extends Scr {
  final int idx;
  const OEdit(this.idx, {super.key});
  @override
  Widget view(c, s) {
    final value = idx >= 0 && idx < repo.services.length
        ? repo.services[idx]
        : ('', 0, 'ساعة');
    final n = s.ctl('name', value.$1),
        p = s.ctl('price', value.$2.toString()),
        u = s.ctl('unit', value.$3);
    return screen(
      c,
      [
        topbar('الخدمة'),
        body([
          inp('الاسم', '', ctl: n),
          inp('السعر', '', ctl: p, kb: TextInputType.number),
          inp('الوحدة', '', ctl: u),
        ]),
      ],
      bottomBar: bottom([
        btn(
          'حفظ',
          tap: () async {
            final price = int.tryParse(p.text);
            if (n.text.trim().isEmpty ||
                price == null ||
                price < 0 ||
                u.text.trim().isEmpty) {
              toast(c, 'تأكد من الاسم والسعر والوحدة');
              return;
            }
            if (await apiAction(
                  c,
                  repo.saveService(idx, (n.text.trim(), price, u.text.trim())),
                  'تم الحفظ',
                ) &&
                c.mounted)
              Navigator.pop(c);
          },
        ),
      ]),
    );
  }
}

class OReviews extends Scr {
  const OReviews({super.key});
  @override
  Widget view(c, s) => screen(c, [
    topbar('التقييمات'),
    body([
      if (repo.ownerReviews.isEmpty) T('ماكو تقييمات', 14, 500, MU),
      for (final r in repo.ownerReviews)
        card(
          [
            R([T(r.name, 15, 800), rating('${r.stars}')], jc: 'sb', w: 'fill'),
            Tn(r.text, s: 14),
            if (r.reply != null) Tn(r.reply!, s: 14, c: P),
            inp('ردّك', '', ctl: s.ctl('reply${r.id}', r.reply ?? '')),
            btn(
              'حفظ الرد',
              kind: 'g',
              tap: () => apiAction(
                c,
                repo.reply(r, s.ctl('reply${r.id}').text.trim()),
                'تم حفظ الرد',
              ),
            ),
          ],
          g: 12,
          p: 14,
        ),
    ]),
  ], onavTab: 'مشروعي');
}
