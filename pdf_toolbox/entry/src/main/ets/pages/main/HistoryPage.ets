import { promptAction, router } from '@kit.ArkUI';
import { PAGE_BG, PRIMARY_COLOR, TEXT_MUTED, TEXT_PRIMARY } from '../../constants/AppConstants';
import { FilePreviewRouteParams, HistoryRecord } from '../../models/ToolModels';
import { FileService } from '../../services/FileService';
import { HistoryService } from '../../services/HistoryService';
import { ShareService } from '../../services/ShareService';

class FilePreviewRouterOptions {
  url: string = '';
  params?: Object;
}

@Component
export struct HistoryPage {
  @State records: HistoryRecord[] = [];
  @State keyword: string = '';
  @State selectedType: string = 'all';
  @State visibleCount: number = 10;

  async aboutToAppear(): Promise<void> {
    await this.refresh();
  }

  async refresh(): Promise<void> {
    this.records = await HistoryService.getRecords();
  }

  private resetPaging(): void {
    this.visibleCount = 10;
  }

  private fileText(record: HistoryRecord): string {
    return `${record.toolName} ${record.toolType} ${record.sourceFileName} ${record.resultFileName} ${record.status}`.toLowerCase();
  }

  private resultExt(record: HistoryRecord): string {
    const fileName = record.resultFileName.toLowerCase();
    const dotIndex = fileName.lastIndexOf('.');
    return dotIndex >= 0 ? fileName.substring(dotIndex + 1) : 'file';
  }

  private resultExtIn(record: HistoryRecord, extensions: string[]): boolean {
    return extensions.includes(this.resultExt(record));
  }

