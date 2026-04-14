using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ComicRealmBE.Models.DTO;
using ComicRealmBE.Services;

namespace ComicRealmBE.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize] // All logged in users can see comics
    public class ComicsController : ControllerBase
    {
        private readonly ComicService _comicService;

        public ComicsController(ComicService comicService)
        {
            _comicService = comicService;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<ComicDto>>> GetAll()
        {
            var comics = await _comicService.GetAllAsync();
            return Ok(comics);
        }

        [HttpGet("{id:int}")]
        public async Task<ActionResult<ComicDto>> GetById(int id)
        {
            var comic = await _comicService.GetByIdAsync(id);
            if (comic == null) return NotFound();
            return Ok(comic);
        }

        [HttpPost]
        [Authorize(Roles = "Admin")]
        public async Task<ActionResult<ComicDto>> Create(CreateComicDto dto)
        {
            var comic = await _comicService.CreateAsync(dto);
            return CreatedAtAction(nameof(GetById), new { id = comic.ComicId }, comic);
        }

        [HttpPut("{id:int}")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> Update(int id, UpdateComicDto dto)
        {
            var success = await _comicService.UpdateAsync(id, dto);
            if (!success) return NotFound();
            
            return NoContent();
        }

        [HttpDelete("{id:int}")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> Delete(int id)
        {
            var success = await _comicService.DeleteAsync(id);
            if (!success) return NotFound();
            
            return NoContent();
        }
    }
}
