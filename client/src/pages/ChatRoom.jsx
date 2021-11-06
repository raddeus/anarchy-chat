import "./ChatRoom.css"
import { useEffect, useState, useRef, useContext } from "react";
import { UsernameContext } from "../contexts/UsernameContext";
import {
    useHistory, useParams
} from "react-router-dom";
import { takeRight } from "lodash";

export default () => {
    const {name, setName, prevName} = useContext(UsernameContext)
    let { roomId } = useParams();
    roomId = decodeURIComponent(roomId);

    const messageContainerRef = useRef();
    const [websocket, setWebsocket] = useState(null);
    const [isConnecting, setIsConnecting] = useState(false);
    const [isConnected, setIsConnected] = useState(false);
    const [messages, setMessages] = useState([]);

    const [isFetchingMessages, setIsFetchingMessages] = useState(false);
    useEffect(() => {
        async function fetchMessages() {
            setIsFetchingMessages(true);
            try {
                const response = await fetch('http://localhost:4000/api/messages?room_id=' + encodeURIComponent(roomId));
                const data = await response.json();
                setMessages(data.messages.map(msg => msg.sender + ': ' + msg.content));
            } catch (e) {
                console.error(e);
                setMessages([]);
            }
            setIsFetchingMessages(false)
        }

        fetchMessages();
    }, []);

    const [messageInput, setMessageInput] = useState('');
    const sendMessage = (e) => {
        e.preventDefault();
        if (messageInput && websocket && isConnected) {
            websocket.send(
                JSON.stringify({
                    data: {message: messageInput},
                })
            )
            setMessageInput('');
        }
    }
    const sendBadPacket = (e) => {
        e.preventDefault();
        if (websocket && isConnected) {
            websocket.send('This is a bad (invalid json) packet')
        }
    }
    const crashRoom = (e) => {
        e.preventDefault();
        if (websocket && isConnected) {
            websocket.send(JSON.stringify({
                data: {message: '!crash'},
            }))
        }
    }
    const spamRoom = (e) => {
        e.preventDefault();
        let count = 0;
        let interval = setInterval(() => {
            count++;
            if (count >= 1000) {
                clearTimeout(interval);
            }
            if (websocket && isConnected) {
                websocket.send(JSON.stringify({
                    data: {message: 'Spam Spam Spam ' + count},
                }))
            }
        }, 100);
    }
    
    const history = useHistory();

    useEffect(() => {
        let ws;
        let shouldReconnect = true;
        async function initWebsocket() {
            console.log('INIT WEBSOCKET');
            ws = new WebSocket("ws://localhost:4000/ws/" + encodeURIComponent(roomId) + '?username=' + encodeURIComponent(name));
            setWebsocket(ws);
            setIsConnecting(true);
            setIsConnected(false);

            ws.addEventListener("message", (event) => {
                console.log(event.data);
                setMessages(messages => {
                    return takeRight([...messages, event.data], 500);
                })
            })

            ws.addEventListener("close", (e) => {
                console.log('Socket closed.', e);
                setWebsocket(null);
                ws = null;
                setIsConnecting(false);
                setIsConnected(false);
                if (shouldReconnect) {
                    setTimeout(() => {
                        console.log('Attempting reconnect...');
                        initWebsocket()
                    }, 500)
                }
            })

            ws.addEventListener("open", () => {
                console.log('Socket opened.');
                setIsConnecting(false);
                setIsConnected(true);
            })
        }

        initWebsocket();

        return () => {
            shouldReconnect = false;
            if (ws) {
                ws.close()
            }
            setWebsocket(null);
            ws = null;
        }
    }, []);

    useEffect(() => {
        if (messageContainerRef.current) {
            messageContainerRef.current.scrollTop = messageContainerRef.current.scrollHeight - messageContainerRef.current.clientHeight;
            //messageContainerRef.current.scrollIntoView(false);
        }
    }, [messages])

    return (
        <div className="chat-main">
            <div className="chat-header">
                <div className="chat-back" onClick={() => history.push('/')}>Back</div>
                <div className="chat-title">{roomId}</div>
                <div className="connection-status">
                    {isConnecting && (
                        <div>Connecting...</div>
                    )}
                    {!isConnecting && isConnected &&(
                        <div>Connected</div>
                    )}
                    {!isConnecting && !isConnected && (
                        <div>Disconnected</div>
                    )}
                </div>
            </div>
            <div className="chat-message-container" ref={messageContainerRef}>
                {messages.map((message, i) => (
                    <div className="chat-message" key={i}>{message}</div>
                ))}
            </div>
            <div className="chat-tools">
                <div className="chat-name" onClick={() => setName('')}>
                    Name: {name}
                </div>
                <form action="#" onSubmit={sendMessage}>
                    <input type="text" value={messageInput} onChange={(e) => setMessageInput(e.target.value)}/>
                    <input type="submit" value="Send"/>
                </form>
                <button onClick={sendBadPacket}>Send Invalid Packet</button>
                <button onClick={crashRoom}>Crash Room</button>
                <button onClick={spamRoom}>Spam Room</button>
            </div>
        </div>
    )
}