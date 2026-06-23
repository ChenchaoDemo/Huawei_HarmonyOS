import { promptAction } from '@kit.ArkUI';
import { PAGE_BG, PRIMARY_COLOR, TEXT_MUTED, TEXT_PRIMARY } from '../../constants/AppConstants';
import { HistoryRecord } from '../../models/ToolModels';
import { FileService } from '../../services/FileService';
import { HistoryService } from '../../services/HistoryService';

@Component
export struct HistoryPage {
  @State records: HistoryRecord[] = [];

  async aboutToAppear(): Promise<void> {
    await this.refresh();
  }

  async refresh(): Promise<void> {
    this.records = await HistoryService.getRecords();
  }

  async remove(id: string): Promise<void> {
    await HistoryService.removeRecord(id);
    await this.refresh();
    promptAction.showToast({ message: '已删除记录' });
  }

  async clearAll(): Promise<void> {
    if (!this.records.length) {
      promptAction.showToast({ message: '暂无可清空的记录' });
      return;
    }
    await HistoryService.clearRecords();
    await this.refresh();
    promptAction.showToast({ message: '已清空记录' });
  }

  async saveRecordFile(record: HistoryRecord): Promise<void> {
    try {
      await FileService.saveToPicker(record.resultPath, record.resultFileName);
      promptAction.showToast({ message: '保存成功' });
    } catch (error) {
      promptAction.showToast({ message: `保存失败：${JSON.stringify(error)}` });
    }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Row() {
          Column({ space: 6 }) {
            Text('处理记录')
              .fontSize(26)
              .fontWeight(FontWeight.Bold)
              .fontColor(TEXT_PRIMARY)
            Text('查看近期处理结果和操作记录')
              .fontSize(13)
              .fontColor(TEXT_MUTED)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Button('清空')
            .height(38)
            .fontSize(13)
            .fontColor(PRIMARY_COLOR)
            .backgroundColor('#EEF3FF')
            .onClick(() => this.clearAll())
        }
        .width('100%')

        if (this.records.length > 0) {
          ForEach(this.records, (record: HistoryRecord) => {
            Column({ space: 10 }) {
              Row() {
                Column({ space: 4 }) {
                  Text(record.toolName)
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(TEXT_PRIMARY)
                  Text(record.resultFileName)
                    .fontSize(12)
                    .fontColor('#52607A')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(`${record.createTime} · ${record.fileSize}`)
                    .fontSize(11)
                    .fontColor(TEXT_MUTED)
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
              }
              Row({ space: 8 }) {
                Button('打开')
                  .height(36)
                  .fontSize(12)
                  .fontColor(PRIMARY_COLOR)
                  .backgroundColor('#EAF1FF')
                  .layoutWeight(1)
                  .onClick(() => promptAction.showToast({ message: `结果路径：${record.resultPath}` }))
                Button('保存')
                  .height(36)
                  .fontSize(12)
                  .fontColor(Color.White)
                  .backgroundColor(PRIMARY_COLOR)
                  .layoutWeight(1)
                  .onClick(() => this.saveRecordFile(record))
                Button('分享')
                  .height(36)
                  .fontSize(12)
                  .fontColor(PRIMARY_COLOR)
                  .backgroundColor('#EAF1FF')
                  .layoutWeight(1)
                  .onClick(() => promptAction.showToast({ message: '系统分享入口待接入' }))
                Button('删除')
                  .height(36)
                  .fontSize(12)
                  .fontColor('#D92D20')
                  .backgroundColor('#FFF0F0')
                  .layoutWeight(1)
                  .onClick(() => this.remove(record.id))
              }
            }
            .width('100%')
            .padding(14)
            .borderRadius(8)
            .backgroundColor(Color.White)
            .shadow({ radius: 10, color: '#1023355C', offsetY: 3 })
          }, (record: HistoryRecord) => record.id)
        } else {
          Column({ space: 8 }) {
            Text('暂无处理记录')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(TEXT_PRIMARY)
            Text('完成文件处理后会自动保存记录')
              .fontSize(13)
              .fontColor(TEXT_MUTED)
          }
          .width('100%')
          .height(220)
          .justifyContent(FlexAlign.Center)
          .backgroundColor(Color.White)
          .borderRadius(8)
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
