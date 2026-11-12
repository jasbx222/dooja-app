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
    'تسجيل المالك يحتاج موافقة الإدارة من الداشبورد. ما نقدر نغيّر صلاحية الحساب من التطبيق.',
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
          Tn(
            'صور المشروع تستخدم مفتاح الصورة الحالي. رفع ملفات وصور فعلية غير مربوط.',
            s: 13,
            c: MU,
          ),
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

class OLoc extends Scr {
  const OLoc({super.key});
  @override
  Widget view(c, s) => noIntegration(
    c,
    'موقع المشروع',
    'إحداثيات GPS والخريطة الحية غير مربوطة. عدّل المنطقة من معلومات المشروع.',
  );
}

class OHours extends Scr {
  const OHours({super.key});
  @override
  Widget view(c, s) => noIntegration(
    c,
    'التواصل والدوام',
    'عدّل الهاتف من معلومات المشروع، وأغلق الأوقات من المواعيد. ساعات الدوام التفصيلية غير مدعومة في API الحالي.',
  );
}

class OMedia extends Scr {
  const OMedia({super.key});
  @override
  Widget view(c, s) => noIntegration(
    c,
    'الصور والفيديو',
    'رفع الصور والفيديو والتخزين غير مربوط حالياً. لن نظهر رفعاً وهمياً.',
  );
}

class OPending extends Scr {
  const OPending({super.key});
  @override
  Widget view(c, s) => noIntegration(
    c,
    'حالة الطلب',
    'لا يوجد مسار API لطلبات تسجيل المشاريع حالياً. تواصل مع الإدارة.',
  );
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
    Tn(
      'يتغير الحجز إلى ملغي. إرسال سبب أو موعد بديل غير مدعوم حالياً.',
      s: 14,
      c: MU,
    ),
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
        Tn(
          'المسح بالكاميرا غير مربوط. أدخل رمز الحجز كاملاً للتحقق من الحجز الحقيقي.',
          s: 14,
          c: MU,
        ),
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
    final a = id == null ? null : repo.availability['$id/$date'];
    final occupied = id == null ? <int>{} : repo.occupied(id, date);
    return screen(c, [
      topbar('المواعيد'),
      ownerSelector(c),
      body([
        R(
          [
            for (var i = 0; i < 5; i++)
              chip(isoDay(i), day == i, null, 11, () {
                s.set('day', i);
                repo.loadClosed(isoDay(i));
              }),
          ],
          g: 5,
          wrap: true,
          w: 'fill',
        ),
        if (id == null)
          T('اختار مشروعاً أولاً', 14, 600, MU)
        else if (a == null)
          btn('تحميل المواعيد', tap: () => repo.loadClosed(date))
        else
          for (var h = 0; h < 24; h++)
            () {
              final time = '${h.toString().padLeft(2, '0')}:00';
              final closed = repo.closedSlots.any(
                (x) => x['day'] == date && x['time'] == time,
              );
              return card(
                [
                  R(
                    [
                      T(time, 14, 800),
                      T(
                        closed
                            ? 'مغلق'
                            : occupied.contains(h)
                            ? 'محجوز'
                            : 'متاح',
                        14,
                        700,
                        closed
                            ? RD
                            : occupied.contains(h)
                            ? WR
                            : OK,
                      ),
                    ],
                    jc: 'sb',
                    w: 'fill',
                  ),
                ],
                p: 12,
                tap: closed || !occupied.contains(h)
                    ? () => apiAction(
                        c,
                        repo.toggleClosed(date, time),
                        'تم تحديث الوقت',
                      )
                    : null,
              );
            }(),
      ]),
    ], onavTab: 'الحجوزات');
  }
}

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
      Tn(
        'إحصائيات الزيارات والمصادر والفترات غير متاحة في API الحالي. الدخل ليس تسوية مدفوعات.',
        s: 14,
        c: MU,
      ),
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
      'ريل · قريباً',
      tap: () {
        Navigator.pop(sc);
        push(c, const OReel());
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

class OReel extends Scr {
  const OReel({super.key});
  @override
  Widget view(c, s) => noIntegration(
    c,
    'ريلز المشروع',
    'نشر الريلز قريباً. رفع الفيديو غير مفعّل، وما ننشر صورة المشروع بدل الريل.',
  );
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
      btn('الصور والفيديو', kind: 'g', tap: () => push(c, const OMedia())),
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

class OStaff extends Scr {
  const OStaff({super.key});
  @override
  Widget view(c, s) => noIntegration(
    c,
    'الموظفون',
    'إدارة الموظفين والصلاحيات غير مدعومة في API الحالي.',
  );
}
