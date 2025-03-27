import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateWorkoutPlanScreen extends StatefulWidget {
  final String? planId; // If provided, we're editing an existing plan

  const CreateWorkoutPlanScreen({super.key, this.planId});

  @override
  State<CreateWorkoutPlanScreen> createState() => _CreateWorkoutPlanScreenState();
}

class _CreateWorkoutPlanScreenState extends State<CreateWorkoutPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  bool _isEditing = false;
  bool _isLoadingPlan = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.planId != null;
    if (_isEditing) {
      _loadWorkoutPlan();
    }
  }

  Future<void> _loadWorkoutPlan() async {
    setState(() {
      _isLoadingPlan = true;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('WorkoutPlans')
          .doc(widget.planId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _descriptionController.text = data['description'] ?? '';
        });
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading workout plan: $error')),
      );
    } finally {
      setState(() {
        _isLoadingPlan = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Workout Plan' : 'Create Workout Plan'),
      ),
      body: _isLoadingPlan
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Workout Plan Name',
                        hintText: 'e.g., Full Body Workout, Upper/Lower Split',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name for your workout plan';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                        hintText: 'Describe your workout plan',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveWorkoutPlan,
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : Text(_isEditing ? 'Update Plan' : 'Create Plan'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _saveWorkoutPlan() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isEditing) {
        // Update existing workout plan
        await FirebaseFirestore.instance
            .collection('WorkoutPlans')
            .doc(widget.planId)
            .update({
          'name': _nameController.text,
          'description': _descriptionController.text,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Workout plan updated successfully')),
          );
          Navigator.pop(context, true); // Return success
        }
      } else {
        // Create new workout plan
        final docRef = await FirebaseFirestore.instance
            .collection('WorkoutPlans')
            .add({
          'name': _nameController.text,
          'description': _descriptionController.text,
          'exercises': [],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          // Add user ID here later when you implement authentication
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Workout plan created successfully')),
          );
          Navigator.pop(context, true); // Return success
        }
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving workout plan: $error')),
        );
      }
    }
  }
}