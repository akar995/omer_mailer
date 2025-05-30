import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';

class ExcelHelper {
  Uint8List? insertInvoiceExcel(Excel excel) {
    return null;
  }
}

const predefinedVendorCode = {
  "QR": "QATAR AIRWAYS",
  "TK": "TURKISH AIRLINE",
  "EK": "EMIRATE AIRWAYS",
  "IA": "IRAQ AIRWAYS",
  "6E": "INDEGO",
  "FZ": "FLY DUBAI",
  "G8": "GO FIRST",
  "G9": "AIR ARABIA",
  "SG": "SPICE JET",
  "UK": "VISTARA",
  "AV": "AVIANCA",
  "ME": "MIDDLE EAST AIRLINE",
};

class InvoiceStructure {
  final String recordKey;
  final List<dynamic> row = [];
  static const int sequentNumber = 1;
  static const int clientId = 2947;
  static const String clientName = 'KENTECH GULF HOLDING LIMITED IRAQ BRANCH';
  final String invoiceDate;
  final String bookedDate;
  static const String voidInd = 'N';
  final String salutation;
  final String passengerName;
  final String bookingType;
  final String documentNumber;
  final String recordLocatorPNR;
  final String vendorCode;
  final String outBoundDate;
  final String departTime;
  final String arrivalDate;
  final String arrivalTime;
  final String serviceCategory;
  static const String currency = 'USD';
  final String lskFee;
  final String baseFare;
  final int taxAmount;

  final int totalAmountLondonSky;
  static const exchangeIndicator = 'N';
  late final String bookingNumber;
  static const refoundIndicator = 'N';
  static const bookingAgentId = 'LONDON SKY';
  static const formOfPayment = 'AR';
  late final String originCode;
  final String destinationCode;
  final String passengerID;
  final String flightNumber;
  static const tripReason = "ROTATION";
  static const constCenter = '1425';

  ///segment
  final int segmentLeg;
  final String airCode;

  /// index+1;
  final List<dynamic> segment = [];

  InvoiceStructure({
    required this.recordKey,
    required this.invoiceDate,
    required this.bookedDate,
    required this.salutation,
    required this.passengerName,
    required this.bookingType,
    required this.documentNumber,
    required this.recordLocatorPNR,
    required this.vendorCode,
    required this.outBoundDate,
    required this.departTime,
    required this.arrivalDate,
    required this.arrivalTime,
    required this.serviceCategory,
    required this.totalAmountLondonSky,
    required this.destinationCode,
    required this.passengerID,
    required this.lskFee,
    required this.baseFare,
    required this.taxAmount,
    required this.segmentLeg,
    required this.airCode,
    required this.originCode,
    required this.flightNumber,
  }) {
    bookingNumber = recordLocatorPNR;
    final lastName =
        passengerName.substring(0, passengerName.indexOf('/')).trim();
    final firstName = passengerName
        .substring(
          passengerName.indexOf('/') + 1,
          passengerName.lastIndexOf(' '),
        )
        .trim();
    final sol = passengerName
        .substring(passengerName.lastIndexOf(' ') + 1, passengerName.length)
        .trim();
    row.add(recordKey);
    row.add(sequentNumber);
    row.add(clientId);
    row.add(clientName);
    row.add(invoiceDate);
    row.add(bookedDate);
    row.add(voidInd);
    row.add(sol);
    row.add(firstName);
    row.add(lastName);

    row.add(bookingType);
    row.add(documentNumber);
    row.add(recordLocatorPNR);
    if (bookingType == "AIR") {
      final countryCode = flightNumber.substring(0, 2);

      final String? countryName = predefinedVendorCode[countryCode];

      if (countryCode.isEmpty) {
        throw ErrorHint("Vendor code is not available");
      }
      row.add(countryCode); //vender code
      row.add(countryName); //vender code
    } else {
      row.add('HTL'); //vender code
      row.add(vendorCode); //vender name
    }

    row.add(outBoundDate);
    row.add(departTime);
    row.add(arrivalDate);
    row.add(arrivalTime);
    row.add(serviceCategory);
    row.add(currency);
    row.add(lskFee);
    row.add(baseFare);
    row.add(taxAmount);
    row.add(totalAmountLondonSky);
    row.add(exchangeIndicator);
    row.add(bookingType == "AIR" ? documentNumber : bookingNumber);
    row.add(refoundIndicator);
    row.add(bookingAgentId);
    row.add(formOfPayment);
    row.add(originCode);
    row.add(destinationCode);
    row.add(passengerID);
    row.add(tripReason);
    row.add(constCenter);

    /// static rows

    row.add("1425-GCMC");
    row.add("N/A");
    row.add("N/A	");
    row.add("joe.golden@kentplc.com	");
    row.add("nemat.talibmarymalik@kentplc.com	");
    row.add("Joy Golden	");
    row.add("IRQ - Kent International Services Limited Iraq Branch");
    row.add("Nemat");

    //// segment
    ///
    if (bookingType == "AIR") {
      segment.add(recordKey);
      segment.add(1);
      segment.add(segmentLeg);
      segment.add(flightNumber.substring(0, 2).trim());
      segment.add(originCode);
      segment.add(outBoundDate);
      segment.add(departTime);
      segment.add(flightNumber.substring(2, flightNumber.length).trim());
      segment.add(destinationCode);
      segment.add(arrivalDate);
      segment.add(arrivalTime);
      segment.add(serviceCategory);
    }
  }
}
