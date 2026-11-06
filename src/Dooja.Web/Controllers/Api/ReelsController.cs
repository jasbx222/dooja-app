using System.ComponentModel.DataAnnotations;
using Dooja.Web.Data;
using Dooja.Web.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
namespace Dooja.Web.Controllers.Api;
[Route("api/reels")]
public class ReelsController(DoojaDb db) : ApiBase(db)
{
    [HttpGet, AllowAnonymous] public async Task<IActionResult> List() => Ok(await Db.Reels.AsNoTracking().Include(x => x.Place).OrderByDescending(x => x.Id).Take(100).ToListAsync());
    [HttpGet("{id:int}/comments"), AllowAnonymous] public async Task<IActionResult> Comments(int id) => Ok(await Db.ReelComments.Where(x => x.ReelId == id).OrderByDescending(x => x.Id).Take(100).ToListAsync());
    public record CommentRequest([Required, StringLength(2000)] string Text);
    [HttpPost("{id:int}/comments")] public async Task<IActionResult> Comment(int id, CommentRequest input) { if (!await Db.Reels.AnyAsync(x => x.Id == id)) return NotFound(); var u = (await Db.Users.FindAsync(UserId))!; var c = new ReelComment { ReelId = id, UserId = UserId, Name = u.Name, Text = input.Text }; Db.ReelComments.Add(c); await Db.SaveChangesAsync(); return Ok(c); }
    [HttpPost("{id:int}/like")] public async Task<IActionResult> Like(int id) { var r = await Db.Reels.FindAsync(id); if (r == null) return NotFound(); var l = await Db.ReelLikes.FindAsync(UserId, id); if (l == null) { Db.ReelLikes.Add(new() { UserId = UserId, ReelId = id }); r.Likes++; } else { Db.ReelLikes.Remove(l); r.Likes = Math.Max(0, r.Likes - 1); } await Db.SaveChangesAsync(); return Ok(new { liked = l == null, likes = r.Likes }); }
    public record CreateReel([Required] string PlaceId, [Required, StringLength(2000)] string Caption, [StringLength(100)] string ImageKey, [StringLength(200)] string OfferText);
    [HttpPost, Authorize(Roles = "Owner,Admin")] public async Task<IActionResult> Create(CreateReel input) { if (!await Owns(input.PlaceId)) return Forbid(); var r = new Reel { PlaceId = input.PlaceId, Caption = input.Caption, ImageKey = input.ImageKey, OfferText = input.OfferText }; Db.Reels.Add(r); await Db.SaveChangesAsync(); return Ok(r); }
}
