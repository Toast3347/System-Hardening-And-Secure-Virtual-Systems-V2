namespace ComicRealmBE.Models.DTO
{
    public class CreateComicDto
    {
        public string Serie { get; set; } = string.Empty;
        public string Number { get; set; } = string.Empty;
        public string Title { get; set; } = string.Empty;
        public int CreatedBy { get; set; }
    }
}
