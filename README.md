# pxvirt-virtio-win

精简版的 [virtio-win](https://github.com/virtio-win/kvm-guest-drivers-windows) Windows 驱动包，
供 PXVirt 使用（例如 autoinstall 在安装 Windows 时自动加载 VirtIO 驱动）。

- 安装路径：`/usr/share/pve-manager/virtio-win/<驱动>/<系统版本>/<架构>/`
- 驱动：`viostor vioscsi NetKVM Balloon vioserial`
- 系统版本：`w10 w11 2k16 2k19 2k22 2k25`
- 架构：`amd64 ARM64`（Windows 驱动与宿主机架构无关，deb 为 `all`，rpm 为 `noarch`）
- 附带：`guest-agent/qemu-ga-x86_64.msi`、`virtio-win_license.txt`、`VERSION`

保留哪些内容由 [`slim.conf`](slim.conf) 控制。

## 版本

[`VERSION`](VERSION) 固定 virtio-win 的版本、上游 release 和 ISO 的 sha256，
构建时下载的 ISO 必须和这个校验值一致。

```sh
scripts/update-version.sh                    # 跟随 stable 渠道
scripts/update-version.sh --channel latest   # 跟随 latest 渠道
scripts/update-version.sh 0.1.271            # 指定版本
```

脚本会更新 `VERSION`、`debian/changelog` 和 `rpm/pxvirt-virtio-win.spec` 的 `%changelog`。

## 本地构建

依赖：`curl`、`bsdtar`（libarchive-tools）、`make`，deb 需要 `debhelper dpkg-dev`，rpm 需要 `rpm-build`。

```sh
make deb      # build/out/pxvirt-virtio-win_<版本>_all.deb
make rpm      # build/out/pxvirt-virtio-win-<版本>.noarch.rpm
make clean
```

## GitHub CI

- **Build**（`.github/workflows/build.yml`）：每次 push / PR 构建 deb（Debian bookworm）和 rpm（Rocky Linux 9）。
  默认分支上如果该版本还没有 release，会自动创建 `v<版本>` release 并上传两个包。
- **Update virtio-win**（`.github/workflows/update.yml`）：每周一自动检查 stable 渠道，
  有新版本就提交到默认分支并构建、发布。也可以在 Actions 页面手动运行，选择渠道或指定版本。

- 手动改 `VERSION` 里的版本号并把 `VIRTIO_WIN_SHA256` 留空后 push，CI 会自动下载 ISO、补上校验值并构建。

自动提交需要默认分支允许 `github-actions[bot]` 推送（没有分支保护，或已加入例外）。
