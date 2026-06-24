import { promptAction, router } from '@kit.ArkUI';
import { PAGE_BG, PRIMARY_COLOR, TEXT_MUTED, TEXT_PRIMARY } from '../../constants/AppConstants';
import { FilePreviewRouteParams, PreviewSourceFile } from '../../models/ToolModels';
import { FilePreviewService } from '../../services/FilePreviewService';
import { FileService } from '../../services/FileService';
import { ShareService } from '../../services/ShareService';
import { formatFileSize, generateId } from '../../utils/FormatUtils';

@Entry
@Component
struct FilePreviewPage {
  @State name: string = '预览文件';
  @State path: string = '';
  @State fileSize: number = 0;
  @State fileSizeText: string = '';
  @State summary: string = '';
  @State toolName: string = '';
  @State previewUri: string = '';
  @State mimeType: string = 'application/octet-stream';
  @State canUsePreview: boolean = false;
  @State previewState: string = '正在准备预览';
  @State error: string = '';
  @State sources: PreviewSourceFile[] = [];
  @State textPreview: string = '';
  @State pageCount: number = 0;

  async aboutToAppear(): Promise<void> {
    const params = router.getParams() as FilePreviewRouteParams;
    this.name = params?.name || '预览文件';
    this.path = params?.path || '';
    this.fileSize = params?.size || 0;
    this.fileSizeText = params?.sizeText || '';
    this.summary = params?.summary || '';
    this.toolName = params?.toolName || '';
    this.sources = this.normalizeSources(params?.sources || []);
    this.textPreview = (params?.textPreview || '').slice(0, 5000);
    this.mimeType = FilePreviewService.mimeType(this.name);

    try {
      this.previewUri = this.path.length > 0 ? FilePreviewService.toPreviewUri(this.path) : '';
      if (!this.textPreview.length && FilePreviewService.isText(this.name) && this.path.length > 0) {
        this.textPreview = FilePreviewService.readTextPreview(this.path, 5000);
      }
      this.pageCount = this.sourceImages().length > 0 ? this.sourceImages().length : (FilePreviewService.isPdf(this.name) && this.path.length > 0 ? FilePreviewService.estimatePdfPageCount(this.path) : 0);
      this.canUsePreview = this.path.length > 0 ? await FilePreviewService.canPreview({ name: this.name, path: this.path }) : false;
      this.previewState = this.canUsePreview ? '可使用系统预览打开完整文件' : '当前系统暂不支持直接打开此文件';
    } catch (err) {
      this.canUsePreview = false;
      this.error = this.errText(err as Error | Object);
      this.previewState = '预览准备失败';
    }
  }

  private normalizeSources(sources: PreviewSourceFile[]): PreviewSourceFile[] {
    return sources.map((source: PreviewSourceFile, index: number): PreviewSourceFile => {
      const ext = source.ext || FilePreviewService.ext(source.name || '');
      return {
        id: source.id || generateId('preview'),
        name: source.name || `来源文件${index + 1}`,
        uri: source.uri || '',
        size: source.size || 0,
        ext,
        type: source.type || (ext ? ext.toUpperCase() : 'FILE')
      };
    }).filter((source: PreviewSourceFile) => source.uri.length > 0);
  }

  private sourceImages(): PreviewSourceFile[] {
    return this.sources.filter((source: PreviewSourceFile) => {
      const ext = (source.ext || FilePreviewService.ext(source.name)).toLowerCase();
      return FilePreviewService.isImage(source.name) || ext === 'jpg' || ext === 'jpeg' || ext === 'png' || ext === 'webp';
    });
  }

  private nonImageSources(): PreviewSourceFile[] {
    return this.sources.filter((source: PreviewSourceFile) => !this.sourceImages().some((image: PreviewSourceFile) => image.id === source.id));
  }

  private extText(): string {
    const ext = FilePreviewService.ext(this.name);
    return ext.length ? ext.toUpperCase() : 'FILE';
  }

  private errText(err: Error | Object): string {
    if (err instanceof Error) {
      return err.message;
    }
    return JSON.stringify(err);
  }

  private titleText(): string {
    if (FilePreviewService.isPdf(this.name) && this.sourceImages().length > 0) {
      return 'PDF 页面预览';
    }
    if (FilePreviewService.isImage(this.name)) {
      return '图片预览';
    }
    if (this.textPreview.trim().length > 0) {
      return '文本预览';
    }
    return '文件预览';
  }

  private subtitleText(): string {
    if (this.toolName.length > 0) {
      return this.toolName;
    }
    return FilePreviewService.displayType(this.name);
  }

  async openSystemPreview(showToast: boolean = true): Promise<void> {
    if (!this.path.length) {
      promptAction.showToast({ message: '没有可预览的文件' });
      return;
    }
    try {
      await FilePreviewService.openPreview({ name: this.name, path: this.path });
      this.error = '';
      this.previewState = '系统预览已打开';
      if (showToast) {
        promptAction.showToast({ message: '已打开系统预览' });
      }
    } catch (err) {
      this.error = this.errText(err as Error | Object);
      this.previewState = '系统预览打开失败';
      if (showToast) {
        promptAction.showToast({ message: this.error });
      }
    }
  }

