#!/bin/bash

savedir=/data/disk3/timelapse
source=/data/disk2usb/videos/uUYr4S55gJ

if [ "$1" == "--fps" ]; then
	re='^[0-9]+$'
	if [[ $2 =~ $re ]]; then
		fps=$2
	else
		echo "$2 is a incorrect fps value"
		exit 0
	fi
else
	fps=30
fi

for i in `find $source -type d -name "*_timelapse" | sort`
	do
	result="${i%"${i##*[!/]}"}"
	result="${result##*/}"
	result=${result:-/}
	cam=$(echo $result | sed 's/^\(.*\)\_timelapse/\1/g')

        find $i -type f -size +10M -name "*.jpg" -exec rm -f {} \;

	n=0
	t=$(find $i -type f -name "*.jpg" | wc -l)
	if [[ "$t" -gt "0" ]]
	then
		[[ -d "/tmp/$cam" ]] || mkdir /tmp/$cam
                first=$(ls -1 $i | grep "[0-9]*\-[0-9]*\-[0-9]*" | head -1)
                last=$(ls -t1 $i | grep "[0-9]*\-[0-9]*\-[0-9]*" | head -1)
		output=${cam}_${first}-${last}_${fps}fps_timelapse.mp4
	        printf "\nTimelapse for $cam between $first and $last\n--------------------------------\n"
                for j in `find $i -type f -name "*.jpg" | sort`
                        do
				cp $j /tmp/$cam
                        ((n++))
                        tab=$(printf "\t")
                        echo -ne "Copy files to temp dir:${tab} $n of $t"\\r
			mkdir -p $savedir/.backup/${cam}_${first}-${last} && mv $j $savedir/.backup/${cam}_${first}-${last}
                done
		for f in /tmp/$cam
			do
			if [ -f $savedir/$output ]
				then
				echo "$savedir/$output already exist..."
				break
			else
				printf "\nStart generate timelapse framerate $fps fps...\n"
				pv $f/*.jpg | ffmpeg -f image2pipe -framerate ${fps} -i - -c:v libx264 -pix_fmt yuv420p ${savedir}/${output} >/dev/null 2>&1
				[[ $? -eq 0 ]] || exit $?
			fi
		done
		echo
		printf "Done! Saved as $savedir/$output\n"
		rm -rf /tmp/$cam
		find $i -type d -empty -delete
	fi
done

#set +x

exit 0
