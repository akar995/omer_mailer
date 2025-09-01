
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'pdf_tab.dart' show InvoiceSegmentData, InvoiceHotelData;

/// Compact, single-page PDF that preserves your original table structure.
/// Only reduces margins/paddings/font sizes (no FittedBox, no structure change).
Future<Uint8List> generateInvoicePdfV2({
  InvoiceHotelData? hotelData,
  required PdfPageFormat format, // <— fixed: no pw. prefix
  required List<InvoiceSegmentData> invoices,
  required String invoiceNo,
  required String date,
  required String dateOfSupply,
  required String costCenter,
  required String employeeId,
  required String businessUnit,
  required String bookedBy,
  required String bookedNo,
  required String passengerName,
  required String approver,
  required String firstPrice, // Ex VAT (fare)
  required String commission, // Commission
  required String airlineCarrierTaxes, // Airline taxes (editable)
  required String serviceFee, // Service fee (editable)
  required String total, // ignored; recomputed below
  required String ticketNumber,
  required String co2e,
  required String travelType,
  required bool changeInvoiceText,
  required bool useNewCompanyAddress,
  required bool useAltCustomerBlock,
}) async {
  final doc = pw.Document(title: 'Invoice', author: 'London Sky');

  // assets
  final logo = pw.MemoryImage(
    (await rootBundle.load('assets/images/london_sky_logo_new.jpg'))
        .buffer
        .asUint8List(),
  );

  // numeric parsing & totals
  num n(String v) => num.tryParse(v.replaceAll(',', '').trim()) ?? 0;
  final num fare = n(firstPrice);
  final num comm = n(commission);
  final num taxes = n(airlineCarrierTaxes);
  final num svc = n(serviceFee);
  final num grandTotal = fare + comm + taxes + svc;

  // adaptive compactness (keeps structure, just tightens)
  final segCount = invoices.length;
  final double scale = () {
    if (segCount <= 2) return 1.00;
    if (segCount <= 4) return 0.96;
    if (segCount <= 6) return 0.93;
    if (segCount <= 8) return 0.90;
    if (segCount <= 10) return 0.88;
    return 0.85; // dense cases
  }();

  pw.TextStyle t({
    double size = 10,
    bool bold = false,
    PdfColor? color,
  }) =>
      pw.TextStyle(
        fontSize: size * scale,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: color,
      );

  double gap(double v) => v * scale;

  // address / customer blocks — store as strings, then map to styled Text
  final List<String> companyAddressLines = useNewCompanyAddress
      ? [
          "London Sky Company",
          "Bakhtiari St. 98, 44001 - Erbil, Iraq",
          "Tel No. +964 750 696 3383",
        ]
      : [
          "London Sky Company for selling Flight Tickets/Limited",
          "London sky Building",
          "Zaza Street-Near 30 Meter Road Erbil_Iraq",
          "Tel No.964 7518108782",
        ];

  final List<String> customerBlockLines = useAltCustomerBlock
      ? [
          "DMG- Kentech Global DMCC",
          "Swiss office 2510 cluster Y",
          "JLT Dubai 27062",
          "Dubai",
          "United Arab Emirates",
          "TRN No:100562490100003",
          "Customer Account KNTCHGLAE",
        ]
      : [
          "Kentech Gulf Holdings Limited Iraq Branch",
          "Building No.106",
          "Al Kindi Street",
          "M213, Al Harithiya",
          "BAGHDAD",
          "IRAQ",
        ];

  // page
  const double margin = 18; // tighter than default, still print-safe

  doc.addPage(
    pw.Page(
      pageFormat: format, // honor the preview-provided format
      margin: const pw.EdgeInsets.all(margin),
      build: (ctx) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // HEADER (logo + address)
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Container(
                  margin: pw.EdgeInsets.only(top: gap(2)),
                  child:
                      pw.Image(logo, width: 150 * scale, height: 150 * scale),
                ),
                pw.Padding(
                  padding: pw.EdgeInsets.only(top: gap(4)),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: companyAddressLines
                        .map((line) => pw.Text(line, style: t(size: 10)))
                        .toList(),
                  ),
                ),
              ],
            ),

            // Title
            pw.SizedBox(height: gap(6)),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                changeInvoiceText ? "Credit Note" : "Tax Invoice",
                style: t(size: 12, bold: true),
              ),
            ),

            // CUSTOMER + META
            pw.SizedBox(height: gap(6)),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: pw.EdgeInsets.only(right: gap(16)),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: customerBlockLines
                          .map((line) => pw.Text(line, style: t(size: 10)))
                          .toList(),
                    ),
                  ),
                ),
                pw.SizedBox(width: gap(6)),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _kv("Invoice No", invoiceNo, t),
                      _kv("Date", date, t),
                      _kv("Date of Supply", dateOfSupply, t),
                      _kv("Cost Center", costCenter, t),
                      _kv("Employee ID", employeeId, t),
                      _kv("Business Unit", businessUnit, t, valueSize: 9),
                      _kv("Booked By", bookedBy, t),
                      _kv("Booking No.", bookedNo, t),
                      _kv("Travel type", travelType, t),
                      _kv("CO2e", co2e, t),
                    ],
                  ),
                ),
              ],
            ),

            // Passenger line
            pw.SizedBox(height: gap(8)),
            pw.Text("Passenger $passengerName", style: t(size: 10)),

            // TABLE HEADER
            pw.SizedBox(height: gap(6)),
            pw.Container(
              color: PdfColor.fromHex('081e5b'),
              padding: pw.EdgeInsets.symmetric(
                vertical: gap(4),
                horizontal: gap(8),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 54,
                    child: pw.Text(
                      "Flight",
                      style: t(
                        size: 11,
                        bold: true,
                        color: PdfColor.fromHex('ceb553'),
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 46,
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text("Ex VAT",
                            style: t(
                                size: 11,
                                bold: true,
                                color: PdfColor.fromHex('ceb553'))),
                        pw.Text("VAT",
                            style: t(
                                size: 11,
                                bold: true,
                                color: PdfColor.fromHex('ceb553'))),
                        pw.Text("Total",
                            style: t(
                                size: 11,
                                bold: true,
                                color: PdfColor.fromHex('ceb553'))),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // DETAILS (segments OR hotel block) — exact two-line per segment
            pw.SizedBox(height: gap(4)),
            if (invoices.isEmpty && hotelData != null)
              _hotelBlockCompact(
                  hotelData, passengerName, fare.toStringAsFixed(2), t, gap)
            else
              ...List.generate(invoices.length,
                  (i) => _segmentTwoLineRow(invoices, i, t, gap)),
            pw.Spacer(),

            // Ticket & Airline taxes (air only)
            if (hotelData == null) ...[
              pw.SizedBox(height: gap(6)),
              pw.Row(
                mainAxisSize: pw.MainAxisSize.max,
                children: [
                  pw.Expanded(
                    flex: 54,
                    child: pw.Padding(
                      padding: pw.EdgeInsets.only(left: gap(64)),
                      child: pw.Text('Ticket No. $ticketNumber',
                          style: t(size: 10)),
                    ),
                  ),
                  pw.Expanded(
                    flex: 46,
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(fare.toStringAsFixed(2), style: t(size: 11)),
                        pw.Text('0.00', style: t(size: 11)),
                        pw.Text(fare.toStringAsFixed(2), style: t(size: 11)),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: gap(2)),
              pw.Row(
                mainAxisSize: pw.MainAxisSize.max,
                children: [
                  pw.Expanded(
                    flex: 54,
                    child: pw.Padding(
                      padding: pw.EdgeInsets.only(left: gap(64)),
                      child:
                          pw.Text('Airline Carrier Taxes', style: t(size: 10)),
                    ),
                  ),
                  pw.Expanded(
                    flex: 46,
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(taxes.toStringAsFixed(2), style: t(size: 11)),
                        pw.Text('0.00', style: t(size: 11)),
                        pw.Text(taxes.toStringAsFixed(2), style: t(size: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ],

            // Commission bar
            pw.SizedBox(height: gap(8)),
            pw.Container(
              color: PdfColor.fromHex('081e5b'),
              padding:
                  pw.EdgeInsets.symmetric(vertical: gap(4), horizontal: gap(8)),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 50,
                    child: pw.Text("Commission",
                        style: t(
                            size: 11,
                            bold: true,
                            color: PdfColor.fromHex('ceb553'))),
                  ),
                  pw.Expanded(
                    flex: 25,
                    child: pw.Text(comm.toStringAsFixed(2),
                        style: t(
                            size: 11,
                            bold: true,
                            color: PdfColor.fromHex('ceb553'))),
                  ),
                  pw.Expanded(
                    flex: 25,
                    child: pw.Text(comm.toStringAsFixed(2),
                        textAlign: pw.TextAlign.right,
                        style: t(
                            size: 11,
                            bold: true,
                            color: PdfColor.fromHex('ceb553'))),
                  ),
                ],
              ),
            ),

            // Service Fee bar
            pw.SizedBox(height: gap(4)),
            pw.Container(
              color: PdfColor.fromHex('081e5b'),
              padding:
                  pw.EdgeInsets.symmetric(vertical: gap(4), horizontal: gap(8)),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 50,
                    child: pw.Text("Service Fee",
                        style: t(
                            size: 11,
                            bold: true,
                            color: PdfColor.fromHex('ceb553'))),
                  ),
                  pw.Expanded(
                    flex: 25,
                    child: pw.Text(svc.toStringAsFixed(2),
                        style: t(
                            size: 11,
                            bold: true,
                            color: PdfColor.fromHex('ceb553'))),
                  ),
                  pw.Expanded(
                    flex: 25,
                    child: pw.Text(svc.toStringAsFixed(2),
                        textAlign: pw.TextAlign.right,
                        style: t(
                            size: 11,
                            bold: true,
                            color: PdfColor.fromHex('ceb553'))),
                  ),
                ],
              ),
            ),

            // Total Payable (yellow bar)
            pw.SizedBox(height: gap(8)),
            pw.Container(
              color: PdfColor.fromHex('ebce5f'),
              padding:
                  pw.EdgeInsets.symmetric(vertical: gap(3), horizontal: gap(8)),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 37,
                    child: pw.Text("Total Payable",
                        style: t(size: 10, bold: true)),
                  ),
                  pw.Expanded(
                    flex: 12,
                    child: pw.Text("USD", style: t(size: 10, bold: true)),
                  ),
                  pw.Expanded(
                      flex: 20,
                      child: pw.Text(grandTotal.toStringAsFixed(2),
                          style: t(size: 10, bold: true))),
                  pw.Expanded(
                      flex: 16,
                      child: pw.Text("0.00", style: t(size: 10, bold: true))),
                  pw.Expanded(
                      flex: 15,
                      child: pw.Text(grandTotal.toStringAsFixed(2),
                          textAlign: pw.TextAlign.right,
                          style: t(size: 10, bold: true))),
                ],
              ),
            ),

            // Notes & Footers (compact but intact)
            pw.SizedBox(height: gap(8)),
            pw.Text("Notes", style: t(size: 10, bold: true)),
            pw.SizedBox(height: gap(4)),
            pw.Row(
              children: [
                pw.Expanded(
                  flex: 32,
                  child: pw.Text("Approver Line Manager Name",
                      style: t(size: 10)),
                ),
                pw.Expanded(
                  flex: 68,
                  child: pw.Text(approver, style: t(size: 10)),
                ),
              ],
            ),
            pw.SizedBox(height: gap(2)),
            pw.Row(
              children: [
                pw.Expanded(
                  flex: 32,
                  child: pw.Text("Trip Reason", style: t(size: 10)),
                ),
                pw.Expanded(
                  flex: 68,
                  child: pw.Text("Rotation", style: t(size: 10)),
                ),
              ],
            ),
            pw.SizedBox(height: gap(2)),
            pw.Row(
              children: [
                pw.Expanded(
                  flex: 32,
                  child: pw.Text("Project Code", style: t(size: 10)),
                ),
                pw.Expanded(
                  flex: 68,
                  child: pw.Text("1425-GCMC", style: t(size: 10)),
                ),
              ],
            ),
            pw.SizedBox(height: gap(6)),
            pw.Divider(height: 0.5),
            pw.SizedBox(height: gap(2)),
            pw.Text("Comments", style: t(size: 10)),
            pw.Divider(height: 0.5),

            pw.SizedBox(height: gap(4)),
            pw.Text(
              """This is a computer-generated document, bears no signature.
Invoices must be paid as per agreed credit terms.
Any dispute must be notified within 14 days of invoice, if not the invoice will be treated as accepted/final Beneficiary Name: LONDON SKY COMPANY FOR SELLING FLIGHT TICKETS/LIMITED
Bank Details: BBAC s.a.l. Erbil Branch, 60M Street, Erbil, Iraq
IBAN: IQ74 BBAC 0013 6863 1202 010 ACCOUNT NO: 0368-631202-002 SWIFT Code: BBACIQBA
All invoice related queries have to be mailed to: accounts@londonskyco.com""",
              style: t(size: segCount > 8 ? 8.5 : 9),
              textAlign: pw.TextAlign.center,
            ),
          ],
        );
      },
    ),
  );

  return doc.save();
}

