import { useState } from 'react';
import { screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, expect, it } from 'vitest';
import { PanelHeaderContext } from '@redmine-kit/plugin/host'; // check-ui-ok: a test; the app's panel gives its header's places
import { HelpPage } from './HelpPage';
import { HelpPanel } from './HelpPanel';
import { renderKit } from './test/render';

// The panel and the page on the plugin's JSON as HelpTopicsController answers it (RedmineKit::Help::Json).
const CONTENTS = {
  help: {
    language: 'ja',
    sections: [
      { id: 'support', title: 'サポート', topics: [{ id: 'support/contact', title: '問い合わせ先' }] },
      { id: 'user', title: 'ユーザーガイド', topics: [{ id: 'user/issues', title: 'チケットトラッキング' }, { id: 'user/issue-list', title: 'チケットの一覧' }] },
    ],
  },
};
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
};
const panel = { close: () => undefined };

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
    expect(await screen.findByRole('link', { name: 'チケットトラッキング' })).toBeInTheDocument();
    expect(screen.getByText('…Redmine の中心です。')).toBeInTheDocument();
  });

  it('a failed load is a notice, never the error', async () => {
    renderKit(<InPanel />, { context: { plugin: 'redmine_kit_help', panel, screen: { name: 'Main', tab: null } }, responses: { 'GET /help/context.json?screen=Main': new Error('boom') } });
    expect(await screen.findByText('ヘルプを読み込めませんでした。')).toBeInTheDocument();
    expect(screen.queryByText('boom')).toBeNull();
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
});
