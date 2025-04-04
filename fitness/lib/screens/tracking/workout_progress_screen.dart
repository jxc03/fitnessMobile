
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; 
import 'package:fl_chart/fl_chart.dart'; // Charts for progress visualisation
import 'package:firebase_auth/firebase_auth.dart'; // Authentication for users

class WorkoutProgressScreen extends StatefulWidget {
  const WorkoutProgressScreen({super.key});

  @override
  State<WorkoutProgressScreen> createState() => _WorkoutProgressScreenState();
}

class _WorkoutProgressScreenState extends State<WorkoutProgressScreen> {
  // Variables for loading state and error handling
  // Tracks if data is currently loading
  // Stores error messages if fails
  bool _isLoading = true;
  String? _errorMessage; 

  // Data structure to store exercise information
  // Assign array to store exercise history with progress stats
  List<Map<String, dynamic>> _exerciseHistory = [];
  
  // Variables for selected exercises
  String? _selectedExerciseId; 
  String? _selectedExerciseName;
  
  // Data structure to store exercise data for charts
  // Map through each exercise ID and create a summary object with progress stats
  Map<String, List<Map<String, dynamic>>> _exerciseData = {};
  
  @override
  void initState() {
    super.initState();
    _fetchExerciseProgress();
  }

  Future<void> _fetchExerciseProgress() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Try block for error handling 
    try {
      // Get the current user ID from Firebase Authentication
      // Check if user is authenticated, if user ID is empty then throw an error
      final String userId = FirebaseAuth.instance.currentUser?.uid ?? ''; 
      if (userId.isEmpty) {
        throw Exception('User not authenticated'); 
      }

      // Query Firestore for all workout sessions for the current user
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('WorkoutSessions')
          .where('userId', isEqualTo: userId) // Filter to show only current users data
          .orderBy('timestamp', descending: false) // Sort chronologically for progression
          .get();

      // Initialise data structures to organise data
      // Map to store exercise data points
      // Map to store exercise names for later reference
      final Map<String, List<Map<String, dynamic>>> exerciseData = {}; 
      final Map<String, String> exerciseNames = {}; 

      // Loop through each document (workout session) in the snapshot
      for (var doc in snapshot.docs) {
        //  Get the document data
        // Get the session date from the document data timestamp or use current date if not available
        // Get the list of exercises performed in the session from the document data or use an empty list if not available
        final data = doc.data() as Map<String, dynamic>;
        final sessionDate = data['timestamp'] != null 
          ? (data['timestamp'] as Timestamp).toDate() 
          : DateTime.now();
        final exercises = data['exercises'] as List? ?? [];
        
        // Loop through each exercise in the session
        for (var exercise in exercises) { 
          // Check if the exercise is completed, if not then skip to the next one
          if (exercise['completed'] != true) continue;

          // Get the exercise ID and name from the exercise data or use default values if not available
          final exerciseId = exercise['exerciseId'] as String? ?? '';
          final exerciseName = exercise['exerciseName'] as String? ?? 'Unknown Exercise';
          
          // Check if exercise ID is empty, if so then skip to the next one
          if (exerciseId.isEmpty) continue;
          
          // Store exercise name mapped to ID for later reference
          exerciseNames[exerciseId] = exerciseName;
          
          // Get the list of sets performed for the exercise from the exercise data or use an empty list if not available
          final sets = exercise['sets'] as List? ?? [];
          // Check if sets are empty, if so then skip to the next one
          if (sets.isEmpty) continue;
          
          // Variables to calculate average weight, reps, and rating for the exercise
          double totalWeight = 0;
          double totalReps = 0;
          double totalRating = 0;
          String? weightUnit;
          
          // Loop through each set to calculate total weight, reps, and rating
          for (var set in sets) {
            // Sum the weight, reps, and rating for each set
            totalWeight += (set['actualWeight'] as num?)?.toDouble() ?? 0;
            totalReps += (set['actualReps'] as num?)?.toDouble() ?? 0;
            totalRating += (set['rating'] as num?)?.toDouble() ?? 0;
            weightUnit = set['weightUnit'] as String? ?? 'kg';
          }
          
          // Calculate average values for weight, reps, and rating
          final avgWeight = totalWeight / sets.length; 
          final avgReps = totalReps / sets.length;
          final avgRating = totalRating / sets.length;
          
          // Data point for the exercise with date, weight, reps, and rating
          final dataPoint = {
            'date': sessionDate,
            'weight': avgWeight,
            'weightUnit': weightUnit,
            'reps': avgReps,
            'rating': avgRating,
          };

          // Check if exercise ID already exists in the exerciseData map, if not then create a new entry
          // If it exists then add the new data point to the list of data points for that exercise
          if (!exerciseData.containsKey(exerciseId)) { 
            exerciseData[exerciseId] = [];
          }
          exerciseData[exerciseId]!.add(dataPoint); 
        }
      }
      
      // A summary list of exercises with each exercise history and calculated progress
      // Map each entry in the exerciseNames map to a new list of exercise history
      final exerciseHistory = exerciseNames.entries.map((entry) { 
        // Get the exercise ID and name from the entry, get the history of data points for the exercise ID or use an empty list if not available
        final exerciseId = entry.key; 
        final exerciseName = entry.value;
        final history = exerciseData[exerciseId] ?? []; 
        
        // Calculate progress percentage, comparing latest to earliest data point
        // Check if there are at least two data points to calculate progress, if so then calculate the percentage change from the earliest to the latest data point
        double progressPercent = 0;
        if (history.length >= 2) {
          final earliest = history.first;
          final latest = history.last;
          
          // If earliest weight is greater than 0, calculate the progress percentage
          // If earliest weight is 0, set progressPercent to 0 to avoid division by zero
          if (earliest['weight'] > 0) {
            progressPercent = ((latest['weight'] - earliest['weight']) / earliest['weight']) * 100;
          }
        }
        
        // A summary object for the exercise with ID, name, number of data points, progress percentage, current weight, and weight unit
        return {
          'exerciseId': exerciseId,
          'exerciseName': exerciseName,
          'dataPoints': history.length,
          'progressPercent': progressPercent,
          'currentWeight': history.isNotEmpty ? history.last['weight'] : 0,
          'weightUnit': history.isNotEmpty ? history.last['weightUnit'] : 'kg',
        };
      }).toList(); // Converted to list 
      
      // Sort the exercise history by the number of data points in descending order (most tracked exercises first)
      exerciseHistory.sort((a, b) => b['dataPoints'].compareTo(a['dataPoints']));
      
      // Set the state with the fetched data
      // Update the exercise history and data maps with the fetched data
      setState(() {
        _exerciseHistory = exerciseHistory;
        _exerciseData = exerciseData;
        _isLoading = false;
        
        // Auto-select first exercise if available
        // Check if exercise history is not empty, if so then set the selected exercise ID and name to the first entry in the history
        if (exerciseHistory.isNotEmpty) {
          _selectedExerciseId = exerciseHistory.first['exerciseId'];
          _selectedExerciseName = exerciseHistory.first['exerciseName'];
        }
      });
    
    // If an error occurs during the fetching process, catch the error and set the error message in the state
    // Print the error message to the console for debugging
    } catch (error) {
      setState(() {
        _errorMessage = 'Failed to load exercise progress: $error';
        _isLoading = false;
      });
      print('Error fetching exercise progress: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Progress'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _buildProgressScreen(),
    );
  }

