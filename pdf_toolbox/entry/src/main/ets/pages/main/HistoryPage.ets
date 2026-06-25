import { promptAction, router } from '@kit.ArkUI';
import { PAGE_BG, PRIMARY_COLOR, TEXT_MUTED, TEXT_PRIMARY } from '../../constants/AppConstants';
import { FilePreviewRouteParams, HistoryRecord } from '../../models/ToolModels';
import { FileService } from '../../services/FileService';
import { HistoryService } from '../../services/HistoryService';
import { ShareService } from '../../services/ShareService';
import { getExt } from '../../utils/FormatUtils';

class FilePreviewRouterOptions {
  url: string = '';
  params?: Object;
}

@Component
export struct HistoryPage {
  @Prop @Watch('onRefreshTokenChange') refreshToken: number = 0;
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

  private onRefreshTokenChange(): void {
    this.refresh();
  }

  private resetPaging(): void {
    this.visibleCount = 10;
  }

  private fileText(record: HistoryRecord): string {
    return `${record.toolName} ${record.toolType} ${record.sourceFileName} ${record.resultFileName} ${this.typeLabel(record)} ${record.status}`.toLowerCase();
  }

  private resultExt(record: HistoryRecord): string {
    const savedExt = (record.resultExt || '').replace(/^\./, '').toLowerCase();
    if (savedExt.length > 0) {
      return savedExt;
    }

    const nameExt = getExt(record.resultFileName);
    if (nameExt.length > 0) {
      return nameExt;
    }

    const pathExt = getExt(record.resultPath);
    if (pathExt.length > 0) {
      return pathExt;
    }

    return this.inferResultExt(record);
  }

  private inferResultExt(record: HistoryRecord): string {
    const toolName = (record.toolName || '').toLowerCase();
    if (toolName.includes('转图片') || toolName.includes('转长图') || toolName.includes('提取图片')) {
      return 'png';
    }
    if (toolName.includes('转word')) {
      return 'docx';
    }
    if (toolName.includes('转excel')) {
      return 'xlsx';
    }
    if (toolName.includes('转ppt')) {
      return 'pptx';
    }
    if (record.toolType === 'pdf' || record.toolType === 'toPdf' || record.toolType === 'scan' || toolName.includes('pdf')) {
      return 'pdf';
    }
    return 'file';
  }

  private resultKind(record: HistoryRecord): string {
    const ext = this.resultExt(record);
    if (ext === 'pdf') {
      return 'pdf';
    }
    if (['jpg', 'jpeg', 'png', 'webp'].includes(ext)) {
      return 'image';
    }
    if (['doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'csv'].includes(ext)) {
      return 'office';
    }
    if (['txt', 'md', 'log'].includes(ext)) {
      return 'text';
    }
    return 'other';
  }

  private typeLabel(record: HistoryRecord): string {
    const kind = this.resultKind(record);
    if (kind === 'pdf') {
      return 'PDF';
    }
    if (kind === 'image') {
      return '图片';
    }
    if (kind === 'office') {
      return 'Office';
    }
    if (kind === 'text') {
      return '文本';
    }
    return this.resultExt(record).toUpperCase();
  }

  private typeColor(record: HistoryRecord): string {
    const kind = this.resultKind(record);
    if (kind === 'pdf') {
      return PRIMARY_COLOR;
    }
    if (kind === 'image') {
      return '#1F8A5B';
    }
    if (kind === 'office') {
      return '#7A4DCC';
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
    return this.resultKind(record) === this.selectedType;
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

  private async removeConfirmed(id: string): Promise<void> {
    await HistoryService.removeRecord(id);
    await this.refresh();
    promptAction.showToast({ message: '已删除记录' });
  }

  remove(record: HistoryRecord): void {
    AlertDialog.show({
      title: '删除记录',
      message: `确定要删除“${record.resultFileName}”这条处理记录吗？`,
      autoCancel: true,
      secondaryButton: {
        value: '取消',
        fontColor: '#52607A',
        action: () => {}
      },
      primaryButton: {
        value: '删除',
        fontColor: '#D92D20',
        action: () => {
          this.removeConfirmed(record.id);
        }
      }
    });
  }

  private async clearAllConfirmed(): Promise<void> {
    await HistoryService.clearRecords();
    await this.refresh();
    this.resetPaging();
    promptAction.showToast({ message: '已清空记录' });
  }

  clearAll(): void {
    if (!this.records.length) {
      promptAction.showToast({ message: '暂无可清空的记录' });
      return;
    }
    AlertDialog.show({
      title: '清空记录',
      message: '确定要清空全部处理记录吗？清空后无法恢复。',
      autoCancel: true,
      secondaryButton: {
        value: '取消',
        fontColor: '#52607A',
        action: () => {}
      },
      primaryButton: {
        value: '清空',
        fontColor: '#D92D20',
        action: () => {
          this.clearAllConfirmed();
        }
      }
    });
  }

  async saveRecordFile(record: HistoryRecord): Promise<void> {
    try {
      const savedTo = await FileService.saveOutput(record.resultPath, record.resultFileName);
      if (savedTo === 'album') {
        promptAction.showToast({ message: '已保存到相册' });
      } else if (savedTo === 'document') {
        promptAction.showToast({ message: '保存成功' });
      }
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
          this.TypeChip('other', '其他')
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
              .fontSize(14)
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
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      Row({ space: 8 }) {
        this.ActionButton('预览', PRIMARY_COLOR, '#EAF1FF', () => this.openRecordPreview(record))
        this.ActionButton('保存', '#FFFFFF', PRIMARY_COLOR, () => this.saveRecordFile(record))
        this.ActionButton('分享', PRIMARY_COLOR, '#EAF1FF', () => this.shareRecordFile(record))
        this.ActionButton('删除', '#D92D20', '#FFF0F0', () => this.remove(record))
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
    Column({ space: 12 }) {
      this.Header()
      this.SearchPanel()

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

      List({ space: 12 }) {
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
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .onReachEnd(() => this.loadMore())
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 34, bottom: 16 })
    .backgroundColor(PAGE_BG)
  }
}
