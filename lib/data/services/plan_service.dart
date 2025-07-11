import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../../core/constants/api_constants.dart';
import '../models/mobile_plans.dart';
import '../models/operator_info.dart';
import 'plan_api_service.dart';

/// Result class for recharge validation
class RechargeValidationResult {
  final bool isValid;
  final String? errorMessage;
  final double shortfallAmount;

  const RechargeValidationResult({
    required this.isValid,
    this.errorMessage,
    required this.shortfallAmount,
  });

  @override
  String toString() {
    return 'RechargeValidationResult(isValid: $isValid, errorMessage: $errorMessage, shortfallAmount: $shortfallAmount)';
  }
}

/// Service for fetching mobile plans
class PlanService {
  static final PlanService _instance = PlanService._internal();
  factory PlanService() => _instance;
  PlanService._internal();

  final Logger _logger = Logger();
  final PlanApiService _planApiService = PlanApiService();

  /// Fetch mobile plans using PlanAPI.in
  Future<MobilePlans?> fetchMobilePlans(String operatorCode, String circleCode) async {
    _logger.i('Fetching mobile plans for operator: $operatorCode, circle: $circleCode');

    try {
      // Use PlanAPI.in to fetch real plans
      final mobilePlans = await _planApiService.fetchMobilePlans(operatorCode, circleCode);
      
      if (mobilePlans != null && mobilePlans.allPlans.isNotEmpty) {
        _logger.i('✅ Successfully fetched ${mobilePlans.allPlans.length} plans from PlanAPI.in');
        return mobilePlans;
      } else {
        _logger.w('⚠️ No plans returned from PlanAPI.in');
        throw Exception('No plans available for the selected operator and circle');
      }
    } catch (e) {
      _logger.e('❌ Failed to fetch mobile plans: $e');
      throw Exception('Failed to fetch mobile plans: ${e.toString()}');
    }
  }

  /// Get operator-specific featured plans
  List<PlanItem> getFeaturedPlans(MobilePlans mobilePlans) {
    final List<PlanItem> featuredPlans = [];
    
    // Get popular plans from different categories
    if (mobilePlans.data.isNotEmpty) {
      featuredPlans.addAll(mobilePlans.data.take(3));
    }
    
    if (mobilePlans.trulyUnlimited.isNotEmpty) {
      featuredPlans.addAll(mobilePlans.trulyUnlimited.take(2));
    }
    
    if (mobilePlans.planVouchers.isNotEmpty) {
      featuredPlans.addAll(mobilePlans.planVouchers.take(2));
    }
    
    // Sort by price and return top 8
    featuredPlans.sort((a, b) => a.rs.compareTo(b.rs));
    return featuredPlans.take(8).toList();
  }

  /// Get plans by category
  List<PlanItem> getPlansByCategory(MobilePlans mobilePlans, String category) {
    switch (category.toLowerCase()) {
      case 'data':
        return mobilePlans.data;
      case 'unlimited':
        return mobilePlans.trulyUnlimited;
      case 'talktime':
        return mobilePlans.talktime;
      case 'cricket':
        return mobilePlans.cricketPacks;
      case 'vouchers':
        return mobilePlans.planVouchers;
      case 'roaming':
        return mobilePlans.roamingPacks;
      default:
        return mobilePlans.allPlans;
    }
  }

  /// Search plans by price range
  List<PlanItem> searchPlansByPrice(MobilePlans mobilePlans, int minPrice, int maxPrice) {
    return mobilePlans.allPlans
        .where((plan) => plan.rs >= minPrice && plan.rs <= maxPrice)
        .toList();
  }

  /// Get popular plan amounts
  List<int> getPopularPlanAmounts() {
    return [149, 199, 239, 299, 399, 449, 499, 599, 699, 799, 999, 1499, 1999, 2999];
  }

  /// Check if plan is popular
  bool isPopularPlan(int amount) {
    final popularAmounts = getPopularPlanAmounts();
    return popularAmounts.contains(amount);
  }

  /// Get plan categories
  List<String> getPlanCategories() {
    return ['Data', 'Unlimited', 'Talktime', 'Cricket', 'Vouchers', 'Roaming'];
  }

