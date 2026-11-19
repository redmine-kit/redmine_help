import { describe, expect, it } from 'vitest';
import { helpBody, helpHref, helpPaths, helpViewOf } from './api';

describe('the help addresses', () => {
  it("a view's page and back: Redmine's help pages", () => {
    expect(helpHref({ kind: 'contents' })).toBe('/help');
    expect(helpHref({ kind: 'topic', id: 'user/issues', anchor: 'チケットの更新' })).toBe('/help/user/issues#%E3%83%81%E3%82%B1%E3%83%83%E3%83%88%E3%81%AE%E6%9B%B4%E6%96%B0');
    expect(helpViewOf(helpHref({ kind: 'topic', id: 'user/issues', anchor: 'チケットの更新' }))).toEqual({ kind: 'topic', id: 'user/issues', anchor: 'チケットの更新' });
    expect(helpViewOf('/help/search?q=a%20b')).toEqual({ kind: 'search', q: 'a b' });
    expect(helpViewOf('/help')).toEqual({ kind: 'contents' });
  });

  it('other links are not the help: other sites, images, other pages', () => {
    for (const href of ['https://www.redmine.org/help/x', '//evil.example/help/x', '/help/assets/en/user/images/a.png', '/projects', 'javascript:alert(1)']) {
      expect(helpViewOf(href)).toBeNull();
    }
  });

  it('the JSON paths encode what the user typed', () => {
    expect(helpPaths.search('a&b')).toBe('/help/search.json?q=a%26b');
    expect(helpPaths.topic('user/issues', 'Updating-an-issue')).toBe('/help/user/issues.json?anchor=Updating-an-issue');
    expect(helpPaths.context('ProjectSettings', 'members')).toBe('/help/context.json?screen=ProjectSettings&tab=members');
    expect(helpPaths.context('Main', null)).toBe('/help/context.json?screen=Main');
  });

  it('the body without its # title', () => {
    expect(helpBody('# Title\n\nText\n# Not a title')).toBe('Text\n# Not a title');
  });
});
