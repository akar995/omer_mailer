import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:omer_mailer/segment_mock.dart';

import 'package:printing/printing.dart';

import 'pdf_tab.dart'
    show InvoiceHotelData, InvoiceSegmentData; // reuse existing models
import 'pdf_generator_v2.dart';

class PDFTabV2 extends StatefulWidget {
  const PDFTabV2({super.key});

  @override
  State<PDFTabV2> createState() => _PDFTabV2State();
}

class _PDFTabV2State extends State<PDFTabV2> {
  // Reuse your existing patterns but add the new fields:
  final invoices = <InvoiceSegmentData>[];
  Future<Uint8List>? pdf;

  // existing
  final _invoiceTextController = TextEditingController();
  final _dateTextController = TextEditingController();
  final _dateOfSupplyTextController = TextEditingController();
  final _costCenterTextController = TextEditingController(text: '1425');
  final _employeeIdTextController = TextEditingController();
  final _businessUnitTextController =
      TextEditingController(text: "Kentech Gulf Holdings Limited Iraq Branch");
  final _bookedByTextController = TextEditingController(text: "NEMAT");
  final _bookNumberTextController = TextEditingController();
  final _firstPriceTextController = TextEditingController(); // fare (ex VAT)
  final _approverTextController = TextEditingController();
  final _passengerNameTextController = TextEditingController();
  final _commissionTextController = TextEditingController(); // was "tax"
  final _ticketNumberController = TextEditingController();

  // NEW fields
  final _airlineCarrierTaxController = TextEditingController();
  final _serviceFeeController = TextEditingController();
  final _co2eController = TextEditingController();
  final _travelTypeController = TextEditingController();

  // toggles
  bool changeInvoiceText = false; // same behavior as v1
  bool useNewCompanyAddress = false; // NEW
  bool useAltCustomerBlock = false; // NEW

  InvoiceHotelData? hotelInvoice; // keep your hotel option

