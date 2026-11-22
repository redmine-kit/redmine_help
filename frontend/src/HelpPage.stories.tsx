import { kitError, screenStory, type Meta, type StoryObj } from '@redmine-kit/plugin/storybook';
import { contentsWithoutGuide, helpResponses, issuesTopicWithSections } from './fixtures';
import { HelpCodeHighlighting, HelpPage, HelpWikiSyntax } from './HelpPage';

// The help pages (the manifest's /help and /help/*topic) and Redmine's help pages the plugin's topics stand for
// (/help/wiki_syntax, /help/code_highlighting), with the plugin's sidebar. Open to whoever may open Redmine's pages: no
// permission, so no 403.
const meta = {
  title: 'Screens/HelpPage',
  component: HelpPage,
  ...screenStory({ sidebar: true, path: '/help', responses: helpResponses }),
} satisfies Meta<typeof HelpPage>;

export default meta;
type Story = StoryObj<typeof meta>;

/** The contents: the operator's section, then the guide's. */
export const Contents: Story = {};

/** The contents without the Redmine guide: the operator's section and the notice that the guide is missing. */
export const WithoutGuide: Story = screenStory({ responses: { ...helpResponses, 'GET /help.json': contentsWithoutGuide } });

/** A topic (/help/user/issues): its title, its text, the table of contents and the operator's block. */
export const Topic: Story = screenStory({ path: '/help/*topic', route: '/help/user/issues' });

/** A topic with plugins' sections (docs/extending.md "Sections in the guide's topics"): each heading labelled with the
 *  plugin's name, one in English in the Japanese topic. */
export const TopicWithPluginSections: Story = screenStory({
  path: '/help/*topic',
  route: '/help/user/issues',
  responses: { ...helpResponses, 'GET /help/user/issues.json': issuesTopicWithSections },
});

/** A topic that isn't there: Redmine's 404. */
export const TopicNotFound: Story = screenStory({
  path: '/help/*topic',
  route: '/help/user/missing',
  responses: { ...helpResponses, 'GET /help/user/missing.json': kitError(404) },
});

/** The help still coming: the page's skeleton. */
export const Loading: Story = screenStory({ state: 'loading' });

/** The help couldn't be read: the error state with a retry. */
export const Failed: Story = screenStory({ state: 'error' });

/** Redmine's text formatting page (/help/wiki_syntax): the plugin's topic of the server's formatting. */
export const WikiSyntax: Story = { render: () => <HelpWikiSyntax />, ...screenStory({ path: '/help/wiki_syntax' }) };

/** Redmine's code highlighting page (/help/code_highlighting): the plugin's topic of the languages. */
export const CodeHighlighting: Story = { render: () => <HelpCodeHighlighting />, ...screenStory({ path: '/help/code_highlighting' }) };
