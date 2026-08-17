import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/models/child_profile.dart' as core;
import '../core/models/parent_account.dart';
import '../core/services/ai_integration_service.dart';
import '../core/services/ai_voice_service.dart';
import '../core/services/parent_repository.dart';
import '../core/state/child_state.dart';
import '../qa_pipeline/models/child_profile.dart' as qa;
import '../qa_pipeline/screens/parent_dashboard.dart';
import '../qa_pipeline/services/content_discovery_service.dart';
import 'sego_concept_screen.dart';

enum ParentAuthMode {
  signup,
  createChild,
  personalizingExperience,
  createPin,
  confirmPin,
  loginPin,
  childLogin,
}

/// NIMO Parent & Child Authentication Screen
/// Matching the exact visual style of the reference mockup:
/// - Coral topographic contour background top banner with smooth wavy card transition
/// - Bold typography with underline accent line
/// - Custom input fields with lead icons
/// - Polished social login placeholders ([Google] [GitHub] [Facebook])
/// - 4-Digit Secure PIN Pad for Parent & Child verification
class ParentAuthScreen extends StatefulWidget {
  final ParentAuthMode initialMode;
  final VoidCallback? onAuthSuccess;

  const ParentAuthScreen({
    super.key,
    this.initialMode = ParentAuthMode.loginPin,
    this.onAuthSuccess,
  });

  @override
  State<ParentAuthScreen> createState() => _ParentAuthScreenState();
}

class _ParentAuthScreenState extends State<ParentAuthScreen> {
  late ParentAuthMode _currentMode;

  // Controllers for Parent Signup
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  // Controllers for Child Creation
  final _childNameController = TextEditingController();
  int _childAge = 5;
  String _selectedStandard = 'Grade 1';
  String _selectedLanguage = 'English';
  String _learningPace = 'normal';

  // Personalizing AI State
  int _personalizedDifficulty = 50;
  String _personalizedLevel = 'Balanced Explorer';
  String _personalizedReasoning = '';
  String _personalizingStatusText = 'Connecting to NIMO AI Pediatric Engine...';
  double _personalizingProgress = 0.0;

  // PIN inputs
  final List<String> _pinDigits = [];
  String? _firstEnteredPin;

  // Form State
  bool _rememberMe = true;
  String? _errorMessage;
  bool _isLoading = false;

  // Created Parent & Child transient state
  ParentAccount? _createdParent;
  qa.ChildProfile? _createdChild;

  @override
  void initState() {
    super.initState();
    _currentMode = widget.initialMode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _childNameController.dispose();
    super.dispose();
  }

  // Handle Parent Signup (PIN Secured)
  Future<void> _handleSignup() async {
    setState(() => _errorMessage = null);

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter your full name');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email address');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final parent = await ParentRepository.createParent(
        name: name,
        email: email,
        password: 'pin_secured_account',
      );

