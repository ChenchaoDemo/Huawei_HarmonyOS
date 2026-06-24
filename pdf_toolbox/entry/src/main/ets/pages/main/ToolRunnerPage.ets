import { promptAction, router } from '@kit.ArkUI';
import { PAGE_BG, PRIMARY_COLOR, TEXT_MUTED, TEXT_PRIMARY, TOOL_CONFIGS, TOOLS, getConfigByToolId, getToolById } from '../../constants/AppConstants';
import { FilePickerPanel } from '../../components/FilePickerPanel';
import { ResultPanel } from '../../components/ResultPanel';
import { SettingRow } from '../../components/SettingRow';
import { FilePreviewRouteParams, PickedFile, PreviewSourceFile, ProcessResultView, ProcessorRequest, SettingMap, SettingValue, ToolConfig, ToolMeta, ToolSetting } from '../../models/ToolModels';
import { FileService } from '../../services/FileService';
import { HistoryService } from '../../services/HistoryService';
import { ShareService } from '../../services/ShareService';
import { ProcessorRegistry } from '../../processors/ProcessorRegistry';
import { businessOutputFileName, fileStem, formatFileSize, generateId, normalizeOutputFileName, nowText } from '../../utils/FormatUtils';

interface ToolRunnerRouteParams {
  toolId?: string;
}

class FilePreviewRouterOptions {
  url: string = '';
  params?: Object;
}

@Entry
@Component
struct ToolRunnerPage {
  @State toolId: string = 'text-to-pdf';
  onBack: () => void = () => router.back();

  @State files: PickedFile[] = [];
  @State inputText: string = '';
  @State outputName: string = '';
  @State outputNameEdited: boolean = false;
  @State settings: SettingMap = new Map<string, SettingValue>();
  @State processing: boolean = false;
  @State progress: number = 0;
  @State progressLabel: string = '未选择文件';
  @State result?: ProcessResultView = undefined;
  @State error: string = '';

  aboutToAppear(): void {
    const params = router.getParams() as ToolRunnerRouteParams;
    if (params && params.toolId && params.toolId.length > 0) {
      this.toolId = params.toolId;
    }
    this.initSettings();
    this.refreshDefaultOutputName();
  }

  private tool(): ToolMeta {
    return getToolById(this.toolId) || TOOLS[0];
  }

  private config(): ToolConfig {
    return getConfigByToolId(this.toolId) || TOOL_CONFIGS['text-to-pdf'];
  }

  private initSettings(): void {
    const next: SettingMap = new Map<string, SettingValue>();
    this.config().settings.forEach((setting: ToolSetting) => {
      if (setting.value !== undefined) {
        next.set(setting.key, setting.value);
      } else {
        next.set(setting.key, setting.type === 'switch' ? false : '');
      }
    });
    this.settings = next;
  }

  private setSetting(key: string, value: SettingValue): void {
    const next: SettingMap = new Map<string, SettingValue>(this.settings);
    next.set(key, value);
    this.settings = next;
  }

  private settingValue(key: string): SettingValue {
    const item = this.settings.get(key);
    return item === undefined ? '' : item;
  }

  private errText(err: Error | Object): string {
    if (err instanceof Error) {
      return err.message;
    }
    return JSON.stringify(err);
  }

  private outputExt(): string {
    return this.config().resultExt || 'pdf';
  }

  private defaultOutputPrefix(): string {
    const toolName = this.tool().name;
    const config = this.config();
    if (this.files.length > 0) {
      if (config.pickMode === 'image' || config.pickMode === 'camera') {
        return `${toolName}_${this.files.length}张图片`;
      }
      if (this.files.length === 1) {
        const stem = fileStem(this.files[0].name);
        return stem.length > 0 ? `${stem}_${toolName}` : toolName;
      }
      return `${toolName}_${this.files.length}个文件`;
    }
    if (config.pickMode === 'text' && this.inputText.trim().length > 0) {
      return `${toolName}_文本内容`;
    }
    return toolName;
  }

  private refreshDefaultOutputName(): void {
    if (!this.outputNameEdited) {
      this.outputName = businessOutputFileName(this.defaultOutputPrefix(), this.outputExt());
    }
  }

  private previewSources(): PreviewSourceFile[] {
    return this.files.map((file: PickedFile): PreviewSourceFile => {
      return {
        id: file.id,
        name: file.name,
        uri: file.uri,
        size: file.size,
        ext: file.ext,
        type: file.type
      };
    });
  }

