import 'package:flutter/material.dart';
import '../../data/models/operator_info.dart';

class OperatorDisplayCard extends StatelessWidget {
  final OperatorInfo operatorInfo;
  final String? selectedCircle;
  final dynamic availableCircles;
  final Function(String?) onCircleChanged;

  const OperatorDisplayCard({
    super.key,
    required this.operatorInfo,
    required this.selectedCircle,
    required this.availableCircles,
    required this.onCircleChanged,
  });

  List<DropdownMenuItem<String>> _getCircleItems() {
    if (availableCircles is Map<String, String>) {
      return (availableCircles as Map<String, String>).entries.map((entry) {
        return DropdownMenuItem<String>(
          value: entry.value,
          child: Text(
            entry.key,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        );
      }).toList();
    } else if (availableCircles is List<String>) {
      return (availableCircles as List<String>).map((circle) {
        return DropdownMenuItem<String>(
          value: circle,
          child: Text(
            circle,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        );
      }).toList();
    } else {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF6C63FF).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Operator Detected',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Operator Info
          Row(
            children: [
              // Operator Logo
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getOperatorColor(operatorInfo.operator ?? 'UNKNOWN').withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getOperatorColor(operatorInfo.operator ?? 'UNKNOWN').withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    _getOperatorInitials(operatorInfo.operator ?? 'UNKNOWN'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getOperatorColor(operatorInfo.operator ?? 'UNKNOWN'),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Operator Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      operatorInfo.operator ?? 'Unknown Operator',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mobile: ${operatorInfo.mobile}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    if (operatorInfo.status == 'FALLBACK') ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Auto-detected',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Circle Selection
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Circle',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFFF8F9FA),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedCircle,
                    hint: const Text(
                      'Select your circle',
                      style: TextStyle(color: Colors.grey),
                    ),
                    isExpanded: true,
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Color(0xFF6C63FF),
                    ),
                    items: _getCircleItems(),
                    onChanged: onCircleChanged,
                  ),
                ),
              ),
              
              // Current detected circle info
              if (operatorInfo.circle != null && operatorInfo.circle!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Detected circle: ${operatorInfo.circle}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Plan Benefits Preview
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF6C63FF).withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.star,
                  color: Color(0xFF6C63FF),
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Get exclusive plans and offers for your operator',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6C63FF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getOperatorColor(String operator) {
    switch (operator.toUpperCase()) {
      case 'AIRTEL':
        return const Color(0xFFE60012);
      case 'VODAFONE':
      case 'VI':
        return const Color(0xFFE60000);
      case 'JIO':
        return const Color(0xFF0066CC);
      case 'IDEA':
        return const Color(0xFFFFD700);
      case 'BSNL':
        return const Color(0xFF008000);
      default:
        return const Color(0xFF6C63FF);
    }
  }

  String _getOperatorInitials(String operator) {
    switch (operator.toUpperCase()) {
      case 'AIRTEL':
        return 'AT';
      case 'VODAFONE':
      case 'VI':
        return 'VI';
      case 'JIO':
        return 'JIO';
      case 'IDEA':
        return 'ID';
      case 'BSNL':
        return 'BS';
      default:
        return operator.length >= 2 ? operator.substring(0, 2).toUpperCase() : operator;
    }
  }
} 