import React from "react";
import {
  BrowserRouter as Router,
  Switch,
  Route,
  Link,
  useParams
} from "react-router-dom";
import Home from './pages/Home'
import ChatRoom from './pages/ChatRoom'

export default function App() {
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
  );
}

function ChatRoomOld(props) {
  let { roomId } = useParams();
  return <h2>Not Impl: {roomId}</h2>;
}

function UsersOld() {
  return <h2>Users</h2>;
}