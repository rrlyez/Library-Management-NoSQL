using LibraryApp.Data;
using MongoDB.Bson;
using MongoDB.Driver;
using Npgsql;

namespace LibraryApp.Benchmarks;

public static class DataGenerator
{
    public static async Task GenerateAsync(string connectionString, int count)
    {
        if (count is < 1 or > 30000) throw new ArgumentOutOfRangeException(nameof(count));
        Console.WriteLine($"Generating {count} books...");
        await using var sql = new NpgsqlConnection(connectionString);
        await sql.OpenAsync();
        const string createTable = """
            CREATE TABLE IF NOT EXISTS benchmark_books (
                book_id INTEGER PRIMARY KEY,
                title TEXT NOT NULL,
                publish_year INTEGER NOT NULL,
                available_copies INTEGER NOT NULL,
                genre TEXT NOT NULL
            );
            """;
        await using (var cmd = new NpgsqlCommand(createTable, sql)) await cmd.ExecuteNonQueryAsync();
        await using (var cmd = new NpgsqlCommand("TRUNCATE TABLE benchmark_books", sql)) await cmd.ExecuteNonQueryAsync();
        const string insert = """
            INSERT INTO benchmark_books (book_id, title, publish_year, available_copies, genre)
            SELECT i, 'Book ' || i, 1990 + (i % 35), i % 6,
                   CASE i % 4 WHEN 0 THEN 'Fantasy' WHEN 1 THEN 'Science'
                                WHEN 2 THEN 'History' ELSE 'Fiction' END
            FROM generate_series(1, @count) AS i;
            """;
        await using (var cmd = new NpgsqlCommand(insert, sql))
        {
            cmd.Parameters.AddWithValue("count", count);
            await cmd.ExecuteNonQueryAsync();
        }
        Console.WriteLine("PostgreSQL: data generated");
        var mongo = MongoDbConnection.GetDatabase().GetCollection<BsonDocument>("benchmark_books");
        await mongo.DeleteManyAsync(FilterDefinition<BsonDocument>.Empty);
        for (int start = 1; start <= count; start += 1000)
        {
            int end = Math.Min(start + 999, count);
            var docs = new List<BsonDocument>();
            for (int i = start; i <= end; i++)
            {
                string genre = (i % 4) switch { 0 => "Fantasy", 1 => "Science", 2 => "History", _ => "Fiction" };
                docs.Add(new BsonDocument {
                    { "book_id", i }, { "title", $"Book {i}" },
                    { "publish_year", 1990 + i % 35 },
                    { "available_copies", i % 6 }, { "genre", genre }
                });
            }
            await mongo.InsertManyAsync(docs);
            Console.WriteLine($"MongoDB: {end}/{count} books");
        }
        await mongo.Indexes.CreateManyAsync(new[] {
            new CreateIndexModel<BsonDocument>(Builders<BsonDocument>.IndexKeys.Ascending("book_id"), new CreateIndexOptions { Unique = true }),
            new CreateIndexModel<BsonDocument>(Builders<BsonDocument>.IndexKeys.Ascending("publish_year")),
            new CreateIndexModel<BsonDocument>(Builders<BsonDocument>.IndexKeys.Ascending("available_copies"))
        });
        const string indexes = """
            CREATE INDEX IF NOT EXISTS idx_bench_year ON benchmark_books(publish_year);
            CREATE INDEX IF NOT EXISTS idx_bench_copies ON benchmark_books(available_copies);
            ANALYZE benchmark_books;
            """;
        await using (var cmd = new NpgsqlCommand(indexes, sql)) await cmd.ExecuteNonQueryAsync();
        Console.WriteLine("Indexes created. Generation completed!");
    }
}
