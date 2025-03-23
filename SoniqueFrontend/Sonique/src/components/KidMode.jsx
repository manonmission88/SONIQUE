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

<<<<<<< HEAD
=======
    // Recursive interaction function.
>>>>>>> 1e44cfe (all updated)
    function interact() {
      if (!isMounted || sessionEnded) return;

      setRecording(false);
<<<<<<< HEAD
      setStatusText('Waiting for your command...');

=======
      setStatusText("Waiting for your command...");

      // Speak the greeting with instructions.
>>>>>>> 1e44cfe (all updated)
      const greeting = new SpeechSynthesisUtterance(
        "Please tell me what you want me to do, or say stop to end the voice session."
      );
      greeting.lang = "en-US";

      greeting.onend = () => {
        if (!isMounted || sessionEnded) return;
        setStatusText("Listening...");
        console.log("Greeting finished. Starting speech recognition...");
        const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
        if (!SpeechRecognition) {
          console.error("Speech recognition not supported in this browser.");
          setStatusText("Speech recognition not supported.");
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
<<<<<<< HEAD

          if (transcript.trim().toLowerCase().includes("stop")) {
            sessionEnded = true;
            setRecording(false);
            setStatusText('Voice session ended');
=======
          setStatusText("Processing your request...");
          if (transcript.trim().toLowerCase().includes("stop")) {
            sessionEnded = true;
            setRecording(false);
            setStatusText("Voice session ended.");
>>>>>>> 1e44cfe (all updated)
            const endUtterance = new SpeechSynthesisUtterance("Voice session ended.");
            endUtterance.lang = "en-US";
            window.speechSynthesis.speak(endUtterance);
            return;
          }
<<<<<<< HEAD

=======
          // Send transcript to backend.
>>>>>>> 1e44cfe (all updated)
          fetch("http://localhost:5004/interpret", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
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
<<<<<<< HEAD
              setStatusText('');
              
=======
              setStatusText("");
              // If backend returns error "No action detected", ask again.
>>>>>>> 1e44cfe (all updated)
              if (data.error && data.error === "No action detected") {
                const retry = new SpeechSynthesisUtterance(
                  "I didn't catch that, please say it again."
                );
                retry.lang = "en-US";
                retry.onend = () => {
                  if (isMounted && !sessionEnded) interact();
                };
                window.speechSynthesis.speak(retry);
<<<<<<< HEAD
              } else if (
                (data.text && data.text.trim() !== "") ||
                (data.summary && data.summary.trim() !== "")
              ) {
                const content = data.text && data.text.trim() !== ""
                  ? data.text
                  : data.summary;
                const cleanText = content.replace(/[^\w\s.,?!]/g, "");
=======
              } else if (data.quiz && data.quiz.trim() !== "") {
                // If a quiz is generated, announce it.
                const quizMsg = new SpeechSynthesisUtterance("Quiz generated and can be accessed on Parent Mode.");
                quizMsg.lang = "en-US";
                quizMsg.onend = () => { if (isMounted && !sessionEnded) interact(); };
                window.speechSynthesis.speak(quizMsg);
              } else if ((data.text && data.text.trim() !== "") || (data.summary && data.summary.trim() !== "")) {
                const content = (data.text && data.text.trim() !== "") ? data.text : data.summary;
                // Clean the text.
                const cleanText = content.replace(/[^\w\s.,?!]/g, '');
>>>>>>> 1e44cfe (all updated)
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
<<<<<<< HEAD
              setStatusText('Error processing request');
=======
              setStatusText("Error processing request.");
>>>>>>> 1e44cfe (all updated)
            });
        };

        recognition.onerror = (event) => {
          console.error("Speech recognition error:", event.error);
          setRecording(false);
<<<<<<< HEAD
          setStatusText('Error with speech recognition');
=======
          setStatusText("Error with speech recognition.");
>>>>>>> 1e44cfe (all updated)
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
<<<<<<< HEAD
      <div className={`mic-container ${recording ? 'recording' : ''}`}>
        <div className="wave"></div>
        <div className="wave"></div>
        <div className="wave"></div>
        <span
          className={`mic-icon ${recording ? 'pulsate' : ''}`}
          role="img"
          aria-label="microphone"
        >
=======
      <div className="mic-container">
        <div className="wave"></div>
        <div className="wave"></div>
        <div className="wave"></div>
        <span className={`mic-icon ${recording ? 'pulsate' : ''}`} role="img" aria-label="microphone">
>>>>>>> 1e44cfe (all updated)
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






// import React, { useEffect, useState } from 'react';
// import './KidMode.css';

// function KidMode({ switchToParent }) {
//   const [recording, setRecording] = useState(false);
//   const [statusText, setStatusText] = useState('');

//   useEffect(() => {
//     let isMounted = true;       // flag to track if KidMode is mounted
//     let sessionEnded = false;   // flag to track if the user said "stop"

//     // Create an AudioContext (used to unlock audio playback)
//     const audioCtx = new (window.AudioContext || window.webkitAudioContext)();

//     // One-time event listener for user interaction to resume the AudioContext.
//     const resumeAudio = () => {
//       if (audioCtx.state === "suspended") {
//         audioCtx.resume().then(() => {
//           console.log("AudioContext resumed after user interaction.");
//         }).catch((err) => {
//           console.error("AudioContext resume error:", err);
//         });
//       }
//     };
//     document.body.addEventListener("click", resumeAudio, { once: true });

//     // Recursive interaction function.
//     function interact() {
//       if (!isMounted || sessionEnded) return; // exit if unmounted or session ended

//       setRecording(false);
//       setStatusText("Waiting for your command...");

//       const greeting = new SpeechSynthesisUtterance("Please tell me what you want me to do, or say stop to end the voice session.");
//       greeting.lang = "en-US";

//       greeting.onend = () => {
//         if (!isMounted || sessionEnded) return;
//         setStatusText("Listening...");
//         console.log("Greeting finished. Starting speech recognition...");
//         const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
//         if (!SpeechRecognition) {
//           console.error("Speech recognition not supported in this browser.");
//           setStatusText("Speech recognition not supported.");
//           return;
//         }
//         const recognition = new SpeechRecognition();
//         recognition.lang = "en-US";
//         recognition.interimResults = false;
//         recognition.maxAlternatives = 1;
//         let recognized = false;

//         setRecording(true);

//         recognition.onresult = (event) => {
//           recognized = true;
//           setRecording(false);
//           const transcript = event.results[0][0].transcript;
//           console.log("User said:", transcript);
//           setStatusText("Processing your request...");
//           if (transcript.trim().toLowerCase().includes("stop")) {
//             sessionEnded = true;
//             setRecording(false);
//             setStatusText("Voice session ended.");
//             const endUtterance = new SpeechSynthesisUtterance("Voice session ended.");
//             endUtterance.lang = "en-US";
//             window.speechSynthesis.speak(endUtterance);
//             return;
//           }
//           fetch("http://localhost:5004/interpret", {
//             method: "POST",
//             headers: {
//               "Content-Type": "application/json",
//             },
//             body: JSON.stringify({ transcript }),
//           })
//             .then((response) => {
//               if (!response.ok) {
//                 throw new Error(`Server error: ${response.status}`);
//               }
//               return response.json();
//             })
//             .then((data) => {
//               console.log("Response from /interpret:", data);
//               setStatusText("");
//               if (data.error && data.error === "No action detected") {
//                 const retry = new SpeechSynthesisUtterance("I didn't catch that, please say it again.");
//                 retry.lang = "en-US";
//                 retry.onend = () => { if (isMounted && !sessionEnded) interact(); };
//                 window.speechSynthesis.speak(retry);
//               } else if ((data.text && data.text.trim() !== "") || (data.summary && data.summary.trim() !== "")) {
//                 const content = (data.text && data.text.trim() !== "") ? data.text : data.summary;
//                 const cleanText = content.replace(/[^\w\s.,?!]/g, '');
//                 const narration = new SpeechSynthesisUtterance(cleanText);
//                 narration.lang = "en-US";
//                 narration.onend = () => { if (isMounted && !sessionEnded) interact(); };
//                 window.speechSynthesis.speak(narration);
//               } else {
//                 const retry = new SpeechSynthesisUtterance("I didn't catch that, please say it again.");
//                 retry.lang = "en-US";
//                 retry.onend = () => { if (isMounted && !sessionEnded) interact(); };
//                 window.speechSynthesis.speak(retry);
//               }
//             })
//             .catch((error) => {
//               console.error("Error sending transcript:", error);
//               setStatusText("Error processing request.");
//             });
//         };

//         recognition.onerror = (event) => {
//           console.error("Speech recognition error:", event.error);
//           setRecording(false);
//           setStatusText("Error with speech recognition.");
//         };

//         recognition.onend = () => {
//           console.log("Speech recognition ended.");
//           setRecording(false);
//           if (!recognized && isMounted && !sessionEnded) {
//             const retry = new SpeechSynthesisUtterance("I didn't catch that, please say it again.");
//             retry.lang = "en-US";
//             retry.onend = () => { if (isMounted && !sessionEnded) interact(); };
//             window.speechSynthesis.speak(retry);
//           }
//         };

//         recognition.start();
//         setTimeout(() => {
//           if (recognition && !recognized) {
//             recognition.stop();
//           }
//         }, 10000);
//       };

//       window.speechSynthesis.speak(greeting);
//     }

//     interact();

//     return () => {
//       isMounted = false;
//       document.body.removeEventListener("click", resumeAudio);
//     };
//   }, []);

//   return (
//     <div className="kid-mode-container">
//       <h1 className="app-title">Learning Mode</h1>
//       <div className="mic-container">
//         <div className="wave"></div>
//         <div className="wave"></div>
//         <div className="wave"></div>
//         <span className={`mic-icon ${recording ? 'pulsate' : ''}`} role="img" aria-label="microphone">
//           🎤
//         </span>
//       </div>
//       {statusText && <p className="status-text">{statusText}</p>}
//       <button className="mode-switch-btn" onClick={switchToParent}>
//         Switch to Parent Mode
//       </button>
//     </div>
//   );
// }

// export default KidMode;