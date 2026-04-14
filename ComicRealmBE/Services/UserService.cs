using ComicRealmBE.Models;
using ComicRealmBE.Models.DTO;
using ComicRealmBE.Models.Enums;
using ComicRealmBE.DBContext;
using Microsoft.EntityFrameworkCore;

namespace ComicRealmBE.Services
{
    public class UserService
    {
        private readonly ComicRealmDbContext _context;

        public UserService(ComicRealmDbContext context)
        {
            _context = context;
        }

        public async Task<IEnumerable<UserDto>> GetAllAsync()
        {
            return await _context.Users
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
        }

        public async Task<UserDto?> GetByIdAsync(int id)
        {
            return await _context.Users
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
        }

        public async Task<UserDto?> CreateAsync(CreateUserDto dto, string? currentUserRole)
        {
            // RBAC logic
            if (currentUserRole == UserRole.SuperAdmin.ToString() && dto.Role != UserRole.Admin)
            {
                return null; // Super admin can only create Admin
            }
            if (currentUserRole == UserRole.Admin.ToString() && dto.Role == UserRole.SuperAdmin)
            {
                return null; // Admin cannot create SuperAdmin
            }

            var user = new UserModel
            {
                Email = dto.Email,
                PasswordHash = dto.PasswordHash, // Hash should be managed securely
                Role = dto.Role,
                CreatedBy = dto.CreatedBy,
                IsActive = dto.IsActive,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _context.Users.Add(user);
            await _context.SaveChangesAsync();

            return new UserDto
            {
                UserId = user.UserId,
                Email = user.Email,
                Role = user.Role,
                CreatedBy = user.CreatedBy,
                CreatedAt = user.CreatedAt,
                UpdatedAt = user.UpdatedAt,
                IsActive = user.IsActive
            };
        }

        public async Task<UserDto?> UpdateAsync(int id, UpdateUserDto dto)
        {
            var user = await _context.Users.FindAsync(id);
            if (user is null)
            {
                return null;
            }

            user.Email = dto.Email;
            user.Role = dto.Role;
            user.CreatedBy = dto.CreatedBy;
            user.IsActive = dto.IsActive;
            user.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return new UserDto
            {
                UserId = user.UserId,
                Email = user.Email,
                Role = user.Role,
                CreatedBy = user.CreatedBy,
                CreatedAt = user.CreatedAt,
                UpdatedAt = user.UpdatedAt,
                IsActive = user.IsActive
            };
        }

        public async Task<bool> DeleteAsync(int id)
        {
            var user = await _context.Users.FindAsync(id);
            if (user is null)
            {
                return false;
            }

            user.IsActive = false;
            user.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return true;
        }
    }
}
