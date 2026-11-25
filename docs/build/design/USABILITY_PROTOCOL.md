# Usability-test protocol

Status: Approved. Review recorded below. `docs/plan/CARD_STATUS.tsv` marks P3-033 Done. The study has not been run. The targets below are not results.

## Protocol review

Checked on 21 November 2026.

- Nine tasks each have a start screen, the words the facilitator says, and a yes or no pass rule. Task 1 uses reduced motion. Task 2 uses 200 percent text. A pass does not use a score inside the app.
- The task target is at least 90 percent of people who attempt a task. The questionnaire is the ten-item System Usability Scale, scored in the standard way, with a target of at least 85. Neither number is a filled-in result.
- The sample is at least 5 adults on low-end Android in Nigeria, at least 5 in Kenya, and at least 5 in South Africa, with at least 2 hearing-impaired adults inside those counts. Their pass uses the Tone Lens and written lines, not sound alone.
- Consent covers the screen recording, the voices, the right to stop, and deletion after the notes. This round does not include anyone under 18, even with a guardian present. The under-13 gate is read by an adult.

Approval stands. No session has been run.

This is a plan for a future study. The study has not been run. This file has no participant, no session, and no filled-in score. Do not read a target below as a result.

The protocol does not change the app. Paths follow the wireflows. The words a participant hears stay as plain as the copy deck.

Sources: `docs/source/ELEVATION.md` §13.7 (lines 1935-1941), `docs/build/design/WIREFLOWS_TODAY_LEARN_SPEAK.md`, `docs/build/design/WIREFLOWS_PLAY_VILLAGE_ME.md`, and `docs/build/design/COPY_DECK.md`.

## What a session is

One adult participant. One facilitator. One low-end Android phone. The session is in person, in Nigeria, Kenya, or South Africa.

The facilitator reads each task once, in the words under "Say this". They may repeat those same words once if the participant asks. They do not point at a control. They do not tap the phone. If the participant says they are stuck, the facilitator marks no and goes to the next task.

Before each task, the facilitator puts the phone on that task's start screen. The participant does not do the setup.

A task the participant never hears is not attempted. It is not a yes and it is not a no. A task they start, then leave unfinished, is a no.

The facilitator marks each task yes or no. There is no third mark and no points.

## Conditions

Every session uses both of these. They are setup for the future study, not a measured result.

- Task 1 is done with reduced motion on. Turn on the phone setting that removes animations before the task. The Tone Lens contour is already on the screen. It does not draw on. After the task, turn reduced motion off unless the participant asks to keep it.
- Task 2 is done at 200 percent text. Set the phone text size to twice the default before the task. After the task, set the text size back to the default unless the participant asks to keep it.

A pass does not use a score, a percent inside the app, or a confidence number.

## Tasks

### Task 1. First spoken word

Condition: reduced motion is on.

Start screen: You speak now. This is the first spoken word. No account is required. The line "No account yet." may be on the screen. The greeting `Ẹ kú àárọ̀` is on the screen, with the Tone Lens contour above it.

Say this: "Read the greeting on this screen. Then tap I said it."

What the participant tries: They read the greeting. They may tap Hear it. They tap I said it.

Hearing-impaired path: They do not need Hear it. They use the visual Tone Lens contour, and the written captions "Good morning." and "Mid, then high, then rising, then low." Sound alone is not the path.

Pass: Yes if the contour is already visible and does not draw on, the greeting is on the screen, and the participant taps I said it themselves. No if the contour only appears by drawing on, they do not tap I said it, or the facilitator taps it. The line "Speak within 60 seconds." is a product target, not a timer, and it is not part of this pass. The sample line "It was mid. The high tone sits up." is not part of this pass.

### Task 2. Today's plan

Condition: text size is 200 percent.

Start screen: Today root. This is the daily plan. The title is Today. The plan shows due reviews, the next lesson, and one speaking moment. Start is the button.

Say this: "This is today's plan. Tap Start."

What the participant tries: They read the plan and tap Start. Start opens the lesson for this plan.

Pass: Yes if Start opens that lesson, and the plan lines and the Start label are fully visible at 200 percent text. No word they need is cut off. No if they cannot find Start, the lesson does not open, or a line they need is clipped. The minute label on the plan is not a score. Do not mark the task from that number.

### Task 3. Locked lesson with a preview

Start screen: Learn root.

Say this: "Open Path and lessons. Find the locked lesson. Tap See a preview."

What the participant tries: They tap Path and lessons. They find the locked lesson. On the path frame that lesson is Family names, and the line is "Morning greetings comes first." They tap See a preview. They do not need to tap Open the locked lesson, and they do not finish the lesson.

Pass: Yes if they tap See a preview on that locked lesson, and the screen shows that lesson's name and the line "Morning greetings comes first." No if they open a different lesson, or they never tap See a preview. Open the locked lesson is a different control. Using it is not this pass.

