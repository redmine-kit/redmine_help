import { useCallback, useEffect, useLayoutEffect, useRef, useState, type FormEvent, type ReactNode, type RefObject } from 'react';
import { ScreenSidebar, useExtensionContext, useKitNavigate, useKitQuery, useT } from '@redmine-kit/plugin';
import { Card, CardBody, CardHeader, NavRow, PageToc, Pane, Panes, SearchInput, SectionHeading, TitleBlock } from '@redmine-kit/ui';
import { contextView, helpHref, helpPaths, type HelpContentsJson, type HelpContextJson, type HelpSyntax, type HelpView } from './api';
import { HelpGuideMissing, HelpLoadError, HelpResults, HelpTextSkeleton, HelpTopicView, helpLinkCapture } from './HelpContent';

// HelpPage: the help pages (Redmine Kit Help's /help, /help/<topic>, /help/search), opened by the panel's 全画面で表示
// and shared by URL. Moved from ui (screens/Help.tsx), on the plugin's JSON:
// - /help                the contents: every section and its topics, side by side as far as the card is wide;
// - /help/<topic>#<a>    a topic (config/kit_ui.yml's /help/*topic: `params.topic`): its title (TitleBlock, no path line:
//                        the sidebar lists the sections), the text (Prose, reading width) with the operator's blocks,
//                        and its headings (PageToc) in the right pane, the heading in view current; it opens at the
//                        anchor's heading;
// - /help/search?q=      the results, with 戻る to the contents;
// - Redmine's help pages, /help/wiki_syntax[/detailed] and /help/code_highlighting (`syntax`: HelpWikiSyntax,
//   HelpCodeHighlighting): the topic the plugin gives them (the server's text formatting's, Textile's or Markdown's; the
//   code highlighting's languages), drawn at Redmine's address (the back button never comes back to a redirect).
// The search is in the header. The sidebar is the plugin's (ScreenSidebar): ヘルプ, with 目次 and each section as a tree
// row with its topics (the current topic marked). No project: the help is the same for the whole Redmine server.

export function HelpPage({ syntax }: { syntax?: HelpSyntax }) {
  const t = useT();
  const { params } = useExtensionContext();
  const resolved = useKitQuery<HelpContextJson>(syntax ? helpPaths.syntax(syntax) : null);
  // the search, in place (the address /help/search?q= opens it: the panel's 全画面で表示 of its results); another topic
  // or the contents leaves it
  const [searched, setSearched] = useState(addressQuery);
  const [q, setQ] = useState(searched);
  const [shownTopic, setShownTopic] = useState(params.topic);
  if (shownTopic !== params.topic) {
    setShownTopic(params.topic);
    setSearched('');
    setQ('');
  }
  const view: HelpView | null = searched
    ? { kind: 'search', q: searched }
    : syntax
      ? resolved.data
        ? contextView(resolved.data)
        : null
      : params.topic
        ? { kind: 'topic', id: params.topic, anchor: addressAnchor() }
        : { kind: 'contents' };
  const onSearch = (e: FormEvent) => {
    e.preventDefault();
    setSearched(q.trim());
  };
  const search = (
    <form role="search" onSubmit={onSearch} className="flex w-60 @max-phone:w-full">
      <SearchInput aria-label={t('label_search')} placeholder={t('label_search')} value={q} onChange={(e) => setQ(e.target.value)} onClear={() => setQ('')} className="w-full" />
    </form>
  );

  const contents = useKitQuery<HelpContentsJson>(helpPaths.contents);
  const sections = contents.data?.help.sections ?? [];
  const current = view?.kind === 'topic' ? view.id : undefined;
  const groups = [
    {
      key: 'help',
      label: t('label_help'),
      rows: [
        { key: 'contents', label: t('label_table_of_contents'), icon: 'list-bullet', href: helpHref({ kind: 'contents' }), selected: view?.kind === 'contents' },
        ...sections.map((section) => ({
          key: section.id,
          label: section.title,
          icon: 'folder',
          children: section.topics.map((item) => ({ key: item.id, label: item.title, href: helpHref({ kind: 'topic', id: item.id }), selected: item.id === current })),
        })),
      ],
      loadingRows: contents.isPending ? 4 : undefined,
    },
  ];

  let body: ReactNode;
  if (!view) {
    body = (
      <>
        <CardHeader title={t('label_help')} actions={search} sidebarToggle sidebarLabel={t('label_help')} divider />
        <CardBody padded>{resolved.isError ? <HelpLoadError /> : <HelpTextSkeleton />}</CardBody>
      </>
    );
  } else if (view.kind === 'topic') {
    body = <TopicPage key={view.id} id={view.id} anchor={view.anchor} search={search} />;
  } else if (view.kind === 'search') {
    body = (
      <>
        <CardHeader title={t('label_search')} back={{ label: t('label_help_back'), onClick: () => (setSearched(''), setQ('')) }} actions={search} sidebarToggle sidebarLabel={t('label_help')} divider />
        <CardBody padded>
          <HelpResults q={view.q} />
        </CardBody>
      </>
    );
  } else {
    body = (
      <>
        <CardHeader title={t('label_help')} actions={search} sidebarToggle sidebarLabel={t('label_help')} divider />
        <CardBody padded>
          <Contents data={contents.data} failed={contents.isError} />
        </CardBody>
      </>
    );
  }
  return (
    <>
      <ScreenSidebar label={t('label_help')} groups={groups} />
      <Card aria-label={t('label_help')}>{body}</Card>
    </>
  );
}

