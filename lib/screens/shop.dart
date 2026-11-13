import 'dart:math';

import 'package:flutter/material.dart';

import '../app.dart';
import '../common.dart';
import '../dsl.dart';
import '../repo.dart';

Widget cartButton(BuildContext c, {VoidCallback? tap}) {
  final n = repo.cartCount;
  return F(
    [
      I('shopping-bag', 20, INK),
      if (n > 0)
        F(
          [Tn('$n', s: 10, w: 700, c: WH, al: 'CENTER')],
          al: 'c',
          jc: 'c',
          w: 18,
          h: 18,
          r: 9,
          bg: P,
          ab: [22, -2],
        ),
    ],
    al: 'c',
    jc: 'c',
    w: 40,
    h: 40,
    r: 20,
    bg: WH,
    sk: LN,
    tap: tap ?? () => push(c, const ShopPage(initial: 1)),
  );
}

Widget productPhoto(String? path, double w, double h, {double r = 16}) {
  final asset = path != null && path.startsWith('assets/') ? path : null;
  final url = asset == null ? repo.media(path) : '';
  Widget fallback([String icon = 'store']) => ColoredBox(color: col(PL), child: Center(child: I(icon, 28, P)));
  Widget picture;
  if (asset != null) {
    picture = Image.asset(asset, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback('image'));
  } else if (url.isEmpty) {
    picture = fallback();
  } else {
    picture = Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback('image'));
  }
  return ClipRRect(
    borderRadius: BorderRadius.circular(r),
    child: ColoredBox(
      color: col(PL),
      child: SizedBox(width: w, height: h, child: picture),
    ),
  );
}

class ShopPage extends Scr {
  final int initial;
  const ShopPage({this.initial = 0, super.key});
  @override
  void init(ScrSt s) {
    s.set('tab', initial);
    if (!repo.shopHydrated) repo.openStore();
  }

  @override
  Widget view(c, s) {
    final tab = s.get('tab', initial);
    return screen(c, [
      R(
        [
          F([
            T('التسوق', 24, 800),
            T('منتجات وعروض توصلك للبيت', 13, 400, MU),
          ], g: 2),
          R([
            iconbtn('heart', tap: () => onCustomerTab(c, 'المفضلة')),
            cartButton(c, tap: () {
              s.set('tab', 1);
            }),
          ], g: 8),
        ],
        jc: 'sb',
        al: 'c',
        w: 'fill',
        p: [8, 20, 4, 20],
      ),
      tabs(const ['المتجر', 'السلة', 'طلباتي'], tab, (i) {
        s.set('tab', i);
        if (i == 2) repo.loadOrders();
        if (i == 0) {
          repo.openStore(q: s.ctl('q').text, categoryId: s.v['cat'] as int?, sort: s.get('sort', 'latest'), discounted: s.get('sale', false));
        }
      }),
      if (tab == 0) _store(c, s),
      if (tab == 1) _cart(c, s),
      if (tab == 2) _orders(c, s),
    ], nav: 'التسوق', bg: BG);
  }

  void _search(ScrSt s, {int? categoryId, String? sort, bool? discounted, int page = 1}) {
    int? money(String raw) => raw.trim().isEmpty ? null : int.tryParse(raw.trim());
    repo.openStore(
      q: s.ctl('q').text,
      categoryId: categoryId ?? s.v['cat'] as int?,
      sort: sort ?? s.get('sort', 'latest'),
      minPrice: money(s.ctl('min').text),
      maxPrice: money(s.ctl('max').text),
      discounted: discounted ?? s.get('sale', false),
      page: page,
    );
  }

  void _queueSearch(ScrSt s) {
    final tok = (s.v['tok'] as int? ?? 0) + 1;
    s.v['tok'] = tok;
    Future.delayed(const Duration(milliseconds: 280), () {
      if (s.mounted && s.v['tok'] == tok) _search(s);
    });
  }

  Widget _empty(String icon, String title, String sub, {String? action, VoidCallback? tap}) => F([
    BOX(w: 10, h: 40),
    F([I(icon, 42, P)], al: 'c', jc: 'c', w: 110, h: 110, r: 32, bg: PL),
    Tn(title, s: 20, w: 800, al: 'CENTER'),
    Tn(sub, s: 14, c: MU, al: 'CENTER', w2: 280, lh: 22),
    if (action != null && tap != null) btn(action, kind: 's', w: 220, tap: tap),
  ], g: 14, al: 'c', w: 'fill', p: [36, 24]);

