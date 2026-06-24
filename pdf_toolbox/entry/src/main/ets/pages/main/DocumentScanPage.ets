import { promptAction, router } from '@kit.ArkUI';
import { PAGE_BG, PRIMARY_COLOR, TEXT_MUTED, TEXT_PRIMARY } from '../../constants/AppConstants';
import { ResultPanel } from '../../components/ResultPanel';
import { PickedFile, ProcessResultView, ProcessorRequest, SettingMap, SettingValue } from '../../models/ToolModels';
import { FileService } from '../../services/FileService';
import { HistoryService } from '../../services/HistoryService';
import { documentScan } from '../../processors/ImageProcessor';
import { formatFileSize, generateId, normalizeOutputFileName, nowText } from '../../utils/FormatUtils';

@Entry
@Component
struct DocumentScanPage {
  onBack: () => void = () => router.back();
  @State files: PickedFile[] = [];
  @State outputName: string = '';
  @State settings: SettingMap = new Map<string, SettingValue>([
    ['direction', '竖向'],
    ['margin', '窄边距'],
    ['watermarkEnabled', false],
    ['watermarkText', '文件处理工具箱'],
    ['watermarkPosition', '居中'],
    ['watermarkFontSize', 36],
    ['watermarkColor', '#8A93A8'],
    ['watermarkOpacity', 32]
  ]);
  @State processing: boolean = false;
  @State progress: number = 0;
  @State progressLabel: string = '等待扫描';
  @State result?: ProcessResultView = undefined;
  @State error: string = '';

  private setSetting(key: string, value: SettingValue): void {
    const next: SettingMap = new Map<string, SettingValue>(this.settings);
    next.set(key, value);
    this.settings = next;
  }

  private value(key: string): SettingValue {
    const item = this.settings.get(key);
    return item === undefined ? '' : item;
  }

  private errText(err: Error | Object): string {
    if (err instanceof Error) {
      return err.message;
    }
    return JSON.stringify(err);
  }

  async pickImages(): Promise<void> {
    try {
      const remaining = 9 - this.files.length;
      if (remaining <= 0) {
        promptAction.showToast({ message: '最多选择 9 张图片' });
        return;
      }
      const picked = await FileService.pickImages(remaining);
      if (picked.length === 0) {
        promptAction.showToast({ message: '未选择图片' });
        return;
      }
      this.files = this.files.concat(picked).slice(0, 9);
      this.result = undefined;
      this.error = '';
      this.progressLabel = `已选择 ${this.files.length} 张图片`;
      promptAction.showToast({ message: `已选择 ${picked.length} 张图片` });
    } catch (err) {
      promptAction.showToast({ message: `图片选择失败：${this.errText(err as Error | Object)}` });
    }
  }

