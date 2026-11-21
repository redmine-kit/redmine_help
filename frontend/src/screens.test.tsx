import { useState } from 'react';
import { screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, expect, it } from 'vitest';
import type { KitTestRequest } from '@redmine-kit/plugin/testing';
import { ApiError } from '@redmine-kit/plugin';
import { ExtensionContext, PanelHeaderContext } from '@redmine-kit/plugin/host'; // check-ui-ok: a test; the app's panel gives its header's places and its requests
import type { ExtensionPanelTarget } from '@redmine-kit/plugin';
import { Button } from '@redmine-kit/ui';
import { HelpCodeHighlighting, HelpPage, HelpWikiSyntax } from './HelpPage';
import { HelpPanel } from './HelpPanel';
import { renderKit } from './test/render';

// The panel and the page on the plugin's JSON as HelpTopicsController answers it (RedmineKit::Help::Json).
const CONTENTS = {
  help: {
    language: 'ja',
    guide: true,
    sections: [
      { id: 'support', title: 'サポート', topics: [{ id: 'support/contact', title: '問い合わせ先' }] },
      { id: 'user', title: 'ユーザーガイド', topics: [{ id: 'user/issues', title: 'チケットトラッキング' }, { id: 'user/issue-list', title: 'チケットの一覧' }] },
    ],
  },
};
// without the guide (docs/setup.md): the operator's section only
const NO_GUIDE = { help: { language: 'ja', guide: false, sections: [CONTENTS.help.sections[0]] } };
const GUIDE_MISSING = 'Redmine のガイドがインストールされていません。システム管理者にインストールを依頼してください。';
const topic = (id: string, title: string, body: string) => ({
  help: { topic: { id, title, language: 'ja', anchors: [], body: `# ${title}\n\n${body}`, anchor: null }, support: ['**ヘルプデスク:** 内線 1234'], section: null },
});
const RESPONSES = {
  'GET /help.json': CONTENTS,
  'GET /help/context.json?screen=ProjectTable': { help: { topic: 'user/issue-list', anchor: null, follow: false } },
  'GET /help/context.json?screen=News': { help: { topic: null, anchor: null, follow: false } },
  'GET /help/user/issue-list.json': topic('user/issue-list', 'チケットの一覧', '[チケット](/help/user/issues) を開きます。'),
  'GET /help/user/issues.json': topic('user/issues', 'チケットトラッキング', 'チケットは Redmine の中心です。'),
  'GET /help/search.json?q=%E4%B8%AD%E5%BF%83': { help: { q: '中心', results: [{ id: 'user/issues', title: 'チケットトラッキング', snippet: '…Redmine の中心です。' }] } },
  'GET /help/user/keyboard-navigation.json': topic('user/keyboard-navigation', 'キーボード操作', 'キーで移動します。'),
  'GET /help/context.json?syntax=wiki': { help: { topic: 'user/text-formatting-markdown', anchor: null, follow: false } },
  'GET /help/context.json?syntax=code': { help: { topic: 'user/code-highlighting-languages', anchor: null, follow: false } },
  'GET /help/user/text-formatting-markdown.json': topic('user/text-formatting-markdown', 'Markdown', '## 強調\n\n太字にします。\n\n## リンク\n\nリンクを書きます。'),
  'GET /help/user/code-highlighting-languages.json': topic('user/code-highlighting-languages', 'コードハイライト', 'Ruby を使えます。'),
};
const panel = { close: () => undefined, request: { target: 'context' as const, key: 1 } };

/** The panel as the app draws it, with the app's requests: each button opens it again at a target (a new key). */
function Requested() {
  const [request, setRequest] = useState<{ target: ExtensionPanelTarget; key: number }>({ target: 'context', key: 1 });
  const ask = (target: ExtensionPanelTarget) => setRequest((now) => ({ target, key: now.key + 1 }));
  return (
    <>
      <Button onClick={() => ask('keyboard')}>?</Button>
      <Button onClick={() => ask('wiki_syntax')}>すべての記法</Button>
      <Button onClick={() => ask('context')}>ヘルプ</Button>
      <ExtensionContext.Provider value={{ plugin: 'redmine_kit_help', project: null, issueId: null, screen: { name: 'ProjectTable', tab: null }, panel: { close: () => undefined, request } }}>
        <InPanel />
      </ExtensionContext.Provider>
    </>
  );
}

/** The panel as the app draws it: its header with the places for the subtitle and the actions. */
function InPanel() {
  const [subtitle, setSubtitle] = useState<HTMLElement | null>(null);
  const [actions, setActions] = useState<HTMLElement | null>(null);
  return (
    <>
      <header>
        <div ref={setSubtitle} data-testid="subtitle" />
        <span ref={setActions} />
      </header>
      <PanelHeaderContext.Provider value={{ subtitle, actions }}>
        <HelpPanel />
      </PanelHeaderContext.Provider>
    </>
  );
}

