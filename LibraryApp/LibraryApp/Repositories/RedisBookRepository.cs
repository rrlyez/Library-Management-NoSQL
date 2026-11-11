using LibraryApp.Data;
using StackExchange.Redis;

namespace LibraryApp.Repositories;

public class RedisBookRepository
{
    private static string BookKey(int id) => $"library:book:{id}:available_count";
    private const string BooksIndex = "library:books:index";

    public async Task SaveBookCountAsync(int bookId, int count)
    {
        if (bookId <= 0 || count < 0) throw new ArgumentException("Invalid book data");
        var db = await RedisConnection.GetDatabaseAsync();
        await db.StringSetAsync(BookKey(bookId), count);
        await db.SetAddAsync(BooksIndex, bookId);
    }

    public async Task<int?> GetBookCountAsync(int bookId)
    {
        var db = await RedisConnection.GetDatabaseAsync();
        RedisValue val = await db.StringGetAsync(BookKey(bookId));
        return val.HasValue ? (int)val : null;
    }

    public async Task DeleteBookCountAsync(int bookId)
    {
        var db = await RedisConnection.GetDatabaseAsync();
        await db.KeyDeleteAsync(BookKey(bookId));
        await db.SetRemoveAsync(BooksIndex, bookId);
    }

    public async Task<List<int>> GetAvailableBookIdsAsync()
    {
        var db = await RedisConnection.GetDatabaseAsync();
        var ids = await db.SetMembersAsync(BooksIndex);
        var result = new List<int>();
        foreach (var id in ids)
        {
            int bookId = (int)id;
            RedisValue val = await db.StringGetAsync(BookKey(bookId));
            if (val.HasValue && (int)val > 0) result.Add(bookId);
        }
        result.Sort();
        return result;
    }
}
