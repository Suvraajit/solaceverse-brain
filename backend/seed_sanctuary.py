import os
import time
import json
import requests
import random
from dotenv import load_dotenv
import google.generativeai as genai
from supabase import create_client, Client

# 1. SETUP
load_dotenv()
GEMINI_KEY = os.getenv("GEMINI_API_KEY")
PEXELS_KEY = os.getenv("PEXELS_API_KEY")
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

if not GEMINI_KEY or not SUPABASE_URL:
    print("❌ Error: Missing Keys in .env file")
    exit()

genai.configure(api_key=GEMINI_KEY)
model = genai.GenerativeModel('gemini-2.5-flash')
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# --- HELPER: GET PEXELS IMAGE (For Poems) ---
def get_pexels_image(query):
    try:
        url = f"https://api.pexels.com/v1/search?query={query}&per_page=1"
        headers = {"Authorization": PEXELS_KEY}
        res = requests.get(url, headers=headers)
        data = res.json()
        if data.get('photos'): return data['photos'][0]['src']['large']
    except: pass
    return "https://images.pexels.com/photos/2885320/pexels-photo-2885320.jpeg"

# --- HELPER: ANALYZE VIBE WITH GEMINI ---
def get_ai_metadata(text, type_label):
    prompt = f"""
    Analyze this {type_label}: "{text[:1000]}..."
    
    1. Give me a 1-word emotional vibe (e.g. Melancholy, Hope, Rage).
    2. Give me a 2-word visual search term for a background image.
    
    Return JSON: {{ "vibe": "Melancholy", "visual": "dark ocean" }}
    """
    try:
        response = model.generate_content(prompt)
        clean = response.text.replace('```json', '').replace('```', '').strip()
        return json.loads(clean)
    except:
        return {"vibe": "Deep", "visual": "abstract art"}

# --- PART 1: FETCH POEMS (PoetryDB) ---
def seed_poems():
    print("\n📜 Fetching Poems from PoetryDB...")
    try:
        # Fetch 10 random poems
        res = requests.get("https://poetrydb.org/random/10")
        poems = res.json()
        
        for p in poems:
            title = p['title']
            author = p['author']
            lines = "\n".join(p['lines'])  # Join lines into one string
            
            # Ask AI for Vibe
            meta = get_ai_metadata(lines, "Poem")
            
            # Get Background Image
            image_url = get_pexels_image(meta['visual'])
            
            item = {
                "title": title,
                "type": "Poetry",
                "content": f"{lines}\n\n— {author}",
                "vibe": meta['vibe'],
                "image": image_url
            }
            
            supabase.table("content_library").insert(item).execute()
            print(f"✅ Added Poem: {title}")
            time.sleep(1) # Be nice to API
            
    except Exception as e:
        print(f"❌ Poem Error: {e}")

# --- PART 2: FETCH ART (Art Institute of Chicago) ---
def seed_art():
    print("\n🎨 Fetching Art from Chicago Institute...")
    try:
        # Fetch 10 Public Domain Artworks with Images
        url = "https://api.artic.edu/api/v1/artworks/search?q=&query[term][is_public_domain]=true&limit=10&fields=id,title,image_id,artist_display,medium_display"
        res = requests.get(url)
        artworks = res.json()['data']
        
        for art in artworks:
            if not art['image_id']: continue
            
            title = art['title']
            artist = art['artist_display']
            medium = art['medium_display']
            
            # Construct IIIF Image URL (High Res)
            image_url = f"https://www.artic.edu/iiif/2/{art['image_id']}/full/843,/0/default.jpg"
            
            # Ask AI for Vibe based on Title
            meta = get_ai_metadata(f"{title} by {artist}", "Painting")
            
            item = {
                "title": title,
                "type": "Visual Art",
                "content": f"Artist: {artist}\nMedium: {medium}\n\n(A visual masterpiece from the Chicago Institute)",
                "vibe": meta['vibe'],
                "image": image_url
            }
            
            supabase.table("content_library").insert(item).execute()
            print(f"✅ Added Art: {title}")
            time.sleep(1)

    except Exception as e:
        print(f"❌ Art Error: {e}")

# --- EXECUTE ---
if __name__ == "__main__":
    # Optional: Clear old data first? 
    # supabase.table("content_library").delete().neq("id", 0).execute() 
    
    seed_poems()
    seed_art()
    print("\n🎉 Sanctuary Seeding Complete!")