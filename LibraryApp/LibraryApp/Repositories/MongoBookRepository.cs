using LibraryApp.Data;
using LibraryApp.Models;
using MongoDB.Driver;

namespace LibraryApp.Repositories;

public class MongoBookRepository
{
    private readonly IMongoCollection<MongoBook> books = MongoDbConnection.GetDatabase().GetCollection<MongoBook>("books");

    public async Task SaveBookAsync(MongoBook book)
    {
        var filter = Builders<MongoBook>.Filter.Eq(x => x.BookId, book.BookId);
        var update = Builders<MongoBook>.Update
            .Set(x => x.Title, book.Title).Set(x => x.Isbn, book.Isbn)
            .Set(x => x.PublishYear, book.PublishYear).Set(x => x.Publisher, book.Publisher)
            .Set(x => x.Authors, book.Authors).Set(x => x.Genres, book.Genres)
            .Set(x => x.AvailableCopies, book.AvailableCopies);
        await books.UpdateOneAsync(filter, update, new UpdateOptions { IsUpsert = true });
    }

    public Task<List<MongoBook>> GetAllBooksAsync() => books.Find(FilterDefinition<MongoBook>.Empty).ToListAsync();
    public Task<List<MongoBook>> FindByGenreAsync(string genre) => books.Find(x => x.Genres.Contains(genre)).ToListAsync();
    public Task<List<MongoBook>> FindByAuthorAsync(string author) => books.Find(x => x.Authors.Contains(author)).ToListAsync();
    public Task<List<MongoBook>> GetAvailableBooksAsync() => books.Find(x => x.AvailableCopies > 0).ToListAsync();
}
