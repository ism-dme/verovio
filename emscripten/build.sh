#/bin/bash

function print_help {
	 echo "Usage:
-l		Light version without ASM and no increased memory allocation
-v N		Version number (e.g., 1.0.0); no number by default" >&2 ; 
 } 

VEROVIO_ROOT=../
VEROVIO_INCLUDE=../include/vrv
EMCC=`which emcc`

if [ ! -d build ]; then mkdir build; fi

if [ ! -d data ]; then mkdir data; fi
	
# default is with ASM an large file support
# memory is increased (TOTAL_MEMORY and TOTAL_STACK) for processing large files (tested up to 7MB)
# we can disable this for a light version 	
ASM="\
	-s ASM_JS=1 \
	-s OUTLINING_LIMIT=160000 \
	-s TOTAL_MEMORY=256*1024*1024 \
	-s TOTAL_STACK=16*1024*1024"
ASM_NAME=""

# default is master (no version)
VERSION=""
VERSION_NAME=""
	
while getopts "lv:h" opt; do
  	case $opt in
		l)
 	   		echo "light version (-l)"
	  	  	ASM="-s ASM_JS=0"
			ASM_NAME="-light"
			;;
		v)
 	   		echo "version (-v) $OPTARG"
			VERSION="$OPTARG"
			VERSION_NAME="-$VERSION"
			;;
		h)
 	   		print_help
			exit 2
			;;
		\?)
			print_help
			exit 2
			;;
	esac
done

FILENAME="verovio-toolkit$ASM_NAME$VERSION_NAME.js"

echo "Sync svg resources"
cp -r ../data/svg data/

echo "Compliling"

python $EMCC --closure 1 -O2 \
	-I./lib/jsonxx \
	-I$VEROVIO_INCLUDE \
	-I$VEROVIO_ROOT/tinyxml \
	-DUSE_EMSCRIPTEN \
	$ASM \
	./emscripten_main.cpp \
	$VEROVIO_ROOT/src/vrv.cpp \
	$VEROVIO_ROOT/src/aligner.cpp \
	$VEROVIO_ROOT/src/app.cpp \
	$VEROVIO_ROOT/src/barline.cpp \
	$VEROVIO_ROOT/src/measure.cpp \
	$VEROVIO_ROOT/src/bboxdevicecontext.cpp \
	$VEROVIO_ROOT/src/beam.cpp \
	$VEROVIO_ROOT/src/clef.cpp \
	$VEROVIO_ROOT/src/interfacecontroller.cpp \
	$VEROVIO_ROOT/src/devicecontext.cpp \
	$VEROVIO_ROOT/src/doc.cpp \
	$VEROVIO_ROOT/src/durationinterface.cpp \
	$VEROVIO_ROOT/src/io.cpp \
	$VEROVIO_ROOT/src/iodarms.cpp \
	$VEROVIO_ROOT/src/iomei.cpp \
	$VEROVIO_ROOT/src/iomusxml.cpp \
	$VEROVIO_ROOT/src/iopae.cpp \
	$VEROVIO_ROOT/src/keysig.cpp \
	$VEROVIO_ROOT/src/layer.cpp \
	$VEROVIO_ROOT/src/layerelement.cpp \
	$VEROVIO_ROOT/src/leipzigbbox.cpp \
	$VEROVIO_ROOT/src/mensur.cpp \
	$VEROVIO_ROOT/src/mrest.cpp \
	$VEROVIO_ROOT/src/multirest.cpp \
	$VEROVIO_ROOT/src/note.cpp \
	$VEROVIO_ROOT/src/object.cpp \
	$VEROVIO_ROOT/src/page.cpp \
	$VEROVIO_ROOT/src/pitchinterface.cpp \
	$VEROVIO_ROOT/src/positioninterface.cpp \
	$VEROVIO_ROOT/src/view.cpp \
	$VEROVIO_ROOT/src/view_beam.cpp \
	$VEROVIO_ROOT/src/view_element.cpp \
	$VEROVIO_ROOT/src/view_graph.cpp \
	$VEROVIO_ROOT/src/view_page.cpp \
	$VEROVIO_ROOT/src/view_tuplet.cpp \
	$VEROVIO_ROOT/src/rest.cpp \
	$VEROVIO_ROOT/src/scoredef.cpp \
	$VEROVIO_ROOT/src/slur.cpp \
	$VEROVIO_ROOT/src/staff.cpp \
	$VEROVIO_ROOT/src/svgdevicecontext.cpp \
	$VEROVIO_ROOT/src/symbol.cpp \
	$VEROVIO_ROOT/src/system.cpp \
	$VEROVIO_ROOT/src/tie.cpp \
	$VEROVIO_ROOT/src/tuplet.cpp \
	$VEROVIO_ROOT/src/pugixml.cpp \
	lib/jsonxx/jsonxx.cc \
	--embed-file data/svg/ \
	-s EXPORTED_FUNCTIONS="[\
		'_vrvInterfaceController_constructor',\
		'_vrvInterfaceController_destructor',\
		'_vrvInterfaceController_getLog',\
		'_vrvInterfaceController_getPageCount',\
		'_vrv_InterfaceController_loadData',\
		'_vrvInterfaceController_renderData',\
		'_vrvInterfaceController_renderPage',\
		'_vrvInterfaceController_setOptions']" \
    -o build/verovio.js

if [ $? -eq 0 ]; then 
	echo "Done."
	# the wrapper is necessary with closure 1 for avoiding to conflict with globals
	cat verovio-wrapper-start.js build/verovio.js verovio-wrapper-end.js verovio-proxy.js > "build/$FILENAME"
	# all good
	echo "build/$FILENAME written"
	# create also a zip file if version name is given
	if [ -n "$VERSION_NAME" ]; then
		cd "build"
		zip "$FILENAME.zip" "$FILENAME"
		cd ..
		echo "build/$FILENAME.zip written"
	fi
fi