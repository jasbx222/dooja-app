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

    static readonly TimeZoneInfo Baghdad = TimeZoneInfo.FindSystemTimeZoneById("Asia/Baghdad");

    /// A date that stays one left-to-right unit inside RTL text and never wraps.
    public static IHtmlContent Date(DateOnly? day) =>
        day is DateOnly d ? new HtmlString($"<bdi class=\"date\" dir=\"ltr\">{d:yyyy-MM-dd}</bdi>") : HtmlString.Empty;

    /// A stored UTC time shown in Baghdad time, the time staff work in.
    public static IHtmlContent Local(DateTime utc) =>
        new HtmlString($"<bdi class=\"date\" dir=\"ltr\">{TimeZoneInfo.ConvertTimeFromUtc(DateTime.SpecifyKind(utc, DateTimeKind.Utc), Baghdad):yyyy-MM-dd HH:mm}</bdi>");

    public static string Initial(string? name) => string.IsNullOrWhiteSpace(name) ? "ض" : name.Trim()[..1];

    /// First (cover) image of a product, or null when it has none loaded.
    public static string? Cover(Dooja.Web.Models.Product? p) =>
        p?.Images?.OrderBy(i => i.SortOrder).Select(i => i.Path).FirstOrDefault();

    /// Product thumbnail: the photo when there is one, otherwise the name's first letter.
    public static IHtmlContent Thumb(string? path, string? name, string css = "thumb")
    {
        var enc = System.Text.Encodings.Web.HtmlEncoder.Default;
        return string.IsNullOrWhiteSpace(path)
            ? new HtmlString($"<span class=\"{css}\" aria-hidden=\"true\">{enc.Encode(Initial(name))}</span>")
            : new HtmlString($"<img class=\"{css}\" src=\"{enc.Encode(path)}\" alt=\"\" loading=\"lazy\"/>");
    }

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
