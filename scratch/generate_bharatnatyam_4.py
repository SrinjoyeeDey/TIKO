import json

def create_bharatnatyam_4():
    data = {
      "title": "Closing Salutation (Tap and Salute) and Practice Principles in Bharatanatyam",
      "section": {
        "start": "00:00",
        "end": "01:55",
        "description": "Comprehensive 45-question pedagogical assessment for ages 3 to 15 spanning Easy, Moderate, and Hard difficulty levels."
      },
      "target_age": 12,
      "age_range": "3-15 years",
      "question_pattern": {
        "main_questions": "45 progressive questions consisting of multi-tier MCQs, conceptual descriptive questions, and voice pronunciation speech questions.",
        "difficulty_distribution": "15 Easy (Ages 3-7), 15 Moderate (Ages 8-11), 15 Hard (Ages 12-15)",
        "descriptive_evaluation": "Cosine similarity comparison against core semantic key concepts.",
        "speech_evaluation": "Voice audio recognition calculating pronunciation accuracy and token alignment.",
        "sequence_test": "Chronological milestone ordering and sequence analysis.",
        "image_matching": "Interactive visual matching connecting postures, terms, and descriptions."
      },
      "questions": [
        # EASY (1-15)
        {
          "id": 1,
          "type": "mcq",
          "question": "What is the closing salutation in Bharatanatyam also called?",
          "options": {
            "A": "Tap and salute",
            "B": "Jump and shout",
            "C": "Spin and bow",
            "D": "Run and freeze"
          },
          "answer": "A",
          "answer_text": "The salutation in Bharatanatyam is also popularly called a 'tap and salute'.",
          "difficulty": "easy",
          "difficulty_percentage": 20,
          "difficulty_level": "Gentle Starter",
          "target_age_group": "3-7 years"
        },
        {
          "id": 2,
          "type": "mcq",
          "question": "Which foot does the dancer strike first when starting the tap and salute?",
          "options": {
            "A": "Right foot (one strike)",
            "B": "Left foot",
            "C": "Both feet together",
            "D": "Neither foot"
          },
          "answer": "A",
          "answer_text": "The dancer begins in Samapadam with hands in front of the chest and strikes the right foot once.",
          "difficulty": "easy",
          "difficulty_percentage": 20,
          "difficulty_level": "Gentle Starter",
          "target_age_group": "3-7 years"
        },
        {
          "id": 3,
          "type": "mcq",
          "question": "What deep sitting posture does the dancer take after striking the foot in the salutation?",
          "options": {
            "A": "Full Mandi (deep squat to the floor)",
            "B": "Standing on one toe",
            "C": "Lying down flat",
            "D": "Sitting on a wooden bench"
          },
          "answer": "A",
          "answer_text": "The dancer brings the hands down and sits in full mandi (deep squat).",
          "difficulty": "easy",
          "difficulty_percentage": 25,
          "difficulty_level": "Gentle Starter",
          "target_age_group": "3-7 years"
        },
        {
          "id": 4,
          "type": "mcq",
          "question": "What does the dancer touch when sitting in full mandi to pay respects to Mother Earth?",
          "options": {
            "A": "Touches the floor and then touches the eyes",
            "B": "Touches the knees only",
            "C": "Touches their shoes",
            "D": "Touches the stage curtain"
          },
          "answer": "A",
          "answer_text": "The dancer touches the sacred floor (Mother Earth) and then touches their eyes with reverence.",
          "difficulty": "easy",
          "difficulty_percentage": 20,
          "difficulty_level": "Gentle Starter",
          "target_age_group": "3-7 years"
        },
        {
          "id": 5,
          "type": "mcq",
          "question": "Where does the dancer place their hands to make a salute to God?",
          "options": {
            "A": "On top of the head",
            "B": "On their knees",
            "C": "Behind the back",
            "D": "In their pockets"
          },
          "answer": "A",
          "answer_text": "The dancer salutes God by placing hands together on top of the head.",
          "difficulty": "easy",
          "difficulty_percentage": 25,
          "difficulty_level": "Gentle Starter",
          "target_age_group": "3-7 years"
        },
        {
          "id": 6,
          "type": "mcq",
          "question": "Where does the dancer place their hands to salute the guru (teacher)?",
          "options": {
            "A": "In front of the forehead",
            "B": "On the floor",
            "C": "Behind the ears",
            "D": "On the feet"
          },
          "answer": "A",
          "answer_text": "The dancer salutes the guru/teacher with hands placed in front of the forehead.",
          "difficulty": "easy",
          "difficulty_percentage": 25,
          "difficulty_level": "Gentle Starter",
          "target_age_group": "3-7 years"
        },
        {
          "id": 7,
          "type": "mcq",
          "question": "Where does the dancer place their hands to salute the audience?",
          "options": {
            "A": "In front of the chest",
            "B": "On top of the head",
            "C": "Under the chin",
            "D": "Above the knees"
          },
          "answer": "A",
          "answer_text": "The dancer salutes the audience by bringing the folded hands to the center of the chest.",
          "difficulty": "easy",
          "difficulty_percentage": 25,
          "difficulty_level": "Gentle Starter",
          "target_age_group": "3-7 years"
        },
        {
          "id": 8,
          "type": "mcq",
          "question": "What Tamil word meaning 'Thank you' is spoken at the end of the lesson?",
          "options": {
            "A": "Nandri",
            "B": "Namaste",
            "C": "Shukriya",
            "D": "Dhanyavad"
          },
          "answer": "A",
          "answer_text": "The teacher concludes the lesson saying 'Nandri', which means thank you in Tamil.",
          "difficulty": "easy",
          "difficulty_percentage": 25,
          "difficulty_level": "Gentle Starter",
          "target_age_group": "3-7 years"
        },
        {
          "id": 9,
          "type": "mcq",
          "question": "What important health and safety advice does the teacher give about stretching?",
          "options": {
            "A": "Always stretch before and after every dance lesson",
            "B": "Never stretch because it is not needed",
            "C": "Stretch only once a month",
            "D": "Only stretch after eating lunch"
          },
          "answer": "A",
          "answer_text": "The teacher reminds learners to always stretch before and after every lesson.",
          "difficulty": "easy",
          "difficulty_percentage": 25,
          "difficulty_level": "Gentle Starter",
          "target_age_group": "3-7 years"
        },
        {
          "id": 10,
          "type": "mcq",
          "question": "Is the tap and salute practice followed in other Indian classical art forms too?",
          "options": {
            "A": "Yes, it is followed in pretty much all Indian classical art forms",
            "B": "No, it is only done in modern gymnastics",
            "C": "It is only done in foreign countries",
            "D": "No other art form ever salutes"
          },
          "answer": "A",
          "answer_text": "Saluting Mother Earth, God, Teacher, and audience is an ancient tradition across Indian classical art forms.",
          "difficulty": "easy",
          "difficulty_percentage": 30,
          "difficulty_level": "Gentle Starter",
          "target_age_group": "3-7 years"
        },
        {
          "id": 11,
          "type": "descriptive",
          "question": "Describe the complete step-by-step process of the tap and salute in Bharatanatyam.",
          "reference_answer": "In Samapadam with hands at chest, strike the right foot once, sit in full mandi, touch the floor and touch the eyes for Mother Earth, salute God (hands above head), salute Guru (hands at forehead), and salute the audience (hands at chest).",
          "key_concepts": ["Samapadam hands at chest", "strike right foot once", "full mandi", "touch floor and eyes for Mother Earth", "salute God above head", "salute Guru at forehead", "salute audience at chest"],
          "cosine_similarity_threshold": 0.55,
          "difficulty": "easy",
          "difficulty_percentage": 30,
          "difficulty_level": "Gentle Starter",
          "target_age_group": "3-7 years"
        },
        {
          "id": 12,
          "type": "descriptive",
          "question": "What practical advice does the teacher share for students who want to keep learning Bharatanatyam?",
          "reference_answer": "The teacher advises students to practice adavus and postures in different speeds, and always remember to stretch before and after every lesson.",
          "key_concepts": ["practice adavus and postures", "different speeds", "stretch before and after every lesson"],
          "cosine_similarity_threshold": 0.55,
          "difficulty": "easy",
          "difficulty_percentage": 30,
          "difficulty_level": "Gentle Starter",
          "target_age_group": "3-7 years"
        },
        {
          "id": 13,
          "type": "speech",
          "question": "Say the Tamil word meaning thank you used at the end of the lesson:",
          "target_phrase": "Nandri Thank You",
          "reference_answer": "Nandri Thank You",
          "key_concepts": ["Nandri", "Thank", "You"],
          "min_score_threshold": 65,
          "difficulty": "easy",
          "difficulty_percentage": 25,
          "difficulty_level": "Gentle Starter",
          "target_age_group": "3-7 years"
        },
        {
          "id": 14,
          "type": "speech",
          "question": "Say the alternative name for the salutation:",
          "target_phrase": "Tap and Salute",
          "reference_answer": "Tap and Salute",
          "key_concepts": ["Tap", "Salute"],
          "min_score_threshold": 65,
          "difficulty": "easy",
          "difficulty_percentage": 25,
          "difficulty_level": "Gentle Starter",
          "target_age_group": "3-7 years"
        },
        {
          "id": 15,
          "type": "speech",
          "question": "Say the deep squat posture taken during the salutation:",
          "target_phrase": "Full Mandi Posture",
          "reference_answer": "Full Mandi Posture",
          "key_concepts": ["Full", "Mandi", "Posture"],
          "min_score_threshold": 65,
          "difficulty": "easy",
          "difficulty_percentage": 30,
          "difficulty_level": "Gentle Starter",
          "target_age_group": "3-7 years"
        },

        # MODERATE (16-30)
        {
          "id": 16,
          "type": "mcq",
          "question": "Why does a classical dancer touch the floor and then touch the eyes during the salutation?",
          "options": {
            "A": "To seek forgiveness and blessings from Mother Earth (Bhumi Devi) for stamping upon her during the dance",
            "B": "To clean the dust off their hands",
            "C": "To check if the stage floor is made of wood or stone",
            "D": "To look for fallen jewelry on the floor"
          },
          "answer": "A",
          "answer_text": "Touching the earth and eyes is a sacred gesture of reverence and asking Mother Earth's pardon for striking her with feet.",
          "difficulty": "moderate",
          "difficulty_percentage": 50,
          "difficulty_level": "Curious Adventurer",
          "target_age_group": "8-11 years"
        },
        {
          "id": 17,
          "type": "mcq",
          "question": "What is the specific anatomical positioning of the three salutes performed from Full Mandi?",
          "options": {
            "A": "Hands on top of the head for God, in front of the forehead for the Guru, and in front of the chest for the audience",
            "B": "Hands on the feet for God, on the waist for Guru, and above the head for audience",
            "C": "Hands covering the ears, eyes, and mouth",
            "D": "Hands behind the back for all three salutes"
          },
          "answer": "A",
          "answer_text": "The sequence moves hierarchically: Crown of head (God) -> Forehead / Third Eye (Guru) -> Heart / Chest (Audience).",
          "difficulty": "moderate",
          "difficulty_percentage": 55,
          "difficulty_level": "Curious Adventurer",
          "target_age_group": "8-11 years"
        },
        {
          "id": 18,
          "type": "mcq",
          "question": "What distinguishes the 'Full Mandi' posture from the 'Aramandi' posture learned earlier?",
          "options": {
            "A": "Full Mandi is a complete deep squat where the thighs rest on the calves, while Aramandi is a half-squat",
            "B": "Full Mandi is standing upright while Aramandi is lying down",
            "C": "Full Mandi is jumping in the air while Aramandi is sitting on a chair",
            "D": "There is no difference between Full Mandi and Aramandi"
          },
          "answer": "A",
          "answer_text": "Aramandi is a half-squat (demi-plié); Full Mandi (Muzhumandi) is a full deep squat to the ground with heels raised and knees wide.",
          "difficulty": "moderate",
          "difficulty_percentage": 55,
          "difficulty_level": "Curious Adventurer",
          "target_age_group": "8-11 years"
        },
        {
          "id": 19,
          "type": "mcq",
          "question": "Why is stretching before and after every dance session medically and physically important for dancers?",
          "options": {
            "A": "It warms up muscles, prevents muscle cramps and joint injuries, and aids in faster recovery after rigorous foot strikes",
            "B": "It allows the dancer to grow taller overnight",
            "C": "It replaces the need to practice adavus",
            "D": "It makes the music sound clearer"
          },
          "answer": "A",
          "answer_text": "Pre- and post-session stretching increases muscular flexibility, prevents tendon strain, and promotes joint health.",
          "difficulty": "moderate",
          "difficulty_percentage": 50,
          "difficulty_level": "Curious Adventurer",
          "target_age_group": "8-11 years"
        },
        {
          "id": 20,
          "type": "mcq",
          "question": "How does the closing salutation reinforce the student-teacher relationship (Guru-Shishya parampara)?",
          "options": {
            "A": "By dedicating a specific reverence gesture at the forehead to the teacher in gratitude for transmitted knowledge",
            "B": "By asking the teacher to grade the student with test marks",
            "C": "By having the student teach the teacher a new dance",
            "D": "By paying cash directly into the teacher's hand"
          },
          "answer": "A",
          "answer_text": "Saluting the Guru at the forehead honors the intellectual and spiritual transmission of classical knowledge.",
          "difficulty": "moderate",
          "difficulty_percentage": 55,
          "difficulty_level": "Curious Adventurer",
          "target_age_group": "8-11 years"
        },
        {
          "id": 21,
          "type": "mcq",
          "question": "What online educational arts collection created this instructional series?",
          "options": {
            "A": "Kennedy Center Education's Teaching Artists Present collection",
            "B": "London Royal Academy of Music",
            "C": "National Geographic Explorer Series",
            "D": "Smithsonian Science Lab"
          },
          "answer": "A",
          "answer_text": "The video is presented by the Kennedy Center Education's Teaching Artists Present collection featuring dancer Deepa Mani.",
          "difficulty": "moderate",
          "difficulty_percentage": 50,
          "difficulty_level": "Curious Adventurer",
          "target_age_group": "8-11 years"
        },
        {
          "id": 22,
          "type": "mcq",
          "question": "Why is performing the tap and salute before AND after a lesson considered a complete ritual frame?",
          "options": {
            "A": "The opening salutation invites blessings and focus, while the closing salutation seals the practice with gratitude and humility",
            "B": "Because dancers are required to perform it twice to remember the steps",
            "C": "It is done twice only if the dancer makes a mistake",
            "D": "The second salutation cancels the first one"
          },
          "answer": "A",
          "answer_text": "The opening ritual consecrates the practice, and the closing ritual offers thanks and discharges the artistic session with grace.",
          "difficulty": "moderate",
          "difficulty_percentage": 60,
          "difficulty_level": "Curious Adventurer",
          "target_age_group": "8-11 years"
        },
        {
          "id": 23,
          "type": "mcq",
          "question": "What does holding hands in front of the chest in Samapadam represent at the start of the salutation?",
          "options": {
            "A": "Centering of personal energy and inner devotion (Anjali Mudra at the heart center)",
            "B": "A signal to turn off the lights",
            "C": "A resting posture because the dancer is tired",
            "D": "A gesture indicating hunger"
          },
          "answer": "A",
          "answer_text": "Holding hands at the heart center (Anjali Mudra) centers the body and mind in calm somatic readiness.",
          "difficulty": "moderate",
          "difficulty_percentage": 60,
          "difficulty_level": "Curious Adventurer",
          "target_age_group": "8-11 years"
        },
        {
          "id": 24,
          "type": "descriptive",
          "question": "Explain the spiritual and cultural meaning of touching the floor and touching the eyes during the salutation.",
          "reference_answer": "In Indian classical dance, the floor represents Mother Earth (Bhumi Devi). Dancers touch the earth and then their eyes to show deep reverence and ask for forgiveness and blessings for stamping their feet upon her during the dance.",
          "key_concepts": ["Mother Earth Bhumi Devi", "touch earth and eyes", "reverence and respect", "ask for forgiveness and blessings", "stamping feet during dance"],
          "cosine_similarity_threshold": 0.60,
          "difficulty": "moderate",
          "difficulty_percentage": 55,
          "difficulty_level": "Curious Adventurer",
          "target_age_group": "8-11 years"
        },
        {
          "id": 25,
          "type": "descriptive",
          "question": "Describe the three distinct hand positions used to salute God, Guru, and the Audience in the closing ritual.",
          "reference_answer": "The dancer salutes God by placing hands on top of the head (crown), salutes the Guru (teacher) by bringing hands in front of the forehead (intellect/wisdom), and salutes the audience by placing hands at the center of the chest (heart/gratitude).",
          "key_concepts": ["salute God on top of head crown", "salute Guru in front of forehead intellect", "salute audience center of chest heart gratitude"],
          "cosine_similarity_threshold": 0.60,
          "difficulty": "moderate",
          "difficulty_percentage": 55,
          "difficulty_level": "Curious Adventurer",
          "target_age_group": "8-11 years"
        },
        {
          "id": 26,
          "type": "descriptive",
          "question": "Explain the importance of stretching and variable speed practice for a dancer's long-term development.",
          "reference_answer": "Stretching before and after every lesson warms up muscles and prevents injury, while practicing adavus at different speeds develops agility, neuromuscular precision, and endurance in maintaining proper postures.",
          "key_concepts": ["stretching before and after", "warms up muscles prevents injury", "practicing at different speeds", "develops agility and precision", "endurance in maintaining postures"],
          "cosine_similarity_threshold": 0.60,
          "difficulty": "moderate",
          "difficulty_percentage": 60,
          "difficulty_level": "Curious Adventurer",
          "target_age_group": "8-11 years"
        },
        {
          "id": 27,
          "type": "speech",
          "question": "Pronounce the phrase honoring Mother Earth:",
          "target_phrase": "Paying Respects for Mother Earth",
          "reference_answer": "Paying Respects for Mother Earth",
          "key_concepts": ["Paying", "Respects", "Mother", "Earth"],
          "min_score_threshold": 70,
          "difficulty": "moderate",
          "difficulty_percentage": 50,
          "difficulty_level": "Curious Adventurer",
          "target_age_group": "8-11 years"
        },
        {
          "id": 28,
          "type": "speech",
          "question": "Pronounce the three hand levels in salutation:",
          "target_phrase": "Top of Head Forehead and Chest",
          "reference_answer": "Top of Head Forehead and Chest",
          "key_concepts": ["Top", "Head", "Forehead", "Chest"],
          "min_score_threshold": 70,
          "difficulty": "moderate",
          "difficulty_percentage": 50,
          "difficulty_level": "Curious Adventurer",
          "target_age_group": "8-11 years"
        },
        {
          "id": 29,
          "type": "speech",
          "question": "Pronounce the practice rule for physical safety:",
          "target_phrase": "Stretch Before and After Every Lesson",
          "reference_answer": "Stretch Before and After Every Lesson",
          "key_concepts": ["Stretch", "Before", "After", "Lesson"],
          "min_score_threshold": 70,
          "difficulty": "moderate",
          "difficulty_percentage": 55,
          "difficulty_level": "Curious Adventurer",
          "target_age_group": "8-11 years"
        },
        {
          "id": 30,
          "type": "speech",
          "question": "Pronounce the closing salutation term in Indian arts:",
          "target_phrase": "Ancient Tap and Salute Practice",
          "reference_answer": "Ancient Tap and Salute Practice",
          "key_concepts": ["Ancient", "Tap", "Salute", "Practice"],
          "min_score_threshold": 75,
          "difficulty": "moderate",
          "difficulty_percentage": 55,
          "difficulty_level": "Curious Adventurer",
          "target_age_group": "8-11 years"
        },

        # HARD (31-45)
        {
          "id": 31,
          "type": "mcq",
          "question": "In classical Natya philosophy, what is the metaphysical significance of the gesture dedicated to Bhumi Devi (Mother Earth)?",
          "options": {
            "A": "It acknowledges the sacred ecological relationship between the dancer and the terrestrial realm, asking divine forgiveness for stamping upon the living earth",
            "B": "It is a superstition with no philosophical significance",
            "C": "It is intended to test the temperature of the stage floor",
            "D": "It signals that the dancer is going to lie down for a nap"
          },
          "answer": "A",
          "answer_text": "The gesture is an eco-spiritual acknowledgment recognizing the earth as a living deity whose forbearance is invoked.",
          "difficulty": "hard",
          "difficulty_percentage": 75,
          "difficulty_level": "Challenger",
          "target_age_group": "12-15 years"
        },
        {
          "id": 32,
          "type": "mcq",
          "question": "Analyze the vertical spatial symbolism of the three salutes (Head, Forehead, Heart) in relation to Indian yogic and aesthetic theory.",
          "options": {
            "A": "Sahasrara (Crown/Divine transcendent consciousness) -> Ajna (Forehead/Guru's wisdom and vision) -> Anahata (Heart/Communal love and shared aesthetic bliss with Rasikas)",
            "B": "They correspond to the three primary colors used in stage lighting",
            "C": "They represent the past, present, and future generations of audience members",
            "D": "They indicate the volume levels of the musical instruments"
          },
          "answer": "A",
          "answer_text": "The three hand placements mirror the subtle energy centers: Crown (Sahasrara/God), Ajna (Forehead/Guru), and Heart (Anahata/Audience).",
          "difficulty": "hard",
          "difficulty_percentage": 80,
          "difficulty_level": "Challenger",
          "target_age_group": "12-15 years"
        },
        {
          "id": 33,
          "type": "mcq",
          "question": "From a physiological and kinesiological perspective, why is full-mandi (deep squat) an extraordinary test of lower-body conditioning?",
          "options": {
            "A": "It requires extreme ankle dorsiflexion, hip abduction, knee flexion strength, and pelvic floor control while keeping the spine vertical",
            "B": "It relaxes all muscles in the body completely so no energy is used",
            "C": "It is performed without using any leg muscles",
            "D": "It only requires upper-body arm strength"
          },
          "answer": "A",
          "answer_text": "Full Mandi demands profound mobility in the ankles, hips, and knees alongside eccentric control of the core and quadriceps.",
          "difficulty": "hard",
          "difficulty_percentage": 85,
          "difficulty_level": "Champion",
          "target_age_group": "12-15 years"
        },
        {
          "id": 34,
          "type": "mcq",
          "question": "How does the closing salutation dissolve the boundary between performer and audience (Nartaki and Rasika)?",
          "options": {
            "A": "By honoring the audience as co-creators of the aesthetic experience (Rasanubhava) whose empathetic engagement completes the purpose of Natya",
            "B": "By asking the audience to perform the dance steps with the dancer",
            "C": "By demanding that the audience pay additional admission fees",
            "D": "By requiring the audience to critique the dancer's mistakes publicly"
          },
          "answer": "A",
          "answer_text": "Classical aesthetics view the Rasika (audience) as an essential spiritual and artistic partner in the manifestation of Rasa.",
          "difficulty": "hard",
          "difficulty_percentage": 85,
          "difficulty_level": "Champion",
          "target_age_group": "12-15 years"
        },
        {
          "id": 35,
          "type": "mcq",
          "question": "Why is the consistent habit of warm-up and cool-down stretching emphasized as an ethical duty in classical Indian performing arts?",
          "options": {
            "A": "The body (Sharira) is revered as the sacred temple and sole instrument of the art, requiring conscious stewardship and preservation",
            "B": "It is a rule created solely by modern gym instructors",
            "C": "It is done to make the practice session look longer",
            "D": "It replaces the need to practice technical adavus"
          },
          "answer": "A",
          "answer_text": "Treating the body as a sanctified vessel of divine art necessitates rigorous somatic care, injury prevention, and physical maintenance.",
          "difficulty": "hard",
          "difficulty_percentage": 75,
          "difficulty_level": "Challenger",
          "target_age_group": "12-15 years"
        },
        {
          "id": 36,
          "type": "mcq",
          "question": "What pedagogical message is encapsulated in the teacher's closing remark: 'Happy learning, Happy dancing, Nandri'?",
          "options": {
            "A": "That classical dance is a lifelong joyful journey of self-discovery, cultural pride, and heartfelt gratitude",
            "B": "That the student should never practice again after watching the video",
            "C": "That classical dance is only meant for commercial entertainment",
            "D": "That the lesson has no connection to broader Indian heritage"
          },
          "answer": "A",
          "answer_text": "It encapsulates the joyful, respectful, and lifelong dedication inherent in Indian classical arts education.",
          "difficulty": "hard",
          "difficulty_percentage": 80,
          "difficulty_level": "Challenger",
          "target_age_group": "12-15 years"
        },
        {
          "id": 37,
          "type": "mcq",
          "question": "How does the entire four-part Bharatanatyam curriculum presented in this series progress systematically?",
          "options": {
            "A": "From cultural origin & syllables -> salutation & static postures -> half-squat geometry & striking steps -> rhythmic subdivision & closing consecrated ritual",
            "B": "From fast jumping -> sleeping -> singing -> stage lighting",
            "C": "From modern hip-hop -> classical ballet -> tap dance -> Bharatanatyam",
            "D": "From painting -> sculpture -> poetry -> instrumental music"
          },
          "answer": "A",
          "answer_text": "The pedagogical trajectory systematically builds from theoretical roots to postural basics, rhythmic footwork, and ritual integration.",
          "difficulty": "hard",
          "difficulty_percentage": 90,
          "difficulty_level": "Champion",
          "target_age_group": "12-15 years"
        },
        {
          "id": 38,
          "type": "descriptive",
          "question": "Critically analyze the philosophical and spiritual architecture of the closing salutation (Tap and Salute) in Bharatanatyam.",
          "reference_answer": "The closing salutation is a consecrated ritual that integrates ecological reverence (touching Mother Earth for forgiveness), spiritual devotion (saluting God at the crown), pedagogical gratitude (saluting Guru at the forehead), and communal respect (saluting the audience at the heart). It harmonizes the dancer within cosmic and social order.",
          "key_concepts": ["consecrated ritual", "ecological reverence Mother Earth", "spiritual devotion God at crown", "pedagogical gratitude Guru at forehead", "communal respect audience at heart", "cosmic and social harmony"],
          "cosine_similarity_threshold": 0.70,
          "difficulty": "hard",
          "difficulty_percentage": 85,
          "difficulty_level": "Champion",
          "target_age_group": "12-15 years"
        },
        {
          "id": 39,
          "type": "descriptive",
          "question": "Examine how the triad of salutations (Crown, Forehead, Chest) corresponds to spiritual and artistic dimensions in Indian aesthetics.",
          "reference_answer": "Placing hands at the crown acknowledges supreme divine grace (the source of art); at the forehead, it honors the intellect and guidance of the Guru who illuminates the path; at the chest, it connects the dancer's heart with the audience in shared emotional and aesthetic communion (Rasa).",
          "key_concepts": ["crown divine grace source of art", "forehead intellect and guidance of Guru", "chest heart connection with audience", "shared aesthetic communion Rasa"],
          "cosine_similarity_threshold": 0.70,
          "difficulty": "hard",
          "difficulty_percentage": 80,
          "difficulty_level": "Challenger",
          "target_age_group": "12-15 years"
        },
        {
          "id": 40,
          "type": "descriptive",
          "question": "Evaluate the kinesiological demands of executing the Full Mandi posture in classical dance.",
          "reference_answer": "Full Mandi demands deep hip abduction, bilateral external femoral rotation, full knee flexion, and ankle plantar-flexion stability while sustaining an upright spinal column and centered pelvic alignment, showcasing extraordinary muscular strength and joint flexibility.",
          "key_concepts": ["Full Mandi kinesiology", "deep hip abduction", "bilateral external rotation", "full knee flexion", "ankle stability", "upright spinal column", "strength and flexibility"],
          "cosine_similarity_threshold": 0.70,
          "difficulty": "hard",
          "difficulty_percentage": 75,
          "difficulty_level": "Challenger",
          "target_age_group": "12-15 years"
        },
        {
          "id": 41,
          "type": "descriptive",
          "question": "Synthesize the overarching philosophy of physical discipline, cultural heritage, and lifelong practice conveyed across this Bharatanatyam instructional journey.",
          "reference_answer": "The instructional journey demonstrates that Bharatanatyam is a holistic discipline uniting somatic rigor (postures, adavus, stretching), mathematical rhythm (Tala), cultural reverence (Salutation to Earth, God, Guru, Audience), and joyful artistic expression, inviting the learner into an ancient living heritage.",
          "key_concepts": ["holistic discipline", "somatic rigor postures adavus stretching", "mathematical rhythm Tala", "cultural reverence Salutation", "Earth God Guru Audience", "joyful artistic expression", "living heritage"],
          "cosine_similarity_threshold": 0.70,
          "difficulty": "hard",
          "difficulty_percentage": 80,
          "difficulty_level": "Challenger",
          "target_age_group": "12-15 years"
        },
        {
          "id": 42,
          "type": "speech",
          "question": "Pronounce the eco-spiritual salutation concept:",
          "target_phrase": "Reverence and Pardon to Mother Earth",
          "reference_answer": "Reverence and Pardon to Mother Earth",
          "key_concepts": ["Reverence", "Pardon", "Mother", "Earth"],
          "min_score_threshold": 80,
          "difficulty": "hard",
          "difficulty_percentage": 80,
          "difficulty_level": "Challenger",
          "target_age_group": "12-15 years"
        },
        {
          "id": 43,
          "type": "speech",
          "question": "Pronounce the complete triad of salutation recipients:",
          "target_phrase": "Salute to God Guru and the Audience",
          "reference_answer": "Salute to God Guru and the Audience",
          "key_concepts": ["Salute", "God", "Guru", "Audience"],
          "min_score_threshold": 80,
          "difficulty": "hard",
          "difficulty_percentage": 85,
          "difficulty_level": "Champion",
          "target_age_group": "12-15 years"
        },
        {
          "id": 44,
          "type": "speech",
          "question": "Pronounce the physical care principle:",
          "target_phrase": "Somatic Stretching Before and After Practice",
          "reference_answer": "Somatic Stretching Before and After Practice",
          "key_concepts": ["Somatic", "Stretching", "Before", "After", "Practice"],
          "min_score_threshold": 80,
          "difficulty": "hard",
          "difficulty_percentage": 75,
          "difficulty_level": "Challenger",
          "target_age_group": "12-15 years"
        },
        {
          "id": 45,
          "type": "speech",
          "question": "Pronounce the joyful conclusion of the lesson:",
          "target_phrase": "Happy Learning Happy Dancing Nandri",
          "reference_answer": "Happy Learning Happy Dancing Nandri",
          "key_concepts": ["Happy", "Learning", "Dancing", "Nandri"],
          "min_score_threshold": 85,
          "difficulty": "hard",
          "difficulty_percentage": 90,
          "difficulty_level": "Champion",
          "target_age_group": "12-15 years"
        }
      ],
      "sequence_test": {
        "title": "Complete Choreographic Sequence of the Closing Tap and Salute",
        "description": "These questions test whether the learner understands the exact chronological sequence of gestures and postures that constitute the closing tap and salute in Bharatanatyam.",
        "questions": [
          {
            "id": 46,
            "type": "sequence_mcq",
            "question": "What is the correct physical sequence of the closing tap and salute?",
            "options": {
              "A": "Samapadam with hands in front of chest -> Strike right foot once -> Sit down in Full Mandi -> Touch floor and touch eyes -> Salute God (hands above head) -> Salute Guru (hands at forehead) -> Salute audience (hands at chest)",
              "B": "Touch floor -> Strike right foot -> Salute audience -> Full Mandi -> Salute God -> Samapadam",
              "C": "Salute God -> Salute Guru -> Salute audience -> Strike right foot -> Full Mandi -> Touch floor",
              "D": "Full Mandi -> Salute audience -> Samapadam -> Strike right foot -> Touch floor"
            },
            "answer": "A",
            "answer_text": "The salutation begins in Samapadam with a right foot tap, descends into Full Mandi, touches the floor and eyes for Mother Earth, and ascends through salutes to God, Guru, and the Audience.",
            "difficulty": "moderate",
            "difficulty_percentage": 60,
            "difficulty_level": "Curious Adventurer"
          },
          {
            "id": 47,
            "type": "sequence_mcq",
            "question": "Arrange the complete structural phases of a Bharatanatyam lesson from opening to conclusion:",
            "options": {
              "A": "Pre-session stretching -> Opening Salutation to God, Guru & Audience -> Foundational Postures & Adavu Practice in progressive speeds -> Closing Tap and Salute ritual -> Post-session stretching",
              "B": "Closing Tap and Salute -> Adavu practice -> Pre-session stretching -> Opening Salutation",
              "C": "Adavu practice in fast speed -> Opening Salutation -> Pre-session stretching -> Closing Salute",
              "D": "Opening Salutation -> Post-session stretching -> Pre-session stretching -> Adavu practice"
            },
            "answer": "A",
            "answer_text": "A complete, disciplined session begins with warm-up stretching and opening salutation, moves through progressive adavu training, and concludes with the tap and salute and cool-down stretching.",
            "difficulty": "hard",
            "difficulty_percentage": 75,
            "difficulty_level": "Challenger"
          }
        ]
      },
      "image_matching": [
        {
          "id": 48,
          "type": "image_matching",
          "question": "Match each salutation gesture with the entity it reveres:",
          "images": [
            {
              "id": "img_1",
              "file": "images/salute_earth.jpg",
              "label": "Touch Floor & Eyes"
            },
            {
              "id": "img_2",
              "file": "images/salute_god.jpg",
              "label": "Hands Above Head"
            },
            {
              "id": "img_3",
              "file": "images/salute_guru.jpg",
              "label": "Hands at Forehead"
            }
          ],
          "descriptions": [
            {
              "id": "desc_1",
              "text": "The sacred gesture asking forgiveness and blessings from Mother Earth (Bhumi Devi)."
            },
            {
              "id": "desc_2",
              "text": "The highest Anjali Mudra placement offering reverence to the Supreme Divine (God)."
            },
            {
              "id": "desc_3",
              "text": "The respectful salute placed in front of the forehead honoring the wisdom of the Guru."
            }
          ],
          "correct_matches": {
            "img_1": "desc_1",
            "img_2": "desc_2",
            "img_3": "desc_3"
          },
          "points": 3,
          "difficulty": "easy",
          "difficulty_percentage": 30,
          "difficulty_level": "Gentle Starter"
        },
        {
          "id": 49,
          "type": "image_matching",
          "question": "Match each practice principle with its essential benefit for classical dancers:",
          "images": [
            {
              "id": "img_1",
              "file": "images/full_mandi_squat.jpg",
              "label": "Full Mandi Posture"
            },
            {
              "id": "img_2",
              "file": "images/stretching_routine.jpg",
              "label": "Pre/Post Stretching"
            },
            {
              "id": "img_3",
              "file": "images/salute_audience.jpg",
              "label": "Salute to Audience"
            }
          ],
          "descriptions": [
            {
              "id": "desc_1",
              "text": "The deep squat posture that demonstrates profound lower-body strength, joint mobility, and control."
            },
            {
              "id": "desc_2",
              "text": "The vital somatic routine performed before and after every lesson to prevent injury and promote recovery."
            },
            {
              "id": "desc_3",
              "text": "Bringing hands to the heart center to honor the community of viewers who witness and complete the art."
            }
          ],
          "correct_matches": {
            "img_1": "desc_1",
            "img_2": "desc_2",
            "img_3": "desc_3"
          },
          "points": 3,
          "difficulty": "moderate",
          "difficulty_percentage": 60,
          "difficulty_level": "Curious Adventurer"
        }
      ],
      "scoring": {
        "mcq": {
          "points_per_correct_answer": 1
        },
        "descriptive": {
          "method": "cosine_similarity",
          "description": "Calculate embedding cosine similarity against reference concepts.",
          "suggested_interpretation": {
            "0.80-1.00": "Outstanding Mastery",
            "0.65-0.79": "Good Conceptual Understanding",
            "0.50-0.64": "Developing Understanding",
            "0.00-0.49": "Needs Reinforcement"
          }
        },
        "speech": {
          "points_per_correct_answer": 1,
          "min_pass_score": 60
        },
        "sequence_test": {
          "points_per_correct_answer": 1
        },
        "image_matching": {
          "points_per_correct_match": 1,
          "total_points": 3
        }
      }
    }
    with open("assets/Bharatnatayam/bharatnatyam_4/questions.json", "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    print("bharatnatyam_4 questions.json created successfully!")

if __name__ == "__main__":
    create_bharatnatyam_4()
