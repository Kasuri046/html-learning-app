import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(100),
        child: AppBar(
          backgroundColor: Color(0xff023047),
          elevation: 0, // Keeps the flat look
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context), // Back navigation
          ),
          title: Padding(
            padding: const EdgeInsets.only(top: 0), // Adjusted padding for title
            child: const Text(
              'About',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          centerTitle: true,
        ),
      ),
      body: Stack(
        children: [
          Container(
            height: 50,
            color: Color(0xff023047),
          ),
          Container(
            margin: const EdgeInsets.only(top: 10,), // Adjusted margins
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30), // Rounded corners
            ),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                // Wrapping the entire content in a container with a light teal background
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1), // Light teal background
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: _buildPrivacyPolicyContent(),
                ),
                const SizedBox(height: 20), // Added spacing before button
                ElevatedButton(
                  onPressed: () {
                    // Action when user agrees to privacy policy
                    Navigator.pop(context); // Go back on button press
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:Color(0xff023047),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text(
                    'I Agree',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
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

  Widget _buildPrivacyPolicyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Introduction\n',
          style: const TextStyle(
            fontSize: 16,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We value your privacy and are committed to protecting your personal data. This privacy policy explains how we collect, use, and share information about you.\n',
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Poppins',
            color: Colors.black54,
            height: 1.5, // Increased line height to add space between lines
          ),
        ),
        const SizedBox(height: 20), // Spacing between sections

        Text(
          'Information We Collect\n',
          style: const TextStyle(
            fontSize: 16,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We collect various types of information, including:\n'
              '• Personal information you provide (e.g., name, email address, etc.)\n'
              '• Usage data (e.g., your interaction with our app)\n'
              '• Cookies and tracking technologies to enhance your experience.\n',
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Poppins',
            color: Colors.black54,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'How We Use Your Information\n',
          style: const TextStyle(
            fontSize: 16,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We use the information we gather for the following purposes:\n'
              '• To provide and improve our services.\n'
              '• To communicate with you about your account and provide customer support.\n'
              '• To protect our users and our services.\n'
              '• To gather analytics and understand user behavior to enhance our offerings.\n',
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Poppins',
            color: Colors.black54,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'Sharing Your Information\n',
          style: const TextStyle(
            fontSize: 16,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We do not sell or rent your personal data to third parties. However, we may share your data in the following situations:\n'
              '• With service providers to assist us in offering our services.\n'
              '• When required by law or to protect our rights and the rights of others.\n',
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Poppins',
            color: Colors.black54,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'Your Rights\n',
          style: const TextStyle(
            fontSize: 16,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'You have the right to:\n'
              '• Request access to the personal data we hold about you.\n'
              '• Rectify any inaccuracies in your information.\n'
              '• Request deletion of your information, subject to certain conditions.\n'
              '• Withdraw your consent at any time for processing your data, where applicable.\n',
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Poppins',
            color: Colors.black54,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'How We Protect Your Information\n',
          style: const TextStyle(
            fontSize: 16,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We take reasonable measures to protect your personal information from unauthorized access, use, or disclosure. This includes:\n'
              '• Implementing security protocols and encryption to protect data.\n'
              '• Regularly reviewing our security practices and policies.\n',
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Poppins',
            color: Colors.black54,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'Changes to This Policy\n',
          style: const TextStyle(
            fontSize: 16,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We may update our privacy policy from time to time. We will notify you of any changes by:\n'
              '• Posting the new policy on this page.\n'
              '• Updating the effective date at the top of this policy.\n',
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Poppins',
            color: Colors.black54,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'Contact Us\n',
          style: const TextStyle(
            fontSize: 16,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'If you have any questions or concerns about this privacy policy or your personal information, please contact us at:\n'
              '• Email: support@example.com\n'
              '• Phone: 123-456-7890\n',
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Poppins',
            color: Colors.black54,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}