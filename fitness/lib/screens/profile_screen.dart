import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness/services/authentication_service.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import '../screens/authentication/welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = _authService.currentUser;
      
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        
        if (doc.exists) {
          setState(() {
            _userData = doc.data();
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _signOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    ) ?? false;
    
    if (shouldSignOut) {
      try {
        await _authService.signOut();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const WelcomeScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error signing out: $e')),
          );
        }
      }
    }
  }
  
  Future<void> _deleteAccount() async {
    final TextEditingController passwordController = TextEditingController();
    
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This action cannot be undone. All your data will be permanently deleted.',
              style: TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            const Text('Please enter your password to confirm:'),
            const SizedBox(height: 8),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Password',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
    
    if (shouldDelete) {
      try {
        await _authService.deleteAccount(passwordController.text);
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const WelcomeScreen()),
            (route) => false,
          );
        }
      } on FirebaseAuthException catch (e) {
        String message = 'An error occurred';
        if (e.code == 'wrong-password') {
          message = 'Incorrect password';
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting account: $e')),
          );
        }
      }
    }
    
    passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userData == null
              ? const Center(child: Text('No user data found'))
              : _buildProfileContent(),
    );
  }
  
  Widget _buildProfileContent() {
    final profile = _userData!['profile'] as Map<String, dynamic>?;
    final settings = _userData!['settings'] as Map<String, dynamic>?;
    
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Profile header
        Center(
          child: Column(
            children: [
              // Profile image
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue.shade100,
                backgroundImage: _userData!['photoURL'] != null
                    ? NetworkImage(_userData!['photoURL'])
                    : null,
                child: _userData!['photoURL'] == null
                    ? Text(
                        _getInitials(_userData!['displayName'] ?? ''),
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      )
                    : null,
              ),
              
              const SizedBox(height: 16),
              
              // Name
              Text(
                _userData!['displayName'] ?? 'User',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              // Email
              Text(
                _userData!['email'] ?? '',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Edit profile button
              ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfileScreen(userData: _userData!),
                    ),
                  );
                  
                  if (result == true) {
                    _loadUserData();
                  }
                },
                child: const Text('Edit Profile'),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        const Divider(),
        
        // Personal information section
        _buildSectionHeader('Personal Information'),
        
        _buildInfoItem(
          'Fitness Level',
          profile?['fitnessLevel'] ?? 'Not set',
          Icons.fitness_center,
        ),
        
        _buildInfoItem(
          'Height',
          profile?['height'] != null ? '${profile!['height']} cm' : 'Not set',
          Icons.height,
        ),
        
        _buildInfoItem(
          'Weight',
          profile?['weight'] != null ? '${profile!['weight']} kg' : 'Not set',
          Icons.monitor_weight,
        ),
        
        // Fitness goals section
        _buildSectionHeader('Fitness Goals'),
        
        if (profile?['fitnessGoals'] is List && (profile!['fitnessGoals'] as List).isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (profile['fitnessGoals'] as List).map((goal) {
              return Chip(
                label: Text(goal.toString()),
                backgroundColor: Colors.blue.shade100,
              );
            }).toList(),
          )
        else
          const Text('No fitness goals set'),
        
        const SizedBox(height: 16),
        const Divider(),
        
        // Settings section
        _buildSectionHeader('Settings'),
        
        SwitchListTile(
          title: const Text('Notifications'),
          value: settings?['notifications'] ?? false,
          onChanged: (value) async {
            try {
              await _authService.updateUserSettings({'notifications': value});
              _loadUserData();
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating setting: $e')),
                );
              }
            }
          },
        ),
        
        ListTile(
          title: const Text('Units'),
          subtitle: Text(settings?['unitSystem'] == 'imperial' ? 'Imperial (lb, ft)' : 'Metric (kg, cm)'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _showUnitSystemPicker();
          },
        ),
        
        ListTile(
          title: const Text('Change Password'),
          leading: const Icon(Icons.lock_outline),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ChangePasswordScreen(),
              ),
            );
          },
        ),
        
        const SizedBox(height: 16),
        const Divider(),
        
        // Danger zone
        _buildSectionHeader('Danger Zone', color: Colors.red),
        
        ListTile(
          title: const Text(
            'Delete Account',
            style: TextStyle(color: Colors.red),
          ),
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          onTap: _deleteAccount,
        ),
        
        const SizedBox(height: 32),
      ],
    );
  }
  
  Widget _buildSectionHeader(String title, {Color color = Colors.black}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
  
  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  void _showUnitSystemPicker() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Unit System'),
        children: [
          SimpleDialogOption(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _authService.updateUserSettings({'unitSystem': 'metric'});
                _loadUserData();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating unit system: $e')),
                  );
                }
              }
            },
            child: const Text('Metric (kg, cm)'),
          ),
          SimpleDialogOption(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _authService.updateUserSettings({'unitSystem': 'imperial'});
                _loadUserData();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating unit system: $e')),
                  );
                }
              }
            },
            child: const Text('Imperial (lb, ft)'),
          ),
        ],
      ),
    );
  }
  
  String _getInitials(String fullName) {
    List<String> names = fullName.split(' ');
    String initials = '';
    
    for (var name in names) {
      if (name.isNotEmpty) {
        initials += name[0];
      }
    }
    
    return initials.toUpperCase();
  }
}