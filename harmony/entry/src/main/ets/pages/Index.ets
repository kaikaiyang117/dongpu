import { BODY_PARTS, findExercise, loadExercises } from '../data/ExerciseCatalog';
import { BodyPart, Exercise } from '../model/Exercise';
import { PlanItem } from '../model/WorkoutData';

const COLOR_BG: string = '#FBFAF5';
const COLOR_CARD: string = '#F4F5EF';
const COLOR_TEXT: string = '#11120F';
const COLOR_MUTED: string = '#777970';
const COLOR_GREEN: string = '#65BF2F';
const COLOR_GREEN_DARK: string = '#3F8D19';
const COLOR_GREEN_SOFT: string = '#EDF8E7';
const COLOR_LINE: string = '#E5E6DC';

@Entry
@Component
struct Index {
  @State exercises: Exercise[] = [];
  @State currentStep: number = 1;
  @State selectedParts: string[] = ['chest'];
  @State selectedExerciseIds: string[] = [];
  @State planItems: PlanItem[] = [];
  @State isExerciseLibraryOpen: boolean = false;
  @State libraryPartId: string = 'chest';
  @State libraryEquipment: string = '全部';
  @State detailExerciseId: string = '';
  @State detailVideoPlaying: boolean = true;
  @State detailSlowMode: boolean = false;
  @State detailVideoTime: number = 0;
  @State detailVideoDuration: number = 3;
  private detailVideoController: VideoController = new VideoController();

  aboutToAppear(): void {
    const hostContext = this.getUIContext().getHostContext();
    if (hostContext !== undefined) {
      this.exercises = loadExercises(hostContext.resourceManager);
    }
  }

  private exercise(id: string): Exercise {
    return findExercise(this.exercises, id);
  }

  private title(): string {
    if (this.detailExerciseId !== '') {
      return this.exercise(this.detailExerciseId).name;
    }
    if (this.isExerciseLibraryOpen) {
      return '动作';
    }
    if (this.currentStep === 2) {
      return '选择动作';
    }
    if (this.currentStep === 3) {
      return '确认计划';
    }
    if (this.currentStep === 4) {
      return '今日训练';
    }
    return '自定义训练';
  }

  private footerText(): string {
    if (this.currentStep === 1) {
      return '下一步 · 选择动作';
    }
    if (this.currentStep === 2) {
      return `下一步 · 确认计划（${this.selectedExerciseIds.length}）`;
    }
    return '开始训练';
  }

  private isPartSelected(id: string): boolean {
    return this.selectedParts.includes(id);
  }

  private isExerciseSelected(id: string): boolean {
    return this.selectedExerciseIds.includes(id);
  }

  private visibleExercises(): Exercise[] {
    return this.exercises.filter((exercise: Exercise) => this.selectedParts.includes(exercise.partId));
  }

  private libraryExercises(): Exercise[] {
    return this.exercises.filter((exercise: Exercise) => {
      return exercise.partId === this.libraryPartId &&
        (this.libraryEquipment === '全部' || exercise.equipment === this.libraryEquipment);
    });
  }

  private libraryEquipmentOptions(): string[] {
    const options: string[] = ['全部'];
    this.exercises.forEach((exercise: Exercise) => {
      if (exercise.partId === this.libraryPartId && !options.includes(exercise.equipment)) {
        options.push(exercise.equipment);
      }
    });
    return options;
  }

  private selectLibraryPart(id: string): void {
    this.libraryPartId = id;
    this.libraryEquipment = '全部';
  }

  private openExerciseDetail(id: string): void {
    this.detailExerciseId = id;
    this.detailVideoPlaying = true;
    this.detailSlowMode = false;
    this.detailVideoTime = 0;
  }

  private closeExerciseDetail(): void {
    this.detailVideoController.pause();
    this.detailExerciseId = '';
  }

  private toggleDetailVideo(): void {
    if (this.detailVideoPlaying) {
      this.detailVideoController.pause();
      return;
    }
    this.detailVideoController.start();
  }

  private replayDetailVideo(): void {
    this.detailVideoController.setCurrentTime(0);
    this.detailVideoController.start();
  }

  private videoTimeLabel(value: number): string {
    const seconds: number = Math.max(0, Math.floor(value));
    return `00:${seconds.toString().padStart(2, '0')}`;
  }

