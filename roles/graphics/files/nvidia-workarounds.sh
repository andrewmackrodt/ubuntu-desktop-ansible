nvidia_drv_video_path="/usr/lib/x86_64-linux-gnu/dri/nvidia_drv_video.so"

# newline separated list of graphics devices
devices=$( switcherooctl \
    | perl -0777 -pe 's#\n\n#\0#g' \
    | tr $'\n' ' ' \
    | perl -pe 's#\0#\n#g' \
    | sed -E 's#\s+# #g' \
    | sed -E 's# ([A-Za-z]+): ?#|\1:#g'
)

# nvidia specific behaviours
if echo "$devices" | grep -qi 'Name:NVIDIA'; then
    if ( echo "$devices" | grep -i 'Default:yes' | grep -qi 'Name:NVIDIA' ) \
        || ( vainfo 2>/dev/null 2>/dev/null | grep -qi 'NVDEC' ) \
    ; then
        # export vaapi environment variables if default gpu and nvidia_drv_video_path exists
        if [ -f "$nvidia_drv_video_path" ]; then
            export LIBVA_DRIVER_NAME=nvidia
            export MOZ_DISABLE_RDD_SANDBOX=1
            export NVD_BACKEND=direct
        fi
    elif [ "${XDG_SESSION_TYPE:-}" = "wayland" ]; then
        # force use of mesa egl if wayland and not the default gpu fixes various app crashes
        # and intel vaapi support under firefox
        # https://github.com/NVIDIA/egl-wayland/issues/41
        export __EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/50_mesa.json
    fi
fi
