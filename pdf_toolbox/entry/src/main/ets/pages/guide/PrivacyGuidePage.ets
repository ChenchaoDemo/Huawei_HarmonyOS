import { router } from '@kit.ArkUI';
import { PAGE_BG, PRIMARY_COLOR, PURPLE_COLOR } from '../../constants/AppConstants';
import { GuideSectionCard } from '../../components/GuideSectionCard';

@Entry
@Component
struct PrivacyGuidePage {
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
              Text('隐私说明')
                .fontSize(25)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
              Text('文件处理边界、权限使用和数据留存')
                .fontSize(13)
                .fontColor('#EAF1FF')
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')

          Text('本页说明应用如何处理文件、为什么要使用系统选择器，以及当前鸿蒙版本下我们如何控制权限和数据留存。')
            .fontSize(13)
            .lineHeight(18)
            .fontColor('#EAF1FF')
        }
        .padding({ left: 18, right: 18, top: 18, bottom: 20 })
        .linearGradient({ angle: 135, colors: [[PRIMARY_COLOR, 0], [PURPLE_COLOR, 1]] })
        .borderRadius({ bottomLeft: 18, bottomRight: 18 })

        GuideSectionCard({
          title: '1. 我们收集什么',
          points: [
            '当前版本只处理你主动选择的文件、图片和你手动输入的文本，不会主动扫描通讯录、短信、相册或全盘存储。',
            '历史记录里仅保存工具名、源文件名、结果文件名、结果路径、文件大小、处理时间和状态，用于查看和管理。',
            '如果你手动填写输出文件名，这个名称只会用于本地生成文件和历史记录显示。'
          ]
        })
        .padding({ left: 16, right: 16 })

        GuideSectionCard({
          title: '2. 文件如何处理',
          points: [
            '能在本地完成的能力，会优先在应用沙箱内处理，避免把原始文件上传到网络。',
            '临时文件写入应用私有目录，便于生成、保存和再次打开；你可以随时在“我的”页清理。',
            '结果默认先保存到沙箱，再由系统保存能力写入你选择的位置，不会擅自写入公共目录。'
          ]
        })
        .padding({ left: 16, right: 16 })

        GuideSectionCard({
          title: '3. 权限与鸿蒙要求',
          points: [
            '文件访问通过鸿蒙系统文件选择器完成，图片访问通过系统相册选择器完成，属于“用户主动选择、系统临时授权”的方式。',
            '当前版本不依赖广泛存储权限，也不需要后台持续访问文件系统。',
            '如果后续接入服务端转换能力或第三方库，会另行补充权限说明和隐私告知，并仅在必要时传输文件。'
          ]
        })
        .padding({ left: 16, right: 16 })

        GuideSectionCard({
          title: '4. 留存、删除与分享',
          points: [
            '历史记录最多保留 100 条，超出后会自动截断旧记录。',
            '“文件清理”会删除应用沙箱中的临时文件和本地历史记录。',
            '分享和打开结果均交由系统处理，应用不会在后台保存额外副本。'
          ]
        })
        .padding({ left: 16, right: 16 })

        GuideSectionCard({
          title: '5. 你的控制权',
          points: [
            '你可以随时停止使用某个工具、删除记录或清空临时文件。',
            '如果不授予文件/相册选择，相关功能不会继续执行，也不会退而求其次读取其他内容。',
            '对于当前未实现的远程转换入口，页面会明确提示“需接入服务端转换能力”，不会偷偷上传原始文件。'
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
