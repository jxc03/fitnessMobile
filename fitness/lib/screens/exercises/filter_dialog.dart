import 'package:flutter/material.dart';

class FilterDialog extends StatefulWidget {
  final String selectedSortOption;
  final List<String> selectedMuscleGroups;
  final List<String> selectedEquipment;
  final List<String> availableMuscleGroups;
  final List<String> availableEquipment;

  const FilterDialog({
    super.key,
    required this.selectedSortOption,
    required this.selectedMuscleGroups,
    required this.selectedEquipment,
    required this.availableMuscleGroups,
    required this.availableEquipment,
  });

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late String _sortOption;
  late List<String> _selectedMuscleGroups;
  late List<String> _selectedEquipment;

  // Colour palette
  static const Color primaryColor = Color(0xFF2A6F97); // Deep blue - primary accent
  static const Color secondaryColor = Color(0xFF61A0AF); // Teal blue - secondary accent
  static const Color accentGreen = Color(0xFF4C956C); // Forest green - energy and growth
  static const Color accentTeal = Color(0xFF2F6D80); // Deep teal - calm and trust
  static const Color neutralDark = Color(0xFF3D5A6C); // Dark slate - professional text
  static const Color neutralLight = Color(0xFFF5F7FA); // Light gray - backgrounds
  static const Color neutralMid = Color(0xFFE1E7ED); // Mid gray - dividers, borders

  @override
  void initState() {
    super.initState();
    _sortOption = widget.selectedSortOption;
    _selectedMuscleGroups = List.from(widget.selectedMuscleGroups);
    _selectedEquipment = List.from(widget.selectedEquipment);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: neutralMid, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                border: Border(
                  bottom: BorderSide(color: neutralMid, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter Exercises',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: neutralDark,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: neutralDark),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            
            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      
                      // Sort options section
                      _buildSectionHeader('Sort By', Icons.sort),
                      const SizedBox(height: 12),
                      _buildSortOptions(),
                      
                      const SizedBox(height: 16),
                      const Divider(color: neutralMid),
                      const SizedBox(height: 16),
                      
                      // Muscle Groups filter
                      _buildSectionHeader('Muscle Groups', Icons.accessibility_new),
                      const SizedBox(height: 12),
                      _buildMuscleGroupsFilter(),
                      
                      const SizedBox(height: 16),
                      const Divider(color: neutralMid),
                      const SizedBox(height: 16),
                      
                      // Equipment filter
                      _buildSectionHeader('Equipment', Icons.fitness_center),
                      const SizedBox(height: 12),
                      _buildEquipmentFilter(),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
            
            // Action buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border(
                  top: BorderSide(color: neutralMid, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _sortOption = 'Default';
                        _selectedMuscleGroups = [];
                        _selectedEquipment = [];
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text(
                      'Reset Filters',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop({
                        'sortOption': _sortOption,
                        'muscleGroups': _selectedMuscleGroups,
                        'equipment': _selectedEquipment,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(fontWeight: FontWeight.w600),
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

  // Section header with icon
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: neutralDark,
          ),
        ),
      ],
    );
  }

  Widget _buildSortOptions() {
    return Column(
      children: [
        _buildSortRadioTile('Default', 'Default'),
        _buildSortRadioTile('A to Z', 'A-Z'),
        _buildSortRadioTile('Z to A', 'Z-A'),
      ],
    );
  }

  Widget _buildSortRadioTile(String title, String value) {
    return RadioListTile<String>(
      title: Text(
        title,
        style: TextStyle(
          color: neutralDark,
          fontWeight: _sortOption == value ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      value: value,
      groupValue: _sortOption,
      onChanged: (newValue) {
        setState(() {
          _sortOption = newValue!;
        });
      },
      activeColor: primaryColor,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  Widget _buildMuscleGroupsFilter() {
    // If no muscle groups available, provide default main muscle groups
    final List<String> muscleGroups = widget.availableMuscleGroups.isEmpty 
        ? ['Chest', 'Back', 'Shoulders', 'Biceps', 'Triceps', 'Legs', 'Abs', 'Glutes', 'Forearms', 'Calves']
        : widget.availableMuscleGroups;
        
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: muscleGroups.map((muscleGroup) {
        final isSelected = _selectedMuscleGroups.contains(muscleGroup);
        return FilterChip(
          label: Text(
            muscleGroup,
            style: TextStyle(
              color: isSelected ? accentGreen : neutralDark,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedMuscleGroups.add(muscleGroup);
              } else {
                _selectedMuscleGroups.remove(muscleGroup);
              }
            });
          },
          backgroundColor: neutralLight,
          selectedColor: accentGreen.withAlpha((0.12 * 255).toInt()),
          checkmarkColor: accentGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
            side: BorderSide(
              color: isSelected ? accentGreen.withAlpha((0.3 * 255).toInt()) : neutralMid,
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        );
      }).toList(),
    );
  }

  Widget _buildEquipmentFilter() {
    // If no equipment available, provide default equipment options
    final List<String> equipment = widget.availableEquipment.isEmpty 
        ? ['Barbell', 'Dumbbell', 'Kettlebell', 'Cable', 'Machine', 'Bodyweight', 'Resistance Band', 'Medicine Ball']
        : widget.availableEquipment;
        
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: equipment.map((equipment) {
        final isSelected = _selectedEquipment.contains(equipment);
        return FilterChip(
          label: Text(
            equipment,
            style: TextStyle(
              color: isSelected ? secondaryColor : neutralDark,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedEquipment.add(equipment);
              } else {
                _selectedEquipment.remove(equipment);
              }
            });
          },
          backgroundColor: neutralLight,
          selectedColor: secondaryColor.withAlpha((0.12 * 255).toInt()),
          checkmarkColor: secondaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
            side: BorderSide(
              color: isSelected ? secondaryColor.withAlpha((0.3 * 255).toInt()) : neutralMid,
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        );
      }).toList(),
    );
  }
}