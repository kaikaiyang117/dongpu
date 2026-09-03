import {
  APP_COLOR_GREEN,
  APP_COLOR_GREEN_DARK,
  APP_COLOR_GREEN_SOFT,
  APP_COLOR_LINE,
  APP_COLOR_MUTED,
  APP_COLOR_SECONDARY_SURFACE,
  APP_COLOR_TEXT,
  APP_COLOR_WARNING,
  APP_COLOR_WARNING_SOFT
} from '../../app/AppTheme';
import { findExercise } from '../../data/ExerciseCatalog';
import { Exercise } from '../../model/Exercise';
import { WorkoutExerciseRecord } from '../../domain/workout/WorkoutModels';
import { ExitWorkoutPage } from './ExitWorkoutPage';

@Component
export struct WorkoutPage {
  @Prop exercise: WorkoutExerciseRecord = new WorkoutExerciseRecord(0, 0, '', '', '', '', '', '', 0, 3, 8, 12, 60);
  @Prop exerciseIndex: number = 0;
  @Prop totalExercises: number = 1;
  @Prop errorText: string = '';
  @Prop isSaving: boolean = false;
  @Prop weightUnit: string = 'kg';
  @Prop allExercises: Exercise[] = [];
  @State weight: number = 0;
  @State reps: number = 10;
  @State hasWeight: boolean = false;
  @State showTips: boolean = false;
  @State showExitSheet: boolean = false;
  @State mediaFailed: boolean = false;
  onReturnHome: () => void = () => {};
  onAbandon: () => void = () => {};
  onOpenAlternatives: () => void = () => {};
  onCompleteSet: (weight: number, reps: number) => void = () => {};

  aboutToAppear(): void {
    if (this.exercise.suggestedWeight > 0) {
      this.weight = this.weightUnit === 'lb' ? this.exercise.suggestedWeight * 2.2046226218 :
        this.exercise.suggestedWeight;
      this.hasWeight = true;
    }
    this.reps = this.exercise.suggestedReps;
  }

  private progress(): number {
    return (this.exerciseIndex + this.exercise.completedSets / this.exercise.targetSets) / this.totalExercises * 100;
  }

  private changeWeight(delta: number): void {
    if (this.exercise.weightIncrementKg <= 0) {
      return;
    }
    if (!this.hasWeight && delta > 0) {
      this.weight = this.weightUnit === 'lb' ? this.exercise.weightIncrementKg * 2.2046226218 :
        this.exercise.weightIncrementKg;
      this.hasWeight = true;
      return;
    }
    const unitDelta: number = this.weightUnit === 'lb' ? delta * 2 : delta;
    this.weight = Math.max(0, this.weight + unitDelta);
    this.hasWeight = this.weight > 0;
  }

