class GuestModel {
  final int? id;
  final String bldRoomNo;
  final String name;
  final String? sex;
  final String? cType;
  final String? cNo;
  final String? comeTime;
  final String? goTime;
  final String? cardId;
  final String? flag;
  final String? beiZhu;
  final double price;
  final double yaJin;

  const GuestModel({
    this.id,
    required this.bldRoomNo,
    required this.name,
    this.sex,
    this.cType,
    this.cNo,
    this.comeTime,
    this.goTime,
    this.cardId,
    this.flag,
    this.beiZhu,
    this.price = 0,
    this.yaJin = 0,
  });

  bool get isWalkIn => flag == 'WalkIn';
  String get roomLabel => bldRoomNo.replaceFirst('1-', '');

  GuestModel copyWith({
    int? id,
    String? bldRoomNo,
    String? name,
    String? sex,
    String? cType,
    String? cNo,
    String? comeTime,
    String? goTime,
    String? cardId,
    String? flag,
    String? beiZhu,
    double? price,
    double? yaJin,
  }) {
    return GuestModel(
      id: id ?? this.id,
      bldRoomNo: bldRoomNo ?? this.bldRoomNo,
      name: name ?? this.name,
      sex: sex ?? this.sex,
      cType: cType ?? this.cType,
      cNo: cNo ?? this.cNo,
      comeTime: comeTime ?? this.comeTime,
      goTime: goTime ?? this.goTime,
      cardId: cardId ?? this.cardId,
      flag: flag ?? this.flag,
      beiZhu: beiZhu ?? this.beiZhu,
      price: price ?? this.price,
      yaJin: yaJin ?? this.yaJin,
    );
  }

  factory GuestModel.fromRow(Map<String, Object?> row) => GuestModel(
        id: row['id'] as int?,
        bldRoomNo: (row['bld_room_no'] as String?) ?? '',
        name: (row['name'] as String?) ?? '',
        sex: row['sex'] as String?,
        cType: row['c_type'] as String?,
        cNo: row['c_no'] as String?,
        comeTime: row['come_time'] as String?,
        goTime: row['go_time'] as String?,
        cardId: row['card_id'] as String?,
        flag: row['flag'] as String?,
        beiZhu: row['bei_zhu'] as String?,
        price: (row['price'] as num?)?.toDouble() ?? 0,
        yaJin: (row['ya_jin'] as num?)?.toDouble() ?? 0,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'bld_room_no': bldRoomNo,
        'name': name,
        'sex': sex,
        'c_type': cType,
        'c_no': cNo,
        'come_time': comeTime,
        'go_time': goTime,
        'card_id': cardId,
        'flag': flag,
        'bei_zhu': beiZhu,
        'price': price,
        'ya_jin': yaJin,
      };
}
