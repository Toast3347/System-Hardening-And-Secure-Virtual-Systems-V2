using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using ComicRealmBE.Models.DTO;
using ComicRealmBE.Services;
using System.Security.Claims;

namespace ComicRealmBE.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly AuthService _authService;

        public AuthController(AuthService authService)
        {
            _authService = authService;
        }

        [HttpPost("login")]
        [AllowAnonymous]
        public async Task<ActionResult<AuthResponseDto>> Login([FromBody] LoginDto dto)
        {
            var response = await _authService.LoginAsync(dto);

            if (response is null)
            {
                return Unauthorized(new { message = "Invalid credentials" });
            }

            return Ok(response);
        }

        [HttpPost("login-cookie")]
        [AllowAnonymous]
        public async Task<IActionResult> LoginCookie([FromBody] LoginDto dto)
        {
            var user = await _authService.ValidateUserAsync(dto.Email, dto.PasswordHash);

            if (user is null)
            {
                return Unauthorized(new { message = "Invalid credentials" });
            }

            var claims = new[]
            {
                new Claim(ClaimTypes.NameIdentifier, user.UserId.ToString()),
                new Claim(ClaimTypes.Email, user.Email),
                new Claim(ClaimTypes.Role, user.Role.ToString())
            };

            var identity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);

            await HttpContext.SignInAsync(
                CookieAuthenticationDefaults.AuthenticationScheme,
                new ClaimsPrincipal(identity),
                new AuthenticationProperties
                {
                    IsPersistent = true,
                    ExpiresUtc = DateTime.UtcNow.AddHours(2)
                });

            return Ok(new { message = "Logged in successfully with cookie", role = user.Role.ToString() });
        }

        [HttpPost("logout")]
        public async Task<IActionResult> LogoutCookie()
        {
            await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
            return Ok(new { message = "Logged out successfully" });
        }
    }
}
