import React, { useState, useEffect, useRef } from 'react';
/*
WordMatchAudio.jsx
Props:
- cards: [{card_id, text, gloss, audio_native_url, ascii}]
- api: {telemetryUrl, srsUrl}
- userId, language, level
*/
export default function WordMatchAudio({ cards=[], api={}, userId, language, level, onFinish }){
  const [left, setLeft] = useState([]);
  const [right, setRight] = useState([]);
  const [selected, setSelected] = useState({left:null,right:null});
  const [results, setResults] = useState([]);
  const audioRef = useRef(null);
  useEffect(()=>{
    const l = cards.map(c=>({id:c.card_id,label:c.text,audio:c.audio_native_url}));
    const r = cards.map(c=>({id:c.card_id,label:c.gloss}));
    shuffle(l); shuffle(r); setLeft(l); setRight(r);
    function shuffle(a){ for(let i=a.length-1;i>0;i--){ const j=Math.floor(Math.random()*(i+1)); [a[i],a[j]]=[a[j],a[i]] } }
  },[cards]);
  function playAudio(url){ if(!url) return; if(audioRef.current){ audioRef.current.src=url; audioRef.current.play().catch(()=>{}); } }
  function selectTile(side,id){
    const next = {...selected, [side]: id};
    setSelected(next);
    if(next.left && next.right){
      evaluate(next.left, next.right);
      setSelected({left:null,right:null});
    }
  }
  function evaluate(lid, rid){
    const correct = lid === rid;
    const ts = Date.now();
    setResults(r=>[...r,{left:lid,right:rid,correct,ts}]);
    // telemetry
    if(api.telemetryUrl){
      fetch(api.telemetryUrl, {method:'POST',headers:{'Content-Type':'application/json'}, body: JSON.stringify({event:'wordmatch_turn', userId, language, lid, rid, correct, ts})}).catch(()=>{});
    }
    // srs update
    const quality = correct ? 5 : 2;
    if(api.srsUrl){
      fetch(api.srsUrl, {method:'POST', headers:{'Content-Type':'application/json'}, body: JSON.stringify({userId, cardId: lid, quality})}).catch(()=>{});
    }
  }
  function finish(){
    const session = {userId, language, level, results, duration_ms: results.length? (results[results.length-1].ts - results[0].ts):0};
    if(api.telemetryUrl) fetch(api.telemetryUrl, {method:'POST', headers:{'Content-Type':'application/json'}, body: JSON.stringify({event:'wordmatch_complete', session})}).catch(()=>{});
    if(onFinish) onFinish(session);
  }
  return (
    <div className="p-4 grid grid-cols-2 gap-4">
      <audio ref={audioRef} />
      <div>
        <h3 className="text-lg font-semibold">Tap a word (audio)</h3>
        <div className="grid gap-2 mt-2">
          {left.map(tile => (
            <button key={tile.id} className="p-2 border rounded text-left" onClick={()=>{playAudio(tile.audio); selectTile('left', tile.id);}}>
              <div className="font-medium">{tile.label}</div>
            </button>
          ))}
        </div>
      </div>
      <div>
        <h3 className="text-lg font-semibold">Tap the meaning</h3>
        <div className="grid gap-2 mt-2">
          {right.map(tile => (
            <button key={tile.id} className="p-2 border rounded text-left" onClick={()=> selectTile('right', tile.id)}>
              <div className="font-medium">{tile.label}</div>
            </button>
          ))}
        </div>
      </div>
      <div className="col-span-2 mt-4 flex justify-end space-x-2">
        <button onClick={finish} className="px-4 py-2 bg-blue-600 text-white rounded">Finish</button>
      </div>
    </div>
  );
}
