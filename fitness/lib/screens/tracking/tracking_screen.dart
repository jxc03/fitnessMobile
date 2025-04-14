import 'package:flutter/material.dart';
import 'workout_history_screen.dart';
import 'workout_progress_screen.dart';

/// A screen that provides access to workout tracking features and progress analytics
/// This widget serves as a dashboard for users to:
/// View summary metrics of their recent workout activities
/// Access their complete workout history
/// iew detailed progress analytics and visualisations
/// See recent trends and insights about their fitness journey
class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Access theme properties for consistent styling throughout the screen
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Tracking'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section with gradient background and descriptive text
            Container(
              width: double.infinity,
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
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main heading with prominent display
                  const Text(
                    'Track Your Progress',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Subheading providing context for the screen's purpose
                  const Text(
                    'View your workout history and analyse your fitness journey',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            
            // Summary metrics cards - quick view of key performance indicators
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildMetricsSummary(context),
            ),
            
            // Section title for tracking options
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: _buildSectionHeader(context, 'Tracking Options'),
            ),
            
            // Navigation cards to access detailed tracking features
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Workout History Card - leads to past workout details
                  _buildTrackingCard(
                    context,
                    title: 'Workout History',
                    description: 'View all your completed workouts with details',
                    icon: Icons.history,
                    iconColor: theme.primaryColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WorkoutHistoryScreen(),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Progress Analytics Card - leads to charts and detailed metrics
                  _buildTrackingCard(
                    context,
                    title: 'Progress Analytics',
                    description: 'Track your improvements with detailed charts',
                    icon: Icons.show_chart,
                    iconColor: colorScheme.tertiary,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WorkoutProgressScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Progress insights section showing recent trends and achievements
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: _buildSectionHeader(context, 'Recent Trends'),
            ),
            
            // Card containing insights and progress indicators
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildInsightsCard(context),
            ),
            
            const SizedBox(height: 32), // Bottom padding for scroll area
          ],
        ),
      ),
    );
  }
  
  /// Builds a section header with text and a divider line
  /// Creates a consistent visual separation between different
  /// sections of the tracking screen
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3), // 30% opacity
            thickness: 1,
          ),
        ),
      ],
    );
  }
  
  /// Builds the metrics summary section with key performance indicators.
  /// Displays two cards showing:
  /// Total workouts completed this month
  /// Current streak of consecutive workout days
  Widget _buildMetricsSummary(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Row(
      children: [
        // Workouts completed this month
        Expanded(
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.2), // 20% opacity
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Icon indicator for workout type
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.1), // 10% opacity
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.fitness_center,
                          size: 18,
                          color: theme.primaryColor,
                        ),
                      ),
                      const Spacer(),
                      // Time period label
                      Text(
                        'This month',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.6), // 60% opacity
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Metric value with prominent display
                  const Text(
                    '12', // Number of workouts
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Metric label
                  Text(
                    'Workouts',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.7), // 70% opacity
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Current workout streak card
        Expanded(
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.2), // 20% opacity
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Flame icon for streak indicator
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.tertiary.withValues(alpha: 0.1), // 10% opacity
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.local_fire_department,
                          size: 18,
                          color: colorScheme.tertiary,
                        ),
                      ),
                      const Spacer(),
                      // Current status label
                      Text(
                        'Current',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.6), // 60% opacity
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Streak count with prominent display
                  const Text(
                    '5', // Number of days
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Streak label
                  Text(
                    'Day streak',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.7), // 70% opacity
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  /// Card for accessing tracking features.
  Widget _buildTrackingCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.2), // 20% opacity
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap, // Navigate to relevant screen when tapped
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Feature icon with colour-coded background
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1), // 10% opacity
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 16),
              // Feature name and description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface.withValues(alpha: 0.7), // 70% opacity
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow indicator showing it's a navigation element
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: colorScheme.onSurface.withValues(alpha: 0.5), // 50% opacity
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Builds a card displaying recent progress insights and trends
  /// Shows automatically generated insights about the user's
  /// workout progress and performance improvements
  Widget _buildInsightsCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.2), // 20% opacity
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card header with icon and title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0), // 10% opacity
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.insights,
                    size: 18,
                    color: theme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Your progress insights',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Individual insight items - each representing a different metric
            _buildInsightItem(
              context,
              icon: Icons.arrow_upward,
              color: colorScheme.tertiary,
              text: 'Bench press strength increased by 10% this month',
            ),
            const SizedBox(height: 12),
            _buildInsightItem(
              context,
              icon: Icons.timer,
              color: theme.primaryColor,
              text: 'Workout frequency improved by 2 days per week',
            ),
            const SizedBox(height: 12),
            _buildInsightItem(
              context,
              icon: Icons.trending_up,
              color: Colors.orange,
              text: 'Squat consistency has improved in the last 14 days',
            ),
            const SizedBox(height: 8),
            // "View all" link to navigate to detailed analytics
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WorkoutProgressScreen(),
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View all insights',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: theme.primaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Builds an individual insight item with icon and text.
  /// 
  /// Creates a consistently styled item representing a single
  /// insight about the user's fitness progress.
  /// 
  /// Parameters:
  /// - context: The build context
  /// - icon: Icon representing the type of insight
  /// - color: Colour for the icon that indicates the nature of the insight
  /// - text: The insight description text
  Widget _buildInsightItem(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Coloured icon indicating insight type (improvement, decline, etc.)
        Container(
          padding: const EdgeInsets.all(6),
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3), // 10% opacity
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 14,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        // Insight text description
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), // 80% opacity
            ),
          ),
        ),
      ],
    );
  }
}