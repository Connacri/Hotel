class RecordOpenModel {
  final int? id;
  final int orderFlag;
  final String? recData;
  final String? openTime;

  const RecordOpenModel({
    this.id,
    required this.orderFlag,
    this.recData,
    this.openTime,
  });

  bool get isEmpty => recData == 'FFFFFFFFFFFFFFFF' || recData == null;
  bool get isSystemConfig => orderFlag > 0 && !isEmpty;
  bool get isDoorOpen => orderFlag == 0 && !isEmpty;

  String get typeLabel {
    if (isEmpty) return 'Vide';
    if (isSystemConfig) return 'Config serrure';
    return 'Ouverture porte';
  }

  RecordOpenModel copyWith({
    int? id,
    int? orderFlag,
    String? recData,
    String? openTime,
  }) {
    return RecordOpenModel(
      id: id ?? this.id,
      orderFlag: orderFlag ?? this.orderFlag,
      recData: recData ?? this.recData,
      openTime: openTime ?? this.openTime,
    );
  }

  factory RecordOpenModel.fromRow(Map<String, Object?> row) => RecordOpenModel(
        id: row['id'] as int?,
        orderFlag: (row['order_flag'] as int?) ?? 0,
        recData: row['rec_data'] as String?,
        openTime: row['open_time'] as String?,
      );
}
