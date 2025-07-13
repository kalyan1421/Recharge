import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/mobile_plans.dart';
import '../../data/models/operator_info.dart';
import '../../data/models/wallet_models.dart';
import '../../data/services/plan_api_service.dart';
import '../../data/services/enhanced_recharge_service.dart';
import '../../data/services/wallet_service.dart';
import '../providers/auth_provider.dart';

class PlanSelectionScreen extends StatefulWidget {
  final String mobileNumber;
  final OperatorInfo operatorInfo;

  const PlanSelectionScreen({
    Key? key,
    required this.mobileNumber,
    required this.operatorInfo,
  }) : super(key: key);

  @override
  State<PlanSelectionScreen> createState() => _PlanSelectionScreenState();
}

class _PlanSelectionScreenState extends State<PlanSelectionScreen> {
  final PlanApiService _planApiService = PlanApiService();
  final EnhancedRechargeService _rechargeService = EnhancedRechargeService();
  final WalletService _walletService = WalletService();

  MobilePlansResponse? _plansResponse;
  ROfferResponse? _rOfferResponse;
  double _userWalletBalance = 0.0;
  bool _isLoadingPlans = false;
  bool _isLoadingROffers = false;
  bool _isLoadingWallet = false;
  bool _isProcessingRecharge = false;
  String? _plansError;
  String? _rOffersError;
  String? _walletError;
  String _selectedCategory = 'Unlimited';

  @override
  void initState() {
    super.initState();
    _fetchMobilePlans();
    _fetchROffers();
    _fetchWalletBalance();
  }

  @override
  void dispose() {
    _planApiService.dispose();
    _rechargeService.dispose();
    _walletService.dispose();
    super.dispose();
  }

  Future<void> _fetchMobilePlans() async {
    setState(() {
      _isLoadingPlans = true;
      _plansError = null;
    });

    try {
      final response = await _planApiService.getMobilePlans(
        operatorCode: widget.operatorInfo.opCode,
        circleCode: widget.operatorInfo.circleCode,
      );

      if (mounted) {
        setState(() {
          _plansResponse = response;
          _isLoadingPlans = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _plansError = e.toString();
          _isLoadingPlans = false;
        });
      }
    }
  }

  Future<void> _fetchROffers() async {
    setState(() {
      _isLoadingROffers = true;
      _rOffersError = null;
    });

    try {
      final response = await _planApiService.getROffers(
        operatorInfo: widget.operatorInfo,
        mobileNumber: widget.mobileNumber,
      );

      if (mounted) {
        setState(() {
          _rOfferResponse = response;
          _isLoadingROffers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _rOffersError = e.toString();
          _isLoadingROffers = false;
        });
      }
    }
  }

  Future<void> _fetchWalletBalance() async {
    setState(() {
      _isLoadingWallet = true;
      _walletError = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final balances = await _rechargeService.getWalletBalances(user.uid);
      
      if (mounted) {
        setState(() {
          _userWalletBalance = balances['userBalance'] ?? 0.0;
          _isLoadingWallet = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _walletError = e.toString();
          _isLoadingWallet = false;
        });
      }
    }
  }

  Future<void> _processRecharge(PlanDetails plan) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorDialog('Login Required', 'Please login to continue');
      return;
    }

    // Show confirmation dialog
    final confirmed = await _showRechargeConfirmationDialog(plan);
    if (!confirmed) return;

    setState(() => _isProcessingRecharge = true);

