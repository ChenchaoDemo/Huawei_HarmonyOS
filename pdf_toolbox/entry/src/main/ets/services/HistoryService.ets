import { preferences } from '@kit.ArkData';
import { HistoryRecord } from '../models/ToolModels';
import { AppContext } from './AppContext';

const STORE_NAME = 'pdf_toolbox_history';
const KEY_RECORDS = 'records';
const MAX_RECORDS = 100;

async function getStore(): Promise<preferences.Preferences> {
  return preferences.getPreferences(AppContext.getContext(), STORE_NAME);
}

export class HistoryService {
  static async getRecords(): Promise<HistoryRecord[]> {
    const store = await getStore();
    const raw = await store.get(KEY_RECORDS, '[]');
    try {
      return JSON.parse(String(raw)) as HistoryRecord[];
    } catch (_) {
      return [];
    }
  }

  static async saveRecord(record: HistoryRecord): Promise<void> {
    const store = await getStore();
    const records = await HistoryService.getRecords();
    records.unshift(record);
    await store.put(KEY_RECORDS, JSON.stringify(records.slice(0, MAX_RECORDS)));
    await store.flush();
  }

  static async removeRecord(id: string): Promise<void> {
    const store = await getStore();
    const records = await HistoryService.getRecords();
    await store.put(KEY_RECORDS, JSON.stringify(records.filter((record: HistoryRecord) => record.id !== id)));
    await store.flush();
  }

  static async clearRecords(): Promise<void> {
    const store = await getStore();
    await store.delete(KEY_RECORDS);
    await store.flush();
  }
}
