import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';

/// Contract and implementation for authentication and session persistence.
///
/// Supports Supabase Auth when configured, and degrades gracefully to local
/// offline / demo authentication when at sea or during local testing.
class AuthRepository {
  AuthRepository({
    this.customClient,
    this.customPreferences,
  });

  final SupabaseClient? customClient;
  SharedPreferences? customPreferences;
  UserProfile? _inMemoryUser;

  static const String _sessionPrefKey = 'orca_user_session';

  SupabaseClient? get client {
    if (customClient != null) return customClient;
    if (Env.hasSupabaseConfig) {
      try {
        return Supabase.instance.client;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<SharedPreferences?> _getPrefs() async {
    if (customPreferences != null) return customPreferences;
    try {
      customPreferences = await SharedPreferences.getInstance();
      return customPreferences;
    } catch (_) {
      // In unit test environments where SharedPreferences is not mocked,
      // fallback to in-memory caching.
      return null;
    }
  }

  /// Restores any previously saved user session.
  ///
  /// Only real Supabase sessions are restored across app restarts.
  /// Offline / demo sessions are intentionally NOT restored — the user must
  /// log in again on each launch when Supabase is not configured.
  Future<UserProfile?> restoreSession() async {
    // Check in-memory first for valid cloud sessions.
    if (_inMemoryUser != null && _inMemoryUser!.isOffline != true) {
      return _inMemoryUser;
    }

    // 1. Try restoring from a live Supabase session first.
    final supabase = client;
    if (supabase != null) {
      try {
        final session = supabase.auth.currentSession;
        if (session != null) {
          final user = session.user;
          final metadata = user.userMetadata ?? {};
          final profile = UserProfile(
            id: user.id,
            email: user.email ?? 'user@orca.sea',
            role: UserRole.fromMetadata(metadata['role'] as String?),
            fullName: metadata['full_name'] as String?,
            assignedPort: metadata['assigned_port'] as String?,
            vesselRegistration: metadata['vessel_registration'] as String?,
            isOffline: false,
            createdAt: DateTime.tryParse(user.createdAt),
          );
          _inMemoryUser = profile;
          await _saveLocally(profile);
          return profile;
        }
      } catch (e) {
        debugPrint('ORCA Auth: Supabase session restore failed ($e).');
      }
    }

    // 2. Check local cache — but ONLY restore if it was a real (non-offline)
    //    Supabase session. Offline/demo sessions must NOT survive a restart.
    try {
      final prefs = await _getPrefs();
      final jsonStr = prefs?.getString(_sessionPrefKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        final profile = UserProfile.fromJson(decoded);
        // Only restore if this was a real cloud session, not a demo/offline one.
        if (profile.isOffline != true) {
          _inMemoryUser = profile;
          return profile;
        } else {
          // Clear the stale offline session so it doesn't linger.
          await prefs?.remove(_sessionPrefKey);
        }
      }
    } catch (e) {
      debugPrint('ORCA Auth: Local session restore error: $e');
    }

    return null;
  }

  /// Sign in with Email and Password.
  /// If [role] is supplied, it is bound to the active session.
  Future<UserProfile> signInWithPassword({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final cleanEmail = email.trim();
    final cleanPassword = password.trim();

    if (cleanEmail.isEmpty) {
      throw const AuthException('Email address cannot be empty.');
    }
    if (cleanPassword.isEmpty) {
      throw const AuthException('Password cannot be empty.');
    }

    final supabase = client;
    if (supabase != null) {
      try {
        final response = await supabase.auth.signInWithPassword(
          email: cleanEmail,
          password: cleanPassword,
        );

        final user = response.user ?? response.session?.user;
        if (user == null) {
          throw const AuthException('No user session returned by authentication service.');
        }

        final metadata = user.userMetadata ?? {};
        final existingRole = metadata['role'] as String?;
        final resolvedRole = existingRole != null
            ? UserRole.fromMetadata(existingRole)
            : role;

        final profile = UserProfile(
          id: user.id,
          email: user.email ?? cleanEmail,
          role: resolvedRole,
          fullName: metadata['full_name'] as String?,
          assignedPort: metadata['assigned_port'] as String?,
          vesselRegistration: metadata['vessel_registration'] as String?,
          isOffline: false,
          createdAt: DateTime.tryParse(user.createdAt),
        );

        _inMemoryUser = profile;
        await _saveLocally(profile);
        return profile;
      } on AuthException {
        rethrow;
      } catch (e) {
        // Network or server timeout: if offline, allow offline login if credentials exist
        debugPrint('ORCA Auth: Supabase error: $e. Falling back to offline authentication.');
      }
    }

    // Offline / Demo mode authentication fallback
    final offlineProfile = UserProfile(
      id: 'usr_${cleanEmail.hashCode.abs().toRadixString(16)}',
      email: cleanEmail,
      role: role,
      fullName: cleanEmail.split('@').first.toUpperCase(),
      assignedPort: 'Rameswaram Fishing Jetty',
      vesselRegistration: role == UserRole.fishermen ? 'IND-TN-10-MM-${(cleanEmail.hashCode % 9000 + 1000).abs()}' : null,
      isOffline: true,
      createdAt: DateTime.now(),
    );

    _inMemoryUser = offlineProfile;
    await _saveLocally(offlineProfile);
    return offlineProfile;
  }

  /// Register a new account with a designated maritime role.
  Future<UserProfile> signUp({
    required String email,
    required String password,
    required UserRole role,
    String? fullName,
    String? assignedPort,
    String? vesselRegistration,
  }) async {
    final cleanEmail = email.trim();
    final cleanPassword = password.trim();

    if (cleanEmail.isEmpty) {
      throw const AuthException('Email address cannot be empty.');
    }
    if (cleanPassword.length < 6) {
      throw const AuthException('Password must be at least 6 characters long.');
    }

    final metadata = <String, dynamic>{
      'role': role.metadataKey,
      if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
      'assigned_port': ?assignedPort,
      'vessel_registration': ?vesselRegistration,
    };

    final supabase = client;
    if (supabase != null) {
      try {
        final response = await supabase.auth.signUp(
          email: cleanEmail,
          password: cleanPassword,
          data: metadata,
        );

        final user = response.user;
        final profile = UserProfile(
          id: user?.id ?? 'usr_${cleanEmail.hashCode.abs().toRadixString(16)}',
          email: cleanEmail,
          role: role,
          fullName: fullName,
          assignedPort: assignedPort ?? 'Rameswaram Port',
          vesselRegistration: vesselRegistration,
          isOffline: false,
          createdAt: user?.createdAt != null ? DateTime.tryParse(user!.createdAt) : DateTime.now(),
        );

        _inMemoryUser = profile;
        await _saveLocally(profile);
        return profile;
      } on AuthException {
        rethrow;
      } catch (e) {
        debugPrint('ORCA Auth: Sign up remote error ($e). Creating offline profile.');
      }
    }

    final profile = UserProfile(
      id: 'usr_${cleanEmail.hashCode.abs().toRadixString(16)}',
      email: cleanEmail,
      role: role,
      fullName: fullName ?? cleanEmail.split('@').first,
      assignedPort: assignedPort ?? 'Rameswaram Fishing Jetty',
      vesselRegistration: vesselRegistration ?? (role == UserRole.fishermen ? 'IND-TN-10-MM-4521' : null),
      isOffline: true,
      createdAt: DateTime.now(),
    );

    _inMemoryUser = profile;
    await _saveLocally(profile);
    return profile;
  }

  /// Instant 1-tap persona login for demonstrations, reviewers, and offline field use.
  Future<UserProfile> quickLoginDemo(UserRole role) async {
    final UserProfile persona;
    switch (role) {
      case UserRole.fishermen:
        persona = const UserProfile(
          id: 'demo_fisherman_01',
          email: 'murugan.fisherman@orca.sea',
          role: UserRole.fishermen,
          fullName: 'Murugan K.',
          assignedPort: 'Rameswaram Jetty (Palk Bay)',
          vesselRegistration: 'IND-TN-10-MM-4521',
          isOffline: true,
        );
        break;
      case UserRole.researchers:
        persona = const UserProfile(
          id: 'demo_researcher_01',
          email: 'ananya.rao@nio.res.in',
          role: UserRole.researchers,
          fullName: 'Dr. Ananya Rao',
          assignedPort: 'NIO Regional Centre, Mandapam',
          isOffline: true,
        );
        break;
      case UserRole.coastalAuthorities:
        persona = const UserProfile(
          id: 'demo_coastguard_01',
          email: 'rajan.icg@gov.in',
          role: UserRole.coastalAuthorities,
          fullName: 'Insp. Rajan V. (ICG)',
          assignedPort: 'Coast Guard Station Mandapam',
          isOffline: true,
        );
        break;
      case UserRole.disasterManagement:
        persona = const UserProfile(
          id: 'demo_disaster_01',
          email: 'control.sdma@tn.gov.in',
          role: UserRole.disasterManagement,
          fullName: 'SDMA Coastal Command Centre',
          assignedPort: 'Ramanathapuram Emergency Operations',
          isOffline: true,
        );
        break;
      case UserRole.maritimeOperators:
        persona = const UserProfile(
          id: 'demo_operator_01',
          email: 'sundaram.voc@maritime.in',
          role: UserRole.maritimeOperators,
          fullName: 'Capt. S. Sundaram',
          assignedPort: 'V.O. Chidambaranar Port Authority',
          vesselRegistration: 'TUG-SEALION-IV',
          isOffline: true,
        );
        break;
    }

    _inMemoryUser = persona;
    await _saveLocally(persona);
    return persona;
  }

  /// Signs out the user and clears all local and remote session tokens.
  Future<void> signOut() async {
    _inMemoryUser = null;
    final supabase = client;
    if (supabase != null) {
      try {
        await supabase.auth.signOut();
      } catch (_) {}
    }

    try {
      final prefs = await _getPrefs();
      await prefs?.remove(_sessionPrefKey);
    } catch (_) {}
  }

  Future<void> _saveLocally(UserProfile profile) async {
    try {
      final prefs = await _getPrefs();
      await prefs?.setString(_sessionPrefKey, jsonEncode(profile.toJson()));
    } catch (_) {}
  }
}
