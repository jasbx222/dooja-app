import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../dsl.dart';
import '../common.dart';
import '../app.dart';
import '../repo.dart';
import 'home.dart';
import 'owner.dart';

class Splash extends Scr {
  const Splash({super.key});
  @override
  void init(ScrSt s) => Future.delayed(const Duration(milliseconds: 1600), () {
    if (s.mounted) replace(s.context, const Onboard());
  });
  @override
  Widget view(c, s) => Scaffold(
    backgroundColor: col(P),
    body: Center(
      child: F(
        [
          BOX(w: 390, h: 300 - 120),
          MARK(150, WH, WH),
          Tn('DOOJA', s: 44, w: 800, c: WH, al: 'CENTER'),
          Tn('ضوجة؟', s: 24, w: 700, c: PL, al: 'CENTER'),
          BOX(w: 10, h: 220),
          Tn(
            'ضايج وما تعرف شنو تسوي؟ خلي ضوجة تختارلك!',
            s: 15,
            w: 500,
            c: PL,
            al: 'CENTER',
            w2: 320,
          ),
        ],
        g: 8,
        al: 'c',
        w: 390,
      ),
    ),
  );
}

class Onboard extends Scr {
  const Onboard({super.key});
  static const pages = [
    (
      'friends',
      'اكتشف أحلى الأماكن بمدينتك',
      'ملاعب، بادل، كافيهات، فعاليات وعروض حصرية، كلها بمكان واحد. احجز بخطوات بسيطة واجمع نقاط.',
    ),
    (
      'padel',
      'احجز موعدك بثواني',
      'شوف الأوقات المتوفرة هسه، اختار الموعد وادفع كاش أو زين كاش بدون مكالمات.',
    ),
    (
      'reel',
      'ضايج؟ خلّي ضوجة تختارلك',
      'جاوب على كم سؤال ونقترحلك الأنسب حسب ميزانيتك وعدد أصحابك وموقعك.',
    ),
  ];
  @override
  Widget view(c, s) {
    final i = s.get('i', 0);
    final pg = pages[i];
    void next() => i < 2 ? s.set('i', i + 1) : replace(c, const Login());
    return screen(c, [
      R(
        [
          F([T('تخطي', 14, 700, MU)], tap: () => replace(c, const Login())),
        ],
        jc: 'e',
        w: 'fill',
        p: [8, 24],
      ),
      F([img(pg.$1, 342, 330, 28)], w: 'fill', al: 'c', p: [12, 24]),
      F(
        [
          Tn(pg.$2, s: 26, w: 800, w2: 'fill', lh: 36),
          Tn(pg.$3, s: 15, c: MU, w2: 'fill', lh: 24),
        ],
        g: 12,
        w: 'fill',
        p: [20, 24],
      ),
      R(
        [
          for (var k = 0; k < 3; k++)
            BOX(w: k == i ? 24 : 8, h: 8, r: 4, bg: k == i ? P : PL),
        ],
        g: 6,
        p: [4, 24],
      ),
      BOX(w: 10, h: 40),
      F(
        [
          btn(
            i == 2 ? 'يلا نبدأ' : 'يلا نبدأ',
            icon: 'chevron-left',
            tap: next,
          ),
          F([
            Tn('عندك حساب؟ سجّل دخول', s: 14, w: 700, c: P, al: 'CENTER'),
          ], tap: () => replace(c, const Login())),
        ],
        g: 16,
        al: 'c',
        w: 'fill',
        p: [0, 24],
      ),
    ]);
  }
}

const IQFLAG =
    '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="16"><rect width="24" height="5.33" fill="#CE1126"/><rect y="5.33" width="24" height="5.34" fill="#fff"/><rect y="10.67" width="24" height="5.33" fill="#000"/></svg>';

