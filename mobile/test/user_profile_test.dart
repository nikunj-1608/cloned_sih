import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orca/core/models/user_profile.dart';
import 'package:orca/core/models/user_role.dart';

void main() {
  group('UserRole enum & RBAC metadata mapping', () {
    test('resolves metadata key correctly for all 5 roles', () {
      expect(UserRole.fromMetadata('fishermen'), UserRole.fishermen);
      expect(UserRole.fromMetadata('researchers'), UserRole.researchers);
      expect(UserRole.fromMetadata('coastal_authorities'), UserRole.coastalAuthorities);
      expect(UserRole.fromMetadata('disaster_management_agencies'), UserRole.disasterManagement);
      expect(UserRole.fromMetadata('maritime_operators'), UserRole.maritimeOperators);
    });

    test('defaults to fishermen when role is unknown or null', () {
      expect(UserRole.fromMetadata(null), UserRole.fishermen);
      expect(UserRole.fromMetadata('unknown_role'), UserRole.fishermen);
    });

    test('has valid bilingual labels and icons for each role', () {
      for (final role in UserRole.values) {
        expect(role.title.en, isNotEmpty);
        expect(role.title.ta, isNotEmpty);
        expect(role.description.en, isNotEmpty);
        expect(role.description.ta, isNotEmpty);
        expect(role.icon, isA<IconData>());
      }
    });
  });

  group('UserProfile model', () {
    test('serializes and deserializes round-trip', () {
      final profile = UserProfile(
        id: 'user_123',
        email: 'fisherman@orca.sea',
        role: UserRole.fishermen,
        fullName: 'Murugan K.',
        assignedPort: 'Rameswaram Jetty',
        vesselRegistration: 'IND-TN-10-MM-4521',
        isOffline: true,
        createdAt: DateTime.parse('2026-09-12T10:00:00.000Z'),
      );

      final json = profile.toJson();
      final reconstructed = UserProfile.fromJson(json);

      expect(reconstructed, equals(profile));
      expect(reconstructed.id, 'user_123');
      expect(reconstructed.email, 'fisherman@orca.sea');
      expect(reconstructed.role, UserRole.fishermen);
      expect(reconstructed.fullName, 'Murugan K.');
      expect(reconstructed.assignedPort, 'Rameswaram Jetty');
      expect(reconstructed.vesselRegistration, 'IND-TN-10-MM-4521');
      expect(reconstructed.isOffline, isTrue);
    });

    test('displayName prefers fullName or falls back to email prefix', () {
      const withName = UserProfile(
        id: '1',
        email: 'rajan@gov.in',
        role: UserRole.coastalAuthorities,
        fullName: 'Insp. Rajan',
      );
      expect(withName.displayName, 'Insp. Rajan');

      const withoutName = UserProfile(
        id: '2',
        email: 'captain@maritime.org',
        role: UserRole.maritimeOperators,
      );
      expect(withoutName.displayName, 'captain');
    });

    test('copyWith updates specified fields correctly', () {
      const original = UserProfile(
        id: '1',
        email: 'test@orca.sea',
        role: UserRole.fishermen,
      );

      final updated = original.copyWith(
        fullName: 'New Name',
        role: UserRole.researchers,
      );

      expect(updated.fullName, 'New Name');
      expect(updated.role, UserRole.researchers);
      expect(updated.email, original.email);
      expect(updated.id, original.id);
    });
  });
}
