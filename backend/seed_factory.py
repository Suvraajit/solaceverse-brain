import os
import time
import random
import json
import requests
from dotenv import load_dotenv
import google.generativeai as genai
from supabase import create_client, Client

# 1. SETUP
load_dotenv()
GEMINI_KEY = os.getenv("GEMINI_API_KEY")
PEXELS_KEY = os.getenv("PEXELS_API_KEY")
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

genai.configure(api_key=GEMINI_KEY)
model = genai.GenerativeModel('gemini-2.5-flash')
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# 2. THEMES TO GENERATE (The Factory Inputs)
themes = [
    "The feeling of being invisible", "Finding hope in a dark winter", "A broken heart healing slowly",
    "Social anxiety at a party", "The peace of a quiet morning", "Nostalgia for childhood",
    "The anger of injustice", "Fear of the future", "Unexpected kindness from a stranger",
    "The beauty of rain", "Letting go of a grudge", "The silence of space",
    "A robot learning to love", "A letter never sent", "The smell of old books",
    "Walking alone in a city at night", "The first day of spring", "Overcoming failure",
    "The loyalty of a dog", "A conversation with the moon"
]

# 3. HELPER: GET IMAGE
def get_image(query):
    if not PEXELS_KEY: return "https://via.placeholder.com/400"
    try:
        url = f"https://api.pexels.com/v1/search?query={query}&per_page=1"
        headers = {"Authorization": PEXELS_KEY}
        res = requests.get(url, headers=headers)
        data = res.json()
        if data.get('photos'): return data['photos'][0]['src']['large']
    except: pass
    return "https://via.placeholder.com/400"

# 4. THE FACTORY LOOP
print(f"🏭 Starting the SolaceVerse Content Factory...")
print(f"🎯 Target: {len(themes)} unique stories.")

for i, theme in enumerate(themes):
    print(f"\n[{i+1}/{len(themes)}] Generating story about: {theme}...")
    
    prompt = f"""
    Write a very short, emotional story (max 150 words) about: "{theme}".
    It should feel like a classic public domain fable or a modern flash fiction.
    
    Also provide:
    1. A Creative Title.
    2. A "Vibe" string (3-4 emotional keywords).
    3. A visual search term for Pexels (2 words).
    
    Return JSON ONLY:
    {{
        "title": "The Title",
        "content": "The story text...",
        "vibe": "sad, lonely, hope",
        "visual": "rainy window"
    }}
    """
    
    try:
        # Ask AI to write the story
        response = model.generate_content(prompt)
        clean_text = response.text.replace('```json', '').replace('```', '').strip()
        data = json.loads(clean_text)
        
        # Get Art
        image_url = get_image(data['visual'])
        
        # Save to Database
        db_item = {
            "title": data['title'],
            "type": "Short Story",
            "content": data['content'], # The story goes here
            "vibe": data['vibe'],
            "image": image_url
        }
        
        supabase.table("content_library").insert(db_item).execute()
        print(f"✅ Created: {data['title']}")
        
        # SLEEP to prevent Rate Limiting (Crucial!)
        time.sleep(2) 
        
    except Exception as e:
        print(f"❌ Failed: {e}")
        time.sleep(5) # Wait longer if we hit an error

print("\n🎉 Factory Shift Complete. Your app is now full of stories.")