import { useEffect, useState, useContext } from "react";
import {
    useHistory
  } from "react-router-dom";
import { UsernameContext } from "../contexts/UsernameContext";
export default () => {
    const {name, setName, prevName} = useContext(UsernameContext)
    const [updatedName, setUpdatedName] = useState(name);

    const submitName = (e) => {
        setName(updatedName)
    };

    return (
        <div>
            <h1>What is your name?</h1>
            <form action="#" onSubmit={submitName}>
                <input type="text" defaultValue={prevName} onChange={(e) => setUpdatedName(e.target.value)}/>
                <input type="submit" value="Save" />
            </form>
        </div>
    )

}