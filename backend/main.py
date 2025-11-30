import os
import json
import requests
import random
from datetime import datetime
from fastapi import FastAPI
from dotenv import load_dotenv
import google.generativeai as genai
from supabase import create_client, Client
from pydantic import BaseModel

# 1. SETUP & SECRETS
load_dotenv()
GEMINI_KEY = os.getenv("GEMINI_API_KEY")
PEXELS_KEY = os.getenv("PEXELS_API_KEY")
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

genai.configure(api_key=GEMINI_KEY)
model = genai.GenerativeModel('gemini-2.5-flash')
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

app = FastAPI()

# --- DATA MODELS ---
class JournalEntry(BaseModel):
    mood: str
    reflection: str
    ai_tag: str
    image_url: str = ""
    date: str = "" # For Backdating

class CopilotRequest(BaseModel):
    text: str

class TemporalRequest(BaseModel):
    latitude: float
    longitude: float
    date: str # YYYY-MM-DD

class HindsightRequest(BaseModel):
    past_text: str
    current_mood: str

# --- HELPER: PEXELS IMAGE ---
def get_dynamic_image(query_term):
    if not PEXELS_KEY:
        return "https://images.unsplash.com/photo-1504197885-60974ceaf268"
    
    url = f"https://api.pexels.com/v1/search?query={query_term}&per_page=1"
    headers = {"Authorization": PEXELS_KEY}
    
    try:
        response = requests.get(url, headers=headers)
        data = response.json()
        if data.get('photos'):
            return data['photos'][0]['src']['large']
        return "https://via.placeholder.com/600x400?text=No+Image"
    except:
        return "https://via.placeholder.com/600x400?text=API+Error"

# --- HELPER: WEATHER DECODER ---
def get_weather_desc(code):
    if code == 0: return "Clear skies"
    if code in [1, 2, 3]: return "Cloudy"
    if code in [45, 48]: return "Foggy"
    if code in [51, 53, 55, 61, 63, 65]: return "Rainy"
    if code in [71, 73, 75, 77]: return "Snowing"
    if code >= 95: return "Thunderstorm"
    return "Unknown weather"

# ==========================================
#              API ENDPOINTS
# ==========================================

@app.get("/")
def home():
    return {"status": "SolaceVerse Brain Online", "version": "Final"}

# 1. ANALYST MODE
@app.get("/mood")
async def check_mood(text: str):
    try:
        db_response = supabase.table("content_library").select("*").execute()
        library_data = db_response.data
    except Exception as e:
        return {"error": f"Database Error: {str(e)}"}

    library_str = json.dumps(library_data)

    prompt = f"""
    You are the AI Curator. User Feeling: "{text}"
    1. Visual Search Term (3 words).
    2. Nuanced Emotion Tag (3 words).
    3. Pick best content ID from library.
    
    Library: {library_str}
    Return JSON: {{ "visual_term": "...", "tag": "...", "recommendation_id": 1 }}
    """
    
    try:
        response = model.generate_content(prompt)
        clean_text = response.text.replace('```json', '').replace('```', '').strip()
        ai_data = json.loads(clean_text)
        
        selected_content = next((item for item in library_data if item['id'] == ai_data['recommendation_id']), None)
        
        visual_term = ai_data.get("visual_term", "abstract")
        if selected_content:
            selected_content['image'] = get_dynamic_image(visual_term)

        return {"ai_nuanced_tag": ai_data['tag'], "content": selected_content}
    except Exception as e:
        return {"error": str(e)}

# 2. NIGHT SHIFT
@app.get("/night-shift")
async def night_shift_mode(text: str):
    prompt = f"""
    Write a soothing bedtime story (max 150 words) for anxiety about: "{text}".
    No advice. Just a story resolving into peace.
    """
    try:
        response = model.generate_content(prompt)
        story_text = response.text.strip()
    except:
        story_text = "The stars whispered that it would be okay..."

    themes = ["calm night sky", "starlight mountains", "soothing deep ocean", "dreamy forest", "aurora borealis"]
    image_url = get_dynamic_image(random.choice(themes))

    return {"story": story_text, "image": image_url}

# 3. CO-PILOT JOURNAL
@app.post("/copilot")
async def copilot_analysis(data: CopilotRequest):
    text = data.text
    if len(text) < 5:
        return {"color": "0xFF121212", "nudge": ""}

    prompt = f"""
    Analyze fragment: "{text}"
    1. Pick a BACKGROUND color (Hex) to COUNTER-BALANCE the emotion:
       - Anger -> COOL TEAL (0xFF004D40)
       - Anxiety -> GROUNDING GREEN (0xFF1B5E20)
       - Sadness -> WARM AMBER (0xFF4E342E)
       - Happy -> VIBRANT PURPLE (0xFF4A148C)
       - Neutral -> Black (0xFF121212)
    2. Generate a short Socratic question (max 10 words).
    Return JSON: {{ "color": "0xFF...", "nudge": "..." }}
    """
    try:
        response = model.generate_content(prompt)
        clean_text = response.text.replace('```json', '').replace('```', '').strip()
        return json.loads(clean_text)
    except:
        return {"color": "0xFF121212", "nudge": ""}

# 4. TEMPORAL MAP (This is what was missing!)
@app.post("/temporal-context")
async def temporal_context(data: TemporalRequest):
    # Call OpenMeteo Historical Weather API
    url = f"https://archive-api.open-meteo.com/v1/archive?latitude={data.latitude}&longitude={data.longitude}&start_date={data.date}&end_date={data.date}&daily=weather_code"
    
    weather_desc = "Unknown"
    try:
        res = requests.get(url).json()
        if 'daily' in res and 'weather_code' in res['daily']:
            code = res['daily']['weather_code'][0]
            weather_desc = get_weather_desc(code)
    except:
        pass

    prompt = f"""
    User is writing a journal for past date: {data.date}.
    Weather was: {weather_desc}.
    Generate a 1-sentence prompt connecting weather to memory.
    """
    try:
        response = model.generate_content(prompt)
        return {"weather": weather_desc, "prompt": response.text.strip()}
    except:
        return {"weather": weather_desc, "prompt": "What do you remember?"}

# 5. SAVE JOURNAL (With Date Support)
@app.post("/save-journal")
async def save_journal(entry: JournalEntry):
    try:
        data = {
            "mood": entry.mood,
            "reflection": entry.reflection,
            "ai_tag": entry.ai_tag,
            "image_url": entry.image_url
        }
        
        # If backdating
        if entry.date:
            iso_date = f"{entry.date}T12:00:00Z"
            data["created_at"] = iso_date

        supabase.table("journal_entries").insert(data).execute()
        return {"status": "success", "message": "Saved."}
    except Exception as e:
        return {"status": "error", "message": str(e)}