# Secrets と Public Keys

このディレクトリには 2 種類のものがあります。

- 暗号化済み secret: `*.age`
- 公開鍵・公開情報: `public-keys/*`

通常運用の考え方は次のとおりです。

- 通常のリモート接続は `tailscale ssh` を前提とする
- `authorized_keys` 用の SSH 公開鍵は常用ではなく、ブートストラップ用と緊急用として扱う
- age identity は別物で、secret 復号専用とする

## Age Identity

この repo が前提にする age identity の配置先は次のとおりです。

- Darwin: `~/.config/age/keys.txt`
- NixOS: `/persist/var/lib/age/keys.txt`

補足:

- macOS のクリーンインストール時は、`~/.config/age/keys.txt` を人手で配置してから `switch-mac` する
- NixOS の初回ブートストラップでは [scripts/cloud-bootstrap.sh](../scripts/cloud-bootstrap.sh) が `~/.config/age/keys.txt` をターゲットへ配送する

## 公開鍵

### GPG 公開鍵

- ファイル: `public-keys/gpg-public-key.asc`
- 形式: ASCII Armor (`.asc`)
- 用途: GPG 署名検証、暗号化通信

### SSH 公開鍵

- `public-keys/ssh-public-key-git.pub`
  - 用途: Git 認証用
- `public-keys/id_ed25519_emergency.pub`
  - 用途: 緊急用 / ブートストラップ用
- `public-keys/id_ed25519_general_ssh.pub`
  - 用途: 旧来の SSH 鍵。現在は常用前提ではない
- `public-keys/ssh-touch-key.pub`
  - 用途: 参照先を確認してから利用すること

## 暗号化済み Secret

主な secret は次の用途で使われています。

- `config.age`
  - Darwin の SSH config
- `id_ed25519_git.age`
  - Git 認証用 SSH 秘密鍵
- `id_ed25519_emergency.age`
  - 緊急用 SSH 秘密鍵
- `gpg-secret-subkeys.age`
  - GPG subkeys
- `gpg-ownertrust.age`
  - GPG ownertrust
- `cachix-token.age`
  - Cachix push token
- `tailscale-auth-key.age`
  - Tailscale auth key
- `tailscale-oauth-client-secret.age`
  - Tailscale OAuth client secret

## 補足

- 秘密鍵の平文をこのディレクトリに直接置かないこと
- 公開鍵は Git 管理でよいが、secret payload は `.age` で管理する
- `secrets/secrets.nix` と実ファイルの整合は定期的に確認すること
