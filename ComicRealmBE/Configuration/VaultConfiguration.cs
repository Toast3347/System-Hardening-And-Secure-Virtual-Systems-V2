using System.Net.Http.Headers;
using System.Text.Json;

namespace ComicRealmBE.Configuration;

/// <summary>
/// Loads secrets from HashiCorp Vault (KV v2) at startup via the HTTP API and
/// exposes them as IConfiguration entries. No secret is ever read from disk
/// or environment files — everything lives in Vault and is fetched on demand.
/// </summary>
public sealed class VaultConfigurationSource : IConfigurationSource
{
    public required string Address { get; init; }
    public required string Token { get; init; }
    public required string Mount { get; init; }
    public required string Path { get; init; }
    public bool Optional { get; init; }

    public IConfigurationProvider Build(IConfigurationBuilder builder) =>
        new VaultConfigurationProvider(this);
}

public sealed class VaultConfigurationProvider : ConfigurationProvider
{
    private readonly VaultConfigurationSource _source;

    public VaultConfigurationProvider(VaultConfigurationSource source)
    {
        _source = source;
    }

    public override void Load()
    {
        try
        {
            LoadAsync().GetAwaiter().GetResult();
        }
        catch (Exception ex) when (_source.Optional)
        {
            // In dev we may want to tolerate Vault being unavailable; in
            // production Optional is false and the failure propagates.
            Console.Error.WriteLine($"[Vault] Optional load failed: {ex.Message}");
        }
    }

    private async Task LoadAsync()
    {
        using var http = new HttpClient
        {
            BaseAddress = new Uri(_source.Address.TrimEnd('/') + "/"),
            Timeout = TimeSpan.FromSeconds(10)
        };
        http.DefaultRequestHeaders.Add("X-Vault-Token", _source.Token);
        http.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));

        var url = $"v1/{_source.Mount.Trim('/')}/data/{_source.Path.Trim('/')}";
        using var response = await http.GetAsync(url).ConfigureAwait(false);
        response.EnsureSuccessStatusCode();

        await using var stream = await response.Content.ReadAsStreamAsync().ConfigureAwait(false);
        using var doc = await JsonDocument.ParseAsync(stream).ConfigureAwait(false);

        if (!doc.RootElement.TryGetProperty("data", out var outer) ||
            !outer.TryGetProperty("data", out var inner))
        {
            throw new InvalidOperationException(
                $"Vault response at '{url}' did not contain data.data (is the path a KV v2 secret?).");
        }

        var data = new Dictionary<string, string?>(StringComparer.OrdinalIgnoreCase);
        foreach (var prop in inner.EnumerateObject())
        {
            // Vault keys use double-underscore to mirror IConfiguration's
            // section separator (e.g. ConnectionStrings__DefaultConnection
            // → ConnectionStrings:DefaultConnection).
            var key = prop.Name.Replace("__", ConfigurationPath.KeyDelimiter);
            data[key] = prop.Value.ValueKind == JsonValueKind.String
                ? prop.Value.GetString()
                : prop.Value.GetRawText();
        }

        Data = data;
    }
}

public static class VaultConfigurationExtensions
{
    /// <summary>
    /// Reads VAULT_ADDR / VAULT_TOKEN / VAULT_KV_MOUNT / VAULT_KV_PATH from
    /// the environment and registers them as a configuration source. Fails
    /// fast in non-Development environments when address or token are missing.
    /// </summary>
    public static IConfigurationBuilder AddVault(this IConfigurationBuilder builder, bool optional = false)
    {
        var address = Environment.GetEnvironmentVariable("VAULT_ADDR");
        var token   = Environment.GetEnvironmentVariable("VAULT_TOKEN");
        var mount   = Environment.GetEnvironmentVariable("VAULT_KV_MOUNT") ?? "secret";
        var path    = Environment.GetEnvironmentVariable("VAULT_KV_PATH")  ?? "comicrealm";

        if (string.IsNullOrWhiteSpace(address) || string.IsNullOrWhiteSpace(token))
        {
            if (optional)
            {
                return builder;
            }
            throw new InvalidOperationException(
                "Vault is required: set VAULT_ADDR and VAULT_TOKEN (the app no longer ships any secret defaults).");
        }

        builder.Add(new VaultConfigurationSource
        {
            Address  = address,
            Token    = token,
            Mount    = mount,
            Path     = path,
            Optional = optional,
        });
        return builder;
    }
}
