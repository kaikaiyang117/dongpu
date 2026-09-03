import {
  APP_COLOR_GREEN_DARK,
  APP_COLOR_GREEN_SOFT,
  APP_COLOR_LINE,
  APP_COLOR_MUTED,
  APP_COLOR_TEXT
} from '../../app/AppTheme';
import { WorkoutSession } from '../../domain/workout/WorkoutModels';

@Component
export struct HistoryPage {
  @Prop sessions: WorkoutSession[] = [];
  @Prop weeklyCompleted: number = 0;
  @Prop weeklyFrequency: number = 3;
  onOpenDetail: (sessionId: number) => void = () => {};

  private dateText(timestamp: number): string {
    const date: Date = new Date(timestamp);
    return `${date.getMonth() + 1} 月 ${date.getDate()} 日`;
  }

  private minutes(session: WorkoutSession): number {
    return Math.max(1, Math.floor((session.completedAt - session.startedAt) / 60000));
  }

  @Builder
  SessionCard(session: WorkoutSession) {
    Column({ space: 8 }) {
      Row() {
        Column({ space: 6 }) {
          Text(this.dateText(session.completedAt))
            .fontSize(13)
            .fontColor(APP_COLOR_GREEN_DARK)
          Text(`${session.workoutCode} · ${session.workoutNameSnapshot}`)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(APP_COLOR_TEXT)
          Text(`${this.minutes(session)} 分钟 · ${session.exercises.length} 个动作`)
            .fontSize(13)
            .fontColor(APP_COLOR_MUTED)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Text('详情 ›')
          .fontSize(13)
          .fontColor(APP_COLOR_GREEN_DARK)
      }
      .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(17)
    .borderRadius(18)
    .backgroundColor(Color.White)
    .border({ width: 1, color: APP_COLOR_LINE })
    .clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.98 })
    .accessibilityText(`查看 ${session.workoutNameSnapshot} 训练详情`)
    .onClick(() => this.onOpenDetail(session.id))
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('记录')
          .width('100%')
          .fontSize(29)
          .fontWeight(FontWeight.Bold)
          .fontColor(APP_COLOR_TEXT)

        Column({ space: 8 }) {
          Text('本周训练概览')
            .width('100%')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(APP_COLOR_TEXT)
          Text(`已完成 ${this.weeklyCompleted} / 3 次必做训练`)
            .width('100%')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(APP_COLOR_GREEN_DARK)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(17)
        .borderRadius(18)
        .backgroundColor(APP_COLOR_GREEN_SOFT)

        Text('训练历史')
          .width('100%')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(APP_COLOR_TEXT)
          .margin({ top: 6 })

        if (this.sessions.length === 0) {
          Text('完成第一次训练后，记录会出现在这里。')
            .width('100%')
            .fontSize(14)
            .fontColor(APP_COLOR_MUTED)
            .lineHeight(22)
            .margin({ top: 12 })
        } else {
          ForEach(this.sessions, (session: WorkoutSession) => {
            this.SessionCard(session)
          }, (session: WorkoutSession) => session.id.toString())
        }
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding({ left: 20, right: 20, top: 18, bottom: 24 })
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }
}
