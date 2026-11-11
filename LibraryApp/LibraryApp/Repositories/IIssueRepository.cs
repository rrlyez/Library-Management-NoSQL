using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using LibraryApp.Models;

namespace LibraryApp.Repositories
{
    public interface IIssueRepository
    {
        Task<List<Issue>> GetActiveIssuesAsync();

        Task IssueBookAsync(
            int copyId,
            int readerId,
            int employeeId,
            DateTime dueDate,
            int updatedBy);

        Task ReturnBookAsync(
            int issueId,
            int updatedBy);
    }
}
