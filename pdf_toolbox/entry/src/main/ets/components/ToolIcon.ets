import { PRIMARY_COLOR, PURPLE_COLOR } from '../constants/AppConstants';

@Component
export struct ToolIcon {
  label: string = 'PDF';

  build() {
    Text(this.label)
      .width(48)
      .height(48)
      .borderRadius(14)
      .fontSize(12)
      .fontWeight(FontWeight.Bold)
      .fontColor(PRIMARY_COLOR)
      .textAlign(TextAlign.Center)
      .backgroundColor('#EEF3FF')
      .linearGradient({
        angle: 135,
        colors: [[PRIMARY_COLOR, 0.0], [PURPLE_COLOR, 1.0]]
      })
      .fontColor(Color.White)
  }
}
