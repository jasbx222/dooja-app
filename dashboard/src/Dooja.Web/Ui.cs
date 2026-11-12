using Microsoft.AspNetCore.Html;

namespace Dooja.Web;

public static class Ui
{
    private static readonly HashSet<string> Icons =
    [
        "house", "store", "calendar-check", "badge-percent", "users", "star", "search", "bell",
        "log-out", "plus", "wallet", "circle-check", "clock", "circle-x", "chart-column", "map-pin",
        "layout-grid", "chevron-down", "chevron-left", "chevron-right", "x", "sliders-horizontal", "pencil"
    ];

    public static IHtmlContent Icon(string name)
    {
        if (!Icons.Contains(name)) throw new ArgumentOutOfRangeException(nameof(name), name, "Unknown icon");
        return new HtmlString($"<span class=\"ico\" style=\"--ico:url('/icons/{name}.svg')\" aria-hidden=\"true\"></span>");
    }

    public static string StatusClass(string? status) => status is "مؤكد" or "مكتمل" ? "ok" : status == "ملغي" ? "bad" : "pending";

    public static string RoleLabel(string? role) => role switch
    {
        "Owner" => "صاحب مكان",
        "Admin" => "مدير",
        _ => "زبون"
    };

    public static string Initial(string? name) => string.IsNullOrWhiteSpace(name) ? "ض" : name.Trim()[..1];

    public static string PageHref(HttpRequest request, int page)
    {
        var pairs = request.Query
            .Where(x => !string.Equals(x.Key, "page", StringComparison.OrdinalIgnoreCase))
            .SelectMany(x => x.Value.Select(v => $"{Uri.EscapeDataString(x.Key)}={Uri.EscapeDataString(v ?? "")}"))
            .ToList();
        pairs.Add($"page={page}");
        return request.Path + "?" + string.Join("&", pairs);
    }

    public static string FilterHref(string? path, string? q, string? status)
    {
        var pairs = new List<string>();
        if (!string.IsNullOrWhiteSpace(q)) pairs.Add("q=" + Uri.EscapeDataString(q));
        if (!string.IsNullOrWhiteSpace(status)) pairs.Add("status=" + Uri.EscapeDataString(status));
        return (path ?? "/") + (pairs.Count == 0 ? "" : "?" + string.Join("&", pairs));
    }
}
