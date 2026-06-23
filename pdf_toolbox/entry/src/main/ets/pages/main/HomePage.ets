import { promptAction } from '@kit.ArkUI';
import { APP_NAME, CATEGORIES, PAGE_BG, PRIMARY_COLOR, PURPLE_COLOR, TEXT_MUTED, TEXT_PRIMARY, TOOLS, getToolsByCategory } from '../../constants/AppConstants';
import { CategorySection } from '../../components/CategorySection';
import { HistoryRecord, ToolMeta } from '../../models/ToolModels';
import { HistoryService } from '../../services/HistoryService';

@Component
export struct HomePage {
  onOpenTool: (tool: ToolMeta) => void = () => {};
  @State keyword: string = '';
  @State recentRecords: HistoryRecord[] = [];

  async aboutToAppear(): Promise<void> {
    this.recentRecords = await HistoryService.getRecords();
  }

  private matchKeyword(tool: ToolMeta): boolean {
    const key = this.keyword.trim().toLowerCase();
    if (!key) {
      return true;
    }
    return [tool.name, tool.desc, tool.category, ...tool.acceptTypes].join(' ').toLowerCase().includes(key);
  }

  private hotTools(): ToolMeta[] {
    return getToolsByCategory('hot').filter((tool: ToolMeta) => this.matchKeyword(tool));
  }

  private recentTools(): ToolMeta[] {
    const used = new Set<string>();
    const result: ToolMeta[] = [];
    this.recentRecords.forEach((record: HistoryRecord) => {
      const tool = TOOLS.find((item: ToolMeta) => item.name === record.toolName);
      if (tool && !used.has(tool.id) && this.matchKeyword(tool)) {
        used.add(tool.id);
        result.push(tool);
      }
    });
    return result.slice(0, 6);
  }

  build() {
    Scroll() {
      Column({ space: 22 }) {
        Column({ space: 14 }) {
          Text(APP_NAME)
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
          Text('PDF、图片、Office 文件一站式处理')
            .fontSize(14)
            .fontColor('#EAF1FF')
          Search({ value: this.keyword, placeholder: '搜索 PDF、图片、Word、Excel 工具' })
            .height(44)
            .backgroundColor(Color.White)
            .borderRadius(10)
            .onChange((value: string) => this.keyword = value)
        }
        .width('100%')
        .padding({ left: 18, right: 18, top: 42, bottom: 22 })
        .linearGradient({ angle: 135, colors: [[PRIMARY_COLOR, 0], [PURPLE_COLOR, 1]] })
        .borderRadius({ bottomLeft: 18, bottomRight: 18 })

        CategorySection({
          title: '最近使用',
          subTitle: '最新 6 个',
          tools: this.recentTools(),
          emptyText: '处理一次文件后，这里会出现最近用过的工具',
          onOpen: this.onOpenTool
        })
        .padding({ left: 16, right: 16 })

        CategorySection({
          title: '热门工具',
          subTitle: '高频常用',
          tools: this.hotTools(),
          emptyText: '没有匹配的热门工具',
          onOpen: this.onOpenTool
        })
        .padding({ left: 16, right: 16, bottom: 24 })
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(PAGE_BG)
  }
}
