import 'package:flutter/material.dart';

/// Data model representing a journey transition from an origin country to a destination.
/// Default flow: Japan (Origin) -> India / Calcutta (Destination).
class JourneyDestination {
  final String originCountry;
  final String originCity;
  final String originQuote;
  final Offset originRelativeCoord;

  final String country;
  final String city;
  final String title;
  final String subtitle;
  final String description;
  final String storyId;
  final Offset relativeTargetCoord;

  final String? mapAsset;
  final String? markerAsset;
  final List<Color> themeGradients;

  const JourneyDestination({
    required this.originCountry,
    required this.originCity,
    required this.originQuote,
    required this.originRelativeCoord,
    required this.country,
    required this.city,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.storyId,
    required this.relativeTargetCoord,
    this.mapAsset,
    this.markerAsset,
    this.themeGradients = const [
      Color(0xFF0D111A), // Deep indigo
      Color(0xFF161F33), // Midnight blue
      Color(0xFF222E47), // Washi paper shadow
    ],
  });

  /// Default initial journey flow: Japan -> India / Calcutta
  static const JourneyDestination japanToIndia = JourneyDestination(
    originCountry: 'Japan',
    originCity: 'Kyoto',
    originQuote: '',
    originRelativeCoord: Offset(
      0.86,
      0.40,
    ), // Location of Japan on world canvas
    country: 'India',
    city: 'Calcutta',
    title: 'YOUR JOURNEY BEGINS IN INDIA',
    subtitle: 'FIRST DESTINATION',
    description:
        'Discover the history, people and stories that shaped this place.',
    storyId: 'babur_story',
    relativeTargetCoord: Offset(
      0.66,
      0.52,
    ), // Location of Calcutta on world canvas
  );
}
