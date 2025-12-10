import React, {useState, useEffect} from 'react'
import Composer from '../components/Composer'
import axios from 'axios'
export default function PrivateChatPage(){const [messages, setMessages] = useState([])
const chatId = 'chat_u1_u2'
useEffect(()=>{axios.get('http://localhost:8000/chats/' + chatId + '/messages').then(r=>setMessages(r.data))},[])
return (<div><h2>Private Chat (Demo)</h2><div style={{height:260, overflow:'auto', border:'1px solid #ddd', padding:8}}>{messages.map((m:any)=>(<div key={m.id} style={{padding:6, margin:6, background:'#f7f7fb', borderRadius:8}}><div style={{fontSize:12, color:'#666'}}>{m.sender}</div><div style={{fontSize:16}}>{m.body}</div></div>))}</div><Composer chatId={chatId} currentUser="u1" /></div>)}
