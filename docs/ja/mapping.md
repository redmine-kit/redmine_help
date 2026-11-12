# 画面とトピックの対応

ヘッダーの「ヘルプ」は、押された画面の情報を付けて `/help/context` を開きます。画面の情報は、コントローラー、アクション、画面にあればパラメーターの `tab` と `type` です。プラグインは、対応表で画面を探してトピックを開きます。サイドパネルは同じ URL に `panel=1` を付けて呼び、リダイレクトの代わりにサイドパネル用のトピックを受け取ります。`show` と `search` も `panel=1` を受け付けます。

<a id="the-map"></a>

## 対応表

対応表は、トピックと同じ場所の `map.yml` です (ガイド、プラグインの `help/`、運用者のディレクトリ)。キーが画面、値がトピックで、見出しのアンカーも付けられます。

```yaml
issues#index: user/issue-list
issues#show: user/issues
issues: user/issues
settings#index?tab=authentication: admin/settings#Authentication
settings#index: admin/settings
```

トピックは、言語のディレクトリから見た Markdown のファイルのパスで、`.md` を除いたものです。`user/issue-list` は `en/user/issue-list.md` と `ja/user/issue-list.md` です。

<a id="lookup"></a>

## 検索順序

画面ごとに、次の順にキーを探し、どれかの対応表で最初に見つかったキーを使います。

1. `controller#action?tab=値` と `controller#action?type=値` (画面にそのパラメーターがあるとき)
2. `controller#action`
3. `controller` (そのコントローラーのすべてのアクション)

同じキーは、運用者のディレクトリ、プラグイン、ガイドの順に探します。どのキーもない画面では、目次 (`/help`) を開きます。

ページを読み込み直さずにタブを切り替えたときは、サイドパネルは新しいタブで画面を探し、タブを含むキー (`controller#action?tab=値`) が見つかったときだけ移ります。タブのキーがないときは、サイドパネルはそのままです。

<a id="anchors"></a>

## アンカー

アンカーは、Redmine が見出しに付けるものと同じです。見出しの文字の空白を `-` にしたものです (Redmine の Wiki と同じ)。`admin/settings#Authentication` は、「Authentication」の見出しの位置でページを開きます。

アンカーは常に英語のページのものを書きます。翻訳は英語のページと同じ数と階層の見出しを同じ順に持ち、ヘルプは翻訳の同じ位置の見出しを開きます。トピック間のリンク (`settings.md#Authentication`) も同じです。見出しが英語と違う翻訳は、ページの先頭で開きます。
