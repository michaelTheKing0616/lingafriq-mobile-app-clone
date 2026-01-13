import React, { useState, useEffect } from 'react';
export default function PhraseSniper({prompts=[], speed=2000, onHit}){
  const [queue, setQueue] = useState(prompts);
  useEffect(()=>{
    const id = setInterval(()=>{ setQueue(q => q.length>0 ? q.slice(1) : q); }, speed);
    return ()=>clearInterval(id);
  },[speed]);
  return (
    <div>
      {queue.slice(0,5).map((p,i)=>(
        <div key={i} style={{display:'flex',justifyContent:'space-between',padding:8,borderBottom:'1px solid #eee'}}>
          <div>{p.text}</div>
          <div><button onClick={()=>onHit && onHit(p)}>Hit</button></div>
        </div>
      ))}
    </div>
  );
}
