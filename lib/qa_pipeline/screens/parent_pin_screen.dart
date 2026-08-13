import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../database/database_helper.dart';

/// PIN-protected gateway to the parent section.
///
/// On first access, prompts the parent to create a 4-digit PIN.
/// On subsequent access, requires PIN entry for verification.
class ParentPinScreen extends StatefulWidget {
  /// Called when PIN verification succeeds.
  final VoidCallback onAuthenticated;

  const ParentPinScreen({super.key, required this.onAuthenticated});

  @override
  State<ParentPinScreen> createState() => _ParentPinScreenState();
}

class _ParentPinScreenState extends State<ParentPinScreen> {
  static const _pinKey = 'parent_pin_hash';

  String _enteredPin = '';
  bool _isSetupMode = false;
  bool _isLoading = true;
  String? _firstPin; // Used during setup for confirmation.
  bool _isConfirming = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkPinExists();
  }

  Future<void> _checkPinExists() async {
    final existing = await DatabaseHelper.instance.getSetting(_pinKey);
    setState(() {
      _isSetupMode = existing == null;
      _isLoading = false;
    });
  }

  String _hashPin(String pin) {
    return sha256.convert(utf8.encode(pin)).toString();
  }

  void _onDigitPressed(String digit) {
    if (_enteredPin.length >= 4) return;
    setState(() {
      _enteredPin += digit;
      _errorMessage = null;
    });

    if (_enteredPin.length == 4) {
      Future.delayed(const Duration(milliseconds: 200), _onPinComplete);
    }
  }

  void _onBackspace() {
    if (_enteredPin.isEmpty) return;
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _errorMessage = null;
    });
  }

  Future<void> _onPinComplete() async {
    if (_isSetupMode) {
      if (!_isConfirming) {
        // First entry during setup.
        setState(() {
          _firstPin = _enteredPin;
          _enteredPin = '';
          _isConfirming = true;
        });
      } else {
        // Confirm entry during setup.
        if (_enteredPin == _firstPin) {
          await DatabaseHelper.instance.setSetting(
            _pinKey,
            _hashPin(_enteredPin),
          );
          if (mounted) widget.onAuthenticated();
        } else {
          setState(() {
            _enteredPin = '';
            _firstPin = null;
            _isConfirming = false;
            _errorMessage = "PINs didn't match. Try again.";
          });
        }
      }
    } else {
      // Verification mode.
      final storedHash = await DatabaseHelper.instance.getSetting(_pinKey);
      if (_hashPin(_enteredPin) == storedHash) {
        if (mounted) widget.onAuthenticated();
      } else {
        setState(() {
          _enteredPin = '';
          _errorMessage = 'Incorrect PIN. Try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0C29),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      appBar: AppBar(
        title: const Text('Parent Section'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
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
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF3F3D99)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                _getTitle(),
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                _getSubtitle(),
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 32),

              // PIN dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < _enteredPin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled
                          ? const Color(0xFF6C63FF)
                          : Colors.transparent,
                      border: Border.all(
                        color: isFilled
                            ? const Color(0xFF6C63FF)
                            : Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),

              // Error message
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.redAccent,
                  ),
                ),
              ],

              const Spacer(flex: 1),

              // Number pad
              _buildNumPad(),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  String _getTitle() {
    if (_isSetupMode && !_isConfirming) return 'Create Parent PIN';
    if (_isSetupMode && _isConfirming) return 'Confirm PIN';
    return 'Enter Parent PIN';
  }

  String _getSubtitle() {
    if (_isSetupMode && !_isConfirming) return 'Choose a 4-digit PIN';
    if (_isSetupMode && _isConfirming) return 'Enter the same PIN again';
    return 'Enter your 4-digit PIN to continue';
  }

  Widget _buildNumPad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          _buildNumRow(['1', '2', '3']),
          const SizedBox(height: 12),
          _buildNumRow(['4', '5', '6']),
          const SizedBox(height: 12),
          _buildNumRow(['7', '8', '9']),
          const SizedBox(height: 12),
          _buildNumRow(['', '0', '⌫']),
        ],
      ),
    );
  }

  Widget _buildNumRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) {
        if (key.isEmpty) {
          return const SizedBox(width: 72, height: 56);
        }

        return SizedBox(
          width: 72,
          height: 56,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: key == '⌫' ? _onBackspace : () => _onDigitPressed(key),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white.withValues(alpha: 0.06),
                ),
                child: Center(
                  child: key == '⌫'
                      ? Icon(Icons.backspace_outlined,
                          color: Colors.white.withValues(alpha: 0.6), size: 22)
                      : Text(
                          key,
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
