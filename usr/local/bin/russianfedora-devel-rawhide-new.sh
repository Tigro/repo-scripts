#!/bin/sh

usage()
{
echo "	russianfedora-repos <repo> [-f]"
echo "	    repo:"
echo "		  -f for rpmfusion-free"
echo "		  -n for rpmfusion-nonfree"
echo "		  -e for russianfedora"
echo "		  -a for all"
exit 1
}

if [ "x$1" == "x" ]; then
    usage
fi

# Detect version of last kernel
KPATH="/mirror/fedora/linux/development/rawhide/i386/os/Packages/"
KVER=$(rpm -qp $KPATH/kernel-2.6*i686* --qf "%{version}-%{release}" )


case "$1" in
    -f)
	REPOS="rpmfusion-free"
	;;
    -n)
    	REPOS="rpmfusion-nonfree"
    	;;
    -e)
	REPOS="russianfedora"
	;;
    -a)
	REPOS="rpmfusion-free rpmfusion-nonfree russianfedora"
	;;
    *)
	echo "Unknown repo. Abort..."
	exit 1
	;;
esac

ARCH="i386 x86_64"
BUILDPATTH="/mirror/fedora/russianfedora/build/development/rawhide/"

cd $BUILDPATTH
for repo in $REPOS; do
    for arch in $ARCH; do
        case "$repo" in
	    	rpmfusion-free)
		    DPATH="/mirror/fedora/rpmfusion/free/fedora/development/$arch/os/"
		    ;;
		rpmfusion-nonfree)
	            DPATH="/mirror/fedora/rpmfusion/nonfree/fedora/development/$arch/os/"
                    ;;
	    	russianfedora)
 		    DPATH="/mirror/fedora/linux/development/rawhide/$arch/os/Packages/"
		    ;;
	    	*)
		    exit 0
		    ;;
		esac

		find $repo/$arch/ -name "*.rpm" | xargs rm -f

		if [ "$repo" == "rpmfusion-free" -o "$repo" == "rpmfusion-nonfree" ]; then
		    EXCLUDERPMS=`/usr/local/bin/repomanage -o $DPATH | sed "s!$DPATH! -x !g"`
		    EXCLUDEMODULES=`ls $DPATH/kmod*2.6*rpm | grep -v $KVER | sed "s!$DPATH! -x !g"`
		    EXCLUDERPMS="$EXCLUDERPMS $EXCLUDEMODULES"
		fi

	        if [ "$repo" == "russianfedora" ]; then
		    EXCLUDERPMS=" -x fedora-release-* -x olpc-logos* -x generic-*"
		fi

                if [ "$BUILDPATTH/$repo/$arch/$repo.xml" -nt "$BUILDPATTH/$repo/$arch/repodata/$repo.xml" ]; then
                    unset $PARAM
	        elif [ "$2" == "-f" ]; then
	            unset $PARAM
                else
		    PARAM="-C"
                fi

		URLPATH=`echo $DPATH | sed 's!/mirror!http://mirror.yandex.ru!g'`

		/usr/sbin/chroot /root/fedora-chroot/ /usr/bin/createrepo  $PARAM $EXCLUDERPMS -x *debuginfo* -d --update -g /root/comps/rawhide/$repo.xml -o $BUILDPATTH/$repo/$arch/ \
                    -u $URLPATH $DPATH
    done
done
cd -

echo "$(date -u)" > /mirror/fedora/russianfedora/.mirror.yandex.ru
