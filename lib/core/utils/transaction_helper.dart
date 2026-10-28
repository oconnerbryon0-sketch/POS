class TransactionHelper {
  TransactionHelper._();

  /// Format: TX-YYYYMMDD-HHmmss-XXXX
  static String generateNumber(DateTime? time) {
    final now = time ?? DateTime.now();
    final date = '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
    final t = '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
    final random = (now.microsecondsSinceEpoch % 10000)
        .toString()
        .padLeft(4, '0');
    return 'TX-$date-$t-$random';
  }
}
