import { useCallback, useRef, useState, type FormEvent } from 'react';
import { ScreenSidebar, useExtensionContext, useKitNavigate, useKitQuery, useT } from '@redmine-kit/plugin';
import { Card, CardBody, CardHeader, SearchInput } from '@redmine-kit/ui';
import { helpHref, helpPaths, type HelpContentsJson, type HelpView } from './api';
import { HelpContents, HelpResults, HelpTopicView } from './HelpContent';

// HelpPage: the help pages (Redmine Kit Help's /help, /help/<topic>, /help/search), opened by the panel's 全画面で表示
// and shared by URL. Moved from ui-mock (screens/Help.tsx), on the plugin's JSON:
// - /help                the contents: every section and its topics;
// - /help/<topic>#<a>    a topic: its title in the header, the text (Prose, reading width) with the operator's blocks;
// - the search in the header: the results, in place.
// The sidebar is the plugin's (ScreenSidebar): ヘルプ, with 目次 and each section as a tree row with its topics (the
// current topic marked). No project: the help is the same for the whole Redmine server.
// Not declared in config/kit_ui.yml yet: a topic's address needs a screen path with a wildcard (/help/*topic, G51 of
// ui-restructure-plan.md 5.3; `params.topic` then), and the app keeps its own help page until G37–G39 and G50.

export function HelpPage() {
  const t = useT();
  const navigate = useKitNavigate();
  const { params } = useExtensionContext();
  const topic = params.topic;
  const [q, setQ] = useState('');
  const [title, setTitle] = useState('');
  const pane = useRef<HTMLDivElement>(null);
  const view: HelpView = q.trim() ? { kind: 'search', q: q.trim() } : topic ? { kind: 'topic', id: topic } : { kind: 'contents' };
  const go = useCallback((next: HelpView) => navigate(helpHref(next)), [navigate]);
  const onSubmit = (e: FormEvent) => {
    e.preventDefault();
    if (q.trim()) go({ kind: 'search', q: q.trim() });
  };
  const contents = useKitQuery<HelpContentsJson>(helpPaths.contents);
  const sections = contents.data?.help.sections ?? [];
  const groups = [
    {
      key: 'help',
      label: t('label_help'),
      rows: [
        { key: 'contents', label: t('label_table_of_contents'), icon: 'list-bullet', href: helpHref({ kind: 'contents' }), selected: view.kind === 'contents' },
        ...sections.map((section) => ({
          key: section.id,
          label: section.title,
          icon: 'folder',
          children: section.topics.map((item) => ({ key: item.id, label: item.title, href: helpHref({ kind: 'topic', id: item.id }), selected: item.id === topic })),
        })),
      ],
      loadingRows: contents.isPending ? 4 : undefined,
    },
  ];
  const heading = view.kind === 'topic' ? title || t('label_help') : view.kind === 'search' ? t('label_search') : t('label_help');
  return (
    <>
      <ScreenSidebar label={t('label_help')} groups={groups} />
      <Card aria-label={t('label_help')}>
        <CardHeader
          title={heading}
          actions={
            <form role="search" onSubmit={onSubmit}>
              <SearchInput aria-label={t('label_search')} placeholder={t('label_search')} value={q} onChange={(e) => setQ(e.target.value)} onClear={() => setQ('')} className="w-full" />
            </form>
          }
          divider
        />
        <CardBody padded>
          <div ref={pane}>
            {view.kind === 'topic' ? (
              <HelpTopicView id={view.id} scroller={pane} reading onTitle={setTitle} />
            ) : view.kind === 'search' ? (
              <HelpResults q={view.q} />
            ) : (
              <HelpContents />
            )}
          </div>
        </CardBody>
      </Card>
    </>
  );
}
