# نشر ضوجة على Oracle Cloud

هذا الملف يجهّز النشر. السيرفر **غير منشور** لأن حساب Oracle Cloud غير مسجّل دخول في المتصفح، وأداة `oci` غير مثبّتة على الجهاز. لا يوجد عنوان عام جديد، ولا فحص خارجي ناجح.

## ما الموجود في المشروع

- الباك إند مشروع واحد: `dashboard/src/Dooja.Web`، ‎.NET 8.
- قاعدة البيانات الافتراضية SQLite. Postgres اختياري عبر `Database__Provider=Postgres`، ولم يُنشأ هنا.
- لا توجد ترحيلات EF. أول تشغيل على ملف SQLite فاضي ينشئ الجداول بـ `EnsureCreated`. هذا ليس نقلاً لقاعدة موجودة.
- الإنتاج يرفض الإقلاع إذا `Jwt__Key` أو `Admin__Password` فاضي.
- `Seed__Demo` في الإنتاج لازم `false`. الريلز والرسائل القصيرة يبقون متوقفين. لا تضبط مفاتيح SMS.
- CORS في الإنتاج يقرأ `Cors:Origins`. المضيف المسموح يقرأ `AllowedHosts`.
- التطبيق يثق برؤوس `X-Forwarded-For` و`X-Forwarded-Proto` من `127.0.0.1` فقط، حتى يعمل HTTPS خلف Nginx.
- المنفذ الداخلي `127.0.0.1:5080`. الجمهور يصل عبر Nginx على 80 أو 443.
- العنوان الحالي المبني داخل تطبيق الويب هو `https://dooja.cloudapps.trade`. ما يتغير إلا بعد ما يصير عنوان OCI حقيقي وإعادة بناء.

## البنية المقترحة

آلة Ubuntu 24.04 واحدة داخل VCN، شبكة فرعية عامة، عنوان IP عام. Nginx على الآلة يستقبل 80/443 ويحوّل إلى Kestrel على الحلقة المحلية. ملف SQLite يعيش في `/var/lib/dooja` خارج مجلد النشر حتى التحديث ما يمسحه.

الأشكال المجانية المناسبة:

| الشكل | المعمارية | الحجم المجاني | أمر النشر |
|---|---|---|---|
| `VM.Standard.A1.Flex` | ARM64 | حتى 4 OCPU و24 GB، حسب حصة الحساب | `-Runtime linux-arm64` |
| `VM.Standard.E2.1.Micro` | AMD64 | 1/8 OCPU و1 GB | `-Runtime linux-x64` |

فضّل Ampere بحصة مجانية: 1 OCPU و6 GB RAM. الـ Micro يكفي للتجربة وذاكرته ضيقة. لا تنشئ شكلاً مدفوعاً قبل موافقة صريحة. قرص الإقلاع 50 GB ضمن الحد المجاني. لا تنشئ قاعدة Oracle مدفوعة ولا Block Volume إضافي.

المنطقة تُختار من الحساب بعد تسجيل الدخول. لا تفترض منطقة.

## ما ينقص قبل إنشاء أي مورد

1. تسجيل الدخول في صفحة Cloud Sign In باسم حساب السحابة، ثم اسم المستخدم وكلمة المرور. الصفحة المفتوحة الآن تطلب Cloud Account Name وما فيها جلسة.
2. موافقة على إنشاء الآلة المجانية والشبكة التابعة لها.
3. موافقة على فتح المنافذ في Security List أو NSG:
   - 22 من عنوانك فقط.
   - 80 و443 من الإنترنت بعد ما يكون النشر جاهزاً.
4. نطاق إذا أردت HTTPS من Let's Encrypt. شهادة Let's Encrypt لا تصدر لعنوان IP.
5. مفتاح SSH عام يُلصق عند إنشاء الآلة. المفتاح الخاص يبقى على هذا الجهاز ولا يدخل المستودع.

## متغيرات البيئة

الأسماء فقط. القيم تُكتب على السيرفر في `/etc/dooja/dooja.env` بصلاحية `600`. القالب: `deploy/oci/dooja.env.example`.

- `ASPNETCORE_ENVIRONMENT`
- `ASPNETCORE_URLS`
- `Database__Provider`
- `ConnectionStrings__Dooja`
- `Seed__Demo`
- `Features__Reels`
- `AllowedHosts`
- `Cors__Origins__0`
- `Jwt__Key`
- `Admin__Password`

`install-server.sh` ينشئ الملف مرة واحدة إذا كان غير موجود، ويولّد `Jwt__Key` و`Admin__Password` داخل الملف بدون طباعتهما. اقرأ كلمة لوحة الإدارة عبر SSH وخزّنها خارج المستودع. التشغيل التالي لا يستبدل الملف.

