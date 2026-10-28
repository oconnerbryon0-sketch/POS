import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/categories_table.dart';
import 'tables/payment_methods_table.dart';
import 'tables/products_table.dart';
import 'tables/stock_logs_table.dart';
import 'tables/sync_queues_table.dart';
import 'tables/transaction_items_table.dart';
import 'tables/transactions_table.dart';

part 'app_database.g.dart';
part 'daos/product_dao.dart';
part 'daos/stock_dao.dart';
part 'daos/transaction_dao.dart';

@DriftDatabase(
  tables: [
    Categories,
    Products,
    Transactions,
    TransactionItems,
    PaymentMethods,
    StockLogs,
    SyncQueues,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedDefaultData();
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          // Index bersifat idempotent (IF NOT EXISTS), aman dipanggil tiap buka.
          await _createIndexes();
        },
        onUpgrade: (m, from, to) async {
          if (from < 1) {
            await m.createAll();
          }
        },
      );

  Future<void> _seedDefaultData() async {
    await _seedPaymentMethods();
  }

  /// Menjalankan pembuatan index strategis untuk performa < 50ms
  /// walau dengan > 10.000 data produk.
  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_product_barcode ON products(barcode)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_product_sku ON products(sku)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_product_name_active '
      'ON products(name, is_active)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_product_category_active '
      'ON products(category_id, is_active)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_transaction_date '
      'ON transactions(created_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_txitem_transaction '
      'ON transaction_items(transaction_id, product_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_stocklog_product '
      'ON stock_logs(product_id, created_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_syncqueue_unsynced '
      'ON sync_queues(is_synced, created_at)',
    );
  }

  Future<void> _seedPaymentMethods() async {
    final existing = await select(paymentMethods).get();
    if (existing.isNotEmpty) return;

    final defaults = <(String, String, int)>[
      ('Tunai', 'cash', 0),
      ('QRIS', 'qris', 1),
      ('Transfer Bank', 'bank_transfer', 2),
      ('Debit', 'debit_card', 3),
      ('Kredit', 'credit_card', 4),
    ];

    for (final (name, icon, order) in defaults) {
      await into(paymentMethods).insert(
        PaymentMethodsCompanion.insert(
          name: name,
          iconName: Value(icon),
          sortOrder: Value(order),
        ),
      );
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'pos_database.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
