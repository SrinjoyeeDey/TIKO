"""
Test script to verify Voice Interaction API and ElevenLabs / Groq integration.
"""
import sys
from pathlib import Path

# Setup paths
_workspace_root = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(_workspace_root))
sys.path.insert(0, str(_workspace_root / "ai_services"))

from fastapi.testclient import TestClient
from ai_services.nimo_contract_api.main import app

client = TestClient(app)

def test_voice_endpoints():
    print("\n--- 1. Testing /health ---")
    res = client.get("/health")
    print("Health response:", res.status_code, res.json())
    assert res.status_code == 200
    assert "elevenlabs_voice" in res.json()["models"]

    print("\n--- 2. Testing /voice/status ---")
    res = client.get("/voice/status")
    print("Voice status:", res.status_code, res.json())
    assert res.status_code == 200
    assert res.json()["status"] == "online"

    print("\n--- 3. Testing POST /voice/interaction (POST_SIGNUP_INTRO) ---")
    intro_req = {
        "interactionType": "POST_SIGNUP_INTRO",
        "childId": "child_001",
        "childName": "Tinna",
        "childAge": 6,
        "difficultyLevel": "Curious Adventurer",
        "availableChapters": ["Netaji", "Success"],
        "chapterName": "Netaji"
    }
    res = client.post("/voice/interaction", json=intro_req)
    print("Intro response:", res.status_code, res.json())
    assert res.status_code == 200
    data = res.json()
    assert data["success"] == True
    assert "Tinna" in data["spokenText"] or "Netaji" in data["spokenText"] or len(data["spokenText"]) > 10

    print("\n--- 4. Testing POST /voice/interaction (READ_QUESTION) ---")
    q_req = {
        "interactionType": "READ_QUESTION",
        "questionNumber": 1,
        "questionText": "When was Subhas Chandra Bose born?",
        "questionType": "mcq",
        "options": {
            "A": "23rd January 1897",
            "B": "15th August 1897"
        }
    }
    res = client.post("/voice/interaction", json=q_req)
    print("Question reader response:", res.status_code, res.json())
    assert res.status_code == 200
    assert "Subhas Chandra Bose" in res.json()["spokenText"]

    print("\n--- 5. Testing POST /voice/interaction (PRONOUNCE_PHRASE) ---")
    pronounce_req = {
        "interactionType": "PRONOUNCE_PHRASE",
        "targetPhrase": "Nationalist Temperament",
        "questionText": "Pronounce this key patriotic attribute:"
    }
    res = client.post("/voice/interaction", json=pronounce_req)
    print("Pronounce response:", res.status_code, res.json())
    assert res.status_code == 200
    assert "Nationalist Temperament" in res.json()["spokenText"]

    print("\n--- 6. Testing POST /voice/interaction (RETRY_QUESTION) ---")
    retry_req = {
        "interactionType": "RETRY_QUESTION",
        "targetPhrase": "Presidency College",
        "retryCount": 2
    }
    res = client.post("/voice/interaction", json=retry_req)
    print("Retry response:", res.status_code, res.json())
    assert res.status_code == 200
    assert "Presidency College" in res.json()["spokenText"]

    print("\n--- 7. Testing POST /voice/interaction (LEVEL_COMPLETION) ---")
    comp_req = {
        "interactionType": "LEVEL_COMPLETION",
        "childName": "Tinna",
        "chapterName": "Netaji",
        "levelName": "Lesson 1",
        "stars": 3,
        "totalCorrect": 5,
        "totalQuestions": 5
    }
    res = client.post("/voice/interaction", json=comp_req)
    print("Completion response:", res.status_code, res.json())
    assert res.status_code == 200
    assert data["success"] == True

    print("\n>>> ALL TESTS PASSED SUCCESSFULLY! <<<")

if __name__ == "__main__":
    test_voice_endpoints()
