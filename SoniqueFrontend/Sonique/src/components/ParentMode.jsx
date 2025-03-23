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