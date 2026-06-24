import { TEXT_MUTED, TEXT_PRIMARY } from '../constants/AppConstants';

@Component
export struct GuideSectionCard {
  title: string = '';
  points: string[] = [];

  build() {
    Column({ space: 10 }) {
      Text(this.title)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(TEXT_PRIMARY)
        .width('100%')

      Column({ space: 8 }) {
        ForEach(this.points, (point: string) => {
          Row({ space: 8 }) {
            Text('•')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#2667FF')
            Text(point)
              .fontSize(13)
              .lineHeight(19)
              .fontColor(TEXT_MUTED)
              .layoutWeight(1)
              .textAlign(TextAlign.Start)
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)
        }, (point: string) => point)
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .borderRadius(8)
    .backgroundColor(Color.White)
    .shadow({ radius: 10, color: '#1023355C', offsetY: 3 })
  }
}
