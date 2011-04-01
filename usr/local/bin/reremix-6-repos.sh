#!/bin/sh

usage()
{
echo "	reremix-repos <repo> [-f]"
echo "	    repo:"
echo "		  -ts for atrpms stable"
echo "		  -tb for atrpms bleeding"
echo "		  -d  for dag"
echo "		  -f  for rpmfusion-free"
echo "		  -n  for rpmfusion-nonfree"
echo "		  -fu for rpmfusion-free-updates"
echo "		  -nu for rpmfusion-nonfree-updates"
echo "		  -u  for reremix-updates"
echo "		  -ut for reremix-updates-testing"
echo "		  -e  for reremix"
echo "		  -a  for all"
exit 1
}

if [ "x$1" == "x" ]; then
    usage
fi

TEDORAVER="6"

# Detect version of last kernel
KPATH="/mirror/scientificlinux/${TEDORAVER}x/x86_64/updates/security"
# CHECK /USR/LOCAL/BIN/SORT
KVER=$(rpm -qp $KPATH/kernel-2.6*i686* --qf "%{version}-%{release}\n" | /usr/local/bin/sort -V | tail -n1)

case "$1" in
    -ts)
	REPOS="atrpms-stable"
	;;
    -tb)
        REPOS="atrpms-bleeding"
        ;;
    -d)
        REPOS="dag"
        ;;
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
	REPOS="reremix-updates"
	;;
    -e)
	REPOS="reremix"
	;;
    *)
	echo "Unknown repo. Abort..."
	exit 1
	;;
esac


ARCH="i386 x86_64"
BUILDPATTH="/mirror/fedora/russianfedora/build/$TEDORAVER"

cd $BUILDPATTH

for repo in $REPOS; do
    for arch in $ARCH; do
        case "$repo" in
	    atrpms-stable)
		DPATH="/mirror/fedora/atrpms/el$TEDORAVER-$arch/atrpms/stable/"
		;;
            atrpms-bleeding)
                DPATH="/mirror/fedora/atrpms/el$TEDORAVER-$arch/atrpms/bleeding/"
                ;;
	    dag)
		DPATH="/mirror/fedora/dag/redhat/el$TEDORAVER/en/$arch/dag/"
		;;
	    rpmfusion-free)
		DPATH="/mirror/fedora/rpmfusion/free/epel/releases/$TEDORAVER/Everything/$arch/os/"
		;;
            rpmfusion-nonfree)
                DPATH="/mirror/fedora/rpmfusion/nonfree/epel/releases/$TEDORAVER/Everything/$arch/os/"
                ;;
            rpmfusion-free-updates)
                DPATH="/mirror/fedora/rpmfusion/free/epel/updates/$TEDORAVER/$arch/"
                ;;
            rpmfusion-nonfree-updates)
                DPATH="/mirror/fedora/rpmfusion/nonfree/epel/updates/$TEDORAVER/$arch/"
                ;;
	    reremix-updates)
		DPATH="/mirror/scientificlinux/${TEDORAVER}x/$arch/updates/security/"
		;;
	    reremix)
		DPATH="/mirror/scientificlinux/${TEDORAVER}x/$arch/os/"
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
	elif [ "$repo" == "reremix-updates" ]; then
            EXCLUDERPMS=`/usr/local/bin/repomanage -o $DPATH | sed "s!$DPATH! -x !g"`
        fi

	if [ "$repo" == "reremix" -o "$repo" == "reremix-updates" ]; then
            EXCLUDERPMS="$EXCLUDERPMS -x fedora-release-* -x olpc-logos* -x generic-* -x anaconda-1*"
	fi

        if [ "$BUILDPATTH/$repo/$arch/$repo.xml" -nt "$BUILDPATTH/$repo/$arch/repodata/$repo.xml" ]; then
            unset $PARAM
        elif [ "$2" == "-f" ]; then
            unset $PARAM
        else
            PARAM="-C"
        fi

        URLPATH=`echo $DPATH | sed 's!/mirror!http://mirror.yandex.ru!g'`

        /usr/sbin/chroot /root/fedora-chroot/ /usr/bin/createrepo $PARAM $EXCLUDERPMS \
        	-x *debuginfo* -d --update -g /root/comps/$TEDORAVER/$repo.xml \
		-o $BUILDPATTH/$repo/$arch/ -u $URLPATH $DPATH
    done
done
cd -

echo "$(date -u)" > /mirror/fedora/russianfedora/.mirror.yandex.ru