  private textPreviewValue(file?: PickedFile): string {
    if (this.config().pickMode === 'text' && this.inputText.trim().length > 0) {
      return this.inputText;
    }
    if (file && file.ext === 'txt') {
      try {
        return FileService.readText(file);
      } catch (_) {
        return '';
      }
    }
    return '';
  }

  private openPreview(params: FilePreviewRouteParams): void {
    const options = new FilePreviewRouterOptions();
    options.url = 'pages/main/FilePreviewPage';
    options.params = params as Object;
    router.pushUrl(options).catch((err: Error) => {
      promptAction.showToast({ message: `预览页打开失败：${err.message}` });
    });
  }

  private pickTitle(): string {
    const config = this.config();
    if (config.pickTitle) {
      return config.pickTitle;
    }
    if (config.pickMode === 'camera') {
      return '拍照或选择图片';
    }
    return '选择文件';
  }

  private pickDesc(): string {
    const config = this.config();
    if (config.pickDesc) {
      return config.pickDesc;
    }
    const types = this.tool().acceptTypes;
    return types.length ? `支持 ${types.join('、')} 格式` : '点击选择文件';
  }

  async pickFiles(): Promise<void> {
    try {
      this.error = '';
      const config = this.config();
      const maxCount = config.maxCount || 9;
      const remaining = config.multiple ? maxCount - this.files.length : 1;
      if (remaining <= 0) {
        promptAction.showToast({ message: `最多选择 ${maxCount} 个文件` });
        return;
      }
      let picked: PickedFile[] = [];
      if (config.pickMode === 'image' || config.pickMode === 'camera') {
        picked = await FileService.pickImages(remaining);
      } else {
        picked = await FileService.pickDocuments(config.multiple ? remaining : 1, config.pickMode === 'text' ? ['txt'] : this.tool().acceptTypes);
      }
      if (picked.length === 0) {
        promptAction.showToast({ message: '未选择文件' });
        return;
      }
      if (config.pickMode === 'text' && !this.inputText.trim()) {
        this.inputText = FileService.readText(picked[0]);
      }
      this.files = config.multiple ? this.files.concat(picked).slice(0, maxCount) : picked.slice(0, 1);
      this.refreshDefaultOutputName();
      this.progressLabel = `已选择 ${this.files.length} 个文件`;
      this.result = undefined;
      promptAction.showToast({ message: `已选择 ${picked.length} 个文件` });
    } catch (err) {
      promptAction.showToast({ message: `选择失败：${this.errText(err as Error | Object)}` });
    }
  }

  moveFile(index: number, step: number): void {
    const nextIndex = index + step;
    if (nextIndex < 0 || nextIndex >= this.files.length) {
      return;
    }
    const list = this.files.slice();
    const current = list[index];
    list[index] = list[nextIndex];
    list[nextIndex] = current;
    this.files = list;
  }

  removeFile(index: number): void {
    this.files = this.files.filter((_: PickedFile, itemIndex: number) => itemIndex !== index);
    this.result = undefined;
    this.refreshDefaultOutputName();
  }

  reset(): void {
    this.files = [];
    this.inputText = '';
    this.outputName = '';
    this.outputNameEdited = false;
    this.result = undefined;
    this.error = '';
    this.progress = 0;
    this.progressLabel = '未选择文件';
    this.initSettings();
    this.refreshDefaultOutputName();
  }

  async tick(label: string, percent: number): Promise<void> {
    this.progressLabel = label;
    this.progress = percent;
    await new Promise<void>((resolve) => setTimeout(resolve, 130));
  }

