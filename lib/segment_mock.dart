import 'dart:math';
import 'package:flutter/material.dart';
import 'pdf_tab.dart' show InvoiceSegmentData;

/// Generates realistic, chained mock flight segments for your PDF tab.
/// - Keeps the route continuous: next.origin = previous.destination
/// - Builds plausible airline code + flight number (e.g., QR221)
/// - Increments times & dates with layovers
/// - Rotates cabin classes (Economy/Premium/Business) and class codes (Y/W/J)
///
/// USAGE (in your onPressed):
///   setState(() {
///     final seg = SegmentMock.nextMockSegment(invoices,
///       startAirport: 'EBL',         // optional, used only for first segment
///       finalAirport: 'DOH',         // optional hint for last destination in short hops
///       startDate: DateTime.now(),   // optional, used only for first segment
///     );
///     invoices.add(seg);
///   });
class SegmentMock {
  // A small set of common airports you seem to work with; extend as you like.
  static const List<_Airport> _airports = [
    _Airport('EBL', 'Erbil'), // Iraq
    _Airport('BGW', 'Baghdad'), // Iraq
    _Airport('DOH', 'Doha'), // Qatar
    _Airport('DXB', 'Dubai'), // UAE
    _Airport('SHJ', 'Sharjah'), // UAE
    _Airport('IST', 'Istanbul'), // Türkiye
    _Airport('SAW', 'Istanbul Sabiha'), // Türkiye
    _Airport('AMM', 'Amman'), // Jordan
    _Airport('BAH', 'Bahrain'), // Bahrain
  ];

  // Airline 2-letter codes mapped to friendly name (used in routeName).
  static const Map<String, String> _airlines = {
    'QR': 'Qatar Airways',
    'TK': 'Turkish Airlines',
    'FZ': 'flydubai',
    'EK': 'Emirates',
    'G9': 'Air Arabia',
    'IA': 'Iraqi Airways',
  };

  // Cycling cabin labels & booking class codes.
  static const List<String> _classNames = [
    'Economy',
    'Premium Economy',
    'Business'
  ];
  static const List<String> _classCodes = ['Y', 'W', 'J'];

  /// Create the next chained segment using the existing [segments].
  /// If [segments] is empty, it starts from [startAirport] (default: EBL) and
  /// picks a sensible near hub as destination (or [finalAirport] if provided).
  /// Times are computed as: depart = prev.arrival + layover; duration 1.0–4.5h.
  static InvoiceSegmentData nextMockSegment(
    List<InvoiceSegmentData> segments, {
    String? startAirport, // only used for first segment
    String? finalAirport, // a hint; not forced every time
    DateTime? startDate, // only used for first segment
    Random? seed,
  }) {
    final rand = seed ?? Random();

    // Derive previous leg info (if exists)
    String origin;
    DateTime departAt;
    if (segments.isEmpty) {
      origin = (startAirport != null && startAirport.trim().isNotEmpty)
          ? startAirport.trim().toUpperCase()
          : 'EBL';

      // Round startDate to nearest 15 minutes for cleaner times
      final base = startDate ?? DateTime.now();
      departAt = _roundToQuarterHour(
          base.add(const Duration(days: 1, hours: 9))); // tomorrow ~09:00
    } else {
      final last = segments.last;
      origin = last.destinationCode.text.trim().toUpperCase();

      final lastArrDate = _parseDate(last.arrivalDate.text);
      final lastArrTime = _parseTime(last.arrivalTime.text);
      final lastArrival = _combineDateTime(lastArrDate, lastArrTime);

      // layover 1–3h
      final layoverMin = 60 + rand.nextInt(121);
      departAt = lastArrival.add(Duration(minutes: layoverMin));
    }

    // Pick a destination that is not the same as origin
    final nextDest = _pickDestination(origin, finalAirport, rand);

    // Flight duration 60–270 minutes (1.0–4.5h) depending on region
    final durMin = 75 + rand.nextInt(151); // 75–225 min
    final arriveAt = departAt.add(Duration(minutes: durMin));

    // Airline & flight number based on corridor
    final airline = _pickAirlineFor(origin, nextDest, rand);
    final flightNo = _buildFlightNo(airline, rand);

    // Cabin rotates with segment index
    final segIndex = segments.length;
    final className = _classNames[segIndex % _classNames.length];
    final classCode = _classCodes[segIndex % _classCodes.length];

    // Build pretty route name
    final routeName =
        '${_airportCity(origin)} - ${_airportCity(nextDest)} (${_airlines[airline] ?? airline})';

    // Fill controllers
    final codeCtrl = TextEditingController(text: flightNo);
    final routeCtrl = TextEditingController(text: routeName);
    final classNameCtrl = TextEditingController(text: className);
    final classCodeCtrl = TextEditingController(text: classCode);

    final departDateCtrl = TextEditingController(text: _fmtDate(departAt));
    final departTimeCtrl = TextEditingController(text: _fmtTime(departAt));
    final arrivalDateCtrl = TextEditingController(text: _fmtDate(arriveAt));
    final arrivalTimeCtrl = TextEditingController(text: _fmtTime(arriveAt));

    final originCtrl = TextEditingController(text: origin);
    final destCtrl = TextEditingController(text: nextDest);

    return InvoiceSegmentData(
      routeName: routeCtrl,
      className: classNameCtrl,
      code: codeCtrl,
      departDate: departDateCtrl,
      departTime: departTimeCtrl,
      arrivalDate: arrivalDateCtrl,
      arrivalTime: arrivalTimeCtrl,
      classCode: classCodeCtrl,
      originCode: originCtrl,
      destinationCode: destCtrl,
    );
  }

