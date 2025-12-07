// drum_shadow.js - rhythm shadowing mini-game logic (client-side)
export function scorePattern(pattern, userTaps){
  // pattern: array of ms offsets relative to start
  // userTaps: array of ms timestamps
  const window = 150; let total = pattern.length, hits=0, sumError=0;
  const used = new Set();
  for(let i=0;i<pattern.length;i++){
    const expected = pattern[i];
    let bestIdx = -1; let bestErr = Infinity;
    for(let j=0;j<userTaps.length;j++){
      if(used.has(j)) continue;
      const err = Math.abs(userTaps[j] - expected);
      if(err < bestErr){ bestErr = err; bestIdx = j; }
    }
    if(bestIdx !== -1 && bestErr <= window){ hits++; sumError += bestErr; used.add(bestIdx); }
  }
  const accuracy = hits / total;
  const avgError = hits ? (sumError / hits) : null;
  return {accuracy, avgError, hits, total};
}
