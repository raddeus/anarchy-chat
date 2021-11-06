import { useEffect, useState } from "react";
import {
    useHistory
  } from "react-router-dom";
export default () => {
    const [newRoomId, setNewRoomId] = useState('');

    const [isFetchingRooms, setIsFetchingRooms] = useState(false);
    const [rooms, setRooms] = useState([]);
    const history = useHistory();
    useEffect(() => {
        async function fetchRooms() {
            setIsFetchingRooms(true);
            try {
                const response = await fetch('http://localhost:4000/api/rooms');
                const data = await response.json();
                setRooms(data.rooms);
            } catch (e) {
                console.error(e);
                setRooms([]);
            }
            setIsFetchingRooms(false)
        }

        fetchRooms();
    }, []);

    return (
        <div>
            <h1>Elixir Chat</h1>
            <div className="create-room-container">
                Create a new room: 
                <form action="#" onSubmit={e => {e.preventDefault(); history.push('/rooms/' + encodeURIComponent(newRoomId))}}>
                    <input type="text" value={newRoomId} onChange={(e) => setNewRoomId(e.target.value)}/>
                    <button type="submit">Create</button>
                </form>
            </div>
            <h3>Or Join One of the Existing Rooms...</h3>
            {isFetchingRooms && (
                <div>Fetching Rooms...</div>
            )}
            {!isFetchingRooms && rooms && rooms.length > 0 && (
                <div className="rooms-container">
                    {rooms.map(room => (
                        <div className="room" key={room.name} onClick={() => history.push('/rooms/' + encodeURIComponent(room.id))}>
                            <div className="room-id">{room.id}</div>
                            <div className="room-user-count">{room.user_count}</div>
                            <div className="room-pid">{room.pid}</div>
                        </div>
                    ))}
                </div>
            )}
        </div>
    )
}