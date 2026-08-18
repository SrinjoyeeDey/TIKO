import json
import os

folders_to_check = [
    ("assets/Netaji/Netaji_0", True),
    ("assets/Netaji/Netaji_1", True),
    ("assets/Netaji/Netaji_2", True),
    ("assets/Bharatnatayam/bharatnatayam_0", True),
    ("assets/Bharatnatayam/bharatnatayam_1", True),
    ("assets/Bharatnatayam/bharatnatayam_2", True),
    ("assets/Bharatnatayam/bharatnatayam_3", True),
    ("assets/Bharatnatayam/bharatnatyam_4", True),
]

all_passed = True

for folder, has_transcript in folders_to_check:
    print(f"=== Validating {folder} ===")
    
    # 1. Check transcript.json
    t_path = os.path.join(folder, "transcript.json")
    if os.path.exists(t_path):
        with open(t_path, "r", encoding="utf-8-sig") as f:
            t_data = json.load(f)
            segments = t_data.get("segments", [])
            print(f"  transcript.json: OK ({len(segments)} segments)")
            for s in segments:
                assert "start" in s and "end" in s and "text" in s, f"Invalid segment in {t_path}: {s}"
    else:
        print(f"  transcript.json: MISSING in {folder}")
        all_passed = False
        
    # 2. Check questions.json
    q_path = os.path.join(folder, "questions.json")
    if os.path.exists(q_path):
        with open(q_path, "r", encoding="utf-8-sig") as f:
            q_data = json.load(f)
            
        # Check root structure
        for key in ["title", "section", "target_age", "age_range", "question_pattern", "questions", "sequence_test", "image_matching", "scoring"]:
            if key not in q_data:
                print(f"  ERROR: missing root key '{key}' in {q_path}")
                all_passed = False
                
        questions = q_data.get("questions", [])
        print(f"  questions count: {len(questions)}")
        if len(questions) != 45:
            print(f"  ERROR: expected 45 questions, got {len(questions)} in {q_path}")
            all_passed = False
            
        diff_counts = {}
        type_counts = {}
        for q in questions:
            d = q.get("difficulty")
            t = q.get("type")
            diff_counts[d] = diff_counts.get(d, 0) + 1
            type_counts[t] = type_counts.get(t, 0) + 1
            
            # Check question fields
            assert "id" in q, f"Missing id: {q}"
            assert "question" in q, f"Missing question: {q}"
            assert "difficulty" in q, f"Missing difficulty: {q}"
            assert "difficulty_percentage" in q, f"Missing difficulty_percentage: {q}"
            assert "difficulty_level" in q, f"Missing difficulty_level: {q}"
            assert "target_age_group" in q, f"Missing target_age_group: {q}"
            
            if t == "mcq":
                assert "options" in q, f"MCQ missing options: {q}"
                assert "answer" in q, f"MCQ missing answer: {q}"
                assert q["answer"] in q["options"], f"MCQ answer not in options: {q}"
                assert "answer_text" in q, f"MCQ missing answer_text: {q}"
            elif t == "descriptive":
                assert "reference_answer" in q, f"Descriptive missing reference_answer: {q}"
                assert "key_concepts" in q and len(q["key_concepts"]) > 0, f"Descriptive missing key_concepts: {q}"
                assert "cosine_similarity_threshold" in q, f"Descriptive missing threshold: {q}"
            elif t == "speech":
                assert "target_phrase" in q, f"Speech missing target_phrase: {q}"
                assert "reference_answer" in q, f"Speech missing reference_answer: {q}"
                assert "key_concepts" in q and len(q["key_concepts"]) > 0, f"Speech missing key_concepts: {q}"
                assert "min_score_threshold" in q, f"Speech missing min_score_threshold: {q}"
                
        print(f"  difficulty breakdown: {diff_counts}")
        print(f"  type breakdown: {type_counts}")
        
        # Check sequence test
        seq_test = q_data.get("sequence_test", {})
        seq_qs = seq_test.get("questions", [])
        print(f"  sequence_test questions: {len(seq_qs)}")
        if len(seq_qs) != 2:
            print(f"  ERROR: expected 2 sequence questions, got {len(seq_qs)}")
            all_passed = False
        for sq in seq_qs:
            assert "options" in sq and "answer" in sq and sq["answer"] in sq["options"]
            
        # Check image matching
        img_match = q_data.get("image_matching", [])
        print(f"  image_matching items: {len(img_match)}")
        if len(img_match) != 2:
            print(f"  ERROR: expected 2 image matching items, got {len(img_match)}")
            all_passed = False
        for im in img_match:
            assert "images" in im and "descriptions" in im and "correct_matches" in im
            assert len(im["images"]) == len(im["descriptions"]) == len(im["correct_matches"])
            
        # Check scoring
        scoring = q_data.get("scoring", {})
        for sk in ["mcq", "descriptive", "speech", "sequence_test", "image_matching"]:
            assert sk in scoring, f"Missing scoring key '{sk}' in {q_path}"
            
    else:
        print(f"  questions.json: MISSING in {folder}")
        all_passed = False

if all_passed:
    print("\n==========================================")
    print("ALL 8 MODULES FULLY VALIDATED AND PASSED!")
    print("==========================================")
else:
    print("\nVALIDATION FAILED WITH ERRORS!")
