import {
  APP_COLOR_GREEN,
  APP_COLOR_GREEN_DARK,
  APP_COLOR_GREEN_SOFT,
  APP_COLOR_LINE,
  APP_COLOR_MUTED,
  APP_COLOR_TEXT
} from '../../app/AppTheme';
import { FoodEntry, NutritionSummary, QuickFood } from '../../domain/nutrition/NutritionModels';

@Component
export struct NutritionPage {
  @Prop summary: NutritionSummary = new NutritionSummary();
  @Prop entries: FoodEntry[] = [];
  @Prop quickFoods: QuickFood[] = [];
  @Prop targetCalories: number = 0;
  @Prop targetProteinG: number = 0;
  @Prop isSaving: boolean = false;
  onBack: () => void = () => {};
  onQuickAdd: (quickFoodId: number) => void = (_quickFoodId: number) => {};
  onOpenEditor: () => void = () => {};

  private mealText(mealType: string): string {
    if (mealType === 'breakfast') return '早餐';
    if (mealType === 'lunch') return '午餐';
    if (mealType === 'dinner') return '晚餐';
    return '加餐';
  }

  @Builder
  SummaryCard() {
    Column({ space: 16 }) {
      Row() {
        Text('今日营养').fontSize(17).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_TEXT)
        Blank()
        Text('热量 + 蛋白质').fontSize(13).fontColor(APP_COLOR_MUTED)
      }.width('100%')
      Row({ space: 12 }) {
        Column({ space: 5 }) {
          Text(`${Math.round(this.summary.calories)} kcal`).fontSize(25).fontWeight(FontWeight.Bold)
            .fontColor(APP_COLOR_TEXT)
          Text(this.targetCalories > 0 ? `/ ${this.targetCalories} kcal` : '今日热量')
            .fontSize(12).fontColor(APP_COLOR_MUTED)
        }.layoutWeight(1).alignItems(HorizontalAlign.Start)
        Column({ space: 5 }) {
          Text(`${Math.round(this.summary.proteinG)} g`).fontSize(25).fontWeight(FontWeight.Bold)
            .fontColor(APP_COLOR_TEXT)
          Text(this.targetProteinG > 0 ? `/ ${this.targetProteinG} g 蛋白质` : '今日蛋白质')
            .fontSize(12).fontColor(APP_COLOR_MUTED)
        }.layoutWeight(1).alignItems(HorizontalAlign.Start)
      }.width('100%')
    }
    .width('100%').padding(18).borderRadius(20).backgroundColor(APP_COLOR_GREEN_SOFT)
  }

  @Builder
  QuickFoodCard(food: QuickFood) {
    Button() {
      Column({ space: 5 }) {
        Text(food.name).fontSize(15).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_TEXT)
        Text(`${food.servingName} · ${Math.round(food.calories)} kcal`)
          .fontSize(12).fontColor(APP_COLOR_MUTED)
        Text(`${Math.round(food.proteinG)} g 蛋白质`).fontSize(12).fontColor(APP_COLOR_GREEN_DARK)
      }.alignItems(HorizontalAlign.Start)
    }
    .width('100%').height(94).padding(12).borderRadius(16).backgroundColor(Color.White)
    .border({ width: 1, color: APP_COLOR_LINE }).onClick(() => this.onQuickAdd(food.id))
  }

  @Builder
  EntryRow(entry: FoodEntry) {
    Row() {
      Column({ space: 4 }) {
        Text(entry.foodName).fontSize(15).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_TEXT)
        Text(`${entry.servings} × ${entry.servingName}`).fontSize(12).fontColor(APP_COLOR_MUTED)
      }.alignItems(HorizontalAlign.Start).layoutWeight(1)
      Column({ space: 4 }) {
        Text(`${Math.round(entry.calories)} kcal`).fontSize(14).fontColor(APP_COLOR_TEXT)
        Text(`${Math.round(entry.proteinG)} g 蛋白质`).fontSize(12).fontColor(APP_COLOR_GREEN_DARK)
      }.alignItems(HorizontalAlign.End)
    }.width('100%').padding({ top: 10, bottom: 10 })
  }

  @Builder
  MealSection(mealType: string, mealEntries: FoodEntry[]) {
    if (mealEntries.length > 0) {
      Column({ space: 4 }) {
        Text(this.mealText(mealType)).width('100%').fontSize(14).fontWeight(FontWeight.Bold)
          .fontColor(APP_COLOR_MUTED)
        ForEach(mealEntries, (entry: FoodEntry) => {
          this.EntryRow(entry)
        }, (entry: FoodEntry) => entry.id.toString())
      }.width('100%').padding(16).borderRadius(18).backgroundColor(Color.White)
        .border({ width: 1, color: APP_COLOR_LINE })
    }
  }

  build() {
    Column() {
      Row() {
        Button('‹').width(48).height(48).fontSize(34).fontColor(APP_COLOR_TEXT)
          .backgroundColor(Color.Transparent).onClick(() => this.onBack())
        Text('营养记录').layoutWeight(1).textAlign(TextAlign.Center).fontSize(19)
          .fontWeight(FontWeight.Bold).fontColor(APP_COLOR_TEXT)
        Blank().width(48)
      }.width('100%').height(58)

      Scroll() {
        Column({ space: 16 }) {
          this.SummaryCard()
          Row() {
            Text('快捷添加').fontSize(18).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_TEXT)
            Blank()
            Text('点击即记录').fontSize(12).fontColor(APP_COLOR_MUTED)
          }.width('100%')
          if (this.quickFoods.length === 0) {
            Text('暂无快捷食物，请使用手动记录。').width('100%').fontSize(14).fontColor(APP_COLOR_MUTED)
          } else {
            Column({ space: 10 }) {
              ForEach(this.quickFoods, (food: QuickFood) => {
                this.QuickFoodCard(food)
              }, (food: QuickFood) => food.id.toString())
            }.width('100%')
          }
          Button('＋ 手动添加食物').width('100%').height(52).fontSize(15).fontWeight(FontWeight.Bold)
            .fontColor(APP_COLOR_GREEN_DARK).backgroundColor(Color.White).borderRadius(16)
            .border({ width: 1, color: APP_COLOR_GREEN }).enabled(!this.isSaving)
            .onClick(() => this.onOpenEditor())
          Text('今天的记录').width('100%').fontSize(18).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_TEXT)
          if (this.entries.length === 0) {
            Text('先添加一勺乳清蛋白，建立今天的记录。').width('100%').fontSize(14).fontColor(APP_COLOR_MUTED)
          } else {
            this.MealSection('breakfast', this.entries.filter((entry: FoodEntry) => entry.mealType === 'breakfast'))
            this.MealSection('lunch', this.entries.filter((entry: FoodEntry) => entry.mealType === 'lunch'))
            this.MealSection('dinner', this.entries.filter((entry: FoodEntry) => entry.mealType === 'dinner'))
            this.MealSection('snack', this.entries.filter((entry: FoodEntry) => entry.mealType === 'snack'))
          }
        }.width('100%').padding({ left: 20, right: 20, top: 10, bottom: 28 })
      }.layoutWeight(1).scrollBar(BarState.Off)
    }.width('100%').height('100%')
  }
}
