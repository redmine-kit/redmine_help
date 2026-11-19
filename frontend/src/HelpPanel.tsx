import { useCallback, useEffect, useRef, useState, type FormEvent } from 'react';
import { AppLink, ExtensionPanelHeader, useExtensionContext, useKitQuery, useT } from '@redmine-kit/plugin';
import { IconButton, SearchInput } from '@redmine-kit/ui';
import { helpHref, helpPaths, type HelpContextJson, type HelpView } from './api';
import { HelpContents, HelpLoadError, HelpResults, HelpTextSkeleton, HelpTopicView, helpLinkCapture } from './HelpContent';

// HelpPanel: the help for the current screen in the app's panel at the right (the slot topbar.panel; the app draws the
// panel, its title ヘルプ and ✕), the new UI's form of Redmine Kit Help's side panel (docs/README.md "Side panel"). Moved
// from ui-mock (screens/help-parts/HelpPanelHost.tsx), on the plugin's JSON:
// - It shows the topic the map gives the app's screen (useExtensionContext().screen → /help/context.json, the same map.yml
//   as Redmine's own screens: config/kit_screens.yml), at the mapped heading; a screen without one shows the contents.
// - Links between topics and the search stay in the panel, and 戻る returns to the page before (with its scroll).
// - The header's subtitle is the topic's title (or 検索, 目次); its actions: 戻る (when there is a page before), 目次 and
//   全画面で表示 (the help page of what is shown). Under it the search (live: results as the user types).
// - It stays open while the user moves between screens and then shows the new screen's topic; a change of the screen's
//   tab moves it only when the map has a topic for that tab (`follow`).
// Not declared in config/kit_ui.yml yet: the app draws its own help panel until the extension API has G37 (anonymous
// visitors), G38 (the TopBar's ヘルプ), G39 (the ? key and the editors' links open a topic) and G50 (open across
// reloads) (ui-restructure-plan.md 5.3).

type Entry = { view: HelpView; scroll?: number };

export function HelpPanel() {
  const t = useT();
  const { screen } = useExtensionContext();
  const name = screen?.name ?? null;
  const tab = screen?.tab ?? null;
  const context = useKitQuery<HelpContextJson>(name ? helpPaths.context(name, tab) : null);
  const [current, setCurrent] = useState<Entry | null>(null);
  const [trail, setTrail] = useState<Entry[]>([]);
  const [q, setQ] = useState('');
  const [title, setTitle] = useState('');
  const body = useRef<HTMLDivElement>(null);

  // the screen's topic: when the panel opens, on another screen, and on another tab of the screen when the map has one
  const screenView: HelpView | null = !name
    ? { kind: 'contents' }
    : context.data
      ? context.data.help.topic
        ? { kind: 'topic', id: context.data.help.topic, anchor: context.data.help.anchor ?? undefined }
        : { kind: 'contents' }
      : null;
  const seen = useRef<{ name: string | null; tab: string | null } | null>(null);
  useEffect(() => {
    if (!screenView) return;
    const prev = seen.current;
    const moved = !prev || prev.name !== name;
    const tabMoved = !!prev && prev.name === name && prev.tab !== tab && !!context.data?.help.follow;
    seen.current = { name, tab };
    if (moved || tabMoved) {
      setCurrent({ view: screenView });
      setTrail([]);
      setQ('');
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [name, tab, screenView?.kind, screenView && 'id' in screenView ? screenView.id : null]);

  const currentRef = useRef(current);
  currentRef.current = current;
  const go = useCallback((view: HelpView) => {
    const from = currentRef.current;
    if (from) setTrail((list) => [...list, { view: from.view, scroll: body.current?.scrollTop ?? 0 }]);
    setCurrent({ view });
    if (view.kind !== 'search') setQ('');
  }, []);
  const back = () => {
    const prev = trail[trail.length - 1];
    if (!prev) return;
    setTrail(trail.slice(0, -1));
    setCurrent(prev);
    setQ(prev.view.kind === 'search' ? prev.view.q : '');
  };
  // the search: results as the user types; clearing it returns to the page before
  const onSearch = (value: string) => {
    setQ(value);
    const text = value.trim();
    if (!text) {
      if (current?.view.kind === 'search') back();
      return;
    }
    if (current?.view.kind === 'search') setCurrent({ view: { kind: 'search', q: text } });
    else go({ kind: 'search', q: text });
  };
  const onSubmit = (e: FormEvent) => e.preventDefault();

  const view = current?.view;
  const subtitle = view?.kind === 'topic' ? title : view?.kind === 'search' ? t('label_search') : t('label_table_of_contents');
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <ExtensionPanelHeader
        subtitle={view ? subtitle : undefined}
        actions={
          <>
            {trail.length > 0 && <IconButton icon="chevron-left" aria-label={t('button_back')} onClick={back} />}
            <IconButton icon="list-bullet" aria-label={t('label_table_of_contents')} pressed={view?.kind === 'contents'} onClick={() => view?.kind !== 'contents' && go({ kind: 'contents' })} />
            <IconButton asChild icon="expand" aria-label={t('label_open_in_full_view')}>
              <AppLink href={helpHref(view ?? { kind: 'contents' })} />
            </IconButton>
          </>
        }
      />
      <form role="search" onSubmit={onSubmit} className="flex-none px-5 pt-3">
        <SearchInput size={28} aria-label={t('label_search')} placeholder={t('label_search')} value={q} onChange={(e) => onSearch(e.target.value)} onClear={() => onSearch('')} />
      </form>
      <div ref={body} onClickCapture={helpLinkCapture(go)} className="min-h-0 flex-1 overflow-y-auto overscroll-contain ps-5 pe-4 pt-4 pb-6">
        {context.isError ? (
          <HelpLoadError />
        ) : !view ? (
          <HelpTextSkeleton />
        ) : view.kind === 'topic' ? (
          <HelpTopicView key={view.id + (view.anchor ?? '')} id={view.id} anchor={view.anchor} scroller={body} restore={current?.scroll} onTitle={setTitle} />
        ) : view.kind === 'search' ? (
          <HelpResults q={view.q} />
        ) : (
          <HelpContents />
        )}
      </div>
    </div>
  );
}
