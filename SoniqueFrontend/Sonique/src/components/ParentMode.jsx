import React, { useState } from 'react';
import PDFLibrary from './PDFLibrary';
import './ParentMode.css';

function ParentMode({ switchToKid }) {
  const [uploading, setUploading] = useState(false);
  const [uploadStatus, setUploadStatus] = useState('');

  // File upload handler
  const handleFileUpload = async (e) => {
    const file = e.target.files[0];
    if (!file) return;

    setUploading(true);
    setUploadStatus('Uploading...');
    console.log("Selected file:", file.name);

    // Build FormData and send to the backend at localhost:5004/upload-book
    const formData = new FormData();
    formData.append("file", file);
    try {
      const response = await fetch("http://localhost:5004/upload-book", {
        method: "POST",
        body: formData,
      });
      if (!response.ok) {
        throw new Error(`Server error: ${response.status}`);
      }
      const data = await response.json();
      console.log("Upload success:", data);
      setUploadStatus('Upload successful!');
      setTimeout(() => setUploadStatus(''), 3000);
    } catch (error) {
      console.error("Upload error:", error);
      setUploadStatus(`Upload failed: ${error.message}`);
    } finally {
      setUploading(false);
    }
  };

  // When a file card is clicked, store it and show the options.
  const handleCardClick = (book) => {
    setSelectedBook(book);
    setViewMode(null);
    setPreviewContent("");
  };

  // Handler to load text content.
  const loadTextContent = async () => {
    try {
      const response = await fetch(`http://127.0.0.1:5004/book/${selectedBook.id}`);
      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new Error(errorData.error || `Server error: ${response.status}`);
      }
      const data = await response.json();
      if (data.content) {
        setPreviewContent(data.content);
        setViewMode("text");
      } else {
        throw new Error("No content found.");
      }
    } catch (error) {
      console.error("Error fetching book content:", error);
      alert(`Failed to load book content: ${error.message}`);
      setPreviewContent("");
    }
  };

  // Handler to load quizzes.
  const loadQuizzes = async () => {
    try {
      const response = await fetch(`http://127.0.0.1:5004/get-quiz/${selectedBook.id}`);
      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new Error(errorData.error || `Server error: ${response.status}`);
      }
      const data = await response.json();
      if (data.quizzes && data.quizzes.length > 0) {
        // Join quizzes with newlines.
        setPreviewContent(data.quizzes.join("\n\n"));
        setViewMode("quiz");
      } else {
        setPreviewContent("Quizzes not generated at the moment.");
        setViewMode("quiz");
      }
    } catch (error) {
      console.error("Error fetching quizzes:", error);
      alert(`Failed to load quizzes: ${error.message}`);
      setPreviewContent("");
    }
  };

  // Handler to generate a quiz.
  const generateQuiz = async () => {
    try {
      // Here we simulate quiz generation by sending a transcript that triggers quiz generation.
      // You might want to adjust the transcript text as needed.
      const transcript = "quiz";
      const response = await fetch("http://localhost:5004/interpret", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ transcript }),
      });
      if (!response.ok) {
        throw new Error(`Server error: ${response.status}`);
      }
      const data = await response.json();
      // Assume the response contains a "quiz" field with the newly generated quiz.
      if (data.quiz && data.quiz.trim() !== "") {
        // Append the new quiz if desired (or just show it).
        setPreviewContent(data.quiz);
        alert("Quiz generated. You can now review it.");
      } else {
        alert("Quiz generation returned no results.");
      }
    } catch (error) {
      console.error("Error generating quiz:", error);
      alert(`Failed to generate quiz: ${error.message}`);
    }
  };

  // Back button handler.
  const handleBack = () => {
    setSelectedBook(null);
    setViewMode(null);
    setPreviewContent("");
  };

  return (
    <div className="parent-mode-container">
      <h1 className="app-title">Parent Mode</h1>
      <div className="upload-section">
        <div className="upload-icon">📚</div>
        <p className="upload-text">Upload Course Material(s)</p>
        <label className="file-upload-btn" htmlFor="file-upload">
          Choose PDF File
          <input
            id="file-upload"
            type="file"
            accept=".pdf"
            onChange={handleFileUpload}
            style={{ display: 'none' }}
          />
        </label>
        {uploadStatus && (
          <div className={`upload-status ${uploading ? 'uploading' : ''}`}>
            {uploadStatus}
          </div>
        )}
      </div>
      
      {/* PDF Library Section */}
      <div className="pdf-library-section">
        <PDFLibrary />
      </div>

      <button className="mode-switch-btn" onClick={switchToKid}>
        Switch to Learning Mode
      </button>
    </div>
  );
}

export default ParentMode;



// import React, { useState, useEffect } from 'react';
// import './ParentMode.css';

// function ParentMode({ switchToKid }) {
//   const [uploadedBooks, setUploadedBooks] = useState([]);
//   const [isLoading, setIsLoading] = useState(false);
//   const [selectedBookContent, setSelectedBookContent] = useState("");
//   const [selectedBookTitle, setSelectedBookTitle] = useState("");

//   // Fetch book names when component mounts.
//   useEffect(() => {
//     fetchBookNames();
//   }, []);

