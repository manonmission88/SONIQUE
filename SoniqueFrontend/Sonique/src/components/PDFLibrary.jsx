import React, { useState, useEffect } from 'react';
import './PDFLibrary.css';

function PDFLibrary() {
  const [books, setBooks] = useState([]);
  const [selectedBook, setSelectedBook] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchBooks();
  }, []);

  const fetchBooks = async () => {
    try {
      const response = await fetch('http://localhost:5004/books');
      if (!response.ok) {
        throw new Error('Failed to fetch books');
      }
      const data = await response.json();
      setBooks(data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleBookClick = (book) => {
    setSelectedBook(book);
  };

  const handleCloseViewer = () => {
    setSelectedBook(null);
  };

  if (loading) {
    return <div className="pdf-library-loading">Loading books...</div>;
  }

  if (error) {
    return <div className="pdf-library-error">Error: {error}</div>;
  }

  return (
    <div className="pdf-library-container">
      <h2 className="pdf-library-title">Your PDF Library</h2>
      
      <div className="pdf-grid">
        {books.map((book) => (
          <div key={book.id} className="pdf-card" onClick={() => handleBookClick(book)}>
            <div className="pdf-icon">📚</div>
            <div className="pdf-info">
              <h3 className="pdf-title">{book.name}</h3>
              <p className="pdf-date">Uploaded: {new Date().toLocaleDateString()}</p>
            </div>
          </div>
        ))}
      </div>

      {selectedBook && (
        <div className="pdf-viewer-modal">
          <div className="pdf-viewer-content">
            <div className="pdf-viewer-header">
              <h3>{selectedBook.name}</h3>
              <button className="close-button" onClick={handleCloseViewer}>×</button>
            </div>
            <div className="pdf-viewer-body">
              <iframe
                src={`http://localhost:5004/uploads/${selectedBook.filepath}`}
                title={selectedBook.name}
                width="100%"
                height="100%"
              />
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default PDFLibrary; 