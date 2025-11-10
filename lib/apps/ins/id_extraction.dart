class IdExtractedData {
  String? firstName;
  String? lastName;
  String? fullName;
  String? documentNumber;
  String? sex; // 'm' or 'f'
  String? address;
  String? issuingCountry;
  DateTime? dob;
  DateTime? expiry;
  final Map<String, String> raw;

  IdExtractedData({
    this.firstName,
    this.lastName,
    this.fullName,
    this.documentNumber,
    this.sex,
    this.address,
    this.issuingCountry,
    this.dob,
    this.expiry,
    Map<String, String>? raw,
  }) : raw = raw ?? {};

  bool get isEmpty =>
      firstName == null && lastName == null && fullName == null && documentNumber == null && dob == null && sex == null && address == null;
}

class IdExtraction {
  // --- AAMVA PDF417 ---
  // Parses common DL/ID (AAMVA) PDF417 payloads
  static IdExtractedData? parseAAMVAFromPdf417(String rawValue) {
    if (rawValue.isEmpty) return null;
    // Normalize line breaks
    final text = rawValue.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    // Basic sanity: many AAMVA start with "@" and an ANSI header, but not always
    if (!text.contains('ANSI') && !text.contains('DL') && !text.contains('ID')) {
      // still try to parse by field tags
    }

    final data = <String, String>{};
    // Extract triplets like DCS/DAC/DBB/etc. by scanning lines
    for (final line in text.split('\n')) {
      if (line.length < 3) continue;
      final tag = line.substring(0, 3);
      final val = line.length > 3 ? line.substring(3).trim() : '';
      if (_isFieldTag(tag)) {
        data[tag] = val;
      }
    }

    // Some payloads are not line-delimited; try greedy extraction of tags
    if (data.isEmpty) {
      final re = RegExp(r'([A-Z]{3})([^A-Z]+)');
      for (final m in re.allMatches(text)) {
        final tag = m.group(1)!;
        final val = (m.group(2) ?? '').trim();
        if (_isFieldTag(tag) && val.isNotEmpty) data[tag] = val;
      }
    }

    if (data.isEmpty) return null;

    String? last = data['DCS']; // Last Name
    String? first = data['DAC']; // First Name
  // Note: some payloads expose Middle Name via DAD; currently unused
    String? fullName = data['DAA']; // Full name (optional)
    String? docNumber = data['DAQ'] ?? data['DBJ']; // ID number (DAQ typical)
    String? sexCode = data['DBC']; // 1=Male,2=Female,9=Not Specified
    String? addr1 = data['DAG'];
    String? city = data['DAI'];
    String? state = data['DAJ'];
    String? zip = data['DAK'];
    String? country = data['DCG'];

    DateTime? dob = _parseAamvaDate(data['DBB']);
    DateTime? expiry = _parseAamvaDate(data['DBA']);

    // Some versions use DCT for given names combined
    if ((first == null || first.isEmpty) && data['DCT'] != null) {
      final parts = data['DCT']!.split(',');
      if (parts.isNotEmpty) first = parts.first.trim();
    }

    // If only DAA provided, split into LAST, FIRST components
    if ((first == null || last == null) && fullName != null && fullName.isNotEmpty) {
      // DAA often formatted as "LAST,FIRST MIDDLE" or "LAST$FIRST$MIDDLE"
      if (fullName.contains(',')) {
        final parts = fullName.split(',');
        if (parts.length >= 2) {
          last ??= parts[0].trim();
          final given = parts[1].trim();
          if (given.isNotEmpty) {
            final gParts = given.split(' ');
            first ??= gParts.first.trim();
          }
        }
      } else if (fullName.contains('\$')) {
        final parts = fullName.split('\$');
        if (parts.length >= 2) {
          last ??= parts[0].trim();
          first ??= parts[1].trim();
        }
      }
    }

    String? address;
    if (addr1 != null && addr1.isNotEmpty) {
      final buf = StringBuffer(addr1);
      if (city != null && city.isNotEmpty) buf.write(', $city');
      if (state != null && state.isNotEmpty) buf.write(', $state');
      if (zip != null && zip.isNotEmpty) buf.write(' $zip');
      address = buf.toString();
    }

    String? sex;
    if (sexCode != null) {
      if (sexCode == '1') sex = 'm';
      if (sexCode == '2') sex = 'f';
    }

    if (first == null && last == null && fullName == null && docNumber == null && dob == null) return null;

    return IdExtractedData(
      firstName: _clean(first),
      lastName: _clean(last),
      fullName: _clean(fullName),
      documentNumber: _clean(docNumber),
      sex: sex,
      address: address,
      issuingCountry: _clean(country),
      dob: dob,
      expiry: expiry,
      raw: data,
    );
  }

