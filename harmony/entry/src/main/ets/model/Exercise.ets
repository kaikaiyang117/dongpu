export class BodyPart {
  id: string;
  name: string;

  constructor(id: string, name: string) {
    this.id = id;
    this.name = name;
  }
}

export type ContentReviewStatus = 'raw' | 'reviewed' | 'approved' | 'rejected';

export interface ExerciseRecord {
  id: string;
  name: string;
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
  contentReviewStatus?: ContentReviewStatus;
  libraryVisible?: boolean;
}

const HOME_EQUIPMENT: string[] = ['自重', '哑铃', '弹力带', '壶铃', '瑜伽垫'];

export class Exercise {
  id: string;
  name: string;
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
  contentReviewStatus: ContentReviewStatus;
  libraryVisible: boolean;

  constructor(record: ExerciseRecord) {
    this.id = record.id;
    this.name = record.name;
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
    this.contentReviewStatus = record.contentReviewStatus ?? (record.recommended ? 'approved' : 'raw');
    this.libraryVisible = record.libraryVisible ?? true;
  }

  get tip(): string {
    return this.steps[0] ?? '';
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
