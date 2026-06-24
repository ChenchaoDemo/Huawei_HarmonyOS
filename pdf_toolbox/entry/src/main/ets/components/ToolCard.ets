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
    Row({ space: 10 }) {
      ToolIcon({ label: this.tool.iconText, iconSize: 38, radius: 11 })

      Column({ space: 6 }) {
        Row() {
          Text(this.tool.name)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_PRIMARY)
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }

        Text(this.tool.desc)
          .fontSize(12)
          .fontColor(TEXT_MUTED)
          .lineHeight(16)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height(86)
    .padding(12)
    .borderRadius(8)
    .backgroundColor(Color.White)
    .shadow({ radius: 8, color: '#0D23355C', offsetY: 3 })
    .onClick(() => this.onOpen(this.tool))
  }
}
