// Redmine Kit Help: the plugin's module for the new UI, built from frontend/src by `npm run build` (frontend/vite.config.js).
// Edit the source, not this file. React, @redmine-kit/ui and @redmine-kit/plugin come from the app (the shell's import map).
import { useCallback, useEffect, useLayoutEffect, useRef, useState } from "react";
import { AppLink, ExtensionPanelHeader, ScreenSidebar, useExtensionContext, useKitNavigate, useKitQuery, useT } from "@redmine-kit/plugin";
import { Card, CardBody, CardHeader, EmptyState, Icon, IconButton, NavRow, Notice, PageToc, Pane, Panes, Prose, SearchInput, SectionHeading, Skeleton, SkeletonRegion, TitleBlock, cn } from "@redmine-kit/ui";
import { Fragment, jsx, jsxs } from "react/jsx-runtime";
// src/api.ts
var enc = (id) => id.split("/").map(encodeURIComponent).join("/");
var helpPaths = {
	contents: "/help.json",
	topic: (id, anchor) => `/help/${enc(id)}.json${anchor ? `?anchor=${encodeURIComponent(anchor)}` : ""}`,
	search: (q) => `/help/search.json?q=${encodeURIComponent(q)}`,
	context: (screen, tab) => `/help/context.json?screen=${encodeURIComponent(screen)}${tab ? `&tab=${encodeURIComponent(tab)}` : ""}`,
	/** the topic of Redmine's help page of the server's text formatting (wiki: help#show_wiki_syntax) or of the code
	*  highlighting (code: help#show_code_highlighting) */
	syntax: (syntax) => `/help/context.json?syntax=${syntax}`
};
/** The keyboard's topic of the guide (the app's ? key: the panel's request `keyboard`). */
var KEYBOARD_TOPIC = "user/keyboard-navigation";
/** The view of a context answer: its topic at its anchor, or the contents. */
var contextView = (data) => data.help.topic ? {
	kind: "topic",
	id: data.help.topic,
	anchor: data.help.anchor ?? void 0
} : { kind: "contents" };
/** The help page of a view: Redmine's help pages' addresses (/help, /help/<topic>#<anchor>, /help/search?q=). */
function helpHref(view) {
	if (view.kind === "topic") return `/help/${enc(view.id)}${view.anchor ? `#${encodeURIComponent(view.anchor)}` : ""}`;
	if (view.kind === "search") return `/help/search?q=${encodeURIComponent(view.q)}`;
	return "/help";
}
/** The view of a link in a topic (/help/<topic>#<anchor>), or null for any other href. */
function helpViewOf(href) {
	let url;
	try {
		url = new URL(href, "http://server.invalid");
	} catch {
		return null;
	}
	if (url.origin !== "http://server.invalid") return null;
	if (url.pathname === "/help") return { kind: "contents" };
	if (url.pathname === "/help/search") return {
		kind: "search",
		q: url.searchParams.get("q") ?? ""
	};
	const topic = /^\/help\/(?!assets\/)(.+)$/.exec(url.pathname)?.[1];
	if (!topic) return null;
	const anchor = url.hash ? decodeURIComponent(url.hash.slice(1)) : void 0;
	return {
		kind: "topic",
		id: topic.split("/").map(decodeURIComponent).join("/"),
		anchor
	};
}
/** The text without its # title: the panel's header and the page's title show it. */
var helpBody = (markdown) => markdown.replace(/^# .*\n+/, "");
// src/HelpContent.tsx
var plain = (e) => e.button === 0 && !e.metaKey && !e.ctrlKey && !e.shiftKey && !e.altKey;
/** A click handler for a container of help links: a plain click on a help link goes through `onGo`. */
function helpLinkCapture(onGo) {
	return (e) => {
		const href = e.target.closest("a")?.getAttribute("href");
		if (!href || !onGo || !plain(e)) return;
		const view = helpViewOf(href);
		if (!view) return;
		e.preventDefault();
		onGo(view);
	};
}
function HelpLoadError() {
	const t = useT();
	return /* @__PURE__ */ jsx(Notice, {
		tone: "warning",
		inset: 0,
		text: t("text_help_load_failed")
	});
}
/** The lines of a loading topic or list, where the text will be. */
function HelpTextSkeleton() {
	const t = useT();
	return /* @__PURE__ */ jsxs(SkeletonRegion, {
		label: t("label_loading"),
		className: "flex flex-col gap-3",
		children: [
			/* @__PURE__ */ jsx(Skeleton, { width: "90%" }),
			/* @__PURE__ */ jsx(Skeleton, { width: "80%" }),
			/* @__PURE__ */ jsx(Skeleton, { width: "85%" }),
			/* @__PURE__ */ jsx(Skeleton, { width: "40%" })
		]
	});
}
function HelpTopicView({ id, anchor, scroller, restore, reading = false, onTitle }) {
	const query = useKitQuery(helpPaths.topic(id, anchor));
	const prose = useRef(null);
	const data = query.data?.help;
	const title = data?.topic.title;
	useEffect(() => {
		if (title) onTitle?.(title);
	}, [title, onTitle]);
	useEffect(() => {
		const box = scroller.current;
		if (!box || !data) return;
		if (restore !== void 0) {
			box.scrollTop = restore;
			return;
		}
		const target = data.topic.anchor ? [...prose.current?.querySelectorAll("[id]") ?? []].find((el) => el.id === data.topic.anchor) : null;
		box.scrollTop = target ? target.getBoundingClientRect().top - box.getBoundingClientRect().top + box.scrollTop - 12 : 0;
	}, [
		data,
		restore,
		scroller
	]);
	if (query.isPending) return /* @__PURE__ */ jsx(HelpTextSkeleton, {});
	if (query.isError) return /* @__PURE__ */ jsx(HelpLoadError, {});
	return /* @__PURE__ */ jsxs(Fragment, { children: [/* @__PURE__ */ jsx(Prose, {
		ref: prose,
		text: helpBody(data.topic.body),
		reading
	}), data.support.map((text, i) => /* @__PURE__ */ jsx("div", {
		className: cn("mt-4 rounded-control bg-surface-band px-3 py-2", reading && "max-w-190"),
		children: /* @__PURE__ */ jsx(Prose, { text })
	}, i))] });
}
function HelpResults({ q }) {
	const t = useT();
	const query = useKitQuery(helpPaths.search(q));
	if (query.isPending) return /* @__PURE__ */ jsx(HelpTextSkeleton, {});
	if (query.isError) return /* @__PURE__ */ jsx(HelpLoadError, {});
	const results = query.data.help.results;
	return /* @__PURE__ */ jsxs("section", {
		"aria-label": t("label_result_plural"),
		className: "flex flex-col",
		children: [/* @__PURE__ */ jsx(SectionHeading, {
			heading: t("label_result_plural"),
			count: results.length,
			level: 3
		}), results.length === 0 ? /* @__PURE__ */ jsx(EmptyState, {
			variant: "block",
			text: t("label_no_data")
		}) : /* @__PURE__ */ jsx("ul", {
			className: "flex flex-col",
			children: results.map((result) => /* @__PURE__ */ jsxs("li", {
				className: "flex flex-col gap-0.5 py-2",
				children: [/* @__PURE__ */ jsxs(AppLink, {
					href: helpHref({
						kind: "topic",
						id: result.id
					}),
					className: "inline-flex items-center gap-1.5 self-start text-body font-medium text-text-link no-underline hover:text-text-link-hover",
					children: [/* @__PURE__ */ jsx(Icon, {
						name: "wiki",
						size: 14,
						className: "flex-none text-text-muted"
					}), result.title]
				}), /* @__PURE__ */ jsx("span", {
					className: "line-clamp-2 text-meta text-text-muted",
					children: result.snippet
				})]
			}, result.id))
		})]
	});
}
function HelpContents({ current }) {
	const t = useT();
	const query = useKitQuery(helpPaths.contents);
	if (query.isPending) return /* @__PURE__ */ jsx(HelpTextSkeleton, {});
	if (query.isError) return /* @__PURE__ */ jsx(HelpLoadError, {});
	return /* @__PURE__ */ jsx("nav", {
		"aria-label": t("label_table_of_contents"),
		className: "flex flex-col gap-4",
		children: query.data.help.sections.map((section) => /* @__PURE__ */ jsxs("div", {
			className: "flex flex-col gap-0.5",
			children: [/* @__PURE__ */ jsx(SectionHeading, {
				heading: section.title,
				level: 3
			}), section.topics.map((topic) => /* @__PURE__ */ jsx(AppLink, {
				href: helpHref({
					kind: "topic",
					id: topic.id
				}),
				"aria-current": topic.id === current ? "page" : void 0,
				className: cn("truncate py-1 text-body no-underline hover:text-text-link-hover", topic.id === current ? "font-medium text-text-title" : "text-text-link"),
				children: topic.title
			}, topic.id))]
		}, section.id))
	});
}
// src/HelpPanel.tsx
/** Outside the app's panel (a test without one): the screen's topic. */
var NO_REQUEST = {
	target: "context",
	key: 0
};
function HelpPanel() {
	const t = useT();
	const { screen, panel } = useExtensionContext();
	const name = screen?.name ?? null;
	const tab = screen?.tab ?? null;
	const request = panel?.request ?? NO_REQUEST;
	const context = useKitQuery(name ? helpPaths.context(name, tab) : null);
	const syntax = useKitQuery(request.target === "wiki_syntax" ? helpPaths.syntax("wiki") : null);
	const [current, setCurrent] = useState(null);
	const [trail, setTrail] = useState([]);
	const [q, setQ] = useState("");
	const [title, setTitle] = useState("");
	const body = useRef(null);
	const screenView = !name ? { kind: "contents" } : context.data ? context.data.help.topic ? {
		kind: "topic",
		id: context.data.help.topic,
		anchor: context.data.help.anchor ?? void 0
	} : { kind: "contents" } : null;
	const requested = request.target === "keyboard" ? {
		kind: "topic",
		id: KEYBOARD_TOPIC
	} : request.target === "wiki_syntax" ? syntax.data ? contextView(syntax.data) : null : screenView;
	const answered = useRef(null);
	const seen = useRef(null);
	useEffect(() => {
		if (!requested || answered.current === request.key) return;
		answered.current = request.key;
		seen.current = {
			name,
			tab
		};
		setCurrent({ view: requested });
		setTrail([]);
		setQ("");
	}, [
		request.key,
		requested?.kind,
		requested && "id" in requested ? requested.id : null
	]);
	useEffect(() => {
		if (!screenView || answered.current !== request.key) return;
		const prev = seen.current;
		const moved = !prev || prev.name !== name;
		const tabMoved = !!prev && prev.name === name && prev.tab !== tab && !!context.data?.help.follow;
		seen.current = {
			name,
			tab
		};
		if (moved || tabMoved) {
			setCurrent({ view: screenView });
			setTrail([]);
			setQ("");
		}
	}, [
		name,
		tab,
		screenView?.kind,
		screenView && "id" in screenView ? screenView.id : null
	]);
	const currentRef = useRef(current);
	currentRef.current = current;
	const go = useCallback((view) => {
		const from = currentRef.current;
		if (from) setTrail((list) => [...list, {
			view: from.view,
			scroll: body.current?.scrollTop ?? 0
		}]);
		setCurrent({ view });
		if (view.kind !== "search") setQ("");
	}, []);
	const back = () => {
		const prev = trail[trail.length - 1];
		if (!prev) return;
		setTrail(trail.slice(0, -1));
		setCurrent(prev);
		setQ(prev.view.kind === "search" ? prev.view.q : "");
	};
	const onSearch = (value) => {
		setQ(value);
		const text = value.trim();
		if (!text) {
			if (current?.view.kind === "search") back();
			return;
		}
		if (current?.view.kind === "search") setCurrent({ view: {
			kind: "search",
			q: text
		} });
		else go({
			kind: "search",
			q: text
		});
	};
	const onSubmit = (e) => e.preventDefault();
	const view = current?.view;
	const subtitle = view?.kind === "topic" ? title : view?.kind === "search" ? t("label_search") : t("label_table_of_contents");
	return /* @__PURE__ */ jsxs("div", {
		className: "flex min-h-0 flex-1 flex-col",
		children: [
			/* @__PURE__ */ jsx(ExtensionPanelHeader, {
				subtitle: view ? subtitle : void 0,
				actions: /* @__PURE__ */ jsxs(Fragment, { children: [
					trail.length > 0 && /* @__PURE__ */ jsx(IconButton, {
						icon: "chevron-left",
						"aria-label": t("button_back"),
						onClick: back
					}),
					/* @__PURE__ */ jsx(IconButton, {
						icon: "list-bullet",
						"aria-label": t("label_table_of_contents"),
						pressed: view?.kind === "contents",
						onClick: () => view?.kind !== "contents" && go({ kind: "contents" })
					}),
					/* @__PURE__ */ jsx(IconButton, {
						asChild: true,
						icon: "expand",
						"aria-label": t("label_open_in_full_view"),
						children: /* @__PURE__ */ jsx(AppLink, { href: helpHref(view ?? { kind: "contents" }) })
					})
				] })
			}),
			/* @__PURE__ */ jsx("form", {
				role: "search",
				onSubmit,
				className: "flex-none px-5 pt-3",
				children: /* @__PURE__ */ jsx(SearchInput, {
					size: 28,
					"aria-label": t("label_search"),
					placeholder: t("label_search"),
					value: q,
					onChange: (e) => onSearch(e.target.value),
					onClear: () => onSearch("")
				})
			}),
			/* @__PURE__ */ jsx("div", {
				ref: body,
				onClickCapture: helpLinkCapture(go),
				className: "min-h-0 flex-1 overflow-y-auto overscroll-contain ps-5 pe-4 pt-4 pb-6",
				children: context.isError || syntax.isError ? /* @__PURE__ */ jsx(HelpLoadError, {}) : !view ? /* @__PURE__ */ jsx(HelpTextSkeleton, {}) : view.kind === "topic" ? /* @__PURE__ */ jsx(HelpTopicView, {
					id: view.id,
					anchor: view.anchor,
					scroller: body,
					restore: current?.scroll,
					onTitle: setTitle
				}, view.id + (view.anchor ?? "")) : view.kind === "search" ? /* @__PURE__ */ jsx(HelpResults, { q: view.q }) : /* @__PURE__ */ jsx(HelpContents, {})
			})
		]
	});
}
// src/HelpPage.tsx
function HelpPage({ syntax }) {
	const t = useT();
	const { params } = useExtensionContext();
	const resolved = useKitQuery(syntax ? helpPaths.syntax(syntax) : null);
	const [searched, setSearched] = useState(addressQuery);
	const [q, setQ] = useState(searched);
	const [shownTopic, setShownTopic] = useState(params.topic);
	if (shownTopic !== params.topic) {
		setShownTopic(params.topic);
		setSearched("");
		setQ("");
	}
	const view = searched ? {
		kind: "search",
		q: searched
	} : syntax ? resolved.data ? contextView(resolved.data) : null : params.topic ? {
		kind: "topic",
		id: params.topic,
		anchor: addressAnchor()
	} : { kind: "contents" };
	const onSearch = (e) => {
		e.preventDefault();
		setSearched(q.trim());
	};
	const search = /* @__PURE__ */ jsx("form", {
		role: "search",
		onSubmit: onSearch,
		className: "flex w-60 @max-phone:w-full",
		children: /* @__PURE__ */ jsx(SearchInput, {
			"aria-label": t("label_search"),
			placeholder: t("label_search"),
			value: q,
			onChange: (e) => setQ(e.target.value),
			onClear: () => setQ(""),
			className: "w-full"
		})
	});
	const contents = useKitQuery(helpPaths.contents);
	const sections = contents.data?.help.sections ?? [];
	const current = view?.kind === "topic" ? view.id : void 0;
	const groups = [{
		key: "help",
		label: t("label_help"),
		rows: [{
			key: "contents",
			label: t("label_table_of_contents"),
			icon: "list-bullet",
			href: helpHref({ kind: "contents" }),
			selected: view?.kind === "contents"
		}, ...sections.map((section) => ({
			key: section.id,
			label: section.title,
			icon: "folder",
			children: section.topics.map((item) => ({
				key: item.id,
				label: item.title,
				href: helpHref({
					kind: "topic",
					id: item.id
				}),
				selected: item.id === current
			}))
		}))],
		loadingRows: contents.isPending ? 4 : void 0
	}];
	let body;
	if (!view) body = /* @__PURE__ */ jsxs(Fragment, { children: [/* @__PURE__ */ jsx(CardHeader, {
		title: t("label_help"),
		actions: search,
		sidebarToggle: true,
		sidebarLabel: t("label_help"),
		divider: true
	}), /* @__PURE__ */ jsx(CardBody, {
		padded: true,
		children: resolved.isError ? /* @__PURE__ */ jsx(HelpLoadError, {}) : /* @__PURE__ */ jsx(HelpTextSkeleton, {})
	})] });
	else if (view.kind === "topic") body = /* @__PURE__ */ jsx(TopicPage, {
		id: view.id,
		anchor: view.anchor,
		search
	}, view.id);
	else if (view.kind === "search") body = /* @__PURE__ */ jsxs(Fragment, { children: [/* @__PURE__ */ jsx(CardHeader, {
		title: t("label_search"),
		back: {
			label: t("label_help_back"),
			onClick: () => (setSearched(""), setQ(""))
		},
		actions: search,
		sidebarToggle: true,
		sidebarLabel: t("label_help"),
		divider: true
	}), /* @__PURE__ */ jsx(CardBody, {
		padded: true,
		children: /* @__PURE__ */ jsx(HelpResults, { q: view.q })
	})] });
	else body = /* @__PURE__ */ jsxs(Fragment, { children: [/* @__PURE__ */ jsx(CardHeader, {
		title: t("label_help"),
		actions: search,
		sidebarToggle: true,
		sidebarLabel: t("label_help"),
		divider: true
	}), /* @__PURE__ */ jsx(CardBody, {
		padded: true,
		children: /* @__PURE__ */ jsx(Contents, {
			data: contents.data,
			failed: contents.isError
		})
	})] });
	return /* @__PURE__ */ jsxs(Fragment, { children: [/* @__PURE__ */ jsx(ScreenSidebar, {
		label: t("label_help"),
		groups
	}), /* @__PURE__ */ jsx(Card, {
		"aria-label": t("label_help"),
		children: body
	})] });
}
/** The words of the address /help/search?q= (the plugin's search page), else none. */
function addressQuery() {
	if (!/\/help\/search\/?$/.test(window.location.pathname)) return "";
	return (new URLSearchParams(window.location.search).get("q") ?? "").trim().slice(0, 100);
}
/** The heading the address asks for (/help/<topic>#<anchor>). */
function addressAnchor() {
	try {
		return window.location.hash ? decodeURIComponent(window.location.hash.slice(1)) : void 0;
	} catch {
		return;
	}
}
/** Redmine's help#show_wiki_syntax (/help/wiki_syntax[/detailed]): the topic of the server's text formatting. */
function HelpWikiSyntax() {
	return /* @__PURE__ */ jsx(HelpPage, { syntax: "wiki" });
}
/** Redmine's help#show_code_highlighting (/help/code_highlighting): the code highlighting's languages. */
function HelpCodeHighlighting() {
	return /* @__PURE__ */ jsx(HelpPage, { syntax: "code" });
}
function Contents({ data, failed }) {
	const t = useT();
	if (failed) return /* @__PURE__ */ jsx(HelpLoadError, {});
	if (!data) return /* @__PURE__ */ jsx(HelpTextSkeleton, {});
	return /* @__PURE__ */ jsx("nav", {
		"aria-label": t("label_table_of_contents"),
		className: "grid grid-cols-fill-240 items-start gap-x-8 gap-y-section-gap",
		children: data.help.sections.map((section) => /* @__PURE__ */ jsxs("section", {
			"aria-label": section.title,
			className: "flex flex-col gap-0.5",
			children: [/* @__PURE__ */ jsx(SectionHeading, {
				heading: section.title,
				count: section.topics.length
			}), section.topics.map((topic) => /* @__PURE__ */ jsx(NavRow, {
				href: helpHref({
					kind: "topic",
					id: topic.id
				}),
				className: "-mx-2.25",
				children: topic.title
			}, topic.id))]
		}, section.id))
	});
}
function TopicPage({ id, anchor, search }) {
	const t = useT();
	const navigate = useKitNavigate();
	const [title, setTitle] = useState("");
	const article = useRef(null);
	const [outline, setOutline] = useState([]);
	useLayoutEffect(() => {
		const box = article.current;
		if (!box) return;
		const read = () => {
			const root = box.firstElementChild;
			const next = Array.from(root?.querySelectorAll("h2, h3") ?? []).map((el, i) => {
				if (!el.id) el.id = `help-h-${i + 1}`;
				return {
					level: el.tagName === "H3" ? 3 : 2,
					text: el.textContent?.trim() ?? "",
					id: el.id
				};
			});
			setOutline((now) => JSON.stringify(now) === JSON.stringify(next) ? now : next);
		};
		read();
		const observer = new MutationObserver(read);
		observer.observe(box, {
			childList: true,
			subtree: true,
			characterData: true
		});
		return () => observer.disconnect();
	}, [id]);
	const spy = useHeadingInView(article, outline);
	return /* @__PURE__ */ jsxs(Fragment, { children: [/* @__PURE__ */ jsx(TitleBlock, {
		title: title || t("label_help"),
		actions: search,
		sidebarToggle: true,
		sidebarLabel: t("label_help"),
		divider: true
	}), /* @__PURE__ */ jsxs(Panes, {
		className: "@max-5xl/app:flex-col @max-5xl/app:overflow-y-auto @max-5xl/app:overscroll-contain",
		children: [/* @__PURE__ */ jsx(Pane, {
			as: "article",
			ref: article,
			"aria-label": title || t("label_help"),
			onClickCapture: helpLinkCapture((next) => navigate(helpHref(next))),
			className: "box-content flex-[999_1_520px] px-6 pt-5 pb-6 @max-5xl/app:flex-none @max-5xl/app:overflow-visible",
			children: /* @__PURE__ */ jsx(HelpTopicView, {
				id,
				anchor,
				scroller: article,
				reading: true,
				onTitle: setTitle
			}, id + (anchor ?? ""))
		}), outline.length > 1 && /* @__PURE__ */ jsx(Pane, {
			as: "aside",
			"aria-label": t("label_table_of_contents"),
			className: "box-content flex min-w-50 flex-[0_1_244px] flex-col p-6 shadow-line-s @max-5xl/app:flex-none @max-5xl/app:overflow-visible @max-5xl/app:shadow-line-t",
			children: /* @__PURE__ */ jsx(PageToc, {
				items: outline.map((h) => ({
					key: h.id,
					level: h.level,
					text: h.text,
					href: "#" + h.id
				})),
				active: spy.active,
				onSelect: spy.jump
			})
		})]
	})] });
}
/** The heading in view (the last one whose top is above the article's top, 16px under it), and a jump to one, 12px under
*  the article's top: the app's wiki page's 目次 (its scroll-spy), for the topic's headings. */
function useHeadingInView(scroller, headings) {
	const [active, setActive] = useState(headings[0]?.id);
	useEffect(() => {
		const box = scroller.current;
		if (!box || headings.length === 0) return;
		const update = () => {
			const top = box.getBoundingClientRect().top + 16;
			let current = headings[0].id;
			for (const heading of headings) {
				const el = box.querySelector("#" + CSS.escape(heading.id));
				if (el && el.getBoundingClientRect().top <= top) current = heading.id;
			}
			setActive(current);
		};
		update();
		box.addEventListener("scroll", update, { passive: true });
		return () => box.removeEventListener("scroll", update);
	}, [scroller, headings]);
	return {
		active,
		jump: useCallback((key) => {
			const box = scroller.current;
			const el = box?.querySelector("#" + CSS.escape(key));
			if (!box || !el) return;
			box.scrollTo({ top: el.getBoundingClientRect().top - box.getBoundingClientRect().top + box.scrollTop - 12 });
			setActive(key);
		}, [scroller])
	};
}
export { HelpCodeHighlighting, HelpPage, HelpPanel, HelpWikiSyntax };
