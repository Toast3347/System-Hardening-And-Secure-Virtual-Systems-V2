namespace ComicRealmBE.Models.DTO
{
    public class ComicDto
    {
        public int ComicId { get; set; }
        public string Serie { get; set; } = string.Empty;
        public string Number { get; set; } = string.Empty;
        public string Title { get; set; } = string.Empty;
        public int CreatedBy { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
    }
}
