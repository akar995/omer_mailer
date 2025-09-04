import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:number_to_text_converter/number_to_text_converter.dart';

/// Generates a single-page invoice styled like the Control Risk sample.
Future<Uint8List> generateControlRiskInvoicePdf({
  // Header
  required String invoiceDate, // e.g. 08/05/2025
  required String invoiceNo, // e.g. RE125298

  // Table row (single record)
  required String product, // AIR / HOTEL / VISA / CAR
  required String supplierName, // e.g. IRAQI AIRWAYS
  required String ticketOrVoucherNo, // e.g. 732406901501
  required String ticketIssuedDate, // e.g. 07/01/2025
  required String airlinePNR, // e.g. 8DJNZ6
  required String passengerName, // e.g. JOSEPH NORTHALL
  required String internalInvoiceNo, // e.g. RE125298
  required String className, // e.g. ECONOMY
  required String departureDate, // e.g. 24/06/2025
  required String returnDate, // e.g.  -  or 30/06/2025
  required String routing, // e.g. BSR/EBL
  required String checkIn, // hotel only / otherwise '-'
  required String checkOut, // hotel only / otherwise '-'
  required String bookedBy, // e.g. Manigandan
  required String projectCode, // e.g. 67000351.01
  required String locationCode, // e.g.  -
  required String reservationType, // e.g. Billable / Non-Billable
  required String reasonForTravel, // e.g. Rotational

  // Money
  required num amountNumeric, // 109.00
  String? amountCurrency, // default USD
  String? amountInWords, // if null, auto-generated in English

  // Footer blocks
  required String billTo, // e.g. CONTROL RISK
  required String invoiceMonthLabel, // e.g. JUL-2025

  // Company Details
  String companyTitle = 'London Sky Company For Selling Flight Tickets Limited',
  String companyAddress = 'Minra, Zaza Street, Erbil, Iraq',
  String companyPhone = '+964 [0] 7518108782',
  String companyEmail = 'accounts@londonskyco.com',
  // Bank
  String bankAccountName = 'LONDON SKY FOR TICKETING LIMITED',
  String bankAccountNo = '0368-631202-010',
  String bankIban = 'IQ74 BBAC 0013 6863 1202 010',
  String bankSwift = 'BBACIQBA',
  String bankName = 'BBAC s.a.l',
  String bankAddress =
      'BBAC s.a.l., Erbil branch, 60 M Street, End of Iskan Tunnel',
}) async {
  var converter = NumberToTextConverter.forInternationalNumberingSystem();

  final pdf = pw.Document(title: 'Invoice $invoiceNo');

  // Assets
  final logo = pw.MemoryImage(
    (await rootBundle.load('assets/images/london_sky_logo_new.jpg'))
        .buffer
        .asUint8List(),
  );

  // Helpers
  String money(num v, {String cur = 'USD'}) {
    final s = v.toStringAsFixed(2);
    return cur == 'USD' ? '\$$s' : '$s $cur';
  }

  String upper(String s) => s.toUpperCase();

  String amountWords = (amountInWords ??
          _amountToWordsUSD(amountNumeric).toUpperCase() + ' ONLY')
      .toUpperCase();

  final cur = amountCurrency ?? 'USD';

  // Layout helpers
  pw.TextStyle t({
    double size = 9,
    bool bold = false,
    PdfColor? color,
  }) =>
      pw.TextStyle(
        fontSize: size,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: color,
      );

  double gap(double v) => v;

  final headers = <String>[
    'Product',
    'Airline/Hotel/Visa/Car',
    'Ticket No / Voucher No',
    'Ticket issued date',
    'Airline PNR',
    'Passenger Name',
    'Invoiceno.',
    'Invoiceamount',
    'CLASS',
    'Departure Date',
    'RETURN DATE',
    'Routing',
    'Check-in',
    'Check-out',
    'Booked by',
    'Project Code',
    'Location Code',
    'Reservation Type',
    'Reason for travel',
  ];

  final rowValues = <String>[
    product,
    supplierName,
    ticketOrVoucherNo,
    ticketIssuedDate,
    airlinePNR,
    passengerName,
    internalInvoiceNo,
    money(amountNumeric, cur: cur),
    className,
    departureDate,
    returnDate,
    routing,
    checkIn,
    checkOut,
    bookedBy,
    projectCode,
    locationCode,
    reservationType,
    reasonForTravel,
  ];

  // Column widths — tuned to fit one line
  final colWidths = <int, pw.TableColumnWidth>{
    0: const pw.FlexColumnWidth(9),
    1: const pw.FlexColumnWidth(18),
    2: const pw.FlexColumnWidth(16),
    3: const pw.FlexColumnWidth(14),
    4: const pw.FlexColumnWidth(12),
    5: const pw.FlexColumnWidth(18),
    6: const pw.FlexColumnWidth(14),
    7: const pw.FlexColumnWidth(13),
    8: const pw.FlexColumnWidth(12),
    9: const pw.FlexColumnWidth(16),
    10: const pw.FlexColumnWidth(16),
    11: const pw.FlexColumnWidth(14),
    12: const pw.FlexColumnWidth(12),
    13: const pw.FlexColumnWidth(12),
    14: const pw.FlexColumnWidth(14),
    15: const pw.FlexColumnWidth(16),
    16: const pw.FlexColumnWidth(12),
    17: const pw.FlexColumnWidth(16),
    18: const pw.FlexColumnWidth(16),
  };

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat(
        1000 * 1.4142857143,
        1000,
      ),
      orientation: pw.PageOrientation.landscape,
      margin: const pw.EdgeInsets.fromLTRB(16, 14, 16, 14),
      build: (ctx) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // Header: logo + right meta
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 120,
                  height: 120,
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Image(logo, fit: pw.BoxFit.contain),
                ),
                pw.Spacer(),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    _kv('Invoice Date', invoiceDate, t),
                    _kv('Invoice No', invoiceNo, t),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: gap(6)),

            // Blue bar of headers

            // Table (1 row)

            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.4),
              defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
              columnWidths: colWidths,
              children: [
                pw.TableRow(
                  verticalAlignment: pw.TableCellVerticalAlignment.full,
                  decoration:
                      pw.BoxDecoration(color: PdfColor.fromHex('08b8f4')),
                  children: List.generate(headers.length, (i) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      child: pw.Text(
                        headers[i],
                        style: t(size: 5, color: PdfColors.black, bold: true),
                        textAlign: pw.TextAlign.center,
                      ),
                    );
                  }),
                ),
                pw.TableRow(
                  children: List.generate(headers.length, (i) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      child: pw.Text(
                        rowValues[i],
                        style: t(size: 8.5, bold: true),
                        textAlign: pw.TextAlign.center,
                      ),
                    );
                  }),
                ),
              ],
            ),

            // Summary (right-aligned mini-table with two rows)
            // pw.SizedBox(height: gap(6)),
            pw.Row(
              children: [
                // pw.Expanded(child: pw.SizedBox()),
                pw.SizedBox(
                  width: 583,
                  child: pw.Table(
                    border:
                        pw.TableBorder.all(color: PdfColors.black, width: 0.4),
                    columnWidths: const {
                      0: pw.FlexColumnWidth(7.8),
                      1: pw.FlexColumnWidth(1),
                    },
                    children: [
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                                converter.convert(amountNumeric.toInt()),
                                style: t(size: 9),
                                textAlign: pw.TextAlign.center),
                          ),
                          pw.Container(
                              decoration: pw.BoxDecoration(
                                  color: PdfColor.fromHex('c0d4ec')),
                              child: _cellRight(
                                  money(amountNumeric, cur: cur), t(size: 9))),
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),

            pw.SizedBox(height: gap(10)),

            // Lower area
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Left: Company + Bank
                pw.Expanded(
                  flex: 6,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Company Details',
                          style: t(size: 10, bold: true)),
                      pw.SizedBox(height: 4),
                      pw.Text(companyTitle, style: t(size: 9)),
                      pw.Text('Address: $companyAddress', style: t(size: 9)),
                      pw.Text('Phone Number: $companyPhone', style: t(size: 9)),
                      pw.Text('Email:$companyEmail', style: t(size: 9)),
                      pw.SizedBox(height: gap(10)),
                      pw.Text('Bank Details', style: t(size: 10, bold: true)),
                      pw.SizedBox(height: 4),
                      pw.Text('Account Name:- $bankAccountName',
                          style: t(size: 9)),
                      pw.Text('Account No:- $bankAccountNo', style: t(size: 9)),
                      pw.Text('IBAN Number: $bankIban', style: t(size: 9)),
                      pw.Text('Swift Code: $bankSwift', style: t(size: 9)),
                      pw.Text('Bank Name:-$bankName', style: t(size: 9)),
                      pw.Text('Bank Adress:$bankAddress', style: t(size: 9)),
                    ],
                  ),
                ),

                pw.SizedBox(width: 12),

                // Right: Stamp-like area
                pw.Expanded(
                  flex: 5,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.only(right: 8),
                    alignment: pw.Alignment.topRight,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          upper(
                              'LONDON SKY COMPANY FOR SELLING FLIGHT TICKETS /LIMITED'),
                          style: t(size: 10, bold: true),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text(
                          upper('ERBIL, IRAQ'),
                          style: t(size: 10, bold: true),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.SizedBox(height: 16),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Text('TO :  ', style: t(size: 10, bold: true)),
                            pw.Text(upper(billTo), style: t(size: 10)),
                          ],
                        ),
                        pw.SizedBox(height: 16),
                        pw.Text(
                          amountWords,
                          style: t(size: 10, bold: true),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.SizedBox(height: 16),
                        pw.Text(
                          'Invoice Of $invoiceMonthLabel',
                          style: t(size: 11, bold: true),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );

  return pdf.save();
}

