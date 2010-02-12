#!/bin/bash
#
# Arnaud Guignard - 2008-2009
#
# usage: install-git.sh GIT_VERSION
#
# dependencies: curl gpg stow sudo [xmlstarlet]

GIT_DL=$HOME/download/git
GIT_HTMLDOCS=$HOME/Documents/git-htmldocs
GIT_WWW=http://www.eu.kernel.org/pub/software/scm/git/

XMLSTARLET=$(which xmlstarlet)
[ -z "$XMLSTARLET" ] && XMLSTARLET=$(which xml)

die() {
    echo >&2 "$@"
    [ -d $tmpdir ] && (rm -rf $tmpdir >/dev/null 2>&1 || sudo rm -rf $tmpdir)
    exit 1
}

usage() {
    die "usage: $(basename $1) [-d] [-n] GIT_VERSION

  -d    download only
  -n    do not verify signatures

If xmlstarlet [http://xmlstar.sourceforge.net/] is installed GIT_VERSION can be
omitted and the current git will be downloaded."
}

download_only=
verify_signature=1

### 0. parse command line arguments
while getopts ":dn" opt; do
    case $opt in
        d) download_only=1 ;;
        n) verify_signature= ;;
        \?) usage $0 ;;
    esac
done

shift $((OPTIND - 1))

version=$1
if [ -z "$version" ] && [ -n "$XMLSTARLET" ]; then
    version=$(curl -s -S -L http://git-scm.com/ | \
              xmlstarlet sel --html -T -t -m "//*[@id='ver']" -v '.' | \
              cut -b2-)
fi

[ -z $version ] && usage $0

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
    if [ -n "$verify_signature" ]; then
        gpg --verify $f.sign $f >/dev/null 2>&1 || die "[-] bad signature for $fn"
        echo "[+] good signature for $fn"
    fi
done

[ -n "$download_only" ] && exit 0

### 2. make git
echo "[+] building git..."
tmpdir=$(mktemp -t -d install-git-XXXXXXXXXX)
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
sudo tar -C $destdir/usr/local/share/man -xjf $GIT_DL/git-manpages-$version.tar.bz2
sudo chown -R root:root $destdir/usr/local/share/man

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

rm -rf $tmpdir

# vim:et:sw=4:ts=4:
