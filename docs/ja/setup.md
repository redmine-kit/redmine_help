# 準備

<a id="requirements"></a>

## 前提

- Redmine 7.0 以降 (7.0.3 で確認)
- Redmine の CommonMark のフォーマッター (Redmine の Gemfile にある `commonmarker`)。Redmine のテキストの書式の設定によらず、ヘルプは Markdown です

<a id="installation"></a>

## インストール

<a id="gem"></a>

### gem

バージョンのタグごとに、プラグインを gem として GitHub Packages (`https://rubygems.pkg.github.com/redmine-kit`) に公開しています。GitHub Packages からインストールするには、公開のパッケージでも、`read:packages` のある GitHub のトークンが要ります。プラグインとガイドを `Gemfile.local` に追加してインストールし、プラグインを `plugins/` にリンクします。

```ruby
source 'https://rubygems.pkg.github.com/redmine-kit' do
  gem 'redmine_help'
  gem 'redmine-guide'
end
```

```sh
bundle install
ln -s "$(bundle info --path redmine_help)" plugins/redmine_help
```

Redmine を再起動します。マイグレーションはありません。

<a id="without-the-gem"></a>

### gem を使わないとき

プラグインを `plugins/` に、ガイドを任意の場所にクローンし、プラグインにガイドの場所を指定します。

```sh
git clone https://github.com/redmine-kit/redmine_help.git plugins/redmine_help
git clone https://github.com/redmine-kit/redmine-guide.git /srv/redmine-guide
export REDMINE_HELP_GUIDE_PATH=/srv/redmine-guide
```

<a id="the-guide"></a>

## ガイド

ガイドの中身 (`en/` と `ja/` の Markdown、`index.yml` の章、`map.yml` の画面) は、このプラグインには含まれていません。別のリポジトリの [redmine-guide](https://github.com/redmine-kit/redmine-guide) にあります。ガイドを redmine.org の更新に合わせ、翻訳を別の予定で進められるようにするためです。プラグインは、次の順にガイドを探します。

1. `REDMINE_HELP_GUIDE_PATH`: redmine-guide のチェックアウト
2. gem の `redmine-guide` (Bundler が読み込んでいるとき)

ガイドがないときは、ほかのプラグインのヘルプと運用者のページだけを表示し、目次にガイドがインストールされていないことを出します。

<a id="configuration"></a>

## 設定

| キー | 説明 | パラメーター |
| --- | --- | --- |
| `REDMINE_HELP_GUIDE_PATH` | ガイドのディレクトリ (redmine-guide のチェックアウト) | 省略可。デフォルトは gem の `redmine-guide` |
| `REDMINE_HELP_EXTRA_PATH` | 運用者のディレクトリ。追加するページ、囲み、置き換えるトピック ([extending.md](extending.md#the-operators-directory)) | 省略可 |

「ヘルプ」は、サイドパネルを開きます ([README.md](README.md#side-panel))。JavaScript がないときは、Redmine の元のリンクと同じく、ヘルプページを新しいタブで開きます。

<a id="tests"></a>

## テスト

テストは、Docker の中の Redmine 7.0.3 と PostgreSQL 16 で動かします。サイドパネルのシステムテスト (`test/system`) は、ヘッドレスの Chromium で動かします。

```sh
bin/test              # プラグインのテスト
bin/test --redmine    # プラグインをインストールした状態で、Redmine のすべてのテストも
REDMINE_BRANCH=master bin/test
bin/services --down   # PostgreSQL と Chromium を止める
bin/lint              # RuboCop
```

テストは、redmine-guide ではなく、`test/fixtures/help` の小さなガイドを使います。この資料のスクリーンショットは `bin/screenshots` で作ります。