describe('the help panel', () => {
  it("opens the screen's topic, with the operator's block; a link stays in the panel and 戻る returns", async () => {
    const user = userEvent.setup();
    renderKit(<InPanel />, { context: { plugin: 'redmine_kit_help', panel, screen: { name: 'ProjectTable', tab: null } }, responses: RESPONSES });
    expect(await screen.findByText('を開きます。', { exact: false })).toBeInTheDocument();
    expect(screen.getByText('内線 1234', { exact: false })).toBeInTheDocument();
    expect(screen.getByTestId('subtitle')).toHaveTextContent('チケットの一覧');
    expect(screen.getByRole('link', { name: '全画面で表示' })).toHaveAttribute('href', '/help/user/issue-list');
    // the # title is the header's, not the text's
    expect(screen.queryByRole('heading', { name: 'チケットの一覧' })).toBeNull();
    await user.click(screen.getByRole('link', { name: 'チケット' }));
    expect(await screen.findByText('チケットは Redmine の中心です。')).toBeInTheDocument();
    await user.click(screen.getByRole('button', { name: '戻る' }));
    expect(await screen.findByText('を開きます。', { exact: false })).toBeInTheDocument();
  });

  it('a screen without a topic shows the contents; the search shows results as the user types', async () => {
    const user = userEvent.setup();
    renderKit(<InPanel />, { context: { plugin: 'redmine_kit_help', panel, screen: { name: 'News', tab: null } }, responses: RESPONSES });
    expect(await screen.findByRole('navigation', { name: '目次' })).toBeInTheDocument();
    expect(screen.getByRole('link', { name: '問い合わせ先' })).toHaveAttribute('href', '/help/support/contact');
    await user.type(screen.getByRole('searchbox', { name: '検索' }), '中心');
    expect(await screen.findByText('…Redmine の中心です。')).toBeInTheDocument();
    expect(screen.getByRole('link', { name: 'チケットトラッキング' })).toBeInTheDocument();
  });

  it('the search asks once the user pauses (SEARCH_DELAY_MS), not on every key', async () => {
    const user = userEvent.setup();
    const requests: KitTestRequest[] = [];
    renderKit(<InPanel />, { context: { plugin: 'redmine_kit_help', panel, screen: { name: 'News', tab: null } }, responses: RESPONSES, requests });
    await screen.findByRole('navigation', { name: '目次' });
    await user.type(screen.getByRole('searchbox', { name: '検索' }), '中心');
    expect(await screen.findByText('…Redmine の中心です。')).toBeInTheDocument();
    expect(requests.filter((r) => r.path.startsWith('/help/search')).map((r) => r.path)).toEqual(['/help/search.json?q=%E4%B8%AD%E5%BF%83']);
  });

  it('a topic the server doesn’t have: Redmine’s words in its place', async () => {
    const missing = { 'GET /help/context.json?screen=Gone': { help: { topic: 'user/gone', anchor: null, follow: false } }, 'GET /help/user/gone.json': new ApiError(404, []) };
    renderKit(<InPanel />, { context: { plugin: 'redmine_kit_help', panel, screen: { name: 'Gone', tab: null } }, responses: { ...RESPONSES, ...missing } });
    expect(await screen.findByText('アクセスしようとしたページは存在しないか削除されています。')).toBeInTheDocument();
  });

  // docs/setup.md: without the guide, the contents say that no guide is installed (they were an empty 目次)
  it('without the guide, the contents say so', async () => {
    renderKit(<InPanel />, { context: { plugin: 'redmine_kit_help', panel, screen: { name: 'News', tab: null } }, responses: { ...RESPONSES, 'GET /help.json': NO_GUIDE } });
    const contents = await screen.findByRole('navigation', { name: '目次' });
    expect(contents).toHaveTextContent(GUIDE_MISSING);
    expect(screen.getByRole('link', { name: '問い合わせ先' })).toBeInTheDocument();
  });

  it('a failed load is the app’s failed-read state with 再読み込み, never the error', async () => {
    renderKit(<InPanel />, { context: { plugin: 'redmine_kit_help', panel, screen: { name: 'Main', tab: null } }, responses: { 'GET /help/context.json?screen=Main': new Error('boom') } });
    expect(await screen.findByText('データを読み込めませんでした。しばらくしてから、もう一度開いてください。')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: '再読み込み' })).toBeInTheDocument();
    expect(screen.queryByText('boom')).toBeNull();
  });
});

describe("the app's requests to the panel", () => {
  it('opens the keyboard’s topic, the text formatting’s, and the screen’s again, each with a fresh trail', async () => {
    const user = userEvent.setup();
    renderKit(<Requested />, { context: { plugin: 'redmine_kit_help' }, responses: RESPONSES });
    expect(await screen.findByText('を開きます。', { exact: false })).toBeInTheDocument();
    await user.click(screen.getByRole('button', { name: '?' }));
    expect(await screen.findByText('キーで移動します。')).toBeInTheDocument();
    expect(screen.getByTestId('subtitle')).toHaveTextContent('キーボード操作');
    expect(screen.queryByRole('button', { name: '戻る' })).toBeNull();
    await user.click(screen.getByRole('button', { name: 'すべての記法' }));
    expect(await screen.findByText('太字にします。')).toBeInTheDocument();
    expect(screen.getByRole('link', { name: '全画面で表示' })).toHaveAttribute('href', '/help/user/text-formatting-markdown');
    await user.click(screen.getByRole('button', { name: 'ヘルプ' }));
    expect(await screen.findByText('を開きます。', { exact: false })).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: '戻る' })).toBeNull();
  });
});

