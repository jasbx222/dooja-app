using Dooja.Web.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
namespace Dooja.Web.Controllers;
public class ReviewsController(DoojaDb db) : DashboardControllerBase
{
    public async Task<IActionResult> Index() => View(await db.Reviews.AsNoTracking().Include(x => x.Place).OrderByDescending(x => x.Id).Take(300).ToListAsync());
    [HttpPost] public async Task<IActionResult> Reply(int id, string text) { var r = await db.Reviews.FindAsync(id); if (r == null) return NotFound(); if (string.IsNullOrWhiteSpace(text) || text.Length > 2000) { TempData["Error"] = "اكتب رداً بين 1 و2000 حرف"; return RedirectToAction(nameof(Index)); } r.Reply = text; await db.SaveChangesAsync(); if (r.UserId.HasValue) { db.Notifications.Add(new() { UserId = r.UserId.Value, Title = "رد على تقييمك", Body = text }); await db.SaveChangesAsync(); } TempData["Success"] = "تم إرسال الرد"; return RedirectToAction(nameof(Index)); }
}
