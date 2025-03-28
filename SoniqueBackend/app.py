from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
from werkzeug.utils import secure_filename
from tinydb import TinyDB, Query
import os, json
import fitz as PYMuDF  # PyMuPDF for PDF parsing
import google.generativeai as genai
from dotenv import load_dotenv
import re

# Load from .env
load_dotenv()

genai.configure(api_key=os.getenv("GEMINI_API_KEY"))
model = genai.GenerativeModel("gemini-2.0-flash")

app = Flask(__name__)
CORS(app)

# Setup
UPLOAD_FOLDER = 'uploads'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

# Add route to serve uploaded files
@app.route('/uploads/<path:filename>')
def serve_file(filename):
    return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

db = TinyDB('books.json')
Book = Query()

@app.route('/upload-book', methods=['POST'])
def upload_book():
    text = ""

    if 'file' not in request.files:
        return jsonify({'error': 'No file uploaded'}), 400

    file = request.files['file']
    filename = secure_filename(file.filename)
    filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
    file.save(filepath)

    # Extract text using PyMuDF
    try:
        with PYMuDF.open(filepath) as doc:
            text = "\n".join([page.get_text() for page in doc])
            print("Extraction Completed\n")
    except Exception as e:
        return jsonify({'error': f'Failed to parse PDF: {str(e)}'}), 500

    # Determine next ID
    existing_books = db.all()
    next_id = 1 if not existing_books else max(b['id'] for b in existing_books) + 1

    # Construct book object
    book = {
        "id": next_id,
        "name": text.strip().split('\n')[0] if text else f"Book {next_id}",
        "content": text,
        "summary": "",
        "quizzes": [],
        "attempts": [],
        "filepath": filepath  # Store the file path
    }

    db.insert(book)

    return jsonify({'message': 'Book uploaded successfully', 'id': next_id})

@app.route('/books', methods=['GET'])
def get_all_books():
    books = db.all()
    # Convert file paths to relative paths for security
    for book in books:
        if 'filepath' in book:
            book['filepath'] = os.path.relpath(book['filepath'], app.config['UPLOAD_FOLDER'])
    return jsonify(books)

@app.route('/book-names', methods=['GET'])
def get_book_names():
    books = db.all()
    names = [{"id": b["id"], "name": b["name"]} for b in books]
    return jsonify(names), 200

@app.route('/book/<int:book_id>', methods=['GET'])
def get_book_content(book_id):
    book = db.get(Book.id == book_id)
    if not book:
        return jsonify({'error': 'Book not found'}), 404

    return jsonify({'content': book['content']}), 200

@app.route('/delete-all', methods=['GET'])
def delete_all_books():
    db.truncate()
    return jsonify({"message": "All data deleted from the database."}), 200

@app.route('/delete-book/<int:book_id>', methods=['GET'])
def delete_book(book_id):
    db.remove(Book.id == book_id)
    return jsonify({"message": f"Book with ID {book_id} deleted."}), 200

def parse_gemini_response(text):
    match = re.search(r'\[(.*?)\]', text)
    if not match:
        return None

    raw = match.group(1)
    cleaned = re.sub(r'[^a-zA-Z0-9,\s]', '', raw)
    parts = [p.strip().lower() for p in cleaned.split(',') if p.strip()]

    if len(parts) < 3:
        return None

    return {
        "action": parts[0],
        "book_id": int(parts[1]) if parts[1].isnumeric() else None,
        "name_match": parts[2] if parts[2].isalpha() else None
    }


