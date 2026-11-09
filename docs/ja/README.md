# Redmine Help

Redmine Help(`redmine_help`)は、Redmine のヘッダーの「ヘルプ」を、ユーザーがいま開いている画面のヘルプに変えるプラグインです。ヘルプはユーザーの言語で、Redmine の中に表示します。

- [準備](setup.md): 前提、インストール、ガイドの中身、設定、テスト
- [画面とトピックの対応](mapping.md): 画面からヘルプのトピックへの対応表
- [ヘルプを足す](extending.md): ほかのプラグインのヘルプ、運用者のページとサポート情報

<a id="features"></a>

## 機能

- **いま開いている画面のヘルプ:** 「ヘルプ」は、画面に対応付けたトピックを開きます。たとえば、チケットの一覧ではガイドのチケットの一覧のページを、「管理」›「設定」›「認証」では認証の節を開きます。対応するトピックのない画面では、目次を開きます。
- **ユーザーの言語:** 翻訳があればユーザーの言語で、なければ英語で、その旨を添えて表示します。サイドバーで、ほかの言語に切り替えられます。
- **Redmine の中に表示:** ページは Redmine の Wiki のページと同じ形です。本文と目次、サイドバーのガイドの章、ヘルプの中の検索があります。
- **Redmine のガイド:** redmine.org のガイドを Markdown にして翻訳したものです。別のリポジトリと gem の [redmine-guide](https://github.com/redmine-kit/redmine-guide) にあります。
- **ほかのプラグインのヘルプ:** プラグインは、`help/` のディレクトリを持つだけで、自分のトピック、章、画面を足せます([extending.md](extending.md#plugins))。
- **運用者のページ:** `REDMINE_HELP_EXTRA_PATH` で指定したディレクトリから、ページ(社内の問い合わせ先、ホスティングのサービスのサポートなど)、すべてのページや一部のトピックに出す囲み、トピックの置き換えを足せます([extending.md](extending.md#the-operators-directory))。

<a id="screen"></a>

## 画面

![チケットの一覧のヘルプ。サイドバーにガイドの章](images/help.png)

<a id="access"></a>

## 使える人

ヘルプは、Redmine を見られる人なら誰でも開けます。ログインしたユーザーと、Redmine がログインを求めないとき(「管理」›「設定」›「認証」›「認証が必要」がオフ)は匿名のユーザーです。

<a id="sponsors"></a>

## スポンサー

<Sponsors ids="keyselect"><a href="https://www.keyselect.co.jp/">KEY SELECT</a></Sponsors>

<a id="license"></a>

## ライセンス

Redmine Help は、GNU General Public License バージョン 2 またはそれ以降のバージョンで公開しています。[LICENSE](../../LICENSE) を参照してください。Redmine の非公式のプラグインです。