  build() {
    Column() {
      Row() {
        Button() {
          Image($r('app.media.icon_close')).width(21).height(21).fillColor(APP_COLOR_TEXT)
        }
          .width(48)
          .height(48)
          .backgroundColor(Color.Transparent)
          .stateEffect(true)
          .accessibilityText('暂时离开训练')
          .onClick(() => this.showExitSheet = true)
        Text('训练中')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(APP_COLOR_TEXT)
        Text(`${this.exerciseIndex + 1} / ${this.totalExercises}`)
          .width(48)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(APP_COLOR_GREEN_DARK)
      }
      .width('100%')
      .height(54)
      Progress({ value: this.progress(), total: 100, type: ProgressType.Linear })
        .width('100%')
        .height(7)
        .color(APP_COLOR_GREEN)
        .backgroundColor(APP_COLOR_LINE)

      Scroll() {
        Column({ space: 14 }) {
          Column({ space: 8 }) {
            Text(this.exercise.exerciseNameSnapshot)
              .width('100%')
              .fontSize(27)
              .fontWeight(FontWeight.Bold)
              .fontColor(APP_COLOR_TEXT)
            Text(`${this.partName()} · ${this.exercise.equipmentNameSnapshot}`)
              .width('100%')
              .fontSize(13)
              .fontColor(APP_COLOR_MUTED)
            if (this.mediaFailed) {
              Column() {
                Text('示范暂时无法加载')
                  .fontSize(14)
                  .fontColor(APP_COLOR_MUTED)
              }
              .width('100%')
              .height(210)
              .justifyContent(FlexAlign.Center)
              .borderRadius(14)
              .backgroundColor(APP_COLOR_SECONDARY_SURFACE)
              .margin({ top: 8 })
            } else {
              Image($rawfile(this.exercise.imagePathSnapshot))
                .width('100%')
                .height(210)
                .objectFit(ImageFit.Contain)
                .margin({ top: 8 })
                .onError(() => this.mediaFailed = true)
            }
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .padding(16)
          .borderRadius(18)
          .backgroundColor(Color.White)
          .border({ width: 1, color: APP_COLOR_LINE })

          Row() {
            Text(`第 ${this.exercise.completedSets + 1} 组 · 共 ${this.exercise.targetSets} 组`)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(APP_COLOR_TEXT)
            Blank()
            Text(`目标 ${this.exercise.repMin}–${this.exercise.repMax} 次`)
              .fontSize(13)
              .fontColor(APP_COLOR_MUTED)
          }
          .width('100%')
          .padding({ left: 14, right: 14 })

          if (this.exercise.completedSets === 0 && this.exercise.suggestedWeight === 0) {
            Column({ space: 4 }) {
              Text('第一次做这个动作')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(APP_COLOR_GREEN_DARK)
              Text(`从轻重量开始，能稳定完成 ${this.exercise.repMin}–${this.exercise.repMax} 次即可。`)
                .fontSize(12)
                .fontColor(APP_COLOR_MUTED)
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
            .padding(14)
            .borderRadius(14)
            .backgroundColor(APP_COLOR_GREEN_SOFT)
          }

          if (this.exercise.suggestedWeight > 0) {
            Text(`上次记录 ${(this.weightUnit === 'lb' ? this.exercise.suggestedWeight * 2.2046226218 :
              this.exercise.suggestedWeight).toFixed(1)} ${this.weightUnit} × ${this.exercise.suggestedReps}`)
              .width('100%')
              .fontSize(13)
              .fontColor(APP_COLOR_MUTED)
              .padding({ left: 14, right: 14 })
          }

          Row({ space: 10 }) {
            Column({ space: 7 }) {
              Text('重量').width('100%').fontSize(13).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_TEXT)
              Row() {
                Button('−')
                  .width(44).height(48).fontSize(20).fontColor(APP_COLOR_GREEN_DARK)
                  .backgroundColor(APP_COLOR_GREEN_SOFT).stateEffect(true).accessibilityText('减少重量')
                  .onClick(() => this.changeWeight(-this.exercise.weightIncrementKg))
                Text(this.hasWeight ? `${this.weight.toFixed(1)} ${this.weightUnit}` : '选择')
                  .layoutWeight(1).textAlign(TextAlign.Center).fontSize(this.hasWeight ? 18 : 15)
                  .fontWeight(FontWeight.Bold).fontColor(this.hasWeight ? APP_COLOR_TEXT : APP_COLOR_GREEN_DARK)
                  .maxLines(1)
                Button('+')
                  .width(44).height(48).fontSize(20).fontColor(APP_COLOR_GREEN_DARK)
                  .backgroundColor(APP_COLOR_GREEN_SOFT).stateEffect(true).accessibilityText('增加重量')
                  .onClick(() => this.changeWeight(this.exercise.weightIncrementKg))
              }.width('100%')
            }
            .layoutWeight(1).padding(12).borderRadius(16).backgroundColor(Color.White)
            .border({ width: 1, color: APP_COLOR_LINE })

            Column({ space: 7 }) {
              Text('次数').width('100%').fontSize(13).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_TEXT)
              Row() {
                Button('−')
                  .width(44).height(48).fontSize(20).fontColor(APP_COLOR_GREEN_DARK)
                  .backgroundColor(APP_COLOR_GREEN_SOFT).stateEffect(true).accessibilityText('减少次数')
                  .onClick(() => this.reps = Math.max(1, this.reps - 1))
                Text(this.reps.toString()).layoutWeight(1).textAlign(TextAlign.Center).fontSize(22)
                  .fontWeight(FontWeight.Bold).fontColor(APP_COLOR_TEXT)
                Button('+')
                  .width(44).height(48).fontSize(20).fontColor(APP_COLOR_GREEN_DARK)
                  .backgroundColor(APP_COLOR_GREEN_SOFT).stateEffect(true).accessibilityText('增加次数')
                  .onClick(() => this.reps += 1)
              }.width('100%')
            }
            .layoutWeight(1).padding(12).borderRadius(16).backgroundColor(Color.White)
            .border({ width: 1, color: APP_COLOR_LINE })
          }.width('100%')

          if (this.errorText !== '') {
            Text(this.errorText)
              .width('100%')
              .fontSize(13)
              .fontColor(APP_COLOR_WARNING)
              .textAlign(TextAlign.Center)
          }

          Row({ space: 10 }) {
            Button('动作要点')
              .layoutWeight(1)
              .height(48)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(APP_COLOR_GREEN_DARK)
              .borderRadius(14)
              .backgroundColor(Color.Transparent)
              .border({ width: 1, color: APP_COLOR_LINE })
              .onClick(() => this.showTips = true)
            Button('器械被占用')
              .layoutWeight(1)
              .height(48)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(APP_COLOR_GREEN_DARK)
              .borderRadius(14)
              .backgroundColor(Color.Transparent)
              .border({ width: 1, color: APP_COLOR_LINE })
              .onClick(() => this.onOpenAlternatives())
          }
          .width('100%')
        }
        .width('100%')
        .padding({ left: 18, right: 18, bottom: 24 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)

      Column() {
        Button(this.isSaving ? '正在保存…' : '完成本组')
          .width('100%')
          .height(58)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .borderRadius(18)
          .backgroundColor(APP_COLOR_GREEN)
          .enabled(!this.isSaving && this.hasWeight)
          .onClick(() => this.onCompleteSet(this.weight, this.reps))
      }
      .width('100%')
      .padding({ left: 18, right: 18, top: 8, bottom: 18 })
    }
    .width('100%')
    .height('100%')
    .bindSheet($$this.showTips, this.TipsContent(), {
      height: SheetSize.LARGE,
      dragBar: true,
      backgroundColor: Color.White,
      onDisappear: () => this.showTips = false
    })
    .bindSheet($$this.showExitSheet, this.ExitSheetContent(), {
      height: '430vp',
      dragBar: true,
      showClose: false,
      backgroundColor: Color.White,
      onDisappear: () => this.showExitSheet = false
    })
  }

  @Builder
  ExitSheetContent() {
    ExitWorkoutPage({
      onReturnHome: () => {
        this.showExitSheet = false;
        this.onReturnHome();
      },
      onContinue: () => this.showExitSheet = false,
      onAbandon: () => {
        this.showExitSheet = false;
        this.onAbandon();
      }
    })
  }

  @Builder
  TipsContent() {
    Column({ space: 18 }) {
      Text(this.tipsExercise().name)
        .width('100%')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(APP_COLOR_TEXT)

      Column({ space: 14 }) {
        Text('怎么做')
          .width('100%')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(APP_COLOR_GREEN_DARK)

        ForEach(this.tipsExercise().stepsZh, (step: string, index: number) => {
          Row({ space: 10 }) {
            Text((index + 1).toString())
              .width(24)
              .height(24)
              .textAlign(TextAlign.Center)
              .fontSize(11)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .borderRadius(12)
              .backgroundColor(APP_COLOR_GREEN)
            Text(step)
              .fontSize(14)
              .fontColor(APP_COLOR_TEXT)
              .lineHeight(20)
              .layoutWeight(1)
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)
        })
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      Column({ space: 8 }) {
        Text('注意什么')
          .width('100%')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(APP_COLOR_WARNING)
        Text(this.tipsExercise().cautionsZh)
          .width('100%')
          .fontSize(13)
          .fontColor(APP_COLOR_TEXT)
          .lineHeight(20)
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding(14)
      .borderRadius(13)
      .backgroundColor(APP_COLOR_WARNING_SOFT)

      Button('知道了')
        .width('100%')
        .height(50)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .borderRadius(16)
        .backgroundColor(APP_COLOR_GREEN)
        .onClick(() => this.showTips = false)
    }
    .padding({ left: 20, right: 20, top: 18, bottom: 28 })
  }

  private tipsExercise(): Exercise {
    const found: Exercise | undefined = this.allExercises.find(
      (e: Exercise) => e.id === this.exercise.actualExerciseId
    );
    if (found !== undefined) {
      return found;
    }
    return new Exercise({
      id: '', name: '', partId: '', equipment: '', target: '',
      steps: [], caution: '', imagePath: '', motionPath: '', recommended: false
    });
  }

  private partName(): string {
    const part: string = this.exercise.partNameSnapshot;
    if (part === 'chest') return '胸部';
    if (part === 'back') return '背部';
    if (part === 'shoulders') return '肩部';
    if (part === 'arms') return '手臂';
    if (part === 'legs') return '腿部';
    if (part === 'core') return '核心';
    return part;
  }
}
