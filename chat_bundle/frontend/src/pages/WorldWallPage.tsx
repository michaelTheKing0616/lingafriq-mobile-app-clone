import React, {useState, useEffect} from 'react'
import axios from 'axios'
export default function WorldWallPage(){const [feed, setFeed] = useState<any[]>([])
const [lang, setLang] = useState('yoruba')
useEffect(()=>{axios.get('http://localhost:8000/world/feed?lang=' + lang).then(r=>setFeed(r.data.items))},[lang])
return (<div><h2>World Wall (Demo)</h2><div style={{marginBottom:8}}><label>Filter language: </label><select value={lang} onChange={e=>setLang(e.target.value)}><option value="yoruba">Yoruba</option><option value="swahili">Swahili</option></select></div><div style={{border:'1px solid #eee', padding:8}}>{feed.map(f => (<div key={f.id} style={{padding:8,borderBottom:'1px solid #f2f2f2'}}><div style={{fontSize:12,color:'#444'}}>{f.author} • {f.country || '—'}</div><div style={{fontSize:16}}>{f.body}</div></div>))}</div></div>)}
