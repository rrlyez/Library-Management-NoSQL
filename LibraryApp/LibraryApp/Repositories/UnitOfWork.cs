using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using LibraryApp.Data;

namespace LibraryApp.Repositories
{
    public class UnitOfWork : IUnitOfWork
    {
        public IBookRepository Books { get; }
        public IIssueRepository Issues { get; }
        public IReaderFineRepository ReaderFines { get; }

        public UnitOfWork(DatabaseConnection database)
        {
            Books = new BookRepository(database);
            Issues = new IssueRepository(database);
            ReaderFines = new ReaderFineRepository(database);
        }
    }
}