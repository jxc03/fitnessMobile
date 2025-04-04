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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter Exercises',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            
            const Divider(),
            
            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sort options
                    const Text(
                      'Sort By',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildSortOptions(),
                    
                    const SizedBox(height: 16),
                    const Divider(),
                    
                    // Muscle Groups filter
                    const Text(
                      'Muscle Groups',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildMuscleGroupsFilter(),
                    
                    const SizedBox(height: 16),
                    const Divider(),
                    
                    // Equipment filter
                    const Text(
                      'Equipment',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildEquipmentFilter(),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
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
                  child: const Text('Reset Filters'),
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
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Apply Filters'),
                ),
              ],
            ),
          ],
        ),
      ),
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
      title: Text(title),
      value: value,
      groupValue: _sortOption,
      onChanged: (newValue) {
        setState(() {
          _sortOption = newValue!;
        });
      },
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
      runSpacing: 4.0,
      children: muscleGroups.map((muscleGroup) {
        final isSelected = _selectedMuscleGroups.contains(muscleGroup);
        return FilterChip(
          label: Text(muscleGroup),
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
          backgroundColor: Colors.grey.shade200,
          selectedColor: Colors.blue.shade100,
          checkmarkColor: Colors.blue,
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
      runSpacing: 4.0,
      children: equipment.map((equipment) {
        final isSelected = _selectedEquipment.contains(equipment);
        return FilterChip(
          label: Text(equipment),
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
          backgroundColor: Colors.grey.shade200,
          selectedColor: Colors.green.shade100,
          checkmarkColor: Colors.green,
        );
      }).toList(),
    );
  }
}