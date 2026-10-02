# pxvirt-virtio-win

精简版的 [virtio-win](https://github.com/virtio-win/kvm-guest-drivers-windows) Windows 驱动包，
供 PXVirt 使用（例如 autoinstall 在安装 Windows 时自动加载 VirtIO 驱动）。

- 安装路径：`/usr/share/pve-manager/virtio-win/<驱动>/<系统版本>/<架构>/`
- 驱动：`viostor vioscsi NetKVM Balloon vioserial`
- 系统版本：`w10 w11 2k16 2k19 2k22 2k25`
- 架构：`amd64 ARM64`（Windows 驱动与宿主机架构无关，deb 为 `all`，rpm 为 `noarch`）
- 附带：`guest-agent/qemu-ga-x86_64.msi`、`guest-agent/qemu-ga-arm64.msi`（来自 [jiangcuo/qemu-guest-agent](https://github.com/jiangcuo/qemu-guest-agent) 的 release）、`virtio-win_license.txt`、`VERSION`

保留哪些内容由 [`slim.conf`](slim.conf) 控制。

另有 `pxvirt-virtio-win-iso` 包，安装精简版 ISO 到
`/var/lib/vz/template/iso/pxvirt-virtio-win.iso`，在界面上可以直接作为 `local:iso/pxvirt-virtio-win.iso`
挂给 Windows 虚拟机。ISO 目录结构与官方 virtio-win ISO 相同，内容与驱动包一致（精简驱动和 qemu-ga）。文件名不带版本号，升级后已挂载的虚拟机无需修改配置。

## 版本

[`VERSION`](VERSION) 固定 virtio-win 的版本、上游 release、ISO 的 sha256，以及 qemu-ga 的版本和两个 MSI 的 sha256，
构建时下载的文件必须和这些校验值一致。

```sh
scripts/update-version.sh                    # 跟随 stable 渠道
scripts/update-version.sh --channel latest   # 跟随 latest 渠道
scripts/update-version.sh 0.1.271            # 指定版本
scripts/update-version.sh --qemu-ga 11.1.2-1 # 指定 qemu-ga 版本（默认最新 release）
```

脚本会更新 `VERSION`、`debian/changelog` 和 `rpm/pxvirt-virtio-win.spec` 的 `%changelog`。

## 本地构建

依赖：`curl`、`bsdtar`（libarchive-tools）、`xorriso`、`make`，deb 需要 `debhelper dpkg-dev`，rpm 需要 `rpm-build`。

```sh
make deb      # build/out/pxvirt-virtio-win{,-iso}_<版本>_all.deb
make rpm      # build/out/pxvirt-virtio-win{,-iso}-<版本>.noarch.rpm
make clean
```

## GitHub CI

- **Build**（`.github/workflows/build.yml`）：每次 push / PR 构建 deb（Debian bookworm）和 rpm（Rocky Linux 9）。
  默认分支上如果该版本还没有 release，会自动创建 `v<版本>` release 并上传两个包。
- **Update virtio-win**（`.github/workflows/update.yml`）：每周一自动检查 virtio-win stable 渠道和 qemu-ga 最新 release，
  有新版本就提交到默认分支并构建、发布。也可以在 Actions 页面手动运行，选择渠道或指定版本。

- 手动改 `VERSION` 里的版本号并把对应的校验值留空后 push，CI 会自动下载 ISO、补上校验值并构建。

自动提交需要默认分支允许 `github-actions[bot]` 推送（没有分支保护，或已加入例外）。