//   const fetchBookNames = async () => {
//     setIsLoading(true);
//     try {
//       const response = await fetch("http://127.0.0.1:5004/book-names");
//       if (!response.ok) {
//         throw new Error(`Error fetching books: ${response.status}`);
//       }
//       const data = await response.json();
//       setUploadedBooks(data);
//     } catch (error) {
//       console.error("Error fetching books:", error);
//     } finally {
//       setIsLoading(false);
//     }
//   };

//   // File upload handler.
//   const handleFileUpload = async (e) => {
//     const file = e.target.files[0];
//     if (!file) return;

//     if (!file.type.includes('pdf')) {
//       alert('Please select a PDF file.');
//       return;
//     }

//     const formData = new FormData();
//     formData.append("file", file);

//     try {
//       const response = await fetch("http://localhost:5004/upload-book", {
//         method: "POST",
//         body: formData,
//       });
//       if (!response.ok) {
//         throw new Error(`Server error: ${response.status}`);
//       }
//       const data = await response.json();
//       alert(`Upload success: ${JSON.stringify(data)}`);
//       // Refresh the list after a successful upload.
//       fetchBookNames();
//     } catch (error) {
//       console.error("Upload error:", error);
//       alert(`Upload error: ${error.message}`);
//     }
//   };

//   // Handler to fetch and display book content when a file card is clicked.
//   const handleFileSelect = async (book) => {
//     setSelectedBookTitle(book.name);
//     try {
//       const response = await fetch(`http://127.0.0.1:5004/book/${book.id}`);
//       if (!response.ok) {
//         const errorData = await response.json().catch(() => ({}));
//         throw new Error(errorData.error || `Server error: ${response.status}`);
//       }
//       const data = await response.json();
//       if (data.content) {
//         setSelectedBookContent(data.content);
//       } else {
//         throw new Error("No content found.");
//       }
//     } catch (error) {
//       console.error("Error fetching book content:", error);
//       alert(`Failed to load book content: ${error.message}`);
//       setSelectedBookContent("");
//     }
//   };

//   // Handler to delete a book.
//   const handleDeleteBook = async (e, book) => {
//     e.stopPropagation(); // Prevent triggering file selection
//     if (!window.confirm(`Are you sure you want to delete "${book.name}"?`)) {
//       return;
//     }
//     try {
//       const response = await fetch(`http://127.0.0.1:5004/delete-book/${book.id}`, {
//         method: 'GET'  // Using GET as per your API endpoint
//       });
//       if (!response.ok) {
//         const errorData = await response.json().catch(() => ({}));
//         throw new Error(errorData.error || `Server error: ${response.status}`);
//       }
//       alert(`Book "${book.name}" deleted successfully.`);
//       // Refresh the list after deletion.
//       fetchBookNames();
//       // If the deleted book is currently selected, clear the preview.
//       if (selectedBookTitle === book.name) {
//         setSelectedBookContent("");
//         setSelectedBookTitle("");
//       }
//     } catch (error) {
//       console.error("Error deleting book:", error);
//       alert(`Failed to delete book: ${error.message}`);
//     }
//   };

//   // Handler to go back to the file list view.
//   const handleBack = () => {
//     setSelectedBookContent("");
//     setSelectedBookTitle("");
//   };

//   return (
//     <div className="parent-mode">
//       <div className="parent-header">
//         <h1>Parent Mode</h1>
//         <button className="mode-switch-btn" onClick={switchToKid}>
//           Switch to Learning Mode
//         </button>
//       </div>

//       <div className="upload-section">
//         <h2>Upload Course Material(s)</h2>
//         <div className="upload-area">
//           <input
//             type="file"
//             accept=".pdf"
//             onChange={handleFileUpload}
//             id="file-upload"
//             className="file-input"
//           />
//           <label htmlFor="file-upload" className="upload-label">
//             <div className="upload-icon">📄</div>
//             <p>Click or drag and drop to upload a PDF file</p>
//           </label>
//         </div>
//       </div>

//       {/* Show preview if a book is selected; otherwise show file list */}
//       {selectedBookContent ? (
//         <div className="preview-section">
//           <div className="preview-header">
//             <button className="back-btn" onClick={handleBack}>
//               ← Back
//             </button>
//             <h2>Book Preview: {selectedBookTitle}</h2>
//           </div>
//           <div className="text-content">
//             <pre>{selectedBookContent}</pre>
//           </div>
//         </div>
//       ) : (
//         <div className="files-section">
//           <h2>Uploaded Materials {isLoading && <span className="loading-text">Loading...</span>}</h2>
//           {uploadedBooks.length === 0 && !isLoading ? (
//             <div className="no-files">
//               <p>No books uploaded yet.</p>
//             </div>
//           ) : (
//             <div className="files-grid">
//               {uploadedBooks.map((book) => (
//                 <div
//                   key={book.id}
//                   className="file-card"
//                   onClick={() => handleFileSelect(book)}
//                   title={`Click to view content for "${book.name}"`}
//                 >
//                   <div className="file-icon">📚</div>
//                   <div className="file-info">
//                     <h3>{book.name}</h3>
//                     <p>ID: {book.id}</p>
//                   </div>
//                   <button
//                     className="delete-btn"
//                     onClick={(e) => handleDeleteBook(e, book)}
//                     title="Delete this book"
//                   >
//                     🗑️
//                   </button>
//                 </div>
//               ))}
//             </div>
//           )}
//         </div>
//       )}
//     </div>
//   );
// }

// export default ParentMode;
