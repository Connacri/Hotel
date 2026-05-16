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

  OperatorModel copyWith({
    String? gongHao,
    String? name,
    String? miMa,
    String? quanXian,
    String? beiZhu,
  }) {
    return OperatorModel(
      gongHao: gongHao ?? this.gongHao,
      name: name ?? this.name,
      miMa: miMa ?? this.miMa,
      quanXian: quanXian ?? this.quanXian,
      beiZhu: beiZhu ?? this.beiZhu,
    );
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
