#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QGridLayout>
#include <QLabel>
#include <QPushButton>
#include <QProgressBar>
#include <QFileDialog>
#include <QDragEnterEvent>
#include <QDropEvent>
#include <QMimeData>
#include <QThread>
#include <QTimer>
#include <QFileInfo>
#include <QScrollArea>
#include <QFrame>

class FileListWidget;
class SettingsWidget;
class ProcessingThread;

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

private slots:
    void selectFiles();
    void startProcessing();
    void updateProgress(int percentage);
    void processingFinished();
    void onFilesChanged(const QStringList &files);

protected:
    void dragEnterEvent(QDragEnterEvent *event) override;
    void dropEvent(QDropEvent *event) override;

private:
    void setupUI();
    void setupHeaderSection();
    void setupFileSelectionSection();
    void setupContentSection();
    void setupFooterSection();
    void updateFileCount();
    
    // UI Components
    QWidget *centralWidget;
    QVBoxLayout *mainLayout;
    
    // Header
    QFrame *headerFrame;
    QLabel *titleLabel;
    QLabel *subtitleLabel;
    
    // File Selection
    QFrame *fileSelectionFrame;
    QLabel *dropZoneLabel;
    QPushButton *selectButton;
    QLabel *fileCountLabel;
    
    // Content
    QFrame *contentFrame;
    QHBoxLayout *contentLayout;
    FileListWidget *fileListWidget;
    SettingsWidget *settingsWidget;
    
    // Processing
    QFrame *processingFrame;
    QPushButton *processButton;
    QProgressBar *progressBar;
    QLabel *progressLabel;
    
    // Footer
    QFrame *footerFrame;
    QLabel *footerLabel;
    
    // Data
    QStringList selectedFiles;
    bool isProcessing;
    ProcessingThread *processingThread;
};

// 処理用スレッド
class ProcessingThread : public QThread
{
    Q_OBJECT
    
public:
    ProcessingThread(const QStringList &files, QObject *parent = nullptr);
    
protected:
    void run() override;
    
signals:
    void progressChanged(int percentage);
    void processingFinished();
    
private:
    QStringList filesToProcess;
};

#endif // MAINWINDOW_H