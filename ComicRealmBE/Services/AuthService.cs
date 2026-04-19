using ComicRealmBE.DBContext;
using ComicRealmBE.Models;
using ComicRealmBE.Models.DTO;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace ComicRealmBE.Services
{
    public class AuthService
    {
        private readonly IConfiguration _config;
        private readonly ComicRealmDbContext _context;

        public AuthService(IConfiguration config, ComicRealmDbContext context)
        {
            _config = config;
            _context = context;
        }

        public async Task<UserModel?> ValidateUserAsync(string email, string passwordHash)
        {
            var normalizedEmail = email.Trim().ToLowerInvariant();

            var user = await _context.Users
                .AsNoTracking()
                .FirstOrDefaultAsync(u => u.Email.ToLower() == normalizedEmail && u.IsActive);

            if (user is null)
            {
                return null;
            }

            var hasher = new PasswordHasher<UserModel>();
            var result = hasher.VerifyHashedPassword(user, user.PasswordHash, passwordHash);
            if (result == PasswordVerificationResult.Failed)
            {
                return null;
            }

            return user;
        }

        public async Task<AuthResponseDto?> LoginAsync(LoginDto dto)
        {
            var user = await ValidateUserAsync(dto.Email, dto.PasswordHash);

            if (user is null)
            {
                return null;
            }

            var token = GenerateJwtToken(user);

            return new AuthResponseDto
            {
                Token = token,
                UserId = user.UserId,
                Email = user.Email,
                Role = user.Role.ToString()
            };
        }

        public string GenerateJwtToken(UserModel user)
        {
            var keyString = _config["Jwt:Key"] ?? "superSecretKey_must_be_long_enough_for_hmacsha256@123456";
            var securityKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(keyString));
            var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);

            var claims = new[]
            {
                new Claim(ClaimTypes.NameIdentifier, user.UserId.ToString()),
                new Claim(ClaimTypes.Email, user.Email),
                new Claim(ClaimTypes.Role, user.Role.ToString())
            };

            var token = new JwtSecurityToken(
              issuer: _config["Jwt:Issuer"] ?? "ComicRealm",
              audience: _config["Jwt:Audience"] ?? "ComicRealm",
              claims: claims,
              expires: DateTime.Now.AddMinutes(120),
              signingCredentials: credentials);

            return new JwtSecurityTokenHandler().WriteToken(token);
        }
    }
}