class Login extends Scr {
  const Login({super.key});
  @override
  Widget view(c, s) {
    final ctl = s.ctl('ph');
    final busy = s.get('busy', false);
    final err = s.get<String?>('err', null);
    Future<void> send() async {
      final d = normPhone(ctl.text);
      if (d == null)
        return s.set('err', 'دخّل رقم موبايل عراقي صحيح، مثل 0770 000 0001');
      s.set('err', null);
      s.set('busy', true);
      try {
        await repo.requestOtp(d);
      } catch (e) {
        s.set('busy', false);
        s.set('err', e.toString());
        return;
      }
      s.set('busy', false);
      if (c.mounted) push(c, Otp(d));
    }

    return screen(c, [
      F([WORD(30)], al: 'c', w: 'fill', p: [40, 24, 30, 24]),
      F(
        [
          T('هلا بيك', 26, 800),
          T('دخّل رقم موبايلك ونرسلك رمز تحقق', 15, 400, MU),
        ],
        g: 8,
        w: 'fill',
        p: [0, 24],
      ),
      F(
        [
          F(
            [
              T('رقم الموبايل', 13, 500, MU),
              R(
                [
                  R(
                    [T('+964', 15, 700, INK), S(IQFLAG, 22, 15)],
                    g: 8,
                    bg: G,
                    r: 14,
                    h: 52,
                    p: [0, 14],
                  ),
                  R(
                    [
                      N(
                        field(
                          ctl,
                          '770 123 4567',
                          16,
                          kb: TextInputType.phone,
                          al: TextAlign.left,
                          w: 500,
                          dir: TextDirection.ltr,
                          maxLength: 14,
                        ),
                        fillW: true,
                      ),
                    ],
                    g: 10,
                    bg: G,
                    r: 14,
                    h: 52,
                    w: 'fill',
                    p: [0, 16],
                  ),
                ],
                g: 8,
                w: 'fill',
                ltr: true,
              ),
              if (err != null) T(err, 12, 500, RD),
            ],
            g: 8,
            w: 'fill',
          ),
          btn('أرسل الرمز', tap: send, busy: busy),
        ],
        g: 20,
        w: 'fill',
        p: [24, 24],
      ),
      if (kDebugMode) ...[
        BOX(w: 10, h: 16),
        F(
          [
            R([
              I('info', 14, P),
              T('تطوير فقط · الرمز 1234', 12, 700, P),
            ], g: 6),
            F(
              [T('زبون: 07700000001', 12, 500, INK)],
              tap: () {
                ctl.text = '07700000001';
                s.set('err', null);
              },
            ),
            F(
              [T('صاحب مشروع: 07700000002', 12, 500, INK)],
              tap: () {
                ctl.text = '07700000002';
                s.set('err', null);
              },
            ),
          ],
          g: 4,
          al: 'c',
          p: [10, 14],
          r: 14,
          bg: BG,
        ),
      ],
      BOX(w: 10, h: 24),
      F(
        [
          Tn(
            'بالمتابعة توافق على الشروط وسياسة الخصوصية',
            s: 12,
            c: MU,
            al: 'CENTER',
          ),
        ],
        w: 'fill',
        al: 'c',
      ),
    ]);
  }
}

class Otp extends Scr {
  final String phone;
  const Otp(this.phone, {super.key});
  @override
  void init(ScrSt s) {
    s.v['left'] = 42;
    void tick() => Future.delayed(const Duration(seconds: 1), () {
      if (!s.mounted) return;
      final l = s.get('left', 42);
      if (l > 0) {
        s.set('left', l - 1);
        tick();
      }
    });
    tick();
  }

