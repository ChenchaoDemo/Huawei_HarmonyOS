import { TEXT_MUTED, TEXT_PRIMARY } from '../constants/AppConstants';
import { ToolMeta } from '../models/ToolModels';
import { ToolCard } from './ToolCard';

@Component
export struct CategorySection {
  title: string = '';
  subTitle: string = '';
  emptyText: string = '';
  tools: ToolMeta[] = [];
  onOpen: (tool: ToolMeta) => void = () => {};

  build() {
    Column({ space: 12 }) {
      Row() {
        Text(this.title)
          .fontSize(19)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_PRIMARY)
          .layoutWeight(1)
        if (this.subTitle.length > 0) {
          Text(this.subTitle)
            .fontSize(12)
            .fontColor(TEXT_MUTED)
        }
      }
      .width('100%')

      if (this.tools.length > 0) {
        Grid() {
          ForEach(this.tools, (tool: ToolMeta) => {
            GridItem() {
              ToolCard({ tool, onOpen: this.onOpen })
            }
          }, (tool: ToolMeta) => tool.id)
        }
        .columnsTemplate('1fr 1fr')
        .columnsGap(12)
        .rowsGap(12)
        .width('100%')
        .height(Math.ceil(this.tools.length / 2) * 98)
      } else {
        Text(this.emptyText || '暂无内容')
          .width('100%')
          .height(92)
          .fontSize(13)
          .fontColor(TEXT_MUTED)
          .textAlign(TextAlign.Center)
          .borderRadius(8)
          .backgroundColor(Color.White)
      }
    }
    .width('100%')
  }
}
