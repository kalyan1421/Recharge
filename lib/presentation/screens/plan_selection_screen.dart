import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/mobile_plans.dart';
import '../../data/models/operator_info.dart';
import '../../data/models/recharge_models.dart';
import '../../data/services/plan_api_service.dart';
import '../../data/services/robotics_exchange_service.dart';
import '../widgets/plan_card.dart';

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
  final RoboticsExchangeService _rechargeService = RoboticsExchangeService();

  MobilePlansResponse? _plansResponse;
  ROfferResponse? _rOfferResponse;
  WalletBalanceResponse? _walletBalance;
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
    super.dispose();
  }

  Future<void> _fetchWalletBalance() async {
    setState(() {
      _isLoadingWallet = true;
      _walletError = null;
    });

    try {
      final response = await _rechargeService.getWalletBalance();
      setState(() {
        _walletBalance = response;
        _isLoadingWallet = false;
      });
    } catch (e) {
      setState(() {
        _walletError = e.toString();
        _isLoadingWallet = false;
      });
    }
  }

  Future<void> _fetchMobilePlans() async {
    setState(() {
      _isLoadingPlans = true;
      _plansError = null;
    });

    try {
      final response = await _planApiService.fetchMobilePlansFromOperatorInfo(widget.operatorInfo);
      setState(() {
        _plansResponse = response;
        _isLoadingPlans = false;
      });
    } catch (e) {
      setState(() {
        _plansError = e.toString();
        _isLoadingPlans = false;
      });
    }
  }

  Future<void> _fetchROffers() async {
    setState(() {
      _isLoadingROffers = true;
      _rOffersError = null;
    });

    try {
      final response = await _planApiService.fetchROffersFromOperatorInfo(
        operatorInfo: widget.operatorInfo,
        mobileNumber: widget.mobileNumber,
      );
      setState(() {
        _rOfferResponse = response;
        _isLoadingROffers = false;
      });
    } catch (e) {
      setState(() {
        _rOffersError = e.toString();
        _isLoadingROffers = false;
      });
    }
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
                status,
                style: const TextStyle(
                  color: Colors.green,
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Recharge'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mobile: ${widget.mobileNumber}'),
            Text('Operator: ${widget.operatorInfo.operator}'),
            Text('Circle: ${widget.operatorInfo.circle}'),
            Text('Amount: ₹${plan.priceString}'),
            Text('Validity: ${plan.validity}'),
            const SizedBox(height: 8),
            Text('Details: ${plan.desc}'),
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
              _performRecharge(plan.priceString, plan.desc);
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

  void _selectROffer(ROfferItem rOffer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm R-Offer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
    if (_walletBalance != null && _walletBalance!.isSuccess) {
      return 'Rs ${_walletBalance!.buyerWalletBalance?.toStringAsFixed(2) ?? '0.00'}/-';
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
      if (!_rechargeService.validateRechargeAmount(amount)) {
        throw Exception('Invalid amount. Amount must be between Rs 10 and Rs 25000');
      }

      // Show processing dialog
      _showRechargeProcessingDialog();

      // Perform recharge
      final response = await _rechargeService.performRechargeWithOperatorInfo(
        mobileNumber: widget.mobileNumber,
        operatorInfo: widget.operatorInfo,
        amount: amount,
      );

      // Close processing dialog
      Navigator.of(context).pop();

      // Show result dialog
      _showRechargeResultDialog(response, amount, description);

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

  void _showRechargeResultDialog(RechargeResponse response, String amount, String description) {
    final status = _rechargeService.getRechargeStatusFromResponse(response);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              status == RechargeStatus.success ? Icons.check_circle : 
              status == RechargeStatus.failed ? Icons.error : 
              Icons.hourglass_empty,
              color: status == RechargeStatus.success ? Colors.green : 
                     status == RechargeStatus.failed ? Colors.red : 
                     Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(status.displayName),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mobile: ${widget.mobileNumber}'),
            Text('Operator: ${widget.operatorInfo.operator}'),
            Text('Amount: ₹$amount'),
                         Text('Order ID: ${response.orderId}'),
             if (response.opTransId != null && response.opTransId!.isNotEmpty) 
               Text('Transaction ID: ${response.opTransId}'),
            const SizedBox(height: 8),
            Text('Message: ${response.message}'),
            if (status == RechargeStatus.processing)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Your recharge is being processed. You will receive a confirmation shortly.',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
          ],
        ),
        actions: [
          if (status == RechargeStatus.processing)
            TextButton(
              onPressed: () => _checkRechargeStatus(response.memberReqId),
              child: const Text('Check Status'),
            ),
          if (status == RechargeStatus.failed)
            TextButton(
              onPressed: () => _showComplaintDialog(response),
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
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkRechargeStatus(String memberReqId) async {
    try {
      final response = await _rechargeService.checkRechargeStatus(
        memberRequestTxnId: memberReqId,
      );
      
      Navigator.of(context).pop(); // Close current dialog
             _showRechargeResultDialog(
         RechargeResponse(
           error: response.error,
           status: response.status,
           orderId: response.orderId,
           opTransId: response.opTransId,
           memberReqId: response.memberReqId,
           message: response.message,
           commission: response.commission,
           mobileNo: response.mobileNo,
           amount: response.amount,
           lapuNo: response.lapuNo,
           openingBal: response.openingBal,
           closingBal: response.closingBal,
         ),
         response.amount ?? '0',
         'Status Check',
       );
    } catch (e) {
      _showErrorDialog('Status Check Failed', e.toString());
    }
  }

  void _showComplaintDialog(RechargeResponse response) {
    final TextEditingController complaintController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Complaint'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
                     children: [
             Text('Order ID: ${response.orderId}'),
             Text('Transaction ID: ${response.opTransId ?? 'N/A'}'),
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
            onPressed: () => _submitComplaint(response, complaintController.text),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitComplaint(RechargeResponse response, String complaintReason) async {
    if (complaintReason.trim().isEmpty) {
      _showErrorDialog('Invalid Input', 'Please enter a complaint reason.');
      return;
    }

    try {
             final complaintResponse = await _rechargeService.submitRechargeComplaint(
         memberRequestTxnId: response.memberReqId,
         ourRefTxnId: response.opTransId ?? '',
         complaintReason: complaintReason,
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