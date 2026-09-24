/**
 * Demo seed for QSPOT.
 *
 *   cd Qspot-API && node scripts/seed-demo.js          # only fills empty collections
 *   cd Qspot-API && node scripts/seed-demo.js --force   # wipes ALL these collections first
 *
 * Safe by design: it skips any collection that already has data unless --force.
 * --force wipes every collection this script touches, including per-user data
 * (video progress, video-quiz attempts, quiz attempts, quiz sessions) so a
 * reseed never leaves orphaned rows pointing at deleted content.
 */
require('dotenv').config();

const mongoose = require('mongoose');

const Course = require('../models/course');
const Subject = require('../models/subject');
const Speaker = require('../models/speakers');
const Schedule = require('../models/schedule');
const Video = require('../models/videos');
const VideoQuestion = require('../models/videoQuestions');
const VideoProgress = require('../models/videoProgress');
const VideoQuizAttempt = require('../models/videoQuizAttempt');
const Banner = require('../models/banner');
const Notification = require('../models/notification');
const User = require('../models/user');
const Question = require('../models/question');
const QuizConfig = require('../models/quizConfig');
const QuizQuestion = require('../models/quizQuestions');
const QuizAttempt = require('../models/quiz');
const QuizSession = require('../models/quizSession');
const Assignment = require('../models/assignment');
const AssignmentSubmission = require('../models/assignmentSubmission');

const FORCE = process.argv.includes('--force');
const PLACEHOLDER = (label, w = 640, h = 400) =>
  `https://placehold.co/${w}x${h}/111827/e5e7eb?text=${encodeURIComponent(label)}`;

const days = (n) => new Date(Date.now() + n * 24 * 60 * 60 * 1000);

async function needSeeding(Model) {
  const count = await Model.estimatedDocumentCount();
  if (count > 0 && !FORCE) {
    console.log(`skip  ${Model.collection.collectionName}: already has ${count} docs (use --force to reseed)`);
    return false;
  }
  if (count > 0 && FORCE) {
    await Model.deleteMany({});
    console.log(`wiped ${Model.collection.collectionName} (${count} docs)`);
  }
  return true;
}

// Per-user collections that must be wiped on --force even though nothing here
// re-seeds a *full* set of rows for them (they are seeded from the sample data
// below, keyed off freshly-created users/videos/quizzes).
async function wipeIfForce(Model) {
  if (!FORCE) return;
  const count = await Model.estimatedDocumentCount();
  if (count > 0) {
    await Model.deleteMany({});
    console.log(`wiped ${Model.collection.collectionName} (${count} docs)`);
  }
}

