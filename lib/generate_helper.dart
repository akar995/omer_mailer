import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Pure-Dart ZIP minimal reader/writer just enough to patch xl/styles.xml.
/// - Rebuilds the ZIP with all files STORED (no compression) to avoid needing
///   a deflate encoder on every platform.
/// - Patches any <numFmt numFmtId="..."> with id < 164 => id + 400.
Uint8List sanitizeNumFmtIdsInXlsx(Uint8List zipBytes) {
  if (kIsWeb) return zipBytes; // no zlib/IO on web; leave as-is

  // ---- helpers (little-endian) ----
  int _le16(ByteData d, int o) => d.getUint16(o, Endian.little);
  int _le32(ByteData d, int o) => d.getUint32(o, Endian.little);
  void _putLe16(ByteData d, int o, int v) => d.setUint16(o, v, Endian.little);
  void _putLe32(ByteData d, int o, int v) => d.setUint32(o, v, Endian.little);

  // ---- find End of Central Directory (EOCD) ----
  final bd = zipBytes.buffer.asByteData();
  const eocdSig = 0x06054b50;
  int eocd = -1;
  final minEOCD = zipBytes.length - 22;
  final scanStart = (zipBytes.length - 22).clamp(0, zipBytes.length - 1);
  final scanEnd = (zipBytes.length - 65536).clamp(0, scanStart);
  for (int i = scanStart; i >= scanEnd; i--) {
    if (_le32(bd, i) == eocdSig) {
      eocd = i;
      break;
    }
  }
  if (eocd < 0) return zipBytes; // not a zip? bail out

  final cdSize = _le32(bd, eocd + 12);
  final cdOffset = _le32(bd, eocd + 16);
  final cdEnd = cdOffset + cdSize;

  // ---- walk Central Directory ----
  const cdhSig = 0x02014b50;
  const lfhSig = 0x04034b50;

  final entries = <_ZipEntry>[];

  int p = cdOffset;
  while (p < cdEnd) {
    if (_le32(bd, p) != cdhSig) break;

    // central dir header layout
    final method = _le16(bd, p + 10);
    final crc32 = _le32(bd, p + 16);
    final compSize = _le32(bd, p + 20);
    final uncompSize = _le32(bd, p + 24);
    final nameLen = _le16(bd, p + 28);
    final extraLen = _le16(bd, p + 30);
    final commentLen = _le16(bd, p + 32);
    final relOfs = _le32(bd, p + 42);
    final name = utf8.decode(zipBytes.sublist(p + 46, p + 46 + nameLen));

    // local header to get data start
    final lfh = relOfs;
    if (_le32(bd, lfh) != lfhSig) return zipBytes; // corrupt

    final lNameLen = _le16(bd, lfh + 26);
    final lExtraLen = _le16(bd, lfh + 28);
    final dataStart = lfh + 30 + lNameLen + lExtraLen;

    // read compressed data slice
    final comp =
        Uint8List.sublistView(zipBytes, dataStart, dataStart + compSize);

    // decompress if needed (method 8 = deflate, 0 = store)
    Uint8List raw;
    if (method == 0) {
      raw = comp;
    } else if (method == 8) {
      // deflate (raw=true because ZIP stores raw-deflate streams)
      final z = ZLibDecoder(raw: true);
      raw = Uint8List.fromList(z.convert(comp));
    } else {
      // unsupported method; bail safely
      return zipBytes;
    }

    entries.add(_ZipEntry(name: name, data: raw));

    // move next central dir entry
    p = p + 46 + nameLen + extraLen + commentLen;
  }

// ---- patch styles.xml if present ----
  for (final e in entries) {
    if (e.name == 'xl/styles.xml') {
      String xmlStr = utf8.decode(e.data);

      // 1) Collect ONLY the numFmtIds that actually have <numFmt ...> nodes
      //    and are < 164 (i.e., illegal custom range).
      final numFmtRegex = RegExp(
          r'''<numFmt\b[^>]*\bnumFmtId=["'](\d+)["'][^>]*>''',
          multiLine: true);
      final idsToBump = <int>{};
      for (final m in numFmtRegex.allMatches(xmlStr)) {
        final id = int.tryParse(m.group(1) ?? '');
        if (id != null && id < 164) idsToBump.add(id);
      }

      if (idsToBump.isNotEmpty) {
        // 2) For each offending id, bump it in BOTH the <numFmt> definitions
        //    AND any <xf ... numFmtId="..."> references. Leave other ids alone.
        for (final oldId in idsToBump) {
          final newId = 400 + oldId;

          // Replace exact attribute occurrences with either " or ' quotes.
          xmlStr = xmlStr
              .replaceAll('numFmtId="$oldId"', 'numFmtId="$newId"')
              .replaceAll("numFmtId='$oldId'", "numFmtId='$newId'");
        }

        // (Optional) The <numFmts count="..."> value can stay as-is. We only changed IDs.
      }

      e.data = Uint8List.fromList(utf8.encode(xmlStr));
      break;
    }
  }

  // ---- rebuild ZIP (STORE all files) ----
  final out = BytesBuilder();
  final central = BytesBuilder();
  final fileRecords = <_CentralRecord>[];

  int offset = 0;
  for (final e in entries) {
    final nameBytes = utf8.encode(e.name);
    final crc = _crc32(e.data);

    // Local File Header
    final lfh = ByteData(30);
    _putLe32(lfh, 0, lfhSig);
    _putLe16(lfh, 4, 20); // version
    _putLe16(lfh, 6, 0); // flags
    _putLe16(lfh, 8, 0); // method = STORE
    _putLe16(lfh, 10, 0); // time
    _putLe16(lfh, 12, 0); // date
    _putLe32(lfh, 14, crc);
    _putLe32(lfh, 18, e.data.length);
    _putLe32(lfh, 22, e.data.length);
    _putLe16(lfh, 26, nameBytes.length);
    _putLe16(lfh, 28, 0); // extra len

    out.add(lfh.buffer.asUint8List());
    out.add(nameBytes);
    out.add(e.data);

    final thisLocalOffset = offset;
    offset += 30 + nameBytes.length + e.data.length;

    fileRecords.add(_CentralRecord(
      nameBytes: nameBytes,
      crc: crc,
      size: e.data.length,
      compSize: e.data.length,
      localHeaderOffset: thisLocalOffset,
    ));
  }

  // Central Directory
  final cdStart = offset;
  for (final r in fileRecords) {
    final cdh = ByteData(46);
    _putLe32(cdh, 0, cdhSig);
    _putLe16(cdh, 4, 20); // version made by
    _putLe16(cdh, 6, 20); // version needed
    _putLe16(cdh, 8, 0); // flags
    _putLe16(cdh, 10, 0); // method
    _putLe16(cdh, 12, 0); // time
    _putLe16(cdh, 14, 0); // date
    _putLe32(cdh, 16, r.crc);
    _putLe32(cdh, 20, r.compSize);
    _putLe32(cdh, 24, r.size);
    _putLe16(cdh, 28, r.nameBytes.length);
    _putLe16(cdh, 30, 0); // extra len
    _putLe16(cdh, 32, 0); // comment len
    _putLe16(cdh, 34, 0); // disk start
    _putLe16(cdh, 36, 0); // internal attr
    _putLe32(cdh, 38, 0); // external attr
    _putLe32(cdh, 42, r.localHeaderOffset);

    central.add(cdh.buffer.asUint8List());
    central.add(r.nameBytes);
    offset += 46 + r.nameBytes.length;
  }
  final cdBytes = central.toBytes();
  out.add(cdBytes);

  // EOCD
  final eocdBd = ByteData(22);
  _putLe32(eocdBd, 0, eocdSig);
  _putLe16(eocdBd, 4, 0); // disk num
  _putLe16(eocdBd, 6, 0); // cd start disk
  _putLe16(eocdBd, 8, fileRecords.length);
  _putLe16(eocdBd, 10, fileRecords.length);
  _putLe32(eocdBd, 12, cdBytes.length);
  _putLe32(eocdBd, 16, cdStart);
  _putLe16(eocdBd, 20, 0); // comment len
  out.add(eocdBd.buffer.asUint8List());

  return out.toBytes();
}

// simple CRC32 (IEEE 802.3) — no dependency
int _crc32(Uint8List data) {
  const poly = 0xEDB88320;
  final table = List<int>.generate(256, (n) {
    var c = n;
    for (int k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? (poly ^ (c >>> 1)) : (c >>> 1);
    }
    return c;
  });
  var crc = 0xFFFFFFFF;
  for (final b in data) {
    crc = table[(crc ^ b) & 0xFF] ^ (crc >>> 8);
  }
  return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}

class _ZipEntry {
  _ZipEntry({required this.name, required this.data});
  final String name;
  Uint8List data;
}

class _CentralRecord {
  _CentralRecord({
    required this.nameBytes,
    required this.crc,
    required this.size,
    required this.compSize,
    required this.localHeaderOffset,
  });
  final List<int> nameBytes;
  final int crc;
  final int size;
  final int compSize;
  final int localHeaderOffset;
}
