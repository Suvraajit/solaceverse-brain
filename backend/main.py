import os
import json
import requests
import random
from datetime import datetime
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
import google.generativeai as genai
from supabase import create_client, Client
from pydantic import BaseModel

# ==========================================
# 1. CONFIGURATION & SECRETS
# ==========================================
load_dotenv()
GEMINI_KEY = os.getenv("GEMINI_API_KEY")
PEXELS_KEY = os.getenv("PEXELS_API_KEY")
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

# Initialize Services
genai.configure(api_key=GEMINI_KEY)
model = genai.GenerativeModel('gemini-2.5-flash') # Flash is fastest for real-time apps
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all websites (including your Netlify app)
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods (GET, POST, etc.)
    allow_headers=["*"],  # Allows all headers
)

# ==========================================
# 2. DATA MODELS (Strict Typing)
# ==========================================
class JournalEntry(BaseModel):
    mood: str
    reflection: str
    ai_tag: str
    image_url: str = ""
    date: str = ""     # Optional: For Time Travel/Backdating
    user_id: str       # REQUIRED: For Privacy/RLS

class CopilotRequest(BaseModel):
    text: str

class TemporalRequest(BaseModel):
    latitude: float
    longitude: float
    date: str # YYYY-MM-DD

class HindsightRequest(BaseModel):
    past_text: str
    current_mood: str

# ==========================================
# 3. HELPER FUNCTIONS
# ==========================================
def get_dynamic_image(query_term):
    """Fetches a high-quality image from Pexels efficiently."""
    if not PEXELS_KEY:
        return "https://images.unsplash.com/photo-1504197885-60974ceaf268"
    
    try:
        url = f"https://api.pexels.com/v1/search?query={query_term}&per_page=1"
        headers = {"Authorization": PEXELS_KEY}
        response = requests.get(url, headers=headers, timeout=5) # 5s timeout to prevent hanging
        data = response.json()
        if data.get('photos'):
            return data['photos'][0]['src']['large']
    except:
        pass
    return "https://via.placeholder.com/600x400?text=SolaceVerse"

def get_weather_desc(code):
    """Converts WMO codes to human text."""
    if code == 0: return "Clear skies"
    if code in [1, 2, 3]: return "Cloudy"
    if code in [45, 48]: return "Foggy"
    if code in [51, 53, 55, 61, 63, 65]: return "Rainy"
    if code in [71, 73, 75, 77]: return "Snowing"
    if code >= 95: return "Thunderstorm"
    return "Unknown weather"

# ==========================================
# 4. API ENDPOINTS
# ==========================================

@app.get("/")
def home():
    return {"status": "SolaceVerse Brain is Online"}

# --- ANALYST MODE (The Curator) ---
@app.get("/mood")
async def check_mood(text: str):
    try:
        # Efficiency: Only fetch columns we need
        db_response = supabase.table("content_library").select("id, title, vibe, type, content").execute()
        library_data = db_response.data
    except Exception as e:
        return {"error": f"Database Error: {str(e)}"}

    # Minify library for token efficiency
    library_str = json.dumps(library_data)

    prompt = f"""
    Act as AI Curator. User Input: "{text}"
    1. Visual Search Term (3 words).
    2. Emotion Tag (3 words).
    3. Pick best content ID from library.
    Library: {library_str}
    Return JSON: {{ "visual_term": "...", "tag": "...", "recommendation_id": 1 }}
    """
    
    try:
        response = model.generate_content(prompt)
        clean_text = response.text.replace('```json', '').replace('```', '').strip()
        ai_data = json.loads(clean_text)
        
        selected_content = next((item for item in library_data if item['id'] == ai_data['recommendation_id']), None)
        
        # Lazy Load Image: Only fetch Pexels if we found content
        visual_term = ai_data.get("visual_term", "abstract")
        if selected_content:
            selected_content['image'] = get_dynamic_image(visual_term)

        return {"ai_nuanced_tag": ai_data['tag'], "content": selected_content}
    except Exception as e:
        return {"error": str(e)}

# --- NIGHT SHIFT (Storyteller) ---
@app.get("/night-shift")
async def night_shift_mode(text: str):
    # Optimized Prompt for speed
    prompt = f"""
    Write a soothing bedtime story (max 100 words) for anxiety about: "{text}".
    Use nature metaphors. No advice. Resolve into peace.
    """
    try:
        response = model.generate_content(prompt)
        story_text = response.text.strip()
    except:
        story_text = "The stars whispered that it would be okay..."

    # Randomize visual theme
    themes = ["calm night sky", "starlight mountains", "soothing deep ocean", "dreamy forest", "aurora borealis"]
    image_url = get_dynamic_image(random.choice(themes))

    return {"story": story_text, "image": image_url}

# --- CO-PILOT JOURNAL (Living Background) ---
@app.post("/copilot")
async def copilot_analysis(data: CopilotRequest):
    text = data.text
    if len(text) < 5:
        return {"color": "0xFF121212", "nudge": ""}

    prompt = f"""
    Analyze: "{text}"
    1. Pick BACKGROUND color (Hex) to COUNTER-BALANCE emotion:
       - Anger -> 0xFF004D40 (Teal)
       - Anxiety -> 0xFF1B5E20 (Green)
       - Sadness -> 0xFF4E342E (Warm Amber)
       - Happy -> 0xFF4A148C (Purple)
       - Neutral -> 0xFF121212 (Black)
    2. Short Socratic question (max 8 words).
    Return JSON: {{ "color": "0xFF...", "nudge": "..." }}
    """
    try:
        response = model.generate_content(prompt)
        clean_text = response.text.replace('```json', '').replace('```', '').strip()
        return json.loads(clean_text)
    except:
        return {"color": "0xFF121212", "nudge": ""}

# --- TEMPORAL MAP (Context Anchor) ---
@app.post("/temporal-context")
async def temporal_context(data: TemporalRequest):
    # OpenMeteo Historical Data
    url = f"https://archive-api.open-meteo.com/v1/archive?latitude={data.latitude}&longitude={data.longitude}&start_date={data.date}&end_date={data.date}&daily=weather_code"
    
    weather_desc = "Unknown"
    try:
        res = requests.get(url, timeout=3).json()
        if 'daily' in res and 'weather_code' in res['daily']:
            code = res['daily']['weather_code'][0]
            weather_desc = get_weather_desc(code)
    except:
        pass # Fail silently to keep app fast

    prompt = f"""
    User journaling for date: {data.date}. Weather: {weather_desc}.
    Generate 1-sentence prompt connecting weather/season to memory.
    """
    try:
        response = model.generate_content(prompt)
        return {"weather": weather_desc, "prompt": response.text.strip()}
    except:
        return {"weather": weather_desc, "prompt": "What do you remember?"}

# --- SAVE JOURNAL (With RLS User ID) ---
@app.post("/save-journal")
async def save_journal(entry: JournalEntry):
    try:
        data = {
            "mood": entry.mood,
            "reflection": entry.reflection,
            "ai_tag": entry.ai_tag,
            "image_url": entry.image_url,
            "user_id": entry.user_id # <--- CRITICAL FOR SECURITY
        }
        
        # Handle Backdating
        if entry.date:
            # Convert "YYYY-MM-DD" to ISO Timestamp
            iso_date = f"{entry.date}T12:00:00Z"
            data["created_at"] = iso_date

        supabase.table("journal_entries").insert(data).execute()
        return {"status": "success", "message": "Saved."}
    except Exception as e:
        return {"status": "error", "message": str(e)}