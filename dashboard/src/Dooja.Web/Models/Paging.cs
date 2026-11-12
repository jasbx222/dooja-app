using Microsoft.AspNetCore.Mvc;

namespace Dooja.Web.Models;

public static class Paging
{
    public const int DefaultSize = 20;
    public const int MaxSize = 50;

    public static IActionResult? Reject(int? page, int? size)
    {
        if (page is < 1) return new BadRequestObjectResult("رقم الصفحة غير صالح");
        if (size is < 1 or > MaxSize) return new BadRequestObjectResult("حجم الصفحة يجب أن يكون بين 1 و 50");
        return null;
    }

    public static (int Page, int Size) Normalize(int? page, int? size) => (page ?? 1, size ?? DefaultSize);
}
