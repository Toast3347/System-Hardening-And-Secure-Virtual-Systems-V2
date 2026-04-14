using ComicRealmBE.DBContext;
using ComicRealmBE.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.Text;

var builder = WebApplication.CreateBuilder(args);
var migrateOnly = args.Contains("--migrate-only");

// Add services to the container.
builder.Services.AddScoped<AuthService>();
builder.Services.AddScoped<ComicService>();
builder.Services.AddScoped<UserService>();

builder.Services.AddDbContext<ComicRealmDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddAuthentication(options =>
    {
        options.DefaultScheme = "JWT_OR_COOKIE";
        options.DefaultChallengeScheme = "JWT_OR_COOKIE";
    })
    .AddCookie(CookieAuthenticationDefaults.AuthenticationScheme, options =>
    {
        options.Events.OnRedirectToLogin = context =>
        {
            context.Response.StatusCode = 401; // Return 401 Unauthorized for API rather than redirecting
            return Task.CompletedTask;
        };
        options.Events.OnRedirectToAccessDenied = context =>
        {
            context.Response.StatusCode = 403; // Return 403 Forbidden
            return Task.CompletedTask;
        };
    })
    .AddJwtBearer(JwtBearerDefaults.AuthenticationScheme, options =>
    {
        var keyString = builder.Configuration["Jwt:Key"] ?? "superSecretKey_must_be_long_enough_for_hmacsha256@123456";
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"] ?? "ComicRealm",
            ValidAudience = builder.Configuration["Jwt:Audience"] ?? "ComicRealm",
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(keyString))
        };
    })
    .AddPolicyScheme("JWT_OR_COOKIE", "JWT_OR_COOKIE", options =>
    {
        options.ForwardDefaultSelector = context =>
        {
            // If the Authorization header starts with 'Bearer ', use JWT.
            string authorization = context.Request.Headers.Authorization.ToString();
            if (!string.IsNullOrEmpty(authorization) && authorization.StartsWith("Bearer "))
            {
                return JwtBearerDefaults.AuthenticationScheme;
            }

            // Otherwise default to Cookies.
            return CookieAuthenticationDefaults.AuthenticationScheme;
        };
    });

builder.Services.AddAuthorization();

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

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();