  Widget _store(BuildContext c, ScrSt s) {
    if (repo.shopLoading && repo.shopProducts.isEmpty) {
      return F([
        _filters(s, enabled: false),
        const ShopSkeleton(),
      ], g: 16, w: 'fill');
    }
    if (repo.shopError != null && repo.shopProducts.isEmpty) {
      return _empty('wifi', 'تعذر تحميل المتجر', repo.shopError!, action: 'إعادة المحاولة', tap: () => repo.openStore());
    }
    if (!repo.shopEnabled) {
      return _empty('store', 'المتجر متوقف حالياً', 'يرجع لما الإدارة تفتحه من لوحة التحكم.');
    }
    final featured = repo.shopProducts.where((p) => p.featured && p.available).take(8).toList();
    return F([
      _filters(s),
      if (featured.length >= 2 && (s.ctl('q').text.isEmpty) && s.v['cat'] == null) ...[
        sechead('مختارات ضوجة', 'sparkle', null),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < featured.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  SizedBox(width: 220, child: _featureCard(c, featured[i])),
                ],
              ],
            ),
          ),
        ),
      ],
      if (repo.shopProducts.isEmpty)
        _empty(
          'search',
          'ماكو منتجات بهالبحث',
          'جرّب كلمة ثانية أو صفّر الفلاتر حتى تشوف كل المنتجات.',
          action: 'مسح البحث',
          tap: () {
            s.ctl('q').clear();
            s.ctl('min').clear();
            s.ctl('max').clear();
            s.set('cat', null);
            s.set('sort', 'latest');
            s.set('sale', false);
            _search(s, categoryId: null, sort: 'latest', discounted: false);
          },
        )
      else ...[
        R([
          T('المنتجات', 18, 800),
          T('${repo.shopTotal} منتج', 13, 500, MU),
        ], jc: 'sb', w: 'fill', p: [4, 20, 0, 20]),
        F([
          for (var i = 0; i < repo.shopProducts.length; i += 2)
            R([
              N(_miniCard(c, repo.shopProducts[i]), fillW: true),
              if (i + 1 < repo.shopProducts.length)
                N(_miniCard(c, repo.shopProducts[i + 1]), fillW: true)
              else
                const N(SizedBox(), fillW: true),
            ], g: 12, al: 's', w: 'fill'),
          if (repo.shopProducts.length < repo.shopTotal)
            btn('عرض المزيد', kind: 's', tap: () => _search(s, page: repo.shopPage + 1)),
        ], g: 12, w: 'fill', p: [4, 20, 20, 20]),
      ],
    ], g: 14, w: 'fill');
  }

  Widget _filters(ScrSt s, {bool enabled = true}) {
    final q = s.ctl('q');
    return F([
      F(
        [
          R([
            I('search', 20, P),
            N(
              field(q, 'ابحث عن منتج، ماركة أو قسم', 14, onChanged: enabled ? (_) => _queueSearch(s) : null),
              fillW: true,
            ),
            if (q.text.isNotEmpty)
              F([
                I('x', 16, MU),
              ], al: 'c', jc: 'c', w: 28, h: 28, r: 14, bg: WH, tap: enabled
                  ? () {
                      q.clear();
                      _search(s);
                    }
                  : null),
          ], g: 10, bg: WH, r: 18, h: 56, w: 'fill', p: [0, 16], sk: LN),
        ],
        w: 'fill',
        p: [8, 20, 0, 20],
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: R([
          chip('الكل', s.v['cat'] == null, 'layout-grid', 13, enabled
              ? () {
                  s.set('cat', null);
                  _search(s, categoryId: null);
                }
              : null),
          for (final cat in repo.shopCategories)
            chip(cat.name, s.v['cat'] == cat.id, 'store', 13, enabled
                ? () {
                    s.set('cat', cat.id);
                    _search(s, categoryId: cat.id);
                  }
                : null),
        ], g: 8, p: [0, 20]),
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: R([
          for (final (id, label, icon) in [
            ('latest', 'الأحدث', 'sparkle'),
            ('price_asc', 'الأرخص', 'banknote'),
            ('price_desc', 'الأغلى', 'wallet'),
            ('discount', 'التخفيضات', 'badge-percent'),
          ])
            chip(label, s.get('sort', 'latest') == id, icon, 13, enabled
                ? () {
                    s.set('sort', id);
                    s.set('sale', id == 'discount');
                    _search(s, sort: id, discounted: id == 'discount');
                  }
                : null),
        ], g: 8, p: [0, 20]),
      ),
    ], g: 12, w: 'fill');
  }

  Widget _featureCard(BuildContext c, ShopProduct p) => F([
    Stack(children: [
      productPhoto(p.image, 220, 150, r: 0),
      if (p.discount != null)
        Positioned(top: 10, right: 10, child: tag('خصم ${p.discount}%', bg: P, c: WH, s: 11)),
    ]),
    F([
      Tx(p.name, 15, 800, INK, maxLines: 1),
      price(fmt(p.price), p.compareAt == null ? null : fmt(p.compareAt!)),
    ], g: 6, p: [12, 14, 14, 14], w: 'fill'),
  ], w: 220, r: 22, bg: WH, sk: LN, clip: true, tap: () => push(c, ProductPage(p.id)));

  Widget _miniCard(BuildContext c, ShopProduct p) => F([
    Stack(children: [
      productPhoto(p.image, 169, 150, r: 0),
      if (p.discount != null)
        Positioned(top: 10, right: 10, child: tag('خصم ${p.discount}%', bg: P, c: WH, s: 11)),
      if (!p.available)
        Positioned.fill(
          child: ColoredBox(
            color: const Color(0x88FFFFFF),
            child: Center(child: tag('نفد', bg: '#FDECEC', c: RD)),
          ),
        ),
    ]),
    F([
      Tx(p.name, 14, 800, INK, maxLines: 2),
      Tn(p.category, s: 11, c: MU, maxLines: 1),
      R([
        N(
          F([
            if (p.compareAt != null) Tn('${fmt(p.compareAt!)} د.ع', s: 11, c: MU, st: true, maxLines: 1),
            Tx('${fmt(p.price)} د.ع', 13, 800, P, maxLines: 1),
          ], g: 2),
          fillW: true,
        ),
        F(
          [I('plus', 16, p.available ? WH : MU)],
          al: 'c',
          jc: 'c',
          w: 32,
          h: 32,
          r: 16,
          bg: p.available ? P : G,
          tap: p.available
              ? () {
                  repo.addToCart(p.id, 1).then((err) {
                    if (c.mounted) toast(c, err ?? 'انضاف للسلة');
                  });
                }
              : null,
        ),
      ], jc: 'sb', al: 'c', w: 'fill'),
    ], g: 6, p: [10, 12, 12, 12], w: 'fill'),
  ], w: 'fill', r: 22, bg: WH, sk: LN, clip: true, tap: () => push(c, ProductPage(p.id)));

  Widget _cart(BuildContext c, ScrSt s) {
    if (repo.cartLines.isEmpty) {
      return _empty('store', 'السلة فارغة', 'ضيف منتجات من المتجر حتى تكمل طلبك بهالخطوة.', action: 'تصفح المتجر', tap: () => s.set('tab', 0));
    }
    return F([
      if (repo.cartWarnings.isNotEmpty) F([for (final w in repo.cartWarnings) Tn(w, s: 12, c: WR)], g: 4, w: 'fill', p: [10, 14], r: 16, bg: WRB),
      for (final line in repo.cartLines)
        R([
          productPhoto(line.image, 76, 76, r: 16),
          F([
            Tn(line.name, s: 14, w: 700, maxLines: 1),
            price(fmt(line.unitPrice)),
            R([
              iconbtn('minus', s: 32, tap: () {
                repo.setCartQty(line.productId, line.qty - 1).then((err) { if (err != null && c.mounted) toast(c, err); });
              }),
              Tn('${line.qty}', s: 14, w: 700),
              iconbtn('plus', s: 32, tap: () {
                repo.setCartQty(line.productId, line.qty + 1).then((err) { if (err != null && c.mounted) toast(c, err); });
              }),
            ], g: 8, al: 'c'),
          ], g: 6, w: 'fill'),
          F([
            Tn('${fmt(line.lineTotal)} د.ع', s: 13, w: 700, c: P),
            F([I('trash-2', 16, RD)], tap: () => repo.setCartQty(line.productId, 0)),
          ], g: 8, al: 'e'),
        ], g: 10, al: 'c', w: 'fill', p: [10, 12], r: 18, bg: WH, sk: LN),
      F([
        R([Tn('المجموع', s: 14, c: MU), Tn('${fmt(repo.cartSubtotal)} د.ع', s: 18, w: 800, c: P)], jc: 'sb', w: 'fill'),
        if (repo.cartDiscount > 0) Tn('وفّرت ${fmt(repo.cartDiscount)} د.ع مقارنة بالسعر السابق', s: 12, c: OK),
        btn('إتمام الشراء', tap: () {
          if (!repo.authenticated) {
            toast(c, 'سجّل دخول حتى تكتمل السلة على حسابك');
            onCustomerTab(c, '__login');
            return;
          }
          push(c, const CheckoutPage());
        }),
      ], g: 10, w: 'fill', p: 16, r: 22, bg: WH, sk: LN),
    ], g: 12, w: 'fill', p: [8, 20]);
  }

  Widget _orders(BuildContext c, ScrSt s) {
    if (!repo.authenticated) {
      return _empty('user', 'سجل دخول لتشوف طلباتك', 'طلباتك تنحفظ بحسابك حتى تراجع حالتها بأي وقت.', action: 'تسجيل الدخول', tap: () => onCustomerTab(c, '__login'));
    }
    if (repo.shopOrders.isEmpty) {
      return _empty('store', 'ما عندك طلبات بعد', 'أول طلب رح يظهر هنا مع رقم التتبع وحالته.', action: 'تسوق الآن', tap: () => s.set('tab', 0));
    }
    return F([
      for (final o in repo.shopOrders)
        F([
          R([Tn(o.number, s: 14, w: 800), tag(o.status, bg: PL, c: P)], jc: 'sb', w: 'fill'),
          Tn('${fmt(o.total)} د.ع · ${o.pay}', s: 13, c: MU),
          if (o.createdAt.isNotEmpty) Tn(o.createdAt, s: 12, c: MU),
        ], g: 6, w: 'fill', p: 16, r: 18, bg: WH, sk: LN, tap: () => push(c, OrderPage(o.id))),
    ], g: 10, w: 'fill', p: [8, 20]);
  }
}

