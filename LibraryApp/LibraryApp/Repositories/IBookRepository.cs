using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using LibraryApp.Models;

namespace LibraryApp.Repositories
{
    public interface IBookRepository
    {
        Task<List<Book>> GetAvailableBooksAsync();
    }
}
