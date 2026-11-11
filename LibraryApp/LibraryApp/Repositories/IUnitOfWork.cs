using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibraryApp.Repositories
{
    public interface IUnitOfWork
    {
        IBookRepository Books { get; }
        IIssueRepository Issues { get; }
        IReaderFineRepository ReaderFines { get; }
    }
}
