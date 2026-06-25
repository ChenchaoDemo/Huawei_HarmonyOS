import { PRIMARY_COLOR, TEXT_MUTED, TEXT_PRIMARY } from '../constants/AppConstants';
import { SettingValue, ToolSetting } from '../models/ToolModels';

@Component
export struct SettingRow {
  @Prop setting: ToolSetting = { key: '', label: '', type: 'input' };
  @Prop value: SettingValue = '';
  onValueChange: (key: string, value: SettingValue) => void = () => {};

  private valueText(): string {
    return String(this.value ?? this.setting.value ?? '');
  }

  private valueNumber(): number {
    return Number(this.value ?? this.setting.value ?? this.setting.min ?? 0);
  }

  @Builder
  OptionChip(option: string) {
    Text(option)
      .height(36)
      .fontSize(13)
      .fontWeight(this.valueText() === option ? FontWeight.Bold : FontWeight.Medium)
      .fontColor(this.valueText() === option ? Color.White : '#52607A')
      .textAlign(TextAlign.Center)
      .padding({ left: 14, right: 14, top: 7, bottom: 7 })
      .margin({ right: 8, bottom: 8 })
      .borderRadius(8)
      .backgroundColor(this.valueText() === option ? PRIMARY_COLOR : '#F1F4FB')
      .border({ width: 1, color: this.valueText() === option ? PRIMARY_COLOR : '#E2E9F5' })
      .onClick(() => this.onValueChange(this.setting.key, option))
  }

  build() {
    Column({ space: 10 }) {
      Text(this.setting.label)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(TEXT_PRIMARY)
        .width('100%')

      if (this.setting.type === 'input' || this.setting.type === 'password') {
        TextInput({ text: this.valueText(), placeholder: this.setting.placeholder || '请输入' })
          .height(42)
          .fontSize(14)
          .type(this.setting.type === 'password' ? InputType.Password : InputType.Normal)
          .backgroundColor('#F5F7FC')
          .borderRadius(8)
          .onChange((value: string) => this.onValueChange(this.setting.key, value))
      } else if (this.setting.type === 'switch') {
        Row() {
          Toggle({ type: ToggleType.Switch, isOn: this.value === true })
            .selectedColor(PRIMARY_COLOR)
            .onChange((value: boolean) => this.onValueChange(this.setting.key, value))
        }
        .width('100%')
        .justifyContent(FlexAlign.End)
      } else if (this.setting.type === 'slider') {
        Row({ space: 10 }) {
          Slider({
            value: this.valueNumber(),
            min: this.setting.min ?? 0,
            max: this.setting.max ?? 100,
            step: this.setting.step ?? 1
          })
            .layoutWeight(1)
            .selectedColor(PRIMARY_COLOR)
            .onChange((value: number) => this.onValueChange(this.setting.key, value))
          Text(`${this.valueNumber()}`)
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor(PRIMARY_COLOR)
            .width(44)
            .textAlign(TextAlign.End)
        }
      } else {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.setting.options || [], (option: string) => {
            this.OptionChip(option)
          }, (option: string) => option)
        }
        .width('100%')
      }

      if (this.setting.dynamicHint || this.setting.hint) {
        Text(this.setting.dynamicHint || this.setting.hint || '')
          .fontSize(12)
          .lineHeight(17)
          .fontColor(TEXT_MUTED)
          .width('100%')
      }
    }
    .width('100%')
    .padding({ top: 14, bottom: 14 })
    .border({ width: { bottom: 1 }, color: '#EDF1F8' })
  }
}
