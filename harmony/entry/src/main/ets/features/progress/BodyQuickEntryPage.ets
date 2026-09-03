import { APP_COLOR_GREEN, APP_COLOR_LINE, APP_COLOR_MUTED, APP_COLOR_TEXT } from '../../app/AppTheme';
import { BodyMeasurement } from '../../domain/body/BodyModels';
import { AppHeader } from '../../components/AppHeader';

@Component
export struct BodyQuickEntryPage {
  @Prop isSaving: boolean = false;
  @State private weightText: string = '';
  @State private waistText: string = '';
  onBack: () => void = () => {};
  onSave: (measurement: BodyMeasurement) => void = (_measurement: BodyMeasurement) => {};

  private value(text: string): number {
    const parsed: number = Number(text);
    return Number.isFinite(parsed) ? parsed : 0;
  }

  private save(): void {
    const weight: number = this.value(this.weightText);
    if (weight <= 0 || this.isSaving) return;
    this.onSave(new BodyMeasurement(0, Date.now(), weight, this.value(this.waistText), 0, 'quick'));
  }

  build() {
    Column() {
      AppHeader({ title: '记录身体', showBack: true, backGlyph: '×', onBack: () => this.onBack() })
      Column({ space: 16 }) {
        Text('记录今天的状态').width('100%').fontSize(27).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_TEXT)
        Text('体重必填，腰围可选。保存后趋势和今日页会立即更新。').width('100%').fontSize(14).fontColor(APP_COLOR_MUTED)
        Text('体重（kg）').width('100%').fontSize(13).fontColor(APP_COLOR_MUTED)
        TextInput({ placeholder: '例如：82.0', text: this.weightText }).height(54).fontSize(18)
          .backgroundColor(Color.White).borderRadius(14).border({ width: 1, color: APP_COLOR_LINE })
          .onChange((value: string) => this.weightText = value)
        Text('腰围（cm，可选）').width('100%').fontSize(13).fontColor(APP_COLOR_MUTED)
        TextInput({ placeholder: '例如：88.0', text: this.waistText }).height(54).fontSize(18)
          .backgroundColor(Color.White).borderRadius(14).border({ width: 1, color: APP_COLOR_LINE })
          .onChange((value: string) => this.waistText = value)
      }.width('100%').padding(20).layoutWeight(1).alignItems(HorizontalAlign.Start)
      Column() {
        Button(this.isSaving ? '正在保存…' : '保存').width('100%').height(58)
          .fontSize(17).fontWeight(FontWeight.Bold).fontColor(Color.White).borderRadius(18)
          .backgroundColor(APP_COLOR_GREEN).enabled(!this.isSaving && this.value(this.weightText) > 0)
          .onClick(() => this.save())
      }.width('100%').padding({ left: 20, right: 20, bottom: 22 })
    }.width('100%').height('100%')
  }
}
