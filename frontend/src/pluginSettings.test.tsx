import { screen } from '@testing-library/react';
import { describe, expect, it } from 'vitest';
import { topic } from './fixtures';
import { HelpPanel } from './HelpPanel';
import { renderKit } from './test/render';

// Administration › Plugins › Configure (the app's PluginSettings): the panel asks for the screen with the plugin as its
// id (settings#plugin?id= in the plugin's map.yml), and opens the plugin's topic.
describe("a plugin's settings", () => {
  it("open the plugin's topic, the plugin passed as the screen's id", async () => {
    renderKit(<HelpPanel />, {
      context: {
        plugin: 'redmine_kit_help',
        panel: { close: () => undefined, request: { target: 'context', key: 1 } },
        screen: { name: 'PluginSettings', tab: null, id: 'redmine_kit_checklist' },
      },
      responses: {
        'GET /help/context.json?screen=PluginSettings&id=redmine_kit_checklist': { help: { topic: 'checklist/checklist', anchor: null, follow: true } },
        'GET /help/checklist/checklist.json': topic('checklist/checklist', 'チェックリスト', 'リリースの前に確認する項目の一覧です。'),
      },
    });
    expect(await screen.findByText('リリースの前に確認する項目の一覧です。')).toBeInTheDocument();
  });
});
