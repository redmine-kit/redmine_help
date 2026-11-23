# 準備

<a id="requirements"></a>

## 前提

- Redmine 7.0 以降 (7.0.3 で確認)、Ruby 3.2〜4.0
- Redmine の CommonMark のフォーマッター (Redmine の Gemfile にある `commonmarker`)。Redmine のテキストの書式の設定によらず、ヘルプは Markdown です

<a id="required-plugins"></a>

### 必須プラグイン

ありません。

<a id="optional-plugins"></a>

### オプションのプラグイン

| プラグイン | 使える機能 |
| --- | --- |
| [Redmine Kit UI](https://github.com/redmine-kit/redmine_kit_ui) | 新しい UI のヘルプのパネル |

<a id="installation"></a>

## インストール

<a id="gem"></a>

### gem

プラグインは gem としてインストールするか (推奨)、`plugins/` にフォルダーとして置きます。`bin/release` が、各バージョンのプラグインを gem として GitHub Packages (`https://rubygems.pkg.github.com/redmine-kit`。[リリース](#releasing)) に公開します。GitHub Packages からインストールするには、公開のパッケージでも、`read:packages` のある GitHub のトークンが要ります。プラグインとガイドを Redmine の `Gemfile.local` に追加します。

```ruby
source 'https://rubygems.pkg.github.com/redmine-kit' do
  gem 'redmine_kit_help'
  gem 'redmine-guide'
end
```

次に、インストールします。

```sh
bundle install
```

Redmine を再起動します。Redmine は gem のフォルダーからプラグインを読み込むので、`plugins/` には何も置きません。マイグレーションはありません。`plugins/redmine_kit_help` にプラグインのチェックアウトがあるときは、gem ではなくそちらを使います。

<a id="without-the-gem"></a>

### gem を使わないとき

プラグインを `plugins/` に、ガイドを任意の場所にクローンし、プラグインにガイドの場所を指定します。

```sh
git clone https://github.com/redmine-kit/redmine_help.git plugins/redmine_kit_help
git clone https://github.com/redmine-kit/redmine-guide.git /srv/redmine-guide
export REDMINE_KIT_HELP_GUIDE_PATH=/srv/redmine-guide
```

<a id="the-guide"></a>

## ガイド

ガイドの中身 (`en/` と `ja/` の Markdown、`index.yml` の章、`map.yml` の画面) は、このプラグインには含まれていません。別のリポジトリの [redmine-guide](https://github.com/redmine-kit/redmine-guide) にあります。ガイドを redmine.org の更新に合わせ、翻訳を別の予定で進められるようにするためです。プラグインは、次の順にガイドを探します。

1. `REDMINE_KIT_HELP_GUIDE_PATH`: redmine-guide のチェックアウト
2. gem の `redmine-guide` (Bundler が読み込んでいるとき)

ガイドがないときは、ほかのプラグインのヘルプと運用者のページだけを表示し、目次にガイドがインストールされていないことを出します。

<a id="configuration"></a>

## 設定

| キー | 説明 | パラメーター |
| --- | --- | --- |
| `REDMINE_KIT_HELP_GUIDE_PATH` | ガイドのディレクトリ (redmine-guide のチェックアウト) | 省略可。デフォルトは gem の `redmine-guide` |
| `REDMINE_KIT_HELP_EXTRA_PATH` | 運用者のディレクトリ。追加するページ、囲み、置き換えるトピック ([extending.md](extending.md#the-operators-directory)) | 省略可 |

「ヘルプ」は、サイドパネルを開きます ([README.md](README.md#side-panel))。JavaScript がないときは、Redmine の元のリンクと同じく、ヘルプページを新しいタブで開きます。

<a id="tests"></a>

## テスト

テストは、コンテナの中の Redmine 7.0.3 と PostgreSQL 16 で動かします。コンテナは、[Apple container](https://github.com/apple/container) がインストールされていて動いていればそれを、そうでなければ Docker を使います (`CONTAINER_CLI=container` か `CONTAINER_CLI=docker` で選べます)。サイドパネルのシステムテスト (`test/system`) は、ヘッドレスの Chromium で動かします。

実行は、終わったときに (テストの成功、失敗、中断のいずれでも)、自分が起動したサービスのコンテナを停止します (削除はしません)。実行の前から動いていたコンテナと、このリポジトリの別の実行がまだ使っているコンテナは、そのまま動かしておきます。`KEEP_SERVICES=1` を指定すると、実行の後も動かしたままにします。

```sh
bin/test              # プラグインのテスト
bin/test --redmine    # プラグインをインストールした状態で、Redmine のすべてのテストも
bin/test-gem          # gem としてインストールしたプラグイン: gem のフォルダーから、次に plugins/ のチェックアウトから
REDMINE_BRANCH=master bin/test
COVERAGE=1 bin/test   # カバレッジを coverage/coverage.xml に出力する
bin/services --down   # PostgreSQL と Chromium を止める
bin/lint              # RuboCop (同じコンテナのツールで)
```

`COVERAGE=1` を付けると、プラグインのテストは、プラグイン自身のファイルのカバレッジ (SimpleCov。Cobertura の XML の `coverage/coverage.xml`) も出力します。CI は Redmine 7.0.3 でこれを有効にし、レポートを `plugin` フラグで [Codecov](https://codecov.io/gh/redmine-kit/redmine_help) に送信します。送信の認証は OIDC (`id-token: write`) なので、トークンをシークレットに保存しません。Codecov のステータスは参考情報で、コミットや Pull Request を失敗にしません (`codecov.yml`)。

テストは、redmine-guide ではなく、`test/fixtures/help` の小さなガイドを使います。この資料のスクリーンショットは `bin/screenshots` で作ります (今は Docker だけ)。

<a id="releasing"></a>
## リリース

`bin/release` は、gemspec のバージョンの gem を GitHub Packages の Redmine Kit のレジストリに公開します。実行できるのは変更のない `main` からだけで、バージョンが最後のタグ `v<version>` より新しいこと、必須プラグインがレジストリから範囲どおりに解決できること (`config/dependencies.yml`)、`bin/lint`、`bin/test`、`bin/test-gem` が成功することが条件です。公開には `~/.gem/credentials` のキー `github` (`:github: Bearer <token>`。`write:packages` を持つトークン) を使い、レジストリの読み取りには `BUNDLE_RUBYGEMS__PKG__GITHUB__COM` を使います。トークンはリポジトリにも出力にも含めません。署名付きのタグ `v<version>` を作り、それをプッシュするコマンドを表示します。バージョンはセマンティックバージョニングに従います。このプラグインを使うプラグインが動かなくなる変更ではメジャーバージョン (1.0 より前はマイナーバージョン) を上げ、それを必要とするプラグインの範囲も変えます。