async function main() {
  await mongoose.connect(process.env.MONGODB_URI);
  console.log('connected:', mongoose.connection.name);

  if (FORCE) {
    // Always wiped first so leftover per-user rows never reference content
    // that this run is about to recreate with new ids.
    await wipeIfForce(VideoProgress);
    await wipeIfForce(VideoQuizAttempt);
    await wipeIfForce(QuizAttempt);
    await wipeIfForce(QuizSession);
    await wipeIfForce(AssignmentSubmission);
    await wipeIfForce(Assignment);
  }

  // ---------- course ----------
  let courses = [];
  let course;
  if (await needSeeding(Course)) {
    courses = await Course.create([
      {
        title: 'Quran Foundations',
        subtitle: 'Recitation, meaning, and daily practice',
        description: 'A structured path from Tajweed basics to confident daily recitation.',
        learnPoints: ['Correct Tajweed rules', 'Understand short surahs', 'Build a daily practice'],
        image: PLACEHOLDER('Quran Foundations', 1200, 630),
        order: 1,
        isActive: true
      },
      {
        title: 'Islamic Studies',
        subtitle: 'Seerah, Fiqh, and Aqeedah',
        description: 'A clear introduction to the stories, beliefs, and everyday practice of Islam.',
        learnPoints: ['Follow the Seerah timeline', 'Learn everyday Fiqh', 'Strengthen core beliefs'],
        image: PLACEHOLDER('Islamic Studies', 1200, 630),
        order: 2,
        isActive: true
      },
      {
        title: 'Arabic for Learners',
        subtitle: 'Words, meanings, and Quranic vocabulary',
        description: 'A gentle course for recognizing useful Arabic words in the Quran and daily life.',
        learnPoints: ['Recognize common words', 'Read simple phrases', 'Connect words to meaning'],
        image: PLACEHOLDER('Arabic for Learners', 1200, 630),
        order: 3,
        isActive: true
      }
    ]);
    console.log(`seeded courses: ${courses.length}`);
  } else {
    courses = await Course.find().sort({ order: 1 });
  }
  course = courses[0] || null;

  // ---------- subjects (linked to the course) ----------
  let subjects = [];
  if (await needSeeding(Subject)) {
    subjects = await Subject.create(
      [
        ['Quran Recitation', 0], ['Tajweed', 0], ['Surah Practice', 0],
        ['Seerah', 1], ['Fiqh', 1], ['Aqeedah', 1],
        ['Arabic Language', 2], ['Quranic Vocabulary', 2], ['Reading Practice', 2]
      ].map(([name, courseIndex], i) => ({
        order: i + 1,
        name,
        image: PLACEHOLDER(name),
        courseId: courses[courseIndex]?._id || null,
        isPublished: true,
        guideTitle: `Welcome to ${name}`,
        guidePoints: [
          { icon: 'info', text: `What you will learn in ${name}` },
          { icon: 'book', text: 'Watch each episode in order for the best flow' }
        ]
      }))
    );
    console.log(`seeded subjects: ${subjects.length}`);
  } else {
    subjects = await Subject.find().sort({ order: 1 });
  }

  // ---------- speakers ----------
  let speakers = [];
  if (await needSeeding(Speaker)) {
    speakers = await Speaker.create([
      { name: 'Ustadh Ahmed Sulaiman', designation: 'Qari & Hafiz', image: PLACEHOLDER('Ahmed Sulaiman', 400, 400), order: 1 },
      { name: 'Dr. Ibrahim Khan', designation: 'Islamic Studies', image: PLACEHOLDER('Ibrahim Khan', 400, 400), order: 2 },
      { name: 'Ustadha Maryam Yusuf', designation: 'Tajweed Instructor', image: PLACEHOLDER('Maryam Yusuf', 400, 400), order: 3 },
      { name: 'Ustadh Bilal Rasheed', designation: 'Seerah & History', image: PLACEHOLDER('Bilal Rasheed', 400, 400), order: 4 }
    ]);
    console.log(`seeded speakers: ${speakers.length}`);
  } else {
    speakers = await Speaker.find().sort({ order: 1 });
  }

  // ---------- schedules ----------
  if (await needSeeding(Schedule)) {
    await Schedule.create([
      { class: 'Class 8', title: 'Tajweed Basics — Makharij', scheduleDate: days(2), faculty: speakers[0]._id },
      { class: 'Class 9', title: 'Seerah: The Makkan Period', scheduleDate: days(3), faculty: speakers[1]._id },
      { class: 'Class 10', title: 'Fiqh: Pillars of Salah', scheduleDate: days(5), faculty: speakers[2]._id },
      { class: 'Class 8', title: 'Surah Al-Mulk — Word by Word', scheduleDate: days(7), faculty: speakers[3]._id }
    ]);
    console.log('seeded schedules: 4');
  } else {
    console.log('skip  schedules');
  }

  // ---------- videos ----------
  let videos = [];
  if (await needSeeding(Video)) {
    videos = await Video.create([
      {
        title: 'Episode 1 — Tajweed Basics',
        description: 'Demo row so the Videos tab is not empty. Replace the YouTube link with your own lecture.',
        video: 'https://youtu.be/VHGZ-EenPQQ',
        subject: subjects[1]._id,
        speaker: speakers[2]._id,
        order: 1,
        isPublished: true,
        durationSeconds: 600,
        releaseDate: '2026-09-10',
        learnText: 'This episode covers the basic articulation points (Makharij) used in correct recitation.',
        learnPoints: ['Identify the main Makharij groups', 'Practice each sound slowly'],
        downloads: [{ title: 'Makharij chart (PDF)', url: PLACEHOLDER('Makharij+PDF', 200, 260), key: null }]
      },
      {
        title: 'Episode 1 — Seerah: The Makkan Period',
        description: 'Demo row so the Videos tab is not empty. Replace the YouTube link with your own lecture.',
        video: 'https://youtu.be/o47jjN_1p6g',
        subject: subjects[2]._id,
        speaker: speakers[3]._id,
        order: 1,
        isPublished: true,
        durationSeconds: 540,
        releaseDate: '2026-09-12',
        learnText: 'An overview of the first thirteen years of revelation in Makkah.',
        learnPoints: ['Key events of the Makkan period', 'Why the early message focused on Tawheed'],
        downloads: []
      },
      {
        title: 'Episode 1 — Surah Al-Fatihah, word by word',
        description: 'Demo row so the Videos tab is not empty. Replace the YouTube link with your own lecture.',
        video: 'https://youtu.be/wdKE4awU5S0',
        subject: subjects[0]._id,
        speaker: speakers[0]._id,
        order: 1,
        isPublished: true,
        durationSeconds: 480,
        releaseDate: '2026-09-15',
        learnText: 'A word-by-word walkthrough of Surah Al-Fatihah.',
        learnPoints: ['Meaning of each verse', 'Correct pronunciation of key words'],
        downloads: []
      },
      {
        title: 'Episode 2 — Coming soon',
        description: 'An upcoming episode; releaseDate is in the future so it is withheld from public listings.',
        video: 'https://youtu.be/VHGZ-EenPQQ',
        subject: subjects[1]._id,
        speaker: speakers[2]._id,
        order: 2,
        isPublished: true,
        durationSeconds: 0,
        releaseDate: days(14).toISOString()
      }
    ]);
    console.log(`seeded videos: ${videos.length}`);
  } else {
    videos = await Video.find().sort({ subject: 1, order: 1 });
  }

  // ---------- video questions (comprehension quiz per episode) ----------
  if (await needSeeding(VideoQuestion)) {
    const targetVideo = videos[0];
    if (targetVideo) {
      await VideoQuestion.create([
        {
          videoId: targetVideo._id,
          type: 'Multiple Choice',
          question_en: 'What does "Makharij" refer to?',
          question_ml: '"മഖാരിജ്" എന്താണ് സൂചിപ്പിക്കുന്നത്?',
          options_en: JSON.stringify(['Articulation points of letters', 'Prayer times', 'Names of Allah', 'Chapters of the Quran']),
          options_ml: JSON.stringify(['അക്ഷരങ്ങളുടെ ഉച്ചാരണസ്ഥാനങ്ങൾ', 'നമസ്കാര സമയങ്ങൾ', 'അല്ലാഹുവിന്റെ നാമങ്ങൾ', 'ഖുർആൻ അധ്യായങ്ങൾ']),
          correct_answer: 'Articulation points of letters',
          difficulty: 'Easy',
          order: 0
        },
        {
          videoId: targetVideo._id,
          type: 'Multiple Choice',
          question_en: 'Who presents this episode?',
          question_ml: 'ഈ എപ്പിസോഡ് അവതരിപ്പിക്കുന്നത് ആരാണ്?',
          options_en: JSON.stringify(['Ustadha Maryam Yusuf', 'Dr. Ibrahim Khan', 'Ustadh Bilal Rasheed', 'Ustadh Ahmed Sulaiman']),
          options_ml: JSON.stringify(['ഉസ്താദ മറിയം യൂസുഫ്', 'ഡോ. ഇബ്രാഹീം ഖാൻ', 'ഉസ്താദ് ബിലാൽ റഷീദ്', 'ഉസ്താദ് അഹ്മദ് സുലൈമാൻ']),
          correct_answer: 'Ustadha Maryam Yusuf',
          difficulty: 'Medium',
          order: 1
        }
      ]);
      console.log('seeded video questions: 2');
    }
  } else {
    console.log('skip  video questions');
  }

  // ---------- banners ----------
  if (await needSeeding(Banner)) {
    await Banner.create([
      { image: PLACEHOLDER('QSPOT - Your Space for Quran Vibes', 1200, 400) },
      { image: PLACEHOLDER('Weekly Quiz is live', 1200, 400) }
    ]);
    console.log('seeded banners: 2');
  } else {
    console.log('skip  banners');
  }

  // ---------- notifications ----------
  if (await needSeeding(Notification)) {
    await Notification.create([
      { title: 'Weekly Quran Quiz is live', description: '10 questions, 10 minutes. Attempt it before Friday.' },
      { title: 'New class added', description: 'Seerah: The Makkan Period — Class 9, this week.' },
      { title: 'Welcome to QSPOT', description: 'Your space for Quran vibes. Join a class and start a quiz.' }
    ]);
    console.log('seeded notifications: 3');
  } else {
    console.log('skip  notifications');
  }

  // ---------- users ----------
  let users = [];
  if (await needSeeding(User)) {
    const allCourseIds = courses.map((item) => item._id);
    const quranCourseIds = courses[0] ? [courses[0]._id] : [];
    const studiesCourseIds = courses[1] ? [courses[1]._id] : [];
    const allAndStudiesCourseIds = courses.slice(0, 2).map((item) => item._id);
    users = await User.create([
      { name: 'Demo Student 1', phone: '0000000001', email: 'student1@example.com', class: 'Class 8', courseIds: quranCourseIds },
      { name: 'Demo Student 2', phone: '0000000002', email: 'student2@example.com', class: 'Class 8', courseIds: allAndStudiesCourseIds },
      { name: 'Demo Student 3', phone: '0000000003', email: 'student3@example.com', class: 'Class 9', courseIds: studiesCourseIds },
      { name: 'Demo Student 4', phone: '0000000004', email: 'student4@example.com', class: 'Class 9', courseIds: allCourseIds },
      { name: 'Demo Student 5', phone: '0000000005', email: 'student5@example.com', class: 'Class 10', courseIds: quranCourseIds },
      { name: 'Demo Student 6', phone: '0000000006', email: 'student6@example.com', class: 'Class 10', courseIds: allCourseIds },
      // Appended at the end on purpose: the questions/attempts below reference
      // users[0..4] positionally, so the dev sign-in users must not shift them.
      // Keep the seeded test account aligned with TEST_LOGIN in .env.
      { name: 'Test Student', phone: process.env.TEST_LOGIN || '9876543210', email: 'test@example.com', class: 'Class 8', courseIds: allAndStudiesCourseIds },
      { name: 'Test Student 2', phone: '8888888888', email: 'test2@example.com', class: 'Class 9', courseIds: studiesCourseIds }
    ]);
    console.log(`seeded users: ${users.length}`);
  } else {
    users = await User.find().limit(8);
  }

  // Faculty accounts use the same OTP login as students, but receive a
  // faculty-scoped token and can manage questions assigned to their profile.
  if (speakers.length && (FORCE || !(await User.exists({ role: 'faculty' })))) {
    await User.deleteMany({ role: 'faculty' });
    await User.create(speakers.map((speaker, index) => ({
      name: speaker.name,
      phone: `600000000${index + 1}`,
      email: `faculty${index + 1}@qspot.demo`,
      class: 'Faculty',
      role: 'faculty',
      facultyProfile: speaker._id,
      courseIds: []
    })));
    console.log(`seeded faculty accounts: ${speakers.length}`);
  }

  // ---------- assignments + submissions ----------
  let assignments = [];
  if (await needSeeding(Assignment)) {
    assignments = await Assignment.create([
      {
        title: 'Record Surah Al-Fatihah',
        instructions: 'Submit a short recording of your recitation and note one Tajweed rule you practised.',
        courseId: courses[0]?._id || null,
        subjectId: subjects[0]?._id || null,
        class: 'Class 8',
        releaseAt: days(-4),
        dueAt: days(3),
        maxPoints: 20,
        allowedMimeTypes: ['audio/mpeg', 'audio/wav', 'audio/mp4', 'image/jpeg', 'image/png'],
        isPublished: true,
        createdBy: 'Ustadha Maryam Yusuf',
        facultyProfile: speakers[2]._id
      },
      {
        title: 'Makkan Period Reflection',
        instructions: 'Write five sentences about one lesson from the Makkan period of the Seerah.',
        courseId: courses[1]?._id || null,
        subjectId: subjects[3]?._id || null,
        class: '',
        releaseAt: days(-2),
        dueAt: days(5),
        maxPoints: 25,
        allowedMimeTypes: ['application/pdf', 'text/plain', 'image/jpeg', 'image/png'],
        isPublished: true,
        createdBy: 'Ustadh Bilal Rasheed',
        facultyProfile: speakers[3]._id
      },
      {
        title: 'Quranic Vocabulary Cards',
        instructions: 'Create ten vocabulary cards with the Arabic word, transliteration, and meaning.',
        courseId: courses[2]?._id || null,
        subjectId: subjects[7]?._id || null,
        class: 'Class 9',
        releaseAt: days(1),
        dueAt: days(10),
        maxPoints: 30,
        allowedMimeTypes: ['application/pdf', 'image/jpeg', 'image/png'],
        isPublished: false,
        createdBy: 'Ustadha Maryam Yusuf',
        facultyProfile: speakers[2]._id
      }
    ]);
    console.log(`seeded assignments: ${assignments.length}`);
  } else {
    assignments = await Assignment.find().sort({ dueAt: 1 });
  }

  if (assignments.length > 0 && users.length > 1 && (await needSeeding(AssignmentSubmission))) {
    await AssignmentSubmission.create([
      {
        assignmentId: assignments[0]._id,
        userId: users[0]._id,
        text: 'I practised the qalqalah and madd rules while recording.',
        status: 'graded',
        grade: 18,
        feedback: 'Clear recitation. Keep the elongations steady.',
        submittedAt: days(-1),
        gradedAt: days(-1),
        gradedBy: 'Ustadha Maryam Yusuf'
      },
      {
        assignmentId: assignments[1]?._id || assignments[0]._id,
        userId: users[1]._id,
        text: 'The Makkan period teaches patience, clarity, and trust in Allah.',
        status: 'submitted',
        submittedAt: days(-1)
      }
    ]);
    console.log('seeded assignment submissions: 2');
  }

  // ---------- questions (student -> faculty Q&A) ----------
  if (await needSeeding(Question)) {
    await Question.create([
      {
        description: 'What is the difference between Madd and Ghunnah?',
        faculty: speakers[2]._id,
        subject: 'Tajweed',
        user: users[0]._id,
        answer: 'Madd is the elongation of a vowel sound, Ghunnah is the nasal sound of noon/meem.',
        answeredBy: 'Ustadha Maryam Yusuf',
        answeredAt: days(-1)
      },
      {
        description: 'How many years did the revelation in Makkah last?',
        faculty: speakers[3]._id,
        subject: 'Seerah',
        user: users[2]._id,
        answer: 'About 13 years in Makkah, then 10 years in Madinah.',
        answeredBy: 'Ustadh Bilal Rasheed',
        answeredAt: days(-2)
      },
      {
        description: 'Can I combine two prayers while travelling by bus?',
        faculty: speakers[1]._id,
        subject: 'Fiqh',
        user: users[4]._id
      },
      {
        description: 'Which surah should a beginner memorise first?',
        faculty: speakers[0]._id,
        subject: 'Quran Recitation',
        user: users[1]._id
      },
      {
        description: 'What does Tawheed mean in simple words?',
        faculty: speakers[1]._id,
        subject: 'Aqeedah',
        user: users[3]._id
      }
    ]);
    console.log('seeded questions: 5');
  } else {
    console.log('skip  questions');
  }

  // ---------- quiz configurations (titled — legacy singleton is gone) ----------
  let weeklyQuiz;
  if (await needSeeding(QuizConfig)) {
    const [weekly] = await QuizConfig.create([
      {
        title: 'Weekly Quran Quiz — Week 1',
        startDate: days(-1),
        endDate: days(7),
        numberOfQuestions: 5,
        questionsRandomization: true,
        isEnable: true,
        overallTimeLimit: 600,
        perQuestionTimeLimit: 60,
        timerMode: 'both',
        allowedClasses: ['Class 8', 'Class 9', 'Class 10'],
        conditions: { requireCompletedVideo: false },
        optionsCount: 4
      },
      {
        title: 'Ramadan Special Quiz',
        startDate: days(30),
        endDate: days(45),
        numberOfQuestions: 10,
        questionsRandomization: false,
        isEnable: false,
        overallTimeLimit: 900,
        perQuestionTimeLimit: null,
        timerMode: 'overall',
        allowedClasses: [],
        conditions: { requireCompletedVideo: false },
        optionsCount: 4
      }
    ]);
    weeklyQuiz = weekly;
    console.log('seeded quiz configs: 2');
  } else {
    weeklyQuiz = await QuizConfig.findOne({ isEnable: true }).sort({ startDate: -1 });
    console.log('skip  quiz configs');
  }

  // ---------- quiz questions (options_en/ml are JSON-encoded arrays) ----------
  let quizQuestionDocs = [];
  if (await needSeeding(QuizQuestion)) {
    const rows = [
      {
        type: 'Multiple Choice', difficulty: 'Easy',
        question_en: 'How many surahs are there in the Quran?',
        question_ml: 'ഖുർആനിൽ എത്ര സൂറഃകൾ ഉണ്ട്?',
        options_en: ['114', '112', '116', '120'],
        options_ml: ['114', '112', '116', '120'],
        correct: '114'
      },
      {
        type: 'Multiple Choice', difficulty: 'Easy',
        question_en: 'Which is the longest surah in the Quran?',
        question_ml: 'ഖുർആനിലെ ഏറ്റവും വലിയ സൂറഃ ഏതാണ്?',
        options_en: ['Al-Baqarah', 'Yaseen', 'Al-Fatihah', 'An-Nur'],
        options_ml: ['അൽ-ബഖറഃ', 'യാസീൻ', 'അൽ-ഫാതിഹഃ', 'അൻ-നൂർ'],
        correct: 'Al-Baqarah'
      },
      {
        type: 'Multiple Choice', difficulty: 'Medium',
        question_en: 'Over how many years was the Quran revealed?',
        question_ml: 'ഖുർആൻ എത്ര വർഷം കൊണ്ടാണ് അവതരിച്ചത്?',
        options_en: ['23 years', '13 years', '40 years', '10 years'],
        options_ml: ['23 വർഷം', '13 വർഷം', '40 വർഷം', '10 വർഷം'],
        correct: '23 years'
      },
      {
        type: 'Multiple Choice', difficulty: 'Medium',
        question_en: 'Which surah is known as the heart of the Quran?',
        question_ml: 'ഖുർആന്റെ ഹൃദയം എന്നറിയപ്പെടുന്ന സൂറഃ ഏതാണ്?',
        options_en: ['Yaseen', 'Al-Fatihah', 'Al-Ikhlas', 'Ar-Rahman'],
        options_ml: ['യാസീൻ', 'അൽ-ഫാതിഹഃ', 'അൽ-ഇഖ്ലാസ്', 'അർ-റഹ്മാൻ'],
        correct: 'Yaseen'
      },
      {
        type: 'Multiple Choice', difficulty: 'Easy',
        question_en: 'Which is the first surah of the Quran?',
        question_ml: 'ഖുർആനിലെ ആദ്യ സൂറഃ ഏതാണ്?',
        options_en: ['Al-Fatihah', 'Al-Baqarah', 'An-Nas', 'Al-Alaq'],
        options_ml: ['അൽ-ഫാതിഹഃ', 'അൽ-ബഖറഃ', 'അൻ-നാസ്', 'അൽ-അലഖ്'],
        correct: 'Al-Fatihah'
      },
      {
        type: 'Multiple Choice', difficulty: 'Hard',
        question_en: 'Which surah does not begin with Bismillah?',
        question_ml: 'ബിസ്മില്ലാഹിനോടെ ആരംഭിക്കാത്ത സൂറഃ ഏതാണ്?',
        options_en: ['At-Tawbah', 'Al-Kahf', 'Maryam', 'Luqman'],
        options_ml: ['അത്-തൗബഃ', 'അൽ-കഹ്ഫ്', 'മറിയം', 'ലുഖ്മാൻ'],
        correct: 'At-Tawbah'
      },
      {
        type: 'Multiple Choice', difficulty: 'Easy',
        question_en: 'How many juz are in the Quran?',
        question_ml: 'ഖുർആനിൽ എത്ര ജുസ്ഉ് ഉണ്ട്?',
        options_en: ['30', '20', '40', '60'],
        options_ml: ['30', '20', '40', '60'],
        correct: '30'
      },
      {
        type: 'Multiple Choice', difficulty: 'Medium',
        question_en: 'In which cave was the first revelation received?',
        question_ml: 'ആദ്യ വഹ്യ് ലഭിച്ചത് ഏത് ഗുഹയിലാണ്?',
        options_en: ['Cave of Hira', 'Cave of Thawr', 'Cave of Uhud', 'Cave of Safa'],
        options_ml: ['ഹിറാ ഗുഹ', 'സൗർ ഗുഹ', 'ഉഹുദ് ഗുഹ', 'സഫാ ഗുഹ'],
        correct: 'Cave of Hira'
      },
      {
        type: 'Multiple Choice', difficulty: 'Hard',
        question_en: 'Which prophet is mentioned most by name in the Quran?',
        question_ml: 'ഖുർആനിൽ ഏറ്റവും കൂടുതൽ പ്രാവശ്യം പേര് പറയപ്പെട്ട നബി ആരാണ്?',
        options_en: ['Musa (AS)', 'Ibrahim (AS)', 'Isa (AS)', 'Nuh (AS)'],
        options_ml: ['മൂസാ (അ)', 'ഇബ്രാഹീം (അ)', 'ഈസാ (അ)', 'നൂഹ് (അ)'],
        correct: 'Musa (AS)'
      },
      {
        type: 'Multiple Choice', difficulty: 'Easy',
        question_en: 'How many ayat are in Surah Al-Fatihah?',
        question_ml: 'സൂറഃ അൽ-ഫാതിഹഃയിൽ എത്ര ആയത്തുകൾ ഉണ്ട്?',
        options_en: ['7', '5', '6', '8'],
        options_ml: ['7', '5', '6', '8'],
        correct: '7'
      }
    ];

    quizQuestionDocs = await QuizQuestion.create(
      rows.map((r, i) => {
        // Rotate the options so the correct answer is not always first — with
        // every answer at index 0 the quiz is trivially guessable.
        const targetIndex = i % r.options_en.length;
        const moveCorrect = (list, correct) => {
          const others = list.filter((o) => o !== correct);
          others.splice(targetIndex, 0, correct);
          return others;
        };
        return {
          quizId: weeklyQuiz ? weeklyQuiz._id : null,
          type: r.type,
          question_en: r.question_en,
          question_ml: r.question_ml,
          options_en: JSON.stringify(moveCorrect(r.options_en, r.correct)),
          options_ml: JSON.stringify(moveCorrect(r.options_ml, r.options_ml[r.options_en.indexOf(r.correct)])),
          correct_answer: r.correct,
          difficulty: r.difficulty
        };
      })
    );
    console.log(`seeded quiz questions: ${rows.length}`);
  } else {
    console.log('skip  quiz questions');
    quizQuestionDocs = await QuizQuestion.find({ quizId: weeklyQuiz ? weeklyQuiz._id : null });
  }

  // ---------- sample video progress + video-quiz attempt ----------
  if (videos[0] && users[0]) {
    const duration = videos[0].durationSeconds || 600;
    await VideoProgress.create({
      userId: users[0]._id,
      videoId: videos[0]._id,
      positionSeconds: duration,
      maxPositionSeconds: duration,
      watchedSeconds: duration,
      durationSeconds: duration,
      completed: true,
      completedAt: days(-1),
      lastViewedAt: days(-1)
    });

    const videoQuestionsForVideo = await VideoQuestion.find({ videoId: videos[0]._id });
    if (videoQuestionsForVideo.length > 0) {
      const answers = videoQuestionsForVideo.map((q, i) => ({
        questionId: q._id,
        attemptedAnswer: '0',
        isCorrect: i === 0
      }));
      const score = answers.filter((a) => a.isCorrect).length;
      await VideoQuizAttempt.create({
        userId: users[0]._id,
        videoId: videos[0]._id,
        language: 'English',
        answers,
        score,
        totalQuestions: answers.length,
        percentage: Math.round((score / answers.length) * 100)
      });
    }
    console.log('seeded sample video progress + video-quiz attempt for Demo Student 1');
  }

  // ---------- sample quiz session + attempt (consistent: session -> attempt) ----------
  if (weeklyQuiz && quizQuestionDocs.length > 0 && users[2]) {
    const sessionQuestionIds = quizQuestionDocs.slice(0, weeklyQuiz.numberOfQuestions).map((q) => q._id);

    const answers = sessionQuestionIds.map((qid, i) => {
      const q = quizQuestionDocs.find((doc) => String(doc._id) === String(qid));
      const options = JSON.parse(q.options_en);
      const correctIndex = options.findIndex((o) => o === q.correct_answer);
      // First attempt: get everything right except question index 1.
      const attemptedAnswer = i === 1 ? (correctIndex + 1) % options.length : correctIndex;
      return {
        questionId: qid,
        attemptedAnswer,
        isCorrect: attemptedAnswer === correctIndex,
        duration: 10 + i
      };
    });
    const score = answers.filter((a) => a.isCorrect).length;

    await QuizAttempt.create({
      userId: users[2]._id,
      quizId: weeklyQuiz._id,
      language: 'English',
      questionIds: sessionQuestionIds,
      answers,
      score,
      totalQuestions: answers.length,
      percentage: Math.round((score / answers.length) * 100),
      totalDuration: answers.reduce((sum, a) => sum + a.duration, 0)
    });
    console.log('seeded sample quiz attempt for Demo Student 3');
  }

  console.log('\n--- totals ---');
  const totals = {
    courses: Course,
    subjects: Subject,
    speakers: Speaker,
    schedules: Schedule,
    videos: Video,
    videoquestions: VideoQuestion,
    videoprogresses: VideoProgress,
    videoquizattempts: VideoQuizAttempt,
    banners: Banner,
    notifications: Notification,
    users: User,
    questions: Question,
    quizconfigs: QuizConfig,
    quizquestions: QuizQuestion,
    quizzes: QuizAttempt,
    quizsessions: QuizSession,
    assignments: Assignment,
    assignmentsubmissions: AssignmentSubmission
  };
  for (const [name, Model] of Object.entries(totals)) {
    console.log(`  ${name.padEnd(18)} ${await Model.estimatedDocumentCount()}`);
  }

  await mongoose.disconnect();
}

main().catch(async (err) => {
  console.error('SEED FAILED:', err.message);
  await mongoose.disconnect().catch(() => {});
  process.exit(1);
});
