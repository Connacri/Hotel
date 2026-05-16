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

  CardModel copyWith({
    int? id,
    String? cardData,
    String? holder,
    String? gongHao,
    String? beiZhu,
    String? status,
  }) {
    return CardModel(
      id: id ?? this.id,
      cardData: cardData ?? this.cardData,
      holder: holder ?? this.holder,
      gongHao: gongHao ?? this.gongHao,
      beiZhu: beiZhu ?? this.beiZhu,
      status: status ?? this.status,
    );
  }

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
