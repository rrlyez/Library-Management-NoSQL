using System.Diagnostics;
using LibraryApp.Data;
using MongoDB.Bson;
using MongoDB.Driver;
using Npgsql;

namespace LibraryApp.Benchmarks;

public static class ScaleBenchmark
{
    public static async Task RunAsync(string connectionString)
    {
        foreach (int size in new[] { 1000, 10000, 30000 })
        {
            Console.WriteLine($"\n {size} BOOKS ");
            await DataGenerator.GenerateAsync(connectionString, size);
            await using var sql = new NpgsqlConnection(connectionString);
            await sql.OpenAsync();
            var mongo = MongoDbConnection.GetDatabase().GetCollection<BsonDocument>("benchmark_books");
            await CompareAsync("Search by ID",
                () => SqlCountAsync(sql, "SELECT COUNT(*) FROM benchmark_books WHERE book_id = 1"),
                () => mongo.CountDocumentsAsync(Builders<BsonDocument>.Filter.Eq("book_id", 1)));
            await CompareAsync("Books after 2005",
                () => SqlCountAsync(sql, "SELECT COUNT(*) FROM benchmark_books WHERE publish_year > 2005"),
                () => mongo.CountDocumentsAsync(Builders<BsonDocument>.Filter.Gt("publish_year", 2005)));
            await CompareAsync("Available books",
                () => SqlCountAsync(sql, "SELECT COUNT(*) FROM benchmark_books WHERE available_copies > 0"),
                () => mongo.CountDocumentsAsync(Builders<BsonDocument>.Filter.Gt("available_copies", 0)));
        }
        Console.WriteLine("\nALL BENCHMARKS COMPLETED!");
    }

    private static async Task<long> SqlCountAsync(NpgsqlConnection sql, string query)
    {
        await using var cmd = new NpgsqlCommand(query, sql);
        return Convert.ToInt64(await cmd.ExecuteScalarAsync());
    }

    private static async Task CompareAsync(string name, Func<Task<long>> sql, Func<Task<long>> mongo)
    {
        const int warmups = 5, repetitions = 30;
        for (int i = 0; i < warmups; i++) { await sql(); await mongo(); }
        var a = new List<double>(); var b = new List<double>();
        long countSql = 0, countMongo = 0;
        for (int i = 0; i < repetitions; i++)
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

    private static async Task<(long count, double ms)> MeasureAsync(Func<Task<long>> query)
    {
        var sw = Stopwatch.StartNew(); long count = await query(); sw.Stop();
        return (count, sw.Elapsed.TotalMilliseconds);
    }

    private static double Median(List<double> numbers)
    {
        var sorted = numbers.OrderBy(x => x).ToArray(); int m = sorted.Length / 2;
        return sorted.Length % 2 == 0 ? (sorted[m - 1] + sorted[m]) / 2 : sorted[m];
    }
}
