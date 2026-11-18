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
  final AuthService? authService;
  final HouseService? houseService;
  final Duration loadTimeout;

  const AuthGate({
    super.key,
    this.authService,
    this.houseService,
    this.loadTimeout = const Duration(seconds: 15),
  });

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final AuthService _auth;
  late final HouseService _houseService;

  StreamSubscription<AuthState>? _subscription;

  bool _loading = true;
  Session? _session;
  House? _house;
  bool _loadFailed = false;
  int _loadVersion = 0;
  final String? _inviteToken = Uri.base.queryParameters['invite'];
  final String? _joinToken = Uri.base.queryParameters['join'];
  bool _passwordResetMode =
      Uri.base.queryParameters['reset'] == '1' ||
      Uri.base.fragment.contains('type=recovery');
  bool _inviteHandled = false;
  bool _joinHandled = false;

  @override
  void initState() {
    super.initState();
    _auth = widget.authService ?? AuthService();
    _houseService = widget.houseService ?? HouseService();
    _session = _auth.currentSession;
    _subscription = _auth.authStateChanges.listen((state) {
      if (!mounted) return;
      if (state.event == AuthChangeEvent.passwordRecovery) {
        setState(() => _passwordResetMode = true);
      }
      final sameUser = _session?.user.id == state.session?.user.id;
      _session = state.session;
      // A token refresh must not replace the screen or discard unsaved work.
      if (sameUser && state.session != null) return;
      _house = null;
      _loadHouse();
    });
    _loadHouse();
  }

  Future<void> _loadHouse() async {
    final version = ++_loadVersion;
    final currentSession = _auth.currentSession;

    if (currentSession == null) {
      if (!mounted) return;
      setState(() {
        _session = null;
        _house = null;
        _loading = false;
        _loadFailed = false;
      });
      return;
    }

    if (mounted) {
      setState(() {
        _session = currentSession;
        _loading = true;
        _loadFailed = false;
      });
    }

    try {
      final houses = await _houseService.getMyHouses().timeout(
        widget.loadTimeout,
      );
      if (!mounted || version != _loadVersion) return;
      setState(() {
        _house = houses.isEmpty ? null : houses.first;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || version != _loadVersion) return;
      setState(() {
        _house = null;
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  @override
  void dispose() {
    _loadVersion++;
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
          _passwordResetMode = false;
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

    if (_loadFailed) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Não consegui carregar sua casa. Confira sua conexão e tente novamente.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loadHouse,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_house == null) return OnboardingScreen(onCreated: _loadHouse);
    return ShellScreen(house: _house!);
  }
}
