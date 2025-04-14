import 'package:flutter/material.dart'; // Import the core Flutter framework

/// A customisable filter dialog for exercise filtering and sorting
/// Allows users to sort exercises and filter by muscle groups and equipment
class FilterDialog extends StatefulWidget {
  final String selectedSortOption; // Currently selected sort option
  final List<String> selectedMuscleGroups; // Currently selected muscle groups
  final List<String> selectedEquipment; // Currently selected equipment
  final List<String> availableMuscleGroups; // Available muscle groups to choose from
  final List<String> availableEquipment; // Available equipment to choose from

  const FilterDialog({
    super.key,
    required this.selectedSortOption, // Required parameter for current sort option
    required this.selectedMuscleGroups, // Required parameter for selected muscle groups
    required this.selectedEquipment, // Required parameter for selected equipment
    required this.availableMuscleGroups, // Required parameter for available muscle groups
    required this.availableEquipment, // Required parameter for available equipment
  });

  @override
  State<FilterDialog> createState() => _FilterDialogState(); // Create the mutable state for this widget
}

class _FilterDialogState extends State<FilterDialog> {
  late String _sortOption; // Tracks the selected sort option
  late List<String> _selectedMuscleGroups; // Tracks selected muscle groups
  late List<String> _selectedEquipment; // Tracks selected equipment types

  // Colour palette 
  static const Color primaryColor = Color(0xFF2A6F97); 
  static const Color secondaryColor = Color(0xFF61A0AF); 
  static const Color accentGreen = Color(0xFF4C956C); 
  static const Color accentTeal = Color(0xFF2F6D80); 
  static const Color neutralDark = Color(0xFF3D5A6C); 
  static const Color neutralLight = Color(0xFFF5F7FA); 
  static const Color neutralMid = Color(0xFFE1E7ED); 