class ShopSkeleton extends StatefulWidget {
  const ShopSkeleton({super.key});
  @override
  State<ShopSkeleton> createState() => _ShopSkeletonState();
}

class _ShopSkeletonState extends State<ShopSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Widget box(double w, double h, {double r = 16}) => FadeTransition(
    opacity: Tween(begin: 0.35, end: 0.8).animate(_ctl),
    child: BOX(w: w, h: h, r: r, bg: WH),
  );

  @override
  Widget build(BuildContext context) => F([
    R([
      for (var i = 0; i < 2; i++)
        N(F([
          box(169, 150, r: 0),
          F([box(120, 12, r: 6), box(80, 12, r: 6)], g: 8, p: 12, w: 'fill'),
        ], w: 'fill', r: 22, bg: G, clip: true), fillW: true),
    ], g: 12, w: 'fill', p: [4, 20]),
    R([
      for (var i = 0; i < 2; i++)
        N(F([
          box(169, 150, r: 0),
          F([box(120, 12, r: 6), box(80, 12, r: 6)], g: 8, p: 12, w: 'fill'),
        ], w: 'fill', r: 22, bg: G, clip: true), fillW: true),
    ], g: 12, w: 'fill', p: [4, 20, 20, 20]),
  ], g: 12, w: 'fill');
}

