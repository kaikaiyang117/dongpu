export class BodyPart {
  id: string;
  name: string;

  constructor(id: string, name: string) {
    this.id = id;
    this.name = name;
  }
}

export interface ExerciseRecord {
  id: string;
  name: string;
  partId: string;
  equipment: string;
  target: string;
  steps: string[];
  caution: string;
  imagePath: string;
  motionPath: string;
  recommended: boolean;
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
  imagePath: string;
  motionPath: string;
  recommended: boolean;

  constructor(record: ExerciseRecord) {
    this.id = record.id;
    this.name = record.name;
    this.partId = record.partId;
    this.equipment = record.equipment;
    this.target = record.target;
    this.steps = record.steps;
    this.caution = record.caution;
    this.imagePath = record.imagePath;
    this.motionPath = record.motionPath;
    this.recommended = record.recommended;
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
    return `调整${this.equipment}到舒适且稳定的位置，先用轻重量确认动作路径。`;
  }

  get gymEligible(): boolean {
    return !HOME_EQUIPMENT.includes(this.equipment);
  }

  get contentApproved(): boolean {
    return this.recommended;
  }
}
