import 'package:doomread_core/src/voice.dart';

/// The Watched app English lines name when no real one has opened yet:
/// the Tone picker and the demo Urge.
const String enSampleApp = 'Instagram';

/// English Tone lines. Roast the Urge, never the person; no insults, no
/// swearing, no guilt about the Planned break. After a Slip only Chill's
/// line is ever said (see voice).
const CopyPack en = {
  Tone.chill: {
    Moment.urge: [
      'Not yet. {app} can wait for your break.',
      'Not yet. It can wait for your break.',
    ],
    Moment.urgeTask: [
      'Not yet. {task} first, {app} at the break.',
      'Not yet. {task} first, the rest at the break.',
      'Not yet. It can wait for your break.',
    ],
    Moment.afterSlip: ['Fumbled. It happens.'],
    Moment.breakHere: ['{minutes} min of Reels, messages, anything.'],
    Moment.breakOver: ["Break's over."],
    Moment.evening: ['A good sitting. Well done.'],
    Moment.newBest: ['Aim reached. This is your longest stretch yet.'],
    Moment.receipt: ['Calm and steady. Same time tomorrow?'],
    Moment.receiptAfterSlip: ['You came back. Same time tomorrow?'],
    Moment.taskDone: ['Done. {minutes} calm minutes, nicely done.'],
    Moment.taskDoneAfterSlip: ['Done. You came back to it, and finished.'],
  },
  Tone.spicy: {
    Moment.urge: [
      'Not yet. {app} will survive without you till the break.',
      'Not yet. The feed will survive without you till the break.',
    ],
    Moment.urgeTask: [
      "Not yet. {task} won't do itself. {app} can wait for the break.",
      "Not yet. {task} won't do itself. The feed can wait for the break.",
      'Not yet. The feed can wait for the break.',
    ],
    Moment.breakHere: ['{minutes} min of legal brainrot. Enjoy.'],
    Moment.breakOver: ['Brainrot over. Lock back in.'],
    Moment.evening: ['Lowkey a great evening. Aura up.'],
    Moment.newBest: ['Longest stretch ever. The aura is real.'],
    Moment.receipt: ['Locked in. Here are the receipts.'],
    Moment.receiptAfterSlip: ['Wandered off, came back anyway. That counts.'],
    Moment.taskDone: ['Locked in. {minutes} minutes, phone stayed face down.'],
    Moment.taskDoneAfterSlip: [
      'Wandered off, came back, got it done. That counts.',
    ],
  },
  Tone.mom: {
    Moment.urge: [
      'Phone. AGAIN?! {app} will still be there after your break!',
      'Phone. AGAIN?! It will still be there after your break!',
    ],
    Moment.urgeTask: [
      'Phone. AGAIN?! First {task}, then {app}!',
      'Phone. AGAIN?! First {task}, then your break!',
      'Phone. AGAIN?! Work first, then your break!',
    ],
    Moment.breakHere: [
      'Bravo! Now get up and have some tea. {minutes} minutes.',
    ],
    Moment.breakOver: ['Enough now! Back to it, go on.'],
    Moment.evening: ['Bravo! Now tell me, what happened?'],
    Moment.newBest: ['Look at you! Never this long in one go!'],
    Moment.receipt: ['Well done! Now get up and make yourself some tea.'],
    Moment.receiptAfterSlip: [
      "You came back, and that's what matters. Now go have some tea.",
    ],
    Moment.taskDone: [
      "Bravo! {minutes} minutes and it's done. Now have some tea.",
    ],
    Moment.taskDoneAfterSlip: [
      "It's done, and that's what matters. Now go have some tea.",
    ],
  },
};
