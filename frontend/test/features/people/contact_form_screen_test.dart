import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:pickup/features/people/data/contact_api.dart';
import 'package:pickup/features/people/data/contact_dtos.dart';
import 'package:pickup/features/people/presentation/contact_form_screen.dart';

/// Records every request the widget sends and replies with a canned response
/// keyed by method + path, so tests never touch a real network.
class _FakeAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  final Map<String, ResponseBody Function(RequestOptions)> responses = {};

  String _key(RequestOptions o) => '${o.method} ${o.path}';

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final handler = responses[_key(options)];
    if (handler == null) {
      throw StateError('No fake response registered for ${_key(options)}');
    }
    return handler(options);
  }

  void onSuccess(String method, String path, Map<String, dynamic> body, {int status = 200}) {
    responses['$method $path'] = (_) => ResponseBody.fromString(
          jsonEncode(body),
          status,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
  }

  void onError(String method, String path, Map<String, dynamic> body, {int status = 400}) {
    responses['$method $path'] = (_) => ResponseBody.fromString(
          jsonEncode(body),
          status,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
  }
}

Map<String, dynamic> _envelope(Map<String, dynamic> data) => {'success': true, 'data': data, 'error': null};

Map<String, dynamic> _errorEnvelope(String code, String message) =>
    {'success': false, 'data': null, 'error': {'code': code, 'message': message, 'fieldErrors': []}};

Map<String, dynamic> _contactJson(String id) => {
      'id': id,
      'name': 'Jamie Rivera',
      'phone': null,
      'email': null,
      'defaultAddress': null,
      'defaultLat': null,
      'defaultLng': null,
      'notes': null,
      'preferredRole': null,
      'vehicleCount': 0,
      'archivedAt': null,
      'createdAt': '2026-01-01T00:00:00.000Z',
      'updatedAt': '2026-01-01T00:00:00.000Z',
    };

Map<String, dynamic> _vehicleJson(String contactId) => {
      'id': 'v1',
      'contactId': contactId,
      'label': "Jamie's car",
      'make': null,
      'model': null,
      'color': null,
      'plate': null,
      'seats': 4,
      'notes': null,
      'createdAt': '2026-01-01T00:00:00.000Z',
    };

/// The vehicle fields push this form well past the default 800x600 test
/// surface; without a taller viewport, taps/text-entry below the fold fail
/// hit-testing instead of scrolling into view.
void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pumpForm(
  WidgetTester tester, {
  required _FakeAdapter adapter,
}) async {
  _useTallViewport(tester);
  final dio = Dio(BaseOptions(baseUrl: ''))..httpClientAdapter = adapter;
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const Scaffold(body: Text('home'))),
      GoRoute(path: '/form', builder: (_, __) => const ContactFormScreen()),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [contactApiProvider.overrideWithValue(ContactApi(dio))],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  router.push('/form');
  await tester.pumpAndSettle();
}

