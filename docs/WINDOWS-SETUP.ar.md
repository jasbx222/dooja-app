# ضوجة — تشغيل الداشبورد على ويندوز + Cloudflare Tunnel + PostgreSQL

الدومين: **https://dooja.cloudapps.trade**  
الجهاز: `DESKTOP-U6B65GL`  
المنفذ المحلي: **5080** (لازم يطابق إعداد النفق)

> لا تحط كلمات سر أو توكنات داخل هالملف. كل سيكريت يضل بمتغير بيئة أو ملف محلي عندك فقط.

---

## 1) تنصيب PostgreSQL 16

افتح PowerShell كـ Administrator:

```powershell
winget install --id PostgreSQL.PostgreSQL.16 -e --accept-package-agreements --accept-source-agreements
```

بعد التنصيب، تأكد خدمة Postgres شغالة، وافتح `SQL Shell (psql)` أو:

```powershell
& "C:\Program Files\PostgreSQL\16\bin\psql.exe" -U postgres
```

داخل psql (بدّل `<كلمة_سرك>` بكلمة سر قوية تختارها أنت):

```sql
CREATE USER dooja WITH PASSWORD '<كلمة_سرك>';
CREATE DATABASE dooja OWNER dooja;
GRANT ALL PRIVILEGES ON DATABASE dooja TO dooja;
\q
```

---

## 2) متغيرات البيئة (مرة وحدة)

PowerShell **عادي** (مو لازم Admin). بدّل كلمة السر فقط:

```powershell
setx ConnectionStrings__Default "Host=localhost;Port=5432;Database=dooja;Username=dooja;Password=<كلمة_سرك>"
setx Database__Provider "Postgres"
setx ASPNETCORE_ENVIRONMENT "Production"
setx AllowedHosts "dooja.cloudapps.trade;localhost;127.0.0.1"
```

سيكريتات الإنتاج (إلزامية قبل أول تشغيل Production — لا تستخدم قيم التطوير):

```powershell
setx Jwt__Key "<مفتاح_عشوائي_طويل_32_بايت_او_اكثر>"
setx Admin__Password "<كلمة_سر_ادمن_قوية>"
setx Seed__Demo "false"
```

اختياري لتطبيق Flutter (أصول CORS):

```powershell
setx Cors__Origins__0 "https://dooja.cloudapps.trade"
```

> بعد `setx` سكّر PowerShell وافتح نافذة جديدة حتى تتشاف المتغيرات.

توليد مفتاح JWT سريع:

```powershell
[Convert]::ToBase64String((1..48 | ForEach-Object { Get-Random -Maximum 256 }) -as [byte[]])
```

---

## 3) سحب المشروع وتطبيق باتش Postgres

إذا الريبو مرفوع على GitHub:

```powershell
cd $HOME
git clone https://github.com/jasbx222/dooja-app.git
cd dooja-app
# الداشبورد داخل المجلد dashboard/
cd dashboard
```

إذا وصلك أرشيف/مجلد بدل الريبو، انسخه لمكان ثابت ودخل عليه.

طبّق باتش Postgres (من نسخة `dooja-deploy` اللي عند الوكيل، أو انسخ الملفات يدوياً):

```powershell
# إذا عندك apply_postgres_patch.py
python apply_postgres_patch.py .
# أو: git apply postgres.patch
```

الباتش يسوي:
- يضيف حزمة `Npgsql.EntityFrameworkCore.PostgreSQL`
- يبدّل المزود: إذا `Database:Provider=Postgres` يستخدم `UseNpgsql(ConnectionStrings:Default)`، غير هيج يبقى SQLite
- المشروع حالياً يستخدم `EnsureCreatedAsync` (ماكو مجلد Migrations). هالشي يشتغل مع Postgres؛ للمستقبل الأفضل تولّد EF migrations وتوقف EnsureCreated على قاعدة الإنتاج

---

## 4) بناء وتشغيل الداشبورد

.NET 10 SDK موجود عندك؛ المشروع يستهدف `net8.0` (الـ SDK الأحدث يشغّله عادةً). إذا احتجت SDK 8:

```powershell
winget install Microsoft.DotNet.SDK.8 -e
```

```powershell
cd $HOME\dooja-dashboard
dotnet restore
dotnet tool install --global dotnet-ef
dotnet build -c Release --project src\Dooja.Web\Dooja.Web.csproj
```

