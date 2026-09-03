import {
  APP_COLOR_DANGER,
  APP_COLOR_GREEN,
  APP_COLOR_GREEN_DARK,
  APP_COLOR_GREEN_SOFT,
  APP_COLOR_LINE,
  APP_COLOR_MUTED,
  APP_COLOR_TEXT
} from '../../app/AppTheme';
import { AppHeader } from '../../components/AppHeader';
import { FoodEntry } from '../../domain/nutrition/NutritionModels';

@Component
export struct FoodEntryEditorPage {
  @Prop isSaving: boolean = false;
  onBack: () => void = () => {};
  onSave: (entry: FoodEntry) => void = (_entry: FoodEntry) => {};

  @State private mealType: string = 'snack';
  @State private foodName: string = '';
  @State private servingName: string = '1 份';
  @State private servingsText: string = '1';
  @State private caloriesText: string = '';
  @State private proteinText: string = '';
  @State private carbsText: string = '';
  @State private fatText: string = '';

  private numberValue(text: string, fallback: number = 0): number {
    const value: number = Number(text);
    return Number.isFinite(value) ? value : fallback;
  }

  private valid(): boolean {
    return this.foodName.trim() !== '' && this.servingName.trim() !== '' &&
      this.numberValue(this.servingsText, 0) > 0 && this.numberValue(this.caloriesText, -1) >= 0 &&
      this.numberValue(this.proteinText, -1) >= 0;
  }

  private save(): void {
    if (!this.valid() || this.isSaving) {
      return;
    }
    const servings: number = this.numberValue(this.servingsText, 1);
    this.onSave(new FoodEntry(0, Date.now(), this.mealType, this.foodName.trim(), this.servingName.trim(), servings,
      this.numberValue(this.caloriesText), this.numberValue(this.proteinText), this.numberValue(this.carbsText),
      this.numberValue(this.fatText), 0, Date.now()));
  }

  @Builder
  Field(label: string, placeholder: string, value: string, onChange: (value: string) => void,
    isHalfWidth: boolean = false) {
    Column({ space: 7 }) {
      Text(label).width('100%').fontSize(13).fontColor(APP_COLOR_MUTED)
      TextInput({ placeholder: placeholder, text: value }).height(50).fontSize(16).backgroundColor(Color.White)
        .borderRadius(13).border({ width: 1, color: APP_COLOR_LINE })
        .onChange((changed: string) => onChange(changed))
    }.width(isHalfWidth ? '48%' : '100%')
  }

  @Builder
  MealButton(label: string, value: string) {
    Button(label).layoutWeight(1).height(44).fontSize(13).fontWeight(FontWeight.Bold)
      .fontColor(this.mealType === value ? APP_COLOR_GREEN_DARK : APP_COLOR_MUTED)
      .backgroundColor(this.mealType === value ? APP_COLOR_GREEN_SOFT : Color.White).borderRadius(12)
      .border({ width: 1, color: this.mealType === value ? APP_COLOR_GREEN : APP_COLOR_LINE })
      .onClick(() => this.mealType = value)
  }

  build() {
    Column() {
      AppHeader({ title: '手动添加', showBack: true, onBack: () => this.onBack() })
      Scroll() {
        Column({ space: 16 }) {
          Text('这顿吃了什么？').width('100%').fontSize(26).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_TEXT)
          Text('只记录你想关注的营养数据，之后仍可修改。').width('100%').fontSize(14).fontColor(APP_COLOR_MUTED)
          Row({ space: 8 }) {
            this.MealButton('早餐', 'breakfast')
            this.MealButton('午餐', 'lunch')
            this.MealButton('晚餐', 'dinner')
            this.MealButton('加餐', 'snack')
          }.width('100%')
          this.Field('食物名称', '例如：鸡胸肉', this.foodName, (value: string) => this.foodName = value)
          this.Field('份量单位', '例如：200g', this.servingName, (value: string) => this.servingName = value)
          this.Field('份数', '例如：1', this.servingsText, (value: string) => this.servingsText = value)
          Row({ space: 10 }) {
            this.Field('热量（kcal）', '0', this.caloriesText, (value: string) => this.caloriesText = value, true)
            this.Field('蛋白质（g）', '0', this.proteinText, (value: string) => this.proteinText = value, true)
          }.width('100%')
          Row({ space: 10 }) {
            this.Field('碳水（g，可选）', '可留空', this.carbsText, (value: string) => this.carbsText = value, true)
            this.Field('脂肪（g，可选）', '可留空', this.fatText, (value: string) => this.fatText = value, true)
          }.width('100%')
          if (!this.valid()) {
            Text('请填写食物名称、份量、热量和蛋白质。').width('100%').fontSize(13)
              .fontColor(APP_COLOR_DANGER)
          }
        }.width('100%').padding({ left: 20, right: 20, top: 12, bottom: 28 })
      }.layoutWeight(1).scrollBar(BarState.Off)
      Column() {
        Button(this.isSaving ? '正在保存…' : '保存并返回今日')
          .width('100%').height(58).fontSize(17)
          .fontWeight(FontWeight.Bold).fontColor(Color.White).borderRadius(18).backgroundColor(APP_COLOR_GREEN)
          .enabled(!this.isSaving && this.valid()).onClick(() => this.save())
      }.width('100%').padding({ left: 20, right: 20, bottom: 22 })
    }.width('100%').height('100%')
  }
}
