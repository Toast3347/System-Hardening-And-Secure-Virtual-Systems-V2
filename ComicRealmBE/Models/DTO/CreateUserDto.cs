using ComicRealmBE.Models.Enums;

namespace ComicRealmBE.Models.DTO
{
    public class CreateUserDto
    {
        public string Email { get; set; } = string.Empty;
        public string PasswordHash { get; set; } = string.Empty;
        public UserRole Role { get; set; }
        public int? CreatedBy { get; set; }
        public bool IsActive { get; set; } = true;
    }
}
