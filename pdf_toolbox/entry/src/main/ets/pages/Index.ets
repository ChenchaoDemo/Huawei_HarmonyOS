import { PAGE_BG, PRIMARY_COLOR, TEXT_MUTED } from '../constants/AppConstants';
import { ToolMeta } from '../models/ToolModels';
import { DocumentScanPage } from './main/DocumentScanPage';
import { HistoryPage } from './main/HistoryPage';
import { HomePage } from './main/HomePage';
import { MinePage } from './main/MinePage';
import { ToolRunnerPage } from './main/ToolRunnerPage';
import { ToolsPage } from './main/ToolsPage';

@Entry
@Component
struct Index {
  @State currentTab: number = 0;
  @State activeToolId: string = '';
  @State showDocumentScan: boolean = false;

  private openTool(tool: ToolMeta): void {
    if (tool.id === 'document-scan') {
      this.showDocumentScan = true;
      this.activeToolId = '';
      return;
    }
    this.activeToolId = tool.id;
    this.showDocumentScan = false;
  }

  private closeDetail(): void {
    this.activeToolId = '';
    this.showDocumentScan = false;
  }

  build() {
    Navigation() {
      if (this.showDocumentScan) {
        DocumentScanPage({ onBack: () => this.closeDetail() })
      } else if (this.activeToolId.length > 0) {
        ToolRunnerPage({ toolId: this.activeToolId, onBack: () => this.closeDetail() })
      } else {
        Tabs({ barPosition: BarPosition.End, index: this.currentTab }) {
          TabContent() {
            HomePage({ onOpenTool: (tool: ToolMeta) => this.openTool(tool) })
          }
          .tabBar('首页')

          TabContent() {
            ToolsPage({ onOpenTool: (tool: ToolMeta) => this.openTool(tool) })
          }
          .tabBar('工具')

          TabContent() {
            HistoryPage()
          }
          .tabBar('记录')

          TabContent() {
            MinePage()
          }
          .tabBar('我的')
        }
        .width('100%')
        .height('100%')
        .barHeight(58)
        .barBackgroundColor(Color.White)
        .animationDuration(180)
        .onChange((index: number) => this.currentTab = index)
      }
    }
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
    .width('100%')
    .height('100%')
    .backgroundColor(PAGE_BG)
  }
}
