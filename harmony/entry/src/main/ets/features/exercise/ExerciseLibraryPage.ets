import {
  APP_COLOR_GREEN,
  APP_COLOR_GREEN_DARK,
  APP_COLOR_GREEN_SOFT,
  APP_COLOR_LINE,
  APP_COLOR_MUTED,
  APP_COLOR_SECONDARY_SURFACE,
  APP_COLOR_TEXT,
  APP_COLOR_TEXT_TERTIARY
} from '../../app/AppTheme';
import { BODY_PARTS, exerciseMatchesPart, getLibraryExercises, userPartId } from '../../data/ExerciseCatalog';
import { BodyPart, Exercise } from '../../model/Exercise';

@Component
export struct ExerciseLibraryPage {
  @Prop exercises: Exercise[] = [];
  @Prop selectedPartId: string = 'chest';
  @Prop selectedEquipment: string = '全部';
  onSelectPart: (id: string) => void = () => {};
  onSelectEquipment: (equipment: string) => void = () => {};
  onOpenExercise: (id: string) => void = () => {};

  private partName(id: string): string {
    const part: BodyPart | undefined = BODY_PARTS.find((item: BodyPart) => item.id === id);
    return part?.name ?? '';
  }

  private partIcon(id: string): Resource {
    if (id === 'back') {
      return $r('app.media.body_back');
    }
    if (id === 'shoulders') {
      return $r('app.media.body_shoulders');
    }
    if (id === 'arms') {
      return $r('app.media.body_arms');
    }
    if (id === 'legs') {
      return $r('app.media.body_legs');
    }
    if (id === 'core') {
      return $r('app.media.body_core');
    }
    return $r('app.media.body_chest');
  }

  private visibleExercises(): Exercise[] {
    return getLibraryExercises(this.exercises).filter((exercise: Exercise) => {
      return exerciseMatchesPart(exercise, this.selectedPartId) &&
        (this.selectedEquipment === '全部' || exercise.equipment === this.selectedEquipment);
    });
  }

  private equipmentOptions(): string[] {
    const options: string[] = ['全部'];
    getLibraryExercises(this.exercises).forEach((exercise: Exercise) => {
      if (exerciseMatchesPart(exercise, this.selectedPartId) && !options.includes(exercise.equipment)) {
        options.push(exercise.equipment);
      }
    });
    return options;
  }

  private exercisePoster(exercise: Exercise): Resource {
    return $rawfile(exercise.imagePath);
  }

  @Builder
  PartButton(part: BodyPart) {
    Button() {
      Column({ space: 5 }) {
        Image(this.partIcon(part.id))
          .width(34)
          .height(36)
          .objectFit(ImageFit.Contain)
        Text(part.name)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.selectedPartId === part.id ? Color.White : APP_COLOR_TEXT)
      }
    }
    .width('100%')
    .height(76)
    .borderRadius(16)
    .backgroundColor(this.selectedPartId === part.id ? APP_COLOR_GREEN : APP_COLOR_SECONDARY_SURFACE)
    .onClick(() => this.onSelectPart(part.id))
  }

  @Builder
  EquipmentButton(equipment: string) {
    Button(equipment)
      .height(36)
      .fontSize(11)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.selectedEquipment === equipment ? Color.White : APP_COLOR_TEXT)
      .borderRadius(12)
      .backgroundColor(this.selectedEquipment === equipment ? APP_COLOR_GREEN_DARK : APP_COLOR_SECONDARY_SURFACE)
      .padding({ left: 12, right: 12 })
      .onClick(() => this.onSelectEquipment(equipment))
  }

  @Builder
  ExerciseCard(exercise: Exercise) {
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
            .fontColor(APP_COLOR_TEXT)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          if (exercise.recommended) {
            Text('推荐')
              .fontSize(9)
              .fontWeight(FontWeight.Bold)
              .fontColor(APP_COLOR_GREEN_DARK)
              .padding({ left: 6, right: 6, top: 3, bottom: 3 })
              .borderRadius(6)
              .backgroundColor(APP_COLOR_GREEN_SOFT)
          }
        }
        .width('100%')

        Text(`${this.partName(userPartId(exercise))} · ${exercise.equipment}`)
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .fontColor(APP_COLOR_GREEN_DARK)

        Text(exercise.tip)
          .fontSize(12)
          .fontColor(APP_COLOR_MUTED)
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
    .border({ width: 1, color: APP_COLOR_LINE })
    .onClick(() => this.onOpenExercise(exercise.id))
  }

  build() {
    Row({ space: 14 }) {
      Scroll() {
        Column({ space: 8 }) {
          Text('部位')
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor(APP_COLOR_MUTED)
            .margin({ bottom: 4 })
          ForEach(BODY_PARTS, (part: BodyPart) => {
            this.PartButton(part)
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
            .fontColor(APP_COLOR_TEXT)
          Text('先选部位，再按器械找动作')
            .fontSize(13)
            .fontColor(APP_COLOR_MUTED)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')

        Scroll() {
          Row({ space: 7 }) {
            ForEach(this.equipmentOptions(), (equipment: string) => {
              this.EquipmentButton(equipment)
            }, (equipment: string) => equipment)
          }
          .height(36)
        }
        .width('100%')
        .height(36)
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)

        Text(`${this.partName(this.selectedPartId)} · ${this.visibleExercises().length} 个动作 · 共 ${getLibraryExercises(this.exercises).length} 个`)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(APP_COLOR_GREEN_DARK)
          .width('100%')

        List({ space: 10 }) {
          ForEach(this.visibleExercises(), (exercise: Exercise) => {
            ListItem() {
              this.ExerciseCard(exercise)
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
          .fontColor(APP_COLOR_TEXT_TERTIARY)
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
}
