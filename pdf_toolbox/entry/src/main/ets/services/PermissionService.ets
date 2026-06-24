export class PermissionService {
  static async ensureImageReadPermission(): Promise<void> {
    // PhotoViewPicker 会在用户主动选择图片后授予对应 URI 的访问能力；普通三方应用不应额外声明受限媒体读取权限。
    return;
  }

  static async ensureDocumentReadPermission(): Promise<void> {
    // DocumentViewPicker 会在用户主动选择文件后授予对应 URI 的访问能力；普通三方应用不应额外声明受限文档读取权限。
    return;
  }
}
