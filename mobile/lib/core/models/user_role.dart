import 'package:flutter/material.dart';
import 'bilingual.dart';

/// Role-Based Access Control (RBAC) personas defined in the ORCA specification.
///
/// Each role corresponds to a specific Supabase user_metadata role and provides
/// tailored interfaces, permissions, and offline capabilities.
enum UserRole {
  fishermen(
    metadataKey: 'fishermen',
    title: Bilingual('Fisherman', 'மீனவர்'),
    description: Bilingual(
      'Offline boundary tracking, PFZ advisory, and emergency siren.',
      'ஆஃப்லைன் எல்லை கண்காணிப்பு, மீன்பிடி மண்டலம் மற்றும் அவசர எச்சரிக்கை.',
    ),
    icon: Icons.sailing_rounded,
  ),
  researchers(
    metadataKey: 'researchers',
    title: Bilingual('Marine Researcher', 'கடல் ஆராய்ச்சியாளர்'),
    description: Bilingual(
      'Oceanographic data, sea temperature, and chlorophyll queries.',
      'கடல்சார் தரவு, கடல் வெப்பநிலை மற்றும் குளோரோபில் பகுப்பாய்வு.',
    ),
    icon: Icons.science_rounded,
  ),
  coastalAuthorities(
    metadataKey: 'coastal_authorities',
    title: Bilingual('Coastal Authority', 'கடலோர காவல் அதிகாரி'),
    description: Bilingual(
      'Maritime border surveillance, distress alerts, and fleet monitoring.',
      'கடல் எல்லை கண்காணிப்பு, அவசர எச்சரிக்கை மற்றும் படகு கண்காணிப்பு.',
    ),
    icon: Icons.shield_rounded,
  ),
  disasterManagement(
    metadataKey: 'disaster_management_agencies',
    title: Bilingual('Disaster Management', 'பேரிடர் மேலாண்மை'),
    description: Bilingual(
      'Cyclone alerts, storm surge warnings, and coastal evacuation zones.',
      'புயல் எச்சரிக்கை, கடல் அலை ஆபத்து மற்றும் பாதுகாப்பு மண்டலங்கள்.',
    ),
    icon: Icons.warning_amber_rounded,
  ),
  maritimeOperators(
    metadataKey: 'maritime_operators',
    title: Bilingual('Maritime Operator', 'கடல்சார் ஆபரேட்டர்'),
    description: Bilingual(
      'Commercial shipping routes, port schedules, and channel navigation.',
      'வணிகக் கப்பல் பாதைகள், துறைமுக அட்டவணை மற்றும் வழிசெலுத்தல்.',
    ),
    icon: Icons.directions_boat_rounded,
  );

  const UserRole({
    required this.metadataKey,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String metadataKey;
  final Bilingual title;
  final Bilingual description;
  final IconData icon;

  /// Resolves a [UserRole] from a Supabase metadata string or stored string.
  /// Defaults to [UserRole.fishermen] as the primary mobile user context.
  static UserRole fromMetadata(String? key) {
    if (key == null) return UserRole.fishermen;
    for (final role in UserRole.values) {
      if (role.metadataKey == key || role.name == key) {
        return role;
      }
    }
    return UserRole.fishermen;
  }
}
