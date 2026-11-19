/// Text for the PDFs, which use the built-in Helvetica font: it has no rupee glyph (the sign shows as a
/// crossed box), so the symbol is written as "Rs." everywhere in a PDF.
String pdfSafeText(String? text) =>
    (text ?? '').replaceAll('₹', 'Rs. ').replaceAll('Rs.  ', 'Rs. ');
