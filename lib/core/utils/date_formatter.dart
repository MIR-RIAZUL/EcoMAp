import 'package:intl/intl.dart';

class DateFormatter {
  static String formatFullDate(DateTime dateTime) {
    return DateFormat('MMMM d, y').format(dateTime);
  }

  static String formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM d, y • h:mm a').format(dateTime);
  }

  static String formatMonthYear(DateTime dateTime) {
    return DateFormat('MMMM y').format(dateTime);
  }

  static String formatMonth(DateTime dateTime) {
    return DateFormat('MMMM').format(dateTime);
  }

  static String formatYear(DateTime dateTime) {
    return DateFormat('y').format(dateTime);
  }

  static String formatShortDate(DateTime dateTime) {
    return DateFormat('MMM d').format(dateTime);
  }

  static String formatRelative(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0 && dateTime.day == now.day) {
      return 'Today';
    } else if (difference.inDays <= 1 && dateTime.day == now.day - 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7 && difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, y').format(dateTime);
    }
  }
}
