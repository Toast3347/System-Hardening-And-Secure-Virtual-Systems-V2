using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ComicRealmBE.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Roles = "Admin,SuperAdmin")]
    public class UsersController : ControllerBase
    {
        private readonly ComicRealmContext _context;

        public UsersController(ComicRealmContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<UserDto>>> GetAll()
        {
            var users = await _context.Users
                .AsNoTracking()
                .Select(u => new UserDto
                {
                    UserId = u.UserId,
                    Email = u.Email,
                    Role = u.Role,
                    CreatedBy = u.CreatedBy,
                    CreatedAt = u.CreatedAt,
                    UpdatedAt = u.UpdatedAt,
                    IsActive = u.IsActive
                })
                .ToListAsync();

            return Ok(users);
        }

        [HttpGet("{id:int}")]
        public async Task<ActionResult<UserDto>> GetById(int id)
        {
            var user = await _context.Users
                .AsNoTracking()
                .Where(u => u.UserId == id)
                .Select(u => new UserDto
                {
                    UserId = u.UserId,
                    Email = u.Email,
                    Role = u.Role,
                    CreatedBy = u.CreatedBy,
                    CreatedAt = u.CreatedAt,
                    UpdatedAt = u.UpdatedAt,
                    IsActive = u.IsActive
                })
                .FirstOrDefaultAsync();

            return user is null ? NotFound() : Ok(user);
        }

        [HttpPost]
        public async Task<ActionResult<UserDto>> Create(CreateUserDto dto)
        {
            var user = new User
            {
                Email = dto.Email,
                PasswordHash = dto.PasswordHash,
                Role = dto.Role,
                CreatedBy = dto.CreatedBy,
                IsActive = dto.IsActive,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _context.Users.Add(user);
            await _context.SaveChangesAsync();

            var result = new UserDto
            {
                UserId = user.UserId,
                Email = user.Email,
                Role = user.Role,
                CreatedBy = user.CreatedBy,
                CreatedAt = user.CreatedAt,
                UpdatedAt = user.UpdatedAt,
                IsActive = user.IsActive
            };

            return CreatedAtAction(nameof(GetById), new { id = user.UserId }, result);
        }

        [HttpPut("{id:int}")]
        public async Task<ActionResult<UserDto>> Update(int id, UpdateUserDto dto)
        {
            var user = await _context.Users.FindAsync(id);
            if (user is null)
            {
                return NotFound();
            }

            user.Email = dto.Email;
            user.Role = dto.Role;
            user.CreatedBy = dto.CreatedBy;
            user.IsActive = dto.IsActive;
            user.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return Ok(new UserDto
            {
                UserId = user.UserId,
                Email = user.Email,
                Role = user.Role,
                CreatedBy = user.CreatedBy,
                CreatedAt = user.CreatedAt,
                UpdatedAt = user.UpdatedAt,
                IsActive = user.IsActive
            });
        }

        [HttpDelete("{id:int}")]
        public async Task<IActionResult> Delete(int id)
        {
            var user = await _context.Users.FindAsync(id);
            if (user is null)
            {
                return NotFound();
            }

            user.IsActive = false;
            user.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return NoContent();
        }
    }
}
