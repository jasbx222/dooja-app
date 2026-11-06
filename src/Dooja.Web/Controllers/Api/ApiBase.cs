using System.Security.Claims;
using Dooja.Web.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.EntityFrameworkCore;
namespace Dooja.Web.Controllers.Api;
[ApiController, Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme)]
public abstract class ApiBase(DoojaDb db) : ControllerBase, IAsyncActionFilter
{
    protected readonly DoojaDb Db = db;
    protected int UserId => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
    [NonAction]
    public async Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
    {
        if (User.Identity?.IsAuthenticated == true && !await Db.Users.AnyAsync(x => x.Id == UserId && x.Active && x.Role == User.FindFirstValue(ClaimTypes.Role))) { context.Result = new UnauthorizedObjectResult(new { error = "الحساب موقوف" }); return; }
        await next();
    }
    protected async Task<bool> Owns(string placeId) => User.IsInRole("Admin") || await Db.Places.AnyAsync(x => x.Id == placeId && x.OwnerUserId == UserId);
}