  // ---------- helpers ----------

  static String _fmt2(int v) => v.toString().padLeft(2, '0');

  static String _fmtDate(DateTime dt) =>
      '${_fmt2(dt.day)}/${_fmt2(dt.month)}/${dt.year}';

  static String _fmtTime(DateTime dt) =>
      '${_fmt2(dt.hour)}:${_fmt2(dt.minute)}';

  static DateTime _roundToQuarterHour(DateTime dt) {
    final m = dt.minute;
    final q = (m / 15).round() * 15;
    final delta = q - m;
    return dt.add(Duration(minutes: delta));
  }

  static DateTime _combineDateTime(DateTime date, TimeOfDay time) =>
      DateTime(date.year, date.month, date.day, time.hour, time.minute);

  static DateTime _parseDate(String s) {
    // accepts DD/MM/YYYY
    try {
      final parts = s.split('/');
      if (parts.length == 3) {
        final d = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        final y = int.parse(parts[2]);
        return DateTime(y, m, d);
      }
    } catch (_) {}
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static TimeOfDay _parseTime(String s) {
    // accepts HH:mm
    try {
      final parts = s.split(':');
      if (parts.length == 2) {
        final h = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        return TimeOfDay(hour: h, minute: m);
      }
    } catch (_) {}
    return const TimeOfDay(hour: 9, minute: 0);
  }

  static String _airportCity(String code) {
    final match = _airports.firstWhere((a) => a.code == code,
        orElse: () => _Airport(code, code));
    return match.city;
  }

  static String _pickDestination(String origin, String? hint, Random rand) {
    // Prefer hint if valid and different
    if (hint != null) {
      final h = hint.trim().toUpperCase();
      if (h != origin && _airports.any((a) => a.code == h)) return h;
    }

    // Otherwise pick a reasonable nearby hub not equal to origin
    final options = _airports.where((a) => a.code != origin).toList();
    if (options.isEmpty) {
      // fallback to DOH if somehow list is empty after filter
      return origin == 'DOH' ? 'DXB' : 'DOH';
    }
    return options[rand.nextInt(options.length)].code;
  }

  static String _pickAirlineFor(String origin, String dest, Random rand) {
    // quick routing heuristic
    if ((origin == 'EBL' || origin == 'BGW') && (dest == 'DOH')) return 'QR';
    if ((origin == 'DOH') && (dest == 'EBL' || dest == 'BGW')) return 'QR';

    if ((origin == 'EBL' || origin == 'BGW') &&
        (dest == 'IST' || dest == 'SAW')) {
      return 'TK';
    }
    if ((origin == 'IST' || origin == 'SAW') &&
        (dest == 'EBL' || dest == 'BGW')) {
      return 'TK';
    }

    if ((origin == 'EBL' || origin == 'BGW') &&
        (dest == 'DXB' || dest == 'SHJ')) {
      return rand.nextBool() ? 'FZ' : 'G9';
    }
    if ((origin == 'DXB' || origin == 'SHJ') &&
        (dest == 'EBL' || dest == 'BGW')) {
      return rand.nextBool() ? 'FZ' : 'G9';
    }

    if ((origin == 'DXB') && (dest == 'DOH' || dest == 'IST')) return 'EK';

    // fallback random from the known set
    final keys = _airlines.keys.toList();
    return keys[rand.nextInt(keys.length)];
  }

  static String _buildFlightNo(String airline, Random rand) {
    // 2–3 digit/letter after airline; keep it mostly numeric for realism
    final numPart = 100 + rand.nextInt(800); // 100–899
    // Occasionally append a letter suffix (A/B)
    final maybeSuffix =
        rand.nextInt(10) == 0 ? String.fromCharCode(65 + rand.nextInt(2)) : '';
    return '$airline$numPart$maybeSuffix';
  }
}

class _Airport {
  final String code;
  final String city;
  const _Airport(this.code, this.city);
}
