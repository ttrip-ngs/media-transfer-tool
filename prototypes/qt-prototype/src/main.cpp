#include <QApplication>
#include <QFile>
#include <QStyleFactory>
#include <QDir>
#include "MainWindow.h"

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    
    // アプリケーション情報の設定
    app.setApplicationName("Media Transfer Tool");
    app.setApplicationVersion("1.0.0");
    app.setOrganizationName("Media Transfer Tools");
    
    // スタイルシートの適用
    QFile styleFile(":/style.qss");
    if (!styleFile.exists()) {
        styleFile.setFileName("style.qss");
    }
    
    if (styleFile.open(QFile::ReadOnly)) {
        QString style = QLatin1String(styleFile.readAll());
        app.setStyleSheet(style);
    }
    
    // メインウィンドウの作成と表示
    MainWindow window;
    window.show();
    
    return app.exec();
}