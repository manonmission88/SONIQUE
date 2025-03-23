import { useState } from 'react';
import KidMode from './components/KidMode';
import ParentMode from './components/ParentMode';
import NavBar from './components/NavBar';
import './App.css';

function App() {
  const [isKidMode, setIsKidMode] = useState(false);

  return (
    <div className="app-container">
      <NavBar />
      <div className="content-container">
        {isKidMode ? (
          <KidMode switchToParent={() => setIsKidMode(false)} />
        ) : (
          <ParentMode switchToKid={() => setIsKidMode(true)} />
        )}
      </div>
    </div>
  );
}

export default App;