### Task 4. Lens Point and Say

Start screen: Today root. The camera button is in the top bar. Before the task, the facilitator places one object where the camera can see it.

Say this: "Tap the camera at the top. Point and Say should be on. Point at the one thing, and read the word."

What the participant tries: They tap the camera. Lens opens on Point & Say. They point at the one object. They read the target-language word and the written meaning. Close would return to Today. They do not have to tap Close.

Hearing-impaired path: They use the visual Tone Lens contour and the written meaning as the caption. They point to the word, the contour, and the meaning. They do not need the sound of Say it.

Pass: Yes if they open Lens from the camera, Point & Say shows the word On, and they point to the word and its written meaning. If the screen says the camera sees no object, Yes still holds if they tap Point again and stay on Lens. No if they cannot find the camera, or they leave Point & Say and do not come back. Do not mark this from which object name came back.

### Task 5. Long-press Word Card

Start screen: Today root, with the greeting word `Ẹ kú àárọ̀` visible on the next lesson row. Word Card is a long press. It is not a tab.

Say this: "Press and hold the greeting word. Read the card. Then tap Close."

What the participant tries: They long-press the target-language word. The Word Card opens. They read it. They tap Close, which returns to Today.

Hearing-impaired path: They read the visual Tone Lens and the written captions on the card: "Good morning." and "Mid, then high, then rising, then low." They do not need Play the audio.

Pass: Yes if the long press opens the Word Card, the card shows the word, the meaning, and the Tone Lens, and Close returns to Today. No if they only tap the word, the card does not open, or Close does not return. Do not mark this from a spoken attempt.

### Task 6. Polie hold to talk

Start screen: Speak root.

Say this: "Open Polie. Hold the button that says Hold to talk. Then stop."

What the participant tries: They tap Polie. They press and hold Hold to talk. They stop by letting go, or by tapping Stop.

Hearing-impaired path: The written line under the greeting is the caption. The greeting is `Ẹ kú àárọ̀`, and the caption is "Good morning." The visual Tone Lens on that word is the pitch cue. They are not marked on whether a voice was heard.

Pass: Yes if Polie opens, they hold Hold to talk, and the screen then shows one of these: the word Listening, the line "You are talking.", the button Stop, the written greeting and its caption, or the honest notice "No reply came back." with "Polie did not speak for you." No if they cannot open Polie or cannot find Hold to talk. Do not mark how they spoke.

### Task 7. One Arcade shelf

Start screen: Play root. This is the Arcade.

Say this: "Open Tone and Sound. Then open Tone Trainer. Then go back."

What the participant tries: They open the Tone and Sound shelf, then Tone Trainer. Tone Trainer is the game with Play on that shelf. They tap Back to Play.

The Arcade page may already show the shelf heading. Tapping Tone Trainer under Tone and Sound is the same path. If the shelf is its own screen, they tap Tone and Sound first, then Tone Trainer.

Pass: Yes if Tone Trainer opens from the Tone and Sound shelf and Back to Play returns to the Arcade. No if they only open a game on a different shelf. They do not play a round. A right or wrong word is not the pass. A hearing-impaired participant uses this same pass. The task does not depend on hearing the tone.

### Task 8. Village place list

Start screen: Village root. This is the place list. The title is Village. The list is the Village map. It is not a drawn map.

Say this: "This is the place list. Open School. Then go back."

What the participant tries: They find School on the place list, tap it, then tap Back to Village.

Pass: Yes if School opens from that list and Back to Village shows the place list again, with place names on it. No if the list does not open, or they cannot return to it. Clips and Create may show the word Locked. That word is not a score. A2 and B1 are level names. This pass does not use them.

### Task 9. Under-13 gate, read by an adult

This task is a reading task. It is how this round tests the product's under-13 gate. A child is not in the session. The adult does not use a child account, and does not type a child's birth year.

Start screen: The adult can see the Village place list. The facilitator also shows the written Village lines for a person under 13, from `docs/build/design/WIREFLOWS_PLAY_VILLAGE_ME.md`. Those lines say that under 13 goes to the guardian flow before the Village map, and that a minor does not get a control that opens Chats, Square, Radio, Clips, or Create. The line is "A guardian must open this."

Say this: "Read the lines for a person under 13. Which places must a guardian open?"

What the participant tries: They read those lines. They say the places.

Pass: Yes if the adult names all five places, Chats, Square, Radio, Clips, and Create, and says a guardian must open them, and says a person under 13 does not get a control that opens those places. No if they miss one of the five, or they say a child can open one of them. No if anyone under 18 is in the room.

## Task-success target

For each task above, the target is that at least 90 percent of the participants who attempt that task get a yes.

This target is for the future study. It is not a result. No one has been counted yet.

The 90 percent counts people who pass. It is not a percent the app shows. A yes does not depend on a score, a percent inside the app, or a confidence number.

