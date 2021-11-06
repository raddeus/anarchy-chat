import React, { createContext, useEffect, useState } from "react"
import useLocalStorage from "../hooks/useLocalStorage";

export const UsernameContext = createContext()

export const UsernameProvider = ({ children }) => {
  const [name, setName] = useLocalStorage("name", "");
  const [prevName, setPrevName] = useState(name);
  useEffect(() => {
    if (name) {
        setPrevName(name);
    }
  }, [name])
  return (
    <UsernameContext.Provider value={{name,setName,prevName}}>
      {children}
    </UsernameContext.Provider>
  );
};