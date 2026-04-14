using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ComicRealmBE.Models.DTO;
using ComicRealmBE.Services;

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
    }
}
