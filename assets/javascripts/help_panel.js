/*
 * The side panel of Redmine Help (docs/README.md#side-panel).
 *
 * The header's Help link opens and closes a panel at the end side of the
 * window with the help for the current screen. The panel is not modal: the
 * page stays usable next to it. Its content comes from the help pages with
 * panel=1 (RedmineHelpController), and links between topics, the search
 * and Back stay inside the panel. Without this script, the Help link opens
 * the help page in a new tab.
 */
(function () {
  'use strict';

  var PANEL_ID = 'help-panel';
  var STORAGE_KEY = 'redmine_help.panel';

  var panel = null;
  var helpRoot = null;
  // The pages shown before the current one, for Back: { url, scroll }.
  var trail = [];
  var current = null;
  var request = 0;

  function storageGet() {
    try { return window.localStorage.getItem(STORAGE_KEY); } catch (e) { return null; }
  }

  function storageSet(value) {
    try { window.localStorage.setItem(STORAGE_KEY, value); } catch (e) { /* not kept */ }
  }

  // The Help link: in the top menu, or in the flyout menu on narrow windows
  // (responsive.js moves the same element).
  function toggleLink() {
    return document.querySelector('#top-menu a.help, .js-flyout-menu a.help');
  }

  function isOpen() {
    return !!panel && !panel.hidden;
  }

  function withPanelParam(url) {
    var u = new URL(url, window.location.href);
    u.searchParams.set('panel', '1');
    return u;
  }

  // The help for the current screen: the Help link's URL, with the tab
  // shown on the page when the link does not name one.
  function contextUrl() {
    var u = new URL(toggleLink().href, window.location.href);
    var selected = document.querySelector('div.tabs a.selected[id^="tab-"][onclick]');
    if (!u.searchParams.has('tab') && selected) {
      u.searchParams.set('tab', selected.id.slice(4));
    }
    return u.toString();
  }

  function ensurePanel() {
    if (panel) { return panel; }
    panel = document.createElement('aside');
    panel.id = PANEL_ID;
    panel.className = 'help-panel';
    panel.hidden = true;
    panel.setAttribute('role', 'complementary');
    panel.setAttribute('aria-labelledby', 'help-panel-title');
    panel.addEventListener('click', onPanelClick);
    panel.addEventListener('keydown', onButtonKey);
    panel.addEventListener('submit', onPanelSubmit);
    document.body.appendChild(panel);
    return panel;
  }

  function setExpanded(open) {
    var link = toggleLink();
    if (link) { link.setAttribute('aria-expanded', open ? 'true' : 'false'); }
    document.documentElement.classList.toggle('help-panel-open', open);
  }

  // Loads a page of the help into the panel. options.follow: show it only
  // when the screen's tab has a topic of its own. Resolves to false when
  // nothing was shown.
  function load(url, options) {
    options = options || {};
    var id = ++request;
    var target = new URL(url, window.location.href);
    return fetch(withPanelParam(target), {
      credentials: 'same-origin',
      headers: { 'X-Requested-With': 'XMLHttpRequest' }
    }).then(function (response) {
      if (!response.ok || response.redirected) { throw new Error(String(response.status)); }
      return response.text();
    }).then(function (html) {
      if (id !== request) { return false; }
      var template = document.createElement('template');
      template.innerHTML = html;
      var header = template.content.querySelector('.help-panel-header');
      if (!header) { throw new Error('no panel'); }
      if (options.follow && header.getAttribute('data-follow') !== 'true') { return false; }
      if (options.push && current) {
        trail.push({ url: current, scroll: content() ? content().scrollTop : 0 });
      }
      ensurePanel();
      panel.replaceChildren(template.content);
      current = target.toString();
      show(target.hash ? decoded(target.hash.slice(1)) : header.getAttribute('data-anchor'), options);
      return true;
    }).catch(function () {
      if (id !== request) { return false; }
      // The help page itself, as without the panel (a session that ended,
      // an error), when the user asked for it.
      if (options.focus) { window.open(target.toString(), '_blank', 'noopener'); }
      if (!options.follow) { close(false); }
      return false;
    });
  }

  function content() {
    return panel && panel.querySelector('.help-panel-content');
  }

  // After a page was put in the panel: Back, the full view link with the
  // anchor, the scroll position, and the focus on the title.
  function show(anchor, options) {
    var back = panel.querySelector('.help-panel-back');
    if (back) { back.hidden = trail.length === 0; }
    var fullView = panel.querySelector('.help-panel-full-view');
    if (fullView && anchor && fullView.href.indexOf('#') < 0) {
      fullView.href += '#' + encodeURIComponent(anchor);
    }
    panel.hidden = false;
    setExpanded(true);
    if (options.scroll !== undefined) {
      content().scrollTop = options.scroll;
    } else {
      scrollToAnchor(anchor);
    }
    if (options.focus) {
      var title = panel.querySelector('#help-panel-title');
      if (title) { title.focus({ preventScroll: true }); }
    }
  }

  // Scrolls the panel (not the page) to a heading, by its anchor (decoded):
  // Redmine puts <a name="..."> before each heading, and the help's HTML
  // has non-ASCII names percent-encoded. Anchors of map.yml may differ from
  // the heading's in case.
  function scrollToAnchor(name) {
    var box = content();
    if (!box) { return; }
    var element = null;
    if (name) {
      var lower = name.toLowerCase();
      element = Array.prototype.find.call(box.querySelectorAll('a[name], [id]'), function (node) {
        return decoded(node.getAttribute('name') || node.id) === name;
      }) || Array.prototype.find.call(box.querySelectorAll('a[name], [id]'), function (node) {
        return decoded(node.getAttribute('name') || node.id).toLowerCase() === lower;
      });
    }
    if (!element) {
      box.scrollTop = 0;
      return;
    }
    var place = function () {
      box.scrollTop = element.getBoundingClientRect().top - box.getBoundingClientRect().top + box.scrollTop;
      return box.scrollTop;
    };
    var top = place();
    box.querySelectorAll('img').forEach(function (img) {
      if (img.complete) { return; }
      img.addEventListener('load', function () {
        if (box.isConnected && box.scrollTop === top) { top = place(); }
      }, { once: true });
    });
  }

  function decoded(text) {
    try { return decodeURIComponent(text); } catch (e) { return text; }
  }

  function open(focus) {
    trail = [];
    current = null;
    storageSet('open');
    return load(contextUrl(), { focus: focus });
  }

  function close(returnFocus) {
    request++;
    storageSet('closed');
    if (!panel) { return; }
    var hadFocus = panel.contains(document.activeElement);
    panel.hidden = true;
    setExpanded(false);
    if (returnFocus || hadFocus) {
      var link = toggleLink();
      // On narrow windows the link is in the closed flyout menu.
      if (link && link.offsetParent === null) { link = document.querySelector('.js-flyout-menu-toggle-button'); }
      if (link) { link.focus(); }
    }
  }

  function back() {
    var previous = trail.pop();
    if (previous) { load(previous.url, { focus: true, scroll: previous.scroll }); }
  }

  function isHelpPage(url) {
    if (url.origin !== window.location.origin || url.pathname.indexOf(helpRoot) !== 0) { return false; }
    var rest = url.pathname.slice(helpRoot.length);
    // The topics' images, and Redmine's own help on text formatting.
    return !/^(assets|wiki_syntax|code_highlighting)(\/|$)/.test(rest);
  }

  function onPanelClick(event) {
    if (event.defaultPrevented || event.button !== 0 || event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) { return; }
    var link = event.target.closest('a[href]');
    if (!link) { return; }
    if (link.classList.contains('help-panel-close')) {
      event.preventDefault();
      close(true);
    } else if (link.classList.contains('help-panel-back')) {
      event.preventDefault();
      back();
    } else if (link.getAttribute('href').charAt(0) === '#') {
      // The table of contents and the headings' anchors.
      event.preventDefault();
      scrollToAnchor(decoded(link.getAttribute('href').slice(1)));
    } else if (!link.target) {
      var url = new URL(link.href, window.location.href);
      if (isHelpPage(url)) {
        event.preventDefault();
        load(url.toString(), { focus: true, push: true });
      } else {
        // Other pages open in a new window, so that the page next to the
        // panel (a form being filled in) stays.
        link.target = '_blank';
        link.rel = 'noopener';
      }
    }
  }

  // Back and Close are links with role="button": Space presses them too.
  function onButtonKey(event) {
    if (event.key === ' ' && event.target.getAttribute('role') === 'button') {
      event.preventDefault();
      event.target.click();
    }
  }

  function onPanelSubmit(event) {
    var form = event.target;
    event.preventDefault();
    var url = new URL(form.action, window.location.href);
    new FormData(form).forEach(function (value, name) { url.searchParams.set(name, value); });
    load(url.toString(), { focus: true, push: true });
  }

  function onDocumentClick(event) {
    var link = event.target.closest('a');
    if (!link || event.button !== 0) { return; }
    if (link === toggleLink()) {
      if (event.defaultPrevented || event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) { return; }
      event.preventDefault();
      if (typeof window.closeFlyout === 'function') { window.closeFlyout(); }
      if (isOpen()) { close(true); } else { open(true); }
    } else if (link.matches('div.tabs a[id^="tab-"][onclick]')) {
      // core's onclick shows the tab and returns false.
      followTab(link.id.slice(4));
    }
  }

  // A tab shown in the page (core's showTab): the Help link names the tab,
  // and an open panel shows the tab's topic when the map has one.
  function followTab(name) {
    var link = toggleLink();
    var u = new URL(link.href, window.location.href);
    u.searchParams.set('tab', name);
    link.href = u.toString();
    if (isOpen()) { load(u.toString(), { follow: true, push: true }); }
  }

  function onDocumentKey(event) {
    var link = toggleLink();
    if (event.key === ' ' && event.target === link) {
      event.preventDefault();
      link.click();
    } else if (event.key === 'Escape' && isOpen()) {
      var active = document.activeElement;
      if (panel.contains(active) || active === link || active === document.body || !active) {
        event.preventDefault();
        close(true);
      }
    }
  }

  function init() {
    var link = toggleLink();
    if (!link) { return; }
    helpRoot = new URL(link.href, window.location.href).pathname.replace(/[^/]*$/, '');
    link.setAttribute('role', 'button');
    link.setAttribute('aria-controls', PANEL_ID);
    link.setAttribute('aria-expanded', 'false');
    ensurePanel();
    document.addEventListener('click', onDocumentClick);
    document.addEventListener('keydown', onDocumentKey);
    // Open on this screen too when it was open on the previous one.
    if (storageGet() === 'open') { open(false); }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
}());
