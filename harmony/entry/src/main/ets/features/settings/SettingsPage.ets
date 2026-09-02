import {
  APP_COLOR_GREEN_DARK,
  APP_COLOR_GREEN_SOFT,
  APP_COLOR_LINE,
  APP_COLOR_MUTED,
  APP_COLOR_TEXT
} from '../../app/AppTheme';

@Component
export struct SettingsPage {
  @Prop title: string = '设置';
  @Prop weeklyFrequency: number = 2;
  @Prop weightUnit: string = 'kg';
  @Prop targetCalories: number = 0;
  @Prop targetProteinG: number = 0;
  @Prop targetSteps: number = 0;
  @Prop todaySteps: number = 0;
  @Prop trainingLocation: string = 'gym';
  @Prop dedicatedLegDay: boolean = false;
  @Prop preferMachines: boolean = true;
  @Prop isSaving: boolean = false;
  @State private caloriesText: string = '';
  @State private proteinText: string = '';
  @State private stepsText: string = '';
  @State private todayStepsText: string = '';
  onBack: () => void = () => {};
  onChangeFrequency: (frequency: number) => void = () => {};
  onChangeWeightUnit: (unit: string) => void = () => {};
  onSaveTargets: (calories: number, proteinG: number, steps: number) => void =
    (_calories: number, _proteinG: number, _steps: number) => {};
  onChangeTrainingPreference: (location: string, dedicatedLegDay: boolean, preferMachines: boolean) => void =
    (_location: string, _dedicatedLegDay: boolean, _preferMachines: boolean) => {};
  onSaveSteps: (steps: number) => void = (_steps: number) => {};

  private targetValue(text: string, fallback: number): number {
    if (text === '') return fallback;
    const value: number = Number(text);
    return Number.isFinite(value) && value >= 0 ? value : fallback;
  }

  private saveTargets(): void {
    this.onSaveTargets(this.targetValue(this.caloriesText, this.targetCalories),
      this.targetValue(this.proteinText, this.targetProteinG), this.targetValue(this.stepsText, this.targetSteps));
  }

  @Builder
  ChoiceButton(label: string, selected: boolean, onTap: () => void) {
    Button(label)
      .height(40)
      .fontSize(13)
      .fontWeight(FontWeight.Bold)
      .fontColor(selected ? APP_COLOR_GREEN_DARK : APP_COLOR_MUTED)
      .borderRadius(12)
      .backgroundColor(selected ? APP_COLOR_GREEN_SOFT : Color.White)
      .border({ width: 1, color: selected ? APP_COLOR_GREEN_DARK : APP_COLOR_LINE })
      .onClick(() => onTap())
  }

  @Builder
  InfoRow(label: string, value: string) {
    Row() {
      Text(label).fontSize(14).fontColor(APP_COLOR_TEXT)
      Blank()
      Text(value).fontSize(13).fontColor(APP_COLOR_MUTED)
    }
    .width('100%')
    .height(48)
    .border({ width: { bottom: 1 }, color: APP_COLOR_LINE })
  }