  /// Format plan validity
  String formatValidity(String validity) {
    if (validity.isEmpty) return 'N/A';
    
    // Clean up validity format
    return validity
        .replaceAll(RegExp(r'(\d+)\s*days?', caseSensitive: false), r'\1 Days')
        .replaceAll(RegExp(r'(\d+)\s*months?', caseSensitive: false), r'\1 Months')
        .replaceAll(RegExp(r'(\d+)\s*years?', caseSensitive: false), r'\1 Years');
  }

  /// Get plan type based on amount
  String getPlanType(int amount) {
    if (amount <= 99) return 'Talktime';
    if (amount <= 199) return 'Basic';
    if (amount <= 399) return 'Standard';
    if (amount <= 699) return 'Premium';
    return 'Unlimited';
  }

  /// Get plan color based on type
  String getPlanColor(String type) {
    switch (type.toLowerCase()) {
      case 'talktime':
        return '#FF9800'; // Orange
      case 'basic':
        return '#4CAF50'; // Green
      case 'standard':
        return '#2196F3'; // Blue
      case 'premium':
        return '#9C27B0'; // Purple
      case 'unlimited':
        return '#F44336'; // Red
      default:
        return '#607D8B'; // Blue Grey
    }
  }

  /// Fetch R-offers (special offers) using PlanAPI.in
  Future<List<Map<String, dynamic>>> fetchROffers(String operatorCode, String mobileNumber) async {
    try {
      _logger.i('Fetching R-offers for mobile: ${_maskMobileNumber(mobileNumber)}');

      // Use PlanAPI.in R-offer endpoint
      final url = Uri.parse(APIConstants.rOfferUrl)
          .replace(queryParameters: {
        'userid': APIConstants.apiUserId,
        'password': APIConstants.apiPassword,
        'format': 'json',
        'operator': operatorCode,
        'mobile': mobileNumber,
      });

      _logger.d('PlanAPI R-offer URL: $url');

      // Make HTTP request
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${APIConstants.apiToken}',
        },
      ).timeout(const Duration(seconds: 30));

      _logger.d('Response status: ${response.statusCode}');
      _logger.d('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> apiResponse = json.decode(response.body);
        
        // Handle PlanAPI.in response format
        if (apiResponse['ERROR'] == '0' && apiResponse['STATUS'] == '1') {
          final dynamic rData = apiResponse['RDATA'];
          List<Map<String, dynamic>> offers = [];
          
          if (rData is List) {
            for (var item in rData) {
              if (item is Map<String, dynamic>) {
                offers.add(item);
              }
            }
          }

          _logger.i('R-offers fetched successfully: ${offers.length} offers');
          return offers;
        } else {
          _logger.w('API returned error for R-offers: ${apiResponse['MESSAGE']}');
          return [];
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      _logger.e('Error fetching R-offers: $e');
      return [];
    }
  }

  /// Check last recharge details using PlanAPI.in
  Future<Map<String, dynamic>?> checkLastRecharge(String mobileNumber) async {
    try {
      _logger.i('Checking last recharge for mobile: ${_maskMobileNumber(mobileNumber)}');

      // Use PlanAPI.in last recharge endpoint
      final url = Uri.parse(APIConstants.lastRechargeUrl)
          .replace(queryParameters: {
        'userid': APIConstants.apiUserId,
        'password': APIConstants.apiPassword,
        'format': 'json',
        'mobile': mobileNumber,
      });

      _logger.d('PlanAPI Last Recharge URL: $url');

      // Make HTTP request
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${APIConstants.apiToken}',
        },
      ).timeout(const Duration(seconds: 30));

      _logger.d('Response status: ${response.statusCode}');
      _logger.d('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> apiResponse = json.decode(response.body);
        
        // Handle PlanAPI.in response format
        if (apiResponse['ERROR'] == '0' && apiResponse['STATUS'] == '1') {
          _logger.i('Last recharge checked successfully');
          return apiResponse;
        } else {
          _logger.w('API returned error for last recharge: ${apiResponse['MESSAGE']}');
          return null;
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      _logger.e('Error checking last recharge: $e');
      return null;
    }
  }

  String _maskMobileNumber(String mobileNumber) {
    if (mobileNumber.length >= 10) {
      return '${mobileNumber.substring(0, 3)}***${mobileNumber.substring(7)}';
    }
    return mobileNumber;
  }

