using Dooja.Web.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
namespace Dooja.Web.Controllers.Api;
[Route("api/notifications")]
public class NotificationsController(DoojaDb db) : ApiBase(db)
{
    [HttpGet] public async Task<IActionResult> Mine() => Ok(await Db.Notifications.AsNoTracking().Where(x => x.UserId == UserId).OrderByDescending(x => x.Id).Take(100).ToListAsync());
    [HttpPost("{id:int}/read")] public async Task<IActionResult> Read(int id) { var n = await Db.Notifications.FirstOrDefaultAsync(x => x.Id == id && x.UserId == UserId); if (n == null) return NotFound(); n.Fresh = false; await Db.SaveChangesAsync(); return Ok(n); }
    [HttpPost("read-all")] public async Task<IActionResult> ReadAll() { await Db.Notifications.Where(x => x.UserId == UserId).ExecuteUpdateAsync(s => s.SetProperty(x => x.Fresh, false)); return Ok(new { success = true }); }
}
