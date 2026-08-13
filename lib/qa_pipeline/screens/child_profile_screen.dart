import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../database/child_repository.dart';
import '../models/child_profile.dart';

/// Playful child profile creation screen.
///
/// Collects name, age, and class in a game-like interface.
/// On completion, creates a local profile and returns it via [onProfileCreated].
class ChildProfileScreen extends StatefulWidget {
  final ValueChanged<ChildProfile> onProfileCreated;

  const ChildProfileScreen({super.key, required this.onProfileCreated});

  @override
  State<ChildProfileScreen> createState() => _ChildProfileScreenState();
}

class _ChildProfileScreenState extends State<ChildProfileScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  int? _selectedAge;
  String? _selectedClass;
  bool _isCreating = false;

  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;

  static const List<int> _ages = [5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18];
  static const List<String> _classes = [
    'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5',
    'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10',
    'Class 11', 'Class 12',
  ];

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  bool get _isValid => _nameController.text.trim().isNotEmpty;

  Future<void> _createProfile() async {
    if (!_isValid || _isCreating) return;

    setState(() => _isCreating = true);

    try {
      final profile = await ChildRepository.createChild(
        name: _nameController.text.trim(),
        age: _selectedAge,
        className: _selectedClass,
      );
      if (mounted) {
        widget.onProfileCreated(profile);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Oops! Something went wrong: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0C29),
              Color(0xFF302B63),
              Color(0xFF24243E),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Animated welcome emoji
                AnimatedBuilder(
                  animation: _bounceAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _bounceAnimation.value),
                      child: child,
                    );
                  },
                  child: const Text('🌟', style: TextStyle(fontSize: 56)),
                ),
                const SizedBox(height: 16),

                // Welcome title
                Text(
                  'Welcome!',
                  style: GoogleFonts.outfit(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ready to start learning?',
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 48),

                // Name field
                _buildLabel("What's your name?"),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _nameController,
                  hint: 'Enter your name',
                  icon: Icons.person_rounded,
                ),
                const SizedBox(height: 24),

                // Age dropdown
                _buildLabel('Your age'),
                const SizedBox(height: 8),
                _buildDropdown<int>(
                  value: _selectedAge,
                  hint: 'Select age',
                  icon: Icons.cake_rounded,
                  items: _ages.map((age) {
                    return DropdownMenuItem(
                      value: age,
                      child: Text('$age years old'),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedAge = val),
                ),
                const SizedBox(height: 24),

                // Class dropdown
                _buildLabel('Your class'),
                const SizedBox(height: 8),
                _buildDropdown<String>(
                  value: _selectedClass,
                  hint: 'Select class',
                  icon: Icons.school_rounded,
                  items: _classes.map((cls) {
                    return DropdownMenuItem(
                      value: cls,
                      child: Text(cls),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedClass = val),
                ),
                const SizedBox(height: 48),

                // Start button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isValid && !_isCreating ? _createProfile : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.white12,
                      disabledForegroundColor: Colors.white30,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor:
                          const Color(0xFF6C63FF).withValues(alpha: 0.5),
                    ),
                    child: _isCreating
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            "Let's Start! 🚀",
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF6C63FF)),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Row(
            children: [
              Icon(icon, color: const Color(0xFF6C63FF), size: 22),
              const SizedBox(width: 12),
              Text(
                hint,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              ),
            ],
          ),
          icon: Icon(Icons.arrow_drop_down,
              color: Colors.white.withValues(alpha: 0.4)),
          isExpanded: true,
          dropdownColor: const Color(0xFF24243E),
          style: const TextStyle(color: Colors.white, fontSize: 16),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
