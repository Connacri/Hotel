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

class CardModel {
  final int? id;
  final String? cardData;
  final String? holder;
  final String? gongHao;
  final String? beiZhu;
  final String? status;

  const CardModel({
    this.id,
    this.cardData,
    this.holder,
    this.gongHao,
    this.beiZhu,
    this.status,
  });

  bool get isErased => status?.contains('Erased') ?? false;
  bool get isCheckIn => status?.contains('Check-In') ?? false;
  bool get isActive => !isErased && cardData != null;

  String get shortData =>
      (cardData != null && cardData!.length > 16)
          ? '${cardData!.substring(0, 16)}...'
          : (cardData ?? '');

  factory CardModel.fromRow(Map<String, Object?> row) => CardModel(
        id: row['id'] as int?,
        cardData: row['card_data'] as String?,
        holder: row['holder'] as String?,
        gongHao: row['gong_hao'] as String?,
        beiZhu: row['bei_zhu'] as String?,
        status: row['status'] as String?,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'card_data': cardData,
        'holder': holder,
        'gong_hao': gongHao,
        'bei_zhu': beiZhu,
        'status': status,
      };
}

class OperatorModel {
  final String gongHao;
  final String name;
  final String miMa;
  final String? quanXian;
  final String? beiZhu;

  const OperatorModel({
    required this.gongHao,
    required this.name,
    required this.miMa,
    this.quanXian,
    this.beiZhu,
  });

  /// Calcule le niveau de permission (0.0 à 1.0) depuis la chaîne QuanXian
  double get permissionLevel {
    if (quanXian == null || quanXian!.isEmpty) return 0;
    final digits = quanXian!.replaceAll(RegExp(r'[^01]'), '');
    if (digits.isEmpty) return 0;
    final ones = digits.split('').where((c) => c == '1').length;
    return ones / digits.length;
  }

  String get roleLabel {
    if (gongHao == 'Super' || gongHao == 'proQuanXian_S') return 'Super Admin';
    if (gongHao == 'Admin' || gongHao == 'proQuanXian_A') return 'Administrateur';
    if (gongHao == 'proQuanXian_M') return 'Manager';
    if (gongHao == 'proQuanXian_G') return 'Opérateur général';
    return 'Opérateur';
  }

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  factory OperatorModel.fromRow(Map<String, Object?> row) => OperatorModel(
        gongHao: (row['gong_hao'] as String?) ?? '',
        name: (row['name'] as String?) ?? '',
        miMa: (row['mi_ma'] as String?) ?? '',
        quanXian: row['quan_xian'] as String?,
        beiZhu: row['bei_zhu'] as String?,
      );

  Map<String, Object?> toMap() => {
        'gong_hao': gongHao,
        'name': name,
        'mi_ma': miMa,
        'quan_xian': quanXian,
        'bei_zhu': beiZhu,
      };
}

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

  factory RecordOpenModel.fromRow(Map<String, Object?> row) => RecordOpenModel(
        id: row['id'] as int?,
        orderFlag: (row['order_flag'] as int?) ?? 0,
        recData: row['rec_data'] as String?,
        openTime: row['open_time'] as String?,
      );
}

class BuildingModel {
  final int bldNo;
  final String bldName;

  const BuildingModel({required this.bldNo, required this.bldName});

  factory BuildingModel.fromRow(Map<String, Object?> row) => BuildingModel(
        bldNo: (row['bld_no'] as int?) ?? 1,
        bldName: (row['bld_name'] as String?) ?? '',
      );
}