  /// Check wallet balance before proceeding with recharge
  Future<bool> checkWalletBalance(double walletBalance, int planAmount) async {
    try {
      _logger.i('Checking wallet balance: ₹$walletBalance against plan amount: ₹$planAmount');
      
      if (walletBalance >= planAmount) {
        _logger.i('✅ Sufficient wallet balance available');
        return true;
      } else {
        final shortfall = planAmount - walletBalance;
        _logger.w('❌ Insufficient wallet balance. Shortfall: ₹$shortfall');
        return false;
      }
    } catch (e) {
      _logger.e('Error checking wallet balance: $e');
      return false;
    }
  }

  /// Get wallet balance shortfall amount
  double getWalletShortfall(double walletBalance, int planAmount) {
    if (walletBalance >= planAmount) return 0.0;
    return planAmount - walletBalance;
  }

  /// Validate recharge prerequisites
  Future<RechargeValidationResult> validateRechargePrerequisites({
    required String mobileNumber,
    required String operatorCode,
    required String circleCode,
    required int planAmount,
    required double walletBalance,
  }) async {
    try {
      _logger.i('Validating recharge prerequisites');

      // Check wallet balance
      final hasEnoughBalance = await checkWalletBalance(walletBalance, planAmount);
      if (!hasEnoughBalance) {
        final shortfall = getWalletShortfall(walletBalance, planAmount);
        return RechargeValidationResult(
          isValid: false,
          errorMessage: 'Insufficient wallet balance. Please add ₹${shortfall.toStringAsFixed(2)} to proceed.',
          shortfallAmount: shortfall,
        );
      }

      // Additional validations can be added here
      // - Check operator validity
      // - Check circle validity
      // - Check mobile number format
      // - Check plan availability

      return RechargeValidationResult(
        isValid: true,
        errorMessage: null,
        shortfallAmount: 0.0,
      );
    } catch (e) {
      _logger.e('Error validating recharge prerequisites: $e');
      return RechargeValidationResult(
        isValid: false,
        errorMessage: 'Failed to validate recharge prerequisites. Please try again.',
        shortfallAmount: 0.0,
      );
    }
  }

  /// Get popular plans (sorted by popularity)
  List<PlanItem> getPopularPlans(MobilePlans plans) {
    final allPlans = plans.allPlans;
    
    // Sort by popularity (based on amount ranges that are commonly used)
    allPlans.sort((a, b) {
      if (a.isPopular && !b.isPopular) return -1;
      if (!a.isPopular && b.isPopular) return 1;
      return a.rs.compareTo(b.rs);
    });
    
    return allPlans.take(20).toList(); // Return top 20 popular plans
  }

  /// Get plans filtered by price range
  List<PlanItem> getPlansByPriceRange(MobilePlans plans, int minPrice, int maxPrice) {
    return plans.allPlans
        .where((plan) => plan.rs >= minPrice && plan.rs <= maxPrice)
        .toList()
      ..sort((a, b) => a.rs.compareTo(b.rs));
  }

  /// Get plans filtered by validity
  List<PlanItem> getPlansByValidity(MobilePlans plans, int minDays, int maxDays) {
    return plans.allPlans.where((plan) {
      final validityText = plan.validity.toLowerCase();
      final RegExp dayPattern = RegExp(r'(\d+)\s*days?');
      final match = dayPattern.firstMatch(validityText);
      
      if (match != null) {
        final days = int.tryParse(match.group(1) ?? '');
        if (days != null) {
          return days >= minDays && days <= maxDays;
        }
      }
      
      return false;
    }).toList()
      ..sort((a, b) => a.rs.compareTo(b.rs));
  }

  /// Search plans by description
  List<PlanItem> searchPlans(MobilePlans plans, String query) {
    if (query.isEmpty) return plans.allPlans;
    
    final queryLower = query.toLowerCase();
    return plans.allPlans
        .where((plan) => 
            plan.cleanDescription.toLowerCase().contains(queryLower) ||
            plan.formattedPrice.contains(query) ||
            plan.validityDisplay.toLowerCase().contains(queryLower))
        .toList();
  }

