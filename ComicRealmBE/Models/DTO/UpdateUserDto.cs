using ComicRealmBE.Models.Enums;

namespace ComicRealmBE.Models.DTO
{
    public class UpdateUserDto
    {
        public string Email { get; set; } = string.Empty;
        public UserRole Role { get; set; }
        public int? CreatedBy { get; set; }
        public bool IsActive { get; set; }
    }
}
