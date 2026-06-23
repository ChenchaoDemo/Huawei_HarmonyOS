import { CATEGORIES, PAGE_BG, PRIMARY_COLOR, PURPLE_COLOR, TEXT_MUTED, getToolsByCategory } from '../../constants/AppConstants';
import { CategorySection } from '../../components/CategorySection';
import { CategoryMeta, ToolMeta } from '../../models/ToolModels';

@Component
export struct ToolsPage {
  onOpenTool: (tool: ToolMeta) => void = () => {};

  build() {
    Scroll() {
      Column({ space: 22 }) {
        Column({ space: 8 }) {
          Text('全部工具')
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
          Text('按类别选择常用办公文件处理能力')
            .fontSize(13)
            .fontColor('#EAF1FF')
        }
        .width('100%')
        .padding(18)
        .borderRadius(8)
        .linearGradient({ angle: 135, colors: [[PRIMARY_COLOR, 0], [PURPLE_COLOR, 1]] })

        ForEach(CATEGORIES.filter((category: CategoryMeta) => category.id !== 'hot'), (category: CategoryMeta) => {
          CategorySection({
            title: category.name,
            subTitle: `${getToolsByCategory(category.id).length} 个工具`,
            tools: getToolsByCategory(category.id),
            onOpen: this.onOpenTool
          })
        }, (category: CategoryMeta) => category.id)
      }
      .padding({ left: 16, right: 16, top: 44, bottom: 16 })
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(PAGE_BG)
  }
}
