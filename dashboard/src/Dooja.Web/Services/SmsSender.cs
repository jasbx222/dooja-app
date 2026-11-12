using System.Net.Http.Headers;
using System.Text;
using Microsoft.Extensions.Options;
namespace Dooja.Web.Services;
public sealed class SmsOptions
{
    public string Provider { get; set; } = "";
    public string AccountSid { get; set; } = "";
    public string AuthToken { get; set; } = "";
    public string From { get; set; } = "";
    public bool IsConfigured => string.Equals(Provider, "Twilio", StringComparison.OrdinalIgnoreCase) && AccountSid.Length > 0 && AuthToken.Length > 0 && From.Length > 0;
}
public interface ISmsSender
{
    bool IsConfigured { get; }
    Task SendAsync(string e164Phone, string body, CancellationToken cancellationToken = default);
}
public sealed class TwilioSmsSender(IHttpClientFactory http, IOptions<SmsOptions> options, ILogger<TwilioSmsSender> log) : ISmsSender
{
    public bool IsConfigured => options.Value.IsConfigured;
    public async Task SendAsync(string e164Phone, string body, CancellationToken cancellationToken = default)
    {
        var settings = options.Value;
        if (!settings.IsConfigured) throw new InvalidOperationException("SMS provider is not configured");
        var request = new HttpRequestMessage(HttpMethod.Post, $"https://api.twilio.com/2010-04-01/Accounts/{Uri.EscapeDataString(settings.AccountSid)}/Messages.json");
        request.Headers.Authorization = new AuthenticationHeaderValue("Basic", Convert.ToBase64String(Encoding.ASCII.GetBytes($"{settings.AccountSid}:{settings.AuthToken}")));
        request.Content = new FormUrlEncodedContent(new Dictionary<string, string> { ["To"] = e164Phone, ["From"] = settings.From, ["Body"] = body });
        var response = await http.CreateClient("sms").SendAsync(request, cancellationToken);
        if (!response.IsSuccessStatusCode) { log.LogWarning("SMS provider rejected a message with status {Status}", (int)response.StatusCode); throw new InvalidOperationException("SMS provider rejected the message"); }
    }
}
