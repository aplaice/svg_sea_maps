#!/bin/bash

TEST_FILES=(png/ug-map-adriatic_sea.png
png/ug-map-aral_sea.png
png/ug-map-celtic_sea.png
png/150/ug-map-coral_sea.png
png/150/ug-map-bering_strait.png
png/150/ug-map-banda_sea.png)

for test_file in "${TEST_FILES[@]}"
do
    make "$test_file"
done

# It's neater if the potential message that the files differ is not
# lost in the make messages.
# I don't however want to supress the make output, just in case.
for test_file in "${TEST_FILES[@]}"
do
    diff "$test_file" tests/samples/
done

if [ x"$1" == xdisplay_diff ]
then
    for test_file in "${TEST_FILES[@]}"
    do
	f="$(basename "$test_file")"
	old=tests/samples/"$f"
	new="$test_file"
	comparison="/tmp/$f"
	#    compare -compose src "$old" "$new" png:- | montage -geometry 400x "$old" "$new" png:- "$comparison"
	compare -compose src "$old" "$new" png:- | montage -geometry 400x+2+2 "$old" "$new" png:- png:- | display -
    done

    # for test_file in "${TEST_FILES[@]}"
    # do
    #     f="$(basename "$test_file")"
    #     comparison="/tmp/$f"
    #     display "$comparison"
    #     rm "$comparison"
    # done
fi
