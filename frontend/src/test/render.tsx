import type { ReactNode } from 'react';
import { render } from '@testing-library/react';
import { KitTestHost, type KitTestHostProps } from '@redmine-kit/plugin/testing';
import { kitCatalog } from '@redmine-kit/plugin/locales';

// A component of the module in a test, with the app's part (KitTestHost): the strings as Redmine loads them (Redmine
// 7.0.3's and redmine_kit_ui's, then the plugin's config/locales), the same as its Storybook's, and the permissions given.

export const JA = kitCatalog('ja');
export const EN = kitCatalog('en');

export function renderKit(ui: ReactNode, { lang = 'ja', ...props }: Omit<KitTestHostProps, 'children'> & { lang?: 'ja' | 'en' } = {}) {
  return render(
    <KitTestHost strings={lang} t={lang === 'ja' ? JA : EN} {...props}>
      {ui}
    </KitTestHost>,
  );
}
