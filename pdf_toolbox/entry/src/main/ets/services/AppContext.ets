import { common } from '@kit.AbilityKit';

export class AppContext {
  private static abilityContext?: common.UIAbilityContext;

  static setContext(context: common.UIAbilityContext): void {
    AppContext.abilityContext = context;
  }

  static getContext(): common.UIAbilityContext {
    if (!AppContext.abilityContext) {
      throw new Error('应用上下文尚未初始化');
    }
    return AppContext.abilityContext;
  }
}
