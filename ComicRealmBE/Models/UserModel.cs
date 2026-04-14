using ComicRealmBE.Models.Enums;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ComicRealmBE.Models
{
    [Table("users")]
    public class UserModel
    {
        [Key]
        [Column("user_id")]
        public int UserId { get; set; }

        [Required]
        [Column("email")]
        [StringLength(255)]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]
        [Column("password_hash")]
        [StringLength(255)]
        public string PasswordHash { get; set; } = string.Empty;

        [Required]
        [Column("role")]
        public UserRole Role { get; set; }

        [Column("created_by")]
        [ForeignKey(nameof(CreatedByUser))]
        public int? CreatedBy { get; set; }

        [Column("created_at")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [Column("updated_at")]
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        [Column("is_active")]
        public bool IsActive { get; set; } = true;

        // Navigation properties
        public virtual UserModel? CreatedByUser { get; set; }
        public virtual ICollection<UserModel> CreatedUsers { get; set; } = new List<UserModel>();
        public virtual ICollection<ComicModel> Comics { get; set; } = new List<ComicModel>();
    }
}
