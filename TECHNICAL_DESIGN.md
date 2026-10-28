# 🏪 POS (Point of Sale) - Technical Design Document
## Offline-First Mobile Kasir untuk UMKM

---

## Table of Contents

1. [Arsitektur Sistem](#1-arsitektur-sistem)
2. [Arsitektur Data & Skema Database](#2-arsitektur-data--skema-database)
3. [Alur Fitur Utama & Integrasi Hardware](#3-alur-fitur-utama--integrasi-hardware)
4. [Laporan & Ekspor Data](#4-laporan--ekspor-data)
5. [Contoh Potongan Kode Krusial](#5-contoh-potongan-kode-krusial)
6. [Strategi Sync & Cloud-Ready Architecture](#6-strategi-sync--cloud-ready-architecture)

---

## 1. Arsitektur Sistem

### 1.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      PRESENTATION LAYER                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────────┐  │
│  │ Dashboard │  │  Kasir   │  │Produk    │  │  Laporan   │  │
│  │    UI     │  │   UI     │  │  UI      │  │    UI      │  │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └─────┬──────┘  │
│       └──────────────┴─────────────┴───────────────┘         │
├─────────────────────────────────────────────────────────────┤
│                  STATE MANAGEMENT (Riverpod)                 │
│  ┌────────────┐ ┌──────────────┐ ┌───────────────────────┐  │
│  │CartProvider │ │ProductProvider│ │ TransactionProvider   │  │
│  └────────────┘ └──────────────┘ └───────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                    REPOSITORY LAYER                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────────┐  │
│  │ Product  │  │Transaction│  │  Stock   │  │   Report   │  │
│  │   Repo   │  │   Repo   │  │   Repo   │  │    Repo    │  │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └─────┬──────┘  │
├───────┴──────────────┴─────────────┴───────────────┴─────────┤
│                      DATA LAYER                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Drift (SQLite) Database                  │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌─────────┐ │   │
│  │  │ Products │ │Transacti-│ │  Stock   │ │Payment  │ │   │
│  │  │          │ │   ons    │ │  Logs    │ │ Methods │ │   │
│  │  └──────────┘ └──────────┘ └──────────┘ └─────────┘ │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │         Sync Engine (Future Cloud Backend)            │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐             │   │
│  │  │  Queue   │ │ Conflict │ │  Delta   │             │   │
│  │  │ Manager  │ │ Resolver │ │  Sync    │             │   │
│  │  └──────────┘ └──────────┘ └──────────┘             │   │
│  └──────────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────────┤
│                    HARDWARE LAYER                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │   Barcode    │  │   Thermal    │  │     Cash         │  │
│  │   Scanner    │  │   Printer    │  │     Drawer       │  │
│  │  (Camera)    │  │ (Bluetooth)  │  │  (via Printer)   │  │
│  └──────────────┘  └──────────────┘  └──────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 Dependency Stack

```yaml
# pubspec.yaml
dependencies:
  # Database
  drift: ^2.14.0            # SQLite ORM terbaik untuk Flutter
  sqlite3_flutter_libs: ^0.5.0
  
  # State Management
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.3.0
  
  # Hardware
  blue_thermal_printer: ^1.2.0    # Thermal printer bluetooth
  mobile_scanner: ^3.5.0          # Barcode/QR scanner
  
  # Export & Reporting
  pdf: ^3.10.0                    # PDF generation
  excel: ^4.0.0                   # Excel export
  printing: ^5.12.0               # PDF preview & share
  
  # Utils
  uuid: ^4.2.0                    # Unique ID generator
  intl: ^0.19.0                   # Date/number formatting
  path_provider: ^2.1.0           # File system access
  
dev_dependencies:
  drift_dev: ^2.14.0
  build_runner: ^2.4.0
  riverpod_generator: ^2.3.0
```

### 1.3 Folder Structure

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_strings.dart
│   │   └── database_constants.dart
│   ├── theme/
│   │   └── app_theme.dart
│   ├── utils/
│   │   ├── currency_formatter.dart
│   │   └── date_formatter.dart
│   └── extensions/
│       └── num_extension.dart
├── data/
│   ├── database/
│   │   ├── app_database.dart          # Drift database definition
│   │   ├── app_database.g.dart        # Generated code
│   │   ├── tables/
│   │   │   ├── products_table.dart
│   │   │   ├── categories_table.dart
│   │   │   ├── transactions_table.dart
│   │   │   ├── transaction_items_table.dart
│   │   │   ├── payment_methods_table.dart
│   │   │   └── stock_logs_table.dart
│   │   └── daos/
│   │       ├── product_dao.dart
│   │       ├── transaction_dao.dart
│   │       └── stock_dao.dart
│   ├── models/
│   │   ├── product.dart
│   │   ├── category.dart
│   │   ├── transaction.dart
│   │   ├── cart_item.dart
│   │   ├── payment_method.dart
│   │   └── stock_log.dart
│   └── repositories/
│       ├── product_repository.dart
│       ├── transaction_repository.dart
│       └── stock_repository.dart
├── providers/
│   ├── cart_provider.dart
│   ├── product_provider.dart
│   ├── transaction_provider.dart
│   ├── printer_provider.dart
│   └── report_provider.dart
├── presentation/
│   ├── screens/
│   │   ├── dashboard/
│   │   ├── kasir/
│   │   ├── products/
│   │   ├── reports/
│   │   └── settings/
│   ├── widgets/
│   │   ├── product_card.dart
│   │   ├── cart_list.dart
│   │   ├── payment_sheet.dart
│   │   └── receipt_preview.dart
│   └── dialogs/
│       ├── discount_dialog.dart
│       └── confirm_dialog.dart
└── services/
    ├── printer/
    │   ├── thermal_printer_service.dart
    │   └── esc_pos_generator.dart
    ├── scanner/
    │   └── barcode_scanner_service.dart
    └── export/
        ├── pdf_export_service.dart
        └── excel_export_service.dart
```

---

## 2. Arsitektur Data & Skema Database

### 2.1 Entity-Relationship Diagram

```
┌─────────────────┐     ┌─────────────────┐
│   categories    │     │    products     │
├─────────────────┤     ├─────────────────┤
│ id (PK)         │◄────│ category_id (FK)│
│ name            │     │ id (PK)         │
│ description     │     │ name            │
│ icon_name       │     │ barcode         │
│ sort_order      │     │ sku             │
│ created_at      │     │ price           │
│ updated_at      │     │ cost_price      │
│ is_active       │     │ stock_quantity  │
└─────────────────┘     │ min_stock       │
                        │ unit            │
                        │ image_path      │
                        │ is_active       │
                        │ created_at      │
                        │ updated_at      │
                        └────────┬────────┘
                                 │
                    ┌────────────┴──────────────┐
                    │                            │
          ┌─────────┴──────────┐    ┌────────────┴──────────┐
          │  transaction_items │    │     stock_logs        │
          ├────────────────────┤    ├───────────────────────┤
          │ id (PK)            │    │ id (PK)              │
          │ transaction_id(FK) │    │ product_id (FK)      │
          │ product_id (FK) ───┤    │ change_type          │
          │ quantity           │    │ quantity_change       │
          │ unit_price         │    │ previous_stock       │
          │ cost_price         │    │ new_stock            │
          │ discount_type      │    │ reference_id         │
          │ discount_value     │    │ reference_type       │
          │ subtotal           │    │ notes                │
          │ created_at         │    │ created_at           │
          └─────────┬──────────┘    └──────────────────────┘
                    │
          ┌─────────┴──────────┐
          │   transactions     │
          ├────────────────────┤
          │ id (PK)            │
          │ transaction_number │
          │ subtotal           │
          │ tax_amount         │
          │ discount_amount    │
          │ total_amount       │
          │ payment_method_id  │──────►┌─────────────────┐
          │ amount_paid        │       │ payment_methods │
          │ change_amount      │       ├─────────────────┤
          │ status             │       │ id (PK)         │
          │ notes              │       │ name            │
          │ created_at         │       │ icon_name       │
          │ updated_at         │       │ is_active       │
          │ synced_at (nullable)       │ sort_order      │
          └────────────────────┘       └─────────────────┘
```

### 2.2 Skema Tabel Lengkap (Drift)

#### Categories Table

```dart
// lib/data/database/tables/categories_table.dart
import 'package:drift/drift.dart';

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  TextColumn get iconName => text().withDefault(const Constant('category_default'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
```

#### Products Table

```dart
// lib/data/database/tables/products_table.dart
import 'package:drift/drift.dart';

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get barcode => text().nullable().unique()();
  TextColumn get sku => text().nullable().unique()();
  IntColumn get price => integer().withDefault(const Constant(0))(); // dalam sen/rupiah kecil
  IntColumn get costPrice => integer().withDefault(const Constant(0))();
  IntColumn get stockQuantity => integer().withDefault(const Constant(0))();
  IntColumn get minStock => integer().withDefault(const Constant(5))();
  TextColumn get unit => text().withDefault(const Constant('pcs'))();
  TextColumn get imagePath => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  // Indexing strategis untuk performa pencarian
  @override
  List<Set<Column>> get uniqueKeys => [{barcode}, {sku}];
}
```

#### Transactions Table

```dart
// lib/data/database/tables/transactions_table.dart
import 'package:drift/drift.dart';

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get transactionNumber => text().unique()();
  IntColumn get subtotal => integer().withDefault(const Constant(0))();
  IntColumn get taxAmount => integer().withDefault(const Constant(0))();
  IntColumn get discountAmount => integer().withDefault(const Constant(0))();
  IntColumn get totalAmount => integer().withDefault(const Constant(0))();
  IntColumn get paymentMethodId => integer().references(PaymentMethods, #id)();
  IntColumn get amountPaid => integer().withDefault(const Constant(0))();
  IntColumn get changeAmount => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('completed'))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().nullable()();
}
```

#### Transaction Items Table

```dart
// lib/data/database/tables/transaction_items_table.dart
import 'package:drift/drift.dart';

class TransactionItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get transactionId => integer().references(Transactions, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get quantity => integer()();
  IntColumn get unitPrice => integer()();
  IntColumn get costPrice => integer()();
  TextColumn get discountType => text().withDefault(const Constant('none'))();
  // 'none', 'percentage', 'fixed'
  IntColumn get discountValue => integer().withDefault(const Constant(0))();
  IntColumn get subtotal => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
```

#### Payment Methods Table

```dart
// lib/data/database/tables/payment_methods_table.dart
import 'package:drift/drift.dart';

class PaymentMethods extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get iconName => text().withDefault(const Constant('payment_default'))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}
```

#### Stock Logs Table

```dart
// lib/data/database/tables/stock_logs_table.dart
import 'package:drift/drift.dart';

class StockLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get changeType => text()();
  // 'sale', 'adjustment', 'return', 'restock', 'damage'
  IntColumn get quantityChange => integer()(); // negatif = pengurangan
  IntColumn get previousStock => integer()();
  IntColumn get newStock => integer()();
  IntColumn get referenceId => integer().nullable()();
  TextColumn get referenceType => text().nullable()();
  // 'transaction', 'manual_adjustment'
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
```

### 2.3 Strategi Indexing

```dart
// lib/data/database/app_database.dart
// Index definitions untuk performa optimal

@DriftDatabase(tables: [
  Categories,
  Products,
  Transactions,
  TransactionItems,
  PaymentMethods,
  StockLogs,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // AUTO-INCREMENT untuk migrasi
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedData();
    },
    onUpgrade: (m, from, to) async {
      // Future migration strategy
    },
  );

  // ========================
  // INDEXING STRATEGI
  // ========================

  // 1. Products: Index untuk pencarian barcode (scanning)
  // Query: SELECT * FROM products WHERE barcode = ?
  // Target: < 10ms
  Set<Index> get productBarcodeIndex => {
    Index('idx_product_barcode', 'CREATE INDEX idx_product_barcode ON products(barcode)'),
  };

  // 2. Products: Index untuk pencarian nama (autocomplete)
  // Query: SELECT * FROM products WHERE name LIKE '%query%' AND is_active = 1
  // Target: < 50ms untuk 10.000+ data
  Set<Index> get productNameIndex => {
    Index('idx_product_name', 
      'CREATE INDEX idx_product_name ON products(name, is_active)'),
  };

  // 3. Products: Composite index untuk filter kategori + pencarian
  // Query: SELECT * FROM products WHERE category_id = ? AND is_active = 1
  Set<Index> get productCategoryIndex => {
    Index('idx_product_category',
      'CREATE INDEX idx_product_category ON products(category_id, is_active)'),
  };

  // 4. Products: FTS (Full-Text Search) untuk pencarian fuzzy
  Set<Index> get productFTSIndex => {
    Index('idx_product_fts',
      'CREATE VIRTUAL TABLE products_fts USING fts5(name, barcode, sku, content=products, content_rowid=id)'),
  };

  // 5. Transactions: Index untuk laporan berdasarkan tanggal
  // Query: SELECT * FROM transactions WHERE created_at BETWEEN ? AND ?
  Set<Index> get transactionDateIndex => {
    Index('idx_transaction_date',
      'CREATE INDEX idx_transaction_date ON transactions(created_at)'),
  };

  // 6. TransactionItems: Index untuk join dengan transactions
  Set<Index> get transactionItemIndex => {
    Index('idx_transaction_item',
      'CREATE INDEX idx_transaction_item ON transaction_items(transaction_id, product_id)'),
  };

  // 7. StockLogs: Index untuk audit trail produk
  Set<Index> get stockLogIndex => {
    Index('idx_stock_log',
      'CREATE INDEX idx_stock_log ON stock_logs(product_id, created_at)'),
  };
}
```

### 2.4 Mekanisme Stok Atomic

```dart
// lib/data/database/daos/stock_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';

part 'stock_dao.g.dart';

@DriftAccessor(tables: [Products, StockLogs, TransactionItems])
class StockDao extends DatabaseAccessor<AppDatabase> with _$StockDaoMixin {
  StockDao(AppDatabase db) : super(db);

  // ============================================================
  // ATOMIC STOCK DEDUCTION - Mencegah Race Condition
  // ============================================================
  
  /// Mengurangi stok secara atomic menggunakan transaction SQLite.
  /// Menggunakan SELECT ... FOR UPDATE (pessimistic lock) pattern.
  /// 
  /// Flow:
  /// 1. Lock baris produk dengan SELECT + transaction
  /// 2. Validasi stok cukup
  /// 3. Update stok
  /// 4. Catat stock log
  /// 5. Commit atau Rollback
  Future<bool> deductStockAtomic({
    required int productId,
    required int quantity,
    required int transactionId,
  }) async {
    return await transaction(() async {
      // STEP 1: Lock dan baca stok terkini (pessimistic lock)
      final product = await (select(products)
        ..where((p) => p.id.equals(productId))
        ..limit(1))
        .getSingleOrNull();

      if (product == null) {
        throw StockException('Produk tidak ditemukan: ID $productId');
      }

      // STEP 2: Validasi stok
      if (product.stockQuantity < quantity) {
        throw InsufficientStockException(
          'Stok tidak cukup untuk ${product.name}. '
          'Tersedia: ${product.stockQuantity}, Dibutuhkan: $quantity',
        );
      }

      // STEP 3: Hitung stok baru
      final previousStock = product.stockQuantity;
      final newStock = previousStock - quantity;

      // STEP 4: Update stok produk
      await (update(products)..where((p) => p.id.equals(productId)))
        .write(ProductsCompanion(
          stockQuantity: Value(newStock),
          updatedAt: Value(DateTime.now()),
        ));

      // STEP 5: Catat stock log (audit trail)
      await into(stockLogs).insert(StockLogsCompanion(
        productId: Value(productId),
        changeType: const Value('sale'),
        quantityChange: Value(-quantity),
        previousStock: Value(previousStock),
        newStock: Value(newStock),
        referenceId: Value(transactionId),
        referenceType: const Value('transaction'),
        notes: Value('Penjualan - Transaksi #${transactionId}'),
        createdAt: Value(DateTime.now()),
      ));

      return true;
    });
  }

  /// Mengembalikan stok (untuk pembatalan transaksi)
  Future<bool> restoreStockAtomic({
    required int productId,
    required int quantity,
    required int transactionId,
    String reason = 'Pembatalan transaksi',
  }) async {
    return await transaction(() async {
      final product = await (select(products)
        ..where((p) => p.id.equals(productId))
        ..limit(1))
        .getSingleOrNull();

      if (product == null) throw StockException('Produk tidak ditemukan');

      final previousStock = product.stockQuantity;
      final newStock = previousStock + quantity;

      await (update(products)..where((p) => p.id.equals(productId)))
        .write(ProductsCompanion(
          stockQuantity: Value(newStock),
          updatedAt: Value(DateTime.now()),
        ));

      await into(stockLogs).insert(StockLogsCompanion(
        productId: Value(productId),
        changeType: const Value('return'),
        quantityChange: Value(quantity),
        previousStock: Value(previousStock),
        newStock: Value(newStock),
        referenceId: Value(transactionId),
        referenceType: const Value('transaction'),
        notes: Value(reason),
        createdAt: Value(DateTime.now()),
      ));

      return true;
    });
  }

  /// Bulk stock deduction untuk checkout multi-item
  /// Semua item harus berhasil, atau semua di-rollback
  Future<void> bulkDeductStock({
    required List<StockDeductionRequest> items,
    required int transactionId,
  }) async {
    await transaction(() async {
      for (final item in items) {
        await deductStockAtomic(
          productId: item.productId,
          quantity: item.quantity,
          transactionId: transactionId,
        );
      }
    });
  }

  /// Pencarian produk cepat dengan FTS
  Future<List<Product>> searchProducts(String query, {int limit = 50}) async {
    if (query.trim().isEmpty) {
      return (select(products)
        ..where((p) => p.isActive.equals(true))
        ..limit(limit))
        .get();
    }

    return await customSelect(
      'SELECT p.* FROM products p '
      'WHERE p.is_active = 1 '
      'AND (p.name LIKE :query OR p.barcode = :exact OR p.sku = :exact) '
      'ORDER BY '
      '  CASE WHEN p.barcode = :exact THEN 0 '
      '       WHEN p.sku = :exact THEN 1 '
      '       WHEN p.name LIKE :prefix THEN 2 '
      '       ELSE 3 END, '
      '  p.name ASC '
      'LIMIT :limit',
      variables: [
        Variable.withString('%$query%'),
        Variable.withString(query),
        Variable.withString(query),
        Variable.withInt(limit),
      ],
      readsFrom: {products},
    ).get();
  }

  // Seed data untuk payment methods default
  Future<void> _seedDefaultPaymentMethods() async {
    final defaults = [
      {'name': 'Tunai', 'icon': 'cash', 'order': 0},
      {'name': 'QRIS', 'icon': 'qris', 'order': 1},
      {'name': 'Transfer Bank', 'icon': 'bank_transfer', 'order': 2},
      {'name': 'Debit', 'icon': 'debit_card', 'order': 3},
      {'name': 'Kredit', 'icon': 'credit_card', 'order': 4},
    ];

    for (final method in defaults) {
      await into(paymentMethods).insert(PaymentMethodsCompanion(
        name: Value(method['name'] as String),
        iconName: Value(method['icon'] as String),
        sortOrder: Value(method['order'] as int),
      ));
    }
  }
}

// Custom exceptions
class StockException implements Exception {
  final String message;
  StockException(this.message);
  @override
  String toString() => 'StockException: $message';
}

class InsufficientStockException extends StockException {
  InsufficientStockException(super.message);
}

class StockDeductionRequest {
  final int productId;
  final int quantity;
  const StockDeductionRequest({required this.productId, required this.quantity});
}
```

---

## 3. Alur Fitur Utama & Integrasi Hardware

### 3.1 Modul Checkout/Kasir - Cart Logic

```dart
// lib/providers/cart_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/cart_item.dart';
import '../data/models/product.dart';

// Cart State
class CartState {
  final List<CartItem> items;
  final double taxRate;        // Default 11% PPN
  final double discountType;   // 0 = none, 1 = percentage, 2 = fixed
  final double discountValue;
  final String? discountNote;

  const CartState({
    this.items = const [],
    this.taxRate = 0.11,
    this.discountType = 0,
    this.discountValue = 0,
    this.discountNote,
  });

  // ========================
  // KALKULASI OTOMATIS
  // ========================

  /// Subtotal sebelum diskon & pajak
  double get subtotal => items.fold(0, (sum, item) => sum + item.subtotal);

  /// Total diskon
  double get discountAmount {
    switch (discountType) {
      case 1: // Persentase
        return subtotal * (discountValue / 100);
      case 2: // Nominal tetap
        return discountValue;
      default:
        return 0;
    }
  }

  /// Subtotal setelah diskon
  double get discountedSubtotal => subtotal - discountAmount;

  /// Pajak (PPN) dari subtotal setelah diskon
  double get taxAmount => discountedSubtotal * taxRate;

  /// Grand Total
  double get grandTotal => discountedSubtotal + taxAmount;

  /// Jumlah item di keranjang
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  CartState copyWith({
    List<CartItem>? items,
    double? taxRate,
    double? discountType,
    double? discountValue,
    String? discountNote,
  }) {
    return CartState(
      items: items ?? this.items,
      taxRate: taxRate ?? this.taxRate,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      discountNote: discountNote ?? this.discountNote,
    );
  }
}

// Cart Notifier
class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  // Tambah produk ke keranjang
  void addItem(Product product, {int quantity = 1}) {
    final existingIndex = state.items.indexWhere(
      (item) => item.productId == product.id,
    );

    if (existingIndex >= 0) {
      // Update quantity jika sudah ada
      final updatedItems = List<CartItem>.from(state.items);
      final existing = updatedItems[existingIndex];
      final newQty = existing.quantity + quantity;

      // Validasi stok
      if (newQty > product.stockQuantity) {
        throw InsufficientStockException(
          'Stok tidak cukup. Tersedia: ${product.stockQuantity}',
        );
      }

      updatedItems[existingIndex] = existing.copyWith(quantity: newQty);
      state = state.copyWith(items: updatedItems);
    } else {
      // Tambah item baru
      if (quantity > product.stockQuantity) {
        throw InsufficientStockException(
          'Stok tidak cukup. Tersedia: ${product.stockQuantity}',
        );
      }

      state = state.copyWith(
        items: [
          ...state.items,
          CartItem(
            productId: product.id,
            name: product.name,
            barcode: product.barcode,
            unitPrice: product.price.toDouble(),
            costPrice: product.costPrice.toDouble(),
            quantity: quantity,
            discountType: 0,
            discountValue: 0,
          ),
        ],
      );
    }
  }

  // Update quantity item
  void updateQuantity(int productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(productId);
      return;
    }

    final updatedItems = state.items.map((item) {
      if (item.productId == productId) {
        return item.copyWith(quantity: newQuantity);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
  }

  // Hapus item
  void removeItem(int productId) {
    state = state.copyWith(
      items: state.items.where((item) => item.productId != productId).toList(),
    );
  }

  // Set diskon persen
  void setPercentageDiscount(double percentage) {
    state = state.copyWith(
      discountType: 1,
      discountValue: percentage,
    );
  }

  // Set diskon nominal
  void setFixedDiscount(double amount) {
    state = state.copyWith(
      discountType: 2,
      discountValue: amount,
    );
  }

  // Hapus diskon
  void clearDiscount() {
    state = state.copyWith(
      discountType: 0,
      discountValue: 0,
    );
  }

  // Hitung uang kembalian
  double calculateChange(double amountPaid) {
    return amountPaid - state.grandTotal;
  }

  // Validasi pembayaran
  bool validatePayment(double amountPaid) {
    return amountPaid >= state.grandTotal;
  }

  // Clear keranjang
  void clear() {
    state = const CartState();
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
```

### 3.2 Cart Item Model

```dart
// lib/data/models/cart_item.dart
class CartItem {
  final int productId;
  final String name;
  final String? barcode;
  final double unitPrice;
  final double costPrice;
  final int quantity;
  final int discountType;  // 0=none, 1=percentage, 2=fixed
  final double discountValue;

  const CartItem({
    required this.productId,
    required this.name,
    this.barcode,
    required this.unitPrice,
    required this.costPrice,
    required this.quantity,
    this.discountType = 0,
    this.discountValue = 0,
  });

  /// Subtotal item sebelum diskon item
  double get subtotal => unitPrice * quantity;

  /// Diskon per item
  double get itemDiscount {
    switch (discountType) {
      case 1:
        return subtotal * (discountValue / 100);
      case 2:
        return discountValue;
      default:
        return 0;
    }
  }

  /// Subtotal setelah diskon item
  double get finalSubtotal => subtotal - itemDiscount;

  /// Profit per item
  double get profit => (unitPrice - costPrice) * quantity;

  CartItem copyWith({
    int? productId,
    String? name,
    String? barcode,
    double? unitPrice,
    double? costPrice,
    int? quantity,
    int? discountType,
    double? discountValue,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      unitPrice: unitPrice ?? this.unitPrice,
      costPrice: costPrice ?? this.costPrice,
      quantity: quantity ?? this.quantity,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
    );
  }
}
```

### 3.3 Integrasi Barcode Scanner

```dart
// lib/services/scanner/barcode_scanner_service.dart
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerService {
  MobileScannerController? _controller;
  
  /// Inisialisasi scanner
  MobileScannerController getController() {
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
      returnImage: false,
    );
    return _controller!;
  }

  /// Stream result dari scanner
  Stream<Barcode> get onBarcodeScanned {
    return _controller?.barcodes ?? const Stream.empty();
  }

  /// Toggle flashlight
  Future<void> toggleTorch() async {
    await _controller?.toggleTorch();
  }

  /// Dispose controller
  void dispose() {
    _controller?.dispose();
    _controller = null;
  }
}
```

**Widget Scanner di UI:**

```dart
// lib/presentation/screens/kasir/barcode_scanner_widget.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerWidget extends StatefulWidget {
  final Function(String barcode) onScanned;
  
  const BarcodeScannerWidget({super.key, required this.onScanned});

  @override
  State<BarcodeScannerWidget> createState() => _BarcodeScannerWidgetState();
}

class _BarcodeScannerWidgetState extends State<BarcodeScannerWidget> {
  late MobileScannerController _controller;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: (capture) {
            if (_isProcessing) return;
            
            final barcode = capture.barcodes.first.rawValue;
            if (barcode != null && barcode.isNotEmpty) {
              _isProcessing = true;
              widget.onScanned(barcode);
              
              // Debounce: delay 500ms sebelum scan berikutnya
              Future.delayed(const Duration(milliseconds: 500), () {
                _isProcessing = false;
              });
            }
          },
        ),
        // Overlay petunjuk scan area
        Center(
          child: Container(
            width: 280,
            height: 180,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green, width: 3),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

### 3.4 Integrasi Printer Thermal Bluetooth (ESC/POS)

```dart
// lib/services/printer/thermal_printer_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'esc_pos_generator.dart';

class ThermalPrinterService {
  final BlueThermalPrinter _printer = BlueThermalPrinter.instance;
  BluetoothDevice? _connectedDevice;
  
  // Check apakah printer tersambung
  Future<bool> get isConnected async => await _printer.isConnected ?? false;

  // Scan available bluetooth devices
  Future<List<BluetoothDevice>> scanDevices() async {
    return await _printer.getBondedDevices();
  }

  // Connect ke printer
  Future<bool> connect(BluetoothDevice device) async {
    try {
      await _printer.connect(device);
      _connectedDevice = device;
      return true;
    } catch (e) {
      return false;
    }
  }

  // Disconnect
  Future<void> disconnect() async {
    await _printer.disconnect();
    _connectedDevice = null;
  }

  // Print struk
  Future<bool> printReceipt(ReceiptData receipt) async {
    if (!await isConnected) {
      throw PrinterException('Printer tidak terhubung');
    }

    try {
      final bytes = EscPosGenerator.generateReceipt(receipt);
      await _printer.writeBytes(bytes);
      return true;
    } catch (e) {
      throw PrinterException('Gagal mencetak: $e');
    }
  }

  // Paper cut
  Future<void> cutPaper() async {
    if (!await isConnected) return;
    await _printer.writeBytes([0x1D, 0x56, 0x42, 0x00]); // Partial cut
  }
}

// Custom exception
class PrinterException implements Exception {
  final String message;
  PrinterException(this.message);
}
```

```dart
// lib/services/printer/esc_pos_generator.dart
import 'dart:convert';
import 'dart:typed_data';

class ReceiptData {
  final String storeName;
  final String? storeAddress;
  final String? storePhone;
  final String transactionNumber;
  final String dateTime;
  final List<ReceiptItem> items;
  final double subtotal;
  final double discount;
  final String? discountNote;
  final double tax;
  final double grandTotal;
  final String paymentMethod;
  final double amountPaid;
  final double change;
  final String? footer;
}

class ReceiptItem {
  final String name;
  final int quantity;
  final double unitPrice;
  final double subtotal;
}

class EscPosGenerator {
  // ESC/POS Commands
  static const _init = [0x1B, 0x40]; // Initialize printer
  static const _boldOn = [0x1B, 0x45, 0x01];
  static const _boldOff = [0x1B, 0x45, 0x00];
  static const _alignCenter = [0x1B, 0x61, 0x01];
  static const _alignLeft = [0x1B, 0x61, 0x00];
  static const _alignRight = [0x1B, 0x61, 0x02];
  static const _underlineOn = [0x1B, 0x2D, 0x01];
  static const _underlineOff = [0x1B, 0x2D, 0x00];
  static const _feedLines = [0x1B, 0x64, 0x03]; // Feed 3 lines
  static const _cutPaper = [0x1D, 0x56, 0x42, 0x00]; // Partial cut

  static Uint8List generateReceipt(ReceiptData receipt) {
    final List<int> bytes = [];
    final lineLength = 32; // 58mm printer = 32 chars, 80mm = 48 chars

    // Init
    bytes.addAll(_init);

    // === HEADER ===
    bytes.addAll(_alignCenter);
    bytes.addAll(_boldOn);
    bytes.addAll(_textToBytes(receipt.storeName, lineLength));
    bytes.addAll(_boldOff);

    if (receipt.storeAddress != null && receipt.storeAddress!.isNotEmpty) {
      bytes.addAll(_textToBytes(receipt.storeAddress!, lineLength));
    }
    if (receipt.storePhone != null && receipt.storePhone!.isNotEmpty) {
      bytes.addAll(_textToBytes(receipt.storePhone!, lineLength));
    }

    bytes.addAll(_underlineOn);
    bytes.addAll([0x0A]);
    bytes.addAll(_underlineOff);

    // === INFO TRANSAKSI ===
    bytes.addAll(_alignLeft);
    bytes.addAll(_boldOn);
    bytes.addAll(_textToBytes('No: ${receipt.transactionNumber}', lineLength));
    bytes.addAll(_boldOff);
    bytes.addAll(_textToBytes('Tanggal: ${receipt.dateTime}', lineLength));
    bytes.addAll(_textToBytes('Kasir: ${receipt.paymentMethod}', lineLength));
    bytes.addAll([0x0A]); // Spasi

    // === DAFTAR ITEM ===
    bytes.addAll(_underlineOn);
    bytes.addAll(_lineSeparator(lineLength));
    bytes.addAll(_underlineOff);

    for (final item in receipt.items) {
      // Baris 1: Nama item x Qty
      final nameLine = '${item.name}  x${item.quantity}';
      bytes.addAll(_textToBytes(nameLine, lineLength));

      // Baris 2: Harga satuan | Subtotal (rata kanan)
      final priceLine = _formatLineRight(
        '${_formatCurrency(item.unitPrice)}',
        '${_formatCurrency(item.subtotal)}',
        lineLength,
      );
      bytes.addAll(_textToBytes(priceLine, lineLength));
    }

    bytes.addAll(_underlineOn);
    bytes.addAll(_lineSeparator(lineLength));
    bytes.addAll(_underlineOff);

    // === TOTAL ===
    bytes.addAll(_textToBytes(_formatLineRight(
      'Subtotal:', _formatCurrency(receipt.subtotal), lineLength,
    ), lineLength));

    if (receipt.discount > 0) {
      final discountText = receipt.discountNote != null
          ? 'Diskon (${receipt.discountNote}):'
          : 'Diskon:';
      bytes.addAll(_textToBytes(_formatLineRight(
        discountText, '-${_formatCurrency(receipt.discount)}', lineLength,
      ), lineLength));
    }

    bytes.addAll(_textToBytes(_formatLineRight(
      'PPN (11%):', _formatCurrency(receipt.tax), lineLength,
    ), lineLength));

    bytes.addAll(_boldOn);
    bytes.addAll(_underlineOn);
    bytes.addAll(_textToBytes(_formatLineRight(
      'TOTAL:', _formatCurrency(receipt.grandTotal), lineLength,
    ), lineLength));
    bytes.addAll(_underlineOff);
    bytes.addAll(_boldOff);

    bytes.addAll([0x0A]);

    // === PEMBAYARAN ===
    bytes.addAll(_textToBytes('Pembayaran: ${receipt.paymentMethod}', lineLength));
    bytes.addAll(_textToBytes(_formatLineRight(
      'Bayar:', _formatCurrency(receipt.amountPaid), lineLength,
    ), lineLength));
    
    if (receipt.change > 0) {
      bytes.addAll(_boldOn);
      bytes.addAll(_textToBytes(_formatLineRight(
        'Kembali:', _formatCurrency(receipt.change), lineLength,
      ), lineLength));
      bytes.addAll(_boldOff);
    }

    bytes.addAll([0x0A]);

    // === FOOTER ===
    bytes.addAll(_alignCenter);
    if (receipt.footer != null && receipt.footer!.isNotEmpty) {
      bytes.addAll(_textToBytes(receipt.footer!, lineLength));
    }
    bytes.addAll(_textToBytes('Terima kasih atas kunjungan Anda', lineLength));
    bytes.addAll(_textToBytes('Barang yang sudah dibeli', lineLength));
    bytes.addAll(_textToBytes('tidak dapat dikembalikan', lineLength));

    // Feed dan cut
    bytes.addAll(_feedLines);
    bytes.addAll(_cutPaper);

    return Uint8List.fromList(bytes);
  }

  // Convert string ke bytes dengan encoding
  static List<int> _textToBytes(String text, int maxChars) {
    // Potong jika lebih dari maxChars
    if (text.length > maxChars) {
      text = text.substring(0, maxChars);
    }
    return utf8.encode('$text\n');
  }

  // Format baris dengan label kiri dan nilai kanan
  static String _formatLineRight(String left, String right, int lineLength) {
    final dotsNeeded = lineLength - left.length - right.length;
    if (dotsNeeded <= 0) return '$left $right';
    
    return '$left ${'.' * dotsNeeded} $right';
  }

  static String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }

  static List<int> _lineSeparator(int length) {
    return utf8.encode('${'-' * length}\n');
  }
}
```

---

## 4. Laporan & Ekspor Data

### 4.1 Report Service

```dart
// lib/providers/report_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';

class ReportService {
  final AppDatabase _db;

  ReportService(this._db);

  // ========================
  // LAPORAN OMZET HARIAN
  // ========================
  Future<DailyReport> getDailyReport(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final transactions = await (_db.select(_db.transactions)
      ..where((t) => 
        t.createdAt.isBetweenValues(startOfDay, endOfDay) &
        t.status.equals('completed'))
      ).get();

    final totalRevenue = transactions.fold<double>(0, (sum, t) => sum + t.totalAmount);
    final totalDiscount = transactions.fold<double>(0, (sum, t) => sum + t.discountAmount);
    final totalTax = transactions.fold<double>(0, (sum, t) => sum + t.taxAmount);
    final transactionCount = transactions.length;

    // Hitung profit bersih
    final transactionIds = transactions.map((t) => t.id).toList();
    final items = await (_db.select(_db.transactionItems)
      ..where((ti) => ti.transactionId.isIn(transactionIds))
      ).get();

    final totalCost = items.fold<double>(0, (sum, item) => 
      sum + (item.costPrice * item.quantity));
    final totalRevenueFromItems = items.fold<double>(0, (sum, item) => 
      sum + item.subtotal);
    final netProfit = totalRevenueFromItems - totalCost - totalDiscount;

    return DailyReport(
      date: date,
      totalRevenue: totalRevenue,
      totalDiscount: totalDiscount,
      totalTax: totalTax,
      netProfit: netProfit,
      transactionCount: transactionCount,
      averageTransactionValue: transactionCount > 0 
        ? totalRevenue / transactionCount 
        : 0,
    );
  }

  // ========================
  // PRODUK TERLARIS
  // ========================
  Future<List<TopProduct>> getTopProducts({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 10,
  }) async {
    final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final end = endDate ?? DateTime.now();

    return await _db.customSelect(
      'SELECT '
      '  p.id, '
      '  p.name, '
      '  p.barcode, '
      '  SUM(ti.quantity) as total_sold, '
      '  SUM(ti.subtotal) as total_revenue, '
      '  SUM((ti.unit_price - ti.cost_price) * ti.quantity) as total_profit '
      'FROM transaction_items ti '
      'JOIN products p ON ti.product_id = p.id '
      'JOIN transactions t ON ti.transaction_id = t.id '
      'WHERE t.created_at BETWEEN :start AND :end '
      'AND t.status = :status '
      'GROUP BY p.id '
      'ORDER BY total_sold DESC '
      'LIMIT :limit',
      variables: [
        Variable.withDateTime(start),
        Variable.withDateTime(end),
        Variable.withString('completed'),
        Variable.withInt(limit),
      ],
      readsFrom: {_db.transactionItems, _db.products, _db.transactions},
    ).get().then((rows) => rows.map((row) => TopProduct(
      productId: row.data['id'] as int,
      name: row.data['name'] as String,
      barcode: row.data['barcode'] as String?,
      totalSold: row.data['total_sold'] as int,
      totalRevenue: (row.data['total_revenue'] as int).toDouble(),
      totalProfit: (row.data['total_profit'] as int).toDouble(),
    )).toList());
  }

  // ========================
  // RINGKASAN PER KATEGORI
  // ========================
  Future<List<CategorySales>> getCategorySales({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final end = endDate ?? DateTime.now();

    return await _db.customSelect(
      'SELECT '
      '  c.name as category_name, '
      '  SUM(ti.quantity) as total_sold, '
      '  SUM(ti.subtotal) as total_revenue '
      'FROM transaction_items ti '
      'JOIN products p ON ti.product_id = p.id '
      'JOIN categories c ON p.category_id = c.id '
      'JOIN transactions t ON ti.transaction_id = t.id '
      'WHERE t.created_at BETWEEN :start AND :end '
      'AND t.status = :status '
      'GROUP BY c.id '
      'ORDER BY total_revenue DESC',
      variables: [
        Variable.withDateTime(start),
        Variable.withDateTime(end),
        Variable.withString('completed'),
      ],
      readsFrom: {_db.transactionItems, _db.products, _db.categories, _db.transactions},
    ).get().then((rows) => rows.map((row) => CategorySales(
      categoryName: row.data['category_name'] as String,
      totalSold: row.data['total_sold'] as int,
      totalRevenue: (row.data['total_revenue'] as int).toDouble(),
    )).toList());
  }
}

// Report Models
class DailyReport {
  final DateTime date;
  final double totalRevenue;
  final double totalDiscount;
  final double totalTax;
  final double netProfit;
  final int transactionCount;
  final double averageTransactionValue;

  const DailyReport({
    required this.date,
    required this.totalRevenue,
    required this.totalDiscount,
    required this.totalTax,
    required this.netProfit,
    required this.transactionCount,
    required this.averageTransactionValue,
  });
}

class TopProduct {
  final int productId;
  final String name;
  final String? barcode;
  final int totalSold;
  final double totalRevenue;
  final double totalProfit;

  const TopProduct({
    required this.productId,
    required this.name,
    this.barcode,
    required this.totalSold,
    required this.totalRevenue,
    required this.totalProfit,
  });
}

class CategorySales {
  final String categoryName;
  final int totalSold;
  final double totalRevenue;

  const CategorySales({
    required this.categoryName,
    required this.totalSold,
    required this.totalRevenue,
  });
}
```

### 4.2 Export ke PDF

```dart
// lib/services/export/pdf_export_service.dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../providers/report_provider.dart';

class PdfExportService {
  /// Generate Laporan Penjualan PDF
  static Future<File> generateSalesReport({
    required DailyReport report,
    required List<TopProduct> topProducts,
    required String storeName,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // === HEADER ===
          pw.Center(
            child: pw.Text(
              storeName,
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              'LAPORAN PENJUALAN HARIAN',
              style: const pw.TextStyle(fontSize: 16),
            ),
          ),
          pw.Center(
            child: pw.Text(
              _formatDate(report.date),
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
            ),
          ),
          pw.SizedBox(height: 20),

          // === RINGKASAN ===
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('RINGKASAN',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                pw.SizedBox(height: 12),
                _summaryRow('Total Transaksi', '${report.transactionCount} transaksi'),
                _summaryRow('Total Omzet', 'Rp ${_formatCurrency(report.totalRevenue)}'),
                _summaryRow('Total Diskon', 'Rp ${_formatCurrency(report.totalDiscount)}'),
                _summaryRow('Total PPN', 'Rp ${_formatCurrency(report.totalTax)}'),
                pw.Divider(color: PdfColors.blue200),
                _summaryRow('Rata-rata/Transaksi', 'Rp ${_formatCurrency(report.averageTransactionValue)}'),
                _summaryRow('Profit Bersih', 'Rp ${_formatCurrency(report.netProfit)}',
                  isBold: true),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // === TOP PRODUK ===
          pw.Text('10 PRODUK TERLARIS',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
          pw.SizedBox(height: 12),
          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue100),
            cellHeight: 30,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
            },
            headers: ['Produk', 'Terjual', 'Omzet', 'Profit'],
            data: topProducts.map((p) => [
              p.name,
              '${p.totalSold}',
              'Rp ${_formatCurrency(p.totalRevenue)}',
              'Rp ${_formatCurrency(p.totalProfit)}',
            ]).toList(),
          ),

          // === FOOTER ===
          pw.SizedBox(height: 40),
          pw.Center(
            child: pw.Text(
              'Dicetak: ${_formatDateTime(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
            ),
          ),
        ],
      ),
    );

    // Simpan file
    final output = await getApplicationDocumentsDirectory();
    final file = File('${output.path}/laporan_penjualan_${_fileDate(report.date)}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _summaryRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(
            fontWeight: isBold ? pw.FontWeight.bold : null)),
          pw.Text(value, style: pw.TextStyle(
            fontWeight: isBold ? pw.FontWeight.bold : null)),
        ],
      ),
    );
  }

  static String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static String _formatDateTime(DateTime dt) {
    return '${_formatDate(dt)} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  static String _fileDate(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }
}
```

### 4.3 Export ke Excel

```dart
// lib/services/export/excel_export_service.dart
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../providers/report_provider.dart';

class ExcelExportService {
  /// Generate Laporan Penjualan Excel
  static Future<File> generateSalesReport({
    required DailyReport report,
    required List<TopProduct> topProducts,
    required List<CategorySales> categorySales,
    required String storeName,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Laporan Penjualan'];

    // Default styling
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#1565C0'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      fontSize: 12,
    );

    int row = 0;

    // === HEADER ===
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
      ..value = TextCellValue(storeName)
      ..cellStyle = CellStyle(bold: true, fontSize: 16);
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row),
    );
    row++;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
      ..value = TextCellValue('Laporan Penjualan Harian - ${_formatDate(report.date)}')
      ..cellStyle = CellStyle(fontSize: 11);
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row),
    );
    row += 2;

    // === RINGKASAN ===
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
      ..value = TextCellValue('RINGKASAN')
      ..cellStyle = CellStyle(bold: true, fontSize: 12);
    row++;

    final summaryData = [
      ['Total Transaksi', report.transactionCount.toString()],
      ['Total Omzet', 'Rp ${_formatCurrency(report.totalRevenue)}'],
      ['Total Diskon', 'Rp ${_formatCurrency(report.totalDiscount)}'],
      ['Total PPN', 'Rp ${_formatCurrency(report.totalTax)}'],
      ['Profit Bersih', 'Rp ${_formatCurrency(report.netProfit)}'],
      ['Rata-rata/Transaksi', 'Rp ${_formatCurrency(report.averageTransactionValue)}'],
    ];

    for (final data in summaryData) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        ..value = TextCellValue(data[0]);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
        ..value = TextCellValue(data[1]);
      row++;
    }
    row++;

    // === TOP PRODUK TERLARIS ===
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
      ..value = TextCellValue('10 PRODUK TERLARIS')
      ..cellStyle = CellStyle(bold: true, fontSize: 12);
    row++;

    // Table header
    final productHeaders = ['No', 'Nama Produk', 'Barcode', 'Terjual', 'Omzet', 'Profit'];
    for (int i = 0; i < productHeaders.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
        ..value = TextCellValue(productHeaders[i])
        ..cellStyle = headerStyle;
    }
    row++;

    // Table data
    for (int i = 0; i < topProducts.length; i++) {
      final p = topProducts[i];
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        ..value = IntCellValue(i + 1);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
        ..value = TextCellValue(p.name);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
        ..value = TextCellValue(p.barcode ?? '-');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
        ..value = IntCellValue(p.totalSold);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
        ..value = DoubleCellValue(p.totalRevenue);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
        ..value = DoubleCellValue(p.totalProfit);
      row++;
    }
    row++;

    // === SALES PER KATEGORI ===
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
      ..value = TextCellValue('PENJUALAN PER KATEGORI')
      ..cellStyle = CellStyle(bold: true, fontSize: 12);
    row++;

    final catHeaders = ['Kategori', 'Total Terjual', 'Total Omzet'];
    for (int i = 0; i < catHeaders.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
        ..value = TextCellValue(catHeaders[i])
        ..cellStyle = headerStyle;
    }
    row++;

    for (final cat in categorySales) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        ..value = TextCellValue(cat.categoryName);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
        ..value = IntCellValue(cat.totalSold);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
        ..value = DoubleCellValue(cat.totalRevenue);
      row++;
    }

    // Auto-fit columns
    sheet.setColWidth(0, 20);
    sheet.setColWidth(1, 30);
    sheet.setColWidth(2, 18);
    sheet.setColWidth(3, 12);
    sheet.setColWidth(4, 18);
    sheet.setColWidth(5, 18);

    // Simpan file
    final output = await getApplicationDocumentsDirectory();
    final file = File('${output.path}/laporan_penjualan_${_fileDate(report.date)}.xlsx');
    final fileBytes = excel.save();
    if (fileBytes != null) {
      await file.writeAsBytes(fileBytes);
    }
    return file;
  }

  static String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static String _fileDate(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }
}
```

---

## 5. Contoh Potongan Kode Krusial

### 5.1 Database Initialization

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/database/app_database.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi database
  final database = AppDatabase();
  
  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
      ],
      child: const PosApp(),
    ),
  );
}

// Database provider
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});
```

### 5.2 Transaction Repository (Checkout Flow)

```dart
// lib/data/repositories/transaction_repository.dart
import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../database/daos/stock_dao.dart';

class TransactionRepository {
  final AppDatabase _db;
  final StockDao _stockDao;

  TransactionRepository(this._db, this._stockDao);

  /// Proses checkout: buat transaksi + kurangi stok (atomic)
  Future<TransactionResult> processCheckout({
    required List<CartItem> items,
    required int paymentMethodId,
    required double amountPaid,
    required double taxRate,
    double discountType = 0,
    double discountValue = 0,
    String? notes,
  }) async {
    return await _db.transaction(() async {
      // 1. Generate nomor transaksi unik
      final transactionNumber = _generateTransactionNumber();

      // 2. Hitung totals
      final subtotal = items.fold<double>(0, (sum, item) => sum + item.subtotal);
      
      double discountAmount = 0;
      if (discountType == 1) { // Percentage
        discountAmount = subtotal * (discountValue / 100);
      } else if (discountType == 2) { // Fixed
        discountAmount = discountValue;
      }
      
      final discountedSubtotal = subtotal - discountAmount;
      final taxAmount = discountedSubtotal * taxRate;
      final totalAmount = discountedSubtotal + taxAmount;

      // 3. Insert transaksi
      final transactionId = await _db.into(_db.transactions).insert(
        TransactionsCompanion(
          transactionNumber: Value(transactionNumber),
          subtotal: Value(subtotal.round()),
          taxAmount: Value(taxAmount.round()),
          discountAmount: Value(discountAmount.round()),
          totalAmount: Value(totalAmount.round()),
          paymentMethodId: Value(paymentMethodId),
          amountPaid: Value(amountPaid.round()),
          changeAmount: Value((amountPaid - totalAmount).round()),
          status: const Value('completed'),
          notes: Value(notes),
        ),
      );

      // 4. Insert items + kurangi stok atomic
      for (final item in items) {
        // Insert transaction item
        await _db.into(_db.transactionItems).insert(
          TransactionItemsCompanion(
            transactionId: Value(transactionId),
            productId: Value(item.productId),
            quantity: Value(item.quantity),
            unitPrice: Value(item.unitPrice.round()),
            costPrice: Value(item.costPrice.round()),
            discountType: Value(_discountTypeToString(item.discountType)),
            discountValue: Value(item.discountValue.round()),
            subtotal: Value(item.finalSubtotal.round()),
          ),
        );

        // Kurangi stok secara atomic
        await _stockDao.deductStockAtomic(
          productId: item.productId,
          quantity: item.quantity,
          transactionId: transactionId,
        );
      }

      return TransactionResult(
        transactionId: transactionId,
        transactionNumber: transactionNumber,
        totalAmount: totalAmount,
        changeAmount: amountPaid - totalAmount,
      );
    });
  }

  String _generateTransactionNumber() {
    final now = DateTime.now();
    final date = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final time = '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    final random = (DateTime.now().microsecondsSinceEpoch % 10000).toString().padLeft(4, '0');
    return 'TX$date$time$random';
  }

  String _discountTypeToString(int type) {
    switch (type) {
      case 1: return 'percentage';
      case 2: return 'fixed';
      default: return 'none';
    }
  }
}

class TransactionResult {
  final int transactionId;
  final String transactionNumber;
  final double totalAmount;
  final double changeAmount;

  const TransactionResult({
    required this.transactionId,
    required this.transactionNumber,
    required this.totalAmount,
    required this.changeAmount,
  });
}
```

### 5.3 Payment Sheet (UI)

```dart
// lib/presentation/widgets/payment_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaymentSheet extends ConsumerStatefulWidget {
  final double grandTotal;
  final Function(double amountPaid) onConfirm;

  const PaymentSheet({
    super.key,
    required this.grandTotal,
    required this.onConfirm,
  });

  @override
  ConsumerState<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<PaymentSheet> {
  final TextEditingController _amountController = TextEditingController();
  double _change = 0;
  
  // Uang kembalian cepat (quick change)
  final List<double> _quickAmounts = [50000, 100000, 200000, 500000];

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_calculateChange);
  }

  void _calculateChange() {
    final amount = double.tryParse(_amountController.text.replaceAll('.', '')) ?? 0;
    setState(() {
      _change = amount - widget.grandTotal;
    });
  }

  void _selectQuickAmount(double amount) {
    _amountController.text = amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Total yang harus dibayar
          Text(
            'Total Pembayaran',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            'Rp ${_formatCurrency(widget.grandTotal)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 20),

          // Input nominal bayar
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 24),
            decoration: InputDecoration(
              labelText: 'Bayar',
              prefixText: 'Rp ',
              prefixStyle: TextStyle(fontSize: 20, color: Colors.grey.shade600),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Quick amount buttons
          Wrap(
            spacing: 8,
            children: _quickAmounts.where((a) => a >= widget.grandTotal).map((amount) {
              return ActionChip(
                label: Text('Rp ${_formatCurrency(amount)}'),
                onPressed: () => _selectQuickAmount(amount.toDouble()),
                backgroundColor: Colors.blue.shade50,
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Kembali
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _change >= 0 ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kembali:',
                  style: TextStyle(
                    fontSize: 16,
                    color: _change >= 0 ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                ),
                Text(
                  _change >= 0
                      ? 'Rp ${_formatCurrency(_change)}'
                      : 'Rp ${_formatCurrency(_change.abs())} (Kurang)',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _change >= 0 ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tombol Konfirmasi
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _change >= 0
                  ? () {
                      final amount = double.tryParse(
                        _amountController.text.replaceAll('.', ''),
                      ) ?? 0;
                      widget.onConfirm(amount);
                      Navigator.pop(context);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Konfirmasi Pembayaran',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}
```

---

## 6. Strategi Sync & Cloud-Ready Architecture

### 6.1 Schema untuk Future Sync

```dart
// Tabel sync_queue untuk offline-first → cloud sync
class SyncQueues extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()(); // 'product', 'transaction', 'stock_log'
  IntColumn get entityId => integer()();
  TextColumn get action => text()(); // 'create', 'update', 'delete'
  TextColumn get payload => text()(); // JSON payload
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().nullable()();
}
```

### 6.2 Sync Strategy

```
┌──────────────────────────────────────────────────────────────┐
│                    OFFLINE → ONLINE SYNC                      │
│                                                              │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐              │
│  │  Local    │───▶│  Sync    │───▶│  Cloud   │              │
│  │  Change   │    │  Queue   │    │  Server  │              │
│  │  (SQLite) │    │  (FIFO)  │    │  (REST)  │              │
│  └──────────┘    └──────────┘    └──────────┘              │
│                       │                                      │
│                       ▼                                      │
│              ┌──────────────┐                               │
│              │   Conflict   │                               │
│              │   Resolver   │                               │
│              │              │                               │
│              │  Rules:      │                               │
│              │  - Last Write│                               │
│              │    Wins      │                               │
│              │  - Manual    │                               │
│              │    Merge     │                               │
│              └──────────────┘                               │
│                                                              │
│  SYNC TRIGGERS:                                              │
│  1. App open → check connectivity → sync if online           │
│  2. Every 5 minutes (if online)                              │
│  3. On manual "Sync" button press                            │
│  4. After each transaction (if online)                       │
│                                                              │
│  STRATEGY:                                                   │
│  - Delta sync: only send changed records (updated_at)        │
│  - Batch upload: max 50 records per request                  │
│  - Retry: exponential backoff (1s, 2s, 4s, 8s, max 5x)      │
│  - Last sync timestamp stored locally                        │
└──────────────────────────────────────────────────────────────┘
```

---

## 7. Komponen Pustaka Pendukung

### 7.1 Currency Formatter

```dart
// lib/core/utils/currency_formatter.dart
class CurrencyFormatter {
  static String format(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }

  static String formatShort(double amount) {
    if (amount >= 1000000000) {
      return 'Rp ${(amount / 1000000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)}jt';
    } else if (amount >= 1000) {
      return 'Rp ${(amount / 1000).toStringAsFixed(1)}rb';
    }
    return format(amount);
  }
}
```

### 7.2 Transaction Number Generator

```dart
// lib/core/utils/transaction_helper.dart
class TransactionHelper {
  /// Generate nomor transaksi unik
  /// Format: TX-YYYYMMDD-HHmmss-XXXX
  static String generateNumber() {
    final now = DateTime.now();
    final date = '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
    final time = '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
    final random = (now.microsecondsSinceEpoch % 10000)
        .toString()
        .padLeft(4, '0');
    return 'TX-$date-$time-$random';
  }
}
```

---

## 8. Checklist Implementasi

| No | Modul | Status | Prioritas |
|----|-------|--------|-----------|
| 1 | Setup project Flutter + dependencies | ☐ | P0 |
| 2 | Database schema (Drift tables + migrations) | ☐ | P0 |
| 3 | DAO layer (CRUD + Atomic stock) | ☐ | P0 |
| 4 | Product management (CRUD) | ☐ | P0 |
| 5 | Cart/Cart provider | ☐ | P0 |
| 6 | Checkout flow + payment sheet | ☐ | P0 |
| 7 | Barcode scanner integration | ☐ | P0 |
| 8 | Thermal printer integration | ☐ | P1 |
| 9 | Dashboard screen | ☐ | P1 |
| 10 | Laporan/Report service | ☐ | P1 |
| 11 | PDF export | ☐ | P1 |
| 12 | Excel export | ☐ | P1 |
| 13 | Stock adjustment feature | ☐ | P1 |
| 14 | Category management | ☐ | P2 |
| 15 | Payment method management | ☐ | P2 |
| 16 | Settings screen | ☐ | P2 |
| 17 | Sync engine (cloud) | ☐ | P3 |

---

*Document generated for POS Mobile App - UMKM Kasir*
*Stack: Flutter + Drift + Riverpod + Thermal Printer + ESC/POS*
