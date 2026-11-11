using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace LibraryApp.Models;

public class MongoBook
{
    [BsonId] public ObjectId Id { get; set; }
    [BsonElement("book_id")] public int BookId { get; set; }
    [BsonElement("title")] public string Title { get; set; } = "";
    [BsonElement("isbn")] public string Isbn { get; set; } = "";
    [BsonElement("publish_year")] public int? PublishYear { get; set; }
    [BsonElement("publisher")] public string Publisher { get; set; } = "";
    [BsonElement("authors")] public List<string> Authors { get; set; } = new();
    [BsonElement("genres")] public List<string> Genres { get; set; } = new();
    [BsonElement("available_copies")] public int AvailableCopies { get; set; }
}
