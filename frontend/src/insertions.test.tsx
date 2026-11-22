import { useRef } from 'react';
import { screen, within } from '@testing-library/react';
import { describe, expect, it } from 'vitest';
import { issuesTopicWithSections, topic } from './fixtures';
import { HelpTopicView } from './HelpContent';
import { HelpPage } from './HelpPage';
import { HelpPanel } from './HelpPanel';
import { renderKit } from './test/render';

// The plugins' sections in a guide's topic (docs/extending.md "Sections in the guide's topics"): the JSON's body has them,
// and `insertions` labels each heading with the plugin's name (and the section's language when it isn't the topic's), as
// Redmine's page does with .badge.

function Topic() {
  const scroller = useRef<HTMLDivElement>(null);
  return (
    <div ref={scroller}>
      <HelpTopicView id="user/issues" scroller={scroller} />
    </div>
  );
}

const RESPONSES = { 'GET /help/user/issues.json': issuesTopicWithSections };

describe("a plugin's section in a topic", () => {
  it("labels the inserted section's heading with the plugin's name, and only that heading", async () => {
    renderKit(<Topic />, { responses: RESPONSES });
    const checklist = await screen.findByRole('heading', { level: 2, name: /チェックリスト/ });
    expect(checklist).toHaveAttribute('id', 'チェックリスト');
    expect(within(checklist).getByText('Redmine Kit Checklist')).toBeInTheDocument();
    // a section in English in a Japanese topic says so
    const timer = screen.getByRole('heading', { level: 2, name: /Timer/ });
    expect(within(timer).getByText('Redmine Kit Timer (English)')).toBeInTheDocument();
    // the guide's own headings have no label
    expect(screen.getByRole('heading', { level: 2, name: /新しいチケット/ }).querySelector('[data-heading-badge]')).toBeNull();
    expect(screen.getByRole('heading', { level: 2, name: /ステータス/ }).querySelector('[data-heading-badge]')).toBeNull();
  });

  it("opens a plugin's screen at the topic and section the server maps it to", async () => {
    renderKit(<HelpPanel />, {
      context: {
        plugin: 'redmine_kit_help',
        panel: { close: () => undefined, request: { target: 'context', key: 1 } },
        screen: { name: 'redmine_kit_checklist:ChecklistScreen', tab: null },
      },
      responses: {
        [`GET /help/user/issues.json?anchor=${encodeURIComponent('チェックリスト')}`]: issuesTopicWithSections,
        'GET /help/context.json?screen=redmine_kit_checklist%3AChecklistScreen': { help: { topic: 'user/issues', anchor: 'チェックリスト', follow: false } },
      },
    });
    const checklist = await screen.findByRole('heading', { level: 2, name: /チェックリスト/ });
    expect(within(checklist).getByText('Redmine Kit Checklist')).toBeInTheDocument();
  });

  it("lists a plugin's subsection of an h3 (an h4) in the help page's 目次, under that h3, without its label", async () => {
    const body = '## チケットの表示\n\n表示します。\n\n### 関連するチケット\n\n関連付けます。\n\n#### 依存関係\n\n開始-開始の関連です。';
    const withH4 = topic('user/issues', 'チケットトラッキング', body, [
      { anchor: '依存関係', plugin: 'redmine_kit_dependencies', name: 'Redmine Kit Dependencies', language: 'ja', label: 'Redmine Kit Dependencies' },
    ]);
    renderKit(<HelpPage />, { context: { plugin: 'redmine_kit_help', params: { topic: 'user/issues' } }, responses: { 'GET /help.json': { help: { language: 'ja', guide: true, sections: [] } }, 'GET /help/user/issues.json': withH4 } });
    const toc = await screen.findByRole('complementary', { name: '目次' });
    expect(await within(toc).findByRole('link', { name: '依存関係' })).toHaveAttribute('href', '#依存関係');
    expect(within(toc).getByRole('link', { name: '関連するチケット' })).toBeInTheDocument();
  });
});
