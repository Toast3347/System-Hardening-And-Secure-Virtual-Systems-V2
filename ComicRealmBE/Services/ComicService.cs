using ComicRealmBE.DBContext;
using ComicRealmBE.Models;
using ComicRealmBE.Models.DTO;
using Microsoft.EntityFrameworkCore;

namespace ComicRealmBE.Services
{
    public class ComicService
    {
        private readonly ComicRealmDbContext _context;

        public ComicService(ComicRealmDbContext context)
        {
            _context = context;
        }

        public async Task<IEnumerable<ComicDto>> GetAllAsync()
        {
            return await _context.Comics
                .AsNoTracking()
                .Select(c => new ComicDto
                {
                    ComicId = c.ComicId,
                    Serie = c.Serie,
                    Number = c.Number,
                    Title = c.Title,
                    CreatedBy = c.CreatedBy,
                    CreatedAt = c.CreatedAt,
                    UpdatedAt = c.UpdatedAt
                }).ToListAsync();
        }

        public async Task<ComicDto?> GetByIdAsync(int id)
        {
            var c = await _context.Comics.FindAsync(id);
            if (c == null) return null;
            return new ComicDto
            {
                ComicId = c.ComicId,
                Serie = c.Serie,
                Number = c.Number,
                Title = c.Title,
                CreatedBy = c.CreatedBy,
                CreatedAt = c.CreatedAt,
                UpdatedAt = c.UpdatedAt
            };
        }

        public async Task<ComicDto> CreateAsync(CreateComicDto dto)
        {
            var comic = new ComicModel
            {
                Serie = dto.Serie,
                Number = dto.Number,
                Title = dto.Title,
                CreatedBy = dto.CreatedBy,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };
            _context.Comics.Add(comic);
            await _context.SaveChangesAsync();
            return new ComicDto
            {
                ComicId = comic.ComicId,
                Serie = comic.Serie,
                Number = comic.Number,
                Title = comic.Title,
                CreatedBy = comic.CreatedBy,
                CreatedAt = comic.CreatedAt,
                UpdatedAt = comic.UpdatedAt
            };
        }

        public async Task<bool> UpdateAsync(int id, UpdateComicDto dto)
        {
            var comic = await _context.Comics.FindAsync(id);
            if (comic == null) return false;
            
            comic.Serie = dto.Serie;
            comic.Number = dto.Number;
            comic.Title = dto.Title;
            comic.UpdatedAt = DateTime.UtcNow;
            
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> DeleteAsync(int id)
        {
            var comic = await _context.Comics.FindAsync(id);
            if (comic == null) return false;
            
            _context.Comics.Remove(comic);
            await _context.SaveChangesAsync();
            return true;
        }
    }
}
