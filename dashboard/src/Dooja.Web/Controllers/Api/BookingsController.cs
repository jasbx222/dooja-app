using System.ComponentModel.DataAnnotations;
using Dooja.Web.Data;
using Dooja.Web.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
namespace Dooja.Web.Controllers.Api;
[Route("api/bookings")]
public class BookingsController(DoojaDb db, BookingService service) : ApiBase(db)
{
    public record CreateBooking([Required] string PlaceId, DateOnly Day, [Required] string Time, [Range(1, 12)] int Hours, [Range(1, 100)] int People, [Required] string PayMethod, bool Wait = false, string? OfferId = null);
    [HttpGet] public async Task<IActionResult> Mine() => Ok(await Db.Bookings.AsNoTracking().Include(x => x.Place).Where(x => x.UserId == UserId).OrderByDescending(x => x.Id).Take(200).ToListAsync());
    [HttpPost] public async Task<IActionResult> Create(CreateBooking input) { var (b, error) = await service.Create(UserId, input.PlaceId, input.Day, input.Time, input.Hours, input.People, input.PayMethod, input.Wait, input.OfferId); return error != null ? BadRequest(new { error }) : Created($"/api/bookings/{b!.Id}", b); }
    [HttpGet("{id:int}")] public async Task<IActionResult> Detail(int id) { var b = await Db.Bookings.AsNoTracking().Include(x => x.Place).FirstOrDefaultAsync(x => x.Id == id && x.UserId == UserId); return b == null ? NotFound() : Ok(b); }
    [HttpPost("{id:int}/cancel")] public async Task<IActionResult> Cancel(int id) { var b = await Db.Bookings.FirstOrDefaultAsync(x => x.Id == id && x.UserId == UserId); if (b == null) return NotFound(); var error = await service.SetStatus(b, "ملغي"); return error == null ? Ok(b) : BadRequest(new { error }); }
}