  /// Get operator-specific demo plans as fallback
  MobilePlans _getOperatorSpecificPlans(String operatorCode) {
    _logger.i('Generating demo plans for operator: $operatorCode');
    
    switch (operatorCode.toUpperCase()) {
      case 'JIO':
      case '14':
      case '11':
        return _getJioPlans();
      case 'AIRTEL':
      case '2':
        return _getAirtelPlans();
      case 'VODAFONE':
      case 'VI':
      case '23':
      case '12':
        return _getViPlans();
      case 'IDEA':
      case '6':
      case '13':
        return _getIdeaPlans();
      case 'BSNL':
      case '5':
      case '15':
        return _getBsnlPlans();
      default:
        return _getDefaultPlans();
    }
  }

  /// Get Jio specific plans
  MobilePlans _getJioPlans() {
    return MobilePlans(
      trulyUnlimited: [
        const PlanItem(rs: 199, validity: '23 days', desc: 'Truly Unlimited 5G Data + Voice + 100 SMS/day'),
        const PlanItem(rs: 239, validity: '28 days', desc: 'Truly Unlimited 5G Data + Voice + 100 SMS/day'),
        const PlanItem(rs: 299, validity: '28 days', desc: 'Truly Unlimited 5G Data + Voice + 100 SMS/day + JioTV'),
        const PlanItem(rs: 395, validity: '84 days', desc: 'Truly Unlimited 5G Data + Voice + 100 SMS/day'),
        const PlanItem(rs: 666, validity: '84 days', desc: 'Truly Unlimited 5G Data + Voice + 100 SMS/day + JioApps'),
        const PlanItem(rs: 999, validity: '84 days', desc: 'Truly Unlimited 5G Data + Voice + 100 SMS/day + Netflix'),
      ],
      data: [
        const PlanItem(rs: 19, validity: '1 day', desc: '1GB Data'),
        const PlanItem(rs: 29, validity: '1 day', desc: '2GB Data'),
        const PlanItem(rs: 52, validity: '28 days', desc: '8GB Data'),
        const PlanItem(rs: 155, validity: '28 days', desc: '15GB Data + Voice'),
        const PlanItem(rs: 179, validity: '28 days', desc: '24GB Data + Voice'),
      ],
      talktime: [
        const PlanItem(rs: 10, validity: '7 days', desc: 'Full Talktime'),
        const PlanItem(rs: 22, validity: '14 days', desc: 'Full Talktime'),
        const PlanItem(rs: 47, validity: '28 days', desc: 'Full Talktime'),
        const PlanItem(rs: 98, validity: '180 days', desc: 'Full Talktime'),
      ],
      cricketPacks: [
        const PlanItem(rs: 61, validity: '28 days', desc: 'Disney+ Hotstar Mobile + 6GB Data'),
        const PlanItem(rs: 103, validity: '28 days', desc: 'JioSaavn Pro + 12GB Data'),
      ],
      planVouchers: [
        const PlanItem(rs: 75, validity: '28 days', desc: 'Netflix Mobile + 6GB Data'),
        const PlanItem(rs: 175, validity: '28 days', desc: 'Amazon Prime + JioApps + 24GB Data'),
      ],
      roamingPacks: [
        const PlanItem(rs: 51, validity: '1 day', desc: 'International Roaming + 100MB'),
        const PlanItem(rs: 575, validity: '7 days', desc: 'International Roaming + 1GB'),
      ],
      status: 'SUCCESS',
      message: 'Demo Jio plans loaded',
    );
  }

