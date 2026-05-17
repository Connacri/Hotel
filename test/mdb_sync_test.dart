import 'package:flutter_test/flutter_test.dart';
import 'package:hotel/core/models/room_model.dart';

void main() {
  test('SQL Generation for MDB Sync', () {
    const room = RoomModel(
      bldNo: 1,
      flrNo: 2,
      romId: 201,
      roomNo: '201',
      status: 'Vacant',
      price: 150.0,
      cardCount: 0,
      maxCards: 10,
    );

    final sql = "UPDATE RoomInfo SET status='${room.status}', price=${room.price} WHERE rom_id=${room.romId}";
    expect(sql, "UPDATE RoomInfo SET status='Vacant', price=150.0 WHERE rom_id=201");
  });
}
