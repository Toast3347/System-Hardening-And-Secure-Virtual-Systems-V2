namespace ComicRealmBE.Models.Enums
{
    // User roles for authorization
    public enum UserRole
    {
        SuperAdmin = 0, //Can do CRUD operations on admins nothing else
        Admin = 1, // can do CRUD operations on comics and friends
        Friend = 2 // Can only read the comics list
    }
}
