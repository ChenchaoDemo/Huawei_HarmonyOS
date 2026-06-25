import { promptAction, router } from '@kit.ArkUI';
import { PdfView, pdfService, pdfViewManager } from '@kit.PDFKit';
import { PAGE_BG, PRIMARY_COLOR, TEXT_MUTED, TEXT_PRIMARY } from '../../constants/AppConstants';
import { FilePreviewRouteParams, PreviewSourceFile } from '../../models/ToolModels';
import { FilePreviewService } from '../../services/FilePreviewService';
import { ShareService } from '../../services/ShareService';
import { generateId } from '../../utils/FormatUtils';

@Entry
@Component
struct FilePreviewPage {
  private pdfController: pdfViewManager.PdfController = new pdfViewManager.PdfController();
  @State name: string = '预览文件';
  @State path: string = '';
  @State summary: string = '';
  @State previewUri: string = '';
  @State canUsePreview: boolean = false;
  @State previewState: string = '正在准备预览';
  @State error: string = '';
  @State sources: PreviewSourceFile[] = [];
  @State textPreview: string = '';
  @State autoOpen: boolean = false;
  @State pdfLoading: boolean = false;
  @State pdfLoaded: boolean = false;
  @State pdfLoadProgress: number = 0;
  @State pdfLoadError: string = '';
  @State pdfReaderPath: string = '';

  async aboutToAppear(): Promise<void> {
    const params = router.getParams() as FilePreviewRouteParams;
    this.name = params?.name || '预览文件';
    this.path = params?.path || '';
    this.summary = params?.summary || '';
    this.sources = this.normalizeSources(params?.sources || []);
    this.textPreview = (params?.textPreview || '').slice(0, 5000);
    this.autoOpen = params?.autoOpen || false;

    try {
      this.previewUri = this.path.length > 0 ? FilePreviewService.toPreviewUri(this.path) : '';
      if (!this.textPreview.length && FilePreviewService.isText(this.name) && this.path.length > 0) {
        this.textPreview = FilePreviewService.readTextPreview(this.path, 5000);
      }
      try {
        this.canUsePreview = this.path.length > 0 ? await FilePreviewService.canPreview({ name: this.name, path: this.path }) : false;
      } catch (_) {
        this.canUsePreview = false;
      }
      this.previewState = this.canUsePreview ? '可使用系统预览打开完整文件' : '当前系统暂不支持直接打开此文件';
      if (this.isPdfFile() && this.path.length > 0) {
        try {
          this.pdfReaderPath = FilePreviewService.preparePdfReaderPath({ name: this.name, path: this.path });
          setTimeout(() => this.loadPdfDocument(), 0);
        } catch (err) {
          this.pdfLoadError = this.errText(err as Error | Object);
          this.previewState = 'PDF 准备失败';
        }
        return;
      }
      if (this.autoOpen && this.path.length > 0) {
        await this.openSystemPreview(false);
      }
    } catch (err) {
      this.canUsePreview = false;
      this.error = this.errText(err as Error | Object);
      this.previewState = '预览准备失败';
    }
  }

