
flutter clean
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs



flutter gen-l10n

dart run flutter_native_splash:create


flutter pub run flutter_launcher_icons


flutter pub run rename setAppName --value "HyperZ"

flutter pub run rename setAppName --value "HyperZ" --targets ios,android,macos,windows    

flutter build web --release 

Lay key
Get-Content C:\\Users\\daota\\.ssh\\pycharm_deploy_key.pub

Bo len ggcloud
nano ~/.ssh/authorized_keys



CORS Konga:

headers:
Content-Type
Authorization
Access-Control-Request-Method
Accept
Origin
Access-Control-Request-Headers
access-control-allow-origin
x-api-key

exposed headers:
Content-Length
Content-Type
Authorization

methods:
GET
POST
PUT
DELETE
OPTIONS
HEAD
PATCH

max age: 3600
credentials: true
