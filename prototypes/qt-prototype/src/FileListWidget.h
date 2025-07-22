#ifndef FILELISTWIDGET_H
#define FILELISTWIDGET_H

#include <QWidget>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QLabel>
#include <QScrollArea>
#include <QFrame>
#include <QFileInfo>
#include <QMimeDatabase>

class FileItemWidget;

class FileListWidget : public QWidget
{
    Q_OBJECT

public:
    explicit FileListWidget(QWidget *parent = nullptr);
    
    void setFiles(const QStringList &files);
    void clearFiles();
    
signals:
    void filesChanged(const QStringList &files);

private:
    void setupUI();
    void updateFileList();
    QString formatFileSize(qint64 bytes);
    QString getFileIcon(const QString &filePath);
    
    QVBoxLayout *mainLayout;
    QLabel *titleLabel;
    QScrollArea *scrollArea;
    QWidget *scrollWidget;
    QVBoxLayout *scrollLayout;
    
    QStringList fileList;
    QList<FileItemWidget*> fileItemWidgets;
};

class FileItemWidget : public QFrame
{
    Q_OBJECT

public:
    explicit FileItemWidget(const QString &filePath, QWidget *parent = nullptr);
    
private:
    void setupUI();
    QString formatFileSize(qint64 bytes);
    QString getFileIcon(const QString &filePath);
    
    QString filePath;
    QHBoxLayout *layout;
    QLabel *iconLabel;
    QLabel *nameLabel;
    QLabel *sizeLabel;
    QLabel *typeLabel;
};

#endif // FILELISTWIDGET_H