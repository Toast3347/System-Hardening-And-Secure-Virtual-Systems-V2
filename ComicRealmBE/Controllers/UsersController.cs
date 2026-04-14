using ComicRealmBE.Models.DTO;
using ComicRealmBE.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ComicRealmBE.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Roles = "Admin,SuperAdmin")]
    public class UsersController : ControllerBase
    {
        private readonly UserService _userService;

        public UsersController(UserService userService)
        {
            _userService = userService;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<UserDto>>> GetAll()
        {
            var users = await _userService.GetAllAsync();
            return Ok(users);
        }

        [HttpGet("{id:int}")]
        public async Task<ActionResult<UserDto>> GetById(int id)
        {
            var user = await _userService.GetByIdAsync(id);
            return user is null ? NotFound() : Ok(user);
        }

        [HttpPost]
        public async Task<ActionResult<UserDto>> Create(CreateUserDto dto)
        {
            var currentUserRole = User.Claims.FirstOrDefault(c => c.Type == System.Security.Claims.ClaimTypes.Role)?.Value;

            var result = await _userService.CreateAsync(dto, currentUserRole);
            
            if (result is null)
            {
                return Forbid(); // Indicates RBAC failure in logic for now
            }

            return CreatedAtAction(nameof(GetById), new { id = result.UserId }, result);
        }

        [HttpPut("{id:int}")]
        public async Task<ActionResult<UserDto>> Update(int id, UpdateUserDto dto)
        {
            var result = await _userService.UpdateAsync(id, dto);
            if (result is null)
            {
                return NotFound();
            }

            return Ok(result);
        }

        [HttpDelete("{id:int}")]
        public async Task<IActionResult> Delete(int id)
        {
            var success = await _userService.DeleteAsync(id);
            if (!success)
            {
                return NotFound();
            }

            return NoContent();
        }
    }
}
