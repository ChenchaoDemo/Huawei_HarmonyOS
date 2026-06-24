import { PRIMARY_COLOR, TEXT_MUTED, TEXT_PRIMARY } from '../constants/AppConstants';
import { ProcessResultView } from '../models/ToolModels';
import { formatFileSize } from '../utils/FormatUtils';

@Component
export struct ResultPanel {
  @Prop result: ProcessResultView | undefined = undefined;
  onOpen: () => void = () => {};
  onSave: () => void = () => {};
  onShare: () => void = () => {};

  @Builder
  ActionButton(text: string, primary: boolean, onClick: () => void) {
    Button(text)
      .height(38)
      .fontSize(13)
      .fontWeight(FontWeight.Bold)
      .fontColor(primary ? Color.White : '#52607A')
      .backgroundColor(primary ? PRIMARY_COLOR : Color.Transparent)
      .borderRadius(8)
      .layoutWeight(1)
      .onClick(onClick)
  }

  build() {
    if (this.result) {
      Column({ space: 12 }) {
        Text('处理成功')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_PRIMARY)
        Text(this.result.summary)
          .fontSize(13)
          .fontColor('#52607A')
          .textAlign(TextAlign.Center)
          .width('100%')
        Column({ space: 8 }) {
          this.MetaRow('文件名', this.result.name)
          this.MetaRow('大小', formatFileSize(this.result.size))
          this.MetaRow('耗时', `${this.result.duration}ms`)
        }
        .width('100%')
        .padding(12)
        .borderRadius(8)
        .backgroundColor('#F6F8FC')

        Row({ space: 8 }) {
          this.ActionButton('预览', false, this.onOpen)
          this.ActionButton('保存', true, this.onSave)
          this.ActionButton('分享', false, this.onShare)
        }
        .width('100%')
        .padding(6)
        .borderRadius(10)
        .backgroundColor('#F8FAFF')
      }
      .width('100%')
      .padding(18)
      .borderRadius(8)
      .backgroundColor(Color.White)
      .shadow({ radius: 10, color: '#1023355C', offsetY: 3 })
    }
  }

  @Builder
  MetaRow(label: string, value: string) {
    Row({ space: 12 }) {
      Text(label)
        .fontSize(12)
        .fontColor(TEXT_MUTED)
        .width(64)
      Text(value)
        .fontSize(12)
        .fontColor('#52607A')
        .layoutWeight(1)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
  }
}