class ProductPage extends Scr {
  final int id;
  const ProductPage(this.id, {super.key});
  @override
  void init(ScrSt s) {
    s.set('qty', 1);
    repo.openProduct(id);
  }

  @override
  Widget view(c, s) {
    final p = repo.currentProduct;
    if (p == null || p.id != id) {
      return screen(c, [
        topbar('المنتج'),
        if (repo.shopError != null)
          F([
            Tn(repo.shopError!, s: 14, c: RD, al: 'CENTER'),
            btn('إعادة المحاولة', kind: 's', tap: () => repo.openProduct(id)),
          ], g: 12, al: 'c', w: 'fill', p: [40, 24])
        else
          const ShopSkeleton(),
      ], bg: BG);
    }
    final qty = s.get('qty', 1);
    final photos = p.images.where((e) => e.isNotEmpty).toList();
    return screen(c, [
      topbar(p.name, right: cartButton(c)),
      if (photos.isEmpty)
        F([productPhoto(null, 350, 240, r: 24)], w: 'fill', al: 'c', p: [0, 20])
      else
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: R([for (final src in photos) productPhoto(src, 280, 240, r: 24)], g: 10, p: [0, 20])),
      F([
        if (p.category.isNotEmpty) tag(p.category, bg: PL, c: P),
        T(p.name, 22, 800),
        R([price(fmt(p.price), p.compareAt == null ? null : fmt(p.compareAt!), 18), tag(p.available ? 'متوفر' : 'غير متوفر', bg: p.available ? OKB : '#FDECEC', c: p.available ? OK : RD)], jc: 'sb', w: 'fill'),
        if (p.description.isNotEmpty) Tn(p.description, s: 14, lh: 22),
        if (p.specs.isNotEmpty) F([Tn('المواصفات', s: 14, w: 800), Tn(p.specs, s: 13, c: MU, lh: 22)], g: 6, w: 'fill'),
        R([
          Tn('الكمية', s: 14, w: 700),
          R([
            iconbtn('minus', tap: qty > 1 ? () => s.set('qty', qty - 1) : null),
            Tn('$qty', s: 16, w: 800),
            iconbtn('plus', tap: qty < p.stock ? () => s.set('qty', qty + 1) : null),
          ], g: 10, al: 'c'),
        ], jc: 'sb', al: 'c', w: 'fill'),
        btn('أضف للسلة', tap: p.available ? () {
          repo.addToCart(p.id, qty).then((err) { if (c.mounted) toast(c, err ?? 'انضاف للسلة'); });
        } : null),
      ], g: 12, w: 'fill', p: 16, r: 24, bg: WH, sk: LN),
    ], bg: BG);
  }
}