  moveImage(index: number, step: number): void {
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

  removeImage(index: number): void {
    this.files = this.files.filter((_: PickedFile, itemIndex: number) => itemIndex !== index);
    this.result = undefined;
  }

  clearImages(): void {
    this.files = [];
    this.result = undefined;
    this.progress = 0;
    this.progressLabel = '等待扫描';
  }

  async tick(label: string, percent: number): Promise<void> {
    this.progressLabel = label;
    this.progress = percent;
    await new Promise<void>((resolve) => setTimeout(resolve, 130));
  }

  async generatePdf(): Promise<void> {
    if (this.processing) {
      return;
    }
    if (!this.files.length) {
      promptAction.showToast({ message: '请先拍摄或选择扫描图片' });
      return;
    }
    this.processing = true;
    this.result = undefined;
    this.error = '';
    const start = Date.now();
    try {
      await this.tick('正在读取扫描图片', 20);
      const request: ProcessorRequest = {
        files: this.files,
        settings: this.settings,
        text: ''
      };
      const output = await documentScan(request);
      await this.tick('正在生成 PDF', 72);
      const fileName = normalizeOutputFileName(this.outputName, '文件扫描', output.ext || 'pdf');
      const saved = FileService.saveTempFile(output.content, fileName);
      await this.tick('正在保存结果', 92);
      this.result = {
        name: fileName,
        path: saved.path,
        size: saved.size,
        duration: Date.now() - start,
        summary: output.summary
      };
      await HistoryService.saveRecord({
        id: generateId('history'),
        toolName: '文件扫描',
        toolType: 'scan',
        sourceFileName: this.files.map((file: PickedFile) => file.name).join('、'),
        resultFileName: fileName,
        resultPath: saved.path,
        fileSize: formatFileSize(saved.size),
        status: '处理成功',
        createTime: nowText()
      });
      await this.tick('处理完成', 100);
      promptAction.showToast({ message: '生成成功' });
    } catch (err) {
      this.error = err instanceof Error ? err.message : JSON.stringify(err);
      this.progressLabel = '生成失败';
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

  @Builder
  Chip(label: string, key: string) {
    Text(label)
      .height(36)
      .fontSize(13)
      .fontColor(this.value(key) === label ? Color.White : '#52607A')
      .textAlign(TextAlign.Center)
      .padding({ left: 12, right: 12, top: 7, bottom: 7 })
      .borderRadius(8)
      .backgroundColor(this.value(key) === label ? PRIMARY_COLOR : '#F1F4FB')
      .onClick(() => this.setSetting(key, label))
  }

  @Builder
  ColorChoice(name: string, color: string) {
    Row({ space: 8 }) {
      Blank()
        .width(18)
        .height(18)
        .borderRadius(9)
        .backgroundColor(color)
      Text(name)
        .fontSize(12)
        .fontColor('#52607A')
    }
    .padding({ left: 10, right: 10, top: 7, bottom: 7 })
    .borderRadius(8)
    .backgroundColor(this.value('watermarkColor') === color ? '#EEF4FF' : '#F8FAFF')
    .border({ width: 1, color: this.value('watermarkColor') === color ? PRIMARY_COLOR : '#E2E9F5' })
    .onClick(() => this.setSetting('watermarkColor', color))
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
          Text('文件扫描')
            .fontSize(21)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_PRIMARY)
          Text('拍照或从相册补充，排序后生成适合保存和打印的 PDF')
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

      Scroll() {
        Column({ space: 16 }) {
          Row({ space: 12 }) {
            Button('拍照')
              .height(44)
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .backgroundColor(PRIMARY_COLOR)
              .layoutWeight(1)
              .onClick(() => this.pickImages())
            Button('从相册选择')
              .height(44)
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor(PRIMARY_COLOR)
              .backgroundColor('#EEF3FF')
              .layoutWeight(1)
              .onClick(() => this.pickImages())
          }

          Column({ space: 14 }) {
            Row() {
              Text('扫描图片')
                .fontSize(17)
                .fontWeight(FontWeight.Bold)
                .fontColor(TEXT_PRIMARY)
                .layoutWeight(1)
              Text(`${this.files.length} 张`)
                .fontSize(12)
                .fontColor(TEXT_MUTED)
            }
            .width('100%')

            if (this.files.length > 0) {
              Grid() {
                ForEach(this.files, (file: PickedFile, index: number) => {
                  GridItem() {
                    Column({ space: 8 }) {
                      Image(file.uri)
                        .width('100%')
                        .height(128)
                        .objectFit(ImageFit.Cover)
                        .borderRadius({ topLeft: 8, topRight: 8 })
                        .backgroundColor('#EEF3FF')
                      Text(`第 ${index + 1} 页`)
                        .fontSize(13)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(TEXT_PRIMARY)
                        .width('100%')
                        .padding({ left: 8, right: 8 })
                      Row({ space: 6 }) {
                        Button('上移')
                          .height(36)
                          .fontSize(11)
                          .fontColor(PRIMARY_COLOR)
                          .backgroundColor('#EAF1FF')
                          .layoutWeight(1)
                          .onClick(() => this.moveImage(index, -1))
                        Button('下移')
                          .height(36)
                          .fontSize(11)
                          .fontColor(PRIMARY_COLOR)
                          .backgroundColor('#EAF1FF')
                          .layoutWeight(1)
                          .onClick(() => this.moveImage(index, 1))
                        Button('删除')
                          .height(36)
                          .fontSize(11)
                          .fontColor('#D92D20')
                          .backgroundColor('#FFF0F0')
                          .layoutWeight(1)
                          .onClick(() => this.removeImage(index))
                      }
                      .padding({ left: 8, right: 8, bottom: 8 })
                    }
                    .borderRadius(8)
                    .backgroundColor('#F8FAFF')
                    .border({ width: 1, color: '#E3EAF5' })
                  }
                }, (file: PickedFile) => file.id)
              }
              .columnsTemplate('1fr 1fr')
              .columnsGap(10)
              .rowsGap(10)
              .height(Math.ceil(this.files.length / 2) * 238)
            } else {
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
                Text('还没有扫描图片')
                  .fontSize(15)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(TEXT_PRIMARY)
                Text('点击拍照开始，一张图片会生成 PDF 的一页。')
                  .fontSize(12)
                  .fontColor(TEXT_MUTED)
              }
              .width('100%')
              .height(170)
              .justifyContent(FlexAlign.Center)
              .border({ width: 1, color: '#BFD0EE', style: BorderStyle.Dashed })
              .borderRadius(8)
              .backgroundColor('#FBFCFF')
            }

            Button('清空图片')
              .height(38)
              .fontSize(13)
              .fontColor('#D92D20')
              .backgroundColor('#FFF0F0')
              .enabled(this.files.length > 0)
              .onClick(() => this.clearImages())
          }
          .width('100%')
          .padding(16)
          .borderRadius(8)
          .backgroundColor(Color.White)

          Column({ space: 14 }) {
            Text('PDF 设置')
              .fontSize(17)
              .fontWeight(FontWeight.Bold)
              .fontColor(TEXT_PRIMARY)
              .width('100%')
            TextInput({ text: this.outputName, placeholder: '输出文件名，不填将自动生成' })
              .height(42)
              .fontSize(14)
              .backgroundColor('#F5F7FC')
              .borderRadius(8)
              .onChange((value: string) => this.outputName = value)
            Text('页面方向')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(TEXT_PRIMARY)
              .width('100%')
            Row({ space: 8 }) {
              this.Chip('竖向', 'direction')
              this.Chip('横向', 'direction')
            }
            Text('页面边距')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(TEXT_PRIMARY)
              .width('100%')
            Row({ space: 8 }) {
              this.Chip('无边距', 'margin')
              this.Chip('窄边距', 'margin')
              this.Chip('普通边距', 'margin')
            }
          }
          .width('100%')
          .padding(16)
          .borderRadius(8)
          .backgroundColor(Color.White)

          Column({ space: 14 }) {
            Row() {
              Text('水印')
                .fontSize(17)
                .fontWeight(FontWeight.Bold)
                .fontColor(TEXT_PRIMARY)
                .layoutWeight(1)
              Toggle({ type: ToggleType.Switch, isOn: this.value('watermarkEnabled') === true })
                .selectedColor(PRIMARY_COLOR)
                .onChange((value: boolean) => this.setSetting('watermarkEnabled', value))
            }
            .width('100%')

            if (this.value('watermarkEnabled') === true) {
              TextInput({ text: String(this.value('watermarkText')), placeholder: '请输入水印文字' })
                .height(42)
                .fontSize(14)
                .backgroundColor('#F5F7FC')
                .borderRadius(8)
                .onChange((value: string) => this.setSetting('watermarkText', value))
              Text('水印位置')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(TEXT_PRIMARY)
                .width('100%')
              Row({ space: 8 }) {
                this.Chip('居中', 'watermarkPosition')
                this.Chip('左上', 'watermarkPosition')
                this.Chip('右上', 'watermarkPosition')
              }
              Row({ space: 8 }) {
                this.Chip('左下', 'watermarkPosition')
                this.Chip('右下', 'watermarkPosition')
              }
              Text('字体颜色')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(TEXT_PRIMARY)
                .width('100%')
              Row({ space: 8 }) {
                this.ColorChoice('灰色', '#8A93A8')
                this.ColorChoice('蓝色', '#2667FF')
                this.ColorChoice('红色', '#D92D20')
              }
              Row({ space: 10 }) {
                Text('文字大小')
                  .fontSize(14)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(TEXT_PRIMARY)
                Slider({ value: Number(this.value('watermarkFontSize')), min: 18, max: 72, step: 2 })
                  .layoutWeight(1)
                  .selectedColor(PRIMARY_COLOR)
                  .onChange((value: number) => this.setSetting('watermarkFontSize', value))
                Text(`${this.value('watermarkFontSize')}`)
                  .fontSize(13)
                  .fontColor(PRIMARY_COLOR)
              }
              Row({ space: 10 }) {
                Text('透明度')
                  .fontSize(14)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(TEXT_PRIMARY)
                Slider({ value: Number(this.value('watermarkOpacity')), min: 10, max: 80, step: 5 })
                  .layoutWeight(1)
                  .selectedColor(PRIMARY_COLOR)
                  .onChange((value: number) => this.setSetting('watermarkOpacity', value))
                Text(`${this.value('watermarkOpacity')}%`)
                  .fontSize(13)
                  .fontColor(PRIMARY_COLOR)
              }
            }
          }
          .width('100%')
          .padding(16)
          .borderRadius(8)
          .backgroundColor(Color.White)

          Button(this.processing ? '正在生成' : '生成扫描PDF')
            .width('100%')
            .height(48)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .backgroundColor(PRIMARY_COLOR)
            .enabled(!this.processing && this.files.length > 0)
            .onClick(() => this.generatePdf())

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
              Text('生成失败')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#D92D20')
              Text(this.error)
                .fontSize(13)
                .fontColor('#8A3A35')
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
