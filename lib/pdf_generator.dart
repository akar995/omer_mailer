import 'dart:async';

import 'package:flutter/services.dart';
import 'package:omer_mailer/pdf_tab.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<Uint8List> generateInvoicePdf({
  InvoiceHotelData? hotelData,
  required PdfPageFormat format,
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
  required String firstPrice,
  required String tax,
  required String total,
  required String ticketNumber,
  required bool changeInvoiceText,
}) async {
  final doc = pw.Document(title: 'Invoice ', author: 'london sky');
  final profileImage = pw.MemoryImage(
    // (await rootBundle.load('assets/images/london_sky_logo.jpeg'))
    (await rootBundle.load('assets/images/london_sky_logo_new.jpg'))
        .buffer
        .asUint8List(),
  );
  // final profileImage = pw.MemoryImage(
  //   (await rootBundle.load('assets/profile.jpg')).buffer.asUint8List(),
  // );

  // final pageTheme = await _myPageTheme(format);

  doc.addPage(pw.MultiPage(
      // pageTheme: pageTheme,
      pageTheme: const pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.only(top: 30, left: 30),
      ),
      header: (context) {
        return pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 20, top: 15),
                  child: pw.Image(
                    profileImage,
                    width: 220,
                    height: 220,
                  )),
              pw.Padding(
                  padding: const pw.EdgeInsets.only(right: 40, top: 0),
                  child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                            "London Sky Company for selling Flight Tickets/Limited ",
                            style: const pw.TextStyle(
                              fontSize: 10,
                            )),
                        pw.Text("London sky Building",
                            style: const pw.TextStyle(
                              fontSize: 10,
                            )),
                        pw.Text("Zaza Street-Near 30 Meter Road Erbil_Iraq",
                            style: const pw.TextStyle(
                              fontSize: 10,
                            )),
                        pw.Text("Tel No.964 7518108782",
                            style: const pw.TextStyle(
                              fontSize: 10,
                            )),
                        // pw.Text("Tel No +964 751 810 8782",
                        //     style: const pw.TextStyle(
                        //       fontSize: 10,
                        //     )),
                      ]))
            ]);
      },
      build: (pw.Context context) => [
            pw.Row(
              children: [
                pw.Expanded(flex: 54, child: pw.SizedBox()),
                pw.Expanded(
                    flex: 46,
                    child: pw.Padding(
                        padding: const pw.EdgeInsets.only(
                            left: 20, top: 15, bottom: 15),
                        child: pw.Text("Tax Invoice",
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            )))),
              ],
            ),
            pw.Row(
              mainAxisSize: pw.MainAxisSize.max,
              children: [
                pw.Expanded(
                    flex: 1,
                    fit: pw.FlexFit.tight,
                    child: pw.Container(
                        padding: const pw.EdgeInsets.only(
                          right: 50,
                        ),
                        child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text("SNC Lavalin UK Limited Iraq Branch",
                                  style: const pw.TextStyle(
                                    fontSize: 10,
                                  )),
                              pw.Text("Unit No: CRG Building",
                                  style: const pw.TextStyle(
                                    fontSize: 10,
                                  )),
                              pw.Text(
                                  "Plot No: 2nd Floor, CRG Building, AMBP Camp",
                                  style: const pw.TextStyle(
                                    fontSize: 10,
                                  )),
                              pw.Text("Iraq",
                                  style: const pw.TextStyle(
                                    fontSize: 10,
                                  )),
                              pw.Text("Basra",
                                  style: const pw.TextStyle(
                                    fontSize: 10,
                                  )),
                              pw.Text(
                                  "Customer Account SNC Lavalin UK Limited - Iraq Branch",
                                  style: const pw.TextStyle(
                                    fontSize: 10,
                                  )),
                            ]))),
                pw.Flexible(
                    flex: 1,
                    fit: pw.FlexFit.tight,
                    child: pw.Row(children: [
                      pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                                changeInvoiceText ? "Credit No" : "Invoice No",
                                style: const pw.TextStyle(
                                  fontSize: 10,
                                )),
                            pw.Text("Date",
                                style: const pw.TextStyle(
                                  fontSize: 10,
                                )),
                            pw.Text("Date of Supply",
                                style: const pw.TextStyle(
                                  fontSize: 10,
                                )),
                            pw.Text("Cost Center",
                                style: const pw.TextStyle(
                                  fontSize: 10,
                                )),
                            pw.Text("Employee ID",
                                style: const pw.TextStyle(
                                  fontSize: 10,
                                )),
                            pw.Text("Business Unit",
                                style: const pw.TextStyle(
                                  fontSize: 10,
                                )),
                            pw.Text("Booked By",
                                style: const pw.TextStyle(
                                  fontSize: 10,
                                )),
                            pw.Text("Booking No.",
                                style: const pw.TextStyle(
                                  fontSize: 10,
                                )),
                          ]),
                      pw.SizedBox(width: 25),
                      pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(invoiceNo,
                                style: const pw.TextStyle(
                                  fontSize: 10,
                                )),
                            pw.Text(date,
                                style: const pw.TextStyle(
                                  fontSize: 10,
                                )),
                            pw.Text(dateOfSupply,
                                style: const pw.TextStyle(
                                  fontSize: 10,
                                )),
                            pw.Text(costCenter,
                                style: const pw.TextStyle(
                                  fontSize: 10,
                                )),
                            pw.Text(employeeId,
                                style: const pw.TextStyle(
                                  fontSize: 10,
                                )),
                            pw.Text(businessUnit,
                                style: const pw.TextStyle(
                                  fontSize: 10,
                                )),
                            pw.Text(bookedBy,
                                style: const pw.TextStyle(
                                  fontSize: 10,
                                )),
                            pw.Text(bookedNo,
                                style: const pw.TextStyle(
                                  fontSize: 10,
                                )),
                          ])
                    ])),
              ],
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 45, bottom: 15),
              child: pw.Text("Passenger $passengerName",
                  style: const pw.TextStyle(
                    fontSize: 10,
                  )),
            ),
            pw.Container(
                color: PdfColor.fromHex('081e5b'),
                padding: const pw.EdgeInsets.only(
                    top: 1, bottom: 5, left: 8, right: 8),
                margin: const pw.EdgeInsets.only(top: 0, right: 8),
                child: pw.Row(children: [
                  pw.Expanded(
                    flex: 54,
                    child: pw.Text("Flight",
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('ceb553'),
                        )),
                  ),
                  pw.Expanded(
                    flex: 46,
                    child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text("Ex VAT",
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromHex('ceb553'),
                              )),
                          pw.Text("VAT",
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromHex('ceb553'),
                              )),
                          pw.Text("Total",
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromHex('ceb553'),
                              ))
                        ]),
                  ),
                ])),
            pw.SizedBox(
                height: hotelData == null ? 200 : 135,
                child: pw.Column(children: [
                  if (invoices.isEmpty && hotelData != null)
                    pw.Padding(
                        padding: const pw.EdgeInsets.only(
                          left: 35,
                          top: 5,
                        ),
                        child: pw.Column(children: [
                          pw.Row(children: [
                            pw.SizedBox(
                              width: 110,
                              child: pw.Text("Hotel",
                                  style: const pw.TextStyle(
                                    fontSize: 12,
                                  )),
                            ),
                            pw.Text(hotelData.hotelName.text,
                                style: const pw.TextStyle(
                                  fontSize: 12,
                                )),
                          ]),
                          pw.SizedBox(height: 5),
                          pw.Row(children: [
                            pw.SizedBox(
                              width: 110,
                              child: pw.Text("Location",
                                  style: const pw.TextStyle(
                                    fontSize: 12,
                                  )),
                            ),
                            pw.Text(hotelData.location.text,
                                style: const pw.TextStyle(
                                  fontSize: 12,
                                )),
                          ]),
                          pw.SizedBox(height: 5),
                          pw.Row(children: [
                            pw.SizedBox(
                              width: 110,
                              child: pw.Text("No. Of Nights",
                                  style: const pw.TextStyle(
                                    fontSize: 12,
                                  )),
                            ),
                            pw.Text(hotelData.numberOfNights.text,
                                style: const pw.TextStyle(
                                  fontSize: 12,
                                )),
                          ]),
                          pw.SizedBox(height: 5),
                          pw.Row(children: [
                            pw.SizedBox(
                              width: 110,
                              child: pw.Text("Check In",
                                  style: const pw.TextStyle(
                                    fontSize: 12,
                                  )),
                            ),
                            pw.Text(hotelData.checkIn.text,
                                style: const pw.TextStyle(
                                  fontSize: 12,
                                )),
                          ]),
                          pw.SizedBox(height: 5),
                          pw.Row(children: [
                            pw.SizedBox(
                              width: 110,
                              child: pw.Text("Check Out",
                                  style: const pw.TextStyle(
                                    fontSize: 12,
                                  )),
                            ),
                            pw.Text(hotelData.checkOut.text,
                                style: const pw.TextStyle(
                                  fontSize: 12,
                                )),
                          ]),
                          pw.SizedBox(height: 5),
                          pw.Row(children: [
                            pw.SizedBox(
                              width: 110,
                              child: pw.Text("Booked For",
                                  style: const pw.TextStyle(
                                    fontSize: 12,
                                  )),
                            ),
                            pw.Text(passengerName,
                                style: const pw.TextStyle(
                                  fontSize: 12,
                                )),
                          ]),
                          pw.SizedBox(height: 5),
                          pw.Row(children: [
                            pw.Container(
                              width: 243,
                              height: 10,
                            ),
                            pw.Align(
                              alignment: pw.Alignment.centerRight,
                              child: pw.ConstrainedBox(
                                constraints: pw.BoxConstraints(minWidth: 27),
                                child: pw.Text(firstPrice,
                                    textAlign: pw.TextAlign.center,
                                    style: const pw.TextStyle(
                                      fontSize: 11,
                                    )),
                              ),
                            ),
                            pw.Spacer(),
                            pw.Padding(
                              padding: pw.EdgeInsets.only(right: 14),
                              child: pw.Align(
                                alignment: pw.Alignment.centerRight,
                                child: pw.ConstrainedBox(
                                  constraints: pw.BoxConstraints(minWidth: 27),
                                  child: pw.Text(firstPrice,
                                      textAlign: pw.TextAlign.center,
                                      style: const pw.TextStyle(
                                        fontSize: 11,
                                      )),
                                ),
                              ),
                            ),
                          ]),
                        ])),
                  for (int i = 0; i < invoices.length; i++)
                    pw.Row(children: [
                      pw.Expanded(
                          flex: 54,
                          child: pw.Column(children: [
                            pw.Row(children: [
                              pw.Row(children: [
                                pw.SizedBox(
                                    width: 52,
                                    height: 10,
                                    child: pw.Text(
                                      i == 0 ? 'Route' : '',
                                      style: const pw.TextStyle(
                                        fontSize: 10,
                                      ),
                                    )),
                                pw.SizedBox(
                                    width: 150,
                                    height: 10,
                                    child: pw.Text(
                                      invoices[i].routeName.text,
                                      style: const pw.TextStyle(
                                        fontSize: 10,
                                      ),
                                    )),
                                pw.SizedBox(
                                    width: 72,
                                    height: 10,
                                    child: pw.Text(
                                      invoices[i].className.text,
                                      style: const pw.TextStyle(
                                        fontSize: 10,
                                      ),
                                    )),
                                // pw.Expanded(
                                //     flex: 60,
                                //     child: pw.Container(color: PdfColors.green)),
                                // pw.Expanded(
                                //     flex: 20, child: pw.Container(color: PdfColors.red))
                              ])
                            ]),
                            pw.Padding(
                                padding:
                                    const pw.EdgeInsets.only(top: 5, bottom: 5),
                                child: pw.Row(children: [
                                  pw.SizedBox(
                                      width: 50,
                                      height: 10,
                                      child: pw.Text(
                                        invoices[i].code.text,
                                        style: const pw.TextStyle(
                                          fontSize: 9,
                                        ),
                                      )),
                                  pw.SizedBox(
                                      width: 60,
                                      height: 10,
                                      child: pw.Center(
                                          child: pw.Text(
                                        invoices[i].departDate.text,
                                        style: const pw.TextStyle(
                                          fontSize: 9,
                                        ),
                                      ))),
                                  pw.SizedBox(
                                      width: 50,
                                      height: 10,
                                      child: pw.Center(
                                          child: pw.Text(
                                        invoices[i].departTime.text,
                                        style: const pw.TextStyle(
                                          fontSize: 9,
                                        ),
                                      ))),
                                  pw.SizedBox(
                                      width: 50,
                                      height: 10,
                                      child: pw.Center(
                                          child: pw.Text(
                                        invoices[i].arrivalDate.text,
                                        style: const pw.TextStyle(
                                          fontSize: 9,
                                        ),
                                      ))),
                                  pw.SizedBox(
                                      width: 40,
                                      height: 10,
                                      child: pw.Center(
                                        child: pw.Text(
                                          invoices[i].arrivalTime.text,
                                          style: const pw.TextStyle(
                                            fontSize: 9,
                                          ),
                                        ),
                                      )),
                                ]))
                          ])),
                      pw.Expanded(
                        flex: 46,
                        child: pw.SizedBox(),
                      ),
                    ]),
                ])),
            if (hotelData == null)
              pw.Row(mainAxisSize: pw.MainAxisSize.max, children: [
                pw.Expanded(
                    child: pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 0, left: 90),
                  child: pw.Text('Ticket No. $ticketNumber',
                      style: const pw.TextStyle(
                        fontSize: 10,
                      )),
                )),
                pw.Expanded(
                    child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                      pw.Text(firstPrice,
                          style: const pw.TextStyle(
                            fontSize: 11,
                          )),
                      pw.Padding(
                          padding: const pw.EdgeInsets.only(right: 16),
                          child: pw.Text(firstPrice,
                              style: const pw.TextStyle(
                                fontSize: 11,
                              ))),
                    ])),
              ]),
            if (hotelData == null)
              pw.Row(mainAxisSize: pw.MainAxisSize.max, children: [
                pw.Expanded(
                    child: pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 0, left: 90),
                  child: pw.Text('Airline Carrier Taxes',
                      style: const pw.TextStyle(
                        fontSize: 10,
                      )),
                )),
                pw.Expanded(
                    child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                      pw.Text('0.00',
                          style: const pw.TextStyle(
                            fontSize: 11,
                          )),
                      pw.Padding(
                          padding: const pw.EdgeInsets.only(right: 16),
                          child: pw.Text('0.00',
                              style: const pw.TextStyle(
                                fontSize: 11,
                              ))),
                    ])),
              ]),
            pw.Container(
                color: PdfColor.fromHex('081e5b'),
                padding: const pw.EdgeInsets.only(
                    top: 1, bottom: 5, left: 8, right: 8),
                margin: const pw.EdgeInsets.only(top: 0, right: 8),
                child: pw.Row(children: [
                  pw.Expanded(
                    flex: 50,
                    child: pw.Text("Commission",
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('ceb553'),
                        )),
                  ),
                  pw.Expanded(
                    flex: 25,
                    child: pw.Text(tax,
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('ceb553'),
                        )),
                  ),
                  pw.Expanded(
                    flex: 25,
                    child: pw.Text(tax,
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('ceb553'),
                        )),
                  ),
                ])),
            pw.Container(
                color: PdfColor.fromHex('ebce5f'),
                padding: const pw.EdgeInsets.only(
                    top: 0, bottom: 1, left: 8, right: 8),
                margin: const pw.EdgeInsets.only(top: 10, right: 8),
                child: pw.Row(children: [
                  pw.Expanded(
                    flex: 37,
                    child: pw.Text("Total Payable",
                        style: const pw.TextStyle(
                          fontSize: 10,
                        )),
                  ),
                  pw.Expanded(
                    flex: 12,
                    child: pw.Text("USD",
                        style: const pw.TextStyle(
                          fontSize: 10,
                        )),
                  ),
                  pw.Expanded(
                    flex: 20,
                    child: pw.Text(total,
                        style: const pw.TextStyle(
                          fontSize: 10,
                        )),
                  ),
                  pw.Expanded(
                    flex: 16,
                    child: pw.Text("0.00",
                        style: const pw.TextStyle(
                          fontSize: 10,
                        )),
                  ),
                  pw.Expanded(
                    flex: 15,
                    child: pw.Text(total,
                        textAlign: pw.TextAlign.right,
                        style: const pw.TextStyle(
                          fontSize: 10,
                        )),
                  ),
                ])),
            pw.Container(
                color: PdfColor.fromHex('ebce5f'),
                padding: const pw.EdgeInsets.only(
                    top: 3, bottom: 1, left: 8, right: 8),
                margin: const pw.EdgeInsets.only(top: 3, right: 8),
                child: pw.Row(children: [
                  pw.Expanded(
                      child: pw.Text("Notes",
                          style: const pw.TextStyle(
                            fontSize: 10,
                          )))
                ])),
            pw.Padding(
                padding: const pw.EdgeInsets.only(top: 5),
                child: pw.Row(children: [
                  pw.Expanded(
                      flex: 29,
                      child: pw.Text("Approver Line Manager Name",
                          style: const pw.TextStyle(
                            fontSize: 10,
                          ))),
                  pw.Expanded(
                      flex: 71,
                      child: pw.Text(approver,
                          style: const pw.TextStyle(
                            fontSize: 10,
                          )))
                ])),
            pw.Padding(
                padding: const pw.EdgeInsets.only(top: 5),
                child: pw.Row(children: [
                  pw.Expanded(
                      flex: 29,
                      child: pw.Text("Trip Reason",
                          style: const pw.TextStyle(
                            fontSize: 10,
                          ))),
                  pw.Expanded(
                      flex: 71,
                      child: pw.Text("Rotation",
                          style: const pw.TextStyle(
                            fontSize: 10,
                          )))
                ])),
            pw.Padding(
                padding: const pw.EdgeInsets.only(top: 5),
                child: pw.Row(children: [
                  pw.Expanded(
                      flex: 29,
                      child: pw.Text("Project Code",
                          style: const pw.TextStyle(
                            fontSize: 10,
                          ))),
                  pw.Expanded(
                      flex: 71,
                      child: pw.Text("1425-GCMC",
                          style: const pw.TextStyle(
                            fontSize: 10,
                          )))
                ])),
            pw.Padding(
              padding: const pw.EdgeInsets.only(right: 30),
              child: pw.Divider(thickness: 1.5),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: -5, right: 30, bottom: 5),
              child: pw.Text("Comments",
                  style: const pw.TextStyle(
                    fontSize: 10,
                  )),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.only(right: 30),
              child: pw.Divider(thickness: 1.5),
            ),
            pw.Text(
                textAlign: pw.TextAlign.center,
                """This is a computer-generated document, bears no signature.
Invoices must be paid as per agreed credit terms.
Any dispute must be notified within 14 days of invoice, if not the invoice will be treated as accepted/final Beneficiary Name: LONDON SKY COMPANY FOR SELLING FLIGHT TICKETS/LIMITED
Bank Details: BBAC s.a.l. Erbil Branch, 60M Street, Erbil, Iraq
IBAN: IQ74 BBAC 0013 6863 1202 010 ACCOUNT NO: 0368-631202-002 SWIFT Code: BBACIQBA
All invoice related queries have to be mailed to: accounts@londonskyco.com""",
                style: const pw.TextStyle(fontSize: 10))
          ]));
  return doc.save();
}