class CheckoutPage extends Scr {
  const CheckoutPage({super.key});
  @override
  void init(ScrSt s) {
    s.set('key', 'shop-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 32)}');
    s.ctl('name', repo.userName);
    s.ctl('phone', repo.phone);
    s.ctl('gov', repo.deliveryAreas.isEmpty ? repo.gov : '');
    s.ctl('area', repo.area);
    s.ctl('addr');
    s.ctl('notes');
  }

  @override
  Widget view(c, s) {
    final busy = s.get('busy', false);
    final pay = s.get('pay', repo.payMethods.isEmpty ? '' : repo.payMethods.first.$1);
    final fee = () {
      if (repo.deliveryAreas.isEmpty) return repo.shopDeliveryFee;
      final match = repo.deliveryAreas.where((a) => a.governorate == s.ctl('gov').text && a.area == s.ctl('area').text);
      return match.isEmpty ? repo.shopDeliveryFee : match.first.fee;
    }();
    final total = repo.cartSubtotal + fee;
    return screen(c, [
      topbar('إتمام الشراء'),
      F([
        inp('الاسم', 'اسم المستلم', ctl: s.ctl('name')),
        inp('الهاتف', '07xxxxxxxxx', ctl: s.ctl('phone'), kb: TextInputType.phone),
        if (repo.deliveryAreas.isEmpty) ...[
          inp('المحافظة', 'بغداد', ctl: s.ctl('gov')),
          inp('المنطقة', 'المنطقة', ctl: s.ctl('area')),
        ] else ...[
          Tn('منطقة التوصيل', s: 13, c: MU),
          for (final a in repo.deliveryAreas)
            chip('${a.governorate} · ${a.area}', s.ctl('gov').text == a.governorate && s.ctl('area').text == a.area, null, 13, () {
              s.ctl('gov').text = a.governorate;
              s.ctl('area').text = a.area;
              s.set('area', a.id);
            }),
        ],
        inp('العنوان', 'أقرب نقطة دالة', ctl: s.ctl('addr')),
        inp('ملاحظات', 'اختياري', ctl: s.ctl('notes')),
        Tn('طريقة الدفع', s: 13, c: MU),
        if (repo.payMethods.isEmpty) Tn('لا توجد طريقة دفع مفعّلة', s: 13, c: RD),
        for (final m in repo.payMethods) chip(m.$2, pay == m.$1, null, 13, () => s.set('pay', m.$1)),
        F([
          R([Tn('البضاعة', s: 13, c: MU), Tn('${fmt(repo.cartSubtotal)} د.ع', s: 13, w: 700)], jc: 'sb', w: 'fill'),
          if (repo.cartDiscount > 0) R([Tn('قيمة الخصم', s: 13, c: MU), Tn('${fmt(repo.cartDiscount)} د.ع', s: 13, w: 700)], jc: 'sb', w: 'fill'),
          R([Tn('التوصيل', s: 13, c: MU), Tn('${fmt(fee)} د.ع', s: 13, w: 700)], jc: 'sb', w: 'fill'),
          R([Tn('الإجمالي', s: 16, w: 800), Tn('${fmt(total)} د.ع', s: 16, w: 800, c: P)], jc: 'sb', w: 'fill'),
          Tn('الإجمالي النهائي يتأكد من الخادم وقت إنشاء الطلب.', s: 11, c: MU),
        ], g: 8, w: 'fill', p: 14, r: 16, bg: BG),
        btn('تأكيد الطلب', busy: busy, tap: busy ? null : () {
          s.set('busy', true);
          repo.checkout(name: s.ctl('name').text, phone: s.ctl('phone').text, governorate: s.ctl('gov').text, area: s.ctl('area').text, address: s.ctl('addr').text, notes: s.ctl('notes').text, payMethod: pay, idempotencyKey: s.get('key', '')).then((result) {
            final (order, err) = result;
            s.set('busy', false);
            if (!c.mounted) return;
            if (err != null || order == null) {
              toast(c, err ?? 'تعذر إكمال الطلب');
              return;
            }
            resetTo(c, OrderDone(order), anim: true);
          });
        }),
      ], g: 12, w: 'fill', p: [0, 20]),
    ]);
  }
}

