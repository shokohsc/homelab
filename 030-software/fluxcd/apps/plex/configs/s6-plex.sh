#!/usr/bin/with-contenv bash

echo "Starting Plex Media Server."
home="$(echo ~plex)"
export PLEX_MEDIA_SERVER_APPLICATION_SUPPORT_DIR="${PLEX_MEDIA_SERVER_APPLICATION_SUPPORT_DIR:-${home}/Library/Application Support}"
export PLEX_MEDIA_SERVER_HOME=/usr/lib/plexmediaserver
export PLEX_MEDIA_SERVER_MAX_PLUGIN_PROCS=6
export PLEX_MEDIA_SERVER_INFO_VENDOR=Docker
export PLEX_MEDIA_SERVER_INFO_DEVICE="Docker Container"
export PLEX_MEDIA_SERVER_INFO_MODEL=$(uname -m)
export PLEX_MEDIA_SERVER_INFO_PLATFORM_VERSION=$(uname -r)

if [ ! -d "${PLEX_MEDIA_SERVER_APPLICATION_SUPPORT_DIR}" ]; then
    /bin/mkdir -p "${PLEX_MEDIA_SERVER_APPLICATION_SUPPORT_DIR}"
    chown plex:plex "${PLEX_MEDIA_SERVER_APPLICATION_SUPPORT_DIR}"
fi

echo "Setup Plex Crack"
if [[ ! -e "/config/patchelf" ]]; then
    apt update && apt install -y patchelf
    cp /usr/bin/patchelf /config/patchelf
fi
if [[ ! -e "/config/plexmediaserver_crack.so" ]]; then
    curl -o /config/plexmediaserver_crack.so https://gitgud.io/yuv420p10le/plexmediaserver_crack/-/raw/master/binaries/plexmediaserver_crack.so?ref_type=heads&inline=false
fi
if [[ ! -e "${PLEX_MEDIA_SERVER_HOME}/lib/plexmediaserver_crack.so" ]]; then
    ln -s /config/plexmediaserver_crack.so ${PLEX_MEDIA_SERVER_HOME}/lib/plexmediaserver_crack.so
fi

/config/patchelf --remove-needed /config/plexmediaserver_crack.so ${PLEX_MEDIA_SERVER_HOME}/lib/libsoci_core.so
/config/patchelf --add-needed /config/plexmediaserver_crack.so ${PLEX_MEDIA_SERVER_HOME}/lib/libsoci_core.so


exec s6-setuidgid plex ${PLEX_MEDIA_SERVER_HOME}/Plex\ Media\ Server