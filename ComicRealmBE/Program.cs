using ComicRealmBE.Configuration;
using ComicRealmBE.DBContext;
using ComicRealmBE.Services;
using ComicRealmBE.Models;
using ComicRealmBE.Models.Enums;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.CookiePolicy;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.Text;

var builder = WebApplication.CreateBuilder(args);
var migrateOnly = args.Contains("--migrate-only");

// Pull every secret (DB connection string, JWT signing key, issuer, audience)
// from Vault at startup via the HTTP API. In Development Vault is optional and
// User Secrets act as the fallback so the unit-test host (and `dotnet run`
// without a Vault sidecar) can still boot. In every other environment Vault
// is mandatory and the app fails fast if it is unreachable.
if (builder.Environment.IsDevelopment())
{
    builder.Configuration.AddVault(optional: true);
    builder.Configuration.AddUserSecrets<Program>();
}
else
{
    builder.Configuration.AddVault(optional: false);
}

var allowedOrigins = builder.Configuration
    .GetSection("Cors:AllowedOrigins")
    .Get<string[]>()
    ?? new[] { "http://localhost:5173" };

// Add services to the container.
builder.Services.AddScoped<AuthService>();
builder.Services.AddScoped<ComicService>();
builder.Services.AddScoped<UserService>();

builder.Services.AddDbContext<ComicRealmDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

var jwtKey = builder.Configuration["Jwt:SigningKey"];

if (string.IsNullOrWhiteSpace(jwtKey))
{
    throw new InvalidOperationException("JWT signing key is missing. Configure Jwt:SigningKey through environment variables, user secrets, or Vault.");
}

builder.Services.Configure<CookiePolicyOptions>(options =>
{
    options.HttpOnly = HttpOnlyPolicy.Always;
    options.Secure = CookieSecurePolicy.Always;
    options.MinimumSameSitePolicy = SameSiteMode.Strict;
});

builder.Services.AddAuthentication(options =>
    {
        options.DefaultScheme = "JWT_OR_COOKIE";
        options.DefaultChallengeScheme = "JWT_OR_COOKIE";
    })
    .AddCookie(CookieAuthenticationDefaults.AuthenticationScheme, options =>
    {
        options.Cookie.HttpOnly = true;
        options.Cookie.SecurePolicy = CookieSecurePolicy.Always;
        options.Cookie.SameSite = SameSiteMode.Strict;

        options.Events.OnRedirectToLogin = context =>
        {
            context.Response.StatusCode = 401;
            return Task.CompletedTask;
        };

        options.Events.OnRedirectToAccessDenied = context =>
        {
            context.Response.StatusCode = 403;
            return Task.CompletedTask;
        };
    })
    .AddJwtBearer(JwtBearerDefaults.AuthenticationScheme, options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey))
        };
    })
    .AddPolicyScheme("JWT_OR_COOKIE", "JWT_OR_COOKIE", options =>
    {
        options.ForwardDefaultSelector = context =>
        {
            string authorization = context.Request.Headers.Authorization.ToString();

            if (!string.IsNullOrEmpty(authorization) && authorization.StartsWith("Bearer "))
            {
                return JwtBearerDefaults.AuthenticationScheme;
            }

            return CookieAuthenticationDefaults.AuthenticationScheme;
        };
    });

builder.Services.AddAuthorization();

builder.Services.AddCors(options =>
{
    options.AddPolicy("Frontend", policy =>
    {
        policy
            .WithOrigins(allowedOrigins)
            .AllowAnyHeader()
            .AllowAnyMethod();
    });
});

builder.Services.AddHealthChecks();

builder.Services.AddControllers();
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

using (var scope = app.Services.CreateScope())
{
    var dbContext = scope.ServiceProvider.GetRequiredService<ComicRealmDbContext>();
    dbContext.Database.Migrate();
}

if (migrateOnly)
{
    return;
}

app.UseHttpsRedirection();
app.UseCookiePolicy();
app.UseCors("Frontend");
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
app.MapHealthChecks("/health");

app.Run();