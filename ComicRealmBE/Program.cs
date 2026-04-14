using ComicRealmBE.DBContext;
using ComicRealmBE.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddScoped<AuthService>();
builder.Services.AddScoped<ComicService>();
builder.Services.AddScoped<UserService>();

builder.Services.AddDbContext<ComicRealmDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
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
    // Try catching migrate so tests or environments without DB don't just crash on startup
    try { dbContext.Database.Migrate(); } catch { }
}

app.UseHttpsRedirection();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();