      _createdParent = parent;
      ChildState.instance.setActiveParent(parent);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentMode = ParentAuthMode.createChild;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  // Handle Child Profile Creation with Groq AI Difficulty Assessment & Personalizing Screen
  Future<void> _handleCreateChild() async {
    setState(() => _errorMessage = null);

    final childName = _childNameController.text.trim();
    if (childName.isEmpty) {
      setState(() => _errorMessage = "Please enter your learner's name");
      return;
    }

    setState(() {
      _currentMode = ParentAuthMode.personalizingExperience;
      _personalizingProgress = 0.15;
      _personalizingStatusText = 'Connecting to NIMO AI Pediatric Engine...';
    });

    try {
      final parentId = _createdParent?.id ?? (await ParentRepository.getActiveParent())?.id ?? 'parent_default';
      final tempChildId = ParentRepository.generateChildId();

      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        setState(() {
          _personalizingProgress = 0.45;
          _personalizingStatusText = 'Analyzing learning milestones for Age $_childAge in $_selectedStandard...';
        });
      }

      // Call Groq LLM AI Microservice (Port 8001 /calculate/difficulty)
      final aiRes = await AiIntegrationService.instance.calculateDifficulty(
        childId: tempChildId,
        name: childName,
        age: _childAge,
        standard: _selectedStandard,
        language: _selectedLanguage,
        learningPace: _learningPace,
      );

      final diffPct = (aiRes['difficultyPercentage'] as num?)?.toInt() ?? 50;
      final diffLevel = (aiRes['difficultyLevel'] as String?) ?? 'Balanced Explorer';
      final diffReason = (aiRes['reasoning'] as String?) ??
          'Personalized $diffPct% quest difficulty configured for age $_childAge ($_selectedStandard).';

      if (mounted) {
        setState(() {
          _personalizedDifficulty = diffPct;
          _personalizedLevel = diffLevel;
          _personalizedReasoning = diffReason;
          _personalizingProgress = 0.85;
          _personalizingStatusText = 'Saving personalized profile to SQLite database...';
        });
      }

      // Store child in SQLite under that child with difficulty level
      final child = await ParentRepository.createChildProfile(
        parentId: parentId,
        name: childName,
        age: _childAge,
        className: _selectedStandard,
        difficultyPercentage: diffPct,
        difficultyLevel: diffLevel,
        difficultyReasoning: diffReason,
      );

      _createdChild = child;
      ChildState.instance.setProfile(
        core.ChildProfile(
          id: child.id,
          parentId: child.parentId,
          name: child.name,
          age: child.age,
          className: child.className,
          difficultyPercentage: diffPct,
          difficultyLevel: diffLevel,
          difficultyReasoning: diffReason,
        ),
        remember: true,
      );

      if (mounted) {
        setState(() {
          _personalizingProgress = 1.0;
          _personalizingStatusText = 'Difficulty Calibrated: $diffPct% ($diffLevel) ✓';
        });
      }

      await Future.delayed(const Duration(milliseconds: 1100));

      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentMode = ParentAuthMode.createPin;
          _pinDigits.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentMode = ParentAuthMode.createChild;
          _errorMessage = 'Failed to personalize experience: $e';
        });
      }
    }
  }

  // Handle Keypad Press for PIN Creation & Verification
  void _onPinKeyPress(String digit) {
    if (_pinDigits.length < 4) {
      setState(() {
        _errorMessage = null;
        _pinDigits.add(digit);
      });

      if (_pinDigits.length == 4) {
        final entered = _pinDigits.join();
        _processCompletedPin(entered);
      }
    }
  }

  void _onPinBackspace() {
    if (_pinDigits.isNotEmpty) {
      setState(() {
        _errorMessage = null;
        _pinDigits.removeLast();
      });
    }
  }

  void _onPinClear() {
    setState(() {
      _errorMessage = null;
      _pinDigits.clear();
    });
  }

  void _showRegistrationSuccessModal() {
    // 1. Dynamically discover real chapters from content service (Zero hardcoding)
    ContentDiscoveryService.discoverContent().then((chapters) {
      final childName = _childNameController.text.trim().isNotEmpty
          ? _childNameController.text.trim()
          : (_createdChild?.name ?? 'Explorer');
      final chapterNames = chapters.map((c) => c.name).toList();
      final firstChapter = chapterNames.isNotEmpty ? chapterNames.first : null;

      // 2. Play dynamic AI-powered post-signup introduction grounded strictly in discovered content
      AiVoiceService.instance.playPostSignupIntro(
        childName: childName,
        age: _childAge,
        difficultyLevel: _personalizedLevel,
        availableChapters: chapterNames,
        firstChapter: firstChapter,
      );
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            backgroundColor: const Color(0xEE18181B),
            elevation: 16,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: BorderSide(color: const Color(0xFF22C55E).withValues(alpha: 0.5), width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Green Success Glow Badge
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0x2222C55E),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF22C55E), width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x4422C55E),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 36),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Title
                  const Text(
                    'Registration Complete! 🎉',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.4,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Subtitle
                  const Text(
                    'AI Voice Companion is ready for your learner!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF9CA3AF),
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Dynamic AI Voice Introduction Card
                  ListenableBuilder(
                    listenable: AiVoiceService.instance,
                    builder: (context, _) {
                      final voiceService = AiVoiceService.instance;
                      final isSpeaking = voiceService.isSpeaking;
                      final spokenText = voiceService.currentSpokenText ??
                          'Welcome to NIMO The Warrior! Your personalized learning quest is ready.';

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF27272A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSpeaking ? const Color(0xFFFC6B6B) : const Color(0xFF3F3F46),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isSpeaking ? const Color(0x33FC6B6B) : const Color(0x223F3F46),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isSpeaking ? Icons.volume_up_rounded : Icons.record_voice_over_rounded,
                                    color: isSpeaking ? const Color(0xFFFC6B6B) : Colors.white70,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isSpeaking ? 'AI Companion Speaking...' : 'AI Voice Introduction',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isSpeaking ? const Color(0xFFFC6B6B) : Colors.white70,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.replay_rounded, size: 18, color: Colors.white70),
                                  tooltip: 'Replay Intro',
                                  onPressed: () => AiVoiceService.instance.replayCurrent(),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              spokenText,
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12,
                                color: Color(0xFFD1D5DB),
                                height: 1.35,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // "Continue to Learning →" Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        AiVoiceService.instance.stop();
                        Navigator.of(dialogCtx).pop();
                        if (widget.onAuthSuccess != null) {
                          widget.onAuthSuccess!();
                        } else {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const SegoConceptScreen(initialPage: 0),
                            ),
                            (route) => false,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFC6B6B),
                        elevation: 4,
                        shadowColor: const Color(0x66FC6B6B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Continue to Learning',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _processCompletedPin(String pin) async {
    if (_currentMode == ParentAuthMode.createPin) {
      _firstEnteredPin = pin;
      setState(() {
        _currentMode = ParentAuthMode.confirmPin;
        _pinDigits.clear();
      });
    } else if (_currentMode == ParentAuthMode.confirmPin) {
      if (pin != _firstEnteredPin) {
        setState(() {
          _errorMessage = "PINs don't match. Try again.";
          _pinDigits.clear();
          _currentMode = ParentAuthMode.createPin;
          _firstEnteredPin = null;
        });
      } else {
        // Save PIN securely
        setState(() => _isLoading = true);
        String? parentId = _createdParent?.id ?? (await ParentRepository.getActiveParent())?.id;
        if (parentId == null) {
          final parent = await ParentRepository.createParent(
            name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Parent User',
            email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : 'parent@nimo.app',
            password: 'pin_secured_account',
          );
          parentId = parent.id;
          ChildState.instance.setActiveParent(parent);
        }
        await ParentRepository.setParentPin(parentId, pin);

        if (mounted) {
          setState(() => _isLoading = false);
          ChildState.instance.setRole('PARENT');
          _showRegistrationSuccessModal();
        }
      }
    } else if (_currentMode == ParentAuthMode.loginPin) {
      // Verify Parent PIN
      final hasAccount = await ParentRepository.hasParentAccount();
      bool isValid = false;

      if (hasAccount) {
        final activeParent = await ParentRepository.getActiveParent();
        if (activeParent != null) {
          isValid = await ParentRepository.verifyPin(activeParent.id, pin);
        }
        if (!isValid) {
          final matchedParent = await ParentRepository.verifyAnyParentPin(pin);
          isValid = matchedParent != null;
          if (matchedParent != null) {
            ChildState.instance.setActiveParent(matchedParent);
          }
        }
      }

      if (!isValid && !hasAccount) {
        final parent = await ParentRepository.createParent(
          name: 'Parent User',
          email: 'parent@nimo.app',
          password: 'pin_secured_account',
        );
        await ParentRepository.setParentPin(parent.id, pin);
        ChildState.instance.setActiveParent(parent);
        isValid = true;
      }

      if (isValid) {
        ChildState.instance.setRole('PARENT');
        if (mounted) {
          if (widget.onAuthSuccess != null) {
            widget.onAuthSuccess!();
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => ParentDashboard(
                  childId: _createdChild?.id ?? ChildState.instance.currentProfile.id,
                ),
              ),
            );
          }
        }
      } else {
        setState(() {
          _errorMessage = "Account doesn't exist or PIN incorrect.";
          _pinDigits.clear();
        });
      }
    } else if (_currentMode == ParentAuthMode.childLogin) {
      // Verify Child PIN
      final hasAccount = await ParentRepository.hasParentAccount();
      bool isValid = false;

      if (hasAccount) {
        final activeParent = await ParentRepository.getActiveParent();
        if (activeParent != null) {
          isValid = await ParentRepository.verifyPin(activeParent.id, pin);
        }
        if (!isValid) {
          final matchedParent = await ParentRepository.verifyAnyParentPin(pin);
          isValid = matchedParent != null;
          if (matchedParent != null) {
            ChildState.instance.setActiveParent(matchedParent);
          }
        }
      }

      if (!isValid && !hasAccount) {
        final parent = await ParentRepository.createParent(
          name: 'Parent User',
          email: 'parent@nimo.app',
          password: 'pin_secured_account',
        );
        await ParentRepository.setParentPin(parent.id, pin);
        ChildState.instance.setActiveParent(parent);
        isValid = true;
      }

      if (isValid) {
        final activeParent = ChildState.instance.currentParent ?? await ParentRepository.getActiveParent();
        if (activeParent != null) {
          final children = await ParentRepository.getChildrenForParent(activeParent.id);
          if (children.isNotEmpty) {
            await ChildState.instance.loadProfile(children.first.id);
          } else {
            final newChild = await ParentRepository.createChildProfile(
              parentId: activeParent.id,
              name: 'Learner',
              age: 6,
            );
            await ChildState.instance.loadProfile(newChild.id);
          }
        }

        ChildState.instance.setRole('CHILD');
        unawaited(ChildState.instance.startNewSession());

        if (mounted) {
          if (widget.onAuthSuccess != null) {
            widget.onAuthSuccess!();
          } else {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 250),
                pageBuilder: (_, animation, __) => FadeTransition(
                  opacity: animation,
                  child: const SegoConceptScreen(initialPage: 3),
                ),
              ),
            );
          }
        }
      } else {
        setState(() {
          _errorMessage = "Account doesn't exist or PIN incorrect.";
          _pinDigits.clear();
        });
      }
    }
  }

  void _showComingSoonSnackBar(String provider) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$provider sign-in coming soon in next release!'),
        backgroundColor: const Color(0xFFFC6B6B),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPinMode = _currentMode == ParentAuthMode.loginPin ||
        _currentMode == ParentAuthMode.childLogin ||
        _currentMode == ParentAuthMode.createPin ||
        _currentMode == ParentAuthMode.confirmPin;

    if (isPinMode) {
      return Scaffold(
        backgroundColor: const Color(0xFF18181B),
        body: SafeArea(
          child: Column(
            children: [
              // Top Bar with Back Arrow & SIGN UP Action Pill
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentMode = ParentAuthMode.signup;
                          _errorMessage = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFC6B6B),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33FC6B6B),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'SIGN UP',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Lock Hero Icon
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFF27272A),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFFC6B6B).withValues(alpha: 0.60),
                              width: 2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x33FC6B6B),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(Icons.lock_rounded, color: Color(0xFFFC6B6B), size: 30),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Title & Subtitle
                        _buildDarkPinHeaderTitle(),

                        const SizedBox(height: 16),

                        // Error Banner if present
                        if (_errorMessage != null) _buildErrorBanner(),

                        // 4 Glowing Pink PIN Dots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(4, (index) {
                            final isFilled = index < _pinDigits.length;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              margin: const EdgeInsets.symmetric(horizontal: 10),
                              width: isFilled ? 20 : 16,
                              height: isFilled ? 20 : 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isFilled ? const Color(0xFFFC6B6B) : const Color(0xFF27272A),
                                border: Border.all(
                                  color: isFilled ? const Color(0xFFFC6B6B) : const Color(0xFF52525B),
                                  width: 2,
                                ),
                                boxShadow: isFilled
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFFFC6B6B).withValues(alpha: 0.5),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : [],
                              ),
                            );
                          }),
                        ),

                        const SizedBox(height: 32),

                        // Keypad Grid with Semi-Transparent Circular Buttons
                        SizedBox(
                          width: 260,
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              for (int i = 1; i <= 9; i++)
                                _buildTransparentPinKey(i.toString(), () => _onPinKeyPress(i.toString())),
                              _buildTransparentPinKey('C', _onPinClear, isAction: true),
                              _buildTransparentPinKey('0', () => _onPinKeyPress('0')),
                              _buildTransparentPinKey('⌫', _onPinBackspace, isAction: true),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Switch to Signup Link
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _currentMode = ParentAuthMode.signup;
                                _errorMessage = null;
                              });
                            },
                            child: RichText(
                              text: const TextSpan(
                                text: "Don't have an Account ? ",
                                style: TextStyle(fontFamily: 'Outfit', color: Colors.grey, fontSize: 13),
                                children: [
                                  TextSpan(
                                    text: 'Sign up',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      color: Color(0xFFFC6B6B),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFC6B6B),
      body: Stack(
        children: [
          // 1. Top Header Topographic Contour Pattern Canvas
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 180,
            child: CustomPaint(
              painter: _TopographicContourPainter(),
            ),
          ),

          // 2. Back Navigation Arrow (Top Left)
          Positioned(
            top: 36,
            left: 16,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),

          // 3. Main Wavy Card Sheet Container
          Positioned(
            top: 145,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 18,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Title & Underline Accent
                      _buildHeaderTitle(),

                      const SizedBox(height: 12),

                      // Error Banner
                      if (_errorMessage != null) _buildErrorBanner(),

                      // Mode Content Switcher
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_currentMode == ParentAuthMode.signup) _buildSignupForm(),
                              if (_currentMode == ParentAuthMode.createChild) _buildCreateChildForm(),
                              if (_currentMode == ParentAuthMode.personalizingExperience) _buildPersonalizingLoadingView(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderTitle() {
    String title = 'Sign in';
    String subtitle = 'Welcome to NIMO learner setup';

    switch (_currentMode) {
      case ParentAuthMode.signup:
        title = 'Sign up';
        subtitle = 'Create your NIMO parent account';
        break;
      case ParentAuthMode.createChild:
        title = 'Create Learner';
        subtitle = 'Set up your child learner profile';
        break;
      case ParentAuthMode.personalizingExperience:
        title = 'Personalizing... 🐾';
        subtitle = 'NIMO AI is calibrating quest difficulty';
        break;
      case ParentAuthMode.createPin:
        title = 'Create Parent PIN';
        subtitle = 'Enter 4-digit PIN for parent access';
        break;
      case ParentAuthMode.confirmPin:
        title = 'Confirm Parent PIN';
        subtitle = 'Re-enter your 4-digit PIN to confirm';
        break;
      case ParentAuthMode.loginPin:
        title = 'Parent Access';
        subtitle = 'Enter Parent PIN to unlock analytics';
        break;
      case ParentAuthMode.childLogin:
        title = "Who's playing?";
        subtitle = 'Enter PIN to start learning journey';
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: Color(0xFF2B2B2B),
            height: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        // Red accent underline matching mockup
        Container(
          width: 38,
          height: 3.5,
          decoration: BoxDecoration(
            color: const Color(0xFFFC6B6B),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    final isAccountError = _errorMessage?.contains("doesn't exist") == true ||
        _errorMessage?.contains("incorrect") == true;

    return GestureDetector(
      onTap: () {
        if (isAccountError) {
          setState(() {
            _currentMode = ParentAuthMode.signup;
            _errorMessage = null;
            _pinDigits.clear();
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xEE2A1215), // Premium dark crimson glassmorphism
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFC6B6B).withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFC6B6B).withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0x33FC6B6B),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, color: Color(0xFFFC6B6B), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  if (isAccountError)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        "👉 Click here to Create an Account / Sign Up",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFFC6B6B),
                          decoration: TextDecoration.underline,
                        ),
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

  // ─────────────────────────────────────────────────────────────────────────
  // PARENT SIGNUP FORM (No Password - PIN Secured)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSignupForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name Field
        _buildInputField(
          label: 'Full Name',
          hint: 'Enter your full name',
          icon: Icons.person_outline_rounded,
          controller: _nameController,
        ),
        const SizedBox(height: 18),

        // Email Field
        _buildInputField(
          label: 'Email Address',
          hint: 'demo@email.com',
          icon: Icons.mail_outline_rounded,
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),

        // Remember Me Row
        Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: _rememberMe,
                activeColor: const Color(0xFFFC6B6B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                onChanged: (val) => setState(() => _rememberMe = val ?? true),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Remember Me',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF555555),
              ),
            ),
          ],
        ),

        const SizedBox(height: 22),

        // Next Step: Learner Setup Primary Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSignup,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFC6B6B),
              elevation: 3,
              shadowColor: const Color(0x66FC6B6B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Next: Learner Setup',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 20),

        // Social Login Divider
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.shade300)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'OR SIGN UP WITH',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey.shade300)),
          ],
        ),

        const SizedBox(height: 18),

        // Social Buttons Placeholders ([Google] [GitHub] [Facebook])
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSocialButton('Google', Icons.g_mobiledata_rounded, Colors.red.shade400),
            _buildSocialButton('GitHub', Icons.code_rounded, Colors.black87),
            _buildSocialButton('Facebook', Icons.facebook_rounded, Colors.blue.shade700),
          ],
        ),

        const SizedBox(height: 20),

        // Switch to Login Link
        Center(
          child: GestureDetector(
            onTap: () {
              setState(() => _currentMode = ParentAuthMode.loginPin);
            },
            child: RichText(
              text: const TextSpan(
                text: 'Already have an Account ? ',
                style: TextStyle(fontFamily: 'Outfit', color: Colors.grey, fontSize: 12),
                children: [
                  TextSpan(
                    text: 'Sign in',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: Color(0xFFFC6B6B),
                      fontWeight: FontWeight.w800,
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

  // ─────────────────────────────────────────────────────────────────────────
  // CREATE CHILD PROFILE FORM
  // ─────────────────────────────────────────────────────────────────────────
  void _showAgeMascotDialog() {
    int tempAge = _childAge;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: const Color(0xFF18181B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              child: Container(
                width: 340,
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Select Your Learner\'s Age 🎈',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Helps customize fun learning quests',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF27272A),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: const Color(0xFFFC6B6B).withValues(alpha: 0.5), width: 1.5),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.face_rounded, color: Color(0xFFFC6B6B), size: 24),
                          SizedBox(width: 8),
                          Text(
                            '🐾 NIMO Age Mascot',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFFC6B6B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: List.generate(10, (index) {
                        final age = index + 3;
                        final isSel = tempAge == age;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() => tempAge = age);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 52,
                            height: 46,
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xFFFC6B6B) : const Color(0xFF27272A),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSel ? const Color(0xFFFC6B6B) : const Color(0xFF3F3F46),
                                width: 1.5,
                              ),
                              boxShadow: isSel
                                  ? [
                                      const BoxShadow(
                                        color: Color(0x66FC6B6B),
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      )
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: Text(
                                '$age',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: isSel ? Colors.white : const Color(0xFFE4E4E7),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => _childAge = tempAge);
                          Navigator.of(ctx).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFC6B6B),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
                        ),
                        child: Text(
                          'Confirm Age ($tempAge Years) ✓',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CREATE CHILD PROFILE FORM
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCreateChildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Child Name
        _buildInputField(
          label: "Child's Name",
          hint: "e.g. Aarav",
          icon: Icons.face_rounded,
          controller: _childNameController,
        ),
        const SizedBox(height: 16),

        // Select Age Mascot Button Card
        const Text(
          "Child's Age",
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF444444),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showAgeMascotDialog,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFC6B6B).withValues(alpha: 0.4), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.cake_rounded, color: Color(0xFFFC6B6B), size: 24),
                    const SizedBox(width: 10),
                    Text(
                      'Age: $_childAge Years Old',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFC6B6B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Select Age 🐾',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Standard / Class Dropdown Selector
        const Text(
          "Standard / Grade (Class)",
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF444444),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedStandard,
              isExpanded: true,
              icon: const Icon(Icons.school_rounded, color: Color(0xFFFC6B6B)),
              items: [
                'Preschool / Nursery',
                'LKG',
                'UKG',
                'Grade 1',
                'Grade 2',
                'Grade 3',
                'Grade 4',
                'Grade 5',
              ].map((std) => DropdownMenuItem(
                value: std,
                child: Text(
                  std,
                  style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600),
                ),
              )).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedStandard = val);
              },
            ),
          ),
        ),
        const SizedBox(height: 14),

        // AI Personalization Info Badge Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF5F5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFC6B6B).withValues(alpha: 0.35), width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFC6B6B),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Groq LLM Dynamic Calibration',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFC6B6B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'AI calculates personalized difficulty percentage for Age $_childAge in $_selectedStandard',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11,
                        color: Color(0xFF555555),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Preferred Language Dropdown
        const Text(
          'Preferred Language',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF444444),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedLanguage,
              isExpanded: true,
              items: ['English', 'Hindi', 'Bengali', 'Japanese']
                  .map((lang) => DropdownMenuItem(value: lang, child: Text(lang)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedLanguage = val);
              },
            ),
          ),
        ),

        const SizedBox(height: 28),

        // Continue Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleCreateChild,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFC6B6B),
              elevation: 4,
              shadowColor: const Color(0x66FC6B6B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Personalize & Continue',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PERSONALIZING EXPERIENCE LOADING VIEW
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildPersonalizingLoadingView() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 10),

          // Animated Pulsing Mascot Radar
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFC6B6B).withValues(alpha: 0.12),
                  ),
                ),
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFC6B6B).withValues(alpha: 0.25),
                  ),
                ),
                Container(
                  width: 66,
                  height: 66,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFC6B6B),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x66FC6B6B),
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.auto_awesome, color: Colors.white, size: 32),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Title
          const Text(
            'Personalizing Your Experience...',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2B2B2B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Calibrating NIMO cognitive quest difficulty for ${_childNameController.text.trim().isEmpty ? 'Learner' : _childNameController.text.trim()}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              color: Color(0xFF71717A),
            ),
          ),

          const SizedBox(height: 24),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _personalizingProgress > 0 ? _personalizingProgress : null,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFC6B6B)),
            ),
          ),

          const SizedBox(height: 16),

          // Dynamic Status Text
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F3),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFC6B6B).withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFFC6B6B),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    _personalizingStatusText,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFC6B6B),
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Summary Card once ready
          if (_personalizingProgress >= 0.8)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: 1.0,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4FBF7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.4), width: 1.5),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Quest Level: $_personalizedDifficulty% ($_personalizedLevel)',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                    if (_personalizedReasoning.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _personalizedReasoning,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11,
                          color: Color(0xFF166534),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SECURE PIN PAD SECTION (DARK THEME STYLING)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildPinPadSection() {
    return Column(
      children: [
        const SizedBox(height: 10),

        // Lock Header Circle Icon
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: const Color(0xFF27272A),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFFC6B6B).withValues(alpha: 0.60),
              width: 2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33FC6B6B),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.lock_rounded, color: Color(0xFFFC6B6B), size: 28),
          ),
        ),

        const SizedBox(height: 24),

        // 4 PIN Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            final isFilled = index < _pinDigits.length;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              width: isFilled ? 20 : 16,
              height: isFilled ? 20 : 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFilled ? const Color(0xFFFC6B6B) : const Color(0xFF27272A),
                border: Border.all(
                  color: isFilled ? const Color(0xFFFC6B6B) : const Color(0xFF52525B),
                  width: 2,
                ),
                boxShadow: isFilled
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFC6B6B).withValues(alpha: 0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
            );
          }),
        ),

        const SizedBox(height: 28),

        // Keypad Grid (1-9, C, 0, Backspace) - Dark Circle Buttons
        SizedBox(
          width: 260,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: [
              for (int i = 1; i <= 9; i++)
                _buildPinKey(i.toString(), () => _onPinKeyPress(i.toString())),
              _buildPinKey('C', _onPinClear, isAction: true),
              _buildPinKey('0', () => _onPinKeyPress('0')),
              _buildPinKey('⌫', _onPinBackspace, isAction: true),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Switch to Signup Link if on PIN mode
        if (_currentMode == ParentAuthMode.loginPin ||
            _currentMode == ParentAuthMode.childLogin ||
            _currentMode == ParentAuthMode.createPin ||
            _currentMode == ParentAuthMode.confirmPin)
          Center(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _currentMode = ParentAuthMode.signup;
                  _errorMessage = null;
                });
              },
              child: RichText(
                text: const TextSpan(
                  text: "Don't have an Account ? ",
                  style: TextStyle(fontFamily: 'Outfit', color: Colors.grey, fontSize: 13),
                  children: [
                    TextSpan(
                      text: 'Sign up',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: Color(0xFFFC6B6B),
                        fontWeight: FontWeight.w800,
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

  Widget _buildPinKey(String label, VoidCallback onTap, {bool isAction = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF27272A),
          shape: BoxShape.circle,
          border: Border.all(
            color: isAction ? const Color(0xFFFC6B6B).withValues(alpha: 0.5) : const Color(0xFF3F3F46),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: isAction ? 18 : 22,
              fontWeight: FontWeight.w800,
              color: isAction ? const Color(0xFFFC6B6B) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildDarkPinHeaderTitle() {
    String title = 'Parent Access';
    String subtitle = 'Enter 4-digit PIN to unlock access';

    switch (_currentMode) {
      case ParentAuthMode.createPin:
        title = 'Create PIN';
        subtitle = 'Set 4-digit PIN for parent access';
        break;
      case ParentAuthMode.confirmPin:
        title = 'Confirm PIN';
        subtitle = 'Re-enter your 4-digit PIN to confirm';
        break;
      case ParentAuthMode.loginPin:
        title = 'Parent PIN';
        subtitle = 'Enter 4-digit PIN to secure Parent mode';
        break;
      case ParentAuthMode.childLogin:
        title = "Who's playing?";
        subtitle = 'Enter PIN to start learning journey';
        break;
      default:
        break;
    }

    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }

  Widget _buildTransparentPinKey(String label, VoidCallback onTap, {bool isAction = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: isAction ? const Color(0x33FC6B6B) : Colors.white.withValues(alpha: 0.10),
          shape: BoxShape.circle,
          border: Border.all(
            color: isAction ? const Color(0xFFFC6B6B).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.18),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.20),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: isAction ? 18 : 22,
              fontWeight: FontWeight.w800,
              color: isAction ? const Color(0xFFFC6B6B) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF444444),
          ),
        ),
        const SizedBox(height: 3),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: TextStyle(fontFamily: 'Outfit', color: Colors.grey.shade400, fontSize: 12),
              prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 18),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton(String provider, IconData icon, Color color) {
    return InkWell(
      onTap: () => _showComingSoonSnackBar(provider),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(
              provider,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// CustomPainter for Topographic Organic Contour Lines Header Canvas
class _TopographicContourPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path1 = Path();
    path1.moveTo(0, size.height * 0.2);
    path1.cubicTo(
      size.width * 0.3, size.height * 0.1,
      size.width * 0.7, size.height * 0.4,
      size.width, size.height * 0.2,
    );

    final path2 = Path();
    path2.moveTo(0, size.height * 0.5);
    path2.cubicTo(
      size.width * 0.4, size.height * 0.7,
      size.width * 0.6, size.height * 0.3,
      size.width, size.height * 0.6,
    );

    final path3 = Path();
    path3.moveTo(size.width * 0.1, 0);
    path3.cubicTo(
      size.width * 0.5, size.height * 0.5,
      size.width * 0.8, size.height * 0.2,
      size.width, size.height * 0.8,
    );

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
    canvas.drawPath(path3, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