  static bool _isFieldTag(String tag) {
    const known = {
      'DAA','DAB','DAC','DAD','DAE','DAF','DAG','DAH','DAI','DAJ','DAK','DAL','DAM','DAN','DAO','DAP','DAQ','DAR','DAS','DAT','DAU','DAV','DAW','DAX','DAY','DAZ',
      'DBA','DBB','DBC','DBD','DBE','DBF','DBG','DBH','DBI','DBJ','DBK','DBL','DBM','DBN','DBO','DBP','DBQ','DBR','DBS','DBT','DBU','DBV','DBW','DBX','DBY','DBZ',
      'DCA','DCB','DCD','DCE','DCF','DCG','DCH','DCI','DCJ','DCK','DCL','DCM','DCN','DCO','DCP','DCQ','DCR','DCS','DCT','DCU','DCV','DCW','DCX','DCY','DCZ',
      'DDA','DDB','DDC','DDD','DDE','DDF','DDG','DDH','DDI','DDJ','DDK','DDL','DDM','DDN','DDO','DDP','DDQ','DDR','DDS','DDT','DDU','DDV','DDW','DDX','DDY','DDZ',
      'DTH'
    };
    return known.contains(tag);
  }

  static DateTime? _parseAamvaDate(String? s) {
    if (s == null) return null;
    final t = s.replaceAll(RegExp(r'[^0-9]'), '');
    if (t.length == 8) {
      // Could be YYYYMMDD or MMDDYYYY; guess based on first 4 digits plausible year
      final y = int.tryParse(t.substring(0, 4));
      if (y != null && y > 1900 && y <= DateTime.now().year + 20) {
        final m = int.tryParse(t.substring(4, 6)) ?? 1;
        final d = int.tryParse(t.substring(6, 8)) ?? 1;
        return DateTime(y, m, d);
      }
      // Try MMDDYYYY
      final m = int.tryParse(t.substring(0, 2)) ?? 1;
      final d = int.tryParse(t.substring(2, 4)) ?? 1;
      final y2 = int.tryParse(t.substring(4, 8)) ?? 1900;
      return DateTime(y2, m, d);
    }
    return null;
  }

  static String _clean(String? s) => (s ?? '').trim().replaceAll('<', ' ').replaceAll(RegExp(r'\s+'), ' ');

