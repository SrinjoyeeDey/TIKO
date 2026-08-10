import 'package:flutter/material.dart';
import '../models/journey_destination.dart';

/// Cinematic Title Banner displaying origin quote ("Every journey begins somewhere.")
/// and destination title ("YOUR JOURNEY BEGINS IN INDIA", "CALCUTTA").
class JourneyTitle extends StatelessWidget {
  final JourneyDestination destination;
  final double opacity;
  final double slideOffset;
  final bool showDestinationText;

  const JourneyTitle({
    super.key,
    required this.destination,
    required this.opacity,
    required this.slideOffset,
    this.showDestinationText = true,
  });

  @override
  Widget build(BuildContext context) {
    if (opacity <= 0.001) return const SizedBox.shrink();

    final titleText = showDestinationText
        ? destination.title.toUpperCase()
        : destination.originQuote;

    final subtext = showDestinationText
        ? destination.city.toUpperCase()
        : '${destination.originCountry} 🇯🇵';

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 350),
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(0, slideOffset),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: const Color(0xFF0D111A).withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFFD54F).withValues(alpha: 0.80),
              width: 1.8,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tag: "FIRST DESTINATION" or "JAPAN ORIGIN"
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF161F33),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: showDestinationText ? const Color(0xFF00E5FF) : const Color(0xFFFFD54F),
                    width: 1.0,
                  ),
                ),
                child: Text(
                  showDestinationText
                      ? destination.subtitle.toUpperCase()
                      : 'JAPAN ORIGIN 🇯🇵',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.2,
                    color: showDestinationText ? const Color(0xFF00E5FF) : const Color(0xFFFFD54F),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Title Text
              Text(
                titleText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: Color(0xFFFFF176),
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      offset: Offset(1.5, 1.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              // City/Country Subtext
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: showDestinationText ? const Color(0xFFFFD54F) : const Color(0xFFD32F2F),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    subtext,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                      color: Color(0xFFF4E8C1),
                    ),
                  ),
                ],
              ),

              if (showDestinationText) ...[
                const SizedBox(height: 6),
                Text(
                  destination.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