  aboutToDisappear(): void {
    try {
      this.pdfController.releaseDocument();
    } catch (_) {
    }
    FilePreviewService.cleanupPreparedPdfPath(this.pdfReaderPath);
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
      return FilePreviewService.isImage(source.name) || FilePreviewService.isImage(source.uri);
    });
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

  private isPdfFile(): boolean {
    return FilePreviewService.isPdfFile(this.name, this.path);
  }

  private isImageFile(): boolean {
    return FilePreviewService.isImage(this.name) || FilePreviewService.isImage(this.path);
  }

  private parseResultText(result: pdfService.ParseResult): string {
    if (result === pdfService.ParseResult.PARSE_ERROR_FILE) {
      return 'PDF 文件无法读取';
    }
    if (result === pdfService.ParseResult.PARSE_ERROR_FORMAT) {
      return 'PDF 格式暂不支持';
    }
    if (result === pdfService.ParseResult.PARSE_ERROR_PASSWORD) {
      return 'PDF 需要密码或密码错误';
    }
    if (result === pdfService.ParseResult.PARSE_ERROR_CERT) {
      return 'PDF 证书校验失败';
    }
    return 'PDF 加载失败';
  }

  private async loadPdfDocument(): Promise<void> {
    const loadPath = this.pdfReaderPath.length > 0 ? this.pdfReaderPath : this.path;
    if (this.pdfLoading || this.pdfLoaded || !loadPath.length) {
      return;
    }
    this.pdfLoading = true;
    this.pdfLoadError = '';
    this.pdfLoadProgress = 0;
    try {
      this.pdfController.enablePageDrag(true, false);
      this.pdfController.setPageLayout(pdfService.PageLayout.LAYOUT_SINGLE);
      this.pdfController.setPageContinuous(true);
      this.pdfController.setPageFit(pdfService.PageFit.FIT_WIDTH);
      this.pdfController.setPageSpacing(0, 12);
      try {
        this.pdfController.setDisplayDirection(pdfViewManager.DisplayDirection.VERTICAL);
        const selfOnly = pdfViewManager.PdfNestedScrollMode.SELF_ONLY;
        this.pdfController.setNestedScroll({
          scrollUp: selfOnly,
          scrollDown: selfOnly,
          scrollLeft: selfOnly,
          scrollRight: selfOnly
        });
      } catch (_) {
      }
      const result = await this.pdfController.loadDocument(loadPath, '', 0, (progress: number) => {
        this.pdfLoadProgress = progress;
      });
      if (result === pdfService.ParseResult.PARSE_SUCCESS) {
        this.pdfLoaded = true;
        this.pdfLoadProgress = 100;
        this.previewState = 'PDF 已加载';
      } else {
        this.pdfLoadError = this.parseResultText(result);
        this.previewState = this.pdfLoadError;
      }
    } catch (err) {
      this.pdfLoadError = this.errText(err as Error | Object);
      this.previewState = 'PDF 加载失败';
    } finally {
      this.pdfLoading = false;
    }
  }

  private titleText(): string {
    if (this.isPdfFile()) {
      return 'PDF 预览';
    }
    if (this.isImageFile()) {
      return '图片预览';
    }
    if (this.textPreview.trim().length > 0) {
      return '文本预览';
    }
    return '文件预览';
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
  ImagePreview() {
    Stack() {
      Image(this.previewUri)
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Contain)
    }
      .width('100%')
      .height('100%')
  }

  @Builder
  SourceImagePage(source: PreviewSourceFile, index: number) {
    Stack({ alignContent: Alignment.TopStart }) {
      Image(FilePreviewService.toPreviewUri(source.uri))
        .width('100%')
        .height(680)
        .objectFit(ImageFit.Contain)
        .backgroundColor(Color.White)
      Text(`${index + 1}`)
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .borderRadius(6)
        .backgroundColor('#17213DCC')
        .margin({ left: 8, top: 8 })
    }
    .width('100%')
    .height(680)
    .backgroundColor(Color.White)
    .border({ width: 1, color: '#E3E8F2' })
    .shadow({ radius: 10, color: '#0F233522', offsetY: 3 })
  }

  @Builder
  PdfImagePreview() {
    Column({ space: 12 }) {
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
        .height(680)
        .fontSize(13)
        .fontColor('#33405F')
        .lineHeight(21)
        .padding(18)
        .backgroundColor(Color.White)
        .border({ width: 1, color: '#E3E8F2' })
        .shadow({ radius: 10, color: '#0F233522', offsetY: 3 })
    }
    .width('100%')
  }

  @Builder
  GenericPreview() {
    Column({ space: 14 }) {
      Text(this.extText())
        .width(84)
        .height(84)
        .borderRadius(12)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .textAlign(TextAlign.Center)
        .backgroundColor(PRIMARY_COLOR)

      Text(this.name)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(TEXT_PRIMARY)
        .maxLines(2)
        .textAlign(TextAlign.Center)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(this.previewState)
        .fontSize(13)
        .fontColor(TEXT_MUTED)
        .textAlign(TextAlign.Center)
        .lineHeight(20)
    }
    .width('100%')
    .height(680)
    .padding({ left: 18, right: 18 })
    .justifyContent(FlexAlign.Center)
    .backgroundColor(Color.White)
    .border({ width: 1, color: '#E3E8F2' })
    .shadow({ radius: 10, color: '#0F233522', offsetY: 3 })
    .onClick(() => this.openSystemPreview())
  }

  @Builder
  PreviewBody() {
    if (this.isImageFile() && this.previewUri.length > 0) {
      this.ImagePreview()
    } else if (this.isPdfFile() && this.sourceImages().length > 0) {
      this.PdfImagePreview()
    } else if (this.textPreview.trim().length > 0) {
      this.TextPreview()
    } else {
      this.GenericPreview()
    }
  }

  @Builder
  PdfReader() {
    Stack() {
      PdfView({
        controller: this.pdfController,
        pageLayout: pdfService.PageLayout.LAYOUT_SINGLE,
        isContinuous: true,
        showScroll: true,
        pageFit: pdfService.PageFit.FIT_WIDTH
      })
        .width('100%')
        .height('100%')
        .backgroundColor('#DCE2EA')

      if (!this.pdfLoaded && this.pdfLoadError.length === 0) {
        Column({ space: 10 }) {
          Text(this.pdfLoading ? `正在打开 PDF ${this.pdfLoadProgress}%` : '正在准备 PDF')
            .fontSize(14)
            .fontColor(TEXT_MUTED)
        }
        .padding({ left: 18, right: 18, top: 14, bottom: 14 })
        .borderRadius(8)
        .backgroundColor('#FFFFFFE6')
      }

      if (this.pdfLoadError.length > 0) {
        Column({ space: 12 }) {
          Text(this.pdfLoadError)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_PRIMARY)
          Button('使用系统预览')
            .height(38)
            .fontSize(13)
            .fontColor(Color.White)
            .backgroundColor(PRIMARY_COLOR)
            .borderRadius(8)
            .onClick(() => this.openSystemPreview())
        }
        .padding(18)
        .borderRadius(8)
        .backgroundColor(Color.White)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#DCE2EA')
  }

  build() {
    Column() {
      Row({ space: 10 }) {
        Button('‹')
          .width(44)
          .height(44)
          .fontSize(22)
          .fontColor(PRIMARY_COLOR)
          .backgroundColor('#EEF3FF')
          .onClick(() => router.back())
        Column({ space: 4 }) {
          Text(this.titleText())
            .fontSize(21)
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
        Button('分享')
          .height(40)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(PRIMARY_COLOR)
          .backgroundColor('#EEF3FF')
          .enabled(this.path.length > 0)
          .onClick(() => this.shareFile())
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 18, bottom: 10 })
      .backgroundColor(PAGE_BG)

      if (this.isPdfFile()) {
        Column() {
          this.PdfReader()
        }
        .width('100%')
        .layoutWeight(1)
        .clip(true)
      } else if (this.isImageFile() && this.previewUri.length > 0) {
        Column() {
          this.ImagePreview()
        }
        .width('100%')
        .layoutWeight(1)
      } else {
        Scroll() {
          Column({ space: 12 }) {
            this.PreviewBody()
          }
          .padding({ left: 18, right: 18, top: 18, bottom: 28 })
          .width('100%')
        }
        .layoutWeight(1)
        .backgroundColor('#DCE2EA')
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(PAGE_BG)
  }
}
