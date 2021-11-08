import { useEffect, useState, useContext } from "react";
import {
    useHistory
  } from "react-router-dom";
import { UsernameContext } from "../contexts/UsernameContext";
export default () => {
    const {name, setName, prevName} = useContext(UsernameContext)
    const [updatedName, setUpdatedName] = useState(name);

    const submitName = (e) => {
        e.preventDefault();
        const nameToValidate = updatedName.trim() ? updatedName.trim() : prevName.trim();
        if (nameToValidate.length < 3) {
            alert('Name must be at least 3 characters');
            return;
        }
        if (nameToValidate.length > 20) {
            alert('Name must be at most 20 characters');
            return;
        }
        setName(nameToValidate)
    };

    return (
        <div className="h-screen flex flex-col items-center justify-center">
            <h1 className="text-5xl my-4 mb-6">What is your name?</h1>
            <form action="#" onSubmit={submitName}>
                <input className="text-input p-2" autoFocus type="text" defaultValue={prevName} onChange={(e) => setUpdatedName(e.target.value)}/>
                <input className="btn-green ml-2" type="submit" value="Save" />
            </form>
        </div>
    )

}