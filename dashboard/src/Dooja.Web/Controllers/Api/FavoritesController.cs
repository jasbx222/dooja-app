using Dooja.Web.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
namespace Dooja.Web.Controllers.Api;
[Route("api/favorites")]
public class FavoritesController(DoojaDb db) : ApiBase(db)
{
    [HttpGet] public async Task<IActionResult> Mine() => Ok(await Db.Favorites.Where(x => x.UserId == UserId).Select(x => x.Place).ToListAsync());
    [HttpPost("{placeId}/toggle")] public async Task<IActionResult> Toggle(string placeId) { if (!await Db.Places.AnyAsync(x => x.Id == placeId && x.Active)) return NotFound(); var f = await Db.Favorites.FindAsync(UserId, placeId); if (f == null) Db.Favorites.Add(new() { UserId = UserId, PlaceId = placeId }); else Db.Favorites.Remove(f); await Db.SaveChangesAsync(); return Ok(new { saved = f == null }); }
}
