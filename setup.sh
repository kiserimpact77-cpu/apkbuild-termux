#!/bin/bash
# ================================================
# سكريبت إعداد بيئة بناء APK على Termux
# شغّله مرة واحدة فقط
# ================================================

echo "🔧 جارٍ تحضير البيئة..."

# الخطوة 1: تحديث Termux وتثبيت proot-distro
pkg update -y && pkg upgrade -y
pkg install -y proot-distro wget unzip git

# الخطوة 2: تثبيت Ubuntu داخل Termux
echo "📦 جارٍ تثبيت Ubuntu... (قد يأخذ وقتاً)"
proot-distro install ubuntu

# الخطوة 3: تثبيت كل أدوات البناء داخل Ubuntu
echo "⚙️  جارٍ تثبيت Java و Android SDK..."
proot-distro login ubuntu -- bash -c "
apt update -y && apt upgrade -y

# تثبيت Java 17
apt install -y openjdk-17-jdk wget unzip git aapt

# إعداد Android SDK
mkdir -p /root/android-sdk/cmdline-tools
cd /root
wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O cmdtools.zip
unzip -q cmdtools.zip
mv cmdline-tools /root/android-sdk/cmdline-tools/latest
rm cmdtools.zip

# إعداد المسارات
export ANDROID_HOME=/root/android-sdk
export PATH=\$PATH:\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools

# قبول الرخص وتثبيت المنصة
yes | sdkmanager --licenses
sdkmanager 'platforms;android-33' 'build-tools;33.0.0' 'platform-tools'

echo 'export ANDROID_HOME=/root/android-sdk' >> ~/.bashrc
echo 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-arm64' >> ~/.bashrc
echo 'export PATH=\$PATH:\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools:\$JAVA_HOME/bin' >> ~/.bashrc

echo '✅ تم تثبيت البيئة بنجاح!'
"

# الخطوة 4: إنشاء أمر apkbuild في Termux
cat > $PREFIX/bin/apkbuild << 'SCRIPT'
#!/bin/bash

if [ "$1" == "new" ]; then
    NAME=$2
    echo "📱 جارٍ إنشاء مشروع: $NAME"
    proot-distro login ubuntu -- bash -c "
    mkdir -p /root/$NAME/app/src/main/java/com/example/$NAME
    mkdir -p /root/$NAME/app/src/main/res/layout

    # build.gradle الرئيسي
    cat > /root/$NAME/build.gradle << 'EOF'
buildscript {
    repositories { google(); mavenCentral() }
    dependencies { classpath 'com.android.tools.build:gradle:7.4.0' }
}
allprojects { repositories { google(); mavenCentral() } }
EOF

    # settings.gradle
    echo \"include ':app'\" > /root/$NAME/settings.gradle

    # build.gradle للتطبيق
    cat > /root/$NAME/app/build.gradle << 'EOF'
apply plugin: 'com.android.application'
android {
    compileSdkVersion 33
    defaultConfig {
        applicationId \"com.example.APPNAME\"
        minSdkVersion 21
        targetSdkVersion 33
        versionCode 1
        versionName '1.0'
    }
}
EOF
    sed -i \"s/APPNAME/$NAME/g\" /root/$NAME/app/build.gradle

    # AndroidManifest.xml
    cat > /root/$NAME/app/src/main/AndroidManifest.xml << 'EOF'
<?xml version=\"1.0\" encoding=\"utf-8\"?>
<manifest xmlns:android=\"http://schemas.android.com/apk/res/android\"
    package=\"com.example.APPNAME\">
    <application android:label=\"APPNAME\" android:allowBackup=\"true\">
        <activity android:name=\".MainActivity\" android:exported=\"true\">
            <intent-filter>
                <action android:name=\"android.intent.action.MAIN\"/>
                <category android:name=\"android.intent.category.LAUNCHER\"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
EOF
    sed -i \"s/APPNAME/$NAME/g\" /root/$NAME/app/src/main/AndroidManifest.xml

    # MainActivity.java
    cat > /root/$NAME/app/src/main/java/com/example/$NAME/MainActivity.java << 'EOF'
package com.example.APPNAME;
import android.app.Activity;
import android.os.Bundle;
import android.widget.TextView;
public class MainActivity extends Activity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        TextView tv = new TextView(this);
        tv.setText(\"مرحبا بك في \" + \"APPNAME\");
        setContentView(tv);
    }
}
EOF
    sed -i \"s/APPNAME/$NAME/g\" /root/$NAME/app/src/main/java/com/example/$NAME/MainActivity.java

    echo '✅ تم إنشاء المشروع! الآن شغّل: apkbuild build $NAME'
    "

elif [ "$1" == "build" ]; then
    NAME=$2
    echo "🔨 جارٍ بناء APK للمشروع: $NAME"
    proot-distro login ubuntu -- bash -c "
    source ~/.bashrc
    export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-arm64
    export ANDROID_HOME=/root/android-sdk
    export PATH=\$JAVA_HOME/bin:\$PATH:\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools

    cd /root/$NAME

    # تحميل gradle wrapper لو مش موجود
    if [ ! -f gradlew ]; then
        gradle wrapper --gradle-version=7.5
    fi

    chmod +x gradlew

    # إصلاح aapt2 لـ ARM64
    find ~/.gradle -name 'aapt2-*-linux.jar' -type f | xargs -I{} jar -u -f {} -C /usr/bin aapt2 2>/dev/null || true

    ./gradlew clean assembleDebug --no-daemon

    if [ -f app/build/outputs/apk/debug/app-debug.apk ]; then
        cp app/build/outputs/apk/debug/app-debug.apk /storage/emulated/0/Download/${NAME}.apk
        echo '✅ نجح البناء! APK موجود في Downloads باسم: ${NAME}.apk'
    else
        echo '❌ فشل البناء - راجع الأخطاء أعلاه'
    fi
    "

else
    echo "الاستخدام:"
    echo "  apkbuild new  <اسم_المشروع>   - إنشاء مشروع جديد"
    echo "  apkbuild build <اسم_المشروع>  - بناء APK"
fi
SCRIPT

chmod +x $PREFIX/bin/apkbuild

echo ""
echo "✅ اكتمل الإعداد!"
echo ""
echo "الآن يمكنك:"
echo "  apkbuild new  myapp   ← إنشاء مشروع جديد"
echo "  apkbuild build myapp  ← بناء APK جاهز في Downloads"

