import { promptAction } from '@kit.ArkUI';
import { PAGE_BG, PRIMARY_COLOR, TEXT_MUTED, TEXT_PRIMARY, TOOL_CONFIGS, TOOLS, getConfigByToolId, getToolById } from '../../constants/AppConstants';
import { FilePickerPanel } from '../../components/FilePickerPanel';
import { ResultPanel } from '../../components/ResultPanel';
import { SettingRow } from '../../components/SettingRow';
import { PickedFile, ProcessResultView, ProcessorRequest, SettingMap, SettingValue, ToolConfig, ToolMeta, ToolSetting } from '../../models/ToolModels';
import { FileService } from '../../services/FileService';
import { HistoryService } from '../../services/HistoryService';
import { ProcessorRegistry } from '../../processors/ProcessorRegistry';
import { formatFileSize, generateId, normalizeOutputFileName, nowText } from '../../utils/FormatUtils';

@Component
export struct ToolRunnerPage {
  toolId: string = 'text-to-pdf';
  onBack: () => void = () => {};

  @State files: PickedFile[] = [];
  @State inputText: string = '';
  @State outputName: string = '';
  @State settings: SettingMap = new Map<string, SettingValue>();
  @State processing: boolean = false;
  @State progress: number = 0;
  @State progressLabel: string = '未选择文件';
  @State result?: ProcessResultView = undefined;
  @State error: string = '';

  aboutToAppear(): void {
    this.initSettings();
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
      this.files = config.multiple ? this.files.concat(picked).slice(0, maxCount) : picked.slice(0, 1);
      this.result = undefined;
    } catch (err) {
      promptAction.showToast({ message: `选择失败：${JSON.stringify(err)}` });
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
  }

  reset(): void {
    this.files = [];
    this.inputText = '';
    this.outputName = '';
    this.result = undefined;
    this.error = '';
    this.progress = 0;
    this.progressLabel = '未选择文件';
    this.initSettings();
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
      promptAction.showToast({ message: `保存失败：${JSON.stringify(err)}` });
    }
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
      .padding({ left: 16, right: 16, top: 44, bottom: 10 })
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
                .onChange((value: string) => this.inputText = value)
              Button('选择 TXT 文件')
                .height(42)
                .fontSize(14)
                .fontColor(PRIMARY_COLOR)
                .backgroundColor('#EEF3FF')
                .onClick(() => this.pickFiles())
            } else {
              FilePickerPanel({
                title: this.pickTitle(),
                desc: this.pickDesc(),
                files: this.files,
                onPick: () => this.pickFiles(),
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
                .onChange((value: string) => this.outputName = value)
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
            onOpen: () => promptAction.showToast({ message: this.result ? `结果路径：${this.result.path}` : '没有可打开的文件' }),
            onSave: () => this.saveResult(),
            onShare: () => promptAction.showToast({ message: '系统分享入口待接入' })
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
