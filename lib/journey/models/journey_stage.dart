/// Stage state enum controlling the multi-phase cinematic intro sequence:
/// 1. unfolding (Stage 1: 3D parchment opens)
/// 2. worldMapRevealed (Stage 2: Recognizable World Map with Japan origin)
/// 3. indiaIlluminated (Stage 3: India lights up on World Map + "ENTER INDIA →" button)
/// 4. enteringIndia (Stage 4: Camera zooms into India)
/// 5. detailedIndiaMap (Stage 5 & 6: Detailed India map from GeoJSON dataset appears)
/// 6. finalDestination (Stage 7: Calcutta highlighted + "YOUR JOURNEY BEGINS IN INDIA" + "PROCEED →")
enum JourneyStage {
  unfolding,
  worldMapRevealed,
  indiaIlluminated,
  enteringIndia,
  detailedIndiaMap,
  finalDestination,
}