  /// Get Airtel specific plans
  MobilePlans _getAirtelPlans() {
    return MobilePlans(
      trulyUnlimited: [
        const PlanItem(rs: 179, validity: '28 days', desc: 'Unlimited Voice + 2GB/day + 100 SMS/day'),
        const PlanItem(rs: 265, validity: '28 days', desc: 'Unlimited Voice + 1GB/day + 100 SMS/day + Airtel Thanks'),
        const PlanItem(rs: 299, validity: '28 days', desc: 'Unlimited Voice + 1.5GB/day + 100 SMS/day + Disney+ Hotstar'),
        const PlanItem(rs: 359, validity: '28 days', desc: 'Unlimited Voice + 2GB/day + 100 SMS/day + Netflix'),
        const PlanItem(rs: 549, validity: '56 days', desc: 'Unlimited Voice + 2GB/day + 100 SMS/day'),
        const PlanItem(rs: 839, validity: '84 days', desc: 'Unlimited Voice + 2GB/day + 100 SMS/day + Apollo 24/7'),
      ],
      data: [
        const PlanItem(rs: 18, validity: '1 day', desc: '1GB Data'),
        const PlanItem(rs: 31, validity: '2 days', desc: '3GB Data'),
        const PlanItem(rs: 65, validity: '21 days', desc: '4GB Data + Unlimited Voice'),
        const PlanItem(rs: 155, validity: '24 days', desc: '1GB/day + Unlimited Voice'),
      ],
      talktime: [
        const PlanItem(rs: 10, validity: '7 days', desc: 'Full Talktime'),
        const PlanItem(rs: 23, validity: '18 days', desc: 'Full Talktime'),
        const PlanItem(rs: 45, validity: '28 days', desc: 'Full Talktime'),
        const PlanItem(rs: 95, validity: '180 days', desc: 'Full Talktime'),
      ],
      cricketPacks: [
        const PlanItem(rs: 49, validity: '28 days', desc: 'Cricbuzz Premium + 4GB Data'),
        const PlanItem(rs: 99, validity: '28 days', desc: 'Disney+ Hotstar Mobile + 12GB Data'),
      ],
      planVouchers: [
        const PlanItem(rs: 82, validity: '28 days', desc: 'Netflix Mobile + 6GB Data'),
        const PlanItem(rs: 148, validity: '28 days', desc: 'Amazon Prime + Airtel Thanks + 12GB Data'),
      ],
      roamingPacks: [
        const PlanItem(rs: 39, validity: '1 day', desc: 'National Roaming + 1GB Data'),
        const PlanItem(rs: 144, validity: '30 days', desc: 'National Roaming + 1GB/day'),
      ],
      status: 'SUCCESS',
      message: 'Demo Airtel plans loaded',
    );
  }

  /// Get Vi (Vodafone-Idea) specific plans
  MobilePlans _getViPlans() {
    return MobilePlans(
      trulyUnlimited: [
        const PlanItem(rs: 189, validity: '28 days', desc: 'Unlimited Voice + 2GB/day + 100 SMS/day'),
        const PlanItem(rs: 289, validity: '28 days', desc: 'Unlimited Voice + 1.5GB/day + 100 SMS/day + Vi Movies & TV'),
        const PlanItem(rs: 359, validity: '28 days', desc: 'Unlimited Voice + 2GB/day + 100 SMS/day + Netflix'),
        const PlanItem(rs: 539, validity: '56 days', desc: 'Unlimited Voice + 2GB/day + 100 SMS/day'),
        const PlanItem(rs: 719, validity: '84 days', desc: 'Unlimited Voice + 1.5GB/day + 100 SMS/day'),
      ],
      data: [
        const PlanItem(rs: 16, validity: '1 day', desc: '1GB Data'),
        const PlanItem(rs: 27, validity: '2 days', desc: '2GB Data'),
        const PlanItem(rs: 58, validity: '28 days', desc: '4GB Data + Unlimited Voice'),
        const PlanItem(rs: 157, validity: '28 days', desc: '1GB/day + Unlimited Voice'),
      ],
      talktime: [
        const PlanItem(rs: 10, validity: '7 days', desc: 'Full Talktime'),
        const PlanItem(rs: 20, validity: '18 days', desc: 'Full Talktime'),
        const PlanItem(rs: 50, validity: '28 days', desc: 'Full Talktime'),
        const PlanItem(rs: 100, validity: '180 days', desc: 'Full Talktime'),
      ],
      cricketPacks: [
        const PlanItem(rs: 59, validity: '28 days', desc: 'SonyLIV + 6GB Data'),
        const PlanItem(rs: 89, validity: '28 days', desc: 'Vi Movies & TV + 12GB Data'),
      ],
      planVouchers: [
        const PlanItem(rs: 79, validity: '28 days', desc: 'Netflix Mobile + 6GB Data'),
        const PlanItem(rs: 149, validity: '28 days', desc: 'Amazon Prime + Vi Apps + 12GB Data'),
      ],
      roamingPacks: [
        const PlanItem(rs: 36, validity: '1 day', desc: 'National Roaming + 1GB Data'),
        const PlanItem(rs: 109, validity: '28 days', desc: 'National Roaming + 1GB/day'),
      ],
      status: 'SUCCESS',
      message: 'Demo Vi plans loaded',
    );
  }

  /// Get IDEA specific plans
  MobilePlans _getIdeaPlans() {
    return _getViPlans(); // Same as Vi after merger
  }

