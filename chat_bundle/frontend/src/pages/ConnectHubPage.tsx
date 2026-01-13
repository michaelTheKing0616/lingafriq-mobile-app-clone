import React, {useState} from 'react'
import axios from 'axios'
export default function ConnectHubPage(){const [matches, setMatches] = useState<any[]>([])
const [lang, setLang] = useState('yoruba')
const find = ()=>{axios.post('http://localhost:8000/connect/match', {lang}).then(r=>setMatches(r.data.matches))}
return (<div><h3>Connect Hub</h3><div style={{display:'flex', gap:8, alignItems:'center'}}><label>Language:</label><select value={lang} onChange={e=>setLang(e.target.value)}><option value="yoruba">Yoruba</option><option value="swahili">Swahili</option></select><button onClick={find}>Find Matches</button></div><div style={{marginTop:8}}>{matches.map(m=> (<div key={m.id} style={{padding:8,border:'1px solid #eee', marginBottom:6, borderRadius:6}}><div style={{fontWeight:600}}>{m.username}</div><div>Native: {m.native.join(', ')}</div></div>))}</div></div>)}
