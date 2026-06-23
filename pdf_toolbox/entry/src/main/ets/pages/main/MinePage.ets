import { promptAction } from '@kit.ArkUI';
import { APP_NAME, PAGE_BG, PRIMARY_COLOR, PURPLE_COLOR, TEXT_MUTED, TEXT_PRIMARY, TOOLS } from '../../constants/AppConstants';
import { FileService } from '../../services/FileService';
import { HistoryService } from '../../services/HistoryService';

@Component
export struct MinePage {
  @State recordCount: number = 0;

  async aboutToAppear(): Promise<void> {
    this.recordCount = (await HistoryService.getRecords()).length;
  }

  async cleanFiles(): Promise<void> {
    FileService.clearTempFiles();
    await HistoryService.clearRecords();
    this.recordCount = 0;
    promptAction.showToast({ message: '已清理缓存和记录' });
  }

  @Builder
  MenuItem(mark: string, title: string, desc: string, danger: boolean, onClick: () => void) {
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
      Text('›')
        .fontSize(24)
        .fontColor('#A1ABC0')
    }
    .width('100%')
    .height(70)
    .onClick(onClick)
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
            this.MenuItem('?', '使用说明', '选择工具、添加文件、设置参数后开始处理，结果可保存到系统文件位置。', false, () => promptAction.showToast({ message: '使用说明页面占位' }))
            this.MenuItem('i', '隐私说明', '文件优先在本机沙箱处理，服务端能力接入前不会上传转换文件。', false, () => promptAction.showToast({ message: '隐私说明页面占位' }))
            this.MenuItem('FB', '意见反馈', '反馈入口占位，后续可接入邮件、客服或表单。', false, () => promptAction.showToast({ message: '意见反馈入口待接入' }))
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
