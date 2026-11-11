using System.Diagnostics;
using LibraryApp.Data;
using LibraryApp.Models;
using MongoDB.Driver;
using Npgsql;

namespace LibraryApp.Benchmarks;

public static class BenchmarkRunner
{
    public static async Task RunAsync(string connectionString)
    {
        await using var sql = new NpgsqlConnection(connectionString);
        await sql.OpenAsync();
        var mongo = MongoDbConnection.GetDatabase().GetCollection<MongoBook>("books");
        Console.WriteLine(" SQL vs NoSQL Benchmark (real library books) ");
        await CompareAsync("Search by ID",
            () => SqlQuery(sql, "SELECT book_id FROM books WHERE book_id = 1 AND is_deleted = false"),
            async () => (await mongo.Find(x => x.BookId == 1).Project(x => x.BookId).ToListAsync()).Count);
        await CompareAsync("Books after 2005",
            () => SqlQuery(sql, "SELECT book_id FROM books WHERE publish_year > 2005 AND is_deleted = false"),
            async () => (await mongo.Find(x => x.PublishYear > 2005).Project(x => x.BookId).ToListAsync()).Count);
        await CompareAsync("Available books",
            () => SqlQuery(sql, """
                SELECT b.book_id FROM books b WHERE b.is_deleted = false
                AND EXISTS (SELECT 1 FROM book_copies bc WHERE bc.book_id = b.book_id
                    AND bc.status = 'available' AND bc.is_deleted = false)
                """),
            async () => (await mongo.Find(x => x.AvailableCopies > 0).Project(x => x.BookId).ToListAsync()).Count);
    }

    private static async Task<int> SqlQuery(NpgsqlConnection sql, string text)
    {
        await using var cmd = new NpgsqlCommand(text, sql);
        await using var reader = await cmd.ExecuteReaderAsync();
        int n = 0; while (await reader.ReadAsync()) n++;
        return n;
    }

    private static async Task CompareAsync(string name, Func<Task<int>> sql, Func<Task<int>> mongo)
    {
        for (int i = 0; i < 10; i++) { await sql(); await mongo(); }
        var a = new List<double>(); var b = new List<double>();
        int countSql = 0, countMongo = 0;
        for (int i = 0; i < 100; i++)
        {
            if (i % 2 == 0)
            {
                var sqlResult = await MeasureAsync(sql);
                var mongoResult = await MeasureAsync(mongo);
                countSql = sqlResult.count;
                countMongo = mongoResult.count;
                a.Add(sqlResult.ms); b.Add(mongoResult.ms);
            }
            else
            {
                var mongoResult = await MeasureAsync(mongo);
                var sqlResult = await MeasureAsync(sql);
                countSql = sqlResult.count;
                countMongo = mongoResult.count;
                b.Add(mongoResult.ms); a.Add(sqlResult.ms);
            }
        }
        Console.WriteLine($"\n{name}");
        Console.WriteLine($"SQL results: {countSql}; Mongo results: {countMongo}");
        Console.WriteLine($"SQL average: {a.Average():F3} ms; Mongo average: {b.Average():F3} ms");
        Console.WriteLine($"SQL median: {Median(a):F3} ms; Mongo median: {Median(b):F3} ms");
        if (countSql != countMongo) Console.WriteLine("WARNING: Different result counts!");
    }

    private static async Task<(int count, double ms)> MeasureAsync(Func<Task<int>> query)
    {
        var sw = Stopwatch.StartNew(); int count = await query(); sw.Stop();
        return (count, sw.Elapsed.TotalMilliseconds);
    }

    private static double Median(List<double> numbers)
    {
        var sorted = numbers.OrderBy(x => x).ToArray(); int m = sorted.Length / 2;
        return sorted.Length % 2 == 0 ? (sorted[m - 1] + sorted[m]) / 2 : sorted[m];
    }
}
