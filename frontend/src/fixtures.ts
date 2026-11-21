import type { HelpContentsJson, HelpContextJson, HelpSearchJson, HelpTopicJson } from './api';

// The stories' data: the plugin's JSON as HelpTopicsController answers it (RedmineKit::Help::Json, api.ts) for a Japanese
// user, the guide installed.

/** GET /help.json: the operator's section, then the guide's. */
export const contents: HelpContentsJson = {
  help: {
    language: 'ja',
    guide: true,
    sections: [
      { id: 'support', title: 'サポート', topics: [{ id: 'support/contact', title: '問い合わせ先' }] },
      {
        id: 'user',
        title: 'ユーザーガイド',
        topics: [
          { id: 'user/issues', title: 'チケットトラッキング' },
          { id: 'user/issue-list', title: 'チケットの一覧' },
          { id: 'user/text-formatting-markdown', title: 'Markdown' },
        ],
      },
    ],
  },
};

/** The contents without the Redmine guide: the operator's section only (the page says the guide is missing). */
export const contentsWithoutGuide: HelpContentsJson = { help: { language: 'ja', guide: false, sections: [contents.help.sections[0]] } };

/** GET /help/<topic>.json: a topic with its headings and the operator's block under it. */
export function topic(id: string, title: string, body: string): HelpTopicJson {
  const anchors = [...body.matchAll(/^## (.+)$/gm)].map((heading) => heading[1]);
  return {
    help: {
      topic: { id, title, language: 'ja', anchors: [title, ...anchors], body: `# ${title}\n\n${body}`, anchor: null },
      support: ['**ヘルプデスク:** 内線 1234 (平日 9:00〜18:00)'],
      section: { id: 'user', title: 'ユーザーガイド' },
    },
  };
}

export const issuesTopic = topic(
  'user/issues',
  'チケットトラッキング',
  'チケットは Redmine の中心です。[チケットの一覧](/help/user/issue-list) から開きます。\n\n## 新しいチケット\n\n**新しいチケット** で作成します。\n\n## ステータス\n\nワークフローに沿って変更します。',
);

export const markdownTopic = topic('user/text-formatting-markdown', 'Markdown', '## 強調\n\n`**太字**` で太字にします。\n\n## リンク\n\n`[文字](URL)` でリンクを書きます。');

export const codeTopic = topic('user/code-highlighting-languages', 'コードハイライト', '`ruby`、`javascript`、`sql` などを使えます。');

/** GET /help/context.json?screen=: the screen's topic (the issue list's), or none (the contents). */
export const issueListContext: HelpContextJson = { help: { topic: 'user/issues', anchor: null, follow: false } };
export const noContext: HelpContextJson = { help: { topic: null, anchor: null, follow: false } };

/** GET /help/search.json?q=: the topics with every word. */
export const searchResults: HelpSearchJson = { help: { q: '中心', results: [{ id: 'user/issues', title: 'チケットトラッキング', snippet: '…Redmine の中心です。' }] } };

/** Every answer of the help, by request. */
export const helpResponses = {
  'GET /help.json': contents,
  'GET /help/user/issues.json': issuesTopic,
  'GET /help/user/text-formatting-markdown.json': markdownTopic,
  'GET /help/user/code-highlighting-languages.json': codeTopic,
  'GET /help/search.json': searchResults,
  'GET /help/context.json': ({ url }: { url: URL }) => {
    const syntax = url.searchParams.get('syntax');
    if (syntax === 'wiki') return { help: { topic: 'user/text-formatting-markdown', anchor: null, follow: false } };
    if (syntax === 'code') return { help: { topic: 'user/code-highlighting-languages', anchor: null, follow: false } };
    return url.searchParams.get('screen') === 'ProjectTable' ? issueListContext : noContext;
  },
};
