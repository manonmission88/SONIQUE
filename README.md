# Sonique - Voice-Interactive Learning Companion for Visually Impaired

## About the Project
Sonique is an AI-powered, voice-interactive learning companion designed for blind and visually impaired children. It transforms caregiver-uploaded educational materials into engaging audio lessons, enabling children to learn and interact using natural voice commands. Our mission is to make education accessible, independent, and joyful—without relying on screens or text.

## Features
- **Caregiver Upload Portal:** Upload PDF files as course materials and manage them in a library.
- **AI-Generated Quizzes:** Generate practice quizzes from uploaded content using the Gemini API.
- **Voice Input and Response:** Fully voice-based interaction, eliminating the need for screens.
- **Book Management:** View uploaded books with file names and open previews in a modal.
- **PDF/Text Preview:** Display PDF files using PDF.js or show text directly if no PDF is available.

## Tech Stack
- **Backend:** Python, Flask, TinyDB, PyMuPDF (fitz), Google Gemini API
- **Frontend:** React.js, Vite, PDF.js, HTML/CSS, Swift for IOS
- **Environment Management:** dotenv for API keys and configurations

## Setup and Installation
1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/sonique.git
   frontend : cd sonique & cd SoniqueFrontend/sonique & npm run dev 
    backend : cd sonique & cd SoniqueBackend/python3 app.py
    ios app : ContentView.swift (preview content) 
