#include "FileListWidget.h"
#include <QMimeDatabase>
#include <QFileInfo>

FileListWidget::FileListWidget(QWidget *parent)
    : QWidget(parent)
{
    setupUI();
}

void FileListWidget::setupUI()
{
    mainLayout = new QVBoxLayout(this);
    mainLayout->setSpacing(10);
    mainLayout->setContentsMargins(15, 15, 15, 15);
    
    titleLabel = new QLabel("📋 選択されたファイル");
    titleLabel->setObjectName("fileListTitle");
    titleLabel->setStyleSheet("font-size: 16px; font-weight: bold; color: #2c3e50; margin-bottom: 10px;");
    
    scrollArea = new QScrollArea();
    scrollArea->setObjectName("fileScrollArea");
    scrollArea->setWidgetResizable(true);
    scrollArea->setHorizontalScrollBarPolicy(Qt::ScrollBarAlwaysOff);
    scrollArea->setVerticalScrollBarPolicy(Qt::ScrollBarAsNeeded);
    
    scrollWidget = new QWidget();
    scrollWidget->setObjectName("fileScrollWidget");
    scrollLayout = new QVBoxLayout(scrollWidget);
    scrollLayout->setSpacing(5);
    scrollLayout->setContentsMargins(0, 0, 0, 0);
    scrollLayout->addStretch();
    
    scrollArea->setWidget(scrollWidget);
    
    mainLayout->addWidget(titleLabel);
    mainLayout->addWidget(scrollArea);
    
    // 初期スタイル設定
    setStyleSheet(
        "FileListWidget {"
        "    background-color: rgba(255, 255, 255, 0.9);"
        "    border: 1px solid #bdc3c7;"
        "    border-radius: 8px;"
        "}"
        "QScrollArea {"
        "    border: none;"
        "    background-color: transparent;"
        "}"
    );
}

void FileListWidget::setFiles(const QStringList &files)
{
    fileList = files;
    updateFileList();
    emit filesChanged(files);
}

void FileListWidget::clearFiles()
{
    fileList.clear();
    updateFileList();
    emit filesChanged(QStringList());
}

void FileListWidget::updateFileList()
{
    // 既存のウィジェットをクリア
    for (FileItemWidget *widget : fileItemWidgets) {
        widget->deleteLater();
    }
    fileItemWidgets.clear();
    
    // 新しいファイルアイテムを作成
    for (const QString &filePath : fileList) {
        FileItemWidget *item = new FileItemWidget(filePath);
        fileItemWidgets.append(item);
        scrollLayout->insertWidget(scrollLayout->count() - 1, item);
    }
}

QString FileListWidget::formatFileSize(qint64 bytes)
{
    if (bytes < 1024) return QString("%1 B").arg(bytes);
    if (bytes < 1024 * 1024) return QString("%1 KB").arg(bytes / 1024);
    if (bytes < 1024 * 1024 * 1024) return QString("%1 MB").arg(bytes / (1024 * 1024));
    return QString("%1 GB").arg(bytes / (1024 * 1024 * 1024));
}

QString FileListWidget::getFileIcon(const QString &filePath)
{
    QFileInfo info(filePath);
    QString suffix = info.suffix().toLower();
    
    if (suffix == "mp4" || suffix == "mov" || suffix == "avi" || suffix == "mkv" || suffix == "wmv") {
        return "🎬";
    } else if (suffix == "jpg" || suffix == "jpeg" || suffix == "png" || suffix == "gif") {
        return "📸";
    }
    return "📄";
}

// FileItemWidget Implementation
FileItemWidget::FileItemWidget(const QString &filePath, QWidget *parent)
    : QFrame(parent), filePath(filePath)
{
    setupUI();
}

void FileItemWidget::setupUI()
{
    setObjectName("fileItemWidget");
    setFrameStyle(QFrame::Box);
    setLineWidth(1);
    
    layout = new QHBoxLayout(this);
    layout->setSpacing(10);
    layout->setContentsMargins(10, 8, 10, 8);
    
    QFileInfo info(filePath);
    
    iconLabel = new QLabel(getFileIcon(filePath));
    iconLabel->setFixedSize(30, 30);
    iconLabel->setAlignment(Qt::AlignCenter);
    iconLabel->setStyleSheet("font-size: 18px;");
    
    nameLabel = new QLabel(info.fileName());
    nameLabel->setStyleSheet("font-weight: bold; color: #2c3e50;");
    nameLabel->setWordWrap(true);
    
    sizeLabel = new QLabel(formatFileSize(info.size()));
    sizeLabel->setStyleSheet("color: #7f8c8d; font-size: 12px;");
    sizeLabel->setMinimumWidth(80);
    
    typeLabel = new QLabel(info.suffix().toUpper());
    typeLabel->setStyleSheet("color: #3498db; font-size: 12px; font-weight: bold;");
    typeLabel->setMinimumWidth(40);
    
    layout->addWidget(iconLabel);
    layout->addWidget(nameLabel, 1);
    layout->addWidget(sizeLabel);
    layout->addWidget(typeLabel);
    
    setStyleSheet(
        "FileItemWidget {"
        "    background-color: #f8f9fa;"
        "    border: 1px solid #dee2e6;"
        "    border-radius: 4px;"
        "    margin: 2px;"
        "}"
        "FileItemWidget:hover {"
        "    background-color: #e9ecef;"
        "    border-color: #3498db;"
        "}"
    );
}

QString FileItemWidget::formatFileSize(qint64 bytes)
{
    if (bytes < 1024) return QString("%1 B").arg(bytes);
    if (bytes < 1024 * 1024) return QString("%1 KB").arg(bytes / 1024);
    if (bytes < 1024 * 1024 * 1024) return QString("%1 MB").arg(bytes / (1024 * 1024));
    return QString("%.1f GB").arg(bytes / (1024.0 * 1024.0 * 1024.0));
}

QString FileItemWidget::getFileIcon(const QString &filePath)
{
    QFileInfo info(filePath);
    QString suffix = info.suffix().toLower();
    
    if (suffix == "mp4" || suffix == "mov" || suffix == "avi" || suffix == "mkv" || suffix == "wmv") {
        return "🎬";
    } else if (suffix == "jpg" || suffix == "jpeg" || suffix == "png" || suffix == "gif") {
        return "📸";
    }
    return "📄";
}

#include "FileListWidget.moc"