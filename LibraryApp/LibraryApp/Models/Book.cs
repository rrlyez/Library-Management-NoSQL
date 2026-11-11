using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibraryApp.Models
{
    public class Book
    {
        public int BookId { get; set; }
        public string Title { get; set; }
        public int CopyId { get; set; }
        public string InventoryNumber { get; set; }
        public string BranchName { get; set; }
    }
}