  Widget _buildProgressScreen() {
    if (_exerciseHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No exercise data yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete workouts to track your progress',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Exercise selector
        _buildExerciseSelector(),
        
        // Detailed progress for selected exercise
        // Check if selected exercise ID is not null, if so then build the exercise details widget
        if (_selectedExerciseId != null)
          Expanded(child: _buildExerciseDetails(_selectedExerciseId!)),
      ],
    );
  }

  Widget _buildExerciseSelector() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Exercise',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedExerciseId,
                hint: const Text('Select an exercise'),
                items: _exerciseHistory.map((exercise) {
                  return DropdownMenuItem<String>(
                    value: exercise['exerciseId'],
                    child: Text(exercise['exerciseName']),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedExerciseId = value;
                      _selectedExerciseName = _exerciseHistory
                          .firstWhere((ex) => ex['exerciseId'] == value)['exerciseName'];
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseDetails(String exerciseId) {
    final exerciseData = _exerciseData[exerciseId] ?? [];
    
    if (exerciseData.isEmpty) {
      return Center(
        child: Text(
          'No data available for this exercise',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }
    
    // Get unit from the most recent data point
    final weightUnit = exerciseData.last['weightUnit'] as String? ?? 'kg';
    
    // Calculate progress stats
    final earliestWeight = exerciseData.first['weight'] as double? ?? 0;
    final latestWeight = exerciseData.last['weight'] as double? ?? 0;
    final weightChange = latestWeight - earliestWeight;
    final weightChangePercent = earliestWeight > 0 
        ? (weightChange / earliestWeight) * 100 
        : 0.0;
    
    final earliestReps = exerciseData.first['reps'] as double? ?? 0;
    final latestReps = exerciseData.last['reps'] as double? ?? 0;
    final repsChange = latestReps - earliestReps;
    
    final Color changeColor = weightChange >= 0 ? Colors.green : Colors.red;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedExerciseName ?? 'Exercise',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Current Weight', 
                          '$latestWeight$weightUnit',
                          Icons.fitness_center,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'Weight Change', 
                          '${weightChange >= 0 ? '+' : ''}$weightChange$weightUnit\n(${weightChangePercent.toStringAsFixed(1)}%)',
                          Icons.trending_up,
                          color: changeColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'Current Reps', 
                          '${latestReps.toStringAsFixed(1)}',
                          Icons.repeat,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Weight progress chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weight Progress ($weightUnit)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: _buildWeightChart(exerciseData),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Rep progress chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reps Progress',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: _buildRepsChart(exerciseData),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Difficulty rating chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Difficulty Rating',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: _buildRatingChart(exerciseData),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color ?? Colors.blue,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWeightChart(List<Map<String, dynamic>> data) {
    // Format dates for X-axis
    final dateFormat = DateFormat('MM/dd');
    
    // Prepare line chart data
    final spots = data.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final item = entry.value;
      final weight = item['weight'] as double? ?? 0;
      return FlSpot(index, weight);
    }).toList();
    
    // Find min and max for the Y-axis
    double minY = double.infinity;
    double maxY = 0;
    
    for (var item in data) {
      final weight = item['weight'] as double? ?? 0;
      if (weight < minY) minY = weight;
      if (weight > maxY) maxY = weight;
    }
    
    // Add padding to Y-axis range
    minY = minY * 0.9;
    maxY = maxY * 1.1;
    
    // Minimum range
    if (maxY - minY < 5) {
      maxY = minY + 5;
    }
    
    if (minY < 0) minY = 0;
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          horizontalInterval: (maxY - minY) / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            axisNameWidget: const Text('Date'),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, titleMeta) {
                // Show dates at intervals
                final index = value.toInt();
                if (index >= 0 && index < data.length && index % 2 == 0) {
                  final date = data[index]['date'] as DateTime?;
                  if (date != null) {
                    return Text(
                      dateFormat.format(date),
                      style: const TextStyle(fontSize: 10),
                    );
                  }
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            axisNameWidget: const Text('Weight'),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, titleMeta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300),
        ),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepsChart(List<Map<String, dynamic>> data) {
    // Format dates for X-axis
    final dateFormat = DateFormat('MM/dd');
    
    // Prepare line chart data
    final spots = data.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final item = entry.value;
      final reps = item['reps'] as double? ?? 0;
      return FlSpot(index, reps);
    }).toList();
    
    // Find min and max for the Y-axis
    double minY = double.infinity;
    double maxY = 0;
    
    for (var item in data) {
      final reps = item['reps'] as double? ?? 0;
      if (reps < minY) minY = reps;
      if (reps > maxY) maxY = reps;
    }
    
    // Add padding to Y-axis range
    minY = minY * 0.9;
    maxY = maxY * 1.1;
    
    // Minimum range
    if (maxY - minY < 5) {
      maxY = minY + 5;
    }
    
    if (minY < 0) minY = 0;
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          horizontalInterval: (maxY - minY) / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            axisNameWidget: const Text('Date'),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, titleMeta) {
                // Show dates at intervals
                final index = value.toInt();
                if (index >= 0 && index < data.length && index % 2 == 0) {
                  final date = data[index]['date'] as DateTime?;
                  if (date != null) {
                    return Text(
                      dateFormat.format(date),
                      style: const TextStyle(fontSize: 10),
                    );
                  }
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            axisNameWidget: const Text('Reps'),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, titleMeta) {
                return Text(
                  value.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300),
        ),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingChart(List<Map<String, dynamic>> data) {
    // Format dates for X-axis
    final dateFormat = DateFormat('MM/dd');
    
    // Prepare line chart data
    final spots = data.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final item = entry.value;
      final rating = item['rating'] as double? ?? 0;
      return FlSpot(index, rating);
    }).toList();
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            axisNameWidget: const Text('Date'),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                // Show dates at intervals
                final index = value.toInt();
                if (index >= 0 && index < data.length && index % 2 == 0) {
                  final date = data[index]['date'] as DateTime?;
                  if (date != null) {
                    return Text(
                      dateFormat.format(date),
                      style: const TextStyle(fontSize: 10),
                    );
                  }
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            axisNameWidget: const Text('Difficulty'),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value % 1 == 0 && value >= 0 && value <= 5) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 12,
                      ),
                      SizedBox(width: 2),
                      Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300),
        ),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: 0,
        maxY: 5,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.orange,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.orange.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }
}