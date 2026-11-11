using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using LibraryApp.Data;
using LibraryApp.Models;

namespace LibraryApp.Repositories
{
    public class BookRepository : IBookRepository
    {
        private readonly DatabaseConnection _database;

        public BookRepository(DatabaseConnection database)
        {
            _database = database;
        }

        public async Task<List<Book>> GetAvailableBooksAsync()
        {
            var books = new List<Book>();

            await using var connection = _database.CreateConnection();
            await connection.OpenAsync();

            await using var command = connection.CreateCommand();
            command.CommandText = "SELECT * FROM available_books";

            await using var reader = await command.ExecuteReaderAsync();

            while (await reader.ReadAsync())
            {
                books.Add(new Book
                {
                    BookId = reader.GetInt32(reader.GetOrdinal("book_id")),
                    Title = reader.GetString(reader.GetOrdinal("title")),
                    CopyId = reader.GetInt32(reader.GetOrdinal("copy_id")),
                    InventoryNumber = reader.GetString(reader.GetOrdinal("inventory_number")),
                    BranchName = reader.GetString(reader.GetOrdinal("branch_name"))
                });
            }

            return books;
        }
    }
}