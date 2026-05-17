import 'package:flutter_test/flutter_test.dart';
import 'package:hotel/core/models/room_model.dart';
import 'package:hotel/core/models/guest_model.dart';

void main() {
  group('RoomModel Sanitization', () {
    test('fromRow should trim and remove null characters from roomNo', () {
      final row = {
        'room_no': ' 101\u0000 ',
        'status': 'Vacant\u0000',
        's_type': ' Standard ',
        'bld_no': 1,
        'flr_no': 1,
        'rom_id': 101,
      };
      
      final room = RoomModel.fromRow(row);
      
      expect(room.roomNo, '101');
      expect(room.status, 'Vacant');
      expect(room.sType, 'Standard');
      expect(room.isVacant, isTrue);
    });

    test('isOccupied should be case-insensitive', () {
      final row = {
        'room_no': '102',
        'status': 'guest', // lowercase
        'bld_no': 1,
        'flr_no': 1,
        'rom_id': 102,
      };
      
      final room = RoomModel.fromRow(row);
      expect(room.isOccupied, isTrue);
    });
  });

  group('GuestModel Sanitization', () {
    test('fromRow should trim and remove null characters', () {
      final row = {
        'name': ' John Doe\u0000 ',
        'bld_room_no': ' 1-101 ',
      };
      
      final guest = GuestModel.fromRow(row);
      
      expect(guest.name, 'John Doe');
      expect(guest.bldRoomNo, '1-101');
      expect(guest.roomLabel, '101');
    });

    test('roomLabel should handle different formats', () {
      const g1 = GuestModel(name: 'Test', bldRoomNo: '1-101');
      const g2 = GuestModel(name: 'Test', bldRoomNo: 'B2-205');
      
      expect(g1.roomLabel, '101');
      expect(g2.roomLabel, '205');
    });
  });
}
