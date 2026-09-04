export class BodyPart {
  id: string;
  name: string;

  constructor(id: string, name: string) {
    this.id = id;
    this.name = name;
  }
}

export type ContentReviewStatus = 'raw' | 'reviewed' | 'approved' | 'rejected';
export type LocalizationStatus = 'raw' | 'auto' | 'reviewed' | 'approved';
export type ExerciseDifficulty = 'beginner' | 'intermediate' | 'advanced' | 'unknown';
export type ExerciseMechanic = 'compound' | 'isolation' | 'cardio' | 'mobility' | 'unknown';
export type ExerciseForce = 'push' | 'pull' | 'static' | 'mixed' | 'unknown';
export type MovementPattern = 'horizontal_push' | 'vertical_push' | 'horizontal_pull' | 'vertical_pull' |
  'squat' | 'hinge' | 'lunge' | 'carry' | 'core_flexion' | 'core_rotation' |
  'core_anti_extension' | 'core_anti_rotation' | 'cardio' | 'mobility' | 'other';

export interface ExerciseRecord {
  id: string;
  name: string;
  nameEn?: string;
  nameZh?: string;
  aliasesZh?: string[];
  partId: string;
  equipment: string;
  target: string;
  steps: string[];
  caution: string;
  equipmentSetup?: string;
  imagePath: string;
  motionPath: string;
  recommended: boolean;
  recommendedForBeginner?: boolean;
  gymEligible?: boolean;
  localizationStatus?: LocalizationStatus;
  difficulty?: ExerciseDifficulty;
  mechanic?: ExerciseMechanic;
  force?: ExerciseForce;
  movementPattern?: MovementPattern;
  contentReviewStatus?: ContentReviewStatus;
  libraryVisible?: boolean;
}

const HOME_EQUIPMENT: string[] = ['自重', '哑铃', '弹力带', '壶铃', '瑜伽垫'];

export class Exercise {
  id: string;
  name: string;
  nameEn: string;
  nameZh: string;
  aliasesZh: string[];
  partId: string;
  equipment: string;
  target: string;
  steps: string[];
  caution: string;
  equipmentSetup: string;
  imagePath: string;
  motionPath: string;
  recommended: boolean;
  recommendedForBeginner: boolean;
  gymEligible: boolean;
  localizationStatus: LocalizationStatus;
  difficulty: ExerciseDifficulty;
  mechanic: ExerciseMechanic;
  force: ExerciseForce;
  movementPattern: MovementPattern;
  contentReviewStatus: ContentReviewStatus;
  libraryVisible: boolean;

  constructor(record: ExerciseRecord) {
    this.id = record.id;
    this.nameEn = record.nameEn ?? record.name;
    this.nameZh = record.nameZh ?? '';
    this.aliasesZh = record.aliasesZh ?? [];
    this.name = this.nameZh.trim().length > 0 ? this.nameZh : this.nameEn;
    this.partId = record.partId;
    this.equipment = record.equipment;
    this.target = record.target;
    this.steps = record.steps;
    this.caution = record.caution;
    this.equipmentSetup = record.equipmentSetup ?? `调整${record.equipment}到舒适且稳定的位置。`;
    this.imagePath = record.imagePath;
    this.motionPath = record.motionPath;
    this.recommended = record.recommended;
    this.recommendedForBeginner = record.recommendedForBeginner ?? record.recommended;
    this.gymEligible = record.gymEligible ?? true;
    this.localizationStatus = record.localizationStatus ?? (this.nameZh.length > 0 ? 'reviewed' : 'raw');
    this.difficulty = record.difficulty ?? 'unknown';
    this.mechanic = record.mechanic ?? 'unknown';
    this.force = record.force ?? 'unknown';
    this.movementPattern = record.movementPattern ?? 'other';
    this.contentReviewStatus = record.contentReviewStatus ?? (record.recommended ? 'approved' : 'raw');
    this.libraryVisible = record.libraryVisible ?? true;
  }

  get tip(): string {
    return this.steps[0] ?? '';
  }

  get displayName(): string {
    return this.nameZh.trim().length > 0 ? this.nameZh : this.nameEn;
  }

  get stepsZh(): string[] {
    return this.steps;
  }

  get cautionsZh(): string {
    return this.caution;
  }

  get equipmentSetupZh(): string {
    return this.equipmentSetup;
  }
}
