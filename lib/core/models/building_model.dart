class BuildingModel {
  final int bldNo;
  final String bldName;

  const BuildingModel({required this.bldNo, required this.bldName});

  BuildingModel copyWith({
    int? bldNo,
    String? bldName,
  }) {
    return BuildingModel(
      bldNo: bldNo ?? this.bldNo,
      bldName: bldName ?? this.bldName,
    );
  }

  factory BuildingModel.fromRow(Map<String, Object?> row) => BuildingModel(
        bldNo: (row['bld_no'] as int?) ?? 1,
        bldName: (row['bld_name'] as String?) ?? '',
      );
}