  private addDetailExerciseToPlan(): void {
    if (this.detailExerciseId === '' || this.isExerciseSelected(this.detailExerciseId)) {
      return;
    }
    this.selectedExerciseIds = [...this.selectedExerciseIds, this.detailExerciseId];
    this.planItems = [...this.planItems, new PlanItem(this.detailExerciseId)];
  }

  private partName(id: string): string {
    const part: BodyPart | undefined = BODY_PARTS.find((item: BodyPart) => item.id === id);
    return part?.name ?? '';
  }

  private partIcon(id: string): Resource {
    if (id === 'back') {
      return $r('app.media.body_back');
    }
    if (id === 'shoulders' || id === 'neck') {
      return $r('app.media.body_shoulders');
    }
    if (id === 'upper arms' || id === 'lower arms') {
      return $r('app.media.body_arms');
    }
    if (id === 'upper legs' || id === 'lower legs' || id === 'cardio') {
      return $r('app.media.body_legs');
    }
    if (id === 'waist') {
      return $r('app.media.body_core');
    }
    return $r('app.media.body_chest');
  }

  private exerciseMotion(exercise: Exercise): Resource {
    return $rawfile(exercise.motionPath);
  }

  private exercisePoster(exercise: Exercise): Resource {
    return $rawfile(exercise.imagePath);
  }

  private togglePart(id: string): void {
    if (this.selectedParts.includes(id)) {
      this.selectedParts = this.selectedParts.filter((partId: string) => partId !== id);
      this.selectedExerciseIds = this.selectedExerciseIds.filter((exerciseId: string) => {
        return this.exercise(exerciseId).partId !== id;
      });
      return;
    }

    if (this.selectedParts.length >= 2) {
      const removedPart: string = this.selectedParts[0];
      this.selectedParts = [this.selectedParts[1], id];
      this.selectedExerciseIds = this.selectedExerciseIds.filter((exerciseId: string) => {
        return this.exercise(exerciseId).partId !== removedPart;
      });
      return;
    }

    this.selectedParts = [...this.selectedParts, id];
  }

  private toggleExercise(id: string): void {
    if (this.selectedExerciseIds.includes(id)) {
      this.selectedExerciseIds = this.selectedExerciseIds.filter((exerciseId: string) => exerciseId !== id);
      return;
    }
    this.selectedExerciseIds = [...this.selectedExerciseIds, id];
  }

  private goBack(): void {
    if (this.currentStep > 1) {
      this.currentStep -= 1;
    }
  }

  private goNext(): void {
    if (this.currentStep === 1 && this.selectedParts.length > 0) {
      this.currentStep = 2;
      return;
    }
    if (this.currentStep === 2 && this.selectedExerciseIds.length > 0) {
      this.planItems = this.selectedExerciseIds.map((id: string) => new PlanItem(id));
      this.currentStep = 3;
      return;
    }
    if (this.currentStep === 3 && this.planItems.length > 0) {
      this.currentStep = 4;
    }
  }

  private canContinue(): boolean {
    if (this.currentStep === 1) {
      return this.selectedParts.length > 0;
    }
    if (this.currentStep === 2) {
      return this.selectedExerciseIds.length > 0;
    }
    return this.planItems.length > 0;
  }

  private updatePlan(id: string, field: string, delta: number): void {
    this.planItems = this.planItems.map((item: PlanItem) => {
      if (item.exerciseId !== id) {
        return item;
      }
      const sets: number = field === 'sets' ? Math.max(1, Math.min(6, item.sets + delta)) : item.sets;
      const reps: number = field === 'reps' ? Math.max(6, Math.min(20, item.reps + delta)) : item.reps;
      return new PlanItem(id, sets, reps);
    });
  }

  private removePlanItem(id: string): void {
    this.planItems = this.planItems.filter((item: PlanItem) => item.exerciseId !== id);
    this.selectedExerciseIds = this.selectedExerciseIds.filter((exerciseId: string) => exerciseId !== id);
  }

  private totalSets(): number {
    return this.planItems.reduce((total: number, item: PlanItem) => total + item.sets, 0);
  }