  @override
  Widget view(c, s) {
    final ctl = s.ctl('otp');
    final focus = s.get('f', FocusNode());
    final code = ctl.text;
    final err = s.get<String?>('err', null);
    final busy = s.get('busy', false);
    final left = s.get('left', 42);
    Future<void> confirm() async {
      final entered = ctl.text.trim();
      if (entered.length < 4) return s.set('err', 'دخّل الرمز كامل');
      if (s.get('busy', false)) return;
      s.set('busy', true);
      Role role;
      try {
        role = await repo.login(phone, entered);
      } catch (e) {
        s.set('busy', false);
        s.set('err', e.toString());
        return;
      }
      if (!c.mounted) return;
      if (role == Role.owner) {
        resetTo(c, const OwnerHome(), anim: true);
      } else if (repo.isNewUser) {
        resetTo(c, const Gov(), anim: true);
      } else {
        resetTo(c, const Home(), anim: true);
      }
    }

    Widget box(String v, bool on) => F(
      [Tn(v, s: 24, w: 800, al: 'CENTER')],
      al: 'c',
      jc: 'c',
      w: 64,
      h: 64,
      r: 16,
      bg: on ? WH : G,
      sk: on ? P : null,
      skw: 2,
    );
    return screen(c, [
      topbar(''),
      F(
        [
          T('دخّل رمز التحقق', 26, 800),
          T('طلبنا رمز تحقق للرقم ${phoneFmt(phone)}', 15, 400, MU),
        ],
        g: 8,
        w: 'fill',
        p: [16, 24],
      ),
      Stack(
        children: [
          Opacity(
            opacity: 0,
            child: SizedBox(
              height: 112,
              child: TextField(
                controller: ctl,
                focusNode: focus,
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                onChanged: (_) {
                  s.set('err', null);
                  if (ctl.text.length == 4) confirm();
                },
              ),
            ),
          ),
          R(
            [
              for (var i = 0; i < 4; i++)
                box(
                  i < code.length ? code[i] : '',
                  i == code.length.clamp(0, 3),
                ),
            ],
            g: 12,
            jc: 'c',
            w: 'fill',
            p: [24, 24],
            ltr: true,
            tap: () => focus.requestFocus(),
          ),
        ],
      ),
      if (err != null)
        F(
          [Tn(err, s: 13, w: 700, c: RD, al: 'CENTER')],
          w: 'fill',
          al: 'c',
          p: [0, 0, 8, 0],
        ),
      F(
        [
          R([
            T('ما وصلك؟', 14, 400, MU),
            F(
              [
                T(
                  left > 0
                      ? 'أعد الإرسال بعد 0:${left.toString().padLeft(2, '0')}'
                      : 'أعد الإرسال',
                  14,
                  700,
                  P,
                ),
              ],
              tap: left > 0
                  ? null
                  : () async {
                      try {
                        await repo.requestOtp(phone);
                        s.set('left', 42);
                        s.widget.init(s);
                        if (c.mounted) toast(c, 'تم طلب الرمز');
                      } catch (e) {
                        s.set('err', e.toString());
                      }
                    },
            ),
          ], g: 6),
        ],
        w: 'fill',
        al: 'c',
      ),
      BOX(w: 10, h: 260),
      F(
        [btn('تأكيد', tap: confirm, busy: busy)],
        w: 'fill',
        p: [0, 24],
      ),
    ]);
  }
}

const GOVS = [
  'بغداد',
  'البصرة',
  'نينوى',
  'أربيل',
  'النجف',
  'كربلاء',
  'السليمانية',
  'بابل',
  'الأنبار',
  'ديالى',
  'كركوك',
  'ذي قار',
  'واسط',
  'صلاح الدين',
  'دهوك',
  'ميسان',
  'المثنى',
  'القادسية',
];

