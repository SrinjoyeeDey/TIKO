import 'package:flutter/material.dart';
import '../widgets/japanese_kungfu_background.dart';
import '../widgets/wooden_back_button.dart';
import '../widgets/wooden_next_button.dart';
import '../widgets/animated_rope_menu.dart';

import 'onboarding_screen.dart';

class CharacterProfileScreen extends StatefulWidget {
  const CharacterProfileScreen({super.key});

  @override
  State<CharacterProfileScreen> createState() => _CharacterProfileScreenState();
}

class _CharacterProfileScreenState extends State<CharacterProfileScreen>
    with SingleTickerProviderStateMixin {
  int _activeTab = 0; // 0: Profile, 1: Log, 2: Achievements
  bool _isAutoEquipped = false;
  late AnimationController _equipAnimController;

  // Equipment Slot States (Slot ID -> IsEquipped)
  final Map<int, bool> _equippedSlots = {
    0: false, // Samurai Helmet
    1: false, // Knight Armor
    2: false, // Boots
    3: false, // Gauntlet
    4: false, // Katana
    5: false, // Ring
  };

  @override
  void initState() {
    super.initState();
    _equipAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _equipAnimController.dispose();
    super.dispose();
  }

  void _toggleAutoEquip() {
    setState(() {
      _isAutoEquipped = !_isAutoEquipped;
      for (int key in _equippedSlots.keys) {
        _equippedSlots[key] = _isAutoEquipped;
      }
    });
    _equipAnimController.forward(from: 0.0);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _isAutoEquipped ? Icons.auto_awesome_rounded : Icons.undo_rounded,
              color: const Color(0xFFFFD54F),
            ),
            const SizedBox(width: 12),
            Text(
              _isAutoEquipped
                  ? 'Auto-Equip Complete! ⚔️✨'
                  : 'Equipment Un-equipped',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF3E2716),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFFFD54F), width: 1.2),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleSingleSlot(int slotIndex) {
    setState(() {
      _equippedSlots[slotIndex] = !(_equippedSlots[slotIndex] ?? false);
      _isAutoEquipped = _equippedSlots.values.every((v) => v);
    });
  }

  void _safePop() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const OnboardingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: JapaneseKungFuBackground(
        showNimoSign: false,
        child: SafeArea(
          child: Stack(
            children: [
              // Main Layout Column
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                child: Column(
                  children: [
                    // 1. TOP CARVED HANGING WOODEN SIGN WITH ROPED KNOTS (No NIMO Sign!)
                    _buildTopHangingWoodPanel(),

                    const SizedBox(height: 6),

                    // 2. MIDDLE SECTION: BIGGER EQUIPMENT SLOTS (No Cat Character!)
                    _buildCloserBiggerEquipmentGrid(),

                    const SizedBox(height: 6),

                    // Bigger Glossy Central Auto-Equip Button: AUTO-EQUIP
                    _buildBiggerGlossyAutoEquipButton(),

                    const SizedBox(height: 8),

                    // 3. EXTENDED PARCHMENT SCROLL WITH FULL HEIGHT GOLDEN CYLINDER HANDLES
                    Expanded(
                      child: _buildExtendedParchmentScrollUI(),
                    ),

                    const SizedBox(height: 8),

                    // 4. CLEAN BOTTOM FOOTER
                    _buildCleanBottomFooter(),
                  ],
                ),
              ),

              // Interactive Suspended Wooden Rope Menu Overlay
              Positioned.fill(
                child: AnimatedRopeMenu(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. TOP CARVED HANGING WOODEN SIGN (Clean Tabs, No Nimo Sign Board)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildTopHangingWoodPanel() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ropes with Tied Knots hanging from top
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            SizedBox(width: 60),
            _TiedRopeStrand(),
            SizedBox(width: 140),
            _TiedRopeStrand(),
            SizedBox(width: 60),
          ],
        ),

        // Suspended Compact Carved Dark Wooden Plank Sign holding tabs
        Container(
          width: 330,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF4A321E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2C1C0F), width: 3.5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTabButton(0, 'PROFILE'),
              _buildTabButton(1, 'LOG'),
              _buildTabButton(2, 'ACHIEVEMENTS'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(int index, String label) {
    final isSelected = _activeTab == index;

    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF9ECC9) : const Color(0xFF332013),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF8D5B2A) : const Color(0xFF5D4037),
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFFFFD54F).withValues(alpha: 0.4),
                blurRadius: 6,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            fontFamily: 'Outfit',
            letterSpacing: 0.8,
            color: isSelected ? const Color(0xFF2C1C0F) : const Color(0xFFD7CCC8),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. BIGGER EQUIPMENT SLOTS BROUGHT CLOSER INWARD (No Cat Character!)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildCloserBiggerEquipmentGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Column
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBiggerEquipmentSlot(0, 'Helmet'),
              const SizedBox(height: 10),
              _buildBiggerEquipmentSlot(1, 'Armor'),
              const SizedBox(height: 10),
              _buildBiggerEquipmentSlot(2, 'Boots'),
            ],
          ),

          // Central Stage Space (Clean Open Lighting Aura, No Cat Character!)
          Expanded(
            child: SizedBox(
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Soft Central Stage Lighting Aura
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFF176).withValues(alpha: 0.08),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD54F).withValues(alpha: 0.15),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right Column
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBiggerEquipmentSlot(3, 'Gauntlet'),
              const SizedBox(height: 10),
              _buildBiggerEquipmentSlot(4, 'Katana', badge: '1'),
              const SizedBox(height: 10),
              _buildBiggerEquipmentSlot(5, 'Ring'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBiggerEquipmentSlot(int slotId, String type, {String? badge}) {
    final isEquipped = _equippedSlots[slotId] ?? false;

    return GestureDetector(
      onTap: () => _toggleSingleSlot(slotId),
      child: AnimatedScale(
        scale: isEquipped ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            color: isEquipped ? const Color(0xFF5C3B1E) : const Color(0xFF2C1C0F),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isEquipped ? const Color(0xFF4ADE80) : const Color(0xFF6E4D31),
              width: isEquipped ? 2.5 : 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isEquipped
                    ? const Color(0xFF4ADE80).withValues(alpha: 0.4)
                    : Colors.black54,
                blurRadius: isEquipped ? 10 : 4,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              _buildSlotSilhouetteIcon(slotId, isEquipped),

              Positioned(
                bottom: 4,
                right: 4,
                child: Icon(
                  isEquipped ? Icons.lock_open_rounded : Icons.lock_rounded,
                  size: 14,
                  color: isEquipped ? const Color(0xFF4ADE80) : const Color(0xFF6E533F),
                ),
              ),

              if (badge != null)
                Positioned(
                  bottom: 3,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlotSilhouetteIcon(int slotId, bool isEquipped) {
    final color = isEquipped ? const Color(0xFF4ADE80) : const Color(0xFF8D6E53);

    switch (slotId) {
      case 0:
        return Icon(Icons.shield_outlined, size: 34, color: color);
      case 1:
        return Icon(Icons.security_rounded, size: 34, color: color);
      case 2:
        return Icon(Icons.directions_walk_rounded, size: 34, color: color);
      case 3:
        return Icon(Icons.back_hand_rounded, size: 34, color: color);
      case 4:
        return Icon(Icons.hardware_rounded, size: 34, color: color);
      case 5:
        return Icon(Icons.radio_button_checked_rounded, size: 34, color: color);
      default:
        return Icon(Icons.shield_rounded, size: 34, color: color);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // CENTRAL BIGGER & GLOSSY AUTO-EQUIP BUTTON
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildBiggerGlossyAutoEquipButton() {
    return GestureDetector(
      onTap: _toggleAutoEquip,
      child: AnimatedScale(
        scale: _isAutoEquipped ? 1.04 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: 190,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFF59E0B),
                Color(0xFFD97706),
                Color(0xFFB45309),
                Color(0xFF78350F),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.4, 0.75, 1.0],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFFF176), width: 2.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
                blurRadius: 14,
                spreadRadius: 2,
              ),
              const BoxShadow(
                color: Colors.black54,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 2,
                left: 12,
                right: 12,
                height: 18,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.40),
                        Colors.white.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.diamond_outlined, size: 16, color: Color(0xFFFFF176)),
                  SizedBox(width: 8),
                  Text(
                    'AUTO-EQUIP',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      fontFamily: 'Outfit',
                      color: Colors.white,
                      shadows: [
                        Shadow(color: Colors.black, offset: Offset(1, 2)),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.diamond_outlined, size: 16, color: Color(0xFFFFF176)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. EXTENDED PARCHMENT SCROLL WITH FULL HEIGHT GOLDEN ROLLER HANDLES
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildExtendedParchmentScrollUI() {
    final atk = _isAutoEquipped ? 1450 : 0;
    final def = _isAutoEquipped ? 820 : 0;
    final hpRegen = _isAutoEquipped ? 150 : 0;
    final critRate = _isAutoEquipped ? 25 : 0;
    final skillCooldown = _isAutoEquipped ? 15 : 0;

    final atkSpeed = _isAutoEquipped ? 35 : 0;
    final maxHp = _isAutoEquipped ? 4850 : 0;
    final skillDmg = _isAutoEquipped ? 50 : 0;
    final critDmg = _isAutoEquipped ? 180 : 0;
    final moveSpeed = _isAutoEquipped ? 120 : 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  padding: const EdgeInsets.fromLTRB(14, 28, 14, 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF9ECC9), Color(0xFFE8D3A7)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF6E4D31), width: 2.2),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatRow('ATTACK', '$atk'),
                            _buildStatRow('DEFENSE', '$def'),
                            _buildStatRow('HP REGEN', '$hpRegen'),
                            _buildStatRow('CRITICAL RATE', '$critRate%'),
                            _buildStatRow('SKILL COOLDOWN', '$skillCooldown%'),
                          ],
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatRow('ATTACK SPEED', '$atkSpeed%'),
                            _buildStatRow('MAX HP', '$maxHp'),
                            _buildStatRow('SKILL DMG', '$skillDmg%'),
                            _buildStatRow('CRIT DMG', '$critDmg%'),
                            _buildStatRow('MOVE SPEED', '$moveSpeed'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Positioned(
                  left: 2,
                  top: -6,
                  bottom: -6,
                  child: _GoldenScrollHandle(isLeft: true),
                ),

                const Positioned(
                  right: 2,
                  top: -6,
                  bottom: -6,
                  child: _GoldenScrollHandle(isLeft: false),
                ),
              ],
            ),
          ),

          Positioned(
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF332317),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF6E4D31), width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'NEXT REWARD IN : XXX HOURS',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: Color(0xFFF3E5AB),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      _RedCrossedSwordsWidget(size: 16),
                      SizedBox(width: 6),
                      Text(
                        '1,459',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFF3E5AB),
                          fontFamily: 'Outfit',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String name, String val) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFD7CCC8), width: 0.8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
                color: Color(0xFF2C1C0F),
                fontFamily: 'Outfit',
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              val,
              key: ValueKey(val),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2C1C0F),
                fontFamily: 'Outfit',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 4. CLEAN BOTTOM FOOTER CONTROLS
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildCleanBottomFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        WoodenBackButton(
          size: 44,
          onTap: _safePop,
        ),

        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF2C1C0F),
              ),
              child: const Icon(Icons.menu_book_rounded, size: 18, color: Color(0xFFFFD54F)),
            ),

            const SizedBox(width: 16),

            Row(
              children: [
                Container(
                  width: 18,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD54F),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Colors.white54,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),

            const SizedBox(width: 16),

            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFD54F),
              ),
              child: const Icon(Icons.card_giftcard_rounded, size: 18, color: Color(0xFF2C1C0F)),
            ),
          ],
        ),

        WoodenNextButton(
          size: 44,
          onTap: _safePop,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GOLDEN SCROLL ROLLER HANDLE PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _GoldenScrollHandle extends StatelessWidget {
  final bool isLeft;

  const _GoldenScrollHandle({this.isLeft = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: double.infinity,
      child: CustomPaint(
        painter: _GoldenScrollHandlePainter(isLeft: isLeft),
      ),
    );
  }
}

class _GoldenScrollHandlePainter extends CustomPainter {
  final bool isLeft;

  _GoldenScrollHandlePainter({this.isLeft = false});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final centerX = w / 2;

    final knobPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF8B6914), Color(0xFFFFF176), Color(0xFFFFD54F), Color(0xFF5D3A1A)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX, 4), width: 12, height: 8),
      knobPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX, 8), width: 16, height: 6),
      knobPaint,
    );

    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX, h - 8), width: 16, height: 6),
      knobPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX, h - 4), width: 12, height: 8),
      knobPaint,
    );

    final shaftRect = Rect.fromLTWH(centerX - 9, 10, 18, h - 20);

    final shaftGradient = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF4A321E),
          Color(0xFF8B6914),
          Color(0xFFFFD54F),
          Color(0xFFFFF9C4),
          Color(0xFFD97706),
          Color(0xFF3E230C),
        ],
        stops: [0.0, 0.15, 0.4, 0.55, 0.8, 1.0],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(shaftRect);

    final shadowPaint = Paint()
      ..color = Colors.black45
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawRRect(
      RRect.fromRectAndRadius(shaftRect, const Radius.circular(9)),
      shadowPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(shaftRect, const Radius.circular(9)),
      shaftGradient,
    );

    final borderPaint = Paint()
      ..color = const Color(0xFF2C1C0F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    canvas.drawRRect(
      RRect.fromRectAndRadius(shaftRect, const Radius.circular(9)),
      borderPaint,
    );

    final filigreePaint = Paint()
      ..color = const Color(0xFF6E4D31)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final filigreeFill = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFF176), Color(0xFFD97706), Color(0xFF5D3A1A)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(centerX - 9, 10, 18, 30));

    final topCapPath = Path()
      ..moveTo(centerX - 9, 10)
      ..lineTo(centerX + 9, 10)
      ..lineTo(centerX + 9, 32)
      ..cubicTo(centerX + 6, 26, centerX, 36, centerX, 36)
      ..cubicTo(centerX, 36, centerX - 6, 26, centerX - 9, 32)
      ..close();

    canvas.drawPath(topCapPath, filigreeFill);
    canvas.drawPath(topCapPath, filigreePaint);

    final bottomCapPath = Path()
      ..moveTo(centerX - 9, h - 10)
      ..lineTo(centerX + 9, h - 10)
      ..lineTo(centerX + 9, h - 32)
      ..cubicTo(centerX + 6, h - 26, centerX, h - 36, centerX, h - 36)
      ..cubicTo(centerX, h - 36, centerX - 6, h - 26, centerX - 9, h - 32)
      ..close();

    canvas.drawPath(bottomCapPath, filigreeFill);
    canvas.drawPath(bottomCapPath, filigreePaint);

    final engravePaint = Paint()
      ..color = const Color(0xFF5D3A1A).withValues(alpha: 0.35)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (double y = 40; y < h - 40; y += 12) {
      canvas.drawLine(Offset(centerX - 7, y), Offset(centerX + 7, y + 6), engravePaint);
      canvas.drawLine(Offset(centerX + 7, y + 2), Offset(centerX - 7, y + 8), engravePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Tied Hemp Rope Strand with Overhand Knot Painter
class _TiedRopeStrand extends StatelessWidget {
  const _TiedRopeStrand();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 38,
      child: CustomPaint(
        painter: _TiedRopeKnotPainter(),
      ),
    );
  }
}