لا تضبط `Sms__Provider` ولا مفاتيح Twilio.

## أوامر النشر والتحديث

من جهاز ويندوز، بعد ما يكون عندك مستخدم SSH وعنوان عام:

```powershell
$env:DOOJA_SSH = "ubuntu@<public-ip>"
$env:DOOJA_PUBLIC_HOST = "<domain-or-ip>"
powershell -File deploy\oci\publish.ps1 -Runtime linux-arm64
```

السكربت ينشر Release، ينسخ الملفات، ويشغّل `install-server.sh` على السيرفر. السكربت على السيرفر:

- يثبّت Nginx وASP.NET Core Runtime 8.
- ينشئ المستخدم `dooja` بدون دخول.
- يحفظ نسخة من `/opt/dooja` في `/var/backups/dooja` قبل الاستبدال.
- يضع الخدمة `dooja.service` مع `Restart=always` وتشغيل عند الإقلاع.
- يترك Kestrel على `127.0.0.1:5080`.

بعد ربط نطاق يشير إلى الآلة، وموافقة على الشهادة:

```bash
DOOJA_PUBLIC_HOST=api.example.com DOOJA_CERT_EMAIL=you@example.com bash enable-https.sh
```

ثم أعد بناء تطبيق Flutter بنفس العنوان وانسخه إلى `wwwroot/app` قبل النشر التالي:

```bash
flutter build web --release --base-href /app/ --dart-define=API_BASE_URL=https://api.example.com
```

`Cors__Origins__0` يصير `https://api.example.com` إذا فُتح التطبيق من نفس المضيف. إذا بقي التطبيق على `https://dooja.cloudapps.trade` وهو يستدعي API على مضيف آخر، أضف أصل الواجهة في `Cors__Origins__0` وأعد تشغيل الخدمة.

## قاعدة البيانات

لا تنسخ `Dooja.db` من جهاز التطوير: فيها بيانات عرض. السيرفر الجديد يبدأ بملف فاضي في `/var/lib/dooja/dooja.db`. أول تشغيل ينشئ الجداول وحساب المدير فقط، بدون أماكن تجريبية، لأن `Seed__Demo=false`.

لا تشغّل `dashboard/scripts/smoke.py` على هذا الملف. هذا السكربت يكتب بيانات.

نسخ احتياطي لقاعدة السيرفر:

```bash
sudo systemctl stop dooja
sudo cp /var/lib/dooja/dooja.db /var/backups/dooja/dooja-$(date +%Y%m%d%H%M%S).db
sudo systemctl start dooja
```

الرجوع عن نسخة التطبيق، بدون لمس قاعدة البيانات:

```bash
bash rollback.sh
```

يعيد أحدث أرشيف من `/var/backups/dooja/dooja-*.tar.gz` ثم يعيد تشغيل الخدمة.

## المراقبة والأعطال

```bash
systemctl status dooja --no-pager
journalctl -u dooja -n 100 --no-pager
curl -fsS http://127.0.0.1:5080/health
sudo nginx -t
```

`/health` يرجع 200 و`database: up` إذا الملف قابل للفتح. `sms` يبقى `missing` وهذا متعمد.

إذا الخدمة ما تقوم: غالباً `Jwt__Key` أقصر من 32 بايت، أو `Admin__Password` فاضي، أو صلاحية `/var/lib/dooja` ليست للمستخدم `dooja`.

## التكلفة الشهرية

ضمن حدود Always Free: الآلة، القرص 50 GB، والعنوان العام، و10 TB صادرة شهرياً تكون 0. تجاوز الحصة أو اختيار شكل غير مجاني أو قاعدة Oracle مدارة يصبح مدفوعاً. لا تنشئ هذه الموارد بدون موافقة.

## تقرير التحقق

| الفحص | النتيجة |
|---|---|
| حساب OCI مسجّل الدخول | فشل. الصفحة تطلب Cloud Account Name |
| أداة `oci` على الجهاز | غير موجودة |
| إنشاء الآلة والشبكة | لم يبدأ |
| الخدمة تعمل | لم يُتحقق |
| `/health` من خارج السيرفر | لم يُتحقق |
| HTTPS | لا نطاق ولا شهادة |
| قاعدة البيانات من OCI | لا سيرفر |
| الدخول والصلاحيات | لم تُفحص على OCI |
| CORS مع الواجهة المنشورة | الواجهة ما زالت على `dooja.cloudapps.trade` |
| السجلات وإعادة الإقلاع | لم تُفحص |

النشر لا يُعتبر ناجحاً. الخطوة التالية: سجّل الدخول لحساب Oracle Cloud، ثم وافق على الآلة المجانية وفتح المنافذ.