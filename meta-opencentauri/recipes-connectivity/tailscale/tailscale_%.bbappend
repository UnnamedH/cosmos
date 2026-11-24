FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# One combined binary (tailscaled, and tailscale via argv0). Everything
# else in PACKAGECONFIG is left off so the omit tag is what gets built.
# clientmetrics stays: tailscale 1.94.2 does not compile ts_omit_clientmetrics
# together with the syspolicy package, which is not itself omit-safe here.
PACKAGECONFIG = "cli"

PACKAGECONFIG[acme] = "ts_acme,ts_omit_acme"
PACKAGECONFIG[advertiseexitnode] = "ts_advertiseexitnode,ts_omit_advertiseexitnode"
PACKAGECONFIG[advertiseroutes] = "ts_advertiseroutes,ts_omit_advertiseroutes"
PACKAGECONFIG[appconnectors] = "ts_appconnectors,ts_omit_appconnectors"
PACKAGECONFIG[captiveportal] = "ts_captiveportal,ts_omit_captiveportal"
PACKAGECONFIG[clientupdate] = "ts_clientupdate,ts_omit_clientupdate"
PACKAGECONFIG[cloud] = "ts_cloud,ts_omit_cloud"
PACKAGECONFIG[dbus] = "ts_dbus,ts_omit_dbus"
PACKAGECONFIG[debug] = "ts_debug,ts_omit_debug"
PACKAGECONFIG[debugeventbus] = "ts_debugeventbus,ts_omit_debugeventbus"
PACKAGECONFIG[debugportmapper] = "ts_debugportmapper,ts_omit_debugportmapper"
PACKAGECONFIG[desktop_sessions] = "ts_desktop_sessions,ts_omit_desktop_sessions"
PACKAGECONFIG[doctor] = "ts_doctor,ts_omit_doctor"
PACKAGECONFIG[drive] = "ts_drive,ts_omit_drive"
PACKAGECONFIG[identityfederation] = "ts_identityfederation,ts_omit_identityfederation"
PACKAGECONFIG[iptables] = "ts_iptables,ts_omit_iptables"
PACKAGECONFIG[linuxdnsfight] = "ts_linuxdnsfight,ts_omit_linuxdnsfight"
PACKAGECONFIG[netlog] = "ts_netlog,ts_omit_netlog"
PACKAGECONFIG[networkmanager] = "ts_networkmanager,ts_omit_networkmanager"
PACKAGECONFIG[outboundproxy] = "ts_outboundproxy,ts_omit_outboundproxy"
PACKAGECONFIG[portlist] = "ts_portlist,ts_omit_portlist"
PACKAGECONFIG[posture] = "ts_posture,ts_omit_posture"
PACKAGECONFIG[qrcodes] = "ts_qrcodes,ts_omit_qrcodes"
PACKAGECONFIG[relayserver] = "ts_relayserver,ts_omit_relayserver"
PACKAGECONFIG[resolved] = "ts_resolved,ts_omit_resolved"
PACKAGECONFIG[sdnotify] = "ts_sdnotify,ts_omit_sdnotify"
PACKAGECONFIG[synology] = "ts_synology,ts_omit_synology"
PACKAGECONFIG[systray] = "ts_systray,ts_omit_systray"
PACKAGECONFIG[taildrop] = "ts_taildrop,ts_omit_taildrop"
PACKAGECONFIG[tpm] = "ts_tpm,ts_omit_tpm"
PACKAGECONFIG[usermetrics] = "ts_usermetrics,ts_omit_usermetrics"
PACKAGECONFIG[webclient] = "ts_webclient,ts_omit_webclient"

# Static internal link. -buildmode=pie forces cgo and a larger binary;
# the stock go class adds it for arm. Measured armv7 size is the
# non-PIE static build (see Development.md).
CGO_ENABLED = "0"
GO_LINUXLOADER = ""
# arm enables GO_DYNLINK, which adds -r .../linux_arm_dynlink to the
# linker command even when the binary is not linkshared.
GO_RPATH = ""
GOBUILDFLAGS:remove = "-buildmode=pie"
GO_EXTRA_LDFLAGS:append = " -s -w"
INSANE_SKIP:${PN} += "textrel"

# iptables cannot run: CONFIG_NETFILTER stays off. The init script logs
# in with --netfilter-mode=off.
RDEPENDS:${PN}d:remove = "iptables"
RDEPENDS:${PN}d:append = " tailscale"
RRECOMMENDS:${PN}d:remove = "kernel-module-wireguard kernel-module-tun kernel-module-xt-mark kernel-module-xt-tcpudp kernel-module-xt-masquerade"

# After Klipper (95) and Moonraker (96).
INITSCRIPT_PARAMS:${PN}d = "defaults 98 2"

CONFFILES:${PN}d += "${sysconfdir}/default/tailscaled"
