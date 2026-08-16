import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _fullDateFormat = DateFormat('EEEE d MMMM yyyy', 'fr_FR');
  static final DateFormat _shortDateFormat = DateFormat('dd/MM/yyyy', 'fr_FR');
  static final DateFormat _mediumDateFormat = DateFormat('d MMMM yyyy', 'fr_FR');
  static final DateFormat _dayOfWeekFormat = DateFormat('EEEE', 'fr_FR');
  static final DateFormat _shortDayOfWeekFormat = DateFormat('EEE', 'fr_FR');
  static final DateFormat _apiDateFormat = DateFormat('yyyy-MM-dd');
  static final NumberFormat _currencyFormat = NumberFormat('#,##0.##', 'fr_FR');

  static String formatFull(DateTime date) {
    final formatted = _fullDateFormat.format(date);
    return formatted.isEmpty ? '' : '${formatted[0].toUpperCase()}${formatted.substring(1)}';
  }

  static String formatShort(DateTime date) {
    return _shortDateFormat.format(date);
  }

  static String formatMedium(DateTime date) {
    return _mediumDateFormat.format(date);
  }

  static String formatDayOfWeek(DateTime date) {
    final formatted = _dayOfWeekFormat.format(date);
    return formatted.isEmpty ? '' : '${formatted[0].toUpperCase()}${formatted.substring(1)}';
  }

  static String formatShortDayOfWeek(DateTime date) {
    return _shortDayOfWeekFormat.format(date).toUpperCase();
  }

  static String toApiString(DateTime date) {
    return _apiDateFormat.format(date);
  }

  static DateTime? fromApiString(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      try {
        return _apiDateFormat.parse(dateStr);
      } catch (_) {
        return null;
      }
    }
  }

  static String formatCurrency(num? amount, {String currency = 'DA'}) {
    if (amount == null) return '0 $currency';
    return '${_currencyFormat.format(amount)} $currency';
  }
}






