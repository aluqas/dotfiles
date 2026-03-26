# アーキテクチャ

このリポジトリは、Darwin・NixOS・Home Manager を単一ルートの flake でまとめて管理するための repo です。

ここでのアーキテクチャ文書は、思想の説明だけではなく、次を判断するための案内図として使うことを目的にしています。

- この設定はどこに置くべきか
- 既存 host はどう組み立てられているか
- 新しい機能や host をどう追加するか
- Stylix や secrets のような横断機能はどこで扱うか

## 設計原則

この repo は次のルールで構成します。

**Modules は実装する, Profiles は組み立てる, Hosts は具現化する, Homes はユーザー環境を持つ**

このルールは、どこにコードを書くかを決めるための最優先ルールです。

- `modules/*` は再利用可能な実装を持つ
- `profiles/*` は再利用可能な束と方針を持つ
- `hosts/*` は machine-specific な入口と最後の調整だけを持つ
- `homes/*` は共有ユーザー環境の正規ルートである

## repo の全体像

```text
.
├── flake.nix
├── lib/
├── modules/
│   ├── shared/
│   ├── darwin/
│   ├── nixos/
│   └── home/
├── profiles/
│   ├── system/
│   └── home/
├── homes/
│   └── saqula/
├── hosts/
│   ├── darwin/
│   └── nixos/
├── secrets/
├── dotfiles/
├── ops/
└── templates/
```

- `dotfiles/*` は実際に配布する設定ファイル群
- `ops/*` は deploy や bootstrap などの運用面
- `templates/*` は新規 project 用の雛形

`ops/*` や `templates/*` は重要ですが、host assembly の中心ではありません。

## dotfiles 反映ポリシー

この repo の dotfiles は、基本的に mutable を前提に扱います。

- app 側の変更をそのまま repo に残したい設定は `mkOutOfStoreSymlink` で local checkout に直結する
- app 側が保持すべき state / token / cache / history は Nix 管理しない
- `source = "${inputs.self}/..."` のような store 直リンクは、immutable に固定したい静的ファイルだけに使う

特に `~/.config/*` や `~/Library/Application Support/*` を directory 単位で link するときは、
配下に runtime state が混ざっていないかを必ず確認します。

判断基準は次の 2 つです。

1. app がその file を自分で更新するか
2. その更新を dotfiles repo に回収したいか

回収したいなら `mkOutOfStoreSymlink`、回収しないならそもそも Nix で管理しません。

## 評価と組み立ての流れ

この repo の中心は `flake.nix` と `lib/hosts.nix` です。  
個々の host を直接 `flake.nix` に書き込むのではなく、共通配線を `lib/hosts.nix` に寄せています。

流れは次のとおりです。

1. `flake.nix` が inputs と `hostDefinitions` を定義する
2. `flake.nix` が `lib/hosts.nix` を読み込み、`mkHosts` で Darwin / NixOS host を生成する
3. `lib/hosts.nix` が共通 module 群、Home Manager、Stylix、ragenix などを注入する
4. 各 host の `hosts/*/default.nix` が host 固有の last-mile override を与える
5. `homeImports` により `homes/saqula/*` と `profiles/home/*` が user environment を組み立てる

重要なのは、共通の組み立てルールを `lib/hosts.nix` に集約していることです。  
新しい host や共通 wiring を足すときは、まずこの流れを保てるかを見る必要があります。

## `flake.nix` の責務

`flake.nix` は「repo のトポロジー」を定義する場所です。

主な責務:

- flake input の宣言
- `hostDefinitions` の定義
- `darwinConfigurations` / `nixosConfigurations` の生成起点
- deploy output の定義
- `templates/*` の公開
- `devenv` shell や `packages` の公開

ここに書いてよいのは、構成の入口や配線の宣言です。  
host 固有挙動や大きな実装ロジックはここに増やさず、`lib/*` / `modules/*` / `hosts/*` に降ろします。

## `lib/*` の責務

`lib/*` は再利用可能な helper、定数、配線補助を持つ層です。  
この repo では特に `lib/hosts.nix` が重要です。

