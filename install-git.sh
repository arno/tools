#!/bin/sh
#
# Arnaud Guignard - 2008
#
# usage: install-git.sh GIT_VERSION
#
# dependencies: curl gpg stow sudo

GIT_DL=$HOME/download/git
GIT_HTMLDOCS=$HOME/Documents/git-htmldocs
GIT_WWW=http://kernel.org/pub/software/scm/git/

tmpdir=$(mktemp -t -d install-git-XXXXXXXXXX)

die() {
    echo >&2 "$@"
    [ -d $tmpdir ] && (rm -rf $tmpdir >/dev/null 2>&1 || sudo rm -rf $tmpdir)
    exit 1
}

[ $# -ne 1 ] && die "usage: $(basename $0) GIT_VERSION"

version=$1

[ -d $GIT_DL ] || mkdir -p $GIT_DL

### 1. download and gpg verify archives
for t in git git-manpages git-htmldocs; do
    fn=$t-$version.tar.bz2
    f=$GIT_DL/$fn
    if [ ! -f $f ]; then
        echo "[+] downloading $fn"
        curl -s -S -o $f $GIT_WWW/$fn || die
        echo "[+] downloading $fn.sign"
        curl -s -S -o $f.sign $GIT_WWW/$fn.sign || die
    fi
    gpg --verify $f.sign $f >/dev/null 2>&1 || die "[-] bad signature for $fn"
    echo "[+] good signature for $fn"
done

### 2. make git
echo "[+] building git..."
tar -C $tmpdir -xjf $GIT_DL/git-$version.tar.bz2
cd $tmpdir/git-$version
make prefix=/usr/local all >/dev/null 2>&1 || die "[-] error compiling git"

### 3. install git

## 3.1 in a temp dir
echo "[+] installing git..."
destdir=$tmpdir/gitstow
sudo DESTDIR=$destdir make prefix=/usr/local install >/dev/null || \
    die "[-] error installing git"
find $destdir -name "perllocal.pod" | sudo xargs rm -f 

## 3.2 man pages
sudo mkdir $destdir/usr/local/man
sudo tar -C $destdir/usr/local/man -xjf $GIT_DL/git-manpages-$version.tar.bz2
sudo chown -R root:root $destdir/usr/local/man

## 3.3 move to stow dir
sudo mv $destdir/usr/local /usr/local/stow/git-$version
sudo rm -rf $destdir $TMP_DIR/git-$version

## 3.4 unstow previous version
cd /usr/local/stow
if [ -e /usr/local/bin/git ]; then
    [ -L /usr/local/bin/git ] || die "[-] git is not installed with stow"
    prev_git=$(readlink /usr/local/bin/git | cut -d '/' -f 3)
    echo "[+] unstowing $prev_git"
    sudo stow -D $prev_git >/dev/null || \
        die "[-] error unstowing previous git version"
fi

## 3.5 stow new version
echo "[+] stowing git $version"
sudo stow git-$version >/dev/null || die "[-] error stowing git"

rm -rf $tempdir

# vim:et:sw=4:ts=4:
