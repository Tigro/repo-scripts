#!/bin/sh

usage()
{
echo "	russianfedora-repos <repo> [-f]"
echo "	    repo:"
echo "		  -f for rpmfusion-free"
echo "		  -n for rpmfusion-nonfree"
echo "		  -fu for rpmfusion-free-updates"
echo "		  -nu for rpmfusion-nonfree-updates"
echo "		  -u for updates"
echo "		  -ut for updates-testing"
echo "		  -t for tigro"
echo "		  -e for russianfedora"
echo "		  -a for all"
exit 1
}

if [ "x$1" == "x" ]; then
    usage
fi

# Detect version of last kernel
#KPATH="/mirror/fedora/linux/development/14/i386/os/Packages/"
KPATH="/mirror/fedora/linux/updates/14/i386/"
KVER=$(rpm -qp $KPATH/kernel-2.6*i686* --qf "%{version}-%{release}")


case "$1" in
    -f)
	REPOS="rpmfusion-free"
	;;
    -n)
        REPOS="rpmfusion-nonfree"
        ;;
    -fu)
        REPOS="rpmfusion-free-updates"
        ;;
    -nu)
        REPOS="rpmfusion-nonfree-updates"
        ;;
    -u)
	REPOS="russianfedora-updates"
	;;
    -ut)
	REPOS="russianfedora-updates-testing"
    ;;
    -t)
	REPOS="tigro"
	;;
    -e)
	REPOS="russianfedora"
	;;
    -a)
	REPOS="rpmfusion-free rpmfusion-free-updates rpmfusion-nonfree rpmfusion-nonfree-updates russianfedora russianfedora-updates"
	;;
    *)
	echo "Unknown repo. Abort..."
	exit 1
	;;
esac

TEDORAVER="14"

ARCH="i386 x86_64"
BUILDPATTH="/mirror/fedora/russianfedora/build/14"

cd $BUILDPATTH

for repo in $REPOS; do
    for arch in $ARCH; do
        case "$repo" in
	    rpmfusion-free)
		DPATH="/mirror/fedora/rpmfusion/free/fedora/releases/$TEDORAVER/Everything/$arch/os/"
		;;
            rpmfusion-nonfree)
                DPATH="/mirror/fedora/rpmfusion/nonfree/fedora/releases/$TEDORAVER/Everything/$arch/os/"
                ;;
            rpmfusion-free-updates)
                DPATH="/mirror/fedora/rpmfusion/free/fedora/updates/$TEDORAVER/$arch/"
                ;;
            rpmfusion-nonfree-updates)
                DPATH="/mirror/fedora/rpmfusion/nonfree/fedora/updates/$TEDORAVER/$arch/"
                ;;
	    russianfedora-updates)
		DPATH="/mirror/fedora/linux/updates/$TEDORAVER/$arch"
		;;
            russianfedora-updates-testing)
                DPATH="/mirror/fedora/linux/updates/testing/$TEDORAVER/$arch"
                ;;
	    russianfedora)
		DPATH="/mirror/fedora/linux/releases/$TEDORAVER/Everything/$arch/os/Packages/"
		;;
	    *)
		exit 0
		;;
	esac

	find $repo/$arch/ -name "*.rpm" | xargs rm -f

	if [ "$repo" == "rpmfusion-nonfree" -o "$repo" == "rpmfusion-free" ]; then
            EXCLUDERPMS=`/usr/local/bin/repomanage -o $DPATH | sed "s!$DPATH! -x !g"`
            EXCLUDEMODULES=`ls $DPATH/kmod*2.6.??*rpm | grep -v $KVER | sed "s!$DPATH/! -x !g"`
            EXCLUDERPMS="$EXCLUDERPMS $EXCLUDEMODULES -x kmod-* -x akmod-*"
        elif [ "$repo" == "rpmfusion-nonfree-updates" -o "$repo" == "rpmfusion-free-updates" ]; then
            EXCLUDERPMS=`/usr/local/bin/repomanage -o $DPATH | sed "s!$DPATH! -x !g"`
            EXCLUDEMODULES=`ls $DPATH/kmod*2.6.??*rpm | grep -v $KVER | sed "s!$DPATH/! -x !g"`
            EXCLUDERPMS="$EXCLUDERPMS $EXCLUDEMODULES"
	fi

	if [ "$repo" == "russianfedora" -o "$repo" == "russianfedora-updates" -o "$repo" == "russianfedora-updates-testing" ]; then
            EXCLUDERPMS=" -x fedora-release-* -x olpc-logos* -x generic-* -x anaconda-1*"
	fi

        if [ "$BUILDPATTH/$repo/$arch/$repo.xml" -nt "$BUILDPATTH/$repo/$arch/repodata/$repo.xml" ]; then
            unset $PARAM
        elif [ "$2" == "-f" ]; then
            unset $PARAM
        else
            PARAM="-C"
        fi

        URLPATH=`echo $DPATH | sed 's!/mirror!http://mirror.yandex.ru!g'`	

        #/usr/sbin/chroot /root/fedora-chroot/ /usr/bin/createrepo  $PARAM $EXCLUDERPMS -x *debuginfo* -d --update -g $BUILDPATTH/$repo/$arch/$repo.xml -o $BUILDPATTH/$repo/$arch/ \
        /usr/sbin/chroot /root/fedora-chroot/ /usr/bin/createrepo  $PARAM $EXCLUDERPMS -x *debuginfo* -d --update -g /root/comps/14/$repo.xml -o $BUILDPATTH/$repo/$arch/ -u $URLPATH $DPATH
    done
done
cd -

echo "$(date -u)" > /mirror/fedora/russianfedora/.mirror.yandex.ru
