using Dooja.Web.Data;
using Dooja.Web.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Dooja.Web.Controllers;

/// Serves images uploaded from the dashboard (stored in the database).
[AllowAnonymous]
public class MediaController(DoojaDb db) : Controller
{
    [HttpGet("/media/{name}")]
    public async Task<IActionResult> Get(string name)
    {
        if (ImageStore.TryId("/media/" + name) is not { } id) return NotFound();
        var file = await db.StoredFiles.AsNoTracking().FirstOrDefaultAsync(x => x.Id == id);
        if (file == null) return NotFound();
        // The id never changes for the same bytes, so browsers and the app may cache it for good.
        Response.Headers.CacheControl = "public, max-age=31536000, immutable";
        Response.Headers["X-Content-Type-Options"] = "nosniff";
        return File(file.Data, file.ContentType);
    }
}
