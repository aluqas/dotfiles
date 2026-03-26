# コンテナ運用ガイド

このドキュメントは、`macbook`（Darwin）でのコンテナ運用手順をまとめたものです。

## macOS: OrbStack（標準）

`macbook` の標準コンテナ運用は OrbStack に統一します。  
日常的な `docker` / `docker compose` 操作は OrbStack 経由で行います。

## 反映

```bash
devenv shell
switch-mac
```

## 初回確認

```bash
docker version
docker compose version
docker ps
```

OrbStack の起動状態に問題がある場合は、OrbStack アプリ側の状態も確認してください。

## 日常運用

```bash
docker ps
docker compose up -d
docker compose logs -f
docker compose down
```

## 補足

- このリポジトリには将来の切り戻し用に Lima 関連実装が残っていますが、現時点では標準導線に含めません。
- `switch-mac` など flake 経由の評価では、参照する新規ファイルが未追跡だと反映されません。
