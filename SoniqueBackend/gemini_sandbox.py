import google.generativeai as genai
import json, os
from dotenv import load_dotenv

# Load from .env
load_dotenv()

genai.configure(api_key=os.getenv("GEMINI_API_KEY"))
model = genai.GenerativeModel("gemini-2.0-flash")

def interpret_user_input():
    transcript = ""

    prompt = f"""
    Generate me a simple comma separated list output randomly. Don't say anything other than the list.
    """

    try:
        response = model.generate_content(prompt)
        parsed = response.text
        return json.dumps({"result": parsed}), 200
    except Exception as e:
        return json.dumps({'error': str(e)}), 500

if __name__ == "__main__":
    result, status = interpret_user_input()
    print(result)
