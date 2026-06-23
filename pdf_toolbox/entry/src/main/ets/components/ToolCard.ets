import { TEXT_MUTED, TEXT_PRIMARY } from '../constants/AppConstants';
import { ToolMeta } from '../models/ToolModels';
import { ToolIcon } from './ToolIcon';

@Component
export struct ToolCard {
  tool: ToolMeta = {
    id: '',
    name: '',
    desc: '',
    category: 'pdf',
    iconText: 'PDF',
    path: '',
    hot: false,
    acceptTypes: []
  };
  onOpen: (tool: ToolMeta) => void = () => {};

  build() {
    Row({ space: 12 }) {
      ToolIcon({ label: this.tool.iconText })
      Column({ space: 6 }) {
        Row({ space: 6 }) {
          Text(this.tool.name)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_PRIMARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          if (this.tool.hot) {
            Text('HOT')
              .fontSize(9)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FF5A3D')
              .padding({ left: 5, right: 5, top: 2, bottom: 2 })
              .borderRadius(6)
              .backgroundColor('#FFF0EC')
          }
        }
        .width('100%')

        Text(this.tool.desc)
          .fontSize(12)
          .fontColor(TEXT_MUTED)
          .lineHeight(17)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .height(86)
    .padding(12)
    .borderRadius(8)
    .backgroundColor(Color.White)
    .shadow({ radius: 10, color: '#1023355C', offsetY: 3 })
    .onClick(() => this.onOpen(this.tool))
  }
}
