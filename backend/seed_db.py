import os
from dotenv import load_dotenv
from supabase import create_client, Client

# 1. Load Keys
load_dotenv()
url = os.getenv("SUPABASE_URL")
key = os.getenv("SUPABASE_KEY")

if not url or not key:
    print("❌ Error: Missing Keys in .env file")
    exit()

# 2. Connect to Supabase
supabase: Client = create_client(url, key)

# 3. The Content to Upload
library_data = [
    {
        "title": "The Quiet Winter",
        "type": "Short Film",
        "vibe": "calm, introspection, solitude, cold, peace",
        "content": "https://www.youtube.com/watch?v=some_calm_video"
    },
    {
        "title": "Burning Out",
        "type": "Poem",
        "vibe": "exhaustion, pressure, overwhelmed, burnout",
        "content": "The candle burns not because it wants to,\nBut because the wick demands it.\nRest now, little flame.\nThe dark is not your enemy."
    },
    {
        "title": "The Weight of Water",
        "type": "Poem",
        "vibe": "sadness, grief, crying, heavy, drowning",
        "content": "Salt in the ocean,\nSalt in my eyes.\nThe waves don't ask permission to break,\nSo why do I apologize for breaking too?"
    },
    {
        "title": "Morning Light",
        "type": "Poem",
        "vibe": "hope, new beginning, sunrise, gentle joy",
        "content": "The sun does not resent the night.\nIt simply rises.\nAgain.\nAnd again.\nJust like you."
    },
    {
        "title": "Static Noise",
        "type": "Visual Art",
        "vibe": "anxiety, chaos, confusion, overthinking",
        "content": "Visual Interpretation of Anxiety: A TV screen showing static snow."
    },
    {
        "title": "Unsent Letters",
        "type": "Journal Prompt",
        "vibe": "heartbreak, nostalgia, missing someone, regret",
        "content": "Prompt: Write a letter to the person you miss, saying everything you swallowed back then. You do not have to send it."
    },
    {
        "title": "The Mask",
        "type": "Poem",
        "vibe": "fake happiness, hiding, loneliness, social anxiety",
        "content": "I wear a smile like a borrowed coat.\nIt fits poorly,\nBut it keeps the questions away."
    },
    {
        "title": "Just Breathe",
        "type": "Meditation",
        "vibe": "panic, stress, fear, racing heart",
        "content": "https://www.youtube.com/watch?v=some_breathing_exercise"
    },
    {
        "title": "Shadows of Joy",
        "type": "Journal Prompt",
        "vibe": "guilt, unworthy, imposter syndrome, conflicted happiness",
        "content": "Prompt: Write down one reason why you deserve this happiness, even if it feels like you don't."
    },
    {
        "title": "Invisible",
        "type": "Poem",
        "vibe": "loneliness, ignored, ghost, isolation",
        "content": "I shouted into the canyon,\nAnd not even an echo loved me back."
    }
]

print("🚀 Uploading content to SolaceVerse Cloud...")

for item in library_data:
    try:
        response = supabase.table("content_library").insert(item).execute()
        print(f"✅ Uploaded: {item['title']}")
    except Exception as e:
        print(f"❌ Failed: {item['title']} - {e}")

print("🎉 Database Seeded Successfully!")