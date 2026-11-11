using LibraryApp.Benchmarks;
using LibraryApp.Data;
using LibraryApp.Repositories;

Console.OutputEncoding = System.Text.Encoding.UTF8;

Console.WriteLine(" LIBRARY DATABASE LAB ");
Console.WriteLine("1. Redis operations");
Console.WriteLine("2. MongoDB books");
Console.WriteLine("3. SQL vs NoSQL scalability benchmark");
Console.WriteLine("4. Import PostgreSQL books into MongoDB");
Console.WriteLine("5. SQL vs NoSQL benchmark (original library data)");
Console.WriteLine("6. Original library read-only overview");
Console.WriteLine("0. Exit");
Console.Write("Choose option: ");
string? choice = Console.ReadLine();

if (choice == "0") return;
if (choice is not ("1" or "2" or "3" or "4" or "5" or "6"))
{
    Console.WriteLine("Unknown option.");
    return;
}

try
{
    if (choice == "1")
    {
        var redis = new RedisBookRepository();
        await redis.SaveBookCountAsync(1, 5);
        await redis.SaveBookCountAsync(2, 0);
        await redis.SaveBookCountAsync(3, 8);
        Console.WriteLine("Three books saved");
        for (int id = 1; id <= 3; id++)
            Console.WriteLine($"Book {id}: {await redis.GetBookCountAsync(id)} copies");
        Console.WriteLine("Available books: " + string.Join(", ", await redis.GetAvailableBookIdsAsync()));
        await redis.SaveBookCountAsync(2, 4);
        Console.WriteLine($"Updated Book 2: {await redis.GetBookCountAsync(2)} copies");
        Console.WriteLine("Available after update: " + string.Join(", ", await redis.GetAvailableBookIdsAsync()));
        await redis.DeleteBookCountAsync(3);
        int? deleted = await redis.GetBookCountAsync(3);
        Console.WriteLine("Book 3 after delete: " + (deleted.HasValue ? deleted.Value.ToString() : "not found"));
        Console.WriteLine("Redis test completed!");
        return;
    }

    if (choice == "2")
    {
        await MongoDbConnection.CheckConnectionAsync();
        var mongo = new MongoBookRepository();
        var books = await mongo.GetAllBooksAsync();
        Console.WriteLine($"MongoDB books: {books.Count}");
        foreach (var book in books)
            Console.WriteLine($"{book.BookId} | {book.Title} | {string.Join(", ", book.Authors)} | available: {book.AvailableCopies}");
        return;
    }

    // Only options 3-6 require PostgreSQL.
    string connectionString = Environment.GetEnvironmentVariable("POSTGRES_CONNECTION_STRING")
        ?? throw new InvalidOperationException("Set POSTGRES_CONNECTION_STRING for PostgreSQL operations.");

    if (choice == "3") { await ScaleBenchmark.RunAsync(connectionString); return; }
    if (choice == "4") { await MongoBookImporter.ImportAsync(connectionString); return; }
    if (choice == "5") { await BenchmarkRunner.RunAsync(connectionString); return; }

    // Non-destructive alternative to the original issue/return sample.
    var database = new DatabaseConnection(connectionString);
    var unitOfWork = new UnitOfWork(database);
    Console.WriteLine("Available books:");
    foreach (var book in await unitOfWork.Books.GetAvailableBooksAsync())
        Console.WriteLine($"{book.BookId} | {book.Title} | {book.InventoryNumber} | {book.BranchName}");
    Console.WriteLine("Active issues:");
    foreach (var issue in await unitOfWork.Issues.GetActiveIssuesAsync())
        Console.WriteLine($"{issue.IssueId} | {issue.FirstName} {issue.LastName} | {issue.Title} | {issue.Status}");
    Console.WriteLine("Reader fines:");
    foreach (var fine in await unitOfWork.ReaderFines.GetReaderFinesAsync())
        Console.WriteLine($"{fine.FineId} | {fine.FirstName} {fine.LastName} | {fine.Amount} | {fine.Status}");
}
catch (Exception ex)
{
    Console.Error.WriteLine($"Operation failed: {ex.Message}");
    Environment.ExitCode = 1;
}
