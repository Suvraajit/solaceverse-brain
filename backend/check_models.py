import google.generativeai as genai
import os
from dotenv import load_dotenv

# Load your key
load_dotenv()
api_key = os.getenv("GEMINI_API_KEY")
genai.configure(api_key=api_key)

print("Searching for available models...")
try:
    # List all models that support content generation
    for m in genai.list_models():
        if 'generateContent' in m.supported_generation_methods:
            print(f"- {m.name}")
except Exception as e:
    print(f"Error: {e}")