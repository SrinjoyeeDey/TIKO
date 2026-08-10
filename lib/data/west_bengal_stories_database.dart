import '../models/interactive_story_models.dart';

/// Database of stories for Indian states.
class IndianStoriesDatabase {
  static final Map<String, StateStoriesCollection> _collections = {
    'west_bengal': StateStoriesCollection(
      stateId: 'west_bengal',
      stateName: 'West Bengal',
      tagline: 'A land of stories, courage and discovery.',
      atmosphericImage: 'assets/images/nimo_japanese_bg_clean.png',
      stories: [
        // Story 1: Swami Vivekananda
        StoryData(
          id: 'vivekananda',
          stateId: 'west_bengal',
          title: 'The Boy Who Found His Voice',
          subtitle: 'Swami Vivekananda',
          taglineOrQuote: '“Arise, awake, and stop not till the goal is reached.”',
          imagePath: 'assets/images/story_vivekananda.png',
          scenes: const [
            StoryScene(
              id: 's1',
              narrativeText:
                  'In 19th-century Kolkata, a young boy named Narendranath was filled with endless curiosity about truth, courage, and the world.',
              imagePath: 'assets/images/story_vivekananda.png',
              historicalFact:
                  'Young Narendra loved reading books on philosophy, history, and science in Kolkata.',
              choices: [
                SceneChoice(label: 'Explore his journey', nextSceneId: 's2'),
              ],
            ),
            StoryScene(
              id: 's2',
              narrativeText:
                  'He met Ramakrishna Paramahamsa and learned that true strength comes from serving humanity and discovering one\'s inner voice.',
              imagePath: 'assets/images/story_vivekananda.png',
              choices: [
                SceneChoice(label: 'Travel to Chicago 1893', nextSceneId: 's3'),
              ],
            ),
            StoryScene(
              id: 's3',
              narrativeText:
                  'At the Parliament of Religions in Chicago, he spoke with profound wisdom, inspiring millions with "Sisters and brothers of America!"',
              imagePath: 'assets/images/story_vivekananda.png',
              historicalFact:
                  'His historic speech in 1893 brought Indian spiritual wisdom and universal brotherhood to the global stage.',
            ),
          ],
        ),

        // Story 2: Netaji Subhas Chandra Bose
        StoryData(
          id: 'netaji',
          stateId: 'west_bengal',
          title: 'Netaji: The Call of Freedom',
          subtitle: 'Subhas Chandra Bose',
          taglineOrQuote: '“Give me blood, and I shall give you freedom!”',
          imagePath: 'assets/images/story_netaji.png',
          scenes: const [
            StoryScene(
              id: 's1',
              narrativeText:
                  'Born in Cuttack, Odisha, Subhas Chandra Bose came to Kolkata for his studies. He possessed unyielding courage and a dream for a free India.',
              imagePath: 'assets/images/story_netaji.png',
              historicalFact:
                  'Though born in Cuttack, Kolkata was the central hub of Subhas Bose\'s higher education, political leadership, and nationalist activities.',
              choices: [
                SceneChoice(label: 'Follow the struggle for freedom', nextSceneId: 's2'),
              ],
            ),
            StoryScene(
              id: 's2',
              narrativeText:
                  'Subhas Bose inspired thousands of young Indians across Kolkata and Bengal with his fearless leadership and devotion to the motherland.',
              imagePath: 'assets/images/story_netaji.png',
              choices: [
                SceneChoice(label: 'Form the Indian National Army', nextSceneId: 's3'),
              ],
            ),
            StoryScene(
              id: 's3',
              narrativeText:
                  'He founded the Indian National Army (Azad Hind Fauj) and rallied patriots with the powerful chant "Jai Hind!"',
              imagePath: 'assets/images/story_netaji.png',
              historicalFact:
                  'Netaji\'s patriotism and supreme sacrifice remain a beacon of courage in Indian history.',
            ),
          ],
        ),

        // Story 3: British Power in Calcutta
        StoryData(
          id: 'british_power',
          stateId: 'west_bengal',
          title: 'The City at the Heart of Power',
          subtitle: 'Calcutta & British India',
          taglineOrQuote: '“How a riverside port became the capital of British India.”',
          imagePath: 'assets/images/story_british_india.png',
          scenes: const [
            StoryScene(
              id: 's1',
              narrativeText:
                  'Along the banks of the Hooghly River, Calcutta transformed from three small villages into a major trading hub for the East India Company.',
              imagePath: 'assets/images/story_british_india.png',
              historicalFact:
                  'After the Battle of Plassey in 1757, East India Company established strong political foothold in Bengal.',
              choices: [
                SceneChoice(label: 'Learn about the capital', nextSceneId: 's2'),
              ],
            ),
            StoryScene(
              id: 's2',
              narrativeText:
                  'From 1772 to 1911, Calcutta served as the capital of British India before the capital was shifted to New Delhi.',
              imagePath: 'assets/images/story_british_india.png',
              historicalFact:
                  'Calcutta grew into a magnificent city of grand architecture, trade ships, and rich cultural interactions.',
            ),
          ],
        ),

        // Story 4: Bengal Renaissance
        StoryData(
          id: 'bengal_renaissance',
          stateId: 'west_bengal',
          title: 'Awakening of Ideas',
          subtitle: 'The Bengal Renaissance',
          taglineOrQuote: '“When literature, art, and science transformed a nation.”',
          imagePath: 'assets/images/story_bengal_renaissance.png',
          scenes: const [
            StoryScene(
              id: 's1',
              narrativeText:
                  'In 19th-century Bengal, a wave of new ideas swept through education, literature, science, and social reform.',
              imagePath: 'assets/images/story_bengal_renaissance.png',
              historicalFact:
                  'Thinkers like Raja Ram Mohan Roy, Ishwar Chandra Vidyasagar, and Rabindranath Tagore led this cultural transformation.',
              choices: [
                SceneChoice(label: 'Discover the awakening', nextSceneId: 's2'),
              ],
            ),
            StoryScene(
              id: 's2',
              narrativeText:
                  'Poetry, art, women\'s education, and scientific discoveries ignited a national pride that reshaped modern India.',
              imagePath: 'assets/images/story_bengal_renaissance.png',
              historicalFact:
                  'The Bengal Renaissance laid the intellectual foundations for India\'s national freedom movement.',
            ),
          ],
        ),
      ],
    ),
  };

  static StateStoriesCollection? getCollectionForState(String stateId) {
    return _collections[stateId.toLowerCase()] ?? _collections['west_bengal'];
  }

  static void markStoryCompleted(String storyId) {
    for (final col in _collections.values) {
      for (final story in col.stories) {
        if (story.id == storyId) {
          story.isCompleted = true;
        }
      }
    }
  }
}