  @override
  void initState() {
    super.initState(); // Call parent initialisation first
    // Initialise state variables with copies of the widget parameters
    _sortOption = widget.selectedSortOption; // Copy the selected sort option
    _selectedMuscleGroups = List.from(widget.selectedMuscleGroups); // Create a copy of selected muscle groups
    _selectedEquipment = List.from(widget.selectedEquipment); // Create a copy of selected equipment
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // Rounded corners for the dialog
      ),
      elevation: 0, // No shadow on the dialog itself
      backgroundColor: Colors.transparent, // Transparent background outside the container
      child: Container(
        padding: const EdgeInsets.all(0), // No padding at container level
        decoration: BoxDecoration(
          color: Colors.white, // White background for the dialog content
          borderRadius: BorderRadius.circular(16), // Rounded corners matching the dialog
          border: Border.all(color: neutralMid, width: 1), // Subtle border around the dialog
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Take minimum required vertical space
          crossAxisAlignment: CrossAxisAlignment.start, // Align items to the left
          children: [
            // Header section with title and close button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), // Padding inside the header
              decoration: BoxDecoration(
                color: Colors.white, // White background for the header
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16), // Match the dialog's top-left corner
                  topRight: Radius.circular(16), // Match the dialog's top-right corner
                ),
                border: Border(
                  bottom: BorderSide(color: neutralMid, width: 1), // Bottom border to separate header
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between title and close button
                children: [
                  const Text(
                    'Filter Exercises', // Dialog title
                    style: TextStyle(
                      fontSize: 20, // Larger font for title
                      fontWeight: FontWeight.bold, // Bold title text
                      color: neutralDark, // Dark colour for better readability
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: neutralDark), // Close (X) icon
                    onPressed: () => Navigator.of(context).pop(), // Dismiss dialog when tapped
                    padding: EdgeInsets.zero, // Remove default padding
                    constraints: const BoxConstraints(), // Remove constraints for tighter layout
                  ),
                ],
              ),
            ),
            
            // Scrollable content area for filters
            Flexible(
              child: SingleChildScrollView( // Allows scrolling if content exceeds screen height
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20), // Horizontal padding for content
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // Align content to the left
                    children: [
                      const SizedBox(height: 20), // Spacing after header
                      
                      // Sort options section
                      _buildSectionHeader('Sort By', Icons.sort), // Section heading with icon
                      const SizedBox(height: 12), // Space after heading
                      _buildSortOptions(), // Radio buttons for sorting options
                      
                      const SizedBox(height: 16), // Spacing before divider
                      const Divider(color: neutralMid), // Visual separator between sections
                      const SizedBox(height: 16), // Spacing after divider
                      
                      // Muscle Groups filter section
                      _buildSectionHeader('Muscle Groups', Icons.accessibility_new), // Section heading with icon
                      const SizedBox(height: 12), // Space after heading
                      _buildMuscleGroupsFilter(), // Filter chips for muscle groups
                      
                      const SizedBox(height: 16), // Spacing before divider
                      const Divider(color: neutralMid), // Visual separator between sections
                      const SizedBox(height: 16), // Spacing after divider
                      
                      // Equipment filter section
                      _buildSectionHeader('Equipment', Icons.fitness_center), // Section heading with icon
                      const SizedBox(height: 12), // Space after heading
                      _buildEquipmentFilter(), // Filter chips for equipment
                      
                      const SizedBox(height: 20), // Bottom padding for scrollable content
                    ],
                  ),
                ),
              ),
            ),
            
            // Footer with action buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), // Padding inside footer
              decoration: BoxDecoration(
                color: Colors.white, // White background for footer
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16), // Match dialog's bottom-left corner
                  bottomRight: Radius.circular(16), // Match dialog's bottom-right corner
                ),
                border: Border(
                  top: BorderSide(color: neutralMid, width: 1), // Top border to separate footer
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between reset and apply buttons
                children: [
                  // Reset filters button
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _sortOption = 'Default'; // Reset to default sorting
                        _selectedMuscleGroups = []; // Clear all muscle group selections
                        _selectedEquipment = []; // Clear all equipment selections
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: primaryColor, // Blue text for reset button
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Button padding
                    ),
                    child: const Text(
                      'Reset Filters', // Reset button text
                      style: TextStyle(fontWeight: FontWeight.w600), // Semi bold text
                    ),
                  ),
                  // Apply filters button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop({
                        'sortOption': _sortOption, // Return selected sort option
                        'muscleGroups': _selectedMuscleGroups, // Return selected muscle groups
                        'equipment': _selectedEquipment, // Return selected equipment
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor, // Blue background for primary action
                      foregroundColor: Colors.white, // White text for contrast
                      elevation: 0, // No shadow for cleaner design
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), // Button padding
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // Slightly rounded corners
                      ),
                    ),
                    child: const Text(
                      'Apply Filters', // Apply button text
                      style: TextStyle(fontWeight: FontWeight.w600), // Semi bold text
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a section header with an icon and title
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: primaryColor), // Icon with primary colour
        const SizedBox(width: 8), // Space between icon and text
        Text(
          title, // Section title
          style: const TextStyle(
            fontSize: 18, // Slightly larger font for section titles
            fontWeight: FontWeight.bold, // Bold text for emphasis
            color: neutralDark, // Dark text for readability
          ),
        ),
      ],
    );
  }

  /// Builds the sort options radio buttons
  Widget _buildSortOptions() {
    return Column(
      children: [
        _buildSortRadioTile('Default', 'Default'), // Default sorting option
        _buildSortRadioTile('A to Z', 'A-Z'), // Alphabetical sorting option
        _buildSortRadioTile('Z to A', 'Z-A'), // Reverse alphabetical sorting option
      ],
    );
  }

  /// Builds a single radio button for sort options
  Widget _buildSortRadioTile(String title, String value) {
    return RadioListTile<String>(
      title: Text(
        title, // Display name for the option
        style: TextStyle(
          color: neutralDark, // Dark text for readability
          fontWeight: _sortOption == value ? FontWeight.w600 : FontWeight.normal, // Bold if selected
        ),
      ),
      value: value, // Value used in the code
      groupValue: _sortOption, // Currently selected value
      onChanged: (newValue) {
        setState(() {
          _sortOption = newValue!; // Update selected sort option
        });
      },
      activeColor: primaryColor, // Blue colour for selected radio button
      contentPadding: EdgeInsets.zero, // Remove default padding
      dense: true, // Compact layout
    );
  }

  /// Builds the muscle groups filter chips
  Widget _buildMuscleGroupsFilter() {
    // If no muscle groups available, provide default main muscle groups
    final List<String> muscleGroups = widget.availableMuscleGroups.isEmpty 
        ? ['Chest', 'Back', 'Shoulders', 'Biceps', 'Triceps', 'Legs', 'Abs', 'Glutes', 'Forearms', 'Calves'] // Default list
        : widget.availableMuscleGroups; // Use provided list
        
    return Wrap(
      spacing: 8.0, // Horizontal spacing between chips
      runSpacing: 8.0, // Vertical spacing between rows of chips
      children: muscleGroups.map((muscleGroup) {
        final isSelected = _selectedMuscleGroups.contains(muscleGroup); // Check if this group is selected
        return FilterChip(
          label: Text(
            muscleGroup, // Muscle group name
            style: TextStyle(
              color: isSelected ? accentGreen : neutralDark, // Green if selected, dark if not
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, // Bold if selected
            ),
          ),
          selected: isSelected, // Set selected state
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedMuscleGroups.add(muscleGroup); // Add to selected list
              } else {
                _selectedMuscleGroups.remove(muscleGroup); // Remove from selected list
              }
            });
          },
          backgroundColor: neutralLight, // Light background for unselected chips
          selectedColor: accentGreen.withAlpha((0.12 * 255).toInt()), // Transparent green for selected
          checkmarkColor: accentGreen, // Green checkmark
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50), // Fully rounded corners (pill shape)
            side: BorderSide(
              color: isSelected ? accentGreen.withAlpha((0.3 * 255).toInt()) : neutralMid, // Green border if selected
              width: 1, // Thin border
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Padding inside chip
        );
      }).toList(),
    );
  }

  /// Equipment filter chips
  Widget _buildEquipmentFilter() {
    // If no equipment available, provide default equipment options
    final List<String> equipment = widget.availableEquipment.isEmpty 
        ? ['Barbell', 'Dumbbell', 'Kettlebell', 'Cable', 'Machine', 'Bodyweight', 'Resistance Band', 'Medicine Ball'] // Default list
        : widget.availableEquipment; // Use provided list
        
    return Wrap(
      spacing: 8.0, // Horizontal spacing between chips
      runSpacing: 8.0, // Vertical spacing between rows of chips
      children: equipment.map((equipment) {
        final isSelected = _selectedEquipment.contains(equipment); // Check if this equipment is selected
        return FilterChip(
          label: Text(
            equipment, // Equipment name
            style: TextStyle(
              color: isSelected ? secondaryColor : neutralDark, // Secondary colour if selected
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, // Bold if selected
            ),
          ),
          selected: isSelected, // Set selected state
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedEquipment.add(equipment); // Add to selected list
              } else {
                _selectedEquipment.remove(equipment); // Remove from selected list
              }
            });
          },
          backgroundColor: neutralLight, // Light background for unselected chips
          selectedColor: secondaryColor.withAlpha((0.12 * 255).toInt()), // Transparent blue for selected
          checkmarkColor: secondaryColor, // Blue checkmark
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50), // Fully rounded corners (pill shape)
            side: BorderSide(
              color: isSelected ? secondaryColor.withAlpha((0.3 * 255).toInt()) : neutralMid, // Blue border if selected
              width: 1, // Thin border
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Padding inside chip
        );
      }).toList(),
    );
  }
}