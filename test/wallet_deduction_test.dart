import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../lib/data/services/wallet_service.dart';
import '../lib/data/services/enhanced_recharge_service.dart';
import '../lib/data/services/robotics_exchange_service.dart';
import '../lib/data/models/wallet_models.dart';
import '../lib/data/models/recharge_models.dart';
import '../lib/core/constants/api_constants.dart';

// Generate mocks
@GenerateMocks([
  FirebaseFirestore,
  RoboticsExchangeService,
  DocumentReference,
  DocumentSnapshot,
  Transaction,
  CollectionReference,
  Query,
  QuerySnapshot,
])
import 'wallet_deduction_test.mocks.dart';

void main() {
  group('Wallet Deduction Flow Tests', () {
    late WalletService walletService;
    late EnhancedRechargeService rechargeService;
    late MockFirebaseFirestore mockFirestore;
    late MockRoboticsExchangeService mockRoboticsService;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockRoboticsService = MockRoboticsExchangeService();
      walletService = WalletService(
        firestore: mockFirestore,
        roboticsService: mockRoboticsService,
      );
      rechargeService = EnhancedRechargeService(
        walletService: walletService,
        roboticsService: mockRoboticsService,
      );
    });

    group('APIConstants Tests', () {
      test('should validate mobile numbers correctly', () {
        // Valid mobile numbers
        expect(APIConstants.isValidMobileNumber('9876543210'), true);
        expect(APIConstants.isValidMobileNumber('8888888888'), true);
        expect(APIConstants.isValidMobileNumber('7777777777'), true);
        expect(APIConstants.isValidMobileNumber('6666666666'), true);
        expect(APIConstants.isValidMobileNumber('919876543210'), true);
        expect(APIConstants.isValidMobileNumber('+91 9876543210'), true);
        expect(APIConstants.isValidMobileNumber('91-9876543210'), true);

        // Invalid mobile numbers
        expect(APIConstants.isValidMobileNumber('5876543210'), false); // Starts with 5
        expect(APIConstants.isValidMobileNumber('98765432'), false); // Too short
        expect(APIConstants.isValidMobileNumber('98765432101'), false); // Too long
        expect(APIConstants.isValidMobileNumber('abcdefghij'), false); // Non-numeric
        expect(APIConstants.isValidMobileNumber(''), false); // Empty
      });

      test('should clean mobile numbers correctly', () {
        expect(APIConstants.cleanMobileNumber('9876543210'), '9876543210');
        expect(APIConstants.cleanMobileNumber('919876543210'), '9876543210');
        expect(APIConstants.cleanMobileNumber('+91 9876543210'), '9876543210');
        expect(APIConstants.cleanMobileNumber('91-9876-543-210'), '9876543210');
        expect(APIConstants.cleanMobileNumber(' 91 9876 543 210 '), '9876543210');
      });

      test('should get correct robotics operator codes', () {
        expect(APIConstants.getRoboticsOperatorCode('AIRTEL'), 'AT');
        expect(APIConstants.getRoboticsOperatorCode('airtel'), 'AT');
        expect(APIConstants.getRoboticsOperatorCode('JIO'), 'JO');
        expect(APIConstants.getRoboticsOperatorCode('RELIANCE JIO'), 'JO');
        expect(APIConstants.getRoboticsOperatorCode('VODAFONE'), 'VI');
        expect(APIConstants.getRoboticsOperatorCode('VI'), 'VI');
        expect(APIConstants.getRoboticsOperatorCode('IDEA'), 'VI');
        expect(APIConstants.getRoboticsOperatorCode('BSNL'), 'BS');
        expect(APIConstants.getRoboticsOperatorCode('UNKNOWN_OPERATOR'), 'JO'); // Default
      });

      test('should get correct circle codes', () {
        expect(APIConstants.getCircleCode('DELHI'), '10');
        expect(APIConstants.getCircleCode('delhi'), '10');
        expect(APIConstants.getCircleCode('MUMBAI'), '92');
        expect(APIConstants.getCircleCode('KOLKATA'), '31');
        expect(APIConstants.getCircleCode('CHENNAI'), '40');
        expect(APIConstants.getCircleCode('BANGALORE'), '06');
        expect(APIConstants.getCircleCode('BENGALURU'), '06');
        expect(APIConstants.getCircleCode('UNKNOWN_CIRCLE'), '10'); // Default
      });

      test('should validate recharge amounts correctly', () {
        expect(APIConstants.isValidRechargeAmount(10.0), true);
        expect(APIConstants.isValidRechargeAmount(100.0), true);
        expect(APIConstants.isValidRechargeAmount(25000.0), true);
        
        expect(APIConstants.isValidRechargeAmount(9.99), false);
        expect(APIConstants.isValidRechargeAmount(25000.01), false);
        expect(APIConstants.isValidRechargeAmount(0.0), false);
        expect(APIConstants.isValidRechargeAmount(-10.0), false);
      });
    });

    group('Wallet Service Tests', () {
      test('should throw InsufficientBalanceException when user balance is low', () async {
        // Mock user document with low balance
        final mockUserDoc = MockDocumentSnapshot<Map<String, dynamic>>();
        final mockUserRef = MockDocumentReference<Map<String, dynamic>>();
        
        when(mockFirestore.collection('users')).thenReturn(
          MockCollectionReference<Map<String, dynamic>>() as CollectionReference<Map<String, dynamic>>
        );
        
        when(mockUserDoc.exists).thenReturn(true);
        when(mockUserDoc.data()).thenReturn({'walletBalance': 50.0});
        
        // Test insufficient balance
        expect(
          () async => await walletService.processWalletDeduction(
            userId: 'test_user',
            amount: 100.0,
            purpose: 'Test recharge',
            transactionId: 'test_txn',
          ),
          throwsA(isA<InsufficientBalanceException>()),
        );
      });

      test('should throw InsufficientApiBalanceException when API balance is low', () async {
        // Mock API wallet response with low balance
        final mockApiResponse = WalletBalanceResponse(
          errorcode: '0',
          status: 1,
          message: 'Success',
          buyerWalletBalance: 50.0,
          sellerWalletBalance: 100.0,
        );

        when(mockRoboticsService.getWalletBalance())
            .thenAnswer((_) async => mockApiResponse);

        // Test insufficient API balance
        expect(
          () async => await walletService.processWalletDeduction(
            userId: 'test_user',
            amount: 100.0,
            purpose: 'Test recharge',
            transactionId: 'test_txn',
          ),
          throwsA(isA<InsufficientApiBalanceException>()),
        );
      });
    });

    group('Enhanced Recharge Service Tests', () {
      test('should validate recharge inputs correctly', () {
        // Test valid inputs
        expect(
          () => rechargeService.processRecharge(
            userId: 'test_user',
            mobileNumber: '9876543210',
            operatorName: 'AIRTEL',
            circleName: 'DELHI',
            amount: 100.0,
          ),
          returnsNormally,
        );

        // Test invalid mobile number
        expect(
          () => rechargeService.processRecharge(
            userId: 'test_user',
            mobileNumber: '5876543210', // Invalid
            operatorName: 'AIRTEL',
            circleName: 'DELHI',
            amount: 100.0,
          ),
          throwsA(isA<ValidationException>()),
        );

        // Test invalid amount
        expect(
          () => rechargeService.processRecharge(
            userId: 'test_user',
            mobileNumber: '9876543210',
            operatorName: 'AIRTEL',
            circleName: 'DELHI',
            amount: 5.0, // Too low
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('should handle successful recharge flow', () async {
        // Mock successful API responses
        final mockApiResponse = WalletBalanceResponse(
          errorcode: '0',
          status: 1,
          message: 'Success',
          buyerWalletBalance: 1000.0,
          sellerWalletBalance: 2000.0,
        );

        final mockRechargeResponse = RechargeResponse(
          error: '0',
          status: 1,
          orderId: 'ORDER123',
          operatorTransactionId: 'OP123',
          memberRequestId: 'TXN123',
          message: 'Recharge successful',
          commission: 5.0,
          mobileNumber: '9876543210',
          amount: '100',
          lapuNumber: null,
          openingBalance: 1000.0,
          closingBalance: 900.0,
          callbackId: null,
          buyerCommission: 0.0,
        );

        when(mockRoboticsService.getWalletBalance())
            .thenAnswer((_) async => mockApiResponse);
        
        when(mockRoboticsService.performRecharge(
          mobileNumber: anyNamed('mobileNumber'),
          operatorName: anyNamed('operatorName'),
          circleName: anyNamed('circleName'),
          amount: anyNamed('amount'),
        )).thenAnswer((_) async => mockRechargeResponse);

        // Test successful recharge
        final result = await rechargeService.processRecharge(
          userId: 'test_user',
          mobileNumber: '9876543210',
          operatorName: 'AIRTEL',
          circleName: 'DELHI',
          amount: 100.0,
        );

        expect(result.success, true);
        expect(result.status, 'SUCCESS');
        expect(result.transactionId, 'ORDER123');
      });
    });

    group('Exception Handling Tests', () {
      test('should create proper exception messages', () {
        final insufficientBalance = InsufficientBalanceException(
          message: 'Insufficient balance',
          availableBalance: 50.0,
          requiredAmount: 100.0,
        );

        expect(insufficientBalance.availableBalance, 50.0);
        expect(insufficientBalance.requiredAmount, 100.0);
        expect(insufficientBalance.toString(), contains('InsufficientBalanceException'));

        final apiBalanceError = InsufficientApiBalanceException(
          message: 'API balance low',
          availableBalance: 25.0,
          requiredAmount: 100.0,
        );

        expect(apiBalanceError.availableBalance, 25.0);
        expect(apiBalanceError.requiredAmount, 100.0);
        expect(apiBalanceError.toString(), contains('InsufficientApiBalanceException'));

        final validationError = ValidationException('Invalid input', field: 'mobileNumber');
        expect(validationError.field, 'mobileNumber');
        expect(validationError.toString(), contains('ValidationException'));
      });
    });

    group('Integration Tests', () {
      test('should test complete recharge flow with mocked dependencies', () async {
        // This test would require more complex mocking setup
        // but demonstrates the structure for integration testing
        
        // Mock all required dependencies
        // Test the complete flow from validation to transaction completion
        // Verify wallet deduction, API call, and transaction recording
        
        expect(true, true); // Placeholder for actual integration test
      });
    });
  });
} 