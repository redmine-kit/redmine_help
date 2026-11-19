// Redmine Kit Help: the plugin's module for the new UI, built from frontend/src by `npm run build` (frontend/vite.config.js).
// Edit the source, not this file. React, @redmine-kit/ui and @redmine-kit/plugin come from the app (the shell's import map).
import { useCallback, useEffect, useRef, useState } from "react";
import { AppLink, ExtensionPanelHeader, ScreenSidebar, useExtensionContext, useKitNavigate, useKitQuery, useT } from "@redmine-kit/plugin";
import { Card, CardBody, CardHeader, EmptyState, Icon, IconButton, Notice, Prose, SearchInput, SectionHeading, Skeleton, SkeletonRegion, cn } from "@redmine-kit/ui";
import { Fragment, jsx, jsxs } from "react/jsx-runtime";
// src/api.ts
var enc = (id) => id.split("/").map(encodeURIComponent).join("/");
var helpPaths = {
	contents: "/help.json",
	topic: (id, anchor) => `/help/${enc(id)}.json${anchor ? `?anchor=${encodeURIComponent(anchor)}` : ""}`,
	search: (q) => `/help/search.json?q=${encodeURIComponent(q)}`,
	context: (screen, tab) => `/help/context.json?screen=${encodeURIComponent(screen)}${tab ? `&tab=${encodeURIComponent(tab)}` : ""}`
};
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
function HelpPanel() {
	const t = useT();
	const { screen } = useExtensionContext();
	const name = screen?.name ?? null;
	const tab = screen?.tab ?? null;
	const context = useKitQuery(name ? helpPaths.context(name, tab) : null);
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
	const seen = useRef(null);
	useEffect(() => {
		if (!screenView) return;
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
				children: context.isError ? /* @__PURE__ */ jsx(HelpLoadError, {}) : !view ? /* @__PURE__ */ jsx(HelpTextSkeleton, {}) : view.kind === "topic" ? /* @__PURE__ */ jsx(HelpTopicView, {
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
function HelpPage() {
	const t = useT();
	const navigate = useKitNavigate();
	const { params } = useExtensionContext();
	const topic = params.topic;
	const [q, setQ] = useState("");
	const [title, setTitle] = useState("");
	const pane = useRef(null);
	const view = q.trim() ? {
		kind: "search",
		q: q.trim()
	} : topic ? {
		kind: "topic",
		id: topic
	} : { kind: "contents" };
	const go = useCallback((next) => navigate(helpHref(next)), [navigate]);
	const onSubmit = (e) => {
		e.preventDefault();
		if (q.trim()) go({
			kind: "search",
			q: q.trim()
		});
	};
	const contents = useKitQuery(helpPaths.contents);
	const sections = contents.data?.help.sections ?? [];
	const groups = [{
		key: "help",
		label: t("label_help"),
		rows: [{
			key: "contents",
			label: t("label_table_of_contents"),
			icon: "list-bullet",
			href: helpHref({ kind: "contents" }),
			selected: view.kind === "contents"
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
				selected: item.id === topic
			}))
		}))],
		loadingRows: contents.isPending ? 4 : void 0
	}];
	const heading = view.kind === "topic" ? title || t("label_help") : view.kind === "search" ? t("label_search") : t("label_help");
	return /* @__PURE__ */ jsxs(Fragment, { children: [/* @__PURE__ */ jsx(ScreenSidebar, {
		label: t("label_help"),
		groups
	}), /* @__PURE__ */ jsxs(Card, {
		"aria-label": t("label_help"),
		children: [/* @__PURE__ */ jsx(CardHeader, {
			title: heading,
			actions: /* @__PURE__ */ jsx("form", {
				role: "search",
				onSubmit,
				children: /* @__PURE__ */ jsx(SearchInput, {
					"aria-label": t("label_search"),
					placeholder: t("label_search"),
					value: q,
					onChange: (e) => setQ(e.target.value),
					onClear: () => setQ(""),
					className: "w-full"
				})
			}),
			divider: true
		}), /* @__PURE__ */ jsx(CardBody, {
			padded: true,
			children: /* @__PURE__ */ jsx("div", {
				ref: pane,
				children: view.kind === "topic" ? /* @__PURE__ */ jsx(HelpTopicView, {
					id: view.id,
					scroller: pane,
					reading: true,
					onTitle: setTitle
				}) : view.kind === "search" ? /* @__PURE__ */ jsx(HelpResults, { q: view.q }) : /* @__PURE__ */ jsx(HelpContents, {})
			})
		})]
	})] });
}
export { HelpPage, HelpPanel };
