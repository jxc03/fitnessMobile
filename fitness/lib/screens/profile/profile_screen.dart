import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness/services/authentication_service.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import '../authentication/welcome_screen.dart';
import 'dart:developer';

/// Displays the user's profile information and settings
/// This widget fetches user data from Firestore and allows users to:
/// View their profile information (name, email, fitness stats)
/// Edit their profile information
/// Manage app settings (notifications, unit system)
/// Change their password
/// Delete their account
/// Sign out from the application
class ProfileScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  
  const ProfileScreen({super.key, this.onNavigate});

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
    _loadUserData(); // Load user data when the screen initialises
  }
  
  /// Fetches the current user's data from Firestore
  /// This method retrieves the user document from the 'users' collection
  /// based on the current authenticated user's ID and updates the state
  /// with the fetched data
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get the current authenticated user
      final user = _authService.currentUser;
      
      if (user != null) {
        // Fetch the user document from Firestore
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        
        if (doc.exists) {
          // Update state with the user data if document exists
          setState(() {
            _userData = doc.data();
            _isLoading = false;
          });
        } else {
          // User document doesn't exist in Firestore
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        // No authenticated user
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      // Log errors for debugging
      log('Error loading user data: $e', name: 'ProfileScreen');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  /// Shows a confirmation dialog and signs out the user if confirmed
  /// This method displays a dialog asking the user to confirm their intention
  /// to sign out. If confirmed, it signs out the user and navigates to the
  /// welcome screen
  Future<void> _signOut() async {
    // Show confirmation dialog
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Sign Out',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: const Text('Are you sure you want to sign out?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1),
        ),
        backgroundColor: Colors.white,
        actions: [
          // Cancel button
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          // Sign out button
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    ) ?? false; // Default to false if dialog is dismissed
    
    // Proceed with sign out if confirmed
    if (shouldSignOut) {
      try {
        await _authService.signOut();
        if (mounted) {
          // Navigate to welcome screen and remove all previous routes
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const WelcomeScreen()),
            (route) => false, // Remove all previous routes
          );
        }
      } catch (e) {
        // Show error message if sign out fails
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error signing out: $e'),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    }
  }
  
  /// Shows a confirmation dialog and deletes the user's account if confirmed
  /// This method displays a dialog asking the user to confirm their intention
  /// to delete their account by entering their password. If confirmed and the
  /// password is correct, it deletes the account and navigates to the welcome screen
  Future<void> _deleteAccount() async {
    final TextEditingController passwordController = TextEditingController();
    
    // Show confirmation dialog with password verification
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Account',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1),
        ),
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning message
            const Text(
              'This action cannot be undone. All your data will be permanently deleted.',
              style: TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            // Password verification
            const Text('Please enter your password to confirm:'),
            const SizedBox(height: 8),
            TextField(
              controller: passwordController,
              obscureText: true, // Hide password text
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                labelText: 'Password',
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Cancel button
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          // Delete button
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false; // Default to false if dialog is dismissed
    
    // Proceed with account deletion if confirmed
    if (shouldDelete) {
      try {
        // Attempt to delete the account with the provided password
        await _authService.deleteAccount(passwordController.text);
        if (mounted) {
          // Navigate to welcome screen and remove all previous routes
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const WelcomeScreen()),
            (route) => false, // Remove all previous routes
          );
        }
      } on FirebaseAuthException catch (e) {
        // Handle specific Firebase Auth errors
        String message = 'An error occurred';
        if (e.code == 'wrong-password') {
          message = 'Incorrect password';
        }
        
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } catch (e) {
        // Handle generic errors
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting account: $e'),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    }
    
    // Clean up the controller to prevent memory leaks
    passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access theme properties for consistent styling
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          // Sign out button in app bar
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
              ),
            )
          : _userData == null
              ? Center(
                  child: Text(
                    'No user data found',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                )
              : _buildProfileContent(context), // Main profile content when data is loaded
    );
  }
  
  /// Builds the main profile content with all sections
  /// This method creates a scrollable list view containing:
  /// Profile header with user image and name
  /// Stats summary
  /// Personal information section
  /// Fitness goals section
  /// Settings section
  /// Danger zone section for account deletion
  Widget _buildProfileContent(BuildContext context) {
    // Access theme properties for consistent styling
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Extract profile and settings data from user data
    final profile = _userData!['profile'] as Map<String, dynamic>?;
    final settings = _userData!['settings'] as Map<String, dynamic>?;
    
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Profile header with gradient background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.primaryColor,
                theme.primaryColor.withValues(alpha: 0.8), // 80% opacity
              ],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 24, left: 24, right: 24),
              child: Column(
                children: [
                  // Profile image or initials
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1), // 10% opacity shadow
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      backgroundImage: _userData!['photoURL'] != null
                          ? NetworkImage(_userData!['photoURL'])
                          : null,
                      child: _userData!['photoURL'] == null
                          ? Text(
                              _getInitials(_userData!['displayName'] ?? ''),
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColor,
                              ),
                            )
                          : null,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Display name
                  Text(
                    _userData!['displayName'] ?? 'User',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  
                  // Email address
                  Text(
                    _userData!['email'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Edit profile button
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfileScreen(userData: _userData!),
                        ),
                      );
                      
                      // Refresh user data if profile was updated
                      if (result == true) {
                        _loadUserData();
                      }
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: theme.primaryColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Stats summary card (workouts, streak, completion)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildStatItem(context, '12', 'Workouts'),
                  _buildVerticalDivider(),
                  _buildStatItem(context, '5', 'Days Streak'),
                  _buildVerticalDivider(),
                  _buildStatItem(context, '87%', 'Completion'),
                ],
              ),
            ),
          ),
        ),
        
        // Personal information section
        _buildSectionHeader(context, 'Personal Information'),
        
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Fitness level info item
              _buildInfoItem(
                context,
                'Fitness Level',
                profile?['fitnessLevel']  != null
                ? (profile!['fitnessLevel'] as String).capitalize() // Capitalize first letter
                : 'Not set',
                Icons.fitness_center,
                colorScheme.secondary,
              ),
              
              Divider(color: colorScheme.outline.withValues(alpha: 0.5), height: 1), // 50% opacity divider
              
              // Height info item
              _buildInfoItem(
                context,
                'Height',
                profile?['height'] != null ? '${profile!['height']} cm' : 'Not set',
                Icons.height,
                theme.primaryColor,
              ),
              
              Divider(color: colorScheme.outline.withValues(alpha: 0.5), height: 1), // 50% opacity divider
              
              // Weight info item
              _buildInfoItem(
                context,
                'Weight',
                profile?['weight'] != null ? '${profile!['weight']} kg' : 'Not set',
                Icons.monitor_weight,
                colorScheme.tertiary,
              ),
            ],
          ),
        ),
        
        // Fitness goals section
        _buildSectionHeader(context, 'Fitness Goals'),
        
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: profile?['fitnessGoals'] is List && (profile!['fitnessGoals'] as List).isNotEmpty
                ? Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (profile['fitnessGoals'] as List).map((goal) {
                      // Create a chip for each fitness goal
                      return Chip(
                        label: Text(
                          goal.toString(),
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        backgroundColor: theme.primaryColor.withValues(alpha: 0.1), // 10% opacity background
                        side: BorderSide(
                          color: theme.primaryColor.withValues(alpha: 0.3), // 30% opacity border
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      );
                    }).toList(),
                  )
                : Text(
                    'No fitness goals set',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.7), // 70% opacity text
                    ),
                  ),
          ),
        ),
        
        // Settings section
        _buildSectionHeader(context, 'Settings'),
                
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Notifications toggle
              SwitchListTile(
                title: Text(
                  'Notifications',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: const Text(
                  'Receive workout reminders and updates',
                  style: TextStyle(fontSize: 13),
                ),
                value: settings?['notifications'] ?? false, // Default to false if not set
                onChanged: (value) async {
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  try {
                    // Update notification setting in Firestore
                    await _authService.updateUserSettings({'notifications': value});
                    _loadUserData(); // Refresh user data
                  } catch (e) {
                    // Show error message if update fails
                    if (mounted) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text('Error updating setting: $e'),
                          backgroundColor: Colors.red.shade700,
                        ),
                      );
                    }
                  }
                },
                activeColor: theme.primaryColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              
              Divider(color: colorScheme.outline.withValues(alpha: 0.5), height: 1), // 50% opacity divider
              
              // Unit system selector
              ListTile(
                title: Text(
                  'Units',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  settings?['unitSystem'] == 'imperial' 
                      ? 'Imperial (lb, ft)' 
                      : 'Metric (kg, cm)',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.7), // 70% opacity
                    fontSize: 13,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right, 
                  color: colorScheme.onSurface.withValues(alpha: 0.7), // 70% opacity
                ),
                onTap: () {
                  _showUnitSystemPicker(context);
                },
                leading: Icon(
                  Icons.straighten, 
                  color: theme.primaryColor,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              
              Divider(color: colorScheme.outline.withValues(alpha: 0.5), height: 1), // 50% opacity divider
              
              // Change password option
              ListTile(
                title: Text(
                  'Change Password',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: const Text(
                  'Update your account password',
                  style: TextStyle(fontSize: 13),
                ),
                leading: Icon(
                  Icons.lock_outline, 
                  color: theme.primaryColor,
                ),
                trailing: Icon(
                  Icons.chevron_right, 
                  color: colorScheme.onSurface.withValues(alpha: 0.7), // 70% opacity
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChangePasswordScreen(),
                    ),
                  );
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ],
          ),
        ),
        
        // Danger zone section with red styling
        _buildSectionHeader(context, 'Danger Zone', color: Colors.red.shade700),
        
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.red.shade200, width: 1),
          ),
          color: Colors.red.shade50, // Light red background for warning
          child: ListTile(
            title: const Text(
              'Delete Account',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: const Text(
              'Permanently remove your account and data',
              style: TextStyle(
                color: Colors.red,
                fontSize: 13,
              ),
            ),
            leading: const Icon(
              Icons.delete_forever, 
              color: Colors.red,
            ),
            onTap: _deleteAccount,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
        
        const SizedBox(height: 32), // Bottom padding
      ],
    );
  }
  /// Sction header with an optional custom colour
  /// Creates a header with a title and a divider line for visually
  /// separating different sections of the profile screen
  Widget _buildSectionHeader(BuildContext context, String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 12),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              color: color?.withValues(alpha: 0.3) ?? Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Builds an information item with an icon, label, and value
  /// Used for displaying personal information items like fitness level,
  Widget _buildInfoItem(
    BuildContext context, 
    String label, 
    String value, 
    IconData icon,
    Color iconColor,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          // Circular icon background
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1), // 10% opacity background
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon, 
              color: iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          // Label and value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.7), // 70% opacity
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Statistics item with a value and label
  /// Used in the stats summary row to display workout statistics
  Widget _buildStatItem(BuildContext context, String value, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Expanded(
      child: Column(
        children: [
          // Statistic value
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          // Statistic label
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface.withValues(alpha: 0.7), // 70% opacity
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  /// Vertical divider for separating statistics items
  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3), // 30% opacity
    );
  }

  /// Shows a dialog for selecting the unit system (metric or imperial).
  /// Allows the user to choose between metric (kg, cm) and imperial (lb, ft)
  void _showUnitSystemPicker(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Select Unit System',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outline, width: 1),
        ),
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Metric (kg, cm)'),
              leading: Radio<String>(
                value: 'metric',
                groupValue: (_userData?['settings'] as Map<String, dynamic>?)?['unitSystem'] ?? 'metric',
                onChanged: (value) async {
                  Navigator.pop(dialogContext);
                  try {
                    await _authService.updateUserSettings({'unitSystem': 'metric'});
                    _loadUserData();
                  } catch (e) {
                    if (mounted) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text('Error updating unit system: $e'),
                          backgroundColor: Colors.red.shade700,
                        ),
                      );
                    }
                  }
                },
                activeColor: theme.primaryColor,
              ),
            ),
            ListTile(
              title: const Text('Imperial (lb, ft)'),
              leading: Radio<String>(
                value: 'imperial',
                groupValue: (_userData?['settings'] as Map<String, dynamic>?)?['unitSystem'] ?? 'metric',
                onChanged: (value) async {
                  Navigator.pop(dialogContext);
                  try {
                    await _authService.updateUserSettings({'unitSystem': 'imperial'});
                    _loadUserData();
                  } catch (e) {
                    if (mounted) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text('Error updating unit system: $e'),
                          backgroundColor: Colors.red.shade700,
                        ),
                      );
                    }
                  }
                },
                activeColor: theme.primaryColor,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: theme.primaryColor,
              ),
            ),
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

