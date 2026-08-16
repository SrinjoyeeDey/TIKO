/// Abstract interface for activity input sources.
/// Prepares Catch NIMO for Touch, Voice, Vision, or ESP32 Hardware inputs.
abstract class InputSource {
  void initialize();
  void dispose();
}

class TouchInputSource implements InputSource {
  @override
  void initialize() {}
  @override
  void dispose() {}
}

class VoiceInputSource implements InputSource {
  @override
  void initialize() {}
  @override
  void dispose() {}
}

class HardwareInputSource implements InputSource {
  @override
  void initialize() {}
  @override
  void dispose() {}
}
