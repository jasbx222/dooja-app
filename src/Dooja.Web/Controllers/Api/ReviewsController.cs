using System.ComponentModel.DataAnnotations;
using Dooja.Web.Data;
using Dooja.Web.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
namespace Dooja.Web.Controllers.Api;
[Route("api/reviews")]
public class ReviewsController(DoojaDb db) : ApiBase(db)
{
    [HttpGet, AllowAnonymous] public async Task<IActionResult> List([Required] string placeId) => Ok(await Db.Reviews.AsNoTracking().Where(x => x.PlaceId == placeId).OrderByDescending(x => x.Id).Take(100).ToListAsync());
    public record CreateReview([Required] string PlaceId, [Range(1, 5)] int Stars, [Required, StringLength(2000)] string Text, int BookingId);
    [HttpPost]
    public async Task<IActionResult> Create(CreateReview input)
    {
        await using var tx = await Db.Database.BeginTransactionAsync();
        var b = await Db.Bookings.FirstOrDefaultAsync(x => x.Id == input.BookingId && x.UserId == UserId && x.PlaceId == input.PlaceId && x.Status == "مكتمل" && !x.Rated);
        if (b == null) return BadRequest(new { error = "يمكن تقييم حجز مكتمل غير مقيّم فقط" });
        var u = (await Db.Users.FindAsync(UserId))!; var r = new Review { UserId = UserId, BookingId = b.Id, Name = u.Name, PlaceId = input.PlaceId, Stars = input.Stars, Text = input.Text }; b.Rated = true; u.Points += 20; Db.Reviews.Add(r); await Db.SaveChangesAsync();
        var p = (await Db.Places.FindAsync(input.PlaceId))!; p.Rating = Math.Round(await Db.Reviews.Where(x => x.PlaceId == p.Id).AverageAsync(x => (double)x.Stars), 1); p.ReviewCount = await Db.Reviews.CountAsync(x => x.PlaceId == p.Id); await Db.SaveChangesAsync(); await tx.CommitAsync(); return Ok(r);
    }
    public record ReplyRequest([Required, StringLength(2000)] string Text);
    [HttpPost("{id:int}/reply")] public async Task<IActionResult> Reply(int id, ReplyRequest input) { var r = await Db.Reviews.FindAsync(id); if (r == null) return NotFound(); if (!await Owns(r.PlaceId)) return Forbid(); r.Reply = input.Text; await Db.SaveChangesAsync(); return Ok(r); }
}