  @Builder
  SectionHeader(title: string) {
    Text(title).width('100%').fontSize(13).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_MUTED)
  }

  build() {
    Column() {
      Row() {
        Button('‹')
          .width(48)
          .height(48)
          .fontSize(34)
          .fontColor(APP_COLOR_TEXT)
          .backgroundColor(Color.Transparent)
          .onClick(() => this.onBack())
        Text(this.title)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .fontSize(19)
          .fontWeight(FontWeight.Bold)
          .fontColor(APP_COLOR_TEXT)
        Blank().width(48)
      }
      .width('100%')
      .height(56)

      Scroll() {
        Column({ space: 20 }) {
          Column({ space: 13 }) {
            this.SectionHeader('当前目标')
            this.InfoRow('目标热量', `${this.targetCalories} kcal`)
            this.InfoRow('蛋白质目标', `${this.targetProteinG} g`)
            this.InfoRow('步数目标', `${this.targetSteps} 步`)
            TextInput({ placeholder: `热量（当前 ${this.targetCalories}）`, text: this.caloriesText })
              .height(46).fontSize(14).backgroundColor(Color.White).borderRadius(12)
              .border({ width: 1, color: APP_COLOR_LINE }).onChange((value: string) => this.caloriesText = value)
            TextInput({ placeholder: `蛋白质（当前 ${this.targetProteinG}）`, text: this.proteinText })
              .height(46).fontSize(14).backgroundColor(Color.White).borderRadius(12)
              .border({ width: 1, color: APP_COLOR_LINE }).onChange((value: string) => this.proteinText = value)
            TextInput({ placeholder: `步数（当前 ${this.targetSteps}）`, text: this.stepsText })
              .height(46).fontSize(14).backgroundColor(Color.White).borderRadius(12)
              .border({ width: 1, color: APP_COLOR_LINE }).onChange((value: string) => this.stepsText = value)
            Button(this.isSaving ? '正在保存…' : '保存目标').width('100%').height(44).fontSize(14)
              .fontWeight(FontWeight.Bold).fontColor(Color.White).backgroundColor(APP_COLOR_GREEN_DARK)
              .borderRadius(12).enabled(!this.isSaving).onClick(() => this.saveTargets())
            Text(`今日步数：${this.todaySteps}`).fontSize(13).fontColor(APP_COLOR_MUTED)
            TextInput({ placeholder: '手动录入今日步数', text: this.todayStepsText }).height(46).fontSize(14)
              .backgroundColor(Color.White).borderRadius(12).border({ width: 1, color: APP_COLOR_LINE })
              .onChange((value: string) => this.todayStepsText = value)
            Button('保存今日步数').width('100%').height(42).fontSize(14).fontWeight(FontWeight.Bold)
              .fontColor(APP_COLOR_GREEN_DARK).backgroundColor(APP_COLOR_GREEN_SOFT).borderRadius(12)
              .enabled(!this.isSaving).onClick(() => {
                const value: number = this.targetValue(this.todayStepsText, this.todaySteps);
                if (value >= 0) this.onSaveSteps(value);
              })
          }
          .width('100%').padding(17).borderRadius(18).backgroundColor(Color.White)
          .border({ width: 1, color: APP_COLOR_LINE })

          Column({ space: 13 }) {
            this.SectionHeader('训练')
            Row() {
              Text('每周训练次数').layoutWeight(1).fontSize(15).fontColor(APP_COLOR_TEXT)
              Row({ space: 8 }) {
                this.ChoiceButton('2 次', this.weeklyFrequency === 2, () => this.onChangeFrequency(2))
                this.ChoiceButton('3 次', this.weeklyFrequency === 3, () => this.onChangeFrequency(3))
              }
            }
            .width('100%')
            this.InfoRow('训练日提醒', '未开启')
            Row() {
              Text('训练地点').layoutWeight(1).fontSize(15).fontColor(APP_COLOR_TEXT)
              Row({ space: 8 }) {
                this.ChoiceButton('健身房', this.trainingLocation === 'gym', () =>
                  this.onChangeTrainingPreference('gym', this.dedicatedLegDay, this.preferMachines))
                this.ChoiceButton('居家', this.trainingLocation === 'home', () =>
                  this.onChangeTrainingPreference('home', this.dedicatedLegDay, this.preferMachines))
              }
            }.width('100%')
            Row() {
              Text('独立腿日').layoutWeight(1).fontSize(15).fontColor(APP_COLOR_TEXT)
              this.ChoiceButton(this.dedicatedLegDay ? '已开启' : '未开启', this.dedicatedLegDay, () =>
                this.onChangeTrainingPreference(this.trainingLocation, !this.dedicatedLegDay, this.preferMachines))
            }.width('100%')
            Row() {
              Text('器械优先').layoutWeight(1).fontSize(15).fontColor(APP_COLOR_TEXT)
              this.ChoiceButton(this.preferMachines ? '已开启' : '未开启', this.preferMachines, () =>
                this.onChangeTrainingPreference(this.trainingLocation, this.dedicatedLegDay, !this.preferMachines))
            }.width('100%')
          }
          .width('100%')
          .padding(17)
          .borderRadius(18)
          .backgroundColor(Color.White)
          .border({ width: 1, color: APP_COLOR_LINE })

          Column({ space: 13 }) {
            this.SectionHeader('记录')
            Row() {
              Text('重量单位').layoutWeight(1).fontSize(15).fontColor(APP_COLOR_TEXT)
              Row({ space: 8 }) {
                this.ChoiceButton('kg', this.weightUnit === 'kg', () => this.onChangeWeightUnit('kg'))
                this.ChoiceButton('lb', this.weightUnit === 'lb', () => this.onChangeWeightUnit('lb'))
              }
            }
            .width('100%')
          }
          .width('100%')
          .padding(17)
          .borderRadius(18)
          .backgroundColor(Color.White)
          .border({ width: 1, color: APP_COLOR_LINE })

          Column({ space: 13 }) {
            this.SectionHeader('存储')
            this.InfoRow('动作媒体', '本地离线')
            this.InfoRow('清理缓存', '无需清理')
          }
          .width('100%')
          .padding(17)
          .borderRadius(18)
          .backgroundColor(Color.White)
          .border({ width: 1, color: APP_COLOR_LINE })

          Column({ space: 13 }) {
            this.SectionHeader('关于')
            this.InfoRow('动作数据来源', 'exercises-dataset')
            this.InfoRow('媒体版权', 'Gym visual · gymvisual.com')
            this.InfoRow('隐私说明', '所有数据仅存本机')
            this.InfoRow('训练免责声明', '量力而行，如有不适请停止')
            this.InfoRow('版本', '1.0.0')
          }
          .width('100%')
          .padding(17)
          .borderRadius(18)
          .backgroundColor(Color.White)
          .border({ width: 1, color: APP_COLOR_LINE })
        }
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 28 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
  }
}
