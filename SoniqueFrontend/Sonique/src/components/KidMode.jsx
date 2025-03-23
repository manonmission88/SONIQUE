import React, { useEffect, useState } from 'react';
import './KidMode.css';

function KidMode({ switchToParent }) {
  const [recording, setRecording] = useState(false);

  useEffect(() => {
    let isMounted = true;       // flag to track if KidMode is mounted
    let sessionEnded = false;   // flag to track if the user said "stop"

    // Create an AudioContext (used to unlock audio playback)
    const audioCtx = new (window.AudioContext || window.webkitAudioContext)();

    // One-time event listener for user interaction to resume the AudioContext.
    const resumeAudio = () => {
      if (audioCtx.state === "suspended") {
        audioCtx.resume().then(() => {
          console.log("AudioContext resumed after user interaction.");
        }).catch((err) => {
          console.error("AudioContext resume error:", err);
        });
      }
    };
    document.body.addEventListener("click", resumeAudio, { once: true });

    // Define the recursive interaction function.
    function interact() {
      if (!isMounted || sessionEnded) return; // exit if unmounted or session ended

      // Update UI: set recording to false initially.
      setRecording(false);

      // Speak the greeting with instruction.
      const greeting = new SpeechSynthesisUtterance("Please tell me what you want me to do, or say stop to end the voice session.");
      greeting.lang = "en-US";

      // Once the greeting is done, start speech recognition.
      greeting.onend = () => {
        if (!isMounted || sessionEnded) return;
        console.log("Greeting finished. Starting speech recognition...");
        const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
        if (!SpeechRecognition) {
          console.error("Speech recognition not supported in this browser.");
          return;
        }
        const recognition = new SpeechRecognition();
        recognition.lang = "en-US";
        recognition.interimResults = false;
        recognition.maxAlternatives = 1;
        let recognized = false;

        // Set recording true while listening.
        setRecording(true);

        recognition.onresult = (event) => {
          recognized = true;
          setRecording(false);
          const transcript = event.results[0][0].transcript;
          console.log("User said:", transcript);
          // Check if user said "stop"
          if (transcript.trim().toLowerCase().includes("stop")) {
            sessionEnded = true;
            setRecording(false);
            const endUtterance = new SpeechSynthesisUtterance("Voice session ended.");
            endUtterance.lang = "en-US";
            window.speechSynthesis.speak(endUtterance);
            return;
          }
          // Send transcript to the backend endpoint.
          fetch("http://localhost:5004/interpret", {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
            },
            body: JSON.stringify({ transcript }),
          })
            .then((response) => {
              if (!response.ok) {
                throw new Error(`Server error: ${response.status}`);
              }
              return response.json();
            })
            .then((data) => {
              console.log("Response from /interpret:", data);
              if (data.error && data.error === "No action detected") {
                const retry = new SpeechSynthesisUtterance("I didn't catch that, please say it again.");
                retry.lang = "en-US";
                retry.onend = () => { if (isMounted && !sessionEnded) interact(); };
                window.speechSynthesis.speak(retry);
              } else if ((data.text && data.text.trim() !== "") || (data.summary && data.summary.trim() !== "")) {
                const content = (data.text && data.text.trim() !== "") ? data.text : data.summary;
                // Clean the text.
                const cleanText = content.replace(/[^\w\s.,?!]/g, '');
                const narration = new SpeechSynthesisUtterance(cleanText);
                narration.lang = "en-US";
                narration.onend = () => { if (isMounted && !sessionEnded) interact(); };
                window.speechSynthesis.speak(narration);
              } else {
                const retry = new SpeechSynthesisUtterance("I didn't catch that, please say it again.");
                retry.lang = "en-US";
                retry.onend = () => { if (isMounted && !sessionEnded) interact(); };
                window.speechSynthesis.speak(retry);
              }
            })
            .catch((error) => {
              console.error("Error sending transcript:", error);
            });
        };

        recognition.onerror = (event) => {
          console.error("Speech recognition error:", event.error);
          setRecording(false);
        };

        recognition.onend = () => {
          console.log("Speech recognition ended.");
          setRecording(false);
          if (!recognized && isMounted && !sessionEnded) {
            const retry = new SpeechSynthesisUtterance("I didn't catch that, please say it again.");
            retry.lang = "en-US";
            retry.onend = () => { if (isMounted && !sessionEnded) interact(); };
            window.speechSynthesis.speak(retry);
          }
        };

        // Start recognition and stop it after 10 seconds if still active.
        recognition.start();
        setTimeout(() => {
          if (recognition && !recognized) {
            recognition.stop();
          }
        }, 10000);
      };

      // Speak the greeting.
      window.speechSynthesis.speak(greeting);
    }

    // Begin the interaction cycle when KidMode mounts.
    interact();

    return () => {
      isMounted = false; // Mark component as unmounted
      document.body.removeEventListener("click", resumeAudio);
    };
  }, []);

  return (
    <div style={{ textAlign: "center", marginTop: "50px", padding: "20px" }}>
      <h1>Learning Mode</h1>
      {/* Animated microphone icon */}
      <div className="mic-container">
        <span className={`mic-icon ${recording ? 'pulsate' : ''}`} role="img" aria-label="microphone">
          🎤
        </span>
      </div>
      <p>
        SONIQUE
      </p>
      <button onClick={switchToParent}>Switch to Parent Mode</button>
    </div>
  );
}

export default KidMode;