لأن المشروع يعتمد `EnsureCreated` مو migrations جاهزة لـ Postgres، **ما تحتاج** `dotnet ef database update` لأول تشغيل — التطبيق ينشئ الجداول وحده. إذا بعدين ضفت Migrations:

```powershell
dotnet ef database update --project src\Dooja.Web\Dooja.Web.csproj
```

شغّل التطبيق (لازم المنفذ 5080):

```powershell
dotnet run --project src\Dooja.Web\Dooja.Web.csproj --no-launch-profile --urls http://127.0.0.1:5080
```

تأكد محلياً:

```powershell
curl http://127.0.0.1:5080/
```

سجّل دخول الأدمن بكلمة السر اللي حطيتها بـ `Admin__Password` (رقم الهاتف الافتراضي للأدمن الأولي: `07700000000` إذا انخلق من Seed بدون بيانات سابقة). **لا تستخدم كلمة سر التطوير على الإنتاج.**

---

## 5) تنصيب cloudflared وربطه بالنفق

```powershell
winget install --id Cloudflare.cloudflared -e --accept-package-agreements --accept-source-agreements
```

خذ التوكن من الملف الآمن `dooja-tunnel.env` (سطر `CLOUDFLARED_TOKEN=...`) — لا تلصقه بالشات ولا ترفعه على GitHub.

PowerShell كـ Administrator:

```powershell
# اقرأ التوكن من الملف المحلي عندك (مثال)
$envFile = "C:\Users\Acer 5\dooja-tunnel.env"
$token = (Get-Content $envFile | Where-Object { $_ -like "CLOUDFLARED_TOKEN=*" }) -replace "^CLOUDFLARED_TOKEN=",""
cloudflared service install $token
Start-Service cloudflared
Get-Service cloudflared
```

النفق مضبوط أصلاً على Cloudflare:
- الاسم: `dooja`
- `dooja.cloudapps.trade` → `http://localhost:5080`
- CNAME بروكسي: `dooja` → `<tunnel-id>.cfargotunnel.com`

---

## 6) التحقق من الدومين

1. الداشبورد شغّال على `127.0.0.1:5080`
2. خدمة `cloudflared` Running
3. افتح: **https://dooja.cloudapps.trade**

```powershell
curl -I https://dooja.cloudapps.trade
```

---

## 7) استكشاف الأخطاء

| العرض | السبب الأقرب | الحل |
|---|---|---|
| 502 / Bad gateway | التطبيق مو شغّال أو بورت غلط | شغّل `dotnet run ... --urls http://127.0.0.1:5080` |
| 1033 / Tunnel error | cloudflared مو متصل | `Get-Service cloudflared` ثم أعد التشغيل؛ تأكد التوكن صح |
| 403 / Host not allowed | `AllowedHosts` مقيّد | أضف `dooja.cloudapps.trade` كما فوق وافتح PowerShell جديد |
| خطأ اتصال قاعدة البيانات | Postgres واقف أو كلمة سر غلط | تأكد الخدمة، وجرّب `psql -U dooja -d dooja -h localhost` |
| Jwt / Admin password exception | نسيت سيكريتات Production | عيّن `Jwt__Key` و `Admin__Password` قبل أول تشغيل |
| Redirect غريب / حلقة | HTTPS redirection خلف النفق | التطبيق يستمع HTTP فقط؛ Cloudflare يتكفّل بالـ TLS. خلّي `--urls http://127.0.0.1:5080` |

---

## ملاحظات أمان

- لا تنشر `dooja-tunnel.env` ولا connection string ولا `Jwt__Key` ولا `Admin__Password` بالشات أو بالريبو.
- `Seed:Demo` لازم `false` بالإنتاج.
- حسابات وأرقام التطوير للتجربة المحلية فقط — مو للإنتاج العام.

## تطبيق الآيفون (PWA) — جاهز على /app

بعد ما `Dooja.Web` والتانل شغّالين:

1. افتح على الآيفون بـ Safari: **https://dooja.cloudapps.trade/app/**
2. مشاركة → إضافة إلى الشاشة الرئيسية.
3. لوحة التحكم MVC تبقى على `/` و`/Auth/Login`. الـ API على `/api/*`.

تفاصيل IPA / TestFlight: [`IOS-TESTFLIGHT.ar.md`](IOS-TESTFLIGHT.ar.md)

لنشر نسخة Flutter web محدّثة إلى `wwwroot/app`:

```bash
# من جذر المستودع (Linux/Mac أو Git Bash)
./dashboard/scripts/publish-flutter-web.sh
# ثم أعد تشغيل Dooja.Web
```

