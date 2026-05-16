class RoomModel {
  final int? id;
  final int bldNo;
  final int flrNo;
  final int romId;
  final int romId2;
  final String roomNo;
  final String? sType;
  final String status;
  final double price;
  final int dai;
  final int cardCount;
  final int maxCards;
  final int publicDoor;
  final String? beiZhu;
  final String? firstCkOut;
  final double hourRateStartup;
  final double hourRatePrice;
  final String? reservCkIn;

  const RoomModel({
    this.id,
    required this.bldNo,
    required this.flrNo,
    required this.romId,
    this.romId2 = 99,
    required this.roomNo,
    this.sType,
    this.status = 'Vacant',
    this.price = 0,
    this.dai = 0,
    this.cardCount = 0,
    this.maxCards = 10,
    this.publicDoor = 0,
    this.beiZhu,
    this.firstCkOut,
    this.hourRateStartup = 0,
    this.hourRatePrice = 0,
    this.reservCkIn,
  });

  bool get isOccupied => status == 'Guest';
  bool get isVacant => status == 'Vacant';
  String get displayName => 'Chambre $roomNo';
  String get floorLabel => 'Étage $flrNo';

  factory RoomModel.fromRow(Map<String, Object?> row) => RoomModel(
        id: row['id'] as int?,
        bldNo: (row['bld_no'] as int?) ?? 1,
        flrNo: (row['flr_no'] as int?) ?? 1,
        romId: (row['rom_id'] as int?) ?? 0,
        romId2: (row['rom_id2'] as int?) ?? 99,
        roomNo: (row['room_no'] as String?) ?? '',
        sType: row['s_type'] as String?,
        status: (row['status'] as String?) ?? 'Vacant',
        price: (row['price'] as num?)?.toDouble() ?? 0,
        dai: (row['dai'] as int?) ?? 0,
        cardCount: (row['card_count'] as int?) ?? 0,
        maxCards: (row['max_cards'] as int?) ?? 10,
        publicDoor: (row['public_door'] as int?) ?? 0,
        beiZhu: row['bei_zhu'] as String?,
        firstCkOut: row['first_ck_out'] as String?,
        hourRateStartup: (row['hour_rate_startup'] as num?)?.toDouble() ?? 0,
        hourRatePrice: (row['hour_rate_price'] as num?)?.toDouble() ?? 0,
        reservCkIn: row['reserv_ck_in'] as String?,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'bld_no': bldNo,
        'flr_no': flrNo,
        'rom_id': romId,
        'rom_id2': romId2,
        'room_no': roomNo,
        's_type': sType,
        'status': status,
        'price': price,
        'dai': dai,
        'card_count': cardCount,
        'max_cards': maxCards,
        'public_door': publicDoor,
        'bei_zhu': beiZhu,
        'first_ck_out': firstCkOut,
        'hour_rate_startup': hourRateStartup,
        'hour_rate_price': hourRatePrice,
        'reserv_ck_in': reservCkIn,
      };

  RoomModel copyWith({
    String? status,
    int? cardCount,
    double? price,
    String? firstCkOut,
  }) =>
      RoomModel(
        id: id,
        bldNo: bldNo,
        flrNo: flrNo,
        romId: romId,
        romId2: romId2,
        roomNo: roomNo,
        sType: sType,
        status: status ?? this.status,
        price: price ?? this.price,
        dai: dai,
        cardCount: cardCount ?? this.cardCount,
        maxCards: maxCards,
        publicDoor: publicDoor,
        beiZhu: beiZhu,
        firstCkOut: firstCkOut ?? this.firstCkOut,
        hourRateStartup: hourRateStartup,
        hourRatePrice: hourRatePrice,
        reservCkIn: reservCkIn,
      );
}
