import { useEffect, useRef, type MouseEvent, type RefObject } from 'react';
import { AppLink, useKitQuery, useT } from '@redmine-kit/plugin';
import { EmptyState, Icon, NavRow, Prose, RequestErrorState, SectionHeading, Skeleton, SkeletonRegion, cn } from '@redmine-kit/ui';
import { helpBody, helpHref, helpPaths, helpViewOf, type HelpContentsJson, type HelpSearchJson, type HelpTopicJson, type HelpView } from './api';

// The help's content, shared by the help panel (HelpPanel) and the help page (HelpPage), as Redmine's help panel and pages
// share their partials (_topic, _results, _contents). Moved from ui (screens/help-parts/HelpContent.tsx), on the
// plugin's JSON instead of the app's sample guide.
// - HelpTopicView: the topic's text (Prose, without its # title) and the operator's blocks under it (_support.md: every
//   page, then this topic). Opens at the view's heading (its anchor, in the topic's language: the JSON's).
// - HelpResults: 結果 (N), each topic's title and a snippet; 表示するデータがありません when nothing matches.
// - HelpContents: the sections (the operator's first) with their topics; without the guide, HelpGuideMissing first.
// Links between topics (/help/<topic>) call `onGo` when given (the panel keeps them inside itself); without it they are
// links of this server (the page).

const plain = (e: MouseEvent) => e.button === 0 && !e.metaKey && !e.ctrlKey && !e.shiftKey && !e.altKey;

/** A click handler for a container of help links: a plain click on a help link goes through `onGo`. */
export function helpLinkCapture(onGo?: (view: HelpView) => void) {
  return (e: MouseEvent) => {
    const href = (e.target as Element).closest('a')?.getAttribute('href');
    if (!href || !onGo || !plain(e)) return;
    const view = helpViewOf(href);
    if (!view) return;
    e.preventDefault();
    onGo(view);
  };
}

/** The lines of a loading topic or list, where the text will be. */
export function HelpTextSkeleton() {
  const t = useT();
  return (
    <SkeletonRegion label={t('label_loading')} className="flex flex-col gap-3">
      <Skeleton width="90%" />
      <Skeleton width="80%" />
      <Skeleton width="85%" />
      <Skeleton width="40%" />
    </SkeletonRegion>
  );
}

export interface HelpTopicViewProps {
  id: string;
  anchor?: string;
  /** the element that scrolls (the panel's body or the page's pane) */
  scroller: RefObject<HTMLElement | null>;
  /** a scroll position to restore instead (戻る) */
  restore?: number;
  /** the reading width of the page */
  reading?: boolean;
  /** the topic's title, once it is known (the panel's subtitle, the page's heading) */
  onTitle?: (title: string) => void;
}

export function HelpTopicView({ id, anchor, scroller, restore, reading = false, onTitle }: HelpTopicViewProps) {
  const query = useKitQuery<HelpTopicJson>(helpPaths.topic(id, anchor));
  const prose = useRef<HTMLDivElement>(null);
  const data = query.data?.help;
  const title = data?.topic.title;
  useEffect(() => {
    if (title) onTitle?.(title);
  }, [title, onTitle]);
  // a passive effect: the scroller may be a parent mounted in the same commit
  useEffect(() => {
    const box = scroller.current;
    if (!box || !data) return;
    if (restore !== undefined) {
      box.scrollTop = restore;
      return;
    }
    // the heading of the anchor (Prose gives headings their anchor as id); the # title isn't shown
    const target = data.topic.anchor ? [...(prose.current?.querySelectorAll('[id]') ?? [])].find((el) => el.id === data.topic.anchor) : null;
    box.scrollTop = target ? target.getBoundingClientRect().top - box.getBoundingClientRect().top + box.scrollTop - 12 : 0;
  }, [data, restore, scroller]);
  if (query.isPending) return <HelpTextSkeleton />;
  // a topic the server doesn't have (a link to a removed topic) is Redmine's 404
  if (query.isError) return <RequestErrorState error={query.error} onRetry={() => void query.refetch()} retrying={query.isFetching} />;
  return (
    <>
      <Prose ref={prose} text={helpBody(data!.topic.body)} reading={reading} />
      {data!.support.map((text, i) => (
        // the operator's block (_support.md): the band fill of Prose's own blocks, so it reads as a note under the text
        <div key={i} className={cn('mt-4 rounded-control bg-surface-band px-3 py-2', reading && 'max-w-190')}>
          <Prose text={text} />
        </div>
      ))}
    </>
  );
}

export function HelpResults({ q }: { q: string }) {
  const t = useT();
  const query = useKitQuery<HelpSearchJson>(helpPaths.search(q));
  if (query.isPending) return <HelpTextSkeleton />;
  if (query.isError) return <RequestErrorState error={query.error} onRetry={() => void query.refetch()} retrying={query.isFetching} />;
  const results = query.data.help.results;
  return (
    <section aria-label={t('label_result_plural')} className="flex flex-col">
      <SectionHeading heading={t('label_result_plural')} count={results.length} level={3} />
      {results.length === 0 ? (
        <EmptyState variant="block" text={t('label_no_data')} />
      ) : (
        <ul className="flex flex-col">
          {results.map((result) => (
            <li key={result.id} className="flex flex-col gap-0.5 py-2">
              <AppLink href={helpHref({ kind: 'topic', id: result.id })} className="inline-flex items-center gap-1.5 self-start text-body font-medium text-text-link no-underline hover:text-text-link-hover">
                <Icon name="wiki" size={14} className="flex-none text-text-muted" />
                {result.title}
              </AppLink>
              <span className="line-clamp-2 text-meta text-text-muted">{result.snippet}</span>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}

/** Without the Redmine guide (docs/setup.md, "The guide"): the contents say so first, as Redmine's page of the plugin does. */
export function HelpGuideMissing() {
  const t = useT();
  return <EmptyState variant="block" text={t('text_help_guide_missing')} />;
}

export function HelpContents({ current }: { current?: string }) {
  const t = useT();
  const query = useKitQuery<HelpContentsJson>(helpPaths.contents);
  if (query.isPending) return <HelpTextSkeleton />;
  if (query.isError) return <RequestErrorState error={query.error} onRetry={() => void query.refetch()} retrying={query.isFetching} />;
  return (
    <nav aria-label={t('label_table_of_contents')} className="flex flex-col gap-4">
      {!query.data.help.guide && <HelpGuideMissing />}
      {query.data.help.sections.map((section) => (
        <div key={section.id} className="flex flex-col gap-0.5">
          <SectionHeading heading={section.title} level={3} />
          {/* the same rows as the help page's contents (NavRow), the current topic selected; the text lines up with the
              heading's */}
          {section.topics.map((topic) => (
            <NavRow key={topic.id} href={helpHref({ kind: 'topic', id: topic.id })} selected={topic.id === current} className="-mx-2.25">
              {topic.title}
            </NavRow>
          ))}
        </div>
      ))}
    </nav>
  );
}