  async startProcess(): Promise<void> {
    if (this.processing) {
      return;
    }
    const config = this.config();
    if (config.pickMode !== 'text' && this.files.length === 0) {
      promptAction.showToast({ message: '请先选择文件' });
      return;
    }
    if (config.pickMode === 'text' && !this.inputText.trim() && this.files.length === 0) {
      promptAction.showToast({ message: '请输入文本或选择 TXT 文件' });
      return;
    }

    this.processing = true;
    this.result = undefined;
    this.error = '';
    const start = Date.now();
    try {
      await this.tick('正在读取文件', 18);
      const processor = ProcessorRegistry.getProcessor(config.processor);
      await this.tick('正在解析文件', 40);
      const request: ProcessorRequest = {
        files: this.files,
        settings: this.settings,
        text: this.inputText
      };
      const output = await processor(request);
      await this.tick('正在生成结果', 72);
      const ext = output.ext || config.resultExt || 'pdf';
      const fileName = normalizeOutputFileName(this.outputName, this.tool().name, ext);
      const saved = FileService.saveTempFile(output.content, fileName);
      await this.tick('正在保存临时文件', 92);
      const result: ProcessResultView = {
        name: fileName,
        path: saved.path,
        size: saved.size,
        duration: Date.now() - start,
        summary: output.summary || '处理完成'
      };
      this.result = result;
      await HistoryService.saveRecord({
        id: generateId('history'),
        toolName: this.tool().name,
        toolType: this.tool().category,
        sourceFileName: this.files.map((file: PickedFile) => file.name).join('、') || '手动输入内容',
        resultFileName: fileName,
        resultPath: saved.path,
        fileSize: formatFileSize(saved.size),
        status: '处理成功',
        createTime: nowText()
      });
      await this.tick('处理完成', 100);
      promptAction.showToast({ message: '处理成功' });
    } catch (err) {
      this.error = err instanceof Error ? err.message : JSON.stringify(err);
      this.progressLabel = '处理失败';
      promptAction.showToast({ message: this.error });
    } finally {
      this.processing = false;
    }
  }

  async saveResult(): Promise<void> {
    if (!this.result) {
      return;
    }
    try {
      await FileService.saveToPicker(this.result.path, this.result.name);
      promptAction.showToast({ message: '保存成功' });
    } catch (err) {
      promptAction.showToast({ message: `保存失败：${this.errText(err as Error | Object)}` });
    }
  }

  async shareResult(): Promise<void> {
    if (!this.result) {
      promptAction.showToast({ message: '没有可分享的文件' });
      return;
    }
    try {
      await ShareService.shareFile({
        name: this.result.name,
        path: this.result.path,
        summary: this.result.summary
      });
    } catch (err) {
      promptAction.showToast({ message: `分享失败：${this.errText(err as Error | Object)}` });
    }
  }

  openResultPreview(): void {
    if (!this.result) {
      promptAction.showToast({ message: '没有可预览的文件' });
      return;
    }
    this.openPreview({
      name: this.result.name,
      path: this.result.path,
      size: this.result.size,
      summary: this.result.summary,
      toolName: this.tool().name,
      sources: this.previewSources(),
      textPreview: this.textPreviewValue()
    });
  }

