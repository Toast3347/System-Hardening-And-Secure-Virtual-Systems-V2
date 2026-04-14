using ComicRealmBE.Models;
using Microsoft.EntityFrameworkCore;

namespace ComicRealmBE.DBContext;

public class ComicRealmDbContext(DbContextOptions<ComicRealmDbContext> options) : DbContext(options)
{
    public DbSet<UserModel> Users => Set<UserModel>();
    public DbSet<ComicModel> Comics => Set<ComicModel>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<UserModel>()
            .HasOne(user => user.CreatedByUser)
            .WithMany(user => user.CreatedUsers)
            .HasForeignKey(user => user.CreatedBy)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<ComicModel>()
            .HasOne(comic => comic.CreatedByUser)
            .WithMany(user => user.Comics)
            .HasForeignKey(comic => comic.CreatedBy)
            .OnDelete(DeleteBehavior.Restrict);
    }
}