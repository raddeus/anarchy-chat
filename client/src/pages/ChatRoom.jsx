//import "./ChatRoom.css"
import { useEffect, useState, useRef, useContext } from "react";
import { UsernameContext } from "../contexts/UsernameContext";
import {
    useHistory, useParams
} from "react-router-dom";
import { takeRight } from "lodash";
import { useIntervalWhen } from "rooks";
import config
 from "../config";
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
                const response = await fetch(config.api_base + '/api/messages?room_id=' + encodeURIComponent(roomId));
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
    const validateAndSetMessageInput = (e) => {
        setMessageInput(e.target.value.substring(0, 200))
    };

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

    const [isSpamming, setIsSpamming] = useState(false);
    const [spamCount, setSpamCount] = useState(0);
    useIntervalWhen(
        () => {
            setSpamCount(spamCount + 1);
            if (websocket && isConnected) {
                websocket.send(JSON.stringify({
                    data: {message: 'Spam Spam Spam ' + spamCount},
                }))
            }
        },
        50,
        isSpamming,
        true,
    );
    const toggleSpam = (e) => {
        e.preventDefault();
        setIsSpamming(!isSpamming);
    }

    const history = useHistory();

    useEffect(() => {
        let ws;
        let shouldReconnect = true;
        async function initWebsocket() {
            console.log('INIT WEBSOCKET');
            ws = new WebSocket(config.ws_base + "/ws/" + encodeURIComponent(roomId) + '?username=' + encodeURIComponent(name));
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
        }
    }, [messages])

    return (
        <div className="h-screen flex flex-col">
            <div className="flex flex-row justify-between items-center border-gray-600 border-b-2 px-4 py-2 shadow-2xl">
                <div 
                    onClick={() => history.push('/')} 
                    className="btn"
                >
                    Back
                </div>
                <div className="chat-title text-3xl">{roomId}</div>
                <div>
                    {isConnecting && (
                        <div className="text-yellow-300">Connecting...</div>
                    )}
                    {!isConnecting && isConnected &&(
                        <div className="text-green-300">Connected</div>
                    )}
                    {!isConnecting && !isConnected && (
                        <div className="text-red-300">Disconnected</div>
                    )}
                </div>
            </div>
            <div className="flex flex-grow flex-col overflow-y-scroll px-3" ref={messageContainerRef}>
                {messages.map((message, i) => (
                    <div className="text-xl m-2 break-all" key={i}>{message}</div>
                ))}
            </div>
            <form action="#" onSubmit={sendMessage} className="flex flex-row border-gray-600 border-t-2 py-2 px-4">
                <input className="text-2xl min-w-0 flex-grow text-input" type="text" autoFocus value={messageInput} onChange={validateAndSetMessageInput}/>
                <input className="btn-green ml-2" type="submit" value="Send"/>
            </form>
            <div className="flex flex-row justify-between items-center py-2 px-4">
                <div className="text-2xl cursor-pointer" onClick={() => setName('')}>
                    Name: {name}
                </div>
                <div>
                    <button className="btn-red mr-1" onClick={sendBadPacket}>Crash Connection</button>
                    <button className="btn-red mr-1" onClick={crashRoom}>Crash Room</button>
                    <button className="btn-red" onClick={toggleSpam}>{isSpamming ? 'Stop Spam' : 'Spam'}</button>
                </div>
            </div>
        </div>
    )
}