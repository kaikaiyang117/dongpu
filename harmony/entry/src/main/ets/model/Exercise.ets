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
}
