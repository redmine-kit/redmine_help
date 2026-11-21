import { useCallback, useEffect, useRef, useState, type FormEvent } from 'react';
import { AppLink, ExtensionPanelHeader, useExtensionContext, useKitQuery, useT } from '@redmine-kit/plugin';
import { IconButton, RequestErrorState, SearchInput, useListSearch } from '@redmine-kit/ui';
import { KEYBOARD_TOPIC, contextView, helpHref, helpPaths, type HelpContextJson, type HelpView } from './api';
import { HelpContents, HelpResults, HelpTextSkeleton, HelpTopicView, helpLinkCapture } from './HelpContent';

// HelpPanel: the help for the current screen in the app's panel at the right (the slot topbar.panel; the app draws the
// panel, its title ヘルプ and ✕), the new UI's form of Redmine Kit Help's side panel (docs/README.md "Side panel"). Moved
// from ui (screens/help-parts/HelpPanelHost.tsx), on the plugin's JSON:
// - It shows the topic the map gives the app's screen (useExtensionContext().screen → /help/context.json, the same map.yml
//   as Redmine's own screens: config/kit_screens.yml), at the mapped heading; a screen without one shows the contents.
// - Links between topics and the search stay in the panel, and 戻る returns to the page before (with its scroll).
// - The header's subtitle is the topic's title (or 検索, 目次); its actions: 戻る (when there is a page before), 目次 and
//   全画面で表示 (the help page of what is shown). Under it the search (live: results as the user types).
// - It stays open while the user moves between screens and then shows the new screen's topic; a change of the screen's
//   tab moves it only when the map has a topic for that tab (`follow`).
// - The app's requests (`panel.request`, a new key per opening): `context` the screen's topic (the TopBar's ヘルプ, and the
//   panel restored with the page: config/kit_ui.yml's `persist`), `keyboard` the keyboard's topic (the ? key),
//   `wiki_syntax` the topic of the server's text formatting (an editor's すべての記法: /help/context.json?syntax=wiki).
//   Each one starts a fresh trail.
// config/kit_ui.yml: the slot topbar.panel with `replaces: help` (the TopBar's ヘルプ is its toggle), `persist: true` and
// `anonymous: true` (anonymous visitors too, unless Redmine requires a login: the JSON answers them as the pages do).

type Entry = { view: HelpView; scroll?: number };

/** Outside the app's panel (a test without one): the screen's topic. */
const NO_REQUEST = { target: 'context', key: 0 } as const;

export function HelpPanel() {
  const t = useT();
  const { screen, panel } = useExtensionContext();
  const name = screen?.name ?? null;
  const tab = screen?.tab ?? null;
  const request = panel?.request ?? NO_REQUEST;
  const context = useKitQuery<HelpContextJson>(name ? helpPaths.context(name, tab) : null);
  const syntax = useKitQuery<HelpContextJson>(request.target === 'wiki_syntax' ? helpPaths.syntax('wiki') : null);
  const [current, setCurrent] = useState<Entry | null>(null);
  const [trail, setTrail] = useState<Entry[]>([]);
  // the search's text as typed, and the text it asks for after the pause (useListSearch: the app's lists' delay)
  const search = useListSearch();
  const q = search.text;
  const setQ = search.setText;
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
  // what the app asked for: the screen's topic, the keyboard's, the text formatting's
  const requested: HelpView | null =
    request.target === 'keyboard' ? { kind: 'topic', id: KEYBOARD_TOPIC } : request.target === 'wiki_syntax' ? (syntax.data ? contextView(syntax.data) : null) : screenView;
  const answered = useRef<number | null>(null);
  const seen = useRef<{ name: string | null; tab: string | null } | null>(null);
  // a new request (each opening): its view, a fresh trail
  useEffect(() => {
    if (!requested || answered.current === request.key) return;
    answered.current = request.key;
    seen.current = { name, tab };
    setCurrent({ view: requested });
    setTrail([]);
    setQ('');
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [request.key, requested?.kind, requested && 'id' in requested ? requested.id : null]);
  // then the screen it follows: another screen's topic, another tab's when the map has one
  useEffect(() => {
    if (!screenView || answered.current !== request.key) return;
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
  // the search: results as the user types, after the pause (one request per pause, not per key); clearing it returns to
  // the page before at once
  const onSearch = (value: string) => {
    setQ(value);
    if (!value.trim() && current?.view.kind === 'search') back();
  };
  const searched = search.searched;
  useEffect(() => {
    const shown = currentRef.current?.view;
    // the text the field shows now (a 戻る or another page may have changed it during the pause)
    if (!searched || searched !== q.trim() || (shown?.kind === 'search' && shown.q === searched)) return;
    if (shown?.kind === 'search') setCurrent({ view: { kind: 'search', q: searched } });
    else go({ kind: 'search', q: searched });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [searched]);
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
        {context.isError || syntax.isError ? (
          <RequestErrorState error={context.error ?? syntax.error} onRetry={() => void (context.isError ? context.refetch() : syntax.refetch())} />
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
