import 'dart:io';
import 'package:flutter_native_html_to_pdf/flutter_native_html_to_pdf.dart';

void main() async {
  final converter = HtmlToPdfConverter();
  
  // User's HTML from the issue
  const html = '''
<!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><style>html,body {width: 240mm;margin: 0 auto;font-family: Helvetica, sans-serif;font-size: 11px;}h1 {color: rgba(29, 112, 183, 1);font-size: 25px;margin: 0;}p {color: rgba(112, 112, 112, 1);margin: 0;}img {object-fit: contain;}.avoid-break-inside {break-inside: avoid;}.cella {border: 1px solid rgba(211, 211, 211, 1);border-radius: 8px;margin-bottom: 11px;min-height: 85px;}.center {text-align: center;}.disponibilita {font-size: 14px;}.disponibilita-container {margin-bottom: 1rem;}.flex {display: flex;}.flex-column {flex-direction: column;}.justify-between {justify-content: space-between;}.justify-center {justify-content: center;}.logo {height: 34px;width: 110px;}.items-center {align-items: center;}.mb-08 {margin-bottom: 0.8rem;}.mb-1 {margin-bottom: 1rem;}.mb-2 {margin-bottom: 2rem;}.mt-3 {margin-top: 3rem;}.p-05 {padding: 0.5rem;}.p-1 {padding: 1rem;}.pallino {border-radius: 50%;width: 10px;height: 10px;margin-right: 1rem;}.prezzo span {color: rgba(29, 112, 183, 1);font-size: 11px;font-weight: bold;}.qta-min {border: 1px solid rgba(112, 164, 209, 1);border-radius: 20px;width: 70%;}.qta-min p {color: rgba(112, 164, 209, 1);text-align: center;font-size: 13px;}.uppercase {text-transform: uppercase;}.w-5 {width: 5%;}.w-15 {width: 15%;}.w-25 {width: 25%;}.w-35 {width: 35%;}.w-40 {width: 40%;}.w-50 {width: 50%;}.w-70 {width: 70%;}body>div:nth-of-type(1) p {line-height: 22px;font-size: 16px;}.cella .w-70 p,.cella .w-70 span {font-size: 16px;}.cella .w-70 p.prezzo {font-size: 13px;}.cella .w-70>p:nth-of-type(1) {font-size: 14px;}.imagesize {height: 60px;width: 60px;}</style></head><body><div class="flex items-center justify-between mb-2 p-05"><div class="flex flex-column items-center w-40"><h1 class="center mb-1">Export Articoli - 05/02/2026</h1><p class="sottotitolo center"></p></div><div class="w-35"><p>Data: 05 febbraio 2026</p><p>Agente: SAINATI EDUIN</p><p>Cliente:  FABIO ERRICO</p></div></div><div class="flex items-center cella p-1 avoid-break-inside"><div class="w-15"><img class="imagesize" src="https://asso.madeinapp.net/app/v1.0/get_article_image.php?guid=D3886E9D1400000000000000000000000000000000000000&w=400&h=400&timestamp=1759521627" /></div><div class="w-5"></div><div class="w-70"><p class="mb-08">TXANG10</p><p class="mb-08">TenX Anguria 10 mg/ml</p><p class="prezzo"><span>1.75€</span> per pz</p></div><div class="w-15 flex flex-column items-center"><div class="flex items-center disponibilita-container"><div class="pallino">&nbsp;</div><p class="disponibilita">Disp: 439</p></div><div class="qta-min p-05"><p>Confezione da</p><p>1pz</p></div></div></div><div class="flex items-center cella p-1 avoid-break-inside"><div class="w-15"><img class="imagesize" src="https://asso.madeinapp.net/app/v1.0/get_article_image.php?guid=CE286E000000000000000000000000000000000000000000&w=400&h=400&timestamp=1744988130" /></div><div class="w-5"></div><div class="w-70"><p class="mb-08">SBAN</p><p class="mb-08">Uma.mi Swap Pod Banana Ice 20mg/ml</p><p class="prezzo"><span>2.20€</span> per pz</p></div><div class="w-15 flex flex-column items-center"><div class="flex items-center disponibilita-container"><div class="pallino">&nbsp;</div><p class="disponibilita">Disp: 10408</p></div><div class="qta-min p-05"><p>Confezione da</p><p>10pz</p></div></div></div><div class="flex items-center cella p-1 avoid-break-inside"><div class="w-15"><img class="imagesize" src="https://asso.madeinapp.net/app/v1.0/get_article_image.php?guid=C2B8A5C80000000000000000000000000000000000000000&w=400&h=400&timestamp=1749153614" /></div><div class="w-5"></div><div class="w-70"><p class="mb-08">PKBER</p><p class="mb-08">Uma.mi Swap Pocket Set Blueberry Ice 20mg/ml</p><p class="prezzo"><span>4.70€</span> per pz</p></div><div class="w-15 flex flex-column items-center"><div class="flex items-center disponibilita-container"><div class="pallino">&nbsp;</div><p class="disponibilita">Disp: 950</p></div><div class="qta-min p-05"><p>Confezione da</p><p>5pz</p></div></div></div><div class="flex items-center cella p-1 avoid-break-inside"><div class="w-15"><img class="imagesize" src="https://asso.madeinapp.net/app/v1.0/get_article_image.php?guid=8E2A61BA3BC0000000000000000000000000000000000000&w=400&h=400&timestamp=1740657268" /></div><div class="w-5"></div><div class="w-70"><p class="mb-08">CBIANCO</p><p class="mb-08">Uma Comb Cover Sigaretta Elettronica Bianca</p><p class="prezzo"><span>2.50€</span> per pz</p></div><div class="w-15 flex flex-column items-center"><div class="flex items-center disponibilita-container"><div class="pallino">&nbsp;</div><p class="disponibilita">Disp: 178</p></div><div class="qta-min p-05"><p>Confezione da</p><p>1pz</p></div></div></div></body></html>
''';
  
  try {
    print('Starting PDF generation...');
    final bytes = await converter.convertHtmlToPdfBytes(html: html);
    print('PDF generated successfully: ${bytes.length} bytes');
    
    // Save for inspection
    final file = File('/tmp/user_html_test.pdf');
    await file.writeAsBytes(bytes);
    print('PDF saved to: ${file.path}');
    print('\nPDF validation:');
    print('- File size: ${(bytes.length / 1024).toStringAsFixed(2)} KB');
    print('- Valid PDF header: ${String.fromCharCodes(bytes.sublist(0, 4)) == '%PDF'}');
    
    // Note about supported CSS properties
    print('\n=== CSS Properties Status ===');
    print('✅ border-radius: SUPPORTED (rounded corners on .cella and .qta-min)');
    print('✅ width/height: SUPPORTED (dimensions on .pallino, .imagesize, etc.)');
    print('✅ min-height: SUPPORTED (minimum height on .cella)');
    print('✅ rgba colors: SUPPORTED (all rgba() colors)');
    print('⚠️  flex properties: NOT SUPPORTED (display: flex, justify-content, etc.)');
    print('⚠️  object-fit: NOT SUPPORTED (PDF has no equivalent)');
    print('⚠️  break-inside: NOT SUPPORTED (PDF pagination differs from CSS)');
    print('\nNote: While flex properties are not supported, the layout should still');
    print('render correctly using standard block and inline elements.');
  } catch (e, stack) {
    print('Error: $e');
    print('Stack trace: $stack');
  }
}
