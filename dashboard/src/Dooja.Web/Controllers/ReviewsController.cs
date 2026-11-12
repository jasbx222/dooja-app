using Dooja.Web.Data;
using Dooja.Web.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
namespace Dooja.Web.Controllers;
public class ReviewsController(DoojaDb db) : DashboardControllerBase
{
    public async Task<IActionResult> Index(string? q, int? page, int? size)
    {
        if (Paging.Reject(page, size) is { } bad) return bad;
        var (p, s) = Paging.Normalize(page, size);
        ViewData["Q"] = q;
        var query = db.Reviews.AsNoTracking().Include(x => x.Place).AsQueryable();
        if (!string.IsNullOrWhiteSpace(q)) query = query.Where(x => x.Name.Contains(q) || x.Text.Contains(q) || x.Place!.Name.Contains(q));
        var total = await query.CountAsync();
        ViewData["Average"] = total == 0 ? null : await query.AverageAsync(x => (double)x.Stars);
        var bar = PageBar.Create(p, s, total);
        var items = await query.OrderByDescending(x => x.Id).Skip((bar.Page - 1) * s).Take(s).ToListAsync();
        return View(new PagedList<Review> { Items = items, Page = bar });
    }
    [HttpPost] public async Task<IActionResult> Reply(int id, string text) { var r = await db.Reviews.FindAsync(id); if (r == null) return NotFound(); if (string.IsNullOrWhiteSpace(text) || text.Length > 2000) { TempData["Error"] = "اكتب رداً بين 1 و2000 حرف"; return RedirectToAction(nameof(Index)); } r.Reply = text; await db.SaveChangesAsync(); if (r.UserId.HasValue) { db.Notifications.Add(new() { UserId = r.UserId.Value, Title = "رد على تقييمك", Body = text }); await db.SaveChangesAsync(); } TempData["Success"] = "تم إرسال الرد"; return RedirectToAction(nameof(Index)); }
}
