using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
namespace Dooja.Web.Controllers;
[Authorize(Roles = "Admin"), AutoValidateAntiforgeryToken]
public abstract class DashboardControllerBase : Controller { }
