import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/network/api_envelope.dart';

void main() {
  group('ApiEnvelope', () {
    test('parses the standard backend envelope', () {
      final envelope = ApiEnvelope<Map<String, dynamic>>.fromJson({
        'success': true,
        'message': 'ok',
        'result': {'id': 7},
      }, (json) => json as Map<String, dynamic>);

      expect(envelope.success, isTrue);
      expect(envelope.message, 'ok');
      expect(envelope.result, {'id': 7});
    });

    test('uses msg when message is absent', () {
      final envelope = ApiEnvelope<List<int>>.fromJson({
        'success': false,
        'msg': 'validation failed',
        'result': [1, 2, 3],
      }, (json) => (json as List<dynamic>).cast<int>());

      expect(envelope.success, isFalse);
      expect(envelope.message, 'validation failed');
      expect(envelope.result, [1, 2, 3]);
    });

    test('allows null result without parsing', () {
      final envelope = ApiEnvelope<Map<String, dynamic>>.fromJson({
        'success': true,
        'message': 'ok',
        'result': null,
      }, (_) => throw StateError('result parser should not be called'));

      expect(envelope.success, isTrue);
      expect(envelope.message, 'ok');
      expect(envelope.result, isNull);
    });

    test('allows omitted result without parsing', () {
      final envelope = ApiEnvelope<List<int>>.fromJson({
        'success': true,
        'message': 'ok',
      }, (_) => throw StateError('result parser should not be called'));

      expect(envelope.success, isTrue);
      expect(envelope.message, 'ok');
      expect(envelope.result, isNull);
    });

    test('falls back to an empty message when message is omitted', () {
      final envelope = ApiEnvelope<String>.fromJson({
        'success': true,
        'result': 'ready',
      }, (json) => json! as String);

      expect(envelope.message, '');
      expect(envelope.result, 'ready');
    });

    test('falls back to an empty message when message is null', () {
      final envelope = ApiEnvelope<String>.fromJson({
        'success': true,
        'message': null,
        'result': 'ready',
      }, (json) => json! as String);

      expect(envelope.message, '');
      expect(envelope.result, 'ready');
    });
  });
}
