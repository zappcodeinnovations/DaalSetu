/// Text for the PDFs, which use the built-in Helvetica font: it has no rupee glyph or
/// extended Unicode support, so special characters are mapped to safe ASCII equivalents.
String pdfSafeText(String? text) {
  if (text == null || text.isEmpty) return '';
  return text
      .replaceAll('₹', 'Rs. ')
      .replaceAll('Rs.  ', 'Rs. ')
      .replaceAll('—', '-') // em-dash
      .replaceAll('–', '-') // en-dash
      .replaceAll('’', "'")
      .replaceAll('‘', "'")
      .replaceAll('“', '"')
      .replaceAll('”', '"')
      .replaceAll('…', '...')
      .replaceAll('•', '*');
}