A hearing-impaired participant who passes by the visual Tone Lens and the captions counts as a yes on that task. They are not a separate score.

## Questionnaire

After the tasks, the facilitator reads the System Usability Scale. It has ten items, in the standard order, written here in plain words. The study does not add an item and does not drop one.

The participant picks one answer for each item. The answers are Strongly disagree, Disagree, Neither, Agree, and Strongly agree. The facilitator does not suggest an answer.

1. I think I would like to use this system often.
2. I found the system more complex than it needs to be.
3. I thought the system was easy to use.
4. I think I would need a technical person to help me use this system.
5. I found the parts of this system fit together.
6. I thought there was too much in this system that did not stay the same.
7. I imagine most people would learn to use this system very quickly.
8. I found the system awkward to use.
9. I felt very confident using the system.
10. I needed to learn a lot before I could get going with this system.

The future study scores a complete set of ten answers in the standard way. Items 1, 3, 5, 7, and 9 are the positive items. Items 2, 4, 6, 8, and 10 are the negative items. Strongly disagree is step 1. Strongly agree is step 5. A positive item contributes its step minus 1. A negative item contributes 5 minus its step. Add the ten contributions and multiply by 2.5. The result runs from 0 to 100.

The target is at least 85. This target is for the future study. It is not a result. This file does not contain a filled-in score. If the participant will not answer an item, write "not answered" and do not compute a total for that person.

## Sample

Every participant uses a low-end Android phone. The facilitator writes the phone model in the session notes. This protocol does not name a model.

The sample has three countries. The floors are:

| Group | Floor |
| --- | --- |
| Nigeria | at least 5 participants |
| Kenya | at least 5 participants |
| South Africa | at least 5 participants |
| Hearing-impaired users | at least 2 in the whole sample |
| Age | 18 or older |

The country floors add up to at least 15 participants. The hearing-impaired users sit inside those country counts. They are not a fourth country, and they are not extra people on top of the 15. A larger sample is allowed. A smaller one is not.

Each hearing-impaired participant is an adult in Nigeria, Kenya, or South Africa. The facilitator does not run a hearing test. The participant says they need words on the screen rather than sound alone. For that person, the phone volume stays down, and tasks 1, 4, 5, and 6 use the visual Tone Lens and the written captions. Task 7 does not ask them to hear a tone. Tasks 2, 3, 8, and 9 are already visual.

## How hearing-impaired tasks avoid sound alone

Sound is not the only cue, and it is not the pass.

- Task 1. The contour above `Ẹ kú àárọ̀` is the Tone Lens. "Good morning." and "Mid, then high, then rising, then low." are the captions. Hear it is optional.
- Task 4. Point & Say shows a contour, a target-language word, and a written meaning. The contour is the Tone Lens. The written meaning is the caption. Say it is not required.
- Task 5. The Word Card shows the Tone Lens, the word, and the same written captions. Play the audio is not required.
- Task 6. When Polie has a line, the caption is the written "Good morning." under `Ẹ kú àárọ̀`, and the Tone Lens is the pitch cue. A pass can also be the visible listening state, or the written notice that no reply came back. Hearing the voice is not required.

Captions here are those written lines on the screen. The protocol does not add a new caption track.

## Consent

The facilitator reads this before any task. The session starts only if the adult says yes. If they say no, the session does not start, and nothing is kept.

Say this: "I will record the phone screen and the voices in this room. I will write notes. You can stop at any time. You can skip a task. You do not need to give a reason. If you stop, I stop the recording. After I write the notes, I delete the recordings. I will not put your name in the notes. This session is for adults. If you are under 18, we stop, even if a guardian is here."

What is recorded:

- The phone screen.
- The voices in the room during the tasks and the questionnaire.
- The notes listed below.

The person can stop:

- They can stop the whole session, or skip a task, at any time.
- They do not need a reason.
- The facilitator stops the recording when the person says stop.
- Stopping does not take away the deletion rule below.

Recordings are deleted after the notes are written. The screen recording and the voice recording are both deleted. The facilitator does not keep a copy. If the notes are not written yet, the recordings stay only until the notes exist, then they are deleted.

The notes may keep:

- A session code made of the country and a number. No name.
- That the person said they are 18 or older.
- Whether they used the hearing-impaired path.
- The phone model.
- Yes or no for each task they attempted, and "not attempted" for the rest.
- The ten questionnaire answers, or "not answered".

The notes do not keep a birth year. The facilitator only asks "Are you 18 or older?" If the answer is no, or the person is not sure, the session stops.

## No one under 18

This round does not include anyone under 18, even with a guardian present. A guardian's yes does not allow a minor to stay. If the facilitator learns that the person is under 18, the session stops, the recordings are deleted, and no task mark is kept.

The product's under-13 gate is task 9. An adult reads the flow. A child is not in the session, and a child does not use the phone.
