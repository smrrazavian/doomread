import 'package:doomread_core/src/voice.dart';

/// The Watched app Persian lines name when no real one has opened yet,
/// in Persian letters, as the copy around it writes it.
const String faSampleApp = 'اینستاگرام';

/// Persian Tone lines, in everyday spoken Persian (محاوره). Roast the
/// Urge, never the person; no insults, no swearing, no guilt about the
/// Planned break. After a Slip only Chill's line is ever said (see voice).
const CopyPack fa = {
  Tone.chill: {
    Moment.urge: [
      'هنوز نه. {app} تا استراحتت صبر می‌کنه.',
      'هنوز نه. بذارش برای استراحتت.',
    ],
    Moment.afterSlip: ['اشکال نداره، برگرد.'],
    Moment.breakHere: ['{minutes} دقیقه ریلز، پیام، هر چی دلت خواست.'],
    Moment.breakOver: ['استراحت تموم شد.'],
    Moment.evening: ['شب خوبی بود. دمت گرم.'],
    Moment.newBest: ['به هدفت رسیدی. این طولانی‌ترین تمرکزت تا حالاست.'],
    Moment.receipt: ['آروم و پیوسته. فردا شب همین موقع؟'],
    Moment.receiptAfterSlip: ['برگشتی. فردا شب همین موقع؟'],
  },
  Tone.spicy: {
    Moment.urge: [
      'هنوز نه! {app} بدون تو هم تا استراحتت دووم میاره.',
      'هنوز نه! فید بدون تو هم تا استراحتت دووم میاره.',
    ],
    Moment.breakHere: ['{minutes} دقیقه ریلز قانونی. حلالت.'],
    Moment.breakOver: ['ریلز بسه. برگرد تو فاز.'],
    Moment.evening: ['امشب ترکوندی. پایه‌ای.'],
    Moment.newBest: ['طولانی‌ترین تمرکزت تا حالا. اورات رفت بالا.'],
    Moment.receipt: ['امشب لاک‌این بودی. اینم مدرکش.'],
    Moment.receiptAfterSlip: ['حواست پرت شد ولی برگشتی. همینه.'],
  },
  Tone.mom: {
    Moment.urge: [
      'باز گوشی دستته؟! {app} فرار نمی‌کنه، بذار استراحتت برسه!',
      'باز گوشی دستته؟! بذار استراحتت برسه!',
    ],
    Moment.breakHere: ['دمت گرم! حالا پاشو یه چایی بخور. {minutes} دقیقه.'],
    Moment.breakOver: ['بسه دیگه! پاشو برگرد سراغش.'],
    Moment.evening: ['آفرین! حالا تعریف کن ببینم چی شد.'],
    Moment.newBest: ['ماشالله! تا حالا این‌قدر یه‌سره نشسته بودی؟'],
    Moment.receipt: ['دمت گرم، حالا پاشو چایی بخور.'],
    Moment.receiptAfterSlip: ['برگشتی، همینش مهمه. حالا پاشو یه چایی بخور.'],
  },
};