class _TiedRopeKnotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final centerX = w / 2;

    const ropeWidth = 9.0;
    final ropeRect = Rect.fromLTWH(centerX - (ropeWidth / 2), 0, ropeWidth, h);

    final ropeGradient = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFE8D3A7), Color(0xFFC49A6C), Color(0xFF8B6914), Color(0xFF5D4037)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(ropeRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(ropeRect, const Radius.circular(3)),
      ropeGradient,
    );

    final twistPaint = Paint()
      ..color = const Color(0xFF4A321E).withValues(alpha: 0.65)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final highlightPaint = Paint()
      ..color = const Color(0xFFFFF176).withValues(alpha: 0.45)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (double y = 2; y < h; y += 5.5) {
      canvas.drawLine(
        Offset(centerX - (ropeWidth / 2) + 1, y),
        Offset(centerX + (ropeWidth / 2) - 1, y + 4.5),
        twistPaint,
      );
      canvas.drawLine(
        Offset(centerX - (ropeWidth / 2) + 1.5, y + 1.2),
        Offset(centerX + (ropeWidth / 2) - 1.5, y + 5.7),
        highlightPaint,
      );
    }

    const knotY = 16.0;
    final shadowPaint = Paint()
      ..color = Colors.black45
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final knotLoopPath = Path()
      ..moveTo(centerX - 8, knotY - 4)
      ..cubicTo(centerX - 10, knotY + 6, centerX + 10, knotY + 6, centerX + 8, knotY - 4)
      ..cubicTo(centerX + 6, knotY - 10, centerX - 6, knotY - 10, centerX - 8, knotY - 4);

    canvas.drawPath(knotLoopPath.shift(const Offset(1, 2)), shadowPaint);

    final knotGradient = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFF9ECC9), Color(0xFFD4A843), Color(0xFF8B6914)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(centerX - 10, knotY - 10, 20, 20));

    canvas.drawPath(knotLoopPath, knotGradient);

    final knotBorder = Paint()
      ..color = const Color(0xFF4A321E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawPath(knotLoopPath, knotBorder);

    final tailPath = Path()
      ..moveTo(centerX - 5, knotY - 2)
      ..cubicTo(centerX - 12, knotY - 4, centerX - 14, knotY - 12, centerX - 10, knotY - 14)
      ..cubicTo(centerX - 6, knotY - 12, centerX - 5, knotY - 6, centerX - 4, knotY - 2)
      ..close();

    canvas.drawPath(tailPath.shift(const Offset(1, 2)), shadowPaint);
    canvas.drawPath(tailPath, knotGradient);
    canvas.drawPath(tailPath, knotBorder);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Red Crossed Swords Battle Emblem Widget
class _RedCrossedSwordsWidget extends StatelessWidget {
  final double size;

  const _RedCrossedSwordsWidget({this.size = 16});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _RedCrossedSwordsPainter(),
    );
  }
}

class _RedCrossedSwordsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawCircle(
      Offset(w / 2, h / 2),
      w / 2,
      Paint()..color = const Color(0xFFC0392B),
    );

    final swordPaint = Paint()
      ..color = const Color(0xFFFFF176)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(w * 0.25, h * 0.25), Offset(w * 0.75, h * 0.75), swordPaint);
    canvas.drawLine(Offset(w * 0.75, h * 0.25), Offset(w * 0.25, h * 0.75), swordPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
