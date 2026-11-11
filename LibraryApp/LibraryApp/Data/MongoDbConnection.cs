using MongoDB.Bson;
using MongoDB.Driver;

namespace LibraryApp.Data;

public static class MongoDbConnection
{
    private static readonly Lazy<MongoClient> Client = new(() =>
    {
        string uri = Environment.GetEnvironmentVariable("MONGODB_URI")
            ?? throw new InvalidOperationException("Set MONGODB_URI in user environment variables.");
        return new MongoClient(uri);
    });

    public static IMongoDatabase GetDatabase() => Client.Value.GetDatabase("library_nosql");

    public static async Task CheckConnectionAsync() =>
        await GetDatabase().RunCommandAsync<BsonDocument>(new BsonDocument("ping", 1));
}
