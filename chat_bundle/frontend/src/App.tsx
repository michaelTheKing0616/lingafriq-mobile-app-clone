import React from 'react'
import PrivateChatPage from './pages/PrivateChatPage'
import WorldWallPage from './pages/WorldWallPage'
import ConnectHubPage from './pages/ConnectHubPage'
export default function App(){return (<div style={{fontFamily:'Inter, Roboto, system-ui', padding:20}}><h1>Polie — Demo</h1><div style={{display:'grid', gridTemplateColumns:'1fr 1fr', gap:20}}><div style={{border:'1px solid #eee', padding:12}}><PrivateChatPage /></div><div style={{border:'1px solid #eee', padding:12}}><WorldWallPage /><div style={{height:20}} /> <ConnectHubPage /></div></div></div>)}
