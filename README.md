# Saqula dotfiles

このリポジトリは、単一ルートの flake で次をまとめて管理するための repo です。

- `macbook` 向けの `nix-darwin`
- `nixos-bootstrap` や `oci-nixcloud` のような NixOS ホスト
- `homes/saqula` を中心にした共有 Home Manager 開発環境

この repo の基本ルールは次のとおりです。

**Modules は実装する, Profiles は組み立てる, Hosts は具現化する, Homes はユーザー環境を持つ**

詳しい設計と拡張ルールは [docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md) にまとめています。
「どこを触ればよいか」「どう配線されるか」を知りたいときは、まずそちらを読む想定です。

## 最短の使い方

macOS を新規ブートストラップする場合:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/aluqas/dotfiles/main/scripts/install.sh)
```

普段の作業はまず `devenv shell` に入ってから行います。

```bash
devenv shell
```

そのうえで、repo に用意しているスクリプトを使います。

```bash
fmt
lint
check
build-mac
switch-mac
build-bootstrap
switch-bootstrap
build-lab
switch-lab
deploy-lab-dry
deploy-lab
update
doctor
clean
```

この repo では raw な `nixos-rebuild` は使わず、`nh` または `devenv` のスクリプトを使う運用です。

## まずどこを見るか

- repo 全体の入口と host 定義: [`flake.nix`](./flake.nix)
- 共通の host 組み立て: [`lib/hosts.nix`](./lib/hosts.nix)
- グローバル既定値と path helper: [`lib/vars.nix`](./lib/vars.nix), [`lib/paths.nix`](./lib/paths.nix)
- shared user environment の入口: [`homes/saqula/default.nix`](./homes/saqula/default.nix)
- Home Manager の shared 実装: [`modules/home/*`](./modules/home)
- Darwin / NixOS の system 実装: [`modules/darwin/*`](./modules/darwin), [`modules/nixos/*`](./modules/nixos)
- 再利用可能な束: [`profiles/home/*`](./profiles/home), [`profiles/system/*`](./profiles/system)
- host ごとの最後の調整: [`hosts/*`](./hosts)
- secret の定義と鍵: [`secrets/*`](./secrets), [`lib/secrets.nix`](./lib/secrets.nix), [`lib/keys.nix`](./lib/keys.nix)

## どこを編集するか

- 再利用可能な system 機能を足したい: `modules/darwin/*` または `modules/nixos/*`
- 複数 host で共有する方針を足したい: `profiles/system/*`
- 共有 user tooling を足したい: `modules/home/*` を実装し、`homes/saqula/*` または `profiles/home/*` で束ねる
- 特定 host だけを調整したい: `hosts/*`
- 実際の dotfiles を変えたい: `dotfiles/*`
- テーマや配色を変えたい: `homes/saqula/stylix.nix` と `dotfiles/stylix/*`
- secret を追加したい: `secrets/*.age`, `secrets/secrets.nix`, `lib/secrets.nix`, `lib/keys.nix`
- deploy や bootstrap 手順を変えたい: `ops/*` または `scripts/*`

## dotfiles の反映方針

この repo の user-facing な設定ファイルは、原則として mutable を前提にします。

- app 側で編集した内容を repo に回収したい設定は `mkOutOfStoreSymlink` で local checkout に直結する
- state / token / cache / history のような runtime data は Nix で管理しない
- directory ごと link するときは、配下に mutable state が混ざらないことを先に確認する

つまり、`/nix/store` に固定したいかどうかではなく、
「その変更を repo で追いたいか」「app に自由に書かせるべきか」を先に判断する運用です。

## 共通機能

### Stylix / テーマ

見た目の共通化は Stylix を軸に行います。

- input の取り込み: [`flake.nix`](./flake.nix)
- host への注入: [`lib/hosts.nix`](./lib/hosts.nix)
- shared Home Manager 設定: [`homes/saqula/stylix.nix`](./homes/saqula/stylix.nix)
- theme asset: [`dotfiles/stylix`](./dotfiles/stylix)

共通テーマはまず shared home 側へ寄せ、アプリ固有の細かい調整は `modules/home/*` または `dotfiles/*` で吸収します。

### Secrets / age / ragenix

secret management は `ragenix` と age を前提にしています。

- 暗号化済み secret 本体: [`secrets/*.age`](./secrets)
- どの鍵で復号できるか: [`secrets/secrets.nix`](./secrets/secrets.nix)
- secret helper: [`lib/secrets.nix`](./lib/secrets.nix)
- 公開鍵の正規定義: [`lib/keys.nix`](./lib/keys.nix)

この repo の復号 identity パスは次の運用に揃えています。

- Darwin: `~/.config/age/keys.txt`
- NixOS: `/persist/var/lib/age/keys.txt`

詳細は [secrets/README.md](./secrets/README.md) を参照してください。

## 詳細ドキュメント

- 設計、配線、置き場所の判断基準: [docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md)
- AI / コーディングエージェント向けの運用ルール: [AGENTS.md](./AGENTS.md)
- secret と公開鍵の管理方針: [secrets/README.md](./secrets/README.md)
