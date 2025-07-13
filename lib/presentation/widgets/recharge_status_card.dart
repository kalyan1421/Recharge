import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/mobile_plans.dart';
import '../../core/theme/app_theme.dart';

class RechargeStatusCard extends StatelessWidget {
  final RechargeStatusResponse? statusResponse;
  final bool isLoading;
  final String? error;

  const RechargeStatusCard({
    Key? key,
    this.statusResponse,
    this.isLoading = false,
    this.error,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.blue[50]!, Colors.blue[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history,
                  color: Colors.blue[700],
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Last Recharge Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (error != null)
              _buildErrorContent()
            else if (statusResponse != null)
              _buildStatusContent()
            else
              _buildEmptyContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusContent() {
    if (!statusResponse!.isSuccess) {
      return _buildErrorContent();
    }

    if (!statusResponse!.hasRechargeData) {
      return _buildNoDataContent();
    }

    final dateFormatter = DateFormat('dd MMM yyyy');
    final rechargeDate = DateTime.tryParse(statusResponse!.rechargeDate ?? '');

    return Column(
      children: [
        _buildInfoRow(
          icon: Icons.currency_rupee,
          label: 'Amount',
          value: '₹${statusResponse!.amount}',
          valueColor: Colors.green[700],
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          icon: Icons.calendar_today,
          label: 'Recharge Date',
          value: rechargeDate != null 
              ? dateFormatter.format(rechargeDate)
              : statusResponse!.rechargeDate ?? 'N/A',
          valueColor: Colors.blue[700],
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          icon: Icons.phone,
          label: 'Mobile Number',
          value: _formatMobileNumber(statusResponse!.mobileNo),
          valueColor: Colors.grey[700],
        ),
      ],
    );
  }

  Widget _buildErrorContent() {
    return Column(
      children: [
        Icon(
          Icons.error_outline,
          color: Colors.red[400],
          size: 48,
        ),
        const SizedBox(height: 8),
        Text(
          error ?? statusResponse?.message ?? 'Failed to load recharge status',
          style: TextStyle(
            color: Colors.red[700],
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildNoDataContent() {
    return Column(
      children: [
        Icon(
          Icons.info_outline,
          color: Colors.orange[400],
          size: 48,
        ),
        const SizedBox(height: 8),
        Text(
          'No recharge data available',
          style: TextStyle(
            color: Colors.orange[700],
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmptyContent() {
    return Column(
      children: [
        Icon(
          Icons.search,
          color: Colors.grey[400],
          size: 48,
        ),
        const SizedBox(height: 8),
        Text(
          'Tap to check last recharge',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.blue[600],
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  String _formatMobileNumber(String mobileNumber) {
    if (mobileNumber.length >= 10) {
      return '${mobileNumber.substring(0, 5)}*****';
    }
    return mobileNumber;
  }
}

class RechargeExpiryCard extends StatelessWidget {
  final RechargeExpiryResponse? expiryResponse;
  final bool isLoading;
  final String? error;

  const RechargeExpiryCard({
    Key? key,
    this.expiryResponse,
    this.isLoading = false,
    this.error,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.green[50]!, Colors.green[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: Colors.green[700],
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recharge Expiry',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (error != null)
              _buildErrorContent()
            else if (expiryResponse != null)
              _buildExpiryContent()
            else
              _buildEmptyContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiryContent() {
    if (!expiryResponse!.isSuccess) {
      return _buildErrorContent();
    }

    if (!expiryResponse!.hasExpiryData) {
      return _buildNoDataContent();
    }

    final dateFormatter = DateFormat('dd MMM yyyy');
    final outgoingDate = expiryResponse!.outgoingDate;
    final incomingDate = expiryResponse!.incomingDate;

    return Column(
      children: [
        _buildInfoRow(
          icon: Icons.call_made,
          label: 'Outgoing Expiry',
          value: outgoingDate != null 
              ? dateFormatter.format(outgoingDate)
              : expiryResponse!.outgoing ?? 'N/A',
          valueColor: _getExpiryColor(outgoingDate),
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          icon: Icons.call_received,
          label: 'Incoming Expiry',
          value: incomingDate != null 
              ? dateFormatter.format(incomingDate)
              : expiryResponse!.incoming ?? 'N/A',
          valueColor: _getExpiryColor(incomingDate),
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          icon: Icons.phone,
          label: 'Mobile Number',
          value: _formatMobileNumber(expiryResponse!.mobileNo),
          valueColor: Colors.grey[700],
        ),
      ],
    );
  }

  Color? _getExpiryColor(DateTime? expiryDate) {
    if (expiryDate == null) return Colors.grey[700];
    
    final now = DateTime.now();
    final difference = expiryDate.difference(now).inDays;
    
    if (difference < 0) {
      return Colors.red[700]; // Expired
    } else if (difference <= 7) {
      return Colors.orange[700]; // Expiring soon
    } else {
      return Colors.green[700]; // Valid
    }
  }

  Widget _buildErrorContent() {
    return Column(
      children: [
        Icon(
          Icons.error_outline,
          color: Colors.red[400],
          size: 48,
        ),
        const SizedBox(height: 8),
        Text(
          error ?? expiryResponse?.message ?? 'Failed to load expiry information',
          style: TextStyle(
            color: Colors.red[700],
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildNoDataContent() {
    return Column(
      children: [
        Icon(
          Icons.info_outline,
          color: Colors.orange[400],
          size: 48,
        ),
        const SizedBox(height: 8),
        Text(
          'No expiry data available',
          style: TextStyle(
            color: Colors.orange[700],
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmptyContent() {
    return Column(
      children: [
        Icon(
          Icons.search,
          color: Colors.grey[400],
          size: 48,
        ),
        const SizedBox(height: 8),
        Text(
          'Tap to check recharge expiry',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.green[600],
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  String _formatMobileNumber(String mobileNumber) {
    if (mobileNumber.length >= 10) {
      return '${mobileNumber.substring(0, 5)}*****';
    }
    return mobileNumber;
  }
} 