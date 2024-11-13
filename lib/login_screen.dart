import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _mobileController = TextEditingController();

  Future<void> _requestOTP() async {
    final mobileNumber = _mobileController.text;

    // Validate mobile number format
    if (mobileNumber.length != 11 || !RegExp(r'^\d+$').hasMatch(mobileNumber)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('شماره موبایل باید ۱۱ رقم باشد')),
        );
      }
      return;
    }

    // Make a POST request to the OTP request API
    final url = Uri.parse('http://localhost:8100/v1/otp/request/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile': mobileNumber}),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          // On success, navigate to OTP screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpScreen(mobileNumber: mobileNumber),
            ),
          );
        }
      } else {
        if (mounted) {
          // Show error message if OTP request failed
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('خطا در ارسال کد تایید. لطفاً دوباره تلاش کنید.')),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        // Catch network-related errors
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'مشکلی در ارتباط با سرور وجود دارد. لطفاً اتصال اینترنت خود را بررسی کنید.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ورود'),
      ),
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Project logo
              Image.asset(
                'logo.png', // Ensure logo path is correct
                width: 200,
                height: 200,
              ),
              const SizedBox(height: 40), // Space between logo and text

              // Instructional text above the mobile input
              Text(
                'لطفاً شماره موبایل خود را وارد کنید تا کد تایید برای شما ارسال شود',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16), // Add some spacing

              TextField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'شماره موبایل',
                  border: OutlineInputBorder(),
                  hintText: '09123456789',
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _requestOTP,
                  child: const Text(
                    'ارسال کد تایید',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
