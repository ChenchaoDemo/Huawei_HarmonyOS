import { router } from '@kit.ArkUI';
import { PAGE_BG, PRIMARY_COLOR, PURPLE_COLOR } from '../../constants/AppConstants';
import { GuideSectionCard } from '../../components/GuideSectionCard';

@Entry
@Component
struct UsageGuidePage {
  onBack: () => void = () => router.back();

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Column({ space: 14 }) {
          Row({ space: 10 }) {
            Button('‹')
              .width(44)
              .height(44)
              .fontSize(22)
              .fontColor(PRIMARY_COLOR)
              .backgroundColor('#EEF3FF')
              .onClick(this.onBack)
            Column({ space: 6 }) {
              Text('使用说明')
                .fontSize(25)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
              Text('文件处理流程、结果保存和鸿蒙使用方式')
                .fontSize(13)
                .fontColor('#EAF1FF')
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')

          Text('本页说明工具如何使用，也说明在鸿蒙系统里哪些能力来自系统选择器、哪些能力只做本地处理。')
            .fontSize(13)
            .lineHeight(18)
            .fontColor('#EAF1FF')
        }
        .padding({ left: 18, right: 18, top: 18, bottom: 20 })
        .linearGradient({ angle: 135, colors: [[PRIMARY_COLOR, 0], [PURPLE_COLOR, 1]] })
        .borderRadius({ bottomLeft: 18, bottomRight: 18 })

        GuideSectionCard({
          title: '1. 适用范围',
          points: [
            '应用面向 PDF、图片、TXT 和部分 Office 入口的日常处理，优先覆盖合并、拆分、转 PDF、扫描件整理等办公场景。',
            '当前版本的本地能力只处理用户主动选择的文件，不会扫描设备全盘内容。',
            'Word、Excel、PPT 原样转换，以及复杂 PDF 渲染、OCR、压缩和加密，会明确提示需要接入服务端或成熟本地库。'
          ]
        })
        .padding({ left: 16, right: 16 })

        GuideSectionCard({
          title: '2. 标准使用流程',
          points: [
            '在首页选择目标工具，进入详情页后先选择文件或图片。',
            '按工具要求设置输出文件名、页码范围、水印、边距、方向或数量限制。',
            '点击开始处理后，页面会显示加载进度、禁用重复操作，并在完成后给出保存、预览和分享入口。',
            '结果文件默认先写入应用沙箱，确认无误后再通过系统保存入口写到用户指定位置。'
          ]
        })
        .padding({ left: 16, right: 16 })

        GuideSectionCard({
          title: '3. 文件选择与排序',
          points: [
            '文件选择使用鸿蒙系统文件选择器，图片选择使用系统相册选择器，降低权限范围并保持原生体验。',
            '图片转 PDF、文件扫描和证件扫描支持多张图片排序，上移和下移会直接影响最终页面顺序。',
            '像证件扫描这类工具有明确数量上限，页面会在超限时拦截，避免生成异常结果。'
          ]
        })
        .padding({ left: 16, right: 16 })

        GuideSectionCard({
          title: '4. 结果保存与历史',
          points: [
            '处理结果会带有文件名、大小、耗时和摘要信息，方便你判断是否符合预期。',
            '保存按钮会调用系统保存能力，让你选择保存目录，而不是直接覆盖系统文件。',
            '历史记录仅保存工具名、源文件名、结果路径、大小和时间，便于重复查看、删除和清空。'
          ]
        })
        .padding({ left: 16, right: 16 })

        GuideSectionCard({
          title: '5. 鸿蒙使用习惯',
          points: [
            '文件和图片权限只在你点选文件时由系统临时授予，不会后台常驻读取。',
            '临时文件位于应用沙箱目录，适合调试和后续再次保存；需要清理时可在“我的”页使用文件清理。',
            '页面按钮和选项按照鸿蒙原生控件尺寸设计，常用触控目标不小于 40vp，减少误触。'
          ]
        })
        .padding({ left: 16, right: 16, bottom: 20 })
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(PAGE_BG)
  }
}
