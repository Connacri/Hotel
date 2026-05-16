import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';

extension AppContext on BuildContext {
  // Theme shortcut
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;

  // Provider shortcuts
  RoomProvider get rooms => read<RoomProvider>();
  GuestProvider get guests => read<GuestProvider>();
  CardProvider get cards => read<CardProvider>();
  OperatorProvider get operators => read<OperatorProvider>();
  RecordProvider get records => read<RecordProvider>();

  // Watch shortcuts (for UI)
  RoomProvider get watchRooms => watch<RoomProvider>();
  GuestProvider get watchGuests => watch<GuestProvider>();
  CardProvider get watchCards => watch<CardProvider>();
  OperatorProvider get watchOperators => watch<OperatorProvider>();
  RecordProvider get watchRecords => watch<RecordProvider>();
}
