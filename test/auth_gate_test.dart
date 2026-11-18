import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oria/models/house.dart';
import 'package:oria/screens/auth_gate.dart';
import 'package:oria/screens/login_screen.dart';
import 'package:oria/screens/onboarding_screen.dart';
import 'package:oria/screens/password_reset_screen.dart';
import 'package:oria/services/auth_service.dart';
import 'package:oria/services/house_service.dart';

class FakeAuth extends AuthService {
  Session? session = Session(
    accessToken: 'test',
    tokenType: 'bearer',
    user: User(
      id: 'user',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: '2026-01-01T00:00:00Z',
    ),
  );
  final events = StreamController<AuthState>.broadcast(sync: true);
  @override
  Session? get currentSession => session;
  @override
  Stream<AuthState> get authStateChanges => events.stream;
}

class FakeHouses extends HouseService {
  int calls = 0;
  Future<List<House>> Function() load = () async => [];
  @override
  Future<List<House>> getMyHouses() {
    calls++;
    return load();
  }
}

void main() {
  late FakeAuth auth;
  late FakeHouses houses;
  setUp(() {
    auth = FakeAuth();
    houses = FakeHouses();
  });
  tearDown(() async {
    await auth.events.close();
  });

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AuthGate(
          authService: auth,
          houseService: houses,
          loadTimeout: const Duration(seconds: 1),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('signed-out users reach login and registration', (tester) async {
    auth.session = null;
    await open(tester);
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    await tester.tap(find.text('Criar meu acesso'));
    await tester.pumpAndSettle();
    expect(find.text('Nome'), findsOneWidget);
    expect(houses.calls, 0);
  });

  testWidgets(
    'authenticated new account chooses a family before seeing forms',
    (tester) async {
      await open(tester);
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text('Nome da casa'), findsNothing);
      expect(find.text('Nome da família'), findsNothing);
      await tester.tap(find.text('Entrar em uma família'));
      await tester.pumpAndSettle();
      expect(find.text('Nome da família'), findsOneWidget);
      expect(find.text('Nome da casa'), findsNothing);
      await tester.tap(find.text('Escolher outra opção'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Criar uma casa'));
      await tester.pumpAndSettle();
      expect(find.text('Nome da casa'), findsOneWidget);
      expect(find.text('Nome da família'), findsNothing);
    },
  );

  testWidgets('timeout shows retry instead of endless splash or onboarding', (
    tester,
  ) async {
    houses.load = () => Completer<List<House>>().future;
    await open(tester);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
    houses.load = () async => [];
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('database error does not pretend user has no house', (
    tester,
  ) async {
    houses.load = () async => throw StateError('offline');
    await open(tester);
    await tester.pumpAndSettle();
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
  });

  testWidgets('late database response cannot override sign out', (
    tester,
  ) async {
    final pending = Completer<List<House>>();
    houses.load = () => pending.future;
    await open(tester);
    auth.session = null;
    auth.events.add(AuthState(AuthChangeEvent.signedOut, null));
    await tester.pumpAndSettle();
    pending.complete([]);
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('token refresh does not reload the house', (tester) async {
    await open(tester);
    await tester.pumpAndSettle();
    expect(find.text('Sair da conta'), findsOneWidget);
    auth.events.add(AuthState(AuthChangeEvent.tokenRefreshed, auth.session));
    await tester.pumpAndSettle();
    expect(houses.calls, 1);
  });

  testWidgets('password recovery can finish without looping', (tester) async {
    await open(tester);
    await tester.pumpAndSettle();
    auth.events.add(AuthState(AuthChangeEvent.passwordRecovery, auth.session));
    await tester.pumpAndSettle();
    final screen = tester.widget<PasswordResetScreen>(
      find.byType(PasswordResetScreen),
    );
    await screen.onDone();
    await tester.pumpAndSettle();
    expect(find.byType(PasswordResetScreen), findsNothing);
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });
}
