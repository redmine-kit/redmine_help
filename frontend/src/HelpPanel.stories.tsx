import { useState } from 'react';
import { useT } from '@redmine-kit/plugin';
import { DrawerHeader } from '@redmine-kit/ui';
import { PanelHeaderContext } from '@redmine-kit/plugin/host'; // check-ui-ok: a story; the app's panel gives its header's places
import { kitStory, type Decorator, type Meta, type StoryObj } from '@redmine-kit/plugin/storybook';
import { helpResponses } from './fixtures';
import { HelpPanel } from './HelpPanel';

// The TopBar's ヘルプ (slot topbar.panel, replaces: help): the help of the current screen in the app's panel at the right,
// with the panel's header (the search and the actions the plugin puts in its toolbar row above the title, the subtitle
// under it). Open to anonymous visitors too: no permission, so no 403.

/** The app's panel: its width and its header (the shared DrawerHeader, as the app draws it) with the title and the
 *  places for the plugin's search, actions and subtitle. Kept here: the shared setup has no frame for a topbar panel's
 *  header. */
const InPanel: Decorator = (Story) => {
  const t = useT();
  const [subtitle, setSubtitle] = useState<HTMLElement | null>(null);
  const [search, setSearch] = useState<HTMLElement | null>(null);
  const [actions, setActions] = useState<HTMLElement | null>(null);
  return (
    <div className="flex h-dvh w-100 max-w-full flex-col bg-surface-card font-sans text-body text-text-body">
      <DrawerHeader
        title={t('label_help')}
        subtitle={<span ref={setSubtitle} className="contents" />}
        search={<span ref={setSearch} className="flex min-w-0 items-center *:min-w-0 *:flex-1" />}
        end={<span ref={setActions} className="flex flex-none items-center gap-1" />}
        onClose={() => undefined}
      />
      <PanelHeaderContext value={{ subtitle, search, actions }}>
        <Story />
      </PanelHeaderContext>
    </div>
  );
};

const panel = { close: () => undefined, request: { target: 'context' as const, key: 1 } };

const meta = {
  title: 'Slots/HelpPanel',
  component: HelpPanel,
  decorators: [InPanel],
  ...kitStory({ context: { screen: { name: 'ProjectTable', tab: null }, panel }, responses: helpResponses }),
} satisfies Meta<typeof HelpPanel>;

export default meta;
type Story = StoryObj<typeof meta>;

/** On the issue list: the screen's topic, with the operator's block. */
export const Default: Story = {};

/** On a screen without a topic: the contents. */
export const Contents: Story = kitStory({ context: { screen: { name: 'News', tab: null }, panel } });

/** Opened by an editor's すべての記法: the text formatting's topic. */
export const WikiSyntax: Story = kitStory({ context: { screen: { name: 'ProjectTable', tab: null }, panel: { ...panel, request: { target: 'wiki_syntax', key: 2 } } } });

/** The topic still coming: the text's skeleton. */
export const Loading: Story = kitStory({ state: 'loading' });

/** The help couldn't be read: the error state with a retry. */
export const Failed: Story = kitStory({ state: 'error' });
