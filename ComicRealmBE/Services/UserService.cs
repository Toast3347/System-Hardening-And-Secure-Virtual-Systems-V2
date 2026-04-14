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

        private IQueryable<UserModel> GetAuthorizedUsers(string? currentUserRole)
        {
            // SuperAdmin can only interact with Admins
            if (currentUserRole == UserRole.SuperAdmin.ToString())
            {
                return _context.Users.Where(u => u.Role == UserRole.Admin);
            }
            // Admin can only interact with Friends
            if (currentUserRole == UserRole.Admin.ToString())
            {
                return _context.Users.Where(u => u.Role == UserRole.Friend);
            }
            // Others get nothing
            return _context.Users.Where(u => false);
        }

        public async Task<IEnumerable<UserDto>> GetAllAsync(string? currentUserRole)
        {
            return await GetAuthorizedUsers(currentUserRole)
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

        public async Task<UserDto?> GetByIdAsync(int id, string? currentUserRole)
        {
            return await GetAuthorizedUsers(currentUserRole)
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
            // RBAC logic for creating
            if (currentUserRole == UserRole.SuperAdmin.ToString() && dto.Role != UserRole.Admin)
            {
                return null; // Super admin can only create Admin
            }
            if (currentUserRole == UserRole.Admin.ToString() && dto.Role != UserRole.Friend)
            {
                return null; // Admin can only create Friends based on strict rules
            }
            if (currentUserRole != UserRole.SuperAdmin.ToString() && currentUserRole != UserRole.Admin.ToString())
            {
                return null; // Others cannot create
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

        public async Task<UserDto?> UpdateAsync(int id, UpdateUserDto dto, string? currentUserRole)
        {
            var user = await GetAuthorizedUsers(currentUserRole).FirstOrDefaultAsync(u => u.UserId == id);
            if (user is null)
            {
                return null;
            }

            // Check if what they are updating to is valid for their role
            if (currentUserRole == UserRole.SuperAdmin.ToString() && dto.Role != UserRole.Admin)
            {
                return null;
            }
            if (currentUserRole == UserRole.Admin.ToString() && dto.Role != UserRole.Friend)
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

        public async Task<bool> DeleteAsync(int id, string? currentUserRole)
        {
            var user = await GetAuthorizedUsers(currentUserRole).FirstOrDefaultAsync(u => u.UserId == id);
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