  /// Get BSNL specific plans
  MobilePlans _getBsnlPlans() {
    return MobilePlans(
      trulyUnlimited: [
        const PlanItem(rs: 108, validity: '25 days', desc: 'Unlimited Voice + 2GB/day + 100 SMS/day'),
        const PlanItem(rs: 187, validity: '28 days', desc: 'Unlimited Voice + 2GB/day + 100 SMS/day'),
        const PlanItem(rs: 397, validity: '80 days', desc: 'Unlimited Voice + 2GB/day + 100 SMS/day'),
        const PlanItem(rs: 797, validity: '160 days', desc: 'Unlimited Voice + 2GB/day + 100 SMS/day'),
      ],
      data: [
        const PlanItem(rs: 17, validity: '2 days', desc: '1GB Data'),
        const PlanItem(rs: 47, validity: '14 days', desc: '3GB Data + Unlimited Voice'),
        const PlanItem(rs: 97, validity: '22 days', desc: '2GB/day + Unlimited Voice'),
      ],
      talktime: [
        const PlanItem(rs: 22, validity: '18 days', desc: 'Full Talktime'),
        const PlanItem(rs: 57, validity: '54 days', desc: 'Full Talktime'),
        const PlanItem(rs: 107, validity: '90 days', desc: 'Full Talktime'),
      ],
      cricketPacks: [],
      planVouchers: [],
      roamingPacks: [
        const PlanItem(rs: 57, validity: '18 days', desc: 'National Roaming + 1GB/day'),
      ],
      status: 'SUCCESS',
      message: 'Demo BSNL plans loaded',
    );
  }

  /// Get default plans for unknown operators
  MobilePlans _getDefaultPlans() {
    return MobilePlans(
      trulyUnlimited: [
        const PlanItem(rs: 199, validity: '28 days', desc: 'Unlimited Voice + 2GB/day + 100 SMS/day'),
        const PlanItem(rs: 299, validity: '28 days', desc: 'Unlimited Voice + 2GB/day + 100 SMS/day + OTT Benefits'),
        const PlanItem(rs: 399, validity: '28 days', desc: 'Unlimited Voice + 2.5GB/day + 100 SMS/day + Premium Benefits'),
        const PlanItem(rs: 599, validity: '56 days', desc: 'Unlimited Voice + 2GB/day + 100 SMS/day'),
        const PlanItem(rs: 999, validity: '84 days', desc: 'Unlimited Voice + 2GB/day + 100 SMS/day + All Benefits'),
      ],
      data: [
        const PlanItem(rs: 19, validity: '1 day', desc: '1GB Data'),
        const PlanItem(rs: 49, validity: '3 days', desc: '3GB Data + Unlimited Voice'),
        const PlanItem(rs: 99, validity: '7 days', desc: '6GB Data + Unlimited Voice'),
        const PlanItem(rs: 149, validity: '24 days', desc: '1GB/day + Unlimited Voice'),
        const PlanItem(rs: 179, validity: '28 days', desc: '2GB Data + Unlimited Voice'),
      ],
      talktime: [
        const PlanItem(rs: 10, validity: '7 days', desc: 'Full Talktime'),
        const PlanItem(rs: 20, validity: '14 days', desc: 'Full Talktime'),
        const PlanItem(rs: 50, validity: '28 days', desc: 'Full Talktime'),
        const PlanItem(rs: 100, validity: '56 days', desc: 'Full Talktime'),
        const PlanItem(rs: 200, validity: '90 days', desc: 'Full Talktime'),
      ],
      cricketPacks: [
        const PlanItem(rs: 59, validity: '28 days', desc: 'Sports Premium + 6GB Data'),
        const PlanItem(rs: 99, validity: '28 days', desc: 'Entertainment Pack + 12GB Data'),
      ],
      planVouchers: [
        const PlanItem(rs: 79, validity: '28 days', desc: 'Streaming Mobile + 6GB Data'),
        const PlanItem(rs: 149, validity: '28 days', desc: 'Premium Benefits + 12GB Data'),
      ],
      roamingPacks: [
        const PlanItem(rs: 39, validity: '1 day', desc: 'National Roaming + 1GB Data'),
        const PlanItem(rs: 99, validity: '7 days', desc: 'National Roaming + 7GB Data'),
      ],
      status: 'SUCCESS',
      message: 'Demo plans loaded (API unavailable)',
    );
  }
} 