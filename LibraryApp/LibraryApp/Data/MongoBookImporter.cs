using LibraryApp.Models;
using LibraryApp.Repositories;
using Npgsql;

namespace LibraryApp.Data;

public static class MongoBookImporter
{
    public static async Task ImportAsync(string connectionString)
    {
        await using var sql = new NpgsqlConnection(connectionString);
        await sql.OpenAsync();
        const string query = """
            SELECT b.book_id, b.title, b.isbn, b.publish_year,
                   p.name AS publisher,
                   COALESCE((
                     SELECT array_agg((a.first_name || ' ' || a.last_name)::text)
                     FROM book_authors ba JOIN authors a ON a.author_id = ba.author_id
                     WHERE ba.book_id = b.book_id
                   ), ARRAY[]::text[]) AS authors,
                   COALESCE((
                     SELECT array_agg(g.name::text)
                     FROM book_genres bg JOIN genres g ON g.genre_id = bg.genre_id
                     WHERE bg.book_id = b.book_id
                   ), ARRAY[]::text[]) AS genres,
                   (SELECT COUNT(*) FROM book_copies bc
                    WHERE bc.book_id = b.book_id AND bc.status = 'available'
                      AND bc.is_deleted = false) AS available_copies
            FROM books b JOIN publishers p ON p.publisher_id = b.publisher_id
            WHERE b.is_deleted = false
            ORDER BY b.book_id;
            """;
        await using var cmd = new NpgsqlCommand(query, sql);
        await using var reader = await cmd.ExecuteReaderAsync();
        var repository = new MongoBookRepository();
        int count = 0;
        while (await reader.ReadAsync())
        {
            var book = new MongoBook
            {
                BookId = reader.GetInt32(0), Title = reader.GetString(1),
                Isbn = reader.GetString(2),
                PublishYear = reader.IsDBNull(3) ? null : reader.GetInt32(3),
                Publisher = reader.GetString(4),
                Authors = reader.GetFieldValue<string[]>(5).ToList(),
                Genres = reader.GetFieldValue<string[]>(6).ToList(),
                AvailableCopies = checked((int)reader.GetInt64(7))
            };
            await repository.SaveBookAsync(book);
            count++;
        }
        Console.WriteLine($"Imported {count} books into MongoDB.");
    }
}
