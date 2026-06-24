import { promptAction, router } from '@kit.ArkUI';
import { PAGE_BG } from '../constants/AppConstants';
import { ToolMeta } from '../models/ToolModels';
import { HistoryPage } from './main/HistoryPage';
import { HomePage } from './main/HomePage';
import { MinePage } from './main/MinePage';

class AppRouterOptions {
  url: string = '';
  params?: Object;
}

class ToolRouteParams {
  toolId: string = '';
}

@Entry
@Component
struct Index {
  @State currentTab: number = 0;

  private openPage(url: string, params?: Object): void {
    const options = new AppRouterOptions();
    options.url = url;
    if (params) {
      options.params = params;
    }
    router.pushUrl(options).catch((error: Error) => {
      promptAction.showToast({ message: `页面打开失败：${error.message}` });
    });
  }

  private openTool(tool: ToolMeta): void {
    if (tool.id === 'document-scan') {
      this.openPage('pages/main/DocumentScanPage');
      return;
    }
    const params = new ToolRouteParams();
    params.toolId = tool.id;
    this.openPage('pages/main/ToolRunnerPage', params);
  }

  build() {
    Navigation() {
      Tabs({ barPosition: BarPosition.End, index: this.currentTab }) {
        TabContent() {
          HomePage({ onOpenTool: (tool: ToolMeta) => this.openTool(tool) })
        }
        .tabBar('首页')

        TabContent() {
          HistoryPage()
        }
        .tabBar('记录')

        TabContent() {
          MinePage({
            onOpenUsage: () => this.openPage('pages/guide/UsageGuidePage'),
            onOpenPrivacy: () => this.openPage('pages/guide/PrivacyGuidePage')
          })
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
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
    .width('100%')
    .height('100%')
    .backgroundColor(PAGE_BG)
  }
}