class Gov extends Scr {
  final bool fromSettings;
  const Gov({super.key, this.fromSettings = false});
  @override
  Widget view(c, s) {
    final q = s.ctl('q');
    final sel = s.get('sel', repo.gov);
    final list = GOVS.where((g) => g.contains(q.text.trim())).toList();
    final k = <Widget>[];
    for (final g in list) {
      final on = g == sel;
      k.add(
        R(
          [
            T(g, 16, on ? 700 : 500, on ? P : INK),
            on
                ? I('circle-check', 22, P)
                : BOX(w: 22, h: 22, r: 11, sk: LN, skw: 2),
          ],
          jc: 'sb',
          w: 'fill',
          p: [16, 0],
          tap: () => s.set('sel', g),
        ),
      );
      k.add(divider());
    }
    return screen(
      c,
      [
        topbar('وين انت؟', back: fromSettings),
        F(
          [
            Tn(
              'اختار محافظتك حتى نعرضلك الأماكن القريبة',
              s: 15,
              c: MU,
              w2: 'fill',
            ),
            R(
              [
                I('search', 20, MU),
                N(
                  field(
                    q,
                    'دوّر على محافظة',
                    15,
                    onChanged: (_) => s.set('x', 0),
                  ),
                  fillW: true,
                ),
              ],
              g: 10,
              bg: G,
              r: 14,
              h: 48,
              w: 'fill',
              p: [0, 16],
            ),
            R(
              [I('locate-fixed', 20, P), T('استخدم موقعي الحالي', 15, 700, P)],
              g: 8,
              p: [4, 0],
              tap: () => toast(c, 'تحديد الموقع غير مربوط حالياً'),
            ),
          ],
          g: 14,
          w: 'fill',
          p: [4, 24],
        ),
        F(k, w: 'fill', p: [0, 24]),
      ],
      bottomBar: bottom([
        btn(
          'التالي',
          tap: () async {
            if (await apiAction(c, repo.saveProfile(governorate: sel)) &&
                c.mounted) {
              fromSettings ? Navigator.pop(c) : push(c, const Interests());
            }
          },
        ),
      ]),
    );
  }
}

class Interests extends Scr {
  const Interests({super.key});
  static const ints = [
    ('dribbble', 'ملاعب'),
    ('padel', 'بادل'),
    ('billiard', 'بليارد'),
    ('gamepad-2', 'ألعاب إلكترونية'),
    ('coffee', 'كافيهات'),
    ('utensils', 'مطاعم'),
    ('tree-palm', 'منتجعات'),
    ('waves', 'مسابح'),
    ('party-popper', 'فعاليات'),
    ('baby', 'أنشطة عائلية'),
  ];
  @override
  Widget view(c, s) {
    final sel = repo.interests;
    void done() => resetTo(c, const Home(), anim: true);
    return screen(c, [
      topbar('شنو يعجبك؟', right: F([T('تخطي', 14, 700, MU)], tap: done)),
      F(
        [
          Tn('اهتمامات محلية للجلسة فقط', s: 15, c: MU, w2: 'fill'),
          T('${sel.length} مختارة', 13, 700, P),
        ],
        g: 6,
        w: 'fill',
        p: [4, 24],
      ),
      R(
        [
          for (final (n, l) in ints)
            F(
              [
                cicon(n, 28, sel.contains(l) ? P : INK),
                Tn(
                  l,
                  s: 14,
                  w: sel.contains(l) ? 700 : 500,
                  c: sel.contains(l) ? P : INK,
                  al: 'CENTER',
                ),
              ],
              g: 10,
              al: 'c',
              jc: 'c',
              w: 106,
              h: 104,
              r: 20,
              bg: sel.contains(l) ? PL : G,
              sk: sel.contains(l) ? P : null,
              skw: 2,
              tap: () {
                sel.contains(l) ? sel.remove(l) : sel.add(l);
                repo.touch();
              },
            ),
        ],
        g: 12,
        wrap: true,
        w: 'fill',
        p: [16, 24],
      ),
    ], bottomBar: bottom([btn('خلصت', tap: done)]));
  }
}

/// Lenient Iraqi mobile normaliser: returns 07XXXXXXXXX or null.
String? normPhone(String raw) {
  var d = raw.replaceAll(RegExp(r'\D'), '');
  if (d.startsWith('00964')) d = d.substring(5);
  if (d.startsWith('964')) d = d.substring(3);
  d = d.replaceFirst(RegExp(r'^0+'), '');
  if (d.length == 11 && d.startsWith('7')) {
    // one extra digit typed inside a run of zeros (e.g. 077000000001)
    final m = RegExp(r'0{2,}').allMatches(d).toList();
    if (m.isNotEmpty) {
      m.sort((x, y) => (y.end - y.start) - (x.end - x.start));
      d = d.replaceRange(m.first.start, m.first.start + 1, '');
    }
  }
  if (!RegExp(r'^7\d{9}$').hasMatch(d)) return null;
  return '0$d';
}
