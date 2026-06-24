import { APP_NAME, CATEGORIES, PAGE_BG, PRIMARY_COLOR, PURPLE_COLOR, TEXT_MUTED, TEXT_PRIMARY, TOOLS, getToolsByCategory } from '../../constants/AppConstants';
import { CategorySection } from '../../components/CategorySection';
import { CategoryMeta, HistoryRecord, ToolMeta } from '../../models/ToolModels';
import { HistoryService } from '../../services/HistoryService';

@Component
export struct HomePage {
  onOpenTool: (tool: ToolMeta) => void = () => {};
  @State keyword: string = '';
  @State selectedCategory: string = 'all';
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

  private allCategories(): CategoryMeta[] {
    return CATEGORIES.filter((category: CategoryMeta) => category.id !== 'hot');
  }

  private categoryTools(category: CategoryMeta): ToolMeta[] {
    return getToolsByCategory(category.id).filter((tool: ToolMeta) => this.matchKeyword(tool));
  }

  private filteredCategories(): CategoryMeta[] {
    if (this.selectedCategory === 'all') {
      return this.allCategories();
    }
    return this.allCategories().filter((category: CategoryMeta) => category.id === this.selectedCategory);
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
    return result.slice(0, 8);
  }

  @Builder
  FilterChip(id: string, label: string) {
    Text(label)
      .height(36)
      .fontSize(13)
      .fontWeight(this.selectedCategory === id ? FontWeight.Bold : FontWeight.Medium)
      .fontColor(this.selectedCategory === id ? Color.White : '#52607A')
      .textAlign(TextAlign.Center)
      .padding({ left: 14, right: 14 })
      .borderRadius(18)
      .backgroundColor(this.selectedCategory === id ? PRIMARY_COLOR : Color.White)
      .border({ width: 1, color: this.selectedCategory === id ? PRIMARY_COLOR : '#E2E9F5' })
      .onClick(() => this.selectedCategory = id)
  }

  build() {
    Scroll() {
      Column({ space: 18 }) {
        Column({ space: 16 }) {
          Row({ space: 12 }) {
            Column({ space: 8 }) {
              Text(APP_NAME)
                .fontSize(28)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
              Text('PDF、图片、Office 文件一站式处理')
                .fontSize(14)
                .fontColor('#EAF1FF')
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Text('PDF')
              .width(52)
              .height(52)
              .borderRadius(13)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(PRIMARY_COLOR)
              .textAlign(TextAlign.Center)
              .backgroundColor(Color.White)
          }
          .width('100%')

          Search({ value: this.keyword, placeholder: '搜索 PDF、图片、Word、Excel 工具' })
            .height(44)
            .backgroundColor(Color.White)
            .borderRadius(10)
            .onChange((value: string) => this.keyword = value)
        }
        .width('100%')
        .padding({ left: 18, right: 18, top: 34, bottom: 22 })
        .linearGradient({ angle: 135, colors: [[PRIMARY_COLOR, 0], [PURPLE_COLOR, 1]] })
        .borderRadius({ bottomLeft: 18, bottomRight: 18 })

        Column({ space: 14 }) {
          Row() {
            Text('工具库')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(TEXT_PRIMARY)
              .layoutWeight(1)
            Text('按分类快速处理文件')
              .fontSize(12)
              .fontColor(TEXT_MUTED)
          }
          .width('100%')

          Scroll() {
            Row({ space: 8 }) {
              this.FilterChip('all', '全部')
              this.FilterChip('recent', '最近使用')
              ForEach(this.allCategories(), (category: CategoryMeta) => {
                this.FilterChip(category.id, category.name)
              }, (category: CategoryMeta) => category.id)
            }
            .padding({ right: 16 })
          }
          .width('100%')
          .height(42)
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
        }
        .padding({ left: 16, right: 16 })

        if (this.selectedCategory === 'all') {
          ForEach(this.allCategories(), (category: CategoryMeta) => {
            CategorySection({
              title: category.name,
              subTitle: `${getToolsByCategory(category.id).length} 个工具`,
              tools: this.categoryTools(category),
              emptyText: '没有匹配的工具',
              onOpen: this.onOpenTool
            })
            .padding({ left: 16, right: 16 })
          }, (category: CategoryMeta) => category.id)
        } else if (this.selectedCategory === 'recent') {
          CategorySection({
            title: '最近使用',
            subTitle: '按处理时间排序',
            tools: this.recentTools(),
            emptyText: '处理一次文件后，这里会出现最近用过的工具',
            onOpen: this.onOpenTool
          })
          .padding({ left: 16, right: 16 })
        } else {
          ForEach(this.filteredCategories(), (category: CategoryMeta) => {
            CategorySection({
              title: category.name,
              subTitle: `${getToolsByCategory(category.id).length} 个工具`,
              tools: this.categoryTools(category),
              emptyText: '没有匹配的工具',
              onOpen: this.onOpenTool
            })
            .padding({ left: 16, right: 16 })
          }, (category: CategoryMeta) => category.id)
        }

        Blank().height(16)
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(PAGE_BG)
  }
}
