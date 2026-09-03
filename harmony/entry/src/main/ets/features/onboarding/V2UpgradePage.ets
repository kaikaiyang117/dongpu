import {
  APP_COLOR_BG,
  APP_COLOR_DANGER,
  APP_COLOR_GREEN,
  APP_COLOR_GREEN_DARK,
  APP_COLOR_GREEN_SOFT,
  APP_COLOR_LINE,
  APP_COLOR_MUTED,
  APP_COLOR_SURFACE_DISABLED,
  APP_COLOR_TEXT
} from '../../app/AppTheme';
import { OnboardingDraft } from '../../domain/profile/ProfileModels';

@Component
export struct V2UpgradePage {
  @Prop isSaving: boolean = false;
  @Prop existingHeightCm: number = 0;
  @Prop existingWeightKg: number = 0;
  @Prop existingFrequency: number = 3;
  @State private heightText: string = '';
  @State private weightText: string = '';
  @State private targetText: string = '';
  @State private frequency: number = 3;
  @State private location: string = 'gym';
  @State private preferMachines: boolean = true;
  onComplete: (draft: OnboardingDraft) => void = (_draft: OnboardingDraft) => {};

  private numberValue(text: string): number {
    const value: number = Number(text);
    return Number.isFinite(value) ? value : 0;
  }

  private valid(): boolean {
    const height: number = this.numberValue(this.heightText);
    const weight: number = this.numberValue(this.weightText);
    const target: number = this.numberValue(this.targetText);
    return height >= 100 && height <= 240 && weight > 0 && target > 0 && !this.isSaving;
  }

  private submit(): void {
    if (!this.valid()) return;
    const draft: OnboardingDraft = new OnboardingDraft(
      'fat_loss', this.numberValue(this.heightText), this.numberValue(this.weightText),
      this.numberValue(this.targetText), 0, this.frequency, this.frequency === 3 ? 4 : 4,
      this.location, false, this.preferMachines, 'simple'
    );
    this.onComplete(draft);
  }

  @Builder
  Field(label: string, placeholder: string, text: string, onChange: (value: string) => void) {
    Column({ space: 7 }) {
      Text(label).width('100%').fontSize(14).fontColor(APP_COLOR_MUTED)
      TextInput({ placeholder: placeholder, text: text })
        .width('100%').height(50).fontSize(16).backgroundColor(Color.White).borderRadius(14)
        .border({ width: 1, color: APP_COLOR_LINE }).onChange((value: string) => onChange(value))
    }.width('100%')
  }

  @Builder
  ChoiceButton(label: string, selected: boolean, onTap: () => void) {
    Button(label).layoutWeight(1).height(46).fontSize(14).fontWeight(FontWeight.Bold)
      .fontColor(selected ? APP_COLOR_GREEN_DARK : APP_COLOR_TEXT)
      .backgroundColor(selected ? APP_COLOR_GREEN_SOFT : Color.White)
      .border({ width: 1, color: selected ? APP_COLOR_GREEN : APP_COLOR_LINE }).borderRadius(14)
      .stateEffect(true)
      .onClick(() => onTap())
  }

  build() {
    Column() {
      Row() {
        Text('动谱').fontSize(20).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_TEXT)
        Blank()
        Text('新版目标设置').fontSize(14).fontColor(APP_COLOR_GREEN_DARK)
      }.width('100%').height(58)
      Scroll() {
        Column({ space: 18 }) {
          Column({ space: 8 }) {
            Text('完成新版目标设置').width('100%').fontSize(28).fontWeight(FontWeight.Bold)
              .fontColor(APP_COLOR_TEXT)
            Text('你的旧训练记录会保留。请确认这些 V2 目标信息，再开始新的计划。')
              .width('100%').fontSize(15).fontColor(APP_COLOR_MUTED).lineHeight(22)
          }.width('100%')
          Column({ space: 14 }) {
            this.Field('当前身高（cm）', this.existingHeightCm > 0 ? `旧资料 ${this.existingHeightCm}，请确认` : '例如 170',
              this.heightText, (value: string) => this.heightText = value)
            this.Field('当前体重（kg）', this.existingWeightKg > 0 ? `最近记录 ${this.existingWeightKg.toFixed(1)}，请确认` : '例如 70',
              this.weightText, (value: string) => this.weightText = value)
            this.Field('目标体重（kg）', '请填写目标体重', this.targetText, (value: string) => this.targetText = value)
          }.width('100%').padding(18).borderRadius(18).backgroundColor(Color.White)
            .border({ width: 1, color: APP_COLOR_LINE })
          Column({ space: 12 }) {
            Text('每周训练次数').fontSize(14).fontColor(APP_COLOR_MUTED)
            Row({ space: 10 }) {
              this.ChoiceButton('3 次', this.frequency === 3, () => this.frequency = 3)
              this.ChoiceButton('4 次', this.frequency === 4, () => this.frequency = 4)
            }.width('100%')
            Text('当前 V2 计划支持 3 次必做训练，4 次可加一场 Optional。')
              .fontSize(13).fontColor(APP_COLOR_MUTED)
          }.width('100%').padding(18).borderRadius(18).backgroundColor(Color.White)
            .border({ width: 1, color: APP_COLOR_LINE })
          Column({ space: 12 }) {
            Text('训练偏好').fontSize(14).fontColor(APP_COLOR_MUTED)
            Row({ space: 10 }) {
              this.ChoiceButton('健身房', this.location === 'gym', () => this.location = 'gym')
              this.ChoiceButton('居家', this.location === 'home', () => this.location = 'home')
            }.width('100%')
            Button(this.preferMachines ? '✓ 优先使用固定器械' : '优先使用固定器械')
              .width('100%').height(46).fontSize(14).fontWeight(FontWeight.Bold)
              .fontColor(APP_COLOR_GREEN_DARK).backgroundColor(APP_COLOR_GREEN_SOFT).borderRadius(14)
              .onClick(() => this.preferMachines = !this.preferMachines)
          }.width('100%').padding(18).borderRadius(18).backgroundColor(Color.White)
            .border({ width: 1, color: APP_COLOR_LINE })
          if (!this.valid() && (this.heightText !== '' || this.weightText !== '' || this.targetText !== '')) {
            Text('请确认身高、体重和目标体重').width('100%').fontSize(13)
              .fontColor(APP_COLOR_DANGER)
          }
        }.width('100%').padding({ left: 20, right: 20, bottom: 24 })
      }.layoutWeight(1).scrollBar(BarState.Off)
      Column() {
        Button(this.isSaving ? '正在保存…' : '保存并进入今日')
          .width('100%').height(58).fontSize(17).fontWeight(FontWeight.Bold)
          .fontColor(Color.White).backgroundColor(this.valid() ? APP_COLOR_GREEN : APP_COLOR_SURFACE_DISABLED)
          .borderRadius(18).enabled(this.valid()).onClick(() => this.submit())
      }.width('100%').padding({ left: 20, right: 20, bottom: 22 }).backgroundColor(APP_COLOR_BG)
    }.width('100%').height('100%').backgroundColor(APP_COLOR_BG)
  }
}
