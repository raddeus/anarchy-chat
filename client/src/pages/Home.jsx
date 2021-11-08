import { useEffect, useState } from "react";
import {
    useHistory
  } from "react-router-dom";

export default () => {
    const [newRoomId, _setNewRoomId] = useState('');
    const setNewRoomId = (val) => {
        _setNewRoomId(val.substring(0, 20))
    }
    const createRoom = e => {
        e.preventDefault();
        if (!newRoomId) return
        history.push('/rooms/' + encodeURIComponent(newRoomId))
    };

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
        const interval = setInterval(() => {
            fetchRooms();
        }, 2000)
        return () => {
            clearTimeout(interval);
        }
    }, []);

    return (
        <div className="flex flex-col items-center p-10">
            <h1 className="my-4 text-red-300 text-5xl">Anarchy Chat</h1>

            <h3 className="my-4 text-2xl">Create a new room:</h3> 
            <div className="flex flex-row justify-center">
                <form action="#" onSubmit={createRoom}>
                    <input 
                    type="text" 
                    value={newRoomId}
                    autoFocus
                    onChange={(e) => setNewRoomId(e.target.value)}
                    className="text-input p-2"
                    />
                    <button className="btn ml-2" type="submit">Create</button>
                </form>
            </div>
            <h3 className="my-4 text-2xl">Or Join One of the Existing Rooms...</h3>
            {rooms.length === 0 && isFetchingRooms && (
                <div>Fetching Rooms...</div>
            )}
            {rooms && rooms.length > 0 && (
                <div className="flex flex-row flex-wrap justify-center">
                    {rooms.map(room => (
                        <div className="border-2 border-solid border-gray-500 p-3 m-2 rounded-md cursor-pointer hover:shadow-2xl hover:bg-gray-800" key={room.id} onClick={() => history.push('/rooms/' + encodeURIComponent(room.id))}>
                            <div className="room-id text-3xl mb-2">{room.id}</div>
                            <div className="room-user-count">Users Connected: {room.user_count || 0}</div>
                            <div className="room-message-count">Total Messages: {room.message_count || 0}</div>
                            {room.pid ? (
                                <>
                                <div className="text-green-300">Awake</div>
                                <div className="text-green-300">{room.pid}</div>
                                </>
                            ) : (
                                <div className="text-red-300">Asleep</div>
                            )}
                            
                        </div>
                    ))}
                </div>
            )}
        </div>
    )
}