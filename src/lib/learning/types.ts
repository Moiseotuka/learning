import type { LevelType } from "@/config/catalog";

export type ChapterProgress = {
  attempts: number;
  bestScore: number | null;
  completed: boolean;
};

export type LearnerChapter = {
  id: string;
  slug: string;
  title: string;
  summary: string;
  level: LevelType;
  position: number;
  unlocked: boolean;
  /** Vrai si le niveau du chapitre n'est pas payé (débutant toujours gratuit). */
  levelLocked: boolean;
  /** Vrai si l'examen de fin du niveau précédent n'est pas réussi. */
  examLocked: boolean;
  progress: ChapterProgress | null;
  videosDone: boolean;
  practiceDone: boolean;
};

export type LevelExamState = {
  status: "none" | "in_progress" | "passed";
  bestScore: number | null;
  attempts: number;
  passedAt: string | null;
};

export type LevelExamInfo = {
  level: LevelType;
  totalChapters: number;
  completedChapters: number;
  allCompleted: boolean;
  exam: LevelExamState;
};

export type LearnerTrack = {
  id: string;
  slug: string;
  title: string;
  description: string;
  level: LevelType;
  durationHours: number;
  modules: number;
  rating: number;
  students: number;
  priceUsd: number | null;
  passingScore: number;
  category: string;
  categoryId: string;
  chapters: LearnerChapter[];
  levels: LevelExamInfo[];
  completedCount: number;
  totalChapters: number;
  percent: number;
  nextChapterSlug: string | null;
};

export type ChapterResource = { label: string; url: string };

export type ChapterVideo = {
  title: string;
  url: string;
  channel: string;
};

export type TrackResourceGroup = {
  chapterSlug: string;
  chapterTitle: string;
  position: number;
  resources: ChapterResource[];
};

export type LearnerPracticeState = {
  done: boolean;
  solutionViewed: boolean;
};

/** Une page numérotée du Cours (découpage type Cisco NetAcad). */
export type ChapterPage = {
  position: number;
  title: string;
  content: string;
};

export type LearnerChapterDetail = {
  id: string;
  slug: string;
  trackId: string;
  trackSlug: string;
  trackTitle: string;
  categoryId: string;
  title: string;
  summary: string;
  level: LevelType;
  position: number;
  objectives: string[];
  videos: ChapterVideo[];
  videoTokens: string[];
  videoWatched: string[];
  videosDone: boolean;
  /** Seconde de reprise par jeton de vidéo : reprend là où l'arrêt a eu lieu. */
  videoSeconds: Record<string, number>;
  /** Dernière page du Cours affichée (null si jamais mémorisée). */
  resumePage: number | null;
  /** Dernière étape ouverte du chapitre (vidéo, cours, exercice…). */
  resumeStep: string | null;
  /** Défilement du conteneur de leçon, par étape, au dernier arrêt. */
  resumeScrolls: Record<string, number>;
  content: string;
  /** Pages numérotées du Cours (vide si la migration n'est pas collée). */
  pages: ChapterPage[];
  exercise: string;
  starterCode: string;
  solutionCode: string;
  codeLanguage: string;
  practice: LearnerPracticeState;
  resources: ChapterResource[];
  passingScore: number;
  chapterCount: number;
  unlocked: boolean;
  /** Vrai si le niveau du chapitre n'est pas payé (débutant toujours gratuit). */
  levelLocked: boolean;
  /** Vrai si l'examen de fin du niveau précédent n'est pas réussi. */
  examLocked: boolean;
  /** Lien vers l'examen à réussir pour débloquer ce niveau (sinon null). */
  examHref: string | null;
  progress: ChapterProgress | null;
  prevSlug: string | null;
  nextSlug: string | null;
  nextUnlocked: boolean;
};

export type QuizQuestion = {
  id: string;
  question: string;
  choices: string[];
};

export type GradedQuestion = QuizQuestion & {
  answerIndex: number;
  explanation: string;
};

export type QuizQuestionResult = QuizQuestion & {
  selected: number;
  correctIndex: number;
  correct: boolean;
  explanation: string;
};

export type QuizState = {
  status: "success" | "error";
  message?: string;
  score?: number;
  passed?: boolean;
  attempts?: number;
  bestScore?: number;
  results?: QuizQuestionResult[];
  next?: { slug: string; title: string } | null;
};
