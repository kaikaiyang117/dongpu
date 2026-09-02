import {
  APP_COLOR_GREEN,
  APP_COLOR_GREEN_DARK,
  APP_COLOR_GREEN_SOFT,
  APP_COLOR_LINE,
  APP_COLOR_MUTED,
  APP_COLOR_TEXT
} from '../../app/AppTheme';
import { OnboardingDraft } from '../../domain/profile/ProfileModels';

@Component
export struct OnboardingPage {
  @Prop isSaving: boolean = false;
  onStart: (draft: OnboardingDraft) => void = (_draft: OnboardingDraft) => {};

  @State private step: number = 1;
  @State private goalType: string = 'fat_loss';
  @State private heightText: string = '170';
  @State private currentWeightText: string = '70';
  @State private targetWeightText: string = '65';
  @State private waistText: string = '';
  @State private frequencyMin: number = 3;
  @State private frequencyMax: number = 4;
  @State private trainingLocation: string = 'gym';
  @State private dedicatedLegDay: boolean = false;
  @State private preferMachines: boolean = true;
  @State private nutritionMode: string = 'simple';

  private numberValue(text: string, fallback: number): number {
    const value: number = Number(text);
    return Number.isFinite(value) ? value : fallback;
  }

  private draft(): OnboardingDraft {
    return new OnboardingDraft(
      this.goalType,
      this.numberValue(this.heightText, 170),
      this.numberValue(this.currentWeightText, 70),
      this.numberValue(this.targetWeightText, 65),
      this.numberValue(this.waistText, 0),
      this.frequencyMin,
      this.frequencyMax,
      this.trainingLocation,
      this.dedicatedLegDay,
      this.preferMachines,
      this.nutritionMode
    );
  }

  private isValid(): boolean {
    if (this.step !== 2) {
      return true;
    }
    const height: number = this.numberValue(this.heightText, 0);
    const current: number = this.numberValue(this.currentWeightText, 0);
    const target: number = this.numberValue(this.targetWeightText, 0);
    return height >= 100 && height <= 240 && current > 0 && target > 0;
  }

  private next(): void {
    if (!this.isValid() || this.isSaving) {
      return;
    }
    if (this.step < 5) {
      this.step += 1;
      return;
    }
    this.onStart(this.draft());
  }

  private summaryCalories(): number {
    const currentWeight: number = this.numberValue(this.currentWeightText, 70);
    return Math.max(1400, Math.round(currentWeight * 28 - 300 + (this.frequencyMax - 3) * 50));
  }

  private summaryProtein(): number {
    return Math.round(this.numberValue(this.currentWeightText, 70) * 1.8);
  }

  @Builder
  ChoiceButton(label: string, selected: boolean, onTap: () => void) {
    Button(label)
      .height(46)
      .fontSize(14)
      .fontWeight(FontWeight.Bold)
      .fontColor(selected ? APP_COLOR_GREEN_DARK : APP_COLOR_TEXT)
      .borderRadius(14)
      .backgroundColor(selected ? APP_COLOR_GREEN_SOFT : Color.White)
      .border({ width: 1, color: selected ? APP_COLOR_GREEN : APP_COLOR_LINE })
      .stateEffect(true)
      .onClick(() => onTap())
  }

  @Builder
  Field(label: string, placeholder: string, value: string, onChange: (value: string) => void) {
    Column({ space: 8 }) {
      Text(label).width('100%').fontSize(14).fontColor(APP_COLOR_MUTED)
      TextInput({ placeholder: placeholder, text: value })
        .height(52)
        .fontSize(17)
        .backgroundColor(Color.White)
        .borderRadius(14)
        .border({ width: 1, color: APP_COLOR_LINE })
        .onChange((changed: string) => onChange(changed))
    }
    .width('100%')
  }

