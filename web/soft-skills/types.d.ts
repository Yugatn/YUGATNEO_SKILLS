export type Age = '4-6' | '7-11' | '12-17' | '18+';
export type ProgressStatus = 'not_started' | 'in_progress' | 'consolidated';
export type ReviewStatus = 'under_review' | 'approved' | 'unconfirmed';
export interface Skill {
 id: string; title: string; block: string; blockTitle: string;
 /** Hash of source card + common age adaptation; revised content gets fresh progress. */
 version: string;
 availability: 'outline' | 'exercise';
 review: { status: ReviewStatus; approvedBy: string | null; approvedAt: string | null };
 evidenceStatus: 'not_assessed';
 source: {url: string; heading: string; excerpt: string; sha256: string};
 situations: {child: string | null; adult: string | null};
 mechanism: string | null; ageAdaptation: string | null;
 steps: {id: string; text: string}[];
 questions: {reflection: string[]; coaching: string[]};
 criterion: string | null; recommendation: string | null;
}
export interface Progress {
 status: ProgressStatus; step: number; completed: string[]; criterionObserved: boolean;
}
export interface Catalogue {
 schemaVersion: 1; sourceUrl: string; retrievedAt: string;
 ages: {id: Age; label: string; guidance: string}[]; skills: Skill[];
}
