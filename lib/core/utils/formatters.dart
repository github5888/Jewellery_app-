class AppFormatters {
  AppFormatters._();

  static const List<String> _monthsShort = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const List<String> _weekdaysShort = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<String> _weekdaysLong = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static String greetingForNow([DateTime? now]) {
    final hour = (now ?? DateTime.now()).hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  /// Prevents duplicate prefix like "Dr. Dr. Ajay Verma" if backend `name` already includes "Dr."
  static String formatDoctorName(String rawName, [String rawSurname = '']) {
    final combined = '${rawName.trim()} ${rawSurname.trim()}'.trim();
    if (combined.isEmpty) return '—';
    final normalized = combined.replaceAll(
      RegExp(r'^(dr\.?\s+)+', caseSensitive: false),
      '',
    );
    if (normalized.isEmpty) return combined;
    return 'Dr. $normalized';
  }

  static String initials(String fullName) {
    final cleaned = fullName
        .replaceAll(
          RegExp(r'^(dr\.?|mr\.?|mrs\.?|ms\.?|nurse)\s+', caseSensitive: false),
          '',
        )
        .trim();
    if (cleaned.isEmpty) return 'NP';
    final parts =
        cleaned.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) {
      final first = parts.first;
      return first.substring(0, first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  /// `10 Nov 2026`
  static String formatDateShort(DateTime? dt) {
    if (dt == null) return '—';
    final d = dt.toLocal();
    final day = d.day.toString().padLeft(2, '0');
    final mon = _monthsShort[d.month - 1];
    return '$day $mon ${d.year}';
  }

  /// `21/10/2026` (matches Dashboard & IPD table in image-5 & image-8)
  static String formatSlashDate(DateTime? dt) {
    if (dt == null) return '—';
    final d = dt.toLocal();
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }

  /// `Tue, 24 Nov, 2026` (matches Annual Calendar in image-11)
  static String formatCalendarDate(DateTime? dt) {
    if (dt == null) return '—';
    final d = dt.toLocal();
    final wd = _weekdaysShort[d.weekday - 1];
    final dd = d.day.toString().padLeft(2, '0');
    final mon = _monthsShort[d.month - 1];
    return '$wd, $dd $mon, ${d.year}';
  }

  /// `Wednesday, Nov 11, 2026` (matches Dashboard date chip in image-4)
  static String formatFullDayDate(DateTime dt) {
    final d = dt.toLocal();
    final wd = _weekdaysLong[d.weekday - 1];
    final mon = _monthsShort[d.month - 1];
    return '$wd, $mon ${d.day}, ${d.year}';
  }

  /// `19:41` / `16:01` (matches OPD & IPD timestamps in image-7 & image-8)
  static String formatTime24h(DateTime? dt) {
    if (dt == null) return '';
    final d = dt.toLocal();
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  static String formatTime12h(DateTime? dt) {
    if (dt == null) return '—';
    final d = dt.toLocal();
    final h24 = d.hour;
    final period = h24 >= 12 ? 'PM' : 'AM';
    final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
    final hh = h12.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$hh:$mm $period';
  }

  static String formatDateTimeShort(DateTime? dt) {
    if (dt == null) return '—';
    return '${formatDateShort(dt)} • ${formatTime12h(dt)}';
  }

  /// `2026-11-11` (for Duty Roster date matching in image-10)
  static String formatIsoDate(DateTime dt) {
    final d = dt.toLocal();
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  static String timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatDateShort(dt);
  }

  static String formatCurrencyInr(num amount) {
    if (amount == amount.roundToDouble()) {
      return '₹${amount.toInt()}';
    }
    return '₹${amount.toStringAsFixed(2)}';
  }

  static String formatCurrencyTwoDecimals(num amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }
}
