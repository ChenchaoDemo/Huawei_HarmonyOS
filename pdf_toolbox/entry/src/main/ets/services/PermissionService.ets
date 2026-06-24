import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { AppContext } from './AppContext';

const READ_IMAGEVIDEO: Permissions = 'ohos.permission.READ_IMAGEVIDEO' as Permissions;
const READ_DOCUMENT: Permissions = 'ohos.permission.READ_DOCUMENT' as Permissions;
const PERMISSION_GRANTED = 0;

function errorMessage(err: Error | Object): string {
  if (err instanceof Error) {
    return err.message;
  }
  return JSON.stringify(err);
}

function isUnsupportedPermissionError(message: string): boolean {
  const lower = message.toLowerCase();
  return lower.indexOf('invalid permission') >= 0 ||
    lower.indexOf('not support') >= 0 ||
    lower.indexOf('not supported') >= 0 ||
    lower.indexOf('not found') >= 0;
}

export class PermissionService {
  static async ensureImageReadPermission(): Promise<void> {
    await PermissionService.requestPermissions(
      [READ_IMAGEVIDEO],
      '需要照片和视频读取权限，才能读取你选择的图片。'
    );
  }

  static async ensureDocumentReadPermission(): Promise<void> {
    try {
      await PermissionService.requestPermissions(
        [READ_DOCUMENT],
        '需要文件读取权限，才能读取你选择的 PDF、文本或 Office 文件。'
      );
    } catch (err) {
      const message = errorMessage(err as Error | Object);
      if (isUnsupportedPermissionError(message)) {
        return;
      }
      throw err;
    }
  }

  private static async requestPermissions(permissions: Permissions[], deniedMessage: string): Promise<void> {
    const context: common.UIAbilityContext = AppContext.getContext();
    const atManager = abilityAccessCtrl.createAtManager();
    try {
      const result = await atManager.requestPermissionsFromUser(context, permissions);
      const denied = result.authResults.find((status: number) => status !== PERMISSION_GRANTED);
      if (denied !== undefined) {
        throw new Error(`${deniedMessage} 请在系统授权弹窗中选择允许，或到系统设置中开启权限后重试。`);
      }
    } catch (err) {
      if (err instanceof Error && err.message.indexOf(deniedMessage) >= 0) {
        throw err;
      }
      throw new Error(`权限申请失败：${errorMessage(err as Error | Object)}`);
    }
  }
}
