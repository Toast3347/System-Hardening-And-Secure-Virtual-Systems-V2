using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ComicRealmBE.Models
{
    [Table("comics")]
    public class ComicModel
    {
        [Key]
        [Column("comic_id")]
        public int ComicId { get; set; }

        [Required]
        [Column("serie")]
        [StringLength(255)]
        public string Serie { get; set; } = string.Empty;

        [Required]
        [Column("number")]
        [StringLength(50)]
        public string Number { get; set; } = string.Empty;

        [Required]
        [Column("title")]
        [StringLength(500)]
        public string Title { get; set; } = string.Empty;

        [Required]
        [Column("created_by")]
        [ForeignKey(nameof(CreatedByUser))]
        public int CreatedBy { get; set; }

        [Column("created_at")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [Column("updated_at")]
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        public virtual User CreatedByUser { get; set; } = null!;
    }
}
