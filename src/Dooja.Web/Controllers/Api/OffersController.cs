using Dooja.Web.Data;
using Dooja.Web.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
namespace Dooja.Web.Controllers.Api;
[Route("api/offers")]
public class OffersController(DoojaDb db) : ApiBase(db)
{
    [HttpGet, AllowAnonymous] public async Task<IActionResult> List(string? category, string? placeId) { var today = BookingService.Today; var q = Db.Offers.AsNoTracking().Include(x => x.Place).Where(x => x.Active && x.Place!.Active && (!x.ExpiresOn.HasValue || x.ExpiresOn >= today)); if (category != null) q = q.Where(x => x.Category == category); if (placeId != null) q = q.Where(x => x.PlaceId == placeId); return Ok(await q.Take(100).ToListAsync()); }
    [HttpGet("{id}"), AllowAnonymous] public async Task<IActionResult> Detail(string id) { var o = await Db.Offers.Include(x => x.Place).FirstOrDefaultAsync(x => x.Id == id && x.Active && x.Place!.Active && (!x.ExpiresOn.HasValue || x.ExpiresOn >= BookingService.Today)); if (o == null) return NotFound(); await Db.Offers.Where(x => x.Id == id).ExecuteUpdateAsync(s => s.SetProperty(x => x.Views, x => x.Views + 1)); o.Views++; return Ok(o); }
    [HttpPost("{id}/click")] public async Task<IActionResult> Click(string id) { var changed = await Db.Offers.Where(x => x.Id == id && x.Active).ExecuteUpdateAsync(s => s.SetProperty(x => x.Clicks, x => x.Clicks + 1)); return changed == 0 ? NotFound() : Ok(new { success = true }); }
}