  openPickedFilePreview(file: PickedFile): void {
    this.openPreview({
      name: file.name,
      path: file.uri,
      size: file.size,
      summary: '这是当前选择的源文件，确认无误后可返回继续处理。',
      toolName: this.tool().name,
      sources: [file],
      textPreview: this.textPreviewValue(file)
    });
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
          .onClick(this.onBack)
        Column({ space: 4 }) {
          Text(this.tool().name)
            .fontSize(21)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_PRIMARY)
          Text(this.tool().desc)
            .fontSize(12)
            .fontColor(TEXT_MUTED)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 18, bottom: 10 })
      .backgroundColor(PAGE_BG)

      Scroll() {
        Column({ space: 16 }) {
          Column({ space: 14 }) {
            Row() {
              Text('文件选择')
                .fontSize(17)
                .fontWeight(FontWeight.Bold)
                .fontColor(TEXT_PRIMARY)
                .layoutWeight(1)
              Text(this.files.length ? '已选择文件' : '未选择文件')
                .fontSize(12)
                .fontColor(TEXT_MUTED)
            }
            .width('100%')

            if (this.config().pickMode === 'text') {
              TextArea({ text: this.inputText, placeholder: '输入文本内容，也可点击下方选择 TXT 文件' })
                .height(180)
                .fontSize(14)
                .backgroundColor('#F5F7FC')
                .borderRadius(8)
                .onChange((value: string) => {
                  this.inputText = value;
                  this.refreshDefaultOutputName();
                })
              Button('选择 TXT 文件')
                .height(42)
                .fontSize(14)
                .fontColor(PRIMARY_COLOR)
                .backgroundColor('#EEF3FF')
                .onClick(() => this.pickFiles())
              if (this.files.length > 0) {
                Row({ space: 10 }) {
                  Column({ space: 4 }) {
                    Text(this.files[0].name)
                      .fontSize(13)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(TEXT_PRIMARY)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(`已读取 TXT · ${formatFileSize(this.files[0].size)}`)
                      .fontSize(11)
                      .fontColor(TEXT_MUTED)
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)
                  Button('预览')
                    .height(34)
                    .fontSize(12)
                    .fontColor(PRIMARY_COLOR)
                    .backgroundColor('#EAF1FF')
                    .onClick(() => this.openPickedFilePreview(this.files[0]))
                  Button('移除')
                    .height(34)
                    .fontSize(12)
                    .fontColor('#D92D20')
                    .backgroundColor('#FFF0F0')
                    .onClick(() => this.removeFile(0))
                }
                .width('100%')
                .padding(10)
                .borderRadius(8)
                .backgroundColor('#F5F7FC')
              }
            } else {
              FilePickerPanel({
                title: this.pickTitle(),
                desc: this.pickDesc(),
                files: this.files,
                onPick: () => this.pickFiles(),
                onPreview: (file: PickedFile) => this.openPickedFilePreview(file),
                onMove: (index: number, step: number) => this.moveFile(index, step),
                onRemove: (index: number) => this.removeFile(index)
              })
            }
          }
          .width('100%')
          .padding(16)
          .borderRadius(8)
          .backgroundColor(Color.White)

          Column({ space: 4 }) {
            Text('参数设置')
              .fontSize(17)
              .fontWeight(FontWeight.Bold)
              .fontColor(TEXT_PRIMARY)
              .width('100%')
            Text(this.config().description)
              .fontSize(12)
              .fontColor(TEXT_MUTED)
              .lineHeight(17)
              .width('100%')
            Column({ space: 0 }) {
              Text('输出文件名')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(TEXT_PRIMARY)
                .width('100%')
                .padding({ top: 14, bottom: 10 })
              TextInput({ text: this.outputName, placeholder: '不填将自动生成，扩展名会自动补全' })
                .height(42)
                .fontSize(14)
                .backgroundColor('#F5F7FC')
                .borderRadius(8)
                .onChange((value: string) => {
                  this.outputNameEdited = true;
                  this.outputName = value;
                })
                .margin({ bottom: 8 })
              if (this.config().settings.length > 0) {
                ForEach(this.config().settings, (setting: ToolSetting) => {
                  SettingRow({
                    setting,
                    value: this.settingValue(setting.key),
                    onValueChange: (key: string, value: SettingValue) => this.setSetting(key, value)
                  })
                }, (setting: ToolSetting) => setting.key)
              } else {
                Text('当前工具没有额外处理参数。')
                  .width('100%')
                  .padding(14)
                  .fontSize(13)
                  .fontColor(TEXT_MUTED)
                  .borderRadius(8)
                  .backgroundColor('#F6F8FC')
              }
            }
            .width('100%')
          }
          .width('100%')
          .padding(16)
          .borderRadius(8)
          .backgroundColor(Color.White)

          Button(this.processing ? '正在处理' : this.config().actionText)
            .width('100%')
            .height(48)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .backgroundColor(PRIMARY_COLOR)
            .enabled(!this.processing)
            .onClick(() => this.startProcess())

          if (this.processing || this.progress > 0) {
            Column({ space: 8 }) {
              Row() {
                Text(this.progressLabel)
                  .fontSize(12)
                  .fontColor(TEXT_MUTED)
                  .layoutWeight(1)
                Text(`${Math.floor(this.progress)}%`)
                  .fontSize(12)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(PRIMARY_COLOR)
              }
              Progress({ value: this.progress, total: 100, type: ProgressType.Linear })
                .color(PRIMARY_COLOR)
                .height(6)
            }
            .width('100%')
            .padding(14)
            .borderRadius(8)
            .backgroundColor(Color.White)
          }

          if (this.error.length > 0) {
            Column({ space: 8 }) {
              Text('处理失败')
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

          ResultPanel({
            result: this.result,
            onOpen: () => this.openResultPreview(),
            onSave: () => this.saveResult(),
            onShare: () => this.shareResult()
          })

          Button('重新选择文件')
            .width('100%')
            .height(44)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(PRIMARY_COLOR)
            .backgroundColor(Color.White)
            .border({ width: 1, color: '#DBE5F4' })
            .onClick(() => this.reset())
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
