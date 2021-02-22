#!/usr/bin/env bash

declare -A REDIS=(
    ['PREFIX']=/usr/bin/redis
    ['fs.cfgPath']=/etc/redis/redis.conf
    ['fs.tmpDir']=/tmp/redis
    ['fs.srcDir']=/usr/src/redis
    ['fs.appDir']=/usr/lib/redis
    ['fs:meritokrat/data']=/var/lib/redis/data
)
REDIS['cli']="${REDIS[PREFIX]}-cli"
REDIS['server']="${REDIS[PREFIX]}-server"

log() {
    local -a echoOptions=(-e)
    local \
        textColor \
        level="$1" \
        message="$2"

    while true; do
        case "${level}" in
            err)
                textColor=31
                unset level
                ;;
            ok)
                textColor=32
                message="${2:-[OK]}"
                unset level
                ;;
            warn)
                textColor=33
                unset level
                ;;
            aspect)
                echoOptions+=(-n)
                level=warn
                ;;
            **) break ;;
        esac
    done

    eval "echo ${echoOptions[*]} \"\e[${textColor}m${message}\e[0m\""
}

redis.upStart() {
    nohup "${REDIS['server']}" "${REDIS['fs.cfgPath']}" >/dev/null 2>&1 &
}

redis.getInfo() {
    ${REDIS['cli']} info
}

redis.shutDown() {
    ${REDIS['cli']} shutdown
}

redis.makeInstall() {
    local \
        tmpDir="${REDIS['fs.tmpDir']}" \
        srcDir="${REDIS['fs.srcDir']}" \
        appDir="${REDIS['fs.appDir']}" \
        dataDir="${REDIS['fs:meritokrat/data']}" \
        cfgPath="${REDIS['fs.cfgPath']}" \
        pkgUrl="${PACKAGE_URL}" \
        pkgPath="${PACKAGE_PATH}"

    log aspect 'Preparing to download and install ... ' &&
        mkdir -p \
            "${tmpDir}" \
            "${srcDir}" \
            "${appDir}" &&
        log ok

    cd "${srcDir}"

    if [[ ! -f "${pkgPath}" ]]; then
        log aspect "Downloading ${pkgUrl} ..." &&
            curl -o "${pkgPath}" "${pkgUrl}" &&
            log ok
    fi

    log aspect "Unpacking ${pkgPath} ..." &&
        tar -xzvf "${pkgPath}" -C . --strip 1 &&
        log ok

    log aspect 'Compiling ...' &&
        make &&
        log ok

    log aspect 'Installing ...' &&
        mv ./{redis-server,redis-cli,redis-benchmark} "${appDir}/" &&
        ln -s "${appDir}"/* /usr/bin/
        # cp ./redis.conf "${cfgPath}"

    log aspect 'Configuring ...' &&
        cat <"${srcDir}/redis.conf" |
        sed "s/dir.*/dir ${dataDir//\//\\/}/g;w ${cfgPath}" &&
        log ok 'Redis has been successfully installed'

    #    log aspect 'Self-checking ...' && {
    #        redis.upStart
    #        redis.getInfo
    #        redis.shutDown
    #    } && log ok
}