  private typeLabel(record: HistoryRecord): string {
    if (record.toolType === 'scan') {
      return '扫描件';
    }
    if (this.resultExtIn(record, ['pdf'])) {
      return 'PDF';
    }
    if (this.resultExtIn(record, ['jpg', 'jpeg', 'png', 'webp'])) {
      return '图片';
    }
    if (this.resultExtIn(record, ['doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'csv'])) {
      return 'Office';
    }
    if (this.resultExtIn(record, ['txt', 'md', 'log'])) {
      return '文本';
    }
    return this.resultExt(record).toUpperCase();
  }

  private typeColor(record: HistoryRecord): string {
    const label = this.typeLabel(record);
    if (label === 'PDF') {
      return PRIMARY_COLOR;
    }
    if (label === '图片') {
      return '#1F8A5B';
    }
    if (label === 'Office') {
      return '#7A4DCC';
    }
    if (label === '扫描件') {
      return '#0B7285';
    }
    return '#52607A';
  }

  private matchKeyword(record: HistoryRecord): boolean {
    const key = this.keyword.trim().toLowerCase();
    if (!key) {
      return true;
    }
    return this.fileText(record).includes(key);
  }

  private matchType(record: HistoryRecord): boolean {
    if (this.selectedType === 'all') {
      return true;
    }
    if (this.selectedType === 'pdf') {
      return this.resultExtIn(record, ['pdf']);
    }
    if (this.selectedType === 'image') {
      return this.resultExtIn(record, ['jpg', 'jpeg', 'png', 'webp']);
    }
    if (this.selectedType === 'office') {
      return this.resultExtIn(record, ['doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'csv']);
    }
    if (this.selectedType === 'text') {
      return this.resultExtIn(record, ['txt', 'md', 'log']);
    }
    if (this.selectedType === 'scan') {
      return record.toolType === 'scan';
    }
    return true;
  }

  private filteredRecords(): HistoryRecord[] {
    return this.records.filter((record: HistoryRecord) => this.matchKeyword(record) && this.matchType(record));
  }

  private visibleRecords(): HistoryRecord[] {
    return this.filteredRecords().slice(0, this.visibleCount);
  }

  private hasMore(): boolean {
    return this.visibleCount < this.filteredRecords().length;
  }

  private loadMore(): void {
    if (this.hasMore()) {
      this.visibleCount += 10;
    }
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
    this.resetPaging();
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

  async shareRecordFile(record: HistoryRecord): Promise<void> {
    try {
      await ShareService.shareFile({
        name: record.resultFileName,
        path: record.resultPath,
        summary: `${record.toolName} · ${record.createTime}`
      });
    } catch (error) {
      promptAction.showToast({ message: `分享失败：${JSON.stringify(error)}` });
    }
  }

  openRecordPreview(record: HistoryRecord): void {
    const options = new FilePreviewRouterOptions();
    options.url = 'pages/main/FilePreviewPage';
    const params: FilePreviewRouteParams = {
      name: record.resultFileName,
      path: record.resultPath,
      size: 0,
      sizeText: record.fileSize,
      summary: `${record.toolName} · ${record.createTime}`,
      toolName: record.toolName
    };
    options.params = params as Object;
    router.pushUrl(options).catch((err: Error) => {
      promptAction.showToast({ message: `预览页打开失败：${err.message}` });
    });
  }

  @Builder
  TypeChip(typeId: string, label: string) {
    Text(label)
      .height(34)
      .fontSize(13)
      .fontWeight(this.selectedType === typeId ? FontWeight.Bold : FontWeight.Medium)
      .fontColor(this.selectedType === typeId ? Color.White : '#52607A')
      .textAlign(TextAlign.Center)
      .padding({ left: 14, right: 14 })
      .borderRadius(17)
      .backgroundColor(this.selectedType === typeId ? PRIMARY_COLOR : Color.White)
      .border({ width: 1, color: this.selectedType === typeId ? PRIMARY_COLOR : '#E2E9F5' })
      .onClick(() => {
        this.selectedType = typeId;
        this.resetPaging();
      })
  }

  @Builder
  ActionButton(label: string, color: string, bgColor: string, onClick: () => void) {
    Button(label)
      .height(36)
      .fontSize(12)
      .fontWeight(FontWeight.Medium)
      .fontColor(color)
      .backgroundColor(bgColor)
      .borderRadius(8)
      .layoutWeight(1)
      .onClick(onClick)
  }

  @Builder
  Header() {
    Column({ space: 14 }) {
      Row() {
        Column({ space: 6 }) {
          Text('处理记录')
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_PRIMARY)
          Text('搜索文件名、筛选类型，快速找到最近处理结果')
            .fontSize(13)
            .fontColor(TEXT_MUTED)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Button('清空')
          .height(38)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(PRIMARY_COLOR)
          .backgroundColor('#EEF3FF')
          .borderRadius(8)
          .onClick(() => this.clearAll())
      }
      .width('100%')

    }
    .width('100%')
  }

  @Builder
  SearchPanel() {
    Column({ space: 12 }) {
      Search({ value: this.keyword, placeholder: '搜索文件名、工具名称或处理状态' })
        .height(44)
        .backgroundColor('#F8FAFF')
        .borderRadius(10)
        .onChange((value: string) => {
          this.keyword = value;
          this.resetPaging();
        })

      Scroll() {
        Row({ space: 8 }) {
          this.TypeChip('all', '全部')
          this.TypeChip('pdf', 'PDF')
          this.TypeChip('image', '图片')
          this.TypeChip('office', 'Office')
          this.TypeChip('text', '文本')
          this.TypeChip('scan', '扫描件')
        }
        .padding({ right: 16 })
      }
      .width('100%')
      .height(38)
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .padding(14)
    .borderRadius(8)
    .backgroundColor(Color.White)
  }

  @Builder
  RecordCard(record: HistoryRecord) {
    Column({ space: 12 }) {
      Row({ space: 12 }) {
        Text(this.resultExt(record).toUpperCase())
          .width(44)
          .height(44)
          .borderRadius(10)
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.typeColor(record))

        Column({ space: 6 }) {
          Row({ space: 8 }) {
            Text(record.resultFileName)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(TEXT_PRIMARY)
              .layoutWeight(1)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(this.typeLabel(record))
              .fontSize(11)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.typeColor(record))
              .padding({ left: 7, right: 7, top: 3, bottom: 3 })
              .borderRadius(6)
              .backgroundColor('#F1F4FB')
          }
          .width('100%')

          Text(record.toolName)
            .fontSize(12)
            .fontColor('#52607A')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Row({ space: 8 }) {
            Text(record.createTime)
              .fontSize(11)
              .fontColor(TEXT_MUTED)
              .layoutWeight(1)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(record.fileSize)
              .fontSize(11)
              .fontColor(TEXT_MUTED)
          }
          .width('100%')

          Text(`来源：${record.sourceFileName}`)
            .fontSize(11)
            .fontColor(TEXT_MUTED)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      Row({ space: 8 }) {
        this.ActionButton('预览', PRIMARY_COLOR, '#EAF1FF', () => this.openRecordPreview(record))
        this.ActionButton('保存', '#FFFFFF', PRIMARY_COLOR, () => this.saveRecordFile(record))
        this.ActionButton('分享', PRIMARY_COLOR, '#EAF1FF', () => this.shareRecordFile(record))
        this.ActionButton('删除', '#D92D20', '#FFF0F0', () => this.remove(record.id))
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .borderRadius(8)
    .backgroundColor(Color.White)
    .shadow({ radius: 8, color: '#0F23351F', offsetY: 3 })
  }

  @Builder
  EmptyState() {
    Column({ space: 10 }) {
      Text(this.records.length ? '没有匹配的记录' : '暂无处理记录')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(TEXT_PRIMARY)
      Text(this.records.length ? '换个关键词或文件类型试试' : '完成文件处理后会自动保存到这里')
        .fontSize(13)
        .fontColor(TEXT_MUTED)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding(24)
    .borderRadius(8)
    .backgroundColor(Color.White)
  }

  @Builder
  Footer() {
    if (this.filteredRecords().length > 0) {
      if (this.hasMore()) {
        Button('加载更多')
          .width('100%')
          .height(42)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(PRIMARY_COLOR)
          .backgroundColor('#EEF3FF')
          .borderRadius(8)
          .onClick(() => this.loadMore())
      } else {
        Text('已展示全部记录')
          .width('100%')
          .height(38)
          .fontSize(12)
          .fontColor(TEXT_MUTED)
          .textAlign(TextAlign.Center)
      }
    }
  }

  build() {
    List({ space: 12 }) {
      ListItem() {
        this.Header()
      }

      ListItem() {
        this.SearchPanel()
      }

      ListItem() {
        Row() {
          Text('最近处理')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_PRIMARY)
          Text(`默认展示最近 ${Math.min(10, this.filteredRecords().length)} 条`)
            .fontSize(12)
            .fontColor(TEXT_MUTED)
            .layoutWeight(1)
            .textAlign(TextAlign.End)
        }
        .width('100%')
      }

      if (this.visibleRecords().length > 0) {
        ForEach(this.visibleRecords(), (record: HistoryRecord) => {
          ListItem() {
            this.RecordCard(record)
          }
        }, (record: HistoryRecord) => record.id)
      } else {
        ListItem() {
          this.EmptyState()
        }
      }

      ListItem() {
        this.Footer()
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 34, bottom: 16 })
    .backgroundColor(PAGE_BG)
    .scrollBar(BarState.Off)
    .onReachEnd(() => this.loadMore())
  }
}