/** The words of the address /help/search?q= (the plugin's search page), else none. */
function addressQuery(): string {
  if (!/\/help\/search\/?$/.test(window.location.pathname)) return '';
  return (new URLSearchParams(window.location.search).get('q') ?? '').trim().slice(0, 100);
}

/** The heading the address asks for (/help/<topic>#<anchor>). */
function addressAnchor(): string | undefined {
  try {
    return window.location.hash ? decodeURIComponent(window.location.hash.slice(1)) : undefined;
  } catch {
    return undefined;
  }
}

/** Redmine's help#show_wiki_syntax (/help/wiki_syntax[/detailed]): the topic of the server's text formatting. */
export function HelpWikiSyntax() {
  return <HelpPage syntax="wiki" />;
}

/** Redmine's help#show_code_highlighting (/help/code_highlighting): the code highlighting's languages. */
export function HelpCodeHighlighting() {
  return <HelpPage syntax="code" />;
}

// The contents: each section's topics, side by side as far as the card is wide (groups with no line between them).
function Contents({ data, failed }: { data: HelpContentsJson | undefined; failed: boolean }) {
  const t = useT();
  if (failed) return <HelpLoadError />;
  if (!data) return <HelpTextSkeleton />;
  return (
    <nav aria-label={t('label_table_of_contents')} className="grid grid-cols-fill-240 items-start gap-x-8 gap-y-section-gap">
      {!data.help.guide && (
        <div className="col-span-full">
          <HelpGuideMissing />
        </div>
      )}
      {data.help.sections.map((section) => (
        <section key={section.id} aria-label={section.title} className="flex flex-col gap-0.5">
          <SectionHeading heading={section.title} count={section.topics.length} />
          {section.topics.map((topic) => (
            <NavRow key={topic.id} href={helpHref({ kind: 'topic', id: topic.id })} className="-mx-2.25">
              {topic.title}
            </NavRow>
          ))}
        </section>
      ))}
    </nav>
  );
}

type Heading = { level: number; text: string; id: string };

