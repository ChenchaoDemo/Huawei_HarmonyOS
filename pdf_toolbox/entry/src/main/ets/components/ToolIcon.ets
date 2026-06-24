import { PRIMARY_COLOR, PURPLE_COLOR } from '../constants/AppConstants';

@Component
export struct ToolIcon {
  label: string = 'PDF';
  iconSize: number = 40;
  radius: number = 12;

  build() {
    Text(this.label)
      .width(this.iconSize)
      .height(this.iconSize)
      .borderRadius(this.radius)
      .fontSize(11)
      .fontWeight(FontWeight.Bold)
      .fontColor(Color.White)
      .textAlign(TextAlign.Center)
      .backgroundColor('#EEF3FF')
      .linearGradient({
        angle: 135,
        colors: [[PRIMARY_COLOR, 0.0], [PURPLE_COLOR, 1.0]]
      })
  }
}
