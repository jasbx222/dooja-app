using Dooja.Web.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
namespace Dooja.Web.Controllers.Api;
[Route("api/places")]
public class PlacesController(DoojaDb db) : ApiBase(db)
{
    [HttpGet, AllowAnonymous] public async Task<IActionResult> List(string? category, string? q, int page = 1, int pageSize = 50) { var query = Db.Places.AsNoTracking().Where(x => x.Active); if (!string.IsNullOrWhiteSpace(category)) query = query.Where(x => x.Category == category); if (!string.IsNullOrWhiteSpace(q)) query = query.Where(x => x.Name.Contains(q) || x.Area.Contains(q)); return Ok(await query.OrderByDescending(x => x.Featured).ThenBy(x => x.Id).Skip((Math.Clamp(page, 1, 10000) - 1) * Math.Clamp(pageSize, 1, 100)).Take(Math.Clamp(pageSize, 1, 100)).ToListAsync()); }
    [HttpGet("{id}"), AllowAnonymous] public async Task<IActionResult> Detail(string id) { var p = await Db.Places.AsNoTracking().FirstOrDefaultAsync(x => x.Id == id && x.Active); return p == null ? NotFound() : Ok(p); }
    [HttpGet("{id}/services"), AllowAnonymous] public async Task<IActionResult> Services(string id) => Ok(await Db.OwnerServices.AsNoTracking().Where(x => x.PlaceId == id).ToListAsync());
    [HttpGet("{id}/availability"), AllowAnonymous] public async Task<IActionResult> Availability(string id, DateOnly day) { if (!await Db.Places.AnyAsync(x => x.Id == id && x.Active)) return NotFound(); return Ok(new { closed = await Db.ClosedSlots.Where(x => x.PlaceId == id && x.Day == day).Select(x => x.Time).ToListAsync(), booked = await Db.Bookings.Where(x => x.PlaceId == id && x.Day == day && (x.Status == "مؤكد" || x.Status == "بانتظار القبول")).Select(x => new { x.Time, x.Hours }).ToListAsync() }); }
    [HttpPost("{id}/follow")] public async Task<IActionResult> Follow(string id) { var p = await Db.Places.FindAsync(id); if (p == null) return NotFound(); var f = await Db.Follows.FindAsync(UserId, id); if (f == null) { Db.Follows.Add(new() { UserId = UserId, PlaceId = id }); p.Followers++; } else { Db.Follows.Remove(f); p.Followers = Math.Max(0, p.Followers - 1); } await Db.SaveChangesAsync(); return Ok(new { following = f == null, followers = p.Followers }); }
    [HttpGet("following")] public async Task<IActionResult> Following() => Ok(await Db.Follows.Where(x => x.UserId == UserId).Select(x => x.Place).ToListAsync());
}
