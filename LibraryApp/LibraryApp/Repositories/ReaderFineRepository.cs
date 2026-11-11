using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using LibraryApp.Data;
using LibraryApp.Models;

namespace LibraryApp.Repositories
{
    public class ReaderFineRepository : IReaderFineRepository
    {
        private readonly DatabaseConnection _database;

        public ReaderFineRepository(DatabaseConnection database)
        {
            _database = database;
        }

        public async Task<List<ReaderFine>> GetReaderFinesAsync()
        {
            var fines = new List<ReaderFine>();

            await using var connection = _database.CreateConnection();
            await connection.OpenAsync();

            await using var command = connection.CreateCommand();
            command.CommandText = "SELECT * FROM reader_fines";

            await using var reader = await command.ExecuteReaderAsync();

            while (await reader.ReadAsync())
            {
                fines.Add(new ReaderFine
                {
                    FineId = reader.GetInt32(reader.GetOrdinal("fine_id")),
                    ReaderId = reader.GetInt32(reader.GetOrdinal("reader_id")),
                    FirstName = reader.GetString(reader.GetOrdinal("first_name")),
                    LastName = reader.GetString(reader.GetOrdinal("last_name")),
                    Amount = reader.GetDecimal(reader.GetOrdinal("amount")),
                    Reason = reader.IsDBNull(reader.GetOrdinal("reason"))
                        ? ""
                        : reader.GetString(reader.GetOrdinal("reason")),
                    Status = reader.GetString(reader.GetOrdinal("status"))
                });
            }

            return fines;
        }
    }
}
