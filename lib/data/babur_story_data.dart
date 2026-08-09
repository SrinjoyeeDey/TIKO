import 'package:flutter/material.dart';
import '../models/story_chapter.dart';

class BaburStoryData {
  static List<StoryChapter> getInitialChapters() {
    return [
      StoryChapter(
        id: 1,
        title: 'Origins',
        subtitle: 'The Valley of Fergana (1483)',
        summary: 'Zahir-ud-din Muhammad, known as Babur, was born in Fergana in Central Asia.',
        icon: Icons.castle_rounded,
        fullStoryText:
            'Zahir-ud-din Muhammad Babur was born in 1483 in the valley of Fergana (modern Uzbekistan). '
            'A direct descendant of Timur on his father\'s side and Genghis Khan on his mother\'s side, young Babur '
            'inherited a passion for learning, poetry, and leadership from an early age.',
        historicalContext:
            'Fergana was a fertile mountain valley along the Silk Road, rich in orchards, rivers, and ancient commerce.',
        keyTakeaway: 'Great leadership begins with a deep love for knowledge, nature, and resilience.',
        status: ChapterStatus.available, // Chapter 1 starts available!
      ),
      StoryChapter(
        id: 2,
        title: 'The Young Prince',
        subtitle: 'Ascending the Throne (1494)',
        summary: 'At just 12 years old, Babur inherited the throne of Fergana after his father\'s death.',
        icon: Icons.workspace_premium_rounded,
        fullStoryText:
            'In 1494, following his father Umar Shaikh Mirza\'s unexpected death, 12-year-old Babur ascended the throne of Fergana. '
            'Surrounded by ambitious uncles and rival warlords, the young prince learned diplomacy, courage, and quick thinking.',
        historicalContext:
            'The Timurid dynasties of Central Asia were fiercely competitive, with prince contesting prince for city-states.',
        keyTakeaway: 'Courage and clear judgment are crucial when facing sudden responsibility.',
        status: ChapterStatus.locked,
      ),
      StoryChapter(
        id: 3,
        title: 'Samarkand',
        subtitle: 'The Jewel of the Silk Road',
        summary: 'Babur captured Samarkand at age 14, enduring fierce sieges and conquests.',
        icon: Icons.fort_rounded,
        fullStoryText:
            'Fascinated by the majestic city of Samarkand built by his ancestor Timur, Babur set out to capture it. '
            'He successfully claimed the city at age 14, but held it for only 100 days before rivals seized Fergana in his absence.',
        historicalContext:
            'Samarkand was famed for its grand turquoise domes, observatory, and bustling markets of turquoise and silk.',
        keyTakeaway: 'Setbacks are temporary detours on the path to master craft and wisdom.',
        status: ChapterStatus.locked,
      ),
      StoryChapter(
        id: 4,
        title: 'Road to Kabul',
        subtitle: 'Crossing the Hindu Kush (1504)',
        summary: 'Undaunted by defeat, Babur led his loyal followers across snowy mountain passes to Kabul.',
        icon: Icons.landscape_rounded,
        fullStoryText:
            'Losing both Fergana and Samarkand, Babur refused to break. Leading a small group of loyal followers through the snowy '
            'Hindu Kush mountains, he captured Kabul in 1504, founding a peaceful new mountain stronghold.',
        historicalContext:
            'Kabul was a strategic trade crossroad connecting Central Asia with Northern India.',
        keyTakeaway: 'A true leader keeps hope alive even when everything seems lost.',
        status: ChapterStatus.locked,
      ),
      StoryChapter(
        id: 5,
        title: 'Building an Army',
        subtitle: 'Innovations & Artillery',
        summary: 'Babur modernized his army, combining cavalry archers with early artillery.',
        icon: Icons.shield_rounded,
        fullStoryText:
            'In Kabul, Babur spent two decades mastering tactical warfare. He combined swift cavalry tactics with new matchlock firearms '
            'and mobile field artillery, creating one of the most disciplined forces of his era.',
        historicalContext:
            'The early 16th century marked the rise of gunpowder empires in Asia.',
        keyTakeaway: 'Combining tradition with modern innovation creates lasting strength.',
        status: ChapterStatus.locked,
      ),
      StoryChapter(
        id: 6,
        title: 'Journey to India',
        subtitle: 'Descending to the Plains (1525)',
        summary: 'Babur marched south across the Indus River into the heart of Northern India.',
        icon: Icons.explore_rounded,
        fullStoryText:
            'Invited by noblemen seeking relief from local turmoil, Babur led five expeditions into India. '
            'His memoirs record his wonder at India\'s vast rivers, diverse wildlife, monsoon rains, and rich heritage.',
        historicalContext:
            'The Baburnama is one of history\'s finest autobiographies, documenting nature, animals, and geography.',
        keyTakeaway: 'Curiosity and respect for new lands enrich every adventure.',
        status: ChapterStatus.locked,
      ),
      StoryChapter(
        id: 7,
        title: 'Panipat',
        subtitle: 'The Turning Point (1526)',
        summary: 'At Panipat, Babur\'s tactical genius defeated a far larger army.',
        icon: Icons.military_tech_rounded,
        fullStoryText:
            'On April 21, 1526, on the plains of Panipat, Babur\'s 12,000 soldiers faced Ibrahim Lodi\'s army of 100,000. '
            'Using the Ottoman cart-barricade formation (Tulughma), Babur achieved a decisive victory that changed world history.',
        historicalContext:
            'The Battle of Panipat marks the official founding of the Mughal Empire in South Asia.',
        keyTakeaway: 'Strategy and coordination triumph over overwhelming odds.',
        status: ChapterStatus.locked,
      ),
      StoryChapter(
        id: 8,
        title: 'Victory',
        subtitle: 'Securing the Realm (1527)',
        summary: 'Babur secured his kingdom at Khanwa, demonstrating steadfast resolve.',
        icon: Icons.emoji_events_rounded,
        fullStoryText:
            'Facing the formidable confederators led by Rana Sanga at Khanwa in 1527, Babur inspired his men with eloquence and personal example. '
            'His victory secured his domain across Northern India.',
        historicalContext:
            'After victory, Babur laid out formal Persian-style quadrangle gardens (Charbagh) in Agra and Dholpur.',
        keyTakeaway: 'True triumph comes from inspiring others with integrity and vision.',
        status: ChapterStatus.locked,
      ),
      StoryChapter(
        id: 9,
        title: 'A New Empire',
        subtitle: 'Legacy of Art & Culture (1530)',
        summary: 'Babur established a legacy of literature, architecture, and enduring culture.',
        icon: Icons.auto_awesome_rounded,
        fullStoryText:
            'Babur spent his final years establishing administrative harmony, planting lush gardens, and finishing his memoir, the Baburnama. '
            'His empire endured for over three centuries, fostering rich art, architecture, and cultural exchange.',
        historicalContext:
            'Babur\'s descendants would build iconic wonders like the Taj Mahal and Fatehpur Sikri.',
        keyTakeaway: 'The greatest legacy a ruler leaves is peace, beauty, and education for generations.',
        status: ChapterStatus.locked,
      ),
    ];
  }

  static String getTreasureTitle() => 'MYSTERY TREASURE OF BABUR';
  static String getTreasureDescription() =>
      'You have unlocked the Royal Imperial Seal & The Royal Library of Babur! '
      'You are now a Grand Explorer of History!';
}
