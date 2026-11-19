// The plugin's JSON (HelpTopicsController with .json, RedmineKit::Help::Json): the same help, language and map as
// Redmine's own help pages. Topics are Markdown, which the screens render with Prose; their links to other topics are
// already paths of this server (/help/<topic>#<anchor>) and their images under /help/assets.

export interface HelpSectionJson {
  id: string;
  title: string;
  topics: { id: string; title: string }[];
}

/** GET /help.json: the sections of the contents (the operator's first, then the guide's, then the plugins'). */
export interface HelpContentsJson {
  help: { language: string; sections: HelpSectionJson[] };
}

/** GET /help/<topic>.json[?anchor=]: the topic in the user's language (or English), the operator's blocks under it. */
export interface HelpTopicJson {
  help: {
    topic: {
      id: string;
      title: string;
      /** the language of the text (English when the user's language has none) */
      language: string;
      /** the headings' anchors, in order, the # title first */
      anchors: string[];
      /** Markdown, with its # title */
      body: string;
      /** the asked anchor, in the topic's language (null: the top) */
      anchor: string | null;
    };
    /** the operator's blocks: every page's, then this topic's (Markdown) */
    support: string[];
    section: { id: string; title: string } | null;
  };
}

/** GET /help/search.json?q=: the topics with every word. */
export interface HelpSearchJson {
  help: { q: string; results: { id: string; title: string; snippet: string }[] };
}

/** GET /help/context.json?screen=&tab=: the topic of the app's screen, or none (the contents). */
export interface HelpContextJson {
  help: { topic: string | null; anchor: string | null; follow: boolean };
}

/** A place in the help: a topic (at a heading), the search results, or the contents. */
export type HelpView = { kind: 'topic'; id: string; anchor?: string } | { kind: 'search'; q: string } | { kind: 'contents' };

const enc = (id: string) => id.split('/').map(encodeURIComponent).join('/');

export const helpPaths = {
  contents: '/help.json',
  topic: (id: string, anchor?: string) => `/help/${enc(id)}.json${anchor ? `?anchor=${encodeURIComponent(anchor)}` : ''}`,
  search: (q: string) => `/help/search.json?q=${encodeURIComponent(q)}`,
  context: (screen: string, tab: string | null) => `/help/context.json?screen=${encodeURIComponent(screen)}${tab ? `&tab=${encodeURIComponent(tab)}` : ''}`,
};

/** The help page of a view: Redmine's help pages' addresses (/help, /help/<topic>#<anchor>, /help/search?q=). */
export function helpHref(view: HelpView): string {
  if (view.kind === 'topic') return `/help/${enc(view.id)}${view.anchor ? `#${encodeURIComponent(view.anchor)}` : ''}`;
  if (view.kind === 'search') return `/help/search?q=${encodeURIComponent(view.q)}`;
  return '/help';
}

/** The view of a link in a topic (/help/<topic>#<anchor>), or null for any other href. */
export function helpViewOf(href: string): HelpView | null {
  let url: URL;
  try {
    url = new URL(href, 'http://server.invalid');
  } catch {
    return null;
  }
  if (url.origin !== 'http://server.invalid') return null;
  if (url.pathname === '/help') return { kind: 'contents' };
  if (url.pathname === '/help/search') return { kind: 'search', q: url.searchParams.get('q') ?? '' };
  const topic = /^\/help\/(?!assets\/)(.+)$/.exec(url.pathname)?.[1];
  if (!topic) return null;
  const anchor = url.hash ? decodeURIComponent(url.hash.slice(1)) : undefined;
  return { kind: 'topic', id: topic.split('/').map(decodeURIComponent).join('/'), anchor };
}

/** The text without its # title: the panel's header and the page's title show it. */
export const helpBody = (markdown: string) => markdown.replace(/^# .*\n+/, '');
