mkdir -p build
APP=Floaty
APP_DEST=build/$APP
clang $APP/*.m -o $APP_DEST -fobjc-arc -fobjc-link-runtime -framework Cocoa -framework WebKit -O3 -g0 && ./$APP_DEST
