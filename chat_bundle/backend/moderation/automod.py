import re
from typing import Dict

# very small profanity list (extend per language)
PROFANITY = set([
    "damn", "shit", "fuck"
])

URL_RE = re.compile(r"https?://\S+")

def score_text(text: str) -> Dict:
    t = (text or "").lower()
    score = 0.0
    reasons = []
    
    # profanity hits
    prof_hits = [w for w in PROFANITY if w in t]
    if prof_hits:
        score += 0.6
        reasons.append({"type":"profanity", "matches": prof_hits})
    
    # URLs (spam / links)
    if URL_RE.search(t):
        score += 0.3
        reasons.append({"type":"url", "matches": True})
    
    # excessive punctuation / caps
    if sum(1 for c in t if c in "!?") > 5:
        score += 0.1
        reasons.append({"type":"excess_punct"})
    
    # clamp
    score = min(1.0, score)
    
    # decide action
    if score >= 0.7:
        action = "block"
    elif score >= 0.4:
        action = "hold_for_review"
    else:
        action = "allow"
    
    return {"score": score, "action": action, "reasons": reasons}