  @Builder
  Header() {
    Row() {
      if (this.detailExerciseId !== '') {
        Button() {
          Text('‹')
            .fontSize(34)
            .fontColor(COLOR_TEXT)
            .fontWeight(FontWeight.Medium)
        }
        .width(48)
        .height(48)
        .backgroundColor(Color.Transparent)
        .onClick(() => this.closeExerciseDetail())
      } else if (this.isExerciseLibraryOpen) {
        Button() {
          Text('‹')
            .fontSize(34)
            .fontColor(COLOR_TEXT)
            .fontWeight(FontWeight.Medium)
        }
        .width(48)
        .height(48)
        .backgroundColor(Color.Transparent)
        .onClick(() => this.isExerciseLibraryOpen = false)
      } else if (this.currentStep > 1) {
        Button() {
          Text(this.currentStep === 4 ? '×' : '‹')
            .fontSize(this.currentStep === 4 ? 25 : 34)
            .fontColor(COLOR_TEXT)
            .fontWeight(FontWeight.Medium)
        }
        .width(48)
        .height(48)
        .backgroundColor(Color.Transparent)
        .onClick(() => this.goBack())
      } else {
        Blank().width(56)
      }

      Text(this.title())
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .fontSize(this.detailExerciseId !== '' ? 20 : 17)
        .fontWeight(FontWeight.Bold)
        .fontColor(COLOR_TEXT)

      if (!this.isExerciseLibraryOpen && this.currentStep === 1) {
        Button() {
          Text('动作')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor(COLOR_GREEN_DARK)
        }
          .width(56)
          .height(48)
          .backgroundColor(Color.Transparent)
          .onClick(() => this.isExerciseLibraryOpen = true)
      } else {
        Blank().width(48)
      }
    }
    .width('100%')
    .height(54)
    .padding({ left: 8, right: 8 })
  }

