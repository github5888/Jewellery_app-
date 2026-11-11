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

  static String greetingForNow([DateTime? now]) {
    final hour = (now ?? DateTime.now()).hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  /// Prevents duplicate prefix like "Dr. Dr. Ajay Verma" if backend `name` already includes "Dr."
  static String formatDoctorName(String rawName, [String rawSurname = '']) {
    final combined = '${rawName.trim()} ${rawSurname.trim()}'.trim();
    if (combined.isEmpty) return 'Unassigned Doctor';
    final normalized = combined.replaceAll(
      RegExp(r'^(dr\.?\s+)+', caseSensitive: false),
      '',
    );
    if (normalized.isEmpty) return combined;
    return 'Dr. $normalized';
  }

  static String initials(String fullName) {
    final cleaned = fullName
        .replaceAll(RegExp(r'^(dr\.?|mr\.?|mrs\.?|ms\.?|nurse)\s+', caseSensitive: false), '')
        .trim();
    if (cleaned.isEmpty) return 'NP';
    final parts = cleaned.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) {
      final first = parts.first;
      return first.substring(0, first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static String formatDateShort(DateTime? dt) {
    if (dt == null) return '—';
    final d = dt.toLocal();
    final day = d.day.toString().padLeft(2, '0');
    final mon = _monthsShort[d.month - 1];
    return '$day $mon ${d.year}';
  }

  static String formatFullDayDate(DateTime dt) {
    final d = dt.toLocal();
    final wd = _weekdaysShort[d.weekday - 1];
    final mon = _monthsShort[d.month - 1];
    return '$wd, $mon ${d.day}, ${d.year}';
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
}