  Timer? _debounce;
  void _onTextChange(_) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () => setState(() {}));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _invoiceTextController.dispose();
    _dateTextController.dispose();
    _dateOfSupplyTextController.dispose();
    _costCenterTextController.dispose();
    _employeeIdTextController.dispose();
    _businessUnitTextController.dispose();
    _bookedByTextController.dispose();
    _bookNumberTextController.dispose();
    _firstPriceTextController.dispose();
    _approverTextController.dispose();
    _passengerNameTextController.dispose();
    _commissionTextController.dispose();
    _ticketNumberController.dispose();
    _airlineCarrierTaxController.dispose();
    _serviceFeeController.dispose();
    _co2eController.dispose();
    _travelTypeController.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label) => InputDecoration(labelText: label);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF v2'),
        actions: [
          Row(children: [
            const Text("Credit Note?"),
            Switch(
              value: changeInvoiceText,
              onChanged: (v) => setState(() => changeInvoiceText = v),
            ),
            const SizedBox(width: 12),
            const Text("New Company Address"),
            Switch(
              value: useNewCompanyAddress,
              onChanged: (v) => setState(() => useNewCompanyAddress = v),
            ),
            const SizedBox(width: 12),
            const Text("Alt Customer Block"),
            Switch(
              value: useAltCustomerBlock,
              onChanged: (v) => setState(() => useAltCustomerBlock = v),
            ),
            const SizedBox(width: 8),
          ])
        ],
      ),
      body: Row(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: _invoiceTextController,
                        onChanged: _onTextChange,
                        decoration: _dec('Invoice Number'),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: _dateTextController,
                        onChanged: _onTextChange,
                        decoration: _dec('Date'),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: _dateOfSupplyTextController,
                        onChanged: _onTextChange,
                        decoration: _dec('Date of Supply'),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: _costCenterTextController,
                        onChanged: _onTextChange,
                        decoration: _dec('Cost Center'),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: _employeeIdTextController,
                        onChanged: _onTextChange,
                        decoration: _dec('Employee ID'),
                      ),
                    ),
                    SizedBox(
                      width: 280,
                      child: TextField(
                        controller: _businessUnitTextController,
                        onChanged: _onTextChange,
                        decoration: _dec('Business Unit'),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: _passengerNameTextController,
                        onChanged: _onTextChange,
                        decoration: _dec('Passenger Name'),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: _bookedByTextController,
                        onChanged: _onTextChange,
                        decoration: _dec('Booked By'),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: _bookNumberTextController,
                        onChanged: _onTextChange,
                        decoration: _dec('Booked No'),
                      ),
                    ),

                    // Fare / Commission / Airline Taxes / Service Fee / Ticket No
                    SizedBox(
                      width: 180,
                      child: TextField(
                        controller: _firstPriceTextController,
                        onChanged: _onTextChange,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[-0-9.,]'))
                        ],
                        decoration: _dec('Fare (Ex VAT)'),
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: TextField(
                        controller: _commissionTextController,
                        onChanged: _onTextChange,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[-0-9.,]'))
                        ],
                        decoration: _dec('Commission'),
                      ),
                    ),
                    SizedBox(
                      width: 190,
                      child: TextField(
                        controller: _airlineCarrierTaxController,
                        onChanged: _onTextChange,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[-0-9.,]'))
                        ],
                        decoration: _dec('Airline Carrier Taxes'),
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: TextField(
                        controller: _serviceFeeController,
                        onChanged: _onTextChange,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[-0-9.,]'))
                        ],
                        decoration: _dec('Service Fee'),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: _ticketNumberController,
                        onChanged: _onTextChange,
                        decoration: _dec('Ticket Number'),
                      ),
                    ),

                    // NEW: Travel Type, CO2e
                    SizedBox(
                      width: 200,
                      child: TextField(
                        controller: _travelTypeController,
                        onChanged: _onTextChange,
                        decoration: _dec('Travel Type'),
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      child: TextField(
                        controller: _co2eController,
                        onChanged: _onTextChange,
                        decoration: _dec('CO2e'),
                      ),
                    ),

                    // Approver
                    SizedBox(
                      width: 260,
                      child: TextField(
                        controller: _approverTextController,
                        onChanged: _onTextChange,
                        decoration: _dec('Approver Line Manager Name'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          invoices.add(InvoiceSegmentData(
                            arrivalDate: TextEditingController(),
                            arrivalTime: TextEditingController(),
                            className: TextEditingController(),
                            code: TextEditingController(),
                            departDate: TextEditingController(),
                            departTime: TextEditingController(),
                            routeName: TextEditingController(),
                            classCode: TextEditingController(),
                            destinationCode: TextEditingController(),
                            originCode: TextEditingController(),
                          ));
                        });
                      },
                      child: const Text("Add Segment"),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (hotelInvoice == null) {
                          setState(() {
                            hotelInvoice = InvoiceHotelData(
                              hotelName: TextEditingController(),
                              location: TextEditingController(),
                              numberOfNights: TextEditingController(),
                              checkIn: TextEditingController(),
                              checkOut: TextEditingController(),
                              hotelDestination: TextEditingController(),
                            );
                          });
                        } else {
                          hotelInvoice!.hotelName.dispose();
                          hotelInvoice!.location.dispose();
                          hotelInvoice!.numberOfNights.dispose();
                          hotelInvoice!.checkIn.dispose();
                          hotelInvoice!.checkOut.dispose();
                          hotelInvoice!.hotelDestination.dispose();
                          setState(() => hotelInvoice = null);
                        }
                      },
                      child: Text(
                          hotelInvoice == null ? "Add Hotel" : "Remove Hotel"),
                    ),
                  ],
                ),
                if (hotelInvoice != null && invoices.isEmpty) ...[
                  const SizedBox(height: 12),
                  _hotelInputs(hotelInvoice!),
                ],
                for (int i = 0; i < invoices.length; i++) ...[
                  const Divider(),
                  _segmentInputs(i),
                ],
              ],
            ),
          ),
          TextButton(
              onPressed: () {
                setState(() {
                  invoices.add(
                    SegmentMock.nextMockSegment(
                      invoices,
                      startAirport: 'EBL', // optional
                      finalAirport: 'DOH', // optional hint
                      startDate: DateTime.now(), // optional
                    ),
                  );
                });
              },
              child: Text("add Mock Data")),
          // PDF preview
          Expanded(
            child: PdfPreview(
              pdfPreviewPageDecoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 1),
              ),
              build: (pageFormat) {
                pdf = generateInvoicePdfV2(
                  hotelData: hotelInvoice,
                  format: pageFormat,
                  invoices: invoices,
                  invoiceNo: _invoiceTextController.text.isNotEmpty
                      ? _invoiceTextController.text
                      : '.',
                  date: _dateTextController.text.isNotEmpty
                      ? _dateTextController.text
                      : '.',
                  dateOfSupply: _dateOfSupplyTextController.text.isNotEmpty
                      ? _dateOfSupplyTextController.text
                      : '.',
                  costCenter: _costCenterTextController.text.isNotEmpty
                      ? _costCenterTextController.text
                      : '.',
                  employeeId: _employeeIdTextController.text.isNotEmpty
                      ? _employeeIdTextController.text
                      : '.',
                  businessUnit: _businessUnitTextController.text.isNotEmpty
                      ? _businessUnitTextController.text
                      : '.',
                  bookedBy: _bookedByTextController.text.isNotEmpty
                      ? _bookedByTextController.text
                      : '.',
                  bookedNo: _bookNumberTextController.text.isNotEmpty
                      ? _bookNumberTextController.text
                      : '.',
                  firstPrice: _firstPriceTextController.text.isNotEmpty
                      ? _firstPriceTextController.text
                      : '0',
                  commission: _commissionTextController.text.isNotEmpty
                      ? _commissionTextController.text
                      : '0',
                  airlineCarrierTaxes:
                      _airlineCarrierTaxController.text.isNotEmpty
                          ? _airlineCarrierTaxController.text
                          : '0',
                  serviceFee: _serviceFeeController.text.isNotEmpty
                      ? _serviceFeeController.text
                      : '0',
                  passengerName: _passengerNameTextController.text,
                  approver: _approverTextController.text,
                  total: '0', // recalculated inside generator
                  ticketNumber: _ticketNumberController.text,
                  co2e: _co2eController.text,
                  travelType: _travelTypeController.text,
                  changeInvoiceText: changeInvoiceText,
                  useNewCompanyAddress: useNewCompanyAddress,
                  useAltCustomerBlock: useAltCustomerBlock,
                );
                return pdf!;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _segmentInputs(int i) {
    final s = invoices[i];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
              child: Text('Segment ${i + 1}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold))),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              s.routeName.dispose();
              s.className.dispose();
              s.code.dispose();
              s.departDate.dispose();
              s.departTime.dispose();
              s.arrivalDate.dispose();
              s.arrivalTime.dispose();
              s.classCode.dispose();
              s.originCode.dispose();
              s.destinationCode.dispose();
              setState(() => invoices.removeAt(i));
            },
          ),
        ]),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
                width: 150,
                child: TextField(
                    controller: s.code,
                    onChanged: _onTextChange,
                    decoration: _dec('Route Code'))),
            SizedBox(
                width: 220,
                child: TextField(
                    controller: s.routeName,
                    onChanged: _onTextChange,
                    decoration: _dec('Route Name'))),
            SizedBox(
                width: 160,
                child: TextField(
                    controller: s.className,
                    onChanged: _onTextChange,
                    decoration: _dec('Class'))),
            SizedBox(
                width: 80,
                child: TextField(
                    controller: s.classCode,
                    onChanged: _onTextChange,
                    decoration: _dec('C.Code'))),
            SizedBox(
                width: 160,
                child: TextField(
                    controller: s.departDate,
                    onChanged: _onTextChange,
                    decoration: _dec('Depart Date'))),
            SizedBox(
                width: 160,
                child: TextField(
                    controller: s.departTime,
                    onChanged: _onTextChange,
                    decoration: _dec('Depart Time'))),
            SizedBox(
                width: 160,
                child: TextField(
                    controller: s.arrivalDate,
                    onChanged: _onTextChange,
                    decoration: _dec('Arrival Date'))),
            SizedBox(
                width: 160,
                child: TextField(
                    controller: s.arrivalTime,
                    onChanged: _onTextChange,
                    decoration: _dec('Arrival Time'))),
            SizedBox(
                width: 160,
                child: TextField(
                    controller: s.originCode,
                    onChanged: _onTextChange,
                    decoration: _dec('Origin Code'))),
            SizedBox(
                width: 160,
                child: TextField(
                    controller: s.destinationCode,
                    onChanged: _onTextChange,
                    decoration: _dec('Destination Code'))),
          ],
        ),
      ],
    );
  }

  Widget _hotelInputs(InvoiceHotelData h) {
    return Column(children: [
      TextField(
          controller: h.hotelName,
          onChanged: _onTextChange,
          decoration: const InputDecoration(
              labelText: "Hotel Name", border: OutlineInputBorder())),
      const SizedBox(height: 8),
      TextField(
          controller: h.location,
          onChanged: _onTextChange,
          decoration: const InputDecoration(
              labelText: "Location", border: OutlineInputBorder())),
      const SizedBox(height: 8),
      TextField(
          controller: h.numberOfNights,
          onChanged: _onTextChange,
          decoration: const InputDecoration(
              labelText: "Number of Nights", border: OutlineInputBorder())),
      const SizedBox(height: 8),
      TextField(
          controller: h.checkIn,
          onChanged: _onTextChange,
          decoration: const InputDecoration(
              labelText: "Check In", border: OutlineInputBorder())),
      const SizedBox(height: 8),
      TextField(
          controller: h.checkOut,
          onChanged: _onTextChange,
          decoration: const InputDecoration(
              labelText: "Check Out", border: OutlineInputBorder())),
      const SizedBox(height: 8),
      TextField(
          controller: h.hotelDestination,
          onChanged: _onTextChange,
          decoration: const InputDecoration(
              labelText: "Destination", border: OutlineInputBorder())),
    ]);
  }
}
