import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:recharger/data/models/operator_info.dart';
import 'package:recharger/data/services/operator_detection_service.dart';

import 'operator_detection_service_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  late MockClient mockClient;
  late OperatorDetectionService service;

  setUp(() {
    mockClient = MockClient();
    service = OperatorDetectionService(client: mockClient);
  });

  group('OperatorDetectionService', () {
    const validMobileNumber = '8890545871';
    final successResponse = {
      'ERROR': '0',
      'STATUS': '1',
      'Mobile': '8890545871',
      'Operator': 'AIRTEL',
      'OpCode': '2',
      'Circle': 'Rajasthan',
      'CircleCode': '70',
      'Message': 'Successfully'
    };

    final errorResponse = {
      'ERROR': '3',
      'STATUS': '3',
      'MOBILENO': '8890545871',
      'Operator': 'null',
      'OpCode': 'null',
      'Circle': 'null',
      'CircleCode': 'null',
      'Message': 'Authentication failed'
    };

    test('detectOperator returns OperatorInfo on successful API call', () async {
      when(mockClient.get(any)).thenAnswer((_) async =>
          http.Response('{"ERROR":"0","STATUS":"1","Mobile":"8890545871",'
              '"Operator":"AIRTEL","OpCode":"2","Circle":"Rajasthan",'
              '"CircleCode":"70","Message":"Successfully"}', 200));

      final result = await service.detectOperator(validMobileNumber);

      expect(result, isA<OperatorInfo>());
      expect(result.operator, equals('AIRTEL'));
      expect(result.circle, equals('Rajasthan'));
      expect(result.isSuccess, isTrue);
    });

    test('detectOperator throws exception on API error', () async {
      when(mockClient.get(any)).thenAnswer((_) async =>
          http.Response('{"ERROR":"3","STATUS":"3","Message":"Authentication failed"}', 401));

      expect(
        () => service.detectOperator(validMobileNumber),
        throwsA(isA<Exception>()),
      );
    });

    test('detectOperator throws exception on network error', () async {
      when(mockClient.get(any)).thenThrow(Exception('Network error'));

      expect(
        () => service.detectOperator(validMobileNumber),
        throwsA(isA<Exception>()),
      );
    });

    test('detectOperator handles timeout correctly', () async {
      when(mockClient.get(any)).thenAnswer(
        (_) async => Future.delayed(
          const Duration(seconds: 31),
          () => http.Response('{}', 200),
        ),
      );

      expect(
        () => service.detectOperator(validMobileNumber),
        throwsA(isA<Exception>()),
      );
    });
  });
} 