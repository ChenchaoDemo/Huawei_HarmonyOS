import { PRIMARY_COLOR, TEXT_MUTED, TEXT_PRIMARY } from '../constants/AppConstants';
import { PickedFile } from '../models/ToolModels';
import { formatFileSize } from '../utils/FormatUtils';

@Component
export struct FilePickerPanel {
  @Prop title: string = '选择文件';
  @Prop desc: string = '点击选择文件';
  @Prop files: PickedFile[] = [];
  onPick: () => void = () => {};
  onPreview: (file: PickedFile) => void = () => {};
  onMove: (index: number, step: number) => void = () => {};
  onRemove: (index: number) => void = () => {};

  @Builder
  MiniAction(text: string, color: string, onClick: () => void) {
    Text(text)
      .height(32)
      .fontSize(12)
      .fontColor(color)
      .textAlign(TextAlign.Center)
      .padding({ left: 8, right: 8, top: 5, bottom: 5 })
      .borderRadius(6)
      .backgroundColor(color === '#D92D20' ? '#FFF0F0' : '#EAF1FF')
      .onClick(onClick)
  }

  build() {
    Column({ space: 12 }) {
      Column({ space: 8 }) {
        Text('+')
          .width(48)
          .height(48)
          .borderRadius(24)
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)
          .backgroundColor(PRIMARY_COLOR)
        Text(this.files.length ? '继续选择文件' : this.title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_PRIMARY)
        Text(this.desc)
          .fontSize(12)
          .fontColor(TEXT_MUTED)
      }
      .width('100%')
      .height(140)
      .justifyContent(FlexAlign.Center)
      .border({ width: 1, color: '#B9C8EA', style: BorderStyle.Dashed })
      .borderRadius(8)
      .backgroundColor('#FBFCFF')
      .onClick(this.onPick)

      if (this.files.length > 0) {
        Column({ space: 10 }) {
          ForEach(this.files, (file: PickedFile, index: number) => {
            Row({ space: 10 }) {
              Column({ space: 4 }) {
                Text(file.name)
                  .fontSize(14)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(TEXT_PRIMARY)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(`${file.type} · ${formatFileSize(file.size)}`)
                  .fontSize(11)
                  .fontColor(TEXT_MUTED)
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              Row({ space: 6 }) {
                this.MiniAction('预览', PRIMARY_COLOR, () => this.onPreview(file))
                this.MiniAction('上移', PRIMARY_COLOR, () => this.onMove(index, -1))
                this.MiniAction('下移', PRIMARY_COLOR, () => this.onMove(index, 1))
                this.MiniAction('删除', '#D92D20', () => this.onRemove(index))
              }
            }
            .width('100%')
            .padding(10)
            .borderRadius(8)
            .backgroundColor('#F5F7FC')
          }, (file: PickedFile) => file.id)
        }
        .width('100%')
      }
    }
    .width('100%')
  }
}
