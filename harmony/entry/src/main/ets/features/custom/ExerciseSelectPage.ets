import {
  APP_COLOR_GREEN,
  APP_COLOR_GREEN_BADGE,
  APP_COLOR_GREEN_BORDER,
  APP_COLOR_GREEN_DARK,
  APP_COLOR_GREEN_SOFT,
  APP_COLOR_LINE,
  APP_COLOR_MUTED,
  APP_COLOR_SECONDARY_SURFACE,
  APP_COLOR_CONTROL_BORDER,
  APP_COLOR_CONTROL_ICON,
  APP_COLOR_TEXT,
  APP_PAGE_MARGIN
} from '../../app/AppTheme';
import { PageHero } from '../../components/PageHero';
import { BODY_PARTS, exerciseMatchesPart, getApprovedExercises } from '../../data/ExerciseCatalog';
import { BodyPart, Exercise } from '../../model/Exercise';

@Component
export struct ExerciseSelectPage {
  @Prop exercises: Exercise[] = [];
  @Prop selectedParts: string[] = [];
  @Prop selectedExerciseIds: string[] = [];
  onToggleExercise: (id: string) => void = () => {};

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

  private visibleExercises(): Exercise[] {
    return getApprovedExercises(this.exercises).filter((exercise: Exercise) =>
      this.selectedParts.some((partId: string) => exerciseMatchesPart(exercise, partId)));
  }

  private isSelected(id: string): boolean {
    return this.selectedExerciseIds.includes(id);
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
      .backgroundColor(APP_COLOR_SECONDARY_SURFACE)

      Column({ space: 5 }) {
        Row({ space: 7 }) {
          Text(exercise.name)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(APP_COLOR_TEXT)
          if (exercise.recommended) {
            Text('推荐')
              .fontSize(9)
              .fontWeight(FontWeight.Bold)
              .fontColor(APP_COLOR_GREEN_DARK)
              .padding({ left: 6, right: 6, top: 3, bottom: 3 })
              .borderRadius(6)
              .backgroundColor(APP_COLOR_GREEN_BADGE)
          }
        }
        Text(`${exercise.equipment} · ${exercise.tip}`)
          .fontSize(11)
          .fontColor(APP_COLOR_MUTED)
          .lineHeight(15)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Stack() {
        Text(this.isSelected(exercise.id) ? '✓' : '+')
          .fontSize(16)
          .fontColor(this.isSelected(exercise.id) ? Color.White : APP_COLOR_CONTROL_ICON)
      }
      .width(27)
      .height(27)
      .borderRadius(14)
      .backgroundColor(this.isSelected(exercise.id) ? APP_COLOR_GREEN : Color.Transparent)
      .border({ width: 1, color: this.isSelected(exercise.id) ? APP_COLOR_GREEN : APP_COLOR_CONTROL_BORDER })
    }
    .width('100%')
    .height(83)
    .padding(12)
    .borderRadius(16)
    .backgroundColor(this.isSelected(exercise.id) ? APP_COLOR_GREEN_SOFT : Color.White)
    .border({ width: 1.5, color: this.isSelected(exercise.id) ? APP_COLOR_GREEN : APP_COLOR_LINE })
    .onClick(() => this.onToggleExercise(exercise.id))
  }

  build() {
    List({ space: 16 }) {
      ListItem() {
        PageHero({
          eyebrow: '第 2 步 · 选择动作',
          title: '选择今天的动作',
          subtitle: '新手建议每个部位选择 2—3 个动作'
        })
      }

      ListItem() {
        Row({ space: 8 }) {
          ForEach(this.selectedParts, (id: string) => {
            Text(this.partName(id))
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor(APP_COLOR_GREEN_DARK)
              .padding({ left: 13, right: 13, top: 8, bottom: 8 })
              .borderRadius(18)
              .backgroundColor(APP_COLOR_GREEN_SOFT)
              .border({ width: 1, color: APP_COLOR_GREEN_BORDER })
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
    .padding({ left: APP_PAGE_MARGIN, right: APP_PAGE_MARGIN, bottom: 24 })
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }
}
