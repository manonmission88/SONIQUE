# # @app.route("/quiz", methods=["GET"])
# # def get_quiz():
# #     chapter = request.args.get("chapter")
# #     doc = db.chapters.find_one({"chapter_id": chapter})
# #     return jsonify(doc["quiz"])


from flask import Flask, request, jsonify
from flask_cors import CORS
from werkzeug.utils import secure_filename
from tinydb import TinyDB, Query
import os
import fitz  # PyMuPDF for PDF parsing

app = Flask(__name__)
CORS(app)

# Setup
UPLOAD_FOLDER = 'uploads'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

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

    # Extract text using PyMuPDF
    try:
        with fitz.open(filepath) as doc:
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
        "attempts": []
    }

    db.insert(book)

    return 201, jsonify({'message': 'Book uploaded successfully', 'id': next_id})

@app.route('/all-books', methods=['GET'])
def get_all_books():
    books = db.all()
    return jsonify(books), 200

# @app.route('/books', methods=['GET'])
# def get_books_metadata():
#     all_books = db.all()
#     # metadata = [{"id": b["id"], "summary": b["summary"]} for b in all_books] 
#     # Needed when we move on to generating new summary or receiving an already-generated one

#     return jsonify(metadata), 200


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