  @Builder
  StepProgress() {
    Row() {
      ForEach([1, 2, 3], (step: number) => {
        Stack() {
          Text(step < this.currentStep ? '✓' : step.toString())
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(step <= this.currentStep ? Color.White : '#979990')
        }
        .width(29)
        .height(29)
        .borderRadius(15)
        .backgroundColor(step <= this.currentStep ? COLOR_GREEN : '#F1F1EB')
        .border({ width: 1, color: step <= this.currentStep ? COLOR_GREEN : '#D8D9D0' })

        if (step < 3) {
          Divider()
            .width(45)
            .strokeWidth(1)
            .color(step < this.currentStep ? COLOR_GREEN : '#D8D9D0')
        }
      })
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height(54)
  }

  @Builder
  Hero(eyebrow: string, title: string, subtitle: string) {
    Column({ space: 6 }) {
      Text(eyebrow)
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor(COLOR_GREEN_DARK)
        .letterSpacing(0.5)
      Text(title)
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .fontColor(COLOR_TEXT)
      Text(subtitle)
        .fontSize(14)
        .fontColor(COLOR_MUTED)
        .lineHeight(21)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  @Builder
  BodyPartCard(part: BodyPart) {
    Stack({ alignContent: Alignment.TopEnd }) {
      Column({ space: 2 }) {
        Image(this.partIcon(part.id))
          .width(98)
          .height(102)
          .objectFit(ImageFit.Contain)
        Text(part.name)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLOR_TEXT)
      }
      .justifyContent(FlexAlign.Center)
      .width('100%')
      .height('100%')

      if (this.isPartSelected(part.id)) {
        Stack() {
          Text('✓')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
        }
        .width(23)
        .height(23)
        .borderRadius(12)
        .backgroundColor(COLOR_GREEN)
        .margin({ top: 10, right: 10 })
      }
    }
    .width('100%')
    .height(148)
    .borderRadius(19)
    .backgroundColor(this.isPartSelected(part.id) ? COLOR_GREEN_SOFT : COLOR_CARD)
    .border({ width: this.isPartSelected(part.id) ? 1.5 : 0, color: COLOR_GREEN })
    .onClick(() => this.togglePart(part.id))
  }

  @Builder
  BodyStep() {
    Scroll() {
      Column({ space: 24 }) {
        this.Hero('第 1 步 · 训练部位', '今天想练哪里？', '建议选择 1—2 个部位，动作会更专注')
        Grid() {
          ForEach(BODY_PARTS, (part: BodyPart) => {
            GridItem() {
              this.BodyPartCard(part)
            }
          }, (part: BodyPart) => part.id)
        }
        .columnsTemplate('1fr 1fr')
        .columnsGap(12)
        .rowsGap(12)
      }
      .width('100%')
      .padding({ left: 20, right: 20, bottom: 24 })
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }

  @Builder
  LibraryPartButton(part: BodyPart) {
    Button() {
      Column({ space: 5 }) {
        Image(this.partIcon(part.id))
          .width(34)
          .height(36)
          .objectFit(ImageFit.Contain)
        Text(part.name)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.libraryPartId === part.id ? Color.White : COLOR_TEXT)
      }
    }
      .width('100%')
      .height(76)
      .borderRadius(16)
      .backgroundColor(this.libraryPartId === part.id ? COLOR_GREEN : '#F0F1EB')
      .onClick(() => this.selectLibraryPart(part.id))
  }

  @Builder
  LibraryEquipmentButton(equipment: string) {
    Button(equipment)
      .height(36)
      .fontSize(11)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.libraryEquipment === equipment ? Color.White : COLOR_TEXT)
      .borderRadius(12)
      .backgroundColor(this.libraryEquipment === equipment ? COLOR_GREEN_DARK : '#F0F1EB')
      .padding({ left: 12, right: 12 })
      .onClick(() => this.libraryEquipment = equipment)
  }

  @Builder
  LibraryExerciseCard(exercise: Exercise) {
    Row({ space: 14 }) {
      Image(this.exercisePoster(exercise))
        .width(104)
        .height(104)
        .borderRadius(14)
        .objectFit(ImageFit.Cover)

      Column({ space: 7 }) {
        Row({ space: 7 }) {
          Text(exercise.name)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(COLOR_TEXT)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          if (exercise.recommended) {
            Text('推荐')
              .fontSize(9)
              .fontWeight(FontWeight.Bold)
              .fontColor(COLOR_GREEN_DARK)
              .padding({ left: 6, right: 6, top: 3, bottom: 3 })
              .borderRadius(6)
              .backgroundColor(COLOR_GREEN_SOFT)
          }
        }
        .width('100%')

        Text(`${this.partName(exercise.partId)} · ${exercise.equipment}`)
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .fontColor(COLOR_GREEN_DARK)

        Text(exercise.tip)
          .fontSize(12)
          .fontColor(COLOR_MUTED)
          .lineHeight(18)
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding(12)
    .borderRadius(16)
    .backgroundColor(Color.White)
    .border({ width: 1, color: COLOR_LINE })
    .onClick(() => this.openExerciseDetail(exercise.id))
  }

  @Builder
  DetailMeta(label: string, value: string) {
    Row({ space: 7 }) {
      Text(label)
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor(COLOR_MUTED)
      Text(value)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(COLOR_GREEN_DARK)
    }
    .layoutWeight(1)
  }

  @Builder
  DetailPhaseHeader(index: string, title: string) {
    Row({ space: 10 }) {
      Text(index)
        .width(28)
        .height(28)
        .textAlign(TextAlign.Center)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .borderRadius(14)
        .backgroundColor(COLOR_GREEN)
      Text(title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(COLOR_GREEN_DARK)
    }
    .width('100%')
  }

  @Builder
  DetailSetupItem(title: string, description: string) {
    Column({ space: 4 }) {
      Text(title)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(COLOR_TEXT)
      Text(description)
        .fontSize(13)
        .fontColor(COLOR_MUTED)
        .lineHeight(20)
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ left: 38 })
  }

  @Builder
  DetailMetric(value: string, label: string) {
    Column({ space: 3 }) {
      Text(value)
        .fontSize(19)
        .fontWeight(FontWeight.Bold)
        .fontColor(COLOR_TEXT)
      Text(label)
        .fontSize(10)
        .fontColor(COLOR_MUTED)
    }
    .layoutWeight(1)
  }

  @Builder
  DetailVideo(exercise: Exercise) {
    Column({ space: 8 }) {
      Stack({ alignContent: Alignment.Center }) {
        Video({
          src: this.exerciseMotion(exercise),
          previewUri: this.exercisePoster(exercise),
          currentProgressRate: this.detailSlowMode ? PlaybackSpeed.Speed_Forward_0_75_X :
            PlaybackSpeed.Speed_Forward_1_00_X,
          controller: this.detailVideoController
        })
          .width('100%')
          .height(245)
          .controls(false)
          .autoPlay(true)
          .loop(true)
          .muted(true)
          .objectFit(ImageFit.Fill)
          .onStart(() => this.detailVideoPlaying = true)
          .onPause(() => this.detailVideoPlaying = false)
          .onPrepared((event: PreparedInfo) => this.detailVideoDuration = event.duration)
          .onUpdate((event: PlaybackInfo) => this.detailVideoTime = event.time)

        if (!this.detailVideoPlaying) {
          Button('播放')
            .width(68)
            .height(44)
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor(COLOR_TEXT)
            .borderRadius(22)
            .backgroundColor('#EFFFFFFF')
            .onClick(() => this.toggleDetailVideo())
        }
      }
      .width('100%')
      .height(245)
      .borderRadius(17)
      .backgroundColor(Color.White)

      Progress({ value: this.detailVideoTime, total: this.detailVideoDuration, type: ProgressType.Linear })
        .width('100%')
        .height(4)
        .color(COLOR_GREEN)
        .backgroundColor('#DEE0D8')

      Row({ space: 7 }) {
        Button(this.detailSlowMode ? '0.75x 慢动作' : '1x 正常')
          .height(36)
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.detailSlowMode ? COLOR_GREEN_DARK : COLOR_MUTED)
          .borderRadius(12)
          .backgroundColor(this.detailSlowMode ? COLOR_GREEN_SOFT : '#F1F2ED')
          .onClick(() => this.detailSlowMode = !this.detailSlowMode)

        Blank()

        Button(this.detailVideoPlaying ? '暂停' : '播放')
          .height(36)
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLOR_TEXT)
          .borderRadius(12)
          .backgroundColor('#F1F2ED')
          .onClick(() => this.toggleDetailVideo())

        Button('重播')
          .height(36)
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLOR_TEXT)
          .borderRadius(12)
          .backgroundColor('#F1F2ED')
          .onClick(() => this.replayDetailVideo())

        Text(`${this.videoTimeLabel(this.detailVideoTime)} / ${this.videoTimeLabel(this.detailVideoDuration)}`)
          .fontSize(10)
          .fontColor(COLOR_MUTED)
      }
      .width('100%')
    }
    .width('100%')
    .padding(12)
    .borderRadius(19)
    .backgroundColor(Color.White)
    .border({ width: 1, color: COLOR_LINE })
  }

