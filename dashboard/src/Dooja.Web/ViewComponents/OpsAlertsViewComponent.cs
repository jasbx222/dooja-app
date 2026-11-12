using Dooja.Web.Data;
using Dooja.Web.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Dooja.Web.ViewComponents;

public class OpsAlertsViewComponent(DoojaDb db) : ViewComponent
{
    public async Task<IViewComponentResult> InvokeAsync()
    {
        var query = db.Bookings.AsNoTracking().Where(x => x.Status == "بانتظار القبول");
        var count = await query.CountAsync();
        var items = await query.Include(x => x.Place).Include(x => x.User).OrderByDescending(x => x.Id).Take(5).ToListAsync();
        return View(new OpsAlertsVm(count, items));
    }
}