### `lib/hosts.nix`

この repo の host assembly の中心です。

担当していること:

- `mkSaqulaLib` で module から使う helper 群を作る
- Darwin / NixOS それぞれの共通 module セットを定義する
- Home Manager, Stylix, ragenix, disko, impermanence などの共通 wiring を注入する
- `inputs`, `hostVars`, `globalVars`, `paths`, `saqulaLib` を `specialArgs` として渡す
- `homeImports` を各 user environment へ接続する

`mkSaqulaLib` が提供する主な helper:

- `secrets`: `lib/secrets.nix` を platform-aware に読んだ helper
- `mkFeatureOptions`: `enable` だけを持つ option helper
- `mkFeatureOptionsExt`: `enable` と追加 option を持つ helper
- `wrapConfig`: `cfg.enable` のときだけ設定を有効化する helper
- `mkPlatformAssert`: Darwin / NixOS の誤用を防ぐ assertion helper

ここは「共通の組み立て規約」を持つ場所であり、個別 host の振る舞いを書く場所ではありません。

### `lib/vars.nix`

グローバル既定値の置き場です。

- default user
- locale / timezone の既定値
- `stateVersion` の一元管理
- 永続化対象の共通一覧

host や module が同じ定数を重複定義しないための基盤です。

### `lib/paths.nix`

repo root から主要ディレクトリへの path を組み立てる helper です。

- `dotfiles`
- `homes`
- `hosts`
- `lib`
- `modules`
- `profiles`
- `scripts`
- `secrets`

path 文字列を module 側に散らさず、共通化したいときに使います。

### `lib/secrets.nix`

`age.secrets.*` 定義を簡潔に書くための helper 群です。

主な helper:

- `mkSecret`
- `mkSshKey`
- `mkSshConfig`
- `mkGpgSecret`

各 host / module が secret の file path や owner / mode の細部を毎回書かなくて済むようにしています。

### `lib/keys.nix`

公開鍵の正規参照点です。

- SSH 公開鍵
- age 公開鍵
- GPG 公開鍵

`hosts/*/vars.nix` や `secrets/secrets.nix` から参照されます。

### `lib/overlays.nix`

nixpkgs overlay の集約点です。

- repo 全体に効かせる package overlay
- toolchain shortcut
- `crane` のような build helper の公開

package override を host ごとに散らしたくないときはここへ寄せます。

## `modules/*` の構成

`modules/*` は再利用可能な実装の層です。  
ここに「どう動かすか」を書き、どこで有効化するかは profile や host で決めます。

### `modules/shared/*`

shared option surface を定義する層です。

- [`modules/shared/options.nix`](../modules/shared/options.nix)
  - `saqula.*` 名前空間の上位 option を定義する
  - 例: `saqula.system.btrbk`, `saqula.home.impermanence`, `saqula.devex.cachix`, `saqula.secrets`
- [`modules/shared/types.nix`](../modules/shared/types.nix)
  - 共通型を定義する
  - 例: 統一 service 定義の submodule 型

ここは「実装」よりも「契約」を置く場所です。

### `modules/darwin/*`

Darwin 固有の system 実装です。

- [`modules/darwin/base.nix`](../modules/darwin/base.nix)
  - Nix 設定
  - shell baseline
  - macOS defaults
  - privacy / security baseline
  - age secret の配置
- [`modules/darwin/apps.nix`](../modules/darwin/apps.nix)
  - GUI app / package のポリシー

Darwin 固有の実装はここへ集約し、`hosts/darwin/*` は薄く保ちます。

### `modules/nixos/*`

NixOS 固有の system 実装です。  
大きく分けると core module と services module があります。

core module の例:

- `boot.nix`
- `disks.nix`
- `guardrails.nix`
- `impermanence.nix`
- `locale.nix`
- `minimal.nix`
- `network.nix`
- `optimization.nix`
- `programs.nix`
- `security.nix`
- `users.nix`

これらは host で何度も使う基礎機能を module 化したものです。

