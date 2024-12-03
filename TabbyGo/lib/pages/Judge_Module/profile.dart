import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Settings'),
        backgroundColor: const Color(0xFF6A5AE0), // Match your theme color
        automaticallyImplyLeading: false, // Removes the back button
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // User Profile Section
            _buildProfileSection(),
            const SizedBox(height: 24),
            // Settings Options
            _buildSettingsOptions(),
            const SizedBox(height: 24),
            // Logout Button
            _buildLogoutButton(context),
          ],
        ),
      ),
    );
  }

  // Method to build the profile section
  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: const AssetImage(
                'assets/images/text logo black.png'), // Replace with user profile image
            backgroundColor: Colors.grey[200],
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'User Name', // Replace with dynamic user name
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'user.email@example.com', // Replace with dynamic user email
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Method to build the settings options
  Widget _buildSettingsOptions() {
    return Column(
      children: [
        _buildSettingItem(
          title: 'Change Password',
          onTap: () {
            // Handle change password action
          },
        ),
        _buildSettingItem(
          title: 'Update Email',
          onTap: () {
            // Handle update email action
          },
        ),
        _buildSettingItem(
          title: 'Manage Notifications',
          onTap: () {
            // Handle manage notifications action
          },
        ),
      ],
    );
  }

  // Method to build individual setting item
  Widget _buildSettingItem(
      {required String title, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0xFF6A5AE0),
            ),
          ],
        ),
      ),
    );
  }

  // Method to build the logout button
  Widget _buildLogoutButton(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          // Handle logout action
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6A5AE0), // Match your theme color
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'Logout',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