class OrderDone extends Scr {
  final ShopOrder order;
  const OrderDone(this.order, {super.key});
  @override
  Widget view(c, s) => screen(c, [
    F([
      I('circle-check', 56, OK),
      Tn('تم استلام طلبك', s: 22, w: 800, al: 'CENTER'),
      Tn(order.number, s: 16, w: 700, c: P, al: 'CENTER'),
      Tn('${fmt(order.total)} د.ع · ${order.pay}', s: 14, c: MU, al: 'CENTER'),
      Tn(order.status, s: 13, al: 'CENTER'),
      btn('تفاصيل الطلب', kind: 's', tap: () => push(c, OrderPage(order.id))),
      btn('متابعة التسوق', tap: () => onCustomerTab(c, 'التسوق')),
    ], g: 12, al: 'c', w: 'fill', p: [80, 24]),
  ]);
}

class OrderPage extends Scr {
  final int id;
  const OrderPage(this.id, {super.key});
  @override
  void init(ScrSt s) => repo.loadOrders();
  @override
  Widget view(c, s) {
    final found = repo.shopOrders.where((o) => o.id == id);
    if (found.isEmpty) return screen(c, [topbar('الطلب'), Tn(repo.shopError ?? 'جاري تحميل الطلب...', s: 14, c: MU, al: 'CENTER')]);
    final o = found.first;
    final canCancel = o.status == 'بانتظار التأكيد';
    return screen(c, [
      topbar(o.number),
      F([
        tag(o.status, bg: PL, c: P),
        Tn('${o.name} · ${o.phone}', s: 14),
        Tn('${o.governorate} · ${o.area}', s: 13, c: MU),
        Tn(o.address, s: 13),
        for (final line in o.items) R([Tn('${line.name} × ${line.qty}', s: 14), Tn('${fmt(line.lineTotal)} د.ع', s: 14, w: 700)], jc: 'sb', w: 'fill'),
        R([Tn('الإجمالي', s: 16, w: 800), Tn('${fmt(o.total)} د.ع', s: 16, w: 800, c: P)], jc: 'sb', w: 'fill'),
        Tn(o.pay, s: 13, c: MU),
        Tn('سجل الحالة', s: 14, w: 800),
        for (final h in o.history) Tn('${h.$1} · ${h.$2}', s: 12, c: MU),
        if (canCancel) btn('إلغاء الطلب', kind: 'd', tap: () {
          repo.cancelOrder(o.id).then((err) {
            if (!c.mounted) return;
            toast(c, err ?? 'تم إلغاء الطلب');
            if (err == null) repo.loadOrders();
          });
        }),
      ], g: 10, w: 'fill', p: [8, 20]),
    ]);
  }
}