// ---------- helpers ---------------------------------------------------------

/// Key:Value inline row (compact, preserves two-column feel)
pw.Widget _kv(
  String k,
  String v,
  pw.TextStyle Function({double size, bool bold, PdfColor? color}) t, {
  double labelSize = 10,
  double valueSize = 10,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 2),
    child: pw.Row(
      // no baseline in pdf Row; keep simple and compact
      children: [
        pw.Text("$k: ", style: t(size: labelSize, bold: true)),
        pw.Expanded(child: pw.Text(v, style: t(size: valueSize))),
      ],
    ),
  );
}

/// Two-line per segment (exact structure):
/// 1) [Route label (i==0)]  RouteName                            Class
/// 2) FlightCode            DepartDate Time      ArrivalDate Time [right cols]
pw.Widget _segmentTwoLineRow(
  List<InvoiceSegmentData> invoices,
  int i,
  pw.TextStyle Function({double size, bool bold, PdfColor? color}) t,
  double Function(double) gap,
) {
  final seg = invoices[i];

  return pw.Padding(
    padding: pw.EdgeInsets.only(bottom: gap(4)),
    child: pw.Column(
      children: [
        // Line 1
        pw.Row(
          children: [
            pw.Expanded(
              flex: 54,
              child: pw.Row(
                children: [
                  pw.SizedBox(
                    width: 48,
                    child: pw.Text(i == 0 ? "Route" : "", style: t(size: 9)),
                  ),
                  pw.Expanded(
                    child: pw.Text(seg.routeName.text, style: t(size: 9)),
                  ),
                  pw.SizedBox(width: gap(8)),
                  pw.SizedBox(
                    width: 90,
                    child: pw.Text(seg.className.text, style: t(size: 9)),
                  ),
                ],
              ),
            ),
            // Right columns block (kept aligned with header; empty per-row)
            pw.Expanded(
              flex: 46,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.SizedBox(width: 1),
                  pw.SizedBox(width: 1),
                  pw.SizedBox(width: 1),
                ],
              ),
            ),
          ],
        ),

        // Line 2
        pw.SizedBox(height: gap(2)),
        pw.Row(
          children: [
            pw.Expanded(
              flex: 54,
              child: pw.Row(
                children: [
                  pw.SizedBox(
                    width: 50,
                    child: pw.Text(seg.code.text, style: t(size: 8.5)),
                  ),
                  pw.SizedBox(width: gap(8)),
                  pw.SizedBox(
                    width: 120,
                    child: pw.Text(
                      "${seg.departDate.text}  ${seg.departTime.text}",
                      style: t(size: 8.5),
                    ),
                  ),
                  pw.SizedBox(width: gap(8)),
                  pw.SizedBox(
                    width: 120,
                    child: pw.Text(
                      "${seg.arrivalDate.text}  ${seg.arrivalTime.text}",
                      style: t(size: 8.5),
                    ),
                  ),
                ],
              ),
            ),
            // Right columns block (kept aligned with header; empty per-row)
            pw.Expanded(
              flex: 46,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.SizedBox(width: 1),
                  pw.SizedBox(width: 1),
                  pw.SizedBox(width: 1),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

/// Compact hotel block matching the table rhythm (left info + right totals)
pw.Widget _hotelBlockCompact(
  InvoiceHotelData h,
  String passenger,
  String fare,
  pw.TextStyle Function({double size, bool bold, PdfColor? color}) t,
  double Function(double) gap,
) {
  pw.Widget r(String l, String v) => pw.Padding(
        padding: pw.EdgeInsets.only(bottom: gap(2)),
        child: pw.Row(
          children: [
            pw.SizedBox(width: 110, child: pw.Text(l, style: t(size: 10))),
            pw.Expanded(child: pw.Text(v, style: t(size: 10))),
          ],
        ),
      );

  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Expanded(
        flex: 54,
        child: pw.Padding(
          padding:
              pw.EdgeInsets.only(left: gap(28), top: gap(2), right: gap(6)),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              r("Hotel", h.hotelName.text),
              r("Location", h.location.text),
              r("No. Of Nights", h.numberOfNights.text),
              r("Check In", h.checkIn.text),
              r("Check Out", h.checkOut.text),
              r("Booked For", passenger),
              pw.SizedBox(height: gap(2)),
            ],
          ),
        ),
      ),
      pw.Expanded(
        flex: 46,
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(fare, style: t(size: 11)),
            pw.Text('0.00', style: t(size: 11)),
            pw.Text(fare, style: t(size: 11)),
          ],
        ),
      ),
    ],
  );
}
