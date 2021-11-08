import React, {useContext} from "react";
import {
  BrowserRouter as Router,
  Switch,
  Route,
  Link,
  useParams
} from "react-router-dom";
import Home from './pages/Home'
import ChatRoom from './pages/ChatRoom'
import NameSelector from "./pages/NameSelector";
import useLocalStorage from "./hooks/useLocalStorage";
import { UsernameContext, UsernameProvider } from "./contexts/UsernameContext";

export default function App() {

  return (
    <div className="bg-gray-900 text-gray-400 min-h-screen">
    <UsernameProvider>
      <Routing/>
    </UsernameProvider>
    </div>
  );
}

function Routing(props) {
  const {name, setName} = useContext(UsernameContext)
  if (name) {
    return (
      <Router>
        <Switch>
          <Route exact path="/">
            <Home />
          </Route>
          <Route path="/rooms/:roomId">
            <ChatRoom />
          </Route>
        </Switch>
      </Router>
    )
  }

  return <NameSelector/>
}