import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/house.dart';
import '../services/auth_service.dart';
import '../services/house_service.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';
import 'password_reset_screen.dart';
import 'invite_join_screen.dart';
import 'join_link_screen.dart';
import 'shell_screen.dart';
import 'splash_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _auth = AuthService();
  final HouseService _houseService = HouseService();

  StreamSubscription<AuthState>? _subscription;

  bool _loading = true;
  Session? _session;
  House? _house;
  final String? _inviteToken = Uri.base.queryParameters['invite'];
  final String? _joinToken = Uri.base.queryParameters['join'];
  final bool _passwordResetMode = Uri.base.queryParameters['reset'] == '1' || Uri.base.fragment.contains('type=recovery');
  bool _inviteHandled = false;
  bool _joinHandled = false;

  @override
  void initState() {
    super.initState();
    _session = _auth.currentSession;
    _subscription = _auth.authStateChanges.listen((state) {
      if (!mounted) return;
      _session = state.session;
      _house = null;
      _loadHouse();
    });
    _loadHouse();
  }

  Future<void> _loadHouse() async {
    final currentSession = _auth.currentSession;

    if (currentSession == null) {
      if (!mounted) return;
      setState(() {
        _session = null;
        _house = null;
        _loading = false;
      });
      return;
    }

    if (mounted) {
      setState(() {
        _session = currentSession;
        _loading = true;
      });
    }

    try {
      final houses = await _houseService.getMyHouses();
      if (!mounted) return;
      setState(() {
        _house = houses.isEmpty ? null : houses.first;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _house = null;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SplashScreen();
    if (_session == null) {
      return LoginScreen(
        onLoggedIn: _loadHouse,
        inviteMode: _inviteToken != null || _joinToken != null,
      );
    }

    if (_passwordResetMode) {
      return PasswordResetScreen(
        onDone: () async {
          await _loadHouse();
        },
      );
    }

    if (_joinToken != null && !_joinHandled) {
      return JoinLinkScreen(
        token: _joinToken,
        onJoined: () async {
          _joinHandled = true;
          await _loadHouse();
        },
      );
    }

    if (_inviteToken != null && !_inviteHandled) {
      return InviteJoinScreen(
        token: _inviteToken,
        onJoined: () async {
          _inviteHandled = true;
          await _loadHouse();
        },
      );
    }

    if (_house == null) return OnboardingScreen(onCreated: _loadHouse);
    return ShellScreen(house: _house!);
  }
}
