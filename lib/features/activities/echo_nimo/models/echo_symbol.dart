import 'package:flutter/material.dart';

/// NIMO Echo Pads representing visual symbols & audio pitch frequencies.
enum EchoSymbol {
  cyan,
  purple,
  yellow,
  green,
  coral,
}

extension EchoSymbolExtension on EchoSymbol {
  String get id => name;

  String get displayName {
    switch (this) {
      case EchoSymbol.cyan: return 'CYAN';
      case EchoSymbol.purple: return 'PURPLE';
      case EchoSymbol.yellow: return 'YELLOW';
      case EchoSymbol.green: return 'GREEN';
      case EchoSymbol.coral: return 'CORAL';
    }
  }

  Color get color {
    switch (this) {
      case EchoSymbol.cyan: return const Color(0xFF00F2FE);
      case EchoSymbol.purple: return const Color(0xFFA855F7);
      case EchoSymbol.yellow: return const Color(0xFFFFBF27);
      case EchoSymbol.green: return const Color(0xFF85D64B);
      case EchoSymbol.coral: return const Color(0xFFFF3B63);
    }
  }

  Color get darkBevelColor {
    switch (this) {
      case EchoSymbol.cyan: return const Color(0xFF0096C7);
      case EchoSymbol.purple: return const Color(0xFF7C23D4);
      case EchoSymbol.yellow: return const Color(0xFFE89B00);
      case EchoSymbol.green: return const Color(0xFF4F8528);
      case EchoSymbol.coral: return const Color(0xFFCC1A40);
    }
  }

  /// Synthesizer Tone Frequency (Hz)
  double get pitchFrequency {
    switch (this) {
      case EchoSymbol.cyan: return 261.63;   // C4
      case EchoSymbol.purple: return 329.63; // E4
      case EchoSymbol.yellow: return 392.00; // G4
      case EchoSymbol.green: return 523.25;  // C5
      case EchoSymbol.coral: return 659.25;  // E5
    }
  }

  IconData get icon {
    switch (this) {
      case EchoSymbol.cyan: return Icons.water_drop_rounded;
      case EchoSymbol.purple: return Icons.bolt_rounded;
      case EchoSymbol.yellow: return Icons.star_rounded;
      case EchoSymbol.green: return Icons.eco_rounded;
      case EchoSymbol.coral: return Icons.local_fire_department_rounded;
    }
  }
}