  @Builder
  ExerciseDetail(exercise: Exercise) {
    Scroll() {
      Column({ space: 14 }) {
        Row() {
          this.DetailMeta('锻炼部位', exercise.target)
          Divider()
            .vertical(true)
            .height(22)
            .strokeWidth(1)
            .color(COLOR_LINE)
          this.DetailMeta('使用器械', exercise.equipment)
        }
        .width('100%')
        .height(44)
        .padding({ left: 10, right: 10 })

        this.DetailVideo(exercise)

        Column({ space: 14 }) {
          this.DetailPhaseHeader('1', '先调器械')
          this.DetailSetupItem('器械位置', exercise.steps[0])
          this.DetailSetupItem('起始姿势', exercise.steps[1])

          Divider()
            .strokeWidth(1)
            .color(COLOR_LINE)

          this.DetailPhaseHeader('2', '再做动作')
          ForEach(exercise.steps, (step: string, index: number) => {
            Row({ space: 10 }) {
              Text((index + 1).toString())
                .width(24)
                .height(24)
                .textAlign(TextAlign.Center)
                .fontSize(11)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
                .borderRadius(12)
                .backgroundColor(COLOR_GREEN)

              Text(step)
                .fontSize(13)
                .fontColor(COLOR_TEXT)
                .lineHeight(20)
                .layoutWeight(1)
            }
            .width('100%')
            .alignItems(VerticalAlign.Top)
          })

          Column({ space: 7 }) {
            Text('避免错误')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#D96D00')
            Text(exercise.caution)
              .fontSize(13)
              .fontColor(COLOR_TEXT)
              .lineHeight(20)
              .width('100%')
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .padding(14)
          .borderRadius(13)
          .backgroundColor('#FFF4E5')
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(16)
        .borderRadius(18)
        .backgroundColor(Color.White)
        .border({ width: 1, color: COLOR_LINE })

        Row() {
          this.DetailMetric('3组', '建议组数')
          Divider().vertical(true).height(34).color(COLOR_LINE)
          this.DetailMetric('10次', '每组次数')
          Divider().vertical(true).height(34).color(COLOR_LINE)
          this.DetailMetric('60秒', '组间休息')
        }
        .width('100%')
        .height(70)
        .padding({ left: 10, right: 10 })
        .borderRadius(16)
        .backgroundColor(Color.White)
        .border({ width: 1, color: COLOR_LINE })

        Text('动作数据来自 exercises-dataset；示范媒体 © Gym visual · gymvisual.com')
          .width('100%')
          .fontSize(10)
          .fontColor('#8A8C84')
          .lineHeight(15)
          .textAlign(TextAlign.Center)
          .padding({ top: 2, bottom: 14 })
      }
      .width('100%')
      .padding({ left: 18, right: 18 })
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }

  @Builder
  DetailFooter(exercise: Exercise) {
    Column() {
      Button(this.isExerciseSelected(exercise.id) ? '已加入今日训练' : '加入今日训练')
        .width('100%')
        .height(56)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .borderRadius(17)
        .backgroundColor(this.isExerciseSelected(exercise.id) ? COLOR_GREEN_DARK : COLOR_GREEN)
        .enabled(!this.isExerciseSelected(exercise.id))
        .onClick(() => this.addDetailExerciseToPlan())
    }
    .width('100%')
    .height(78)
    .padding({ left: 18, right: 18, top: 7, bottom: 15 })
    .backgroundColor(COLOR_BG)
  }

  @Builder
  ExerciseLibrary() {
    Row({ space: 14 }) {
      Scroll() {
        Column({ space: 8 }) {
          Text('部位')
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor(COLOR_MUTED)
            .margin({ bottom: 4 })
          ForEach(BODY_PARTS, (part: BodyPart) => {
            this.LibraryPartButton(part)
          }, (part: BodyPart) => part.id)
        }
        .width('100%')
        .padding({ bottom: 18 })
      }
      .width(82)
      .scrollBar(BarState.Off)

      Column({ space: 14 }) {
        Column({ space: 7 }) {
          Text('先看动作，再开练')
            .fontSize(25)
            .fontWeight(FontWeight.Bold)
            .fontColor(COLOR_TEXT)
          Text('先选部位，再按器械找动作')
            .fontSize(13)
            .fontColor(COLOR_MUTED)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')

        Scroll() {
          Row({ space: 7 }) {
            ForEach(this.libraryEquipmentOptions(), (equipment: string) => {
              this.LibraryEquipmentButton(equipment)
            }, (equipment: string) => equipment)
          }
          .height(36)
        }
        .width('100%')
        .height(36)
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)

        Text(`${this.partName(this.libraryPartId)} · ${this.libraryExercises().length} 个动作 · 共 ${this.exercises.length} 个`)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLOR_GREEN_DARK)
          .width('100%')

        List({ space: 10 }) {
          ForEach(this.libraryExercises(), (exercise: Exercise) => {
            ListItem() {
              this.LibraryExerciseCard(exercise)
            }
          }, (exercise: Exercise) => exercise.id)
        }
        .width('100%')
        .padding({ bottom: 12 })
        .layoutWeight(1)
        .scrollBar(BarState.Off)

        Text('数据来自 exercises-dataset；示范图 © Gym visual · gymvisual.com')
          .width('100%')
          .fontSize(9)
          .fontColor('#8A8C84')
          .lineHeight(14)
          .textAlign(TextAlign.Center)
          .padding({ top: 2, bottom: 10 })
      }
      .layoutWeight(1)
      .height('100%')
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ left: 12, right: 12, bottom: 4 })
  }

  @Builder
  ExerciseRow(exercise: Exercise) {
    Row({ space: 12 }) {
      Stack() {
        Image(this.partIcon(exercise.partId))
          .width(50)
          .height(54)
          .objectFit(ImageFit.Contain)
      }
      .width(54)
      .height(58)
      .borderRadius(12)
      .backgroundColor(COLOR_CARD)

      Column({ space: 5 }) {
        Row({ space: 7 }) {
          Text(exercise.name)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(COLOR_TEXT)
          if (exercise.recommended) {
            Text('推荐')
              .fontSize(9)
              .fontWeight(FontWeight.Bold)
              .fontColor(COLOR_GREEN_DARK)
              .padding({ left: 6, right: 6, top: 3, bottom: 3 })
              .borderRadius(6)
              .backgroundColor('#E6F5DC')
          }
        }
        Text(`${exercise.equipment} · ${exercise.tip}`)
          .fontSize(11)
          .fontColor(COLOR_MUTED)
          .lineHeight(15)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Stack() {
        Text(this.isExerciseSelected(exercise.id) ? '✓' : '+')
          .fontSize(16)
          .fontColor(this.isExerciseSelected(exercise.id) ? Color.White : '#8D9188')
      }
      .width(27)
      .height(27)
      .borderRadius(14)
      .backgroundColor(this.isExerciseSelected(exercise.id) ? COLOR_GREEN : Color.Transparent)
      .border({ width: 1, color: this.isExerciseSelected(exercise.id) ? COLOR_GREEN : '#D6D8CF' })
    }
    .width('100%')
    .height(83)
    .padding(12)
    .borderRadius(16)
    .backgroundColor(this.isExerciseSelected(exercise.id) ? COLOR_GREEN_SOFT : Color.White)
    .border({ width: 1.5, color: this.isExerciseSelected(exercise.id) ? COLOR_GREEN : COLOR_LINE })
    .onClick(() => this.toggleExercise(exercise.id))
  }

  @Builder
  ExerciseStep() {
    List({ space: 16 }) {
      ListItem() {
        this.Hero('第 2 步 · 选择动作', '选择今天的动作', '新手建议每个部位选择 2—3 个动作')
      }

      ListItem() {
        Row({ space: 8 }) {
          ForEach(this.selectedParts, (id: string) => {
            Text(this.partName(id))
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor(COLOR_GREEN_DARK)
              .padding({ left: 13, right: 13, top: 8, bottom: 8 })
              .borderRadius(18)
              .backgroundColor(COLOR_GREEN_SOFT)
              .border({ width: 1, color: '#CCE9BA' })
          })
        }
        .width('100%')
      }

      ForEach(this.visibleExercises(), (exercise: Exercise) => {
        ListItem() {
            this.ExerciseRow(exercise)
        }
      }, (exercise: Exercise) => exercise.id)
    }
    .width('100%')
    .padding({ left: 20, right: 20, bottom: 24 })
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }

  @Builder
  NumberControl(item: PlanItem, field: string) {
    Row() {
      Text('−')
        .width(30)
        .height(34)
        .textAlign(TextAlign.Center)
        .fontSize(18)
        .fontColor(COLOR_TEXT)
        .onClick(() => this.updatePlan(item.exerciseId, field, -1))
      Text((field === 'sets' ? item.sets : item.reps).toString())
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(COLOR_TEXT)
      Text('+')
        .width(30)
        .height(34)
        .textAlign(TextAlign.Center)
        .fontSize(17)
        .fontColor(COLOR_TEXT)
        .onClick(() => this.updatePlan(item.exerciseId, field, 1))
    }
    .width('100%')
    .height(34)
    .borderRadius(10)
    .backgroundColor('#F3F4EE')
  }

  @Builder
  PlanRow(item: PlanItem, index: number) {
    Row({ space: 9 }) {
      Text('⋮⋮')
        .fontSize(14)
        .fontColor('#BABCB4')
      Text((index + 1).toString().padStart(2, '0'))
        .width(28)
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor(COLOR_GREEN_DARK)

      Column({ space: 4 }) {
        Row() {
          Text(this.exercise(item.exerciseId).name)
            .layoutWeight(1)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(COLOR_TEXT)
          Text('×')
            .width(28)
            .height(28)
            .textAlign(TextAlign.Center)
            .fontSize(18)
            .fontColor('#A8AAA3')
            .onClick(() => this.removePlanItem(item.exerciseId))
        }
        Text(this.exercise(item.exerciseId).equipment)
          .fontSize(11)
          .fontColor(COLOR_MUTED)
        Row({ space: 10 }) {
          Column({ space: 5 }) {
            Text('组数').fontSize(10).fontWeight(FontWeight.Bold).fontColor(COLOR_MUTED)
            this.NumberControl(item, 'sets')
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          Column({ space: 5 }) {
            Text('次数').fontSize(10).fontWeight(FontWeight.Bold).fontColor(COLOR_MUTED)
            this.NumberControl(item, 'reps')
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .margin({ top: 8 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding(14)
    .borderRadius(17)
    .backgroundColor(Color.White)
    .border({ width: 1, color: COLOR_LINE })
  }

  @Builder
  ConfirmStep() {
    Scroll() {
      Column({ space: 16 }) {
        this.Hero('第 3 步 · 确认计划', '今天就按这个练',
          `${this.planItems.length} 个动作 · ${this.totalSets()} 组 · 约 ${Math.max(20, this.planItems.length * 7)} 分钟`)
        Column({ space: 10 }) {
          ForEach(this.planItems, (item: PlanItem, index: number) => {
            this.PlanRow(item, index)
          }, (item: PlanItem) => item.exerciseId)
        }
        .width('100%')

        Button() {
          Row({ space: 7 }) {
            Text('+').fontSize(18)
            Text('添加或修改动作').fontSize(13).fontWeight(FontWeight.Bold)
          }
        }
        .width('100%')
        .height(48)
        .fontColor(COLOR_TEXT)
        .borderRadius(14)
        .backgroundColor(Color.Transparent)
        .border({ width: 1, color: COLOR_LINE })
        .onClick(() => this.currentStep = 2)
      }
      .width('100%')
      .padding({ left: 20, right: 20, bottom: 24 })
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }

  @Builder
  SuccessStep() {
    Scroll() {
      Column({ space: 18 }) {
        Stack() {
          Text('✓')
            .fontSize(34)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
        }
        .width(72)
        .height(72)
        .borderRadius(36)
        .backgroundColor(COLOR_GREEN)
        .margin({ top: 40 })

        Text('计划已准备好')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLOR_GREEN_DARK)
        Text('开始今天的训练')
          .fontSize(31)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLOR_TEXT)
        Text('先从轻重量热身，感觉动作稳定后再慢慢加重。')
          .fontSize(14)
          .fontColor(COLOR_MUTED)
          .lineHeight(21)
          .textAlign(TextAlign.Center)

        Row() {
          this.SummaryMetric(this.planItems.length.toString(), '个动作')
          this.SummaryMetric(this.totalSets().toString(), '组')
          this.SummaryMetric(Math.max(20, this.planItems.length * 7).toString(), '分钟')
        }
        .width('100%')
        .padding({ top: 18, bottom: 18 })
        .margin({ top: 8 })
        .border({ width: { top: 1, bottom: 1 }, color: COLOR_LINE })

        Column() {
          ForEach(this.planItems, (item: PlanItem, index: number) => {
            Row({ space: 12 }) {
              Text((index + 1).toString())
                .width(18)
                .fontSize(11)
                .fontColor(COLOR_GREEN_DARK)
              Text(this.exercise(item.exerciseId).name)
                .layoutWeight(1)
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(COLOR_TEXT)
            }
            .width('100%')
            .height(48)
            .border({ width: { bottom: 1 }, color: COLOR_LINE })
          }, (item: PlanItem) => item.exerciseId)
        }
        .width('100%')

        Button('返回调整计划')
          .width('100%')
          .height(48)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLOR_TEXT)
          .borderRadius(14)
          .backgroundColor(Color.Transparent)
          .border({ width: 1, color: COLOR_LINE })
          .onClick(() => this.currentStep = 3)
      }
      .width('100%')
      .padding({ left: 24, right: 24, bottom: 32 })
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }

  @Builder
  SummaryMetric(value: string, label: string) {
    Column({ space: 4 }) {
      Text(value)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(COLOR_TEXT)
      Text(label)
        .fontSize(11)
        .fontColor(COLOR_MUTED)
    }
    .layoutWeight(1)
  }

  @Builder
  Footer() {
    Column() {
      Button(this.footerText())
        .width('100%')
        .height(58)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.canContinue() ? Color.White : '#9B9E96')
        .borderRadius(18)
        .backgroundColor(this.canContinue() ? COLOR_GREEN : '#D9DDD4')
        .enabled(this.canContinue())
        .onClick(() => this.goNext())
    }
    .width('100%')
    .height(86)
    .padding({ left: 20, right: 20, top: 10, bottom: 18 })
    .backgroundColor(COLOR_BG)
  }

  build() {
    Column() {
      this.Header()
      if (!this.isExerciseLibraryOpen && this.currentStep <= 3) {
        this.StepProgress()
      }

      if (this.detailExerciseId !== '') {
        this.ExerciseDetail(this.exercise(this.detailExerciseId))
        this.DetailFooter(this.exercise(this.detailExerciseId))
      } else if (this.isExerciseLibraryOpen) {
        this.ExerciseLibrary()
      } else if (this.currentStep === 1) {
        this.BodyStep()
      } else if (this.currentStep === 2) {
        this.ExerciseStep()
      } else if (this.currentStep === 3) {
        this.ConfirmStep()
      } else {
        this.SuccessStep()
      }

      if (!this.isExerciseLibraryOpen && this.currentStep <= 3) {
        this.Footer()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLOR_BG)
  }
}