  // --- MRZ ---
  static IdExtractedData? parseMRZ(String text) {
    final lines = text.toUpperCase().split(RegExp(r'\r?\n')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (lines.length < 2) return null;

    // Try TD3 (passport) - 2 lines of 44 chars; line1 starts with P<
    final td3 = _tryParseTD3(lines);
    if (td3 != null) return td3;

    // Try TD1/TD2 (ID cards)
    final td1 = _tryParseTD1(lines);
    if (td1 != null) return td1;

    final td2 = _tryParseTD2(lines);
    if (td2 != null) return td2;

    return null;
  }

  static IdExtractedData? _tryParseTD3(List<String> lines) {
    // Find lines containing P<
    int idx = lines.indexWhere((l) => l.startsWith('P<'));
    if (idx < 0 || idx + 1 >= lines.length) return null;
    final l1 = lines[idx];
    final l2 = lines[idx + 1];
    if (l2.length < 28) return null;

    // Names on line 1 after 2-letter type and country (positions 0-2 and 2-5)
    final namesPart = l1.substring(2).split('<<');
    String surname = namesPart.isNotEmpty ? namesPart[0].replaceAll('<', ' ').trim() : '';
    String given = namesPart.length > 1 ? namesPart[1].replaceAll('<', ' ').trim() : '';

    // Birth: line2 positions 13-18 (YYMMDD)
    final birthRaw = l2.substring(13, 19).replaceAll('<', '0');
    final birth = _parseYYMMDD(birthRaw);
    // Sex: pos 20
    final sexChar = (l2.length > 20 ? l2[20] : '<');
    String? sex;
    if (sexChar == 'M') sex = 'm';
    if (sexChar == 'F') sex = 'f';
    // Expiry: pos 21-26
    final expRaw = l2.substring(21, 27).replaceAll('<', '0');
    final exp = _parseYYMMDD(expRaw);

    if (surname.isEmpty && given.isEmpty && birth == null) return null;

    return IdExtractedData(
      lastName: surname,
      firstName: given.split(' ').isNotEmpty ? given.split(' ').first : given,
      fullName: (given.isNotEmpty ? '$given ' : '') + surname,
      sex: sex,
      dob: birth,
      expiry: exp,
    );
  }

  static IdExtractedData? _tryParseTD1(List<String> lines) {
    // TD1 uses 3 lines; try to find a block of 3 consecutive MRZ-like lines
    for (int i = 0; i + 2 < lines.length; i++) {
      final a = lines[i];
      final b = lines[i + 1];
      final c = lines[i + 2];
      if ((a.length >= 30 && b.length >= 30 && c.length >= 30) &&
          (a.contains('<') && b.contains('<') && c.contains('<'))) {
        // Names often on line 3
        final namePart = c.split('<<');
        String surname = namePart.isNotEmpty ? namePart[0].replaceAll('<', ' ').trim() : '';
        String given = namePart.length > 1 ? namePart[1].replaceAll('<', ' ').trim() : '';
        // Birth often on line 2 positions 0-5 (YYMMDD)
        DateTime? birth;
        if (b.length >= 6) {
          final birthRaw = b.substring(0, 6).replaceAll('<', '0');
          birth = _parseYYMMDD(birthRaw);
        }
        String? sex;
        if (b.length > 7) {
          final ch = b[7];
          if (ch == 'M') sex = 'm';
          if (ch == 'F') sex = 'f';
        }
        if (surname.isEmpty && given.isEmpty && birth == null) continue;
        return IdExtractedData(
          lastName: surname,
          firstName: given.split(' ').isNotEmpty ? given.split(' ').first : given,
          fullName: (given.isNotEmpty ? '$given ' : '') + surname,
          sex: sex,
          dob: birth,
        );
      }
    }
    return null;
  }

  static IdExtractedData? _tryParseTD2(List<String> lines) {
    // TD2 uses 2 lines of 36 chars; names typically on line 2
    for (int i = 0; i + 1 < lines.length; i++) {
      final a = lines[i];
      final b = lines[i + 1];
      if ((a.length >= 30 && b.length >= 30) && a.contains('<') && b.contains('<')) {
        final namePart = b.split('<<');
        String surname = namePart.isNotEmpty ? namePart[0].replaceAll('<', ' ').trim() : '';
        String given = namePart.length > 1 ? namePart[1].replaceAll('<', ' ').trim() : '';
        DateTime? birth;
        if (a.length >= 20) {
          final birthRaw = a.substring(13, 19).replaceAll('<', '0');
          birth = _parseYYMMDD(birthRaw);
        }
        String? sex;
        if (a.length > 20) {
          final ch = a[20];
          if (ch == 'M') sex = 'm';
          if (ch == 'F') sex = 'f';
        }
        if (surname.isEmpty && given.isEmpty && birth == null) continue;
        return IdExtractedData(
          lastName: surname,
          firstName: given.split(' ').isNotEmpty ? given.split(' ').first : given,
          fullName: (given.isNotEmpty ? '$given ' : '') + surname,
          sex: sex,
          dob: birth,
        );
      }
    }
    return null;
  }

  static DateTime? _parseYYMMDD(String s) {
    if (s.length != 6) return null;
    final yy = int.tryParse(s.substring(0, 2)) ?? 0;
    final mm = int.tryParse(s.substring(2, 4)) ?? 1;
    final dd = int.tryParse(s.substring(4, 6)) ?? 1;
    final nowYY = DateTime.now().year % 100;
    // Heuristic century: if YY > current YY, it's 1900s, else 2000s
    final century = (yy > nowYY) ? 1900 : 2000;
    return DateTime(century + yy, mm, dd);
  }

  // ---- Fallback OCR text heuristics ----
  static IdExtractedData? parseTextHeuristics(String text) {
    final t = text;
    // DOB patterns
    final dobRe = RegExp(r'(\b\d{4}[-/.]\d{2}[-/.]\d{2}\b)|(\b\d{2}[-/.]\d{2}[-/.]\d{4}\b)');
    DateTime? dob;
    final m = dobRe.firstMatch(t);
    if (m != null) {
      final s = m.group(0)!;
      final cleaned = s.replaceAll(RegExp(r'[^0-9]'), '-');
      final parts = cleaned.split('-').where((p) => p.isNotEmpty).toList();
      if (parts.length == 3) {
        if (parts[0].length == 4) {
          dob = DateTime.tryParse('${parts[0]}-${parts[1].padLeft(2, '0')}-${parts[2].padLeft(2, '0')}');
        } else {
          dob = DateTime.tryParse('${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}');
        }
      }
    }

    // Sex
    String? sex;
    if (RegExp(r'\bSEX\b|\bSEXE\b', caseSensitive: false).hasMatch(t)) {
      if (RegExp(r'\bM\b|\bMALE\b', caseSensitive: false).hasMatch(t)) sex = 'm';
      if (RegExp(r'\bF\b|\bFEMALE\b|\bFEMME\b', caseSensitive: false).hasMatch(t)) sex = 'f';
    }

    // Names (very heuristic)
    String? first;
    String? last;
    final lines = t.split(RegExp(r'\r?\n')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    for (final line in lines) {
      if (RegExp(r'^(NOM|NAME)[:\s-]', caseSensitive: false).hasMatch(line)) {
        final v = line.split(RegExp(r'[:\s-]')).skip(1).join(' ').trim();
        if (v.isNotEmpty) last ??= v.split(' ').first;
      }
      if (RegExp(r'^(PRÉ?NOM|GIVEN\s+NAMES?|FIRST\s+NAME)[:\s-]', caseSensitive: false).hasMatch(line)) {
        final v = line.split(RegExp(r'[:\s-]')).skip(1).join(' ').trim();
        if (v.isNotEmpty) first ??= v.split(' ').first;
      }
      if (first != null && last != null) break;
    }

    if (first == null && last == null && dob == null && sex == null) return null;
    return IdExtractedData(firstName: first, lastName: last, dob: dob, sex: sex);
  }
}
