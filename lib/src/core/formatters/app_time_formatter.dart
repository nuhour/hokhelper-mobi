import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

abstract final class AppTimeFormatter {
  static DateTime? parseLocal(String value) {
    final parsed = DateTime.tryParse(value.trim());
    return parsed?.toLocal();
  }

  static String relative(BuildContext context, String value) {
    final date = parseLocal(value);
    if (date == null) return '';
    final difference = DateTime.now().difference(date);
    if (difference.isNegative || difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    if (difference.inDays < 28) {
      return '${(difference.inDays / 7).floor()}w ago';
    }
    if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mo ago';
    }
    return '${(difference.inDays / 365).floor()}y ago';
  }

  static String dateTime(BuildContext context, String value) {
    final date = parseLocal(value);
    if (date == null) return '';
    final locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat.yMMMd(locale).add_Hm().format(date);
  }
}
