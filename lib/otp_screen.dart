import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class OtpScreen extends StatefulWidget {
  final String mobileNumber;

  const OtpScreen({super.key, required this.mobileNumber});

  @override
  // ignore: library_private_types_in_public_api
  _OtpScreenState createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();

  Future<void> _verifyOtp() async {
    final otp = _otpController.text;

    if (otp.length != 6 || !RegExp(r'^\d+$').hasMatch(otp)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('کد تایید باید ۶ رقم باشد')),
        );
      }
      return;
    }

    // Make a POST request to the OTP verification API
    final url = Uri.parse('http://localhost:8100/v1/otp/verify/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mobile': widget.mobileNumber,
          'otp': otp,
        }),
      );

      if (response.statusCode == 200) {
        // On success, store the access token
        final responseData = jsonDecode(response.body);
        final accessToken = responseData['access_token'];
        final refreshToken = responseData['refresh_token'];

        if (accessToken != null) {
          // Save the access token to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', accessToken);
          await prefs.setString('refresh_token', refreshToken);

          if (mounted) {
            // Navigate to Home screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        } else {
          // Handle missing token in the response
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('دریافت توکن ناموفق بود')),
            );
          }
        }
      } else {
        if (mounted) {
          // Show error message if OTP verification failed
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('کد تایید اشتباه است.')),
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
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('وارد کردن کد تایید'),
      ),
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Instructional text above OTP input
              const Text(
                'لطفاً کد تایید ارسال شده به شماره موبایل خود را وارد کنید',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16), // Add some spacing

              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'کد تایید',
                  border: OutlineInputBorder(),
                  hintText: '123456',
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
                  onPressed: _verifyOtp,
                  child: const Text(
                    'تایید کد',
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
