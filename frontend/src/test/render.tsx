import type { ReactNode } from 'react';
import { render } from '@testing-library/react';
import { KitTestHost, type KitTestHostProps } from '@redmine-kit/plugin/testing';
import ja from '../../../config/locales/ja.yml?raw';
import en from '../../../config/locales/en.yml?raw';

// A component of the module in a test, with the app's part (KitTestHost): the plugin's strings from its locale files
// (config/locales/{ja,en}.yml, flat; a plural as its `other` form: the test host's strings take no count), the
// permissions given.

/** The plugin's strings of a language: `key: value` lines, and a plural's `other` under its key. */
function strings(yml: string): Record<string, string> {
  const out: Record<string, string> = {};
  let plural = '';
  for (const line of yml.split('\n')) {
    const top = /^ {2}([a-z_0-9]+):\s*(.*)$/.exec(line);
    const sub = /^ {4}other:\s*(.*)$/.exec(line);
    const value = (v: string) => v.replace(/^"(.*)"$/, '$1').replace(/^'(.*)'$/, '$1');
    if (top) {
      plural = top[2] ? '' : top[1];
      if (top[2]) out[top[1]] = value(top[2]);
    } else if (sub && plural) out[plural] = value(sub[1]);
  }
  return out;
}

export const JA = strings(ja);
export const EN = strings(en);

/** Redmine's own strings the screens use (config/locales/{ja,en}.yml of Redmine 7.0.3), for the tests that read them. */
const REDMINE_JA: Record<string, string> = {
  label_help: 'ヘルプ',
  label_search: '検索',
  label_result_plural: '結果',
  label_table_of_contents: '目次',
  label_open_in_full_view: '全画面で表示',
  label_no_data: '表示するデータがありません',
  button_back: '戻る',
  notice_file_not_found: 'アクセスしようとしたページは存在しないか削除されています。',
};
const REDMINE_EN: Record<string, string> = { label_help: 'Help', label_search: 'Search', label_table_of_contents: 'Table of contents' };

export function renderKit(ui: ReactNode, { lang = 'ja', ...props }: Omit<KitTestHostProps, 'children'> & { lang?: 'ja' | 'en' } = {}) {
  const t = lang === 'ja' ? { ...REDMINE_JA, ...JA } : { ...REDMINE_EN, ...EN };
  return render(
    <KitTestHost strings={lang} t={t} {...props}>
      {ui}
    </KitTestHost>,
  );
}
