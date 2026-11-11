using Dooja.Web.Models;
using Microsoft.EntityFrameworkCore;

namespace Dooja.Web.Data;

public static class ShopCatalogSeed
{
    public static async Task Ensure(DoojaDb db)
    {
        if (await db.Products.AnyAsync()) return;
        var categories = new (string Name, string Image, int Sort)[]
        {
            ("ألعاب فيديو", "/img/gaming.jpg", 1),
            ("إكسسوارات الألعاب", "/img/dice.png", 2),
            ("أذرع التحكم", "/img/gaming.jpg", 3),
            ("سماعات", "/img/reel.jpg", 4),
            ("ألعاب جماعية", "/img/friends.jpg", 5),
            ("هدايا", "/img/friends.jpg", 6)
        };
        var saved = new Dictionary<string, ProductCategory>();
        foreach (var category in categories)
        {
            var row = new ProductCategory { Name = category.Name, ImagePath = category.Image, SortOrder = category.Sort, Active = true };
            db.ProductCategories.Add(row);
            saved[category.Name] = row;
        }
        await db.SaveChangesAsync();

        Product Add(string category, string name, string description, string specs, long price, long? compare, int stock, bool featured, params string[] images)
        {
            var product = new Product
            {
                CategoryId = saved[category].Id,
                Name = name,
                Description = description,
                Specs = specs,
                Price = price,
                CompareAtPrice = compare,
                Stock = stock,
                Active = true,
                Featured = featured,
                Images = images.Select((path, index) => new ProductImage { Path = path, SortOrder = index }).ToList()
            };
            db.Products.Add(product);
            return product;
        }

        Add("ألعاب فيديو", "فيفا 26 — بلايستيشن 5",
            "نسخة عربية كاملة من فيفا 26 لجهاز بلايستيشن 5. تشمل دوري نجوم العراق والأندية الأوروبية، مع تعليق عربي وتحديثات الموسم الأول.",
            "المنصة: بلايستيشن 5\nاللغة: العربية والإنجليزية\nاللاعبون: 1–4 محلي، أونلاين حتى 22\nالمساحة: 55 غيغابايت\nالتصنيف العمري: 3+",
            65000, 75000, 18, true, "/img/gaming.jpg", "/img/dice.png");
        Add("ألعاب فيديو", "غود أوف وور راغناروك",
            "مغامرة كريتوس وأتريوس الكاملة على بلايستيشن 5. قصة طويلة، عالم مفتوح، ووضع التصوير للقطات.",
            "المنصة: بلايستيشن 5\nاللغة: إنجليزية مع ترجمة عربية\nاللاعبون: لاعب واحد\nالمساحة: 98 غيغابايت\nيشمل: القرص والنسخة الرقمية داخل الحساب بعد التفعيل",
            55000, null, 9, false, "/img/gaming.jpg");
        Add("ألعاب فيديو", "إي إيه إف سي 26 — إكس بوكس",
            "نسخة إكس بوكس سيريس لجهاز Series X. تدعم اللعب المشترك مع الجيل الحالي وتحديثات الفرق حتى نهاية الموسم.",
            "المنصة: Xbox Series X|S\nاللغة: العربية والإنجليزية\nاللاعبون: 1–4\nالمساحة: 50 غيغابايت\nيتطلب: اتصال لتفعيل التحديث الأول",
            64000, 72000, 14, false, "/img/gaming.jpg");

        Add("إكسسوارات الألعاب", "قاعدة شحن مزدوجة لذراع DualSense",
            "تشحن ذراعين في الوقت نفسه وتعرض مستوى البطارية. القاعدة ثابتة على المكتب وتأتي مع كابل USB-C.",
            "التوافق: DualSense\nالمداخل: USB-C\nالشحن: ذراعان معاً\nالطول: 22 سم\nالضمان: 6 أشهر",
            22000, 28000, 30, false, "/img/dice.png");
        Add("إكسسوارات الألعاب", "كابل HDMI 2.1 بطول مترين",
            "كابل معتمد لدقّة 4K بمعدل 120 إطار. مناسب للبلايستيشن 5 والإكس بوكس وسيريس.",
            "المعيار: HDMI 2.1\nالطول: 2 متر\nالدقة: حتى 8K\nالتغليف: مضفر ضد العقد\nالضمان: استبدال خلال 30 يوماً",
            12000, null, 40, false, "/img/dice.png");
        Add("إكسسوارات الألعاب", "حامل رأس للسماعة",
            "حامل معدني يثبت تحت الشاشة أو على حافة الطاولة. يحمي وسائد السماعة من الانضغاط.",
            "الخامة: ألمنيوم\nالتحمل: حتى 1 كغم\nالتركيب: مشبك بدون براغي\nاللون: أسود\nالأبعاد: 28 × 11 سم",
            18000, 24000, 15, false, "/img/dice.png", "/img/gaming.jpg");

        Add("أذرع التحكم", "ذراع DualSense أبيض",
            "ذراع بلايستيشن 5 الرسمي باللون الأبيض. اهتزاز لمسي، زناد متكيّف، وبطارية داخلية.",
            "التوافق: PS5 وويندوز\nالاتصال: لاسلكي وUSB-C\nالبطارية: حتى 12 ساعة\nاللون: أبيض\nالضمان: سنة",
            78000, 89000, 12, true, "/img/gaming.jpg", "/img/dice.png");
        Add("أذرع التحكم", "ذراع إكس بوكس اللاسلكي أسود",
            "ذراع Xbox Wireless الرسمي. يعمل مع Series X وويندوز 10 و11 عبر البلوتوث أو المحوّل.",
            "التوافق: Xbox Series وويندوز\nالاتصال: Xbox Wireless وبلوتوث\nالبطارية: بطاريات AA\nاللون: أسود\nالضمان: سنة",
            72000, 85000, 10, true, "/img/gaming.jpg");
        Add("أذرع التحكم", "ذراع سلكي احترافي للكمبيوتر",
            "ذراع سلكي بأزرار خلفية وقبضة مطاطية. مناسب للألعاب التنافسية بدون تأخير لاسلكي.",
            "التوافق: ويندوز 10 و11\nالكابل: 2 متر مضفر\nالأزرار الخلفية: 2\nالتردد: سلكي فقط\nالضمان: 6 أشهر",
            35000, null, 20, false, "/img/gaming.jpg");

        Add("سماعات", "سماعة بالس 3D",
            "سماعة بلايستيشن الرسمية بصوت ثلاثي الأبعاد. ميكروفون قابل للطي وعصابة خفيفة للجلسات الطويلة.",
            "التوافق: PS5 وPS4 وويندوز\nالصوت: Tempest 3D على PS5\nالميكروفون: مخفي قابل للطي\nالاتصال: لاسلكي دونغل USB\nالوزن: 292 غرام",
            95000, 110000, 8, true, "/img/reel.jpg", "/img/gaming.jpg");
        Add("سماعات", "سماعة هايبر إكس كلاود",
            "سماعة مغلقة بذاكرة إسفنجية. صوت واضح للخطوات والمايك منفصل.",
            "التوافق: PS وXbox وPC وموبايل\nالممانعة: 64 أوم\nالميكروفون: قابل للفصل\nالكابل: 1.3 متر + وصلة 3.5 مم\nالوزن: 309 غرام",
            68000, 79000, 11, false, "/img/reel.jpg");
        Add("سماعات", "سماعة أذن للموبايل والألعاب",
            "سماعة داخل الأذن بمايكروفون، للعب الجماعي من الهاتف. عزل خفيف وأطراف بثلاثة مقاسات.",
            "المدخل: 3.5 مم\nالمايك: مدمج مع زر الرد\nالطول: 1.2 متر\nالمقاسات: S وM وL\nاللون: أسود",
            18000, 25000, 25, false, "/img/reel.jpg");

        Add("ألعاب جماعية", "بلايستيشن بلس — شهر",
            "بطاقة اشتراك شهر واحد للألعاب الجماعية والأونلاين. تُفعَّل على حساب بلايستيشن عراقي أو عالمي حسب المنطقة المطبوعة.",
            "المدة: 30 يوماً\nالمنصة: PS4 وPS5\nيشمل: اللعب الجماعي والألعاب الشهرية للمستوى الأساسي\nالتسليم: كود يظهر بعد تأكيد الطلب\nملاحظة: الكود لا يُسترجع بعد إظهاره",
            15000, null, 50, false, "/img/friends.jpg");
        Add("ألعاب جماعية", "إت تيكس تو",
            "لعبة تعاونية لشخصين على نفس الشاشة أو أونلاين. قصة كاملة يمكن لعبها مع صديق من البداية للنهاية.",
            "المنصة: بلايستيشن 5\nاللاعبون: 2\nاللغة: إنجليزية\nالمساحة: 45 غيغابايت\nنمط اللعب: محلي وأونلاين",
            42000, 52000, 7, true, "/img/friends.jpg", "/img/gaming.jpg");
        Add("ألعاب جماعية", "ماريو كارت 8 ديلوكس",
            "سباقات جماعية حتى 4 لاعبين على شاشة واحدة، مع كل الحلبات الإضافية.",
            "المنصة: نينتندو سويتش\nاللاعبون: 1–4 محلي، حتى 8 أونلاين\nاللغة: إنجليزية\nالمساحة: 7 غيغابايت\nيشمل: القرص",
            58000, null, 6, false, "/img/friends.jpg");

        Add("هدايا", "بطاقة هدايا بلايستيشن 50 ألف دينار",
            "بطاقة رصيد للمتجر. تُسلَّم كوداً داخل الطلب بعد الدفع عند الاستلام والتأكيد.",
            "القيمة: 50,000 دينار عراقي\nالمنصة: حساب PlayStation\nالصلاحية: تُطبع على البطاقة\nالتسليم: كود داخل تفاصيل الطلب\nالاسترجاع: قبل إظهار الكود فقط",
            50000, null, 20, true, "/img/friends.jpg");
        Add("هدايا", "صندوق هدية اللاعب",
            "صندوق جاهز للتغليف: سماعة أذن، قبضة إضافية للموبايل، وبطاقة معايدة. مناسب كهدية بدون ما تختار كل قطعة وحدها.",
            "المحتويات: سماعة 3.5 مم + قبضة موبايل + بطاقة\nالتغليف: صندوق مغلق\nالمناسبة: عيد ميلاد أو نجاح\nالمخزون: يُجهَّز في نفس اليوم داخل بغداد\nالوزن التقريبي: 450 غرام",
            120000, 145000, 4, true, "/img/friends.jpg", "/img/dice.png");
        Add("هدايا", "مجسم ذراع تحكم للديكور",
            "مجسم صغير لذراع تحكم يوضع على الرف. ليس ذراعاً حقيقياً ولا يتصل بالأجهزة.",
            "الخامة: راتنج\nالارتفاع: 12 سم\nالاستخدام: ديكور فقط\nاللون: أبيض وأسود\nالتغليف: علبة كرتون",
            15000, 20000, 16, false, "/img/dice.png");

        var settings = await db.StoreSettings.FirstAsync(x => x.Id == 1);
        if (settings.DeliveryFee == 0) settings.DeliveryFee = 5000;
        if (!await db.DeliveryAreas.AnyAsync())
        {
            db.DeliveryAreas.AddRange(
                new DeliveryArea { Governorate = "بغداد", Area = "المنصور", Fee = 4000, Active = true },
                new DeliveryArea { Governorate = "بغداد", Area = "الكرادة", Fee = 5000, Active = true },
                new DeliveryArea { Governorate = "بغداد", Area = "زيونة", Fee = 5000, Active = true },
                new DeliveryArea { Governorate = "بغداد", Area = "الجادرية", Fee = 6000, Active = true },
                new DeliveryArea { Governorate = "بغداد", Area = "الأعظمية", Fee = 6000, Active = true },
                new DeliveryArea { Governorate = "بغداد", Area = "الشعب", Fee = 7000, Active = true }
            );
        }
        await db.SaveChangesAsync();
    }
}