  @Builder
  GoalStep() {
    Column({ space: 18 }) {
      Text('先确定你的目标').width('100%').fontSize(28).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_TEXT)
      Text('目标会影响训练安排和每日建议。之后随时可以调整。')
        .width('100%').fontSize(15).fontColor(APP_COLOR_MUTED).lineHeight(22)
      Row({ space: 10 }) {
        this.ChoiceButton('减脂', this.goalType === 'fat_loss', () => this.goalType = 'fat_loss')
        this.ChoiceButton('增肌（后续支持）', false, () => {})
        this.ChoiceButton('保持体型（后续支持）', false, () => {})
      }.width('100%')
      Text('当前 MVP 先完整支持减脂目标，其余目标将在后续版本开放。')
        .width('100%').fontSize(13).fontColor(APP_COLOR_MUTED)
    }.width('100%')
  }

  @Builder
  BodyStep() {
    Column({ space: 16 }) {
      Text('告诉我你的起点').width('100%').fontSize(28).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_TEXT)
      Text('只用于生成初始目标，数据保存在本机。').width('100%').fontSize(15).fontColor(APP_COLOR_MUTED)
      this.Field('身高（cm）', '例如 170', this.heightText, (value: string) => this.heightText = value)
      this.Field('当前体重（kg）', '例如 70', this.currentWeightText, (value: string) => this.currentWeightText = value)
      this.Field('目标体重（kg）', '例如 65', this.targetWeightText, (value: string) => this.targetWeightText = value)
      this.Field('腰围（cm，可选）', '可以稍后记录', this.waistText, (value: string) => this.waistText = value)
      if (!this.isValid()) {
        Text('请填写有效的身高和体重').fontSize(13).fontColor('#C83B36')
      }
    }.width('100%')
  }

  @Builder
  TrainingStep() {
    Column({ space: 18 }) {
      Text('安排你的训练偏好').width('100%').fontSize(28).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_TEXT)
      Text('先给你一个可执行的 3—4 练方案。').width('100%').fontSize(15).fontColor(APP_COLOR_MUTED)
      Text('每周训练次数').width('100%').fontSize(14).fontColor(APP_COLOR_MUTED)
      Row({ space: 10 }) {
        this.ChoiceButton('3 次', this.frequencyMin === 3, () => {
          this.frequencyMin = 3;
          this.frequencyMax = 4;
        })
        this.ChoiceButton('4 次', this.frequencyMin === 4, () => {
          this.frequencyMin = 4;
          this.frequencyMax = 4;
        })
      }.width('100%')
      Text('训练地点').width('100%').fontSize(14).fontColor(APP_COLOR_MUTED)
      Row({ space: 10 }) {
        this.ChoiceButton('健身房', this.trainingLocation === 'gym', () => this.trainingLocation = 'gym')
        this.ChoiceButton('居家', this.trainingLocation === 'home', () => this.trainingLocation = 'home')
      }.width('100%')
      this.ChoiceButton(this.dedicatedLegDay ? '✓ 包含独立腿日' : '包含独立腿日', this.dedicatedLegDay,
        () => this.dedicatedLegDay = !this.dedicatedLegDay)
      this.ChoiceButton(this.preferMachines ? '✓ 优先使用固定器械' : '优先使用固定器械', this.preferMachines,
        () => this.preferMachines = !this.preferMachines)
    }.width('100%')
  }

  @Builder
  NutritionStep() {
    Column({ space: 18 }) {
      Text('选择记录方式').width('100%').fontSize(28).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_TEXT)
      Text('先从最容易坚持的方式开始，之后可以切换详细记录。')
        .width('100%').fontSize(15).fontColor(APP_COLOR_MUTED).lineHeight(22)
      this.ChoiceButton('简单：热量 + 蛋白质', this.nutritionMode === 'simple',
        () => this.nutritionMode = 'simple')
      this.ChoiceButton('详细：加上碳水 + 脂肪', this.nutritionMode === 'detailed',
        () => this.nutritionMode = 'detailed')
    }.width('100%')
  }

  @Builder
  SummaryStep() {
    Column({ space: 16 }) {
      Text('你的初始方案').width('100%').fontSize(28).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_TEXT)
      Text(`${this.numberValue(this.currentWeightText, 70)} kg → ${this.numberValue(this.targetWeightText, 65)} kg`)
        .fontSize(22).fontWeight(FontWeight.Bold)
      Text('这是可调整的初始目标，不是医疗建议。').width('100%').fontSize(14).fontColor(APP_COLOR_MUTED)
      Column({ space: 12 }) {
        this.SummaryRow('每日热量', `${this.summaryCalories()} kcal`)
        this.SummaryRow('每日蛋白质', `${this.summaryProtein()} g`)
        this.SummaryRow('每日步数', '8000 步')
        this.SummaryRow('训练安排', `${this.frequencyMin}—${this.frequencyMax} 次 / 周`)
        this.SummaryRow('记录方式', this.nutritionMode === 'simple' ? '热量 + 蛋白质' : '详细营养')
      }
      .width('100%').padding(18).borderRadius(18).backgroundColor(Color.White)
    }.width('100%')
  }

  @Builder
  SummaryRow(label: string, value: string) {
    Row() {
      Text(label).fontSize(15).fontColor(APP_COLOR_TEXT)
      Blank()
      Text(value).fontSize(15).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_GREEN_DARK)
    }.width('100%').height(38)
  }

  @Builder
  StepContent() {
    if (this.step === 1) {
      this.GoalStep()
    } else if (this.step === 2) {
      this.BodyStep()
    } else if (this.step === 3) {
      this.TrainingStep()
    } else if (this.step === 4) {
      this.NutritionStep()
    } else {
      this.SummaryStep()
    }
  }

  build() {
    Column() {
      Row() {
        if (this.step > 1) {
          Button('‹').width(48).height(48).fontSize(34).fontColor(APP_COLOR_TEXT)
            .backgroundColor(Color.Transparent).onClick(() => this.step -= 1)
        } else {
          Blank().width(48)
        }
        Text(`动谱  ${this.step} / 5`).layoutWeight(1).textAlign(TextAlign.Center)
          .fontSize(17).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_TEXT)
        Blank().width(48)
      }.width('100%').height(58)

      Scroll() {
        Column({ space: 24 }) {
          this.StepContent()
          Text('每一步都可以稍后在“我的”中修改。').width('100%').fontSize(13).fontColor(APP_COLOR_MUTED)
        }.width('100%').padding({ left: 20, right: 20, top: 24, bottom: 24 })
      }.layoutWeight(1).scrollBar(BarState.Off)

      Column() {
        Button(this.isSaving ? '正在保存…' : (this.step === 5 ? '完成并生成计划' : '下一步'))
          .width('100%').height(58).fontSize(17).fontWeight(FontWeight.Bold).fontColor(Color.White)
          .borderRadius(18).backgroundColor(APP_COLOR_GREEN).enabled(!this.isSaving && this.isValid())
          .onClick(() => this.next())
      }.width('100%').padding({ left: 20, right: 20, bottom: 22 })
    }.width('100%').height('100%')
  }
}
