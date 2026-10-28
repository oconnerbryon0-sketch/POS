class DbConstants {
  DbConstants._();

  // Prisma/pagination defaults
  static const int defaultPageSize = 50;
  static const int searchLimit = 100;

  // Stock log change types
  static const String stockChangeSale = 'sale';
  static const String stockChangeAdjustment = 'adjustment';
  static const String stockChangeReturn = 'return';
  static const String stockChangeRestock = 'restock';
  static const String stockChangeDamage = 'damage';

  // Discount types
  static const String discountNone = 'none';
  static const String discountPercentage = 'percentage';
  static const String discountFixed = 'fixed';

  // Transaction status
  static const String txStatusCompleted = 'completed';
  static const String txStatusCancelled = 'cancelled';
  static const String txStatusVoid = 'void';

  // Sync reference types
  static const String refTypeTransaction = 'transaction';
  static const String refTypeManualAdjustment = 'manual_adjustment';
}
