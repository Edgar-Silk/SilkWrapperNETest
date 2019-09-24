using System;
using System.Text.RegularExpressions;
using System.Runtime.InteropServices;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using SilkWrapperNET;

namespace SilkWrapperNETest {
  class Program {

    public static PDF P = new PDF();
    static void Main(string[] args) {

      Console.WriteLine("Initializing Library...");

      //Native.FPDF_InitLibrary();

      string File = "C:/projects/silkwrappernetest/test.pdf";

      Console.WriteLine("\nOpen PDF file in: " + File);

      //IntPtr doc = Native.FPDF_LoadDocument(File, null);
      PDF.Load(File);

      Console.WriteLine("\nNumber of Pages:" + PDF.PageCount().ToString());

      var inf = PDF.GetInformation();
      Console.WriteLine("\nCreator: " + inf.Creator);
      Console.WriteLine("\nTitle: " + inf.Title);
      Console.WriteLine("\nAuthor: " + inf.Author);
      Console.WriteLine("\nSubject: " + inf.Subject);
      Console.WriteLine("\nKeywords: " + inf.Keywords);
      Console.WriteLine("\nProducer: " + inf.Producer);
      Console.WriteLine("\nCreationDate: " + inf.CreationDate);
      Console.WriteLine("\nModDate: " + inf.ModificationDate);
      
      Console.WriteLine("\nDestroying library...");

      
      Console.ReadKey();

    }
  }
}