    try {
      // Show processing dialog
      _showProcessingDialog();

      final result = await _rechargeService.processRecharge(
        userId: user.uid,
        mobileNumber: widget.mobileNumber,
        operatorName: widget.operatorInfo.operator,
        circleName: widget.operatorInfo.circle,
        amount: plan.priceValue.toDouble(),
      );

      // Close processing dialog
      Navigator.of(context).pop();

      if (result.success) {
        _showSuccessDialog(result);
        // Refresh wallet balance
        _fetchWalletBalance();
      } else {
        _showErrorDialog('Recharge Failed', result.message);
      }
    } catch (e) {
      // Close processing dialog
      Navigator.of(context).pop();
      
      if (e is InsufficientBalanceException) {
        _showInsufficientBalanceDialog(e);
      } else if (e is ValidationException) {
        _showErrorDialog('Recharge Failed', e.message);
      } else {
        _showErrorDialog('Recharge Failed', 'Recharge failed: ${e.toString()}');
      }
    } finally {
      setState(() => _isProcessingRecharge = false);
    }
  }

  Future<bool> _showRechargeConfirmationDialog(PlanDetails plan) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Recharge'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mobile: ${widget.mobileNumber}'),
            Text('Operator: ${widget.operatorInfo.operator}'),
            Text('Circle: ${widget.operatorInfo.circle}'),
            const SizedBox(height: 10),
            Text('Plan: ₹${plan.price}'),
            Text('Validity: ${plan.validity}'),
            Text('Description: ${plan.desc}'),
            const SizedBox(height: 10),
            Text('Wallet Balance: ₹${_userWalletBalance.toStringAsFixed(2)}'),
            Text('After Recharge: ₹${(_userWalletBalance - plan.priceValue).toStringAsFixed(2)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showProcessingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Processing recharge...'),
            const SizedBox(height: 8),
            Text(
              'Please wait while we process your recharge',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(RechargeResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              result.status == 'PROCESSING' ? Icons.hourglass_empty : Icons.check_circle,
              color: result.status == 'PROCESSING' ? Colors.orange : Colors.green,
              size: 30,
            ),
            const SizedBox(width: 10),
            Text(result.status == 'PROCESSING' ? 'Recharge Processing' : 'Recharge Successful'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mobile: ${result.mobileNumber}'),
            Text('Amount: ₹${result.amount?.toStringAsFixed(2) ?? 'N/A'}'),
            Text('Transaction ID: ${result.transactionId}'),
            if (result.operatorTransactionId != null)
              Text('Operator Ref: ${result.operatorTransactionId}'),
            const SizedBox(height: 10),
            Text(result.message),
            if (result.status == 'PROCESSING')
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  'Your recharge is being processed. You will receive confirmation shortly.',
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to home
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }



  void _showInsufficientBalanceDialog(InsufficientBalanceException e) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet, color: Colors.red, size: 30),
            SizedBox(width: 10),
            Text('Insufficient Balance'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('You don\'t have enough balance to complete this recharge.'),
            const SizedBox(height: 10),
            Text('Available Balance: ₹${e.availableBalance.toStringAsFixed(2)}'),
            Text('Required Amount: ₹${e.requiredAmount.toStringAsFixed(2)}'),
            Text('Shortfall: ₹${(e.requiredAmount - e.availableBalance).toStringAsFixed(2)}'),
            const SizedBox(height: 10),
            const Text('Please add money to your wallet to continue.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to add money screen
            },
            child: const Text('Add Money'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Recharge'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              // Navigate to Add Money screen
            },
            child: const Text(
              'Add Money',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Mobile Number Input Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Mobile Number Input
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.phone, color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Mobile Number',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              widget.mobileNumber,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Operator Selection
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.red,
                        child: Text(
                          widget.operatorInfo.operator.substring(0, 1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${widget.operatorInfo.operator}-Prepaid',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Amount Input
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.currency_rupee, color: Colors.grey),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Enter Amount',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Incorrect Recharge wont be refundable.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(height: 16),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Check Offer'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Plan Sheet'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Wallet Balance
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                                             Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           const Text(
                             'Wallet Balance',
                             style: TextStyle(
                               fontSize: 12,
                               color: Colors.grey,
                             ),
                           ),
                           Text(
                             _getWalletBalanceText(),
                             style: const TextStyle(
                               fontSize: 16,
                               fontWeight: FontWeight.bold,
                             ),
                           ),
                         ],
                       ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Proceed Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Proceed',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Category Tabs
          Container(
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildCategoryTab('Unlimited', _selectedCategory == 'Unlimited'),
                  _buildCategoryTab('Data', _selectedCategory == 'Data'),
                  _buildCategoryTab('Talktime', _selectedCategory == 'Talktime'),
                  _buildCategoryTab('Roaming', _selectedCategory == 'Roaming'),
                  _buildCategoryTab('Ratecut', _selectedCategory == 'Ratecut'),
                ],
              ),
            ),
          ),
          // Plans List
          Expanded(
            child: _buildPlansContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTab(String category, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 16, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey,
          ),
        ),
        child: Text(
          category,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildPlansContent() {
    if (_isLoadingPlans) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading plans...'),
          ],
        ),
      );
    }

    if (_plansError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading plans',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _plansError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchMobilePlans,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchMobilePlans,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plans Section
            _buildPlansSection(),
            const SizedBox(height: 24),
            // R-Offers Section (only if available)
            if (_hasROffers()) _buildROffersSection(),
            const SizedBox(height: 24),
            // Recent Recharge Section
            _buildRecentRechargeSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlansSection() {
    if (_plansResponse == null || _plansResponse!.rdata == null) {
      return const Center(
        child: Text('No plans available'),
      );
    }

    final categories = _plansResponse!.rdata!.getAllCategories();
    final selectedCategoryData = categories.firstWhere(
      (cat) => cat.name.toLowerCase().contains(_selectedCategory.toLowerCase()),
      orElse: () => categories.isNotEmpty ? categories.first : PlanCategory(name: 'No Plans', plans: []),
    );

    if (selectedCategoryData.plans.isEmpty) {
      return const Center(
        child: Text('No plans available for this category'),
      );
    }

    return Column(
      children: selectedCategoryData.plans.map((plan) => 
        _buildPlanCard(plan)
      ).toList(),
    );
  }

  Widget _buildPlanCard(PlanItem plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rs ${plan.priceString}/-',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(
                Icons.bookmark_border,
                color: Colors.yellow,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildPlanDetail('Validity', plan.validity),
              const SizedBox(width: 24),
              _buildPlanDetail('Data', _extractDataFromDesc(plan.desc)),
              const SizedBox(width: 24),
              _buildPlanDetail('Unlimited', 'Local/STD'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {},
                child: const Text(
                  'View Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => _selectPlan(plan),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Recharge Now',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _extractDataFromDesc(String desc) {
    // Extract data information from description
    final dataRegex = RegExp(r'(\d+\.?\d*)\s*(GB|MB)', caseSensitive: false);
    final match = dataRegex.firstMatch(desc);
    if (match != null) {
      return '${match.group(1)} ${match.group(2)}/ Day';
    }
    return '1 GB/ Day';
  }

  bool _hasROffers() {
    return _rOfferResponse != null && 
           _rOfferResponse!.rdata != null && 
           _rOfferResponse!.rdata!.isNotEmpty &&
           !_isLoadingROffers &&
           _rOffersError == null;
  }

  Widget _buildROffersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'R-Offers',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._rOfferResponse!.rdata!.map((rOffer) => _buildROfferCard(rOffer)),
      ],
    );
  }

  Widget _buildROfferCard(ROfferItem rOffer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rs ${rOffer.price}/-',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(
                Icons.bookmark_border,
                color: Colors.yellow,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            rOffer.offerText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            rOffer.logDescription,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {},
                child: const Text(
                  'View Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => _selectROffer(rOffer),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Recharge Now',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRechargeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Recharge',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'View All',
                style: TextStyle(
                  color: Colors.purple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildRecentRechargeItem('9876543210', 'Airtel', 'Rs 545/-', 'Success'),
        _buildRecentRechargeItem('9876543210', 'Jio', 'Rs 545/-', 'Success'),
      ],
    );
  }

  Widget _buildRecentRechargeItem(String number, String operator, String amount, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: operator == 'Airtel' ? Colors.red : Colors.blue,
            child: Text(
              operator.substring(0, 1),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  number,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '28 May 2024 | 00:02:26 PM',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Status: $status',
                style: TextStyle(
                  color: status == 'Success' ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {},
            child: const Text(
              'Repeat Recharge',
              style: TextStyle(
                color: Colors.purple,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectPlan(PlanItem plan) {
    // Convert PlanItem to PlanDetails for the new recharge flow
    final planDetails = PlanDetails(
      price: plan.priceString,
      validity: plan.validity,
      desc: plan.desc,
      type: 'unlimited', // Default type since PlanItem doesn't have type
    );
    
    _processRecharge(planDetails);
  }

  void _selectROffer(ROfferItem rOffer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm R-Offer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Mobile: ${widget.mobileNumber}'),
            Text('Operator: ${widget.operatorInfo.operator}'),
            Text('Circle: ${widget.operatorInfo.circle}'),
            Text('Amount: ₹${rOffer.price}'),
            const SizedBox(height: 8),
            Text('Offer: ${rOffer.offerText}'),
            Text('Details: ${rOffer.logDescription}'),
            const SizedBox(height: 8),
            Text(
              'Current Balance: ${_getWalletBalanceText()}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isProcessingRecharge ? null : () {
              Navigator.pop(context);
              _performRecharge(rOffer.price, rOffer.offerText);
            },
            child: _isProcessingRecharge 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Proceed'),
          ),
        ],
      ),
    );
  }



  String _getWalletBalanceText() {
    if (_isLoadingWallet) {
      return 'Loading...';
    }
    if (_walletError != null) {
      return 'Error';
    }
    if (_userWalletBalance != null) {
      return 'Rs ${_userWalletBalance.toStringAsFixed(2)}/-';
    }
    return 'Rs 0.00/-';
  }

  Future<void> _performRecharge(String amount, String description) async {
    if (_isProcessingRecharge) return;

    setState(() {
      _isProcessingRecharge = true;
    });

    try {
      // Validate amount
      if (!_rechargeService.validateRechargeAmount(double.tryParse(amount) ?? 0)) {
        throw Exception('Invalid amount. Amount must be between Rs 10 and Rs 25000');
      }

      // Show processing dialog
      _showRechargeProcessingDialog();

      // Perform recharge
      final response = await _rechargeService.performRechargeWithOperatorInfo(
        userId: FirebaseAuth.instance.currentUser!.uid,
        mobileNumber: widget.mobileNumber,
        operatorName: widget.operatorInfo.operator,
        circleName: widget.operatorInfo.circle,
        amount: double.tryParse(amount) ?? 0,
      );

      // Close processing dialog
      Navigator.of(context).pop();

      // Handle response
      if (response.status == 'SUCCESS') {
        _showSuccessDialog(response);
      } else {
        _showErrorDialog('Recharge Failed', response.message);
      }
      
      // Refresh wallet balance
      _fetchWalletBalance();

    } catch (e) {
      // Close processing dialog
      Navigator.of(context).pop();
      
      // Show error dialog
      _showErrorDialog('Recharge Failed', e.toString());
    } finally {
      setState(() {
        _isProcessingRecharge = false;
      });
    }
  }

  void _showRechargeProcessingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Processing Recharge...'),
            const SizedBox(height: 8),
            Text(
              'Please wait while we process your recharge.',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showRechargeResultDialog(RechargeResult result, String amount, String description) {
    final status = _rechargeService.getRechargeStatusFromResponse(result);
    
    String statusText = status;
    Color statusColor = Colors.grey;
    
    if (status == 'SUCCESS') {
      statusText = 'Success';
      statusColor = Colors.green;
    } else if (status == 'PROCESSING') {
      statusText = 'Processing';
      statusColor = Colors.orange;
    } else if (status == 'FAILED') {
      statusText = 'Failed';
      statusColor = Colors.red;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              status == 'PROCESSING' ? Icons.hourglass_empty : 
              status == 'FAILED' ? Icons.error : 
              Icons.check_circle,
              color: status == 'PROCESSING' ? Colors.orange : 
                     status == 'FAILED' ? Colors.red : 
                     Colors.green,
            ),
            const SizedBox(width: 8),
            Text(statusText),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mobile: ${widget.mobileNumber}'),
            Text('Operator: ${widget.operatorInfo.operator}'),
            Text('Amount: ₹$amount'),
                         Text('Order ID: ${result.transactionId}'),
             if (result.operatorTransactionId != null && result.operatorTransactionId!.isNotEmpty) 
               Text('Transaction ID: ${result.operatorTransactionId}'),
            const SizedBox(height: 8),
            Text('Message: ${result.message}'),
            const SizedBox(height: 8),
            Text(
              'Status: $statusText',
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (status == 'PROCESSING')
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
        actions: [
          if (status == 'PROCESSING')
            TextButton(
              onPressed: () => _checkRechargeStatus(result.transactionId),
              child: const Text('Check Status'),
            ),
          if (status == 'FAILED')
            TextButton(
              onPressed: () => _showComplaintDialog(result),
              child: const Text('Complaint'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkRechargeStatus(String memberReqId) async {
    try {
      final result = await _rechargeService.checkRechargeStatus(memberReqId);
      
      Navigator.of(context).pop(); // Close current dialog
      _showRechargeResultDialog(
        result,
        result.amount?.toString() ?? '0',
        'Status Check',
      );
    } catch (e) {
      _showErrorDialog('Status Check Failed', e.toString());
    }
  }

  void _showComplaintDialog(RechargeResult result) {
    final TextEditingController complaintController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Complaint'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
                     children: [
             Text('Order ID: ${result.transactionId}'),
             Text('Transaction ID: ${result.operatorTransactionId ?? 'N/A'}'),
            const SizedBox(height: 16),
            TextField(
              controller: complaintController,
              decoration: const InputDecoration(
                labelText: 'Complaint Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _submitComplaint(result, complaintController.text),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitComplaint(RechargeResult result, String complaintReason) async {
    if (complaintReason.trim().isEmpty) {
      _showErrorDialog('Invalid Input', 'Please enter a complaint reason.');
      return;
    }

    try {
        final complaintResponse = await _rechargeService.submitRechargeComplaint(
          transactionId: result.transactionId,
          reason: complaintReason,
        );

      Navigator.of(context).pop(); // Close complaint dialog
      
      if (complaintResponse.isSuccess) {
        _showErrorDialog('Complaint Submitted', 'Your complaint has been submitted successfully.');
      } else {
        _showErrorDialog('Complaint Failed', complaintResponse.message);
      }
    } catch (e) {
      _showErrorDialog('Complaint Failed', e.toString());
    }
  }
} 