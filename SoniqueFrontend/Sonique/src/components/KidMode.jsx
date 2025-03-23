import React, { useEffect, useState } from 'react';
import './KidMode.css';

function KidMode({ switchToParent }) {
  const [recording, setRecording] = useState(false);
  const [statusText, setStatusText] = useState('');

  useEffect(() => {
    let isMounted = true;
    let sessionEnded = false;

    const audioCtx = new (window.AudioContext || window.webkitAudioContext)();

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

    function interact() {
      if (!isMounted || sessionEnded) return;

      setRecording(false);
      setStatusText('Waiting for your command...');

      const greeting = new SpeechSynthesisUtterance(
        "Please tell me what you want me to do, or say stop to end the voice session."
      );
      greeting.lang = "en-US";

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

        setRecording(true);
        setStatusText('Listening...');

        recognition.onresult = (event) => {
          recognized = true;
          setRecording(false);
          const transcript = event.results[0][0].transcript;
          setStatusText('Processing your request...');
          console.log("User said:", transcript);

          if (transcript.trim().toLowerCase().includes("stop")) {
            sessionEnded = true;
            setRecording(false);
            setStatusText('Voice session ended');
            const endUtterance = new SpeechSynthesisUtterance("Voice session ended.");
            endUtterance.lang = "en-US";
            window.speechSynthesis.speak(endUtterance);
            return;
          }

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
              setStatusText('');
              
              if (data.error && data.error === "No action detected") {
                const retry = new SpeechSynthesisUtterance(
                  "I didn't catch that, please say it again."
                );
                retry.lang = "en-US";
                retry.onend = () => {
                  if (isMounted && !sessionEnded) interact();
                };
                window.speechSynthesis.speak(retry);
              } else if (
                (data.text && data.text.trim() !== "") ||
                (data.summary && data.summary.trim() !== "")
              ) {
                const content = data.text && data.text.trim() !== ""
                  ? data.text
                  : data.summary;
                const cleanText = content.replace(/[^\w\s.,?!]/g, "");
                const narration = new SpeechSynthesisUtterance(cleanText);
                narration.lang = "en-US";
                narration.onend = () => {
                  if (isMounted && !sessionEnded) interact();
                };
                window.speechSynthesis.speak(narration);
              } else {
                const retry = new SpeechSynthesisUtterance(
                  "I didn't catch that, please say it again."
                );
                retry.lang = "en-US";
                retry.onend = () => {
                  if (isMounted && !sessionEnded) interact();
                };
                window.speechSynthesis.speak(retry);
              }
            })
            .catch((error) => {
              console.error("Error sending transcript:", error);
              setStatusText('Error processing request');
            });
        };

        recognition.onerror = (event) => {
          console.error("Speech recognition error:", event.error);
          setRecording(false);
          setStatusText('Error with speech recognition');
        };

        recognition.onend = () => {
          console.log("Speech recognition ended.");
          setRecording(false);
          if (!recognized && isMounted && !sessionEnded) {
            const retry = new SpeechSynthesisUtterance(
              "I didn't catch that, please say it again."
            );
            retry.lang = "en-US";
            retry.onend = () => {
              if (isMounted && !sessionEnded) interact();
            };
            window.speechSynthesis.speak(retry);
          }
        };

        recognition.start();
        setTimeout(() => {
          if (recognition && !recognized) {
            recognition.stop();
          }
        }, 10000);
      };

      window.speechSynthesis.speak(greeting);
    }

    interact();

    return () => {
      isMounted = false;
      document.body.removeEventListener("click", resumeAudio);
    };
  }, []);

  return (
    <div className="kid-mode-container">
      <h1 className="app-title">Learning Mode</h1>
      <div className={`mic-container ${recording ? 'recording' : ''}`}>
        <div className="wave"></div>
        <div className="wave"></div>
        <div className="wave"></div>
        <span
          className={`mic-icon ${recording ? 'pulsate' : ''}`}
          role="img"
          aria-label="microphone"
        >
          🎤
        </span>
      </div>
      {statusText && <p className="status-text">{statusText}</p>}
      <button className="mode-switch-btn" onClick={switchToParent}>
        Switch to Parent Mode
      </button>
    </div>
  );
}

export default KidMode;
