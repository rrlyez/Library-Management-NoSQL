using StackExchange.Redis;

namespace LibraryApp.Data;

public static class RedisConnection
{
    private static readonly Lazy<Task<ConnectionMultiplexer>> Connection = new(async () =>
    {
        string host = Environment.GetEnvironmentVariable("REDIS_HOST")
            ?? throw new InvalidOperationException("Set REDIS_HOST.");
        string password = Environment.GetEnvironmentVariable("REDIS_PASSWORD")
            ?? throw new InvalidOperationException("Set REDIS_PASSWORD.");
        int port = int.TryParse(Environment.GetEnvironmentVariable("REDIS_PORT"), out var p) ? p : 12211;
        var options = new ConfigurationOptions
        {
            User = "default", Password = password,
            Ssl = string.Equals(Environment.GetEnvironmentVariable("REDIS_SSL"), "true", StringComparison.OrdinalIgnoreCase),
            AbortOnConnectFail = false, ConnectTimeout = 10000
        };
        options.EndPoints.Add(host, port);
        return await ConnectionMultiplexer.ConnectAsync(options);
    });

    public static async Task<IDatabase> GetDatabaseAsync() => (await Connection.Value).GetDatabase();
}
