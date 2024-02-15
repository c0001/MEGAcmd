#!/usr/bin/env bash
set -e

srcname="${BASH_SOURCE[0]}"
while [ -h "$srcname" ]; do # resolve $srcname until the file is no longer a symlink
    srcdir="$( cd -P "$( dirname "$srcname" )" >/dev/null && pwd )"
    srcname="$(readlink "$srcname")"

    # if $srcname was a relative symlink, we need to resolve it relative
    # to the path where the symlink file was located
    [[ $srcname != /* ]] && srcname="$srcdir/$srcname"
done
srcdir="$( cd -P "$( dirname "$srcname" )" >/dev/null && pwd )"
origpwd="$(pwd)"

msg_help () {
    cat <<EOF
${srcname} [-h|--help] <installation destination> [--no-confirm]
EOF
}

msg_ok () {
    echo -e "\e[32mOK: ${*}\e[0m"
}

msg_err () {
    echo -e "\e[31mERR: ${*}\e[0m"
}

msg_warn () {
    echo -e "\e[33mWARN: ${*}\e[0m"
}

inst_dir="${1:?err: intall dir not specfied}"
install_dir="$(realpath "$inst_dir")"

if [[ $1 =~ ^(-h|--help)$ ]]; then
    msg_help ; exit 0
elif [[ ! -d "$inst_dir" ]]; then
    msg_err "installation destination not existed: '${inst_dir}'"
    exit 1
fi

cd "$srcdir"
git -C "$srcdir" submodule deinit --all -f
git -C "$srcdir" clean -xfd
git -C "$srcdir" submodule update --init

if [[ $2 != '--no-confirm' ]] ; then
    printf '\e[33mCONFIRMATION\e[0m: %s' \
           "\
install megacmd to dest? ('${inst_dir}') : "
    read -r cfm
    if [[ ! $cfm = 'yes' ]]; then
        msg_err "Abort!" ; exit 1
    fi
fi

./autogen.sh
./configure --prefix="${inst_dir}" --without-ffmpeg --without-freeimage
make -j"$(nproc)" && make install
msg_ok "All is done, install megacmd to '${inst_dir}' successfully."
