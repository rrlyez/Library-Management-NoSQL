using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using LibraryApp.Data;
using LibraryApp.Models;
using Npgsql;

namespace LibraryApp.Repositories
{
    public class IssueRepository : IIssueRepository
    {
        private readonly DatabaseConnection _database;

        public IssueRepository(DatabaseConnection database)
        {
            _database = database;
        }

        public async Task<List<Issue>> GetActiveIssuesAsync()
        {
            var issues = new List<Issue>();

            await using var connection = _database.CreateConnection();
            await connection.OpenAsync();

            await using var command = connection.CreateCommand();
            command.CommandText = "SELECT * FROM active_issues";

            await using var reader = await command.ExecuteReaderAsync();

            while (await reader.ReadAsync())
            {
                issues.Add(new Issue
                {
                    IssueId = reader.GetInt32(reader.GetOrdinal("issue_id")),
                    FirstName = reader.GetString(reader.GetOrdinal("first_name")),
                    LastName = reader.GetString(reader.GetOrdinal("last_name")),
                    Title = reader.GetString(reader.GetOrdinal("title")),
                    IssueDate = reader.GetDateTime(reader.GetOrdinal("issue_date")),
                    DueDate = reader.GetDateTime(reader.GetOrdinal("due_date")),
                    Status = reader.GetString(reader.GetOrdinal("status"))
                });
            }

            return issues;
        }

        public async Task IssueBookAsync(
            int copyId,
            int readerId,
            int employeeId,
            DateTime dueDate,
            int updatedBy)
        {
            await using var connection = _database.CreateConnection();
            await connection.OpenAsync();

            await using var command = connection.CreateCommand();
            command.CommandText = "CALL issue_book(@copy_id, @reader_id, @employee_id, @due_date, @updated_by)";

            command.Parameters.AddWithValue("copy_id", copyId);
            command.Parameters.AddWithValue("reader_id", readerId);
            command.Parameters.AddWithValue("employee_id", employeeId);
            command.Parameters.AddWithValue(
                "due_date",
                NpgsqlTypes.NpgsqlDbType.Date,
                dueDate.Date);
            command.Parameters.AddWithValue("updated_by", updatedBy);

            await command.ExecuteNonQueryAsync();
        }

        public async Task ReturnBookAsync(int issueId, int updatedBy)
        {
            await using var connection = _database.CreateConnection();
            await connection.OpenAsync();

            await using var command = connection.CreateCommand();
            command.CommandText = "CALL return_book(@issue_id, @updated_by)";

            command.Parameters.AddWithValue("issue_id", issueId);
            command.Parameters.AddWithValue("updated_by", updatedBy);

            await command.ExecuteNonQueryAsync();
        }
    }
}
