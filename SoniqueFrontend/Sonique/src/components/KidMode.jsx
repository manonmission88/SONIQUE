import React, { useEffect } from 'react';

function KidMode({ switchToParent }) {
  useEffect(() => {
    // Attempt to speak the greeting on mount.
    const greeting = new SpeechSynthesisUtterance("Hello, what do you want to do today?");
    greeting.lang = "en-US";
    window.speechSynthesis.speak(greeting);

    // Wait 6 seconds, then start listening for the user's response.
    const timer = setTimeout(() => {
      const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
      if (!SpeechRecognition) {
        console.error("Speech recognition not supported in this browser.");
        return;
      }
      const recognition = new SpeechRecognition();
      recognition.lang = "en-US";
      recognition.interimResults = false;
      recognition.maxAlternatives = 1;

      recognition.start();
      console.log("Speech recognition started.");

      recognition.onresult = (event) => {
        const transcript = event.results[0][0].transcript;
        console.log("User said:", transcript);
      };

      recognition.onerror = (event) => {
        console.error("Speech recognition error:", event.error);
      };

      recognition.onend = () => {
        console.log("Speech recognition ended.");
      };
    }, 6000);

    return () => clearTimeout(timer);
  }, []);

  return (
    <div style={{ textAlign: "center", marginTop: "50px" }}>
      <h1>Kid Mode</h1>
      <p>
        The voice assistant should greet you with "Hello, what do you want to do today?" and after 6 seconds it will start listening for your response. Check the console for the transcribed response.
      </p>
      <button onClick={switchToParent}>Switch to Parent Mode</button>
    </div>
  );
}

export default KidMode;