  async saveFile(): Promise<void> {
    if (!this.path.length) {
      promptAction.showToast({ message: '没有可保存的文件' });
      return;
    }
    try {
      await FileService.saveToPicker(this.path, this.name);
      promptAction.showToast({ message: '保存成功' });
    } catch (err) {
      promptAction.showToast({ message: `保存失败：${this.errText(err as Error | Object)}` });
    }
  }

  async shareFile(): Promise<void> {
    if (!this.path.length) {
      promptAction.showToast({ message: '没有可分享的文件' });
      return;
    }
    try {
      await ShareService.shareFile({
        name: this.name,
        path: this.path,
        summary: this.summary
      });
    } catch (err) {
      promptAction.showToast({ message: `分享失败：${this.errText(err as Error | Object)}` });
    }
  }

  @Builder
  ActionButton(label: string, primary: boolean, enabled: boolean, onClick: () => void) {
    Button(label)
      .height(42)
      .fontSize(14)
      .fontWeight(FontWeight.Bold)
      .fontColor(enabled ? (primary ? Color.White : PRIMARY_COLOR) : TEXT_MUTED)
      .backgroundColor(enabled ? (primary ? PRIMARY_COLOR : '#EEF3FF') : '#EEF0F5')
      .borderRadius(8)
      .layoutWeight(1)
      .enabled(enabled)
      .onClick(onClick)
  }

  @Builder
  MetaRow(label: string, value: string) {
    Row({ space: 12 }) {
      Text(label)
        .width(64)
        .fontSize(12)
        .fontColor(TEXT_MUTED)
      Text(value)
        .layoutWeight(1)
        .fontSize(12)
        .fontColor('#52607A')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
  }

  @Builder
  ImagePreview() {
    Column({ space: 10 }) {
      Image(this.previewUri)
        .width('100%')
        .height(430)
        .objectFit(ImageFit.Contain)
        .borderRadius(8)
        .backgroundColor('#F1F4FB')
      Text('图片可在当前页面直接查看，保存后也可在系统相册或文件管理中打开。')
        .fontSize(12)
        .fontColor(TEXT_MUTED)
        .lineHeight(18)
    }
    .width('100%')
  }

  @Builder
  SourceImagePage(source: PreviewSourceFile, index: number) {
    Column({ space: 8 }) {
      Stack({ alignContent: Alignment.TopStart }) {
        Image(FilePreviewService.toPreviewUri(source.uri))
          .width('100%')
          .height(220)
          .objectFit(ImageFit.Contain)
          .borderRadius(8)
          .backgroundColor('#F1F4FB')
        Text(`第 ${index + 1} 页`)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(6)
          .backgroundColor('#17213DCC')
          .margin({ left: 8, top: 8 })
      }
      .width('100%')
      .height(220)

      Text(source.name)
        .width('100%')
        .fontSize(12)
        .fontColor('#52607A')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding(10)
    .borderRadius(8)
    .backgroundColor('#F8FAFF')
    .border({ width: 1, color: '#E2E9F5' })
  }

  @Builder
  PdfImagePreview() {
    Column({ space: 12 }) {
      Row() {
        Text('生成 PDF 页面')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_PRIMARY)
          .layoutWeight(1)
        Text(`${this.sourceImages().length} 页`)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(PRIMARY_COLOR)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(6)
          .backgroundColor('#EEF3FF')
      }
      .width('100%')

      ForEach(this.sourceImages(), (source: PreviewSourceFile, index: number) => {
        this.SourceImagePage(source, index)
      }, (source: PreviewSourceFile) => source.id)
    }
    .width('100%')
  }

  @Builder
  TextPreview() {
    Column({ space: 10 }) {
      Text(this.textPreview)
        .width('100%')
        .fontSize(13)
        .fontColor('#33405F')
        .lineHeight(21)
        .padding(14)
        .borderRadius(8)
        .backgroundColor('#F8FAFF')
      if (this.textPreview.length >= 5000) {
        Text('仅展示前 5000 个字符，完整内容请使用系统预览或保存后打开。')
          .fontSize(12)
          .fontColor(TEXT_MUTED)
      }
    }
    .width('100%')
  }

  @Builder
  GenericPreview() {
    Column({ space: 14 }) {
      Text(this.extText())
        .width(76)
        .height(76)
        .borderRadius(18)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .textAlign(TextAlign.Center)
        .backgroundColor(PRIMARY_COLOR)

      Text(FilePreviewService.displayType(this.name))
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(TEXT_PRIMARY)

      if (FilePreviewService.isPdf(this.name) && this.pageCount > 0) {
        Text(`检测到约 ${this.pageCount} 页`)
          .fontSize(13)
          .fontColor(PRIMARY_COLOR)
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .borderRadius(6)
          .backgroundColor('#EEF3FF')
      }

      Text(this.previewState)
        .fontSize(13)
        .fontColor(TEXT_MUTED)
        .textAlign(TextAlign.Center)
        .lineHeight(20)
    }
    .width('100%')
    .padding({ top: 32, bottom: 32, left: 18, right: 18 })
    .borderRadius(8)
    .backgroundColor('#F8FAFF')
  }

  @Builder
  PreviewBody() {
    if (FilePreviewService.isImage(this.name) && this.previewUri.length > 0) {
      this.ImagePreview()
    } else if (FilePreviewService.isPdf(this.name) && this.sourceImages().length > 0) {
      this.PdfImagePreview()
    } else if (this.textPreview.trim().length > 0) {
      this.TextPreview()
    } else {
      this.GenericPreview()
    }
  }

  @Builder
  SourceFileList() {
    if (this.nonImageSources().length > 0) {
      Column({ space: 10 }) {
        Text('来源文件')
          .width('100%')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_PRIMARY)

        ForEach(this.nonImageSources(), (source: PreviewSourceFile) => {
          Row({ space: 10 }) {
            Text((source.ext || FilePreviewService.ext(source.name) || 'FILE').toUpperCase())
              .width(42)
              .height(42)
              .borderRadius(9)
              .fontSize(10)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .textAlign(TextAlign.Center)
              .backgroundColor('#52607A')
            Column({ space: 4 }) {
              Text(source.name)
                .fontSize(13)
                .fontWeight(FontWeight.Bold)
                .fontColor(TEXT_PRIMARY)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(`${source.type} · ${formatFileSize(source.size)}`)
                .fontSize(11)
                .fontColor(TEXT_MUTED)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .padding(10)
          .borderRadius(8)
          .backgroundColor('#F8FAFF')
        }, (source: PreviewSourceFile) => source.id)
      }
      .width('100%')
      .padding(16)
      .borderRadius(8)
      .backgroundColor(Color.White)
    }
  }

  build() {
    Column() {
      Row({ space: 10 }) {
        Button('‹')
          .width(40)
          .height(40)
          .fontSize(22)
          .fontColor(PRIMARY_COLOR)
          .backgroundColor('#EEF3FF')
          .borderRadius(8)
          .onClick(() => router.back())
        Column({ space: 3 }) {
          Text(this.titleText())
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_PRIMARY)
          Text(this.name)
            .fontSize(12)
            .fontColor(TEXT_MUTED)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 10, bottom: 10 })

      Scroll() {
        Column({ space: 14 }) {
          Column({ space: 14 }) {
            Row() {
              Column({ space: 4 }) {
                Text(this.subtitleText())
                  .fontSize(15)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(TEXT_PRIMARY)
                Text(this.summary.length > 0 ? this.summary : '处理结果可保存到系统文件，也可调用系统支持的应用继续查看。')
                  .fontSize(12)
                  .fontColor(TEXT_MUTED)
                  .lineHeight(18)
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')

            this.PreviewBody()

            Row({ space: 10 }) {
              this.ActionButton('系统打开', true, this.path.length > 0 && this.canUsePreview, () => this.openSystemPreview())
              this.ActionButton('保存', false, this.path.length > 0, () => this.saveFile())
              this.ActionButton('分享', false, this.path.length > 0, () => this.shareFile())
            }
            .width('100%')
          }
          .width('100%')
          .padding(16)
          .borderRadius(8)
          .backgroundColor(Color.White)

          Column({ space: 10 }) {
            Text('文件信息')
              .width('100%')
              .fontSize(17)
              .fontWeight(FontWeight.Bold)
              .fontColor(TEXT_PRIMARY)
            this.MetaRow('文件名', this.name)
            this.MetaRow('类型', FilePreviewService.displayType(this.name))
            this.MetaRow('格式', this.mimeType)
            this.MetaRow('大小', this.fileSizeText.length > 0 ? this.fileSizeText : formatFileSize(this.fileSize))
            if (FilePreviewService.isPdf(this.name)) {
              this.MetaRow('页数', this.pageCount > 0 ? `${this.pageCount} 页` : '未知')
            }
            if (this.sources.length > 0) {
              this.MetaRow('来源', `${this.sources.length} 个文件`)
            }
            if (this.path.length > 0) {
              this.MetaRow('路径', this.path)
            }
          }
          .width('100%')
          .padding(16)
          .borderRadius(8)
          .backgroundColor(Color.White)

          this.SourceFileList()

          if (this.error.length > 0) {
            Column({ space: 8 }) {
              Text('预览失败')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#D92D20')
              Text(this.error)
                .fontSize(13)
                .fontColor('#8A3A35')
                .lineHeight(18)
            }
            .width('100%')
            .padding(14)
            .borderRadius(8)
            .backgroundColor('#FFF7F7')
          }
        }
        .padding({ left: 16, right: 16, bottom: 24 })
        .width('100%')
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(PAGE_BG)
  }
}
