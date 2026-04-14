using ComicRealmBE.Controllers;
using ComicRealmBE.DBContext;
using ComicRealmBE.Models;
using ComicRealmBE.Models.DTO;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Moq;
using Xunit;

namespace ComicRealmBE.Tests
{
    public class ComicsControllerTests
    {
        private ComicRealmDbContext GetDbContext()
        {
            var options = new DbContextOptionsBuilder<ComicRealmDbContext>()
                .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
                .Options;
            return new ComicRealmDbContext(options);
        }

        [Fact]
        public async Task GetAll_ReturnsAllComics()
        {
            // Arrange
            var db = GetDbContext();
            db.Comics.Add(new ComicModel { Title = "Test", Serie = "Series", Number = "1", CreatedBy = 1 });
            await db.SaveChangesAsync();
            var service = new ComicRealmBE.Services.ComicService(db);
            var controller = new ComicsController(service);

            // Act
            var result = await (controller.GetAll());

            // Assert
            var okResult = Assert.IsType<OkObjectResult>(result.Result);
            var items = Assert.IsAssignableFrom<IEnumerable<ComicDto>>(okResult.Value);
            Assert.Single(items);
        }
    }
}