pw.Widget _kv(
  String k,
  String v,
  pw.TextStyle Function({double size, bool bold, PdfColor? color}) t,
) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 2),
    child: pw.Row(
      children: [
        pw.Text('$k: ', style: t(size: 10, bold: true)),
        pw.Text(v, style: t(size: 10)),
      ],
    ),
  );
}

pw.Widget _cellRight(String s, pw.TextStyle style) => pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(s, style: style),
      ),
    );

/// Small English number-to-words for USD whole amounts.
String _amountToWordsUSD(num amount) {
  final n = amount.round();
  if (n == 0) return 'ZERO DOLLARS';
  final units = [
    '',
    'ONE',
    'TWO',
    'THREE',
    'FOUR',
    'FIVE',
    'SIX',
    'SEVEN',
    'EIGHT',
    'NINE',
    'TEN',
    'ELEVEN',
    'TWELVE',
    'THIRTEEN',
    'FOURTEEN',
    'FIFTEEN',
    'SIXTEEN',
    'SEVENTEEN',
    'EIGHTEEN',
    'NINETEEN'
  ];
  final tens = [
    '',
    '',
    'TWENTY',
    'THIRTY',
    'FORTY',
    'FIFTY',
    'SIXTY',
    'SEVENTY',
    'EIGHTY',
    'NINETY'
  ];

  String belowThousand(int x) {
    final h = x ~/ 100;
    final r = x % 100;
    final b = StringBuffer();
    if (h > 0) {
      b.write('${units[h]} HUNDRED');
      if (r > 0) b.write(' ');
    }
    if (r > 0) {
      if (r < 20) {
        b.write(units[r]);
      } else {
        final t = r ~/ 10;
        final u = r % 10;
        b.write(tens[t]);
        if (u > 0) b.write('-${units[u]}');
      }
    }
    return b.toString();
  }

  final parts = <String>[];
  int billions = n ~/ 1000000000;
  int millions = (n ~/ 1000000) % 1000;
  int thousands = (n ~/ 1000) % 1000;
  int rest = n % 1000;

  if (billions > 0) parts.add('${belowThousand(billions)} BILLION');
  if (millions > 0) parts.add('${belowThousand(millions)} MILLION');
  if (thousands > 0) parts.add('${belowThousand(thousands)} THOUSAND');
  if (rest > 0) parts.add(belowThousand(rest));

  return '${parts.join(' ')} DOLLARS';
}
