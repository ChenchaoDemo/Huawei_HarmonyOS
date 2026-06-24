import { promptAction } from '@kit.ArkUI';
import { updateManager } from '@kit.AppGalleryKit';
import { APP_NAME, PAGE_BG, PRIMARY_COLOR, PURPLE_COLOR, TEXT_MUTED, TEXT_PRIMARY, TOOLS } from '../../constants/AppConstants';
import { AppContext } from '../../services/AppContext';
import { FileService } from '../../services/FileService';
import { HistoryService } from '../../services/HistoryService';

@Component
export struct MinePage {
  @State recordCount: number = 0;
  @State checkingUpdate: boolean = false;
  onOpenUsage: () => void = () => {};
  onOpenPrivacy: () => void = () => {};

  async aboutToAppear(): Promise<void> {
    this.recordCount = (await HistoryService.getRecords()).length;
  }

  async cleanFiles(): Promise<void> {
    FileService.clearTempFiles();
    await HistoryService.clearRecords();
    this.recordCount = 0;
    promptAction.showToast({ message: '已清理缓存和处理记录' });
  }

  async checkUpdate(): Promise<void> {
    if (this.checkingUpdate) {
      return;
    }

    this.checkingUpdate = true;
    try {
      const context = AppContext.getContext();
      const result = await updateManager.checkAppUpdate(context);
      if (result.updateAvailable === updateManager.UpdateAvailableCode.LATER_VERSION_EXIST) {
        const showResult = await updateManager.showUpdateDialog(context);
        if (showResult === updateManager.ShowUpdateResultCode.SHOW_DIALOG_SUCCESS) {
          promptAction.showToast({ message: '已打开应用商店更新页' });
        } else {
          promptAction.showToast({ message: '更新页打开失败' });
        }
        return;
      }

      promptAction.showToast({ message: '当前已是最新版本' });
    } catch (error) {
      promptAction.showToast({ message: '检测更新失败，请稍后重试' });
    } finally {
      this.checkingUpdate = false;
    }
  }

  @Builder
  MenuItem(mark: string, title: string, desc: string, danger: boolean, onClick: () => void, disabled: boolean = false) {
    Row({ space: 12 }) {
      Text(mark)
        .width(34)
        .height(34)
        .borderRadius(8)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(danger ? '#D92D20' : PRIMARY_COLOR)
        .textAlign(TextAlign.Center)
        .backgroundColor(danger ? '#FFF0F0' : '#EEF3FF')
      Column({ space: 4 }) {
        Text(title)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_PRIMARY)
        Text(desc)
          .fontSize(12)
          .fontColor(TEXT_MUTED)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Text('>')
        .fontSize(18)
        .fontColor('#A1ABC0')
    }
    .width('100%')
    .height(70)
    .opacity(disabled ? 0.55 : 1)
    .enabled(!disabled)
    .onClick(() => {
      if (!disabled) {
        onClick();
      }
    })
  }

  build() {
    Scroll() {
      Column({ space: 22 }) {
        Column({ space: 18 }) {
          Row({ space: 14 }) {
            Text('PDF')
              .width(58)
              .height(58)
              .borderRadius(12)
              .fontSize(17)
              .fontWeight(FontWeight.Bold)
              .fontColor(PRIMARY_COLOR)
              .textAlign(TextAlign.Center)
              .backgroundColor(Color.White)
            Column({ space: 6 }) {
              Text(APP_NAME)
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
              Text('PDF、图片、Office 文档处理助手')
                .fontSize(13)
                .fontColor('#EAF1FF')
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
          }

          Row() {
            Column({ space: 6 }) {
              Text(`${TOOLS.length}`)
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
              Text('工具数量')
                .fontSize(12)
                .fontColor('#EAF1FF')
            }
            .layoutWeight(1)
            Column({ space: 6 }) {
              Text(`${this.recordCount}`)
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
              Text('处理记录')
                .fontSize(12)
                .fontColor('#EAF1FF')
            }
            .layoutWeight(1)
          }
          .width('100%')
        }
        .width('100%')
        .padding(18)
        .borderRadius(8)
        .linearGradient({ angle: 135, colors: [[PRIMARY_COLOR, 0], [PURPLE_COLOR, 1]] })

        Column({ space: 10 }) {
          Text('帮助与支持')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_PRIMARY)
            .width('100%')
          Column() {
            this.MenuItem('?', '使用说明', '查看完整操作流程、文件选择、保存方式和常见使用习惯。', false, () => this.onOpenUsage())
            this.MenuItem('i', '隐私说明', '了解文件处理边界、权限使用、数据留存和鸿蒙隐私要求。', false, () => this.onOpenPrivacy())
            this.MenuItem('更', this.checkingUpdate ? '正在检测更新' : '检测更新', '检查新版本并跳转到应用商店更新。', false, () => this.checkUpdate(), this.checkingUpdate)
          }
          .width('100%')
          .padding({ left: 14, right: 14 })
          .borderRadius(8)
          .backgroundColor(Color.White)
        }

        Column({ space: 10 }) {
          Text('数据管理')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_PRIMARY)
            .width('100%')
          Column() {
            this.MenuItem('!', '文件清理', '清理缓存、临时文件和处理记录。', true, () => this.cleanFiles())
            this.MenuItem('A', '关于', `${APP_NAME} 1.0.0，面向日常办公和学习资料整理。`, false, () => promptAction.showToast({ message: `${APP_NAME} 1.0.0` }))
          }
          .width('100%')
          .padding({ left: 14, right: 14 })
          .borderRadius(8)
          .backgroundColor(Color.White)
        }
      }
      .padding({ left: 16, right: 16, top: 44, bottom: 16 })
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(PAGE_BG)
  }
}
