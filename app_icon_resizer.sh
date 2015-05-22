#!/bin/bash

######## APP ICON RESIZER script ########
##### Created in May 2015 at Inaka ######


### SYSTEM REQUIREMENTS ###
# * jq - For JSON parsing (if you don't have it, it will be auto-downloaded)
# * imageclick - For images resizing (no auto-download support for this for now)


### PROJECT REQUIREMENTS ###
# * The original icon (must be 1024 x 1024 pixels size) of the app named 'AppIcon.png' and inside the project folder.
# * An 'Images.xcassets' folder (should come by default with the project).
# * An 'AppIcon.imageset' folder inside the 'Images.xcassets' folder (should come by default with the project).


### USAGE ###
# * Add this script under a Run Script tab under your Build Phases tab of the application target in question, setting the text "/bin/bash" in the script's text field.
# * Add the slots for the icons that you need in your AppIcon imageset.
# * Run!
# * The script will generate all the required icons based on the original one and will fill all the slots in the AppIcon image set automatically.


### THE SCRIPT ITSELF ###

#Install jq for JSON parsing (if not present)
if [ ! -e /usr/local/bin/jq ]
then
echo "Installing jq for JSON parsing..."
curl -O "http://assets.xtremelabs.com/xlt-scripts-bash/jq" 1>/dev/null 2>/dev/null
sudo cp jq /usr/local/bin
sudo chmod ugo+x /usr/local/bin/jq
fi

# Check if app icon original file exists
FILE=`find ${SRCROOT} -name "AppIcon.png"`
if [ ! -f $FILE ];
then
echo "(!) File '$FILE' not found."
exit 1
fi

# Check if file is an image
IMG_CHARS=$(identify "${FILE}" 2> /dev/null)
if [ $? -eq 1 ]
then
echo "(!) '${FILE}' is not a proper image file."
exit 1
fi

# Check if image dimensions are correct
IMG_CHARS=$(echo "${IMG_CHARS}" | sed -n 's/\(^.*\)\ \([0-9]*\)x\([0-9]*\)\ \(.*$\)/\2 \3/p')
WIDTH=$(echo "${IMG_CHARS}" | awk '{print $1}')
HEIGHT=$(echo "${IMG_CHARS}" | awk '{print $2}')
if [ ! ${WIDTH} -eq 1024 ] || [ ! ${HEIGHT} -eq 1024 ]
then
echo "(!) Couldn't generate icons."
echo "'${FILE}' should be 1024 x 1024 pixels."
exit 1
fi

# Create enclosing folder if it doesn't exist
APPICONSETPATH=`find ${SRCROOT} -type d -name "AppIcon.appiconset"`
if [[ ! -d ${APPICONSETPATH} ]]
then
mkdir ${APPICONSETPATH}
fi

# Target Contents.json file from AppIcon set
INPUTJSONPATH=`find ${APPICONSETPATH} -name "Contents.json"`

# Parse JSON file to know what sizes are needed
SIZES=($(/usr/local/bin/jq -r 'def parse: .|split("x")[0]; def calculateSize: (.size|parse|tonumber) * (.scale|parse|tonumber); .images | map(select(has("size") and has("scale"))) | map(.|calculateSize) | unique | .[]' ${INPUTJSONPATH}))

# Generate a new Contents.json file based on the new icons
NEWJSONPATH="${INPUTJSONPATH}_copy"
cat ${INPUTJSONPATH} | /usr/local/bin/jq 'def parse: .|split("x")[0]; def calculateSize: (.size|parse|tonumber) * (.scale|parse|tonumber); def imageName:("AppIcon_"+(.|calculateSize|tostring)+".png"); .images | map(select(has("size") and has("scale") and has ("idiom"))) | map({"idiom": .idiom, "size": .size, "scale": .scale, "filename": (.|imageName)}) | {"images": ., "info":{"version": 1, "author": "xcode"}}' > ${NEWJSONPATH}
rm ${INPUTJSONPATH}
cp ${NEWJSONPATH} ${INPUTJSONPATH}
rm ${NEWJSONPATH}

# Generate icons
echo "Generating app icons..."
for i in "${SIZES[@]}"
do
:
/usr/local/bin/convert ${FILE} -resize ${i}x${i} ${APPICONSETPATH}"/AppIcon_"${i}".png"
echo -e "\xE2\x9C\x93 Created ${i} x ${i} icon"
done

# We're happy here
echo "Done! :)"