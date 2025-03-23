import React from 'react';

function ParentMode({ switchToKid }) {
  // File upload handler
  const handleFileUpload = async (e) => {
    const file = e.target.files[0];
    if (!file) return;

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
      alert(`Upload success: ${JSON.stringify(data)}`);
    } catch (error) {
      console.error("Upload error:", error);
      alert(`Upload error: ${error.message}`);
    }
  };

  return (
    <div style={{ textAlign: "center", marginTop: "50px" }}>
      <h1>Parent Mode</h1>
      <p>This is the view for parents. Upload a file below.</p>
      <input type="file" accept=".pdf" onChange={handleFileUpload} />
      <br />
      <br />
      <button onClick={switchToKid}>Switch to Kid Mode</button>
    </div>
  );
}

export default ParentMode;