describe('the help page', () => {
  it('the contents, and a topic with its title in the header', async () => {
    const contents = renderKit(<HelpPage />, { context: { plugin: 'redmine_kit_help' }, responses: RESPONSES });
    expect(await screen.findByRole('link', { name: 'チケットの一覧' })).toHaveAttribute('href', '/help/user/issue-list');
    contents.unmount();
    renderKit(<HelpPage />, { context: { plugin: 'redmine_kit_help', params: { topic: 'user/issues' } }, responses: RESPONSES });
    expect(await screen.findByRole('heading', { name: 'チケットトラッキング' })).toBeInTheDocument();
    expect(screen.getByText('チケットは Redmine の中心です。')).toBeInTheDocument();
  });

  it('a topic the server doesn’t have (a link to a removed topic): Redmine’s 404', async () => {
    renderKit(<HelpPage />, { context: { plugin: 'redmine_kit_help', params: { topic: 'user/gone' } }, responses: { ...RESPONSES, 'GET /help/user/gone.json': new ApiError(404, []) } });
    expect(await screen.findByRole('heading', { name: 'アクセスしようとしたページは存在しないか削除されています。' })).toBeInTheDocument();
    expect(screen.getByText('404')).toBeInTheDocument();
  });

  it('the contents as sections of topics; the search in place, with 戻る to the contents', async () => {
    const user = userEvent.setup();
    renderKit(<HelpPage />, { context: { plugin: 'redmine_kit_help' }, responses: RESPONSES });
    const contents = await screen.findByRole('navigation', { name: '目次' });
    expect(contents.querySelectorAll('section')).toHaveLength(2);
    await user.type(screen.getByRole('searchbox', { name: '検索' }), '中心{Enter}');
    expect(await screen.findByText('…Redmine の中心です。')).toBeInTheDocument();
    await user.click(screen.getByRole('button', { name: 'ヘルプに戻る' }));
    expect(await screen.findByRole('navigation', { name: '目次' })).toBeInTheDocument();
  });

  it('a topic: one scroll, 目次 a sticky side column (ui forms.md "One scroll per form")', async () => {
    renderKit(<HelpWikiSyntax />, { context: { plugin: 'redmine_kit_help', params: { type: 'detailed' } }, responses: RESPONSES });
    await screen.findByText('太字にします。');
    const toc = screen.getByRole('complementary', { name: /目次|label_table_of_contents/ });
    expect(toc).toHaveAttribute('data-sticky');
    const article = screen.getByRole('article');
    expect(article.className).not.toMatch(/overflow/);
    expect(toc.className).not.toMatch(/overflow/);
  });

  it("Redmine's help pages show the plugin's topic, with the table of its headings", async () => {
    const wiki = renderKit(<HelpWikiSyntax />, { context: { plugin: 'redmine_kit_help', params: { type: 'detailed' } }, responses: RESPONSES });
    expect(await screen.findByText('太字にします。')).toBeInTheDocument();
    expect(screen.getByRole('heading', { name: 'Markdown', level: 1 })).toBeInTheDocument();
    const toc = await screen.findByRole('complementary', { name: '目次' });
    expect(toc).toHaveTextContent('強調');
    expect(toc).toHaveTextContent('リンク');
    wiki.unmount();
    renderKit(<HelpCodeHighlighting />, { context: { plugin: 'redmine_kit_help' }, responses: RESPONSES });
    expect(await screen.findByText('Ruby を使えます。')).toBeInTheDocument();
  });

  it('without the guide, the contents say so first; with no other help, only that', async () => {
    const page = renderKit(<HelpPage />, { context: { plugin: 'redmine_kit_help' }, responses: { ...RESPONSES, 'GET /help.json': NO_GUIDE } });
    expect(await screen.findByRole('navigation', { name: '目次' })).toHaveTextContent(GUIDE_MISSING);
    expect(screen.getByRole('link', { name: '問い合わせ先' })).toBeInTheDocument();
    page.unmount();
    renderKit(<HelpPage />, { context: { plugin: 'redmine_kit_help' }, responses: { ...RESPONSES, 'GET /help.json': { help: { language: 'ja', guide: false, sections: [] } } } });
    const contents = await screen.findByRole('navigation', { name: '目次' });
    expect(contents).toHaveTextContent(GUIDE_MISSING);
    expect(contents.querySelectorAll('section')).toHaveLength(0);
  });

  it("Redmine's help page whose topic fails to load: the failed-read state with 再読み込み", async () => {
    renderKit(<HelpWikiSyntax />, { context: { plugin: 'redmine_kit_help' }, responses: { ...RESPONSES, 'GET /help/context.json?syntax=wiki': new Error('boom') } });
    expect(await screen.findByText('データを読み込めませんでした。しばらくしてから、もう一度開いてください。')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: '再読み込み' })).toBeInTheDocument();
  });
});