### `modules/nixos/services/*`

service 実装のまとまりです。  
さらに 3 つのサブツリーに分かれています。

#### `modules/nixos/services/container/*`

container runtime と周辺機能です。

- `containerd.nix`
- `podman.nix`
- `runtimes.nix`
- `compose-service.nix`
- `tailscale-sidecar.nix`

Docker / Podman / containerd 周辺の再利用可能な実装はここに置きます。

#### `modules/nixos/services/cluster/*`

cluster / container orchestration まわりです。

- `portainer.nix`
- `nomad.nix`
- `incus.nix`

単体サービスとして使える cluster tool を置いています。

#### `modules/nixos/services/k3s/*`

K3s stack とその addon 群です。

- `k3s.nix`
- `runtimes.nix`
- `cilium.nix`
- `argocd.nix`
- `vcluster.nix`
- `kubevirt.nix`
- `longhorn.nix`
- `tailscale-operator.nix`
- `rancher.nix`

K3s 本体だけでなく、「K3s を中心とした一式」をここで実装します。

### `modules/home/*`

Home Manager 側の shared 実装です。  
共有ユーザー環境の実体はここにあります。

サブツリーの意味:

- `modules/home/develop/*`
  - editor, shell, terminal, git, env
- `modules/home/cli/*`
  - CLI utility 群
- `modules/home/agent/*`
  - agent / MCP 関連
- `modules/home/infra/*`
  - infra tool
- `modules/home/security/*`
  - GPG など

shared user environment を変えたいときは、まずここを見るのが基本です。

## `profiles/*` の構成

`profiles/*` は再利用可能な束を plain `imports` で組み立てる層です。  
実装を持つのではなく、「何を一緒に有効化するか」を定義します。

### `profiles/home/*`

- [`profiles/home/develop.nix`](../profiles/home/develop.nix)
  - shared developer UX の bundle
  - `modules/home/agent/*`, `modules/home/develop/*`, `modules/home/cli/*`, `modules/home/security/*` を束ねる
- [`profiles/home/infra.nix`](../profiles/home/infra.nix)
  - cloud / Kubernetes 系の tooling を足す

### `profiles/system/*`

- [`profiles/system/darwin-workstation.nix`](../profiles/system/darwin-workstation.nix)
  - Darwin workstation の既定
- [`profiles/system/nixos-server.nix`](../profiles/system/nixos-server.nix)
  - NixOS server の baseline
- [`profiles/system/nixos-oci-node.nix`](../profiles/system/nixos-oci-node.nix)
  - OCI 向け追加方針

system policy を複数 host で共有したいなら、まずここに置きます。

## `homes/*` の構成

`homes/*` は shared user environment の正規ルートです。

この repo では `homes/saqula/*` が中心です。

- [`homes/saqula/base.nix`](../homes/saqula/base.nix)
  - `home.stateVersion`
  - `programs.home-manager.enable`
- [`homes/saqula/stylix.nix`](../homes/saqula/stylix.nix)
  - shared theme policy
- [`homes/saqula/platform/darwin.nix`](../homes/saqula/platform/darwin.nix)
  - Darwin 向け Home Manager 追加設定
- [`homes/saqula/default.nix`](../homes/saqula/default.nix)
  - `base.nix` と `stylix.nix` の入口

shared な user experience は host に直書きせず、まず `homes/saqula/*` を通します。

## `hosts/*` の構成

`hosts/*` は machine-specific な入口です。  
host は薄く保ち、最後の調整だけを担当します。

各 host ディレクトリには、だいたい次のものがあります。

- `default.nix`
  - profile import
  - host 固有の override
- `vars.nix`
  - hostname, username, disk path, subnet などの host facts
- `hardware-configuration.nix`
  - NixOS の low-level hardware config
- `disk-config.nix`
  - host 固有の disk layout
- `services.nix`
  - host 固有の service enablement 集約

例:

- `hosts/darwin/macbook/default.nix`
  - `darwin-workstation` profile を import し、hostname を与える