function TopicPage({ id, anchor, search }: { id: string; anchor?: string; search: ReactNode }) {
  const t = useT();
  const navigate = useKitNavigate();
  const [title, setTitle] = useState('');
  const article = useRef<HTMLElement>(null);
  // the view's one scroller: Panes' (the parent of its row of panes), where the anchor is scrolled to and 目次 follows
  const scroller = useRef<HTMLElement | null>(null);
  const panesRow = useCallback((row: HTMLDivElement | null) => {
    scroller.current = row?.parentElement ?? null;
  }, []);
  // The headings (目次): h2 and h3 of the topic's text as it was rendered (its first child; the operator's blocks after it
  // are not part of the topic), so the outline shows what the reader sees. A heading without an id gets one.
  const [outline, setOutline] = useState<Heading[]>([]);
  useLayoutEffect(() => {
    const box = article.current;
    if (!box) return;
    const read = () => {
      const root = box.firstElementChild;
      const next = Array.from(root?.querySelectorAll<HTMLElement>('h2, h3') ?? []).map((el, i) => {
        if (!el.id) el.id = `help-h-${i + 1}`;
        return { level: el.tagName === 'H3' ? 3 : 2, text: el.textContent?.trim() ?? '', id: el.id };
      });
      setOutline((now) => (JSON.stringify(now) === JSON.stringify(next) ? now : next));
    };
    read();
    const observer = new MutationObserver(read);
    observer.observe(box, { childList: true, subtree: true, characterData: true });
    return () => observer.disconnect();
  }, [id]);
  const spy = useHeadingInView(scroller, outline);
  return (
    <>
      <TitleBlock title={title || t('label_help')} actions={search} sidebarToggle sidebarLabel={t('label_help')} divider />
      {/* one scroll (ui docs/decisions/forms.md "One scroll per form"): Panes is the scroller, 目次 a sticky side column;
          below 1024px they stack */}
      <Panes ref={panesRow} dividers stacked>
        <Pane
          as="article"
          ref={article}
          aria-label={title || t('label_help')}
          onClickCapture={helpLinkCapture((next) => navigate(helpHref(next)))}
          className="box-content flex-[999_1_520px] px-6 pt-5 pb-6"
        >
          <HelpTopicView key={id + (anchor ?? '')} id={id} anchor={anchor} scroller={scroller} reading onTitle={setTitle} />
        </Pane>
        {outline.length > 1 && (
          <Pane as="aside" sticky aria-label={t('label_table_of_contents')} className="box-content flex min-w-50 flex-[0_1_244px] flex-col p-6">
            <PageToc items={outline.map((h) => ({ key: h.id, level: h.level, text: h.text, href: '#' + h.id }))} active={spy.active} onSelect={spy.jump} />
          </Pane>
        )}
      </Panes>
    </>
  );
}

/** The heading in view (the last one whose top is above the article's top, 16px under it), and a jump to one, 12px under
 *  the article's top: the app's wiki page's 目次 (its scroll-spy), for the topic's headings. */
function useHeadingInView(scroller: RefObject<HTMLElement | null>, headings: Heading[]) {
  const [active, setActive] = useState<string | undefined>(headings[0]?.id);
  useEffect(() => {
    const box = scroller.current;
    if (!box || headings.length === 0) return;
    const update = () => {
      const top = box.getBoundingClientRect().top + 16;
      let current = headings[0].id;
      for (const heading of headings) {
        const el = box.querySelector<HTMLElement>('#' + CSS.escape(heading.id));
        if (el && el.getBoundingClientRect().top <= top) current = heading.id;
      }
      setActive(current);
    };
    update();
    box.addEventListener('scroll', update, { passive: true });
    return () => box.removeEventListener('scroll', update);
  }, [scroller, headings]);
  const jump = useCallback(
    (key: string) => {
      const box = scroller.current;
      const el = box?.querySelector<HTMLElement>('#' + CSS.escape(key));
      if (!box || !el) return;
      box.scrollTo({ top: el.getBoundingClientRect().top - box.getBoundingClientRect().top + box.scrollTop - 12 });
      setActive(key);
    },
    [scroller],
  );
  return { active, jump };
}