@app.route('/interpret', methods=['POST'])
def interpret_user_input():
    try:
        data = request.get_json()
        transcript = data.get("transcript", "")

        # Instead of calling get_book_names(), get the books directly
        books = db.all()
        booksStr = json.dumps(books)

        prompt = f"""
                You are an assistant for a voice-powered learning app. From the following user command, identify their intent. Respond only with a list in this format:
                
                [action, book_id, name_match]
                
                Where:
                - action is summarize, quiz, narrate, or none if it's unclear
                - book_id is an integer from the list below
                - name_match is the name or number of the chapter
                
                Respond ONLY with the list. No extra text.
                
                User command:
                "{transcript}"
                
                Available books:
                {booksStr}
                """

        response = model.generate_content(prompt)
        parsed = parse_gemini_response(response.text)

        if not parsed:
            return jsonify({"error": "Failed to parse Gemini response"}), 400

        action = parsed["action"]
        book_id = parsed["book_id"]
        chapter_name = parsed["name_match"]

        print(action)

        if action == "summarize":
            return jsonify(generate_summary(book_id)), 200
        elif action == "quiz":
            return jsonify(generate_quiz(book_id)), 200
        elif action == "narrate":
            return jsonify(narrate_chapter(book_id)), 200
        else:
            return jsonify({"error": "No action detected"}), 200

    except Exception as e:
        app.logger.error("Error in /interpret: %s", str(e))
        return jsonify({"error": str(e)}), 500


def generate_summary(book_id):
    # print(f"[Summary] Book ID: {book_id}, Chapter: {name_match}")
    book = db.get(Book.id == book_id)
    if not book:
        return {"error": "Book not found"}

    if book["summary"]:
        return {"summary": book["summary"], "source": "cached"}

    full_text = book["content"].strip()

    if not full_text:
        return {"error": "Book content is empty"}

    prompt = f"""
    Summarize the following educational content in a way that is clear and accessible for a middle school student. Only provide the summary and nothing else. It shouldn't be more than 3 sentences.

    {full_text}
    """

    try:
        response = model.generate_content(prompt)
        summary_text = response.text.strip()

        db.update({"summary": summary_text}, Book.id == book_id)

        return {"summary": summary_text, "source": "generated"}

    except Exception as e:
        return {"error": f"Gemini failed: {str(e)}"}
    
def narrate_chapter(book_id):
    book = db.get(Book.id == book_id)
    if not book:
        return {"error": "Book not found"}

    return {
        "text": book["content"], 
        "status": "ready"
    }


def generate_quiz(book_id):
    # Use content to generate a quiz via Gemini and take the quiz
    # return {"status": "quiz generated"}
    book = db.get(Book.id == book_id)
    if not book:
        return {"error": "Book not found"}

    full_text = book["content"].strip()

    if not full_text:
        return {"error": "Book content is empty"}

    prompt = f"""
    Generate three quiz questions based on the following educational content. The questions should be suitable for a middle school student. There should be 4 options for each question and the correct answer should be included. It should be plain text without special characters and no markdown formatting.
    
    Example:
    Question: What is the capital of France?
    A. London
    B. Paris
    C. Berlin
    D. Madrid
    Correct Answer: B

    {full_text}
    """

    try:
        response = model.generate_content(prompt)
        new_quiz = response.text.strip()

        # Retrieve the book from the database
        book = db.get(Book.id == book_id)
        if not book:
            return {"error": "Book not found"}

        # Get the existing quizzes list (or use an empty list if none exists)
        existing_quizzes = book.get("quizzes", [])

        # Append the new quiz to the list
        updated_quizzes = existing_quizzes + [new_quiz]

        # Update the book record with the new list of quizzes
        db.update({"quizzes": updated_quizzes}, Book.id == book_id)

        return {"quiz": new_quiz, "source": "generated"}
    except Exception as e:
        return {"error": f"Gemini failed: {str(e)}"}

@app.route('/get-quiz/<int:book_id>', methods=['GET'])
def get_quiz(book_id):
    book = db.get(Book.id == book_id)
    if not book:
        return jsonify({"error": "Book not found"}), 404

    return jsonify({"quizzes": book["quizzes"]})

def take_quiz(book_id, name_match):
    print(f"[Take Quiz] Book ID: {book_id}, Chapter: {name_match}")
    # Return quiz from DB or ask questions
    return {"status": "quiz started"}


# Expose the URL and Port
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5004, debug=True)