void main() {
  group('ContactFormScreen — add person', () {
    testWidgets('vehicle option is hidden until the checkbox is ticked', (tester) async {
      await _pumpForm(tester, adapter: _FakeAdapter());

      expect(find.text('Add a vehicle for this person'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Label'), findsNothing);

      await tester.tap(find.text('Add a vehicle for this person'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextFormField, 'Label'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Make (optional)'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Model (optional)'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Total seats'), findsOneWidget);
    });

    testWidgets('does not show the vehicle option when editing an existing contact', (tester) async {
      final adapter = _FakeAdapter();
      final dio = Dio(BaseOptions(baseUrl: ''))..httpClientAdapter = adapter;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [contactApiProvider.overrideWithValue(ContactApi(dio))],
          child: MaterialApp(
            home: ContactFormScreen(
              existing: ContactResponse.fromJson(_contactJson('c1')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add a vehicle for this person'), findsNothing);
    });

    testWidgets('requires a label once the vehicle option is enabled, but not make/model', (tester) async {
      final adapter = _FakeAdapter();
      adapter.onSuccess('POST', '/contacts', _envelope(_contactJson('c1')));
      await _pumpForm(tester, adapter: adapter);

      await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Jamie Rivera');
      await tester.tap(find.text('Add a vehicle for this person'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Add person'));
      await tester.pumpAndSettle();

      expect(find.text('Label is required'), findsOneWidget);
      // The contact must not be created until validation passes.
      expect(adapter.requests, isEmpty);
    });

    testWidgets('creates the contact then the vehicle from just a label', (tester) async {
      final adapter = _FakeAdapter();
      adapter.onSuccess('POST', '/contacts', _envelope(_contactJson('c1')));
      adapter.onSuccess('POST', '/contacts/c1/vehicles', _envelope(_vehicleJson('c1')));
      await _pumpForm(tester, adapter: adapter);

      await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Jamie Rivera');
      await tester.tap(find.text('Add a vehicle for this person'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Label'), "Jamie's car");
      // Make/model intentionally left blank — only the label is required.

      await tester.tap(find.widgetWithText(FilledButton, 'Add person'));
      await tester.pumpAndSettle();

      expect(adapter.requests.map((r) => '${r.method} ${r.path}').toList(), [
        'POST /contacts',
        'POST /contacts/c1/vehicles',
      ]);
      final vehicleBody = adapter.requests.last.data as Map<String, dynamic>;
      expect(vehicleBody['label'], "Jamie's car");
      expect(vehicleBody.containsKey('make'), isFalse);
      expect(vehicleBody.containsKey('model'), isFalse);
      expect(vehicleBody['seats'], 4);
      expect(find.text('Person added'), findsOneWidget);
      // Navigated back to the previous route after success.
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('sends make and model when provided alongside the label', (tester) async {
      final adapter = _FakeAdapter();
      adapter.onSuccess('POST', '/contacts', _envelope(_contactJson('c1')));
      adapter.onSuccess('POST', '/contacts/c1/vehicles', _envelope(_vehicleJson('c1')));
      await _pumpForm(tester, adapter: adapter);

      await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Jamie Rivera');
      await tester.tap(find.text('Add a vehicle for this person'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Label'), "Jamie's car");
      await tester.enterText(find.widgetWithText(TextFormField, 'Make (optional)'), 'Toyota');
      await tester.enterText(find.widgetWithText(TextFormField, 'Model (optional)'), 'Corolla');

      await tester.tap(find.widgetWithText(FilledButton, 'Add person'));
      await tester.pumpAndSettle();

      final vehicleBody = adapter.requests.last.data as Map<String, dynamic>;
      expect(vehicleBody['make'], 'Toyota');
      expect(vehicleBody['model'], 'Corolla');
    });

    testWidgets('surfaces a distinct message when the vehicle fails to save', (tester) async {
      final adapter = _FakeAdapter();
      adapter.onSuccess('POST', '/contacts', _envelope(_contactJson('c1')));
      adapter.onError(
        'POST',
        '/contacts/c1/vehicles',
        _errorEnvelope('VALIDATION_ERROR', 'Seats must be between 1 and 15'),
      );
      await _pumpForm(tester, adapter: adapter);

      await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Jamie Rivera');
      await tester.tap(find.text('Add a vehicle for this person'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Label'), "Jamie's car");

      await tester.tap(find.widgetWithText(FilledButton, 'Add person'));
      await tester.pumpAndSettle();

      expect(
        find.text('Person added, but the vehicle could not be saved: Seats must be between 1 and 15'),
        findsOneWidget,
      );
      // Still navigates away — the contact itself was created successfully.
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('skips vehicle creation entirely when the option is left unchecked', (tester) async {
      final adapter = _FakeAdapter();
      adapter.onSuccess('POST', '/contacts', _envelope(_contactJson('c1')));
      await _pumpForm(tester, adapter: adapter);

      await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Jamie Rivera');
      await tester.tap(find.widgetWithText(FilledButton, 'Add person'));
      await tester.pumpAndSettle();

      expect(adapter.requests.map((r) => '${r.method} ${r.path}').toList(), ['POST /contacts']);
      expect(find.text('Person added'), findsOneWidget);
    });
  });
}
