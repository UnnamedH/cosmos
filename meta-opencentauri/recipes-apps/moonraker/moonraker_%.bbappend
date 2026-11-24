# Tailscale peers talk to Moonraker from 100.64/10 and fd7a:115c:a1e0::/48.
# Those ranges are not trusted unless this image was built with the feature,
# so a stock image does not widen the printer's API.

do_install:append() {
    if ${@bb.utils.contains('DISTRO_FEATURES', 'tailscale', 'true', 'false', d)}; then
        sed -i '/::1\/128/a\    100.64.0.0/10\
    fd7a:115c:a1e0::/48' \
            ${D}${sysconfdir}/klipper/config/moonraker-readonly/moonraker.conf
        printf 'tailscaled\n' >> ${D}${sysconfdir}/klipper/moonraker.asvc
    fi
}