- `hosts/nixos/nixos-bootstrap/default.nix`
  - baseline server と hardware / disk config を import し、最小限の server bootstrap を組む
- `hosts/nixos/oci-nixcloud/default.nix`
  - `nixos-server` + `nixos-oci-node` を import し、Tailscale, storage, K3s data path などの最後の調整を与える

## クロスカット機能

### Stylix / テーマ

見た目の共通化は Stylix を軸に行います。

- input の取り込み: [`flake.nix`](../flake.nix)
- host への wiring: [`lib/hosts.nix`](../lib/hosts.nix)
- shared Home Manager 設定: [`homes/saqula/stylix.nix`](../homes/saqula/stylix.nix)
- theme asset: `dotfiles/stylix/*`

原則:

- 配色や共通テーマ方針は `homes/saqula/stylix.nix`
- アプリ固有の調整は `modules/home/*` または `dotfiles/*`
- host ごとにテーマ方針を重複させない

### Secrets

secret management は `ragenix` と age を前提にします。

- encrypted payload: `secrets/*.age`
- どの鍵で復号できるか: [`secrets/secrets.nix`](../secrets/secrets.nix)
- helper: [`lib/secrets.nix`](../lib/secrets.nix)
- 公開鍵の正規定義: [`lib/keys.nix`](../lib/keys.nix)
- 利用側: 各 module / host の `config.age.secrets.*`

原則:

- secret の実体は `secrets/*.age`
- 鍵や helper は `lib/*`
- 利用側 module は「どの secret を使うか」だけを書く
- 復号 identity path のルールは platform ごとの system module で持つ

### Home Manager

Home Manager は host builder から共通注入されます。

- Darwin / NixOS どちらも `lib/hosts.nix` で wiring される
- `sharedModules` として Stylix Home module が入る
- 各 user の `imports` は `homeImports` で host definition から渡される

つまり、Home Manager の shared 配線を変えるときは host file ではなく `lib/hosts.nix` 側を見ます。

### Impermanence

impermanence は NixOS 側の横断機能です。

- input 注入: `lib/hosts.nix`
- 実装: `modules/nixos/impermanence.nix`
- host 側の disk / persist layout と組み合わせて動く

永続化対象の共通一覧は `lib/vars.nix` にあり、system 側の rollback / persistence 実装は `modules/nixos/impermanence.nix` にあります。

## 〇〇したいとき

- 新しい host を増やしたい
  - `flake.nix` の `hostDefinitions` を追加する
  - `hosts/<platform>/<host>/` を作る
- 新しい shared system 機能を作りたい
  - `modules/darwin/*` または `modules/nixos/*` に置く
- 新しい reusable service を作りたい
  - `modules/nixos/services/*` に置く
- shared developer UX を変えたい
  - `modules/home/*` に実装し、`homes/saqula/*` または `profiles/home/*` で束ねる
- 複数 host で共通の方針を追加したい
  - `profiles/system/*` または `profiles/home/*` に置く
- 特定 host だけを変えたい
  - `hosts/*` に last-mile override として書く
- テーマを変えたい
  - `homes/saqula/stylix.nix` と `dotfiles/stylix/*` を見る
- secret を追加したい
  - `secrets/*.age`, `secrets/secrets.nix`, `lib/secrets.nix`, `lib/keys.nix`, 利用側 module を順に見る
- host assembly 自体を変えたい
  - `lib/hosts.nix` を見る

## アンチパターン

- host 固有の調整を reusable module に書く
- shared user tooling を host の `default.nix` に直書きする
- secrets の path / owner / mode を各所で ad hoc に複製する
- テーマ方針を host ごとに重複定義する
- `flake.nix` に詳細実装を直接書き込む
- native HM / NixOS option で足りるのに wrapper option を増やす

この repo の目的は、設定を 1 箇所に集めることではなく、責務ごとに迷わず置けるようにすることです。  
置き場所に迷ったら、「これは実装か、方針か、shared user env か、host-specific last mile か」を先に切り分けます。
