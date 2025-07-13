import 'package:flutter/material.dart';
import '../../data/models/operator_info.dart';

class OperatorDisplayCard extends StatelessWidget {
  final OperatorInfo operatorInfo;

  const OperatorDisplayCard({
    Key? key,
    required this.operatorInfo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              context,
              'Operator',
              operatorInfo.operator,
              Icons.business,
            ),
            const Divider(),
            _buildInfoRow(
              context,
              'Circle',
              operatorInfo.circle,
              Icons.location_on,
            ),
            const Divider(),
            _buildInfoRow(
              context,
              'Mobile',
              operatorInfo.mobile,
              Icons.phone_android,
            ),
            if (operatorInfo.message.isNotEmpty) ...[
              const Divider(),
              _buildInfoRow(
                context,
                'Status',
                operatorInfo.message,
                Icons.info_outline,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 