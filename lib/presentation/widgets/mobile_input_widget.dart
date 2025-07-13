import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MobileInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;
  final String? errorText;
  final bool isLoading;

  const MobileInputWidget({
    Key? key,
    required this.controller,
    required this.onChanged,
    this.errorText,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mobile Number',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          enabled: !isLoading,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(
            hintText: 'Enter 10 digit mobile number',
            prefixIcon: const Icon(Icons.phone_android),
            suffixIcon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : null,
            errorText: errorText,
            border: const OutlineInputBorder(),
            counterText: '',
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
} 