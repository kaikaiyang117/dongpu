import {
  APP_COLOR_GREEN,
  APP_COLOR_GREEN_SOFT,
  APP_COLOR_SECONDARY_SURFACE,
  APP_COLOR_TEXT,
  APP_PAGE_MARGIN
} from '../../app/AppTheme';
import { PageHero } from '../../components/PageHero';
import { BODY_PARTS } from '../../data/ExerciseCatalog';
import { BodyPart } from '../../model/Exercise';

@Component
export struct BodyPartSelectPage {
  @Prop selectedParts: string[] = [];
  onTogglePart: (id: string) => void = () => {};

  private isSelected(id: string): boolean {
    return this.selectedParts.includes(id);
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
          .fontColor(APP_COLOR_TEXT)
      }
      .justifyContent(FlexAlign.Center)
      .width('100%')
      .height('100%')

      if (this.isSelected(part.id)) {
        Stack() {
          Text('✓')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
        }
        .width(23)
        .height(23)
        .borderRadius(12)
        .backgroundColor(APP_COLOR_GREEN)
        .margin({ top: 10, right: 10 })
      }
    }
    .width('100%')
    .height(148)
    .borderRadius(19)
    .backgroundColor(this.isSelected(part.id) ? APP_COLOR_GREEN_SOFT : APP_COLOR_SECONDARY_SURFACE)
    .border({ width: this.isSelected(part.id) ? 1.5 : 0, color: APP_COLOR_GREEN })
    .clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.98 })
    .accessibilityText(part.name)
    .accessibilitySelected(this.isSelected(part.id))
    .onClick(() => this.onTogglePart(part.id))
  }

  build() {
    Scroll() {
      Column({ space: 24 }) {
        PageHero({
          eyebrow: '第 1 步 · 训练部位',
          title: '今天想练哪里？',
          subtitle: '建议选择 1—2 个部位，也可按今天的节奏多选'
        })
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
      .padding({ left: APP_PAGE_MARGIN, right: APP_PAGE_MARGIN, bottom: 24 })
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }
}
