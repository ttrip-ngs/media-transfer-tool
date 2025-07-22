#include "MainWindow.h"
#include "FileListWidget.h"
#include "SettingsWidget.h"
#include <QApplication>
#include <QMessageBox>
#include <QStandardPaths>
#include <QUrl>
#include <QThread>

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , centralWidget(nullptr)
    , isProcessing(false)
    , processingThread(nullptr)
{
    setupUI();
    setAcceptDrops(true);
    setWindowTitle("📷 Media Transfer Tool - Qt");
    setMinimumSize(1000, 700);
    resize(1200, 800);
}

MainWindow::~MainWindow()
{
    if (processingThread && processingThread->isRunning()) {
        processingThread->quit();
        processingThread->wait();
    }
}

void MainWindow::setupUI()
{
    centralWidget = new QWidget(this);
    setCentralWidget(centralWidget);
    
    mainLayout = new QVBoxLayout(centralWidget);
    mainLayout->setSpacing(0);
    mainLayout->setContentsMargins(0, 0, 0, 0);
    
    setupHeaderSection();
    setupFileSelectionSection();
    setupContentSection();
    setupFooterSection();
    
    // 初期状態の設定
    updateFileCount();
}

void MainWindow::setupHeaderSection()
{
    headerFrame = new QFrame();
    headerFrame->setObjectName("headerFrame");
    headerFrame->setFixedHeight(120);
    
    QVBoxLayout *headerLayout = new QVBoxLayout(headerFrame);
    headerLayout->setAlignment(Qt::AlignCenter);
    
    titleLabel = new QLabel("🖥️ Media Transfer Tool - Qt");
    titleLabel->setObjectName("titleLabel");
    titleLabel->setAlignment(Qt::AlignCenter);
    
    subtitleLabel = new QLabel("写真・動画ファイルを高速で効率的に整理・転送");
    subtitleLabel->setObjectName("subtitleLabel");
    subtitleLabel->setAlignment(Qt::AlignCenter);
    
    headerLayout->addWidget(titleLabel);
    headerLayout->addWidget(subtitleLabel);
    
    mainLayout->addWidget(headerFrame);
}

void MainWindow::setupFileSelectionSection()
{
    fileSelectionFrame = new QFrame();
    fileSelectionFrame->setObjectName("fileSelectionFrame");
    fileSelectionFrame->setFixedHeight(200);
    
    QVBoxLayout *selectionLayout = new QVBoxLayout(fileSelectionFrame);
    selectionLayout->setAlignment(Qt::AlignCenter);
    
    dropZoneLabel = new QLabel("📂 ファイルをドラッグ&ドロップするか、下のボタンをクリック");
    dropZoneLabel->setObjectName("dropZoneLabel");
    dropZoneLabel->setAlignment(Qt::AlignCenter);
    
    selectButton = new QPushButton("📁 ファイルを選択");
    selectButton->setObjectName("selectButton");
    selectButton->setFixedSize(200, 50);
    
    fileCountLabel = new QLabel("ファイルが選択されていません");
    fileCountLabel->setObjectName("fileCountLabel");
    fileCountLabel->setAlignment(Qt::AlignCenter);
    
    selectionLayout->addWidget(dropZoneLabel);
    selectionLayout->addWidget(selectButton, 0, Qt::AlignCenter);
    selectionLayout->addWidget(fileCountLabel);
    
    connect(selectButton, &QPushButton::clicked, this, &MainWindow::selectFiles);
    
    mainLayout->addWidget(fileSelectionFrame);
}

void MainWindow::setupContentSection()
{
    contentFrame = new QFrame();
    contentFrame->setObjectName("contentFrame");
    
    contentLayout = new QHBoxLayout(contentFrame);
    contentLayout->setSpacing(20);
    contentLayout->setContentsMargins(20, 20, 20, 20);
    
    // ファイルリストウィジェット
    fileListWidget = new FileListWidget();
    fileListWidget->setMinimumWidth(500);
    
    // 設定ウィジェット
    settingsWidget = new SettingsWidget();
    settingsWidget->setFixedWidth(300);
    
    contentLayout->addWidget(fileListWidget, 2);
    contentLayout->addWidget(settingsWidget, 1);
    
    // 処理セクション
    processingFrame = new QFrame();
    processingFrame->setObjectName("processingFrame");
    processingFrame->setFixedHeight(120);
    
    QVBoxLayout *processingLayout = new QVBoxLayout(processingFrame);
    processingLayout->setAlignment(Qt::AlignCenter);
    
    processButton = new QPushButton("🚀 処理を開始");
    processButton->setObjectName("processButton");
    processButton->setFixedSize(200, 50);
    processButton->setEnabled(false);
    
    progressBar = new QProgressBar();
    progressBar->setObjectName("progressBar");
    progressBar->setVisible(false);
    
    progressLabel = new QLabel();
    progressLabel->setObjectName("progressLabel");
    progressLabel->setAlignment(Qt::AlignCenter);
    progressLabel->setVisible(false);
    
    processingLayout->addWidget(processButton, 0, Qt::AlignCenter);
    processingLayout->addWidget(progressBar);
    processingLayout->addWidget(progressLabel);
    
    connect(processButton, &QPushButton::clicked, this, &MainWindow::startProcessing);
    connect(fileListWidget, &FileListWidget::filesChanged, this, &MainWindow::onFilesChanged);
    
    mainLayout->addWidget(contentFrame);
    mainLayout->addWidget(processingFrame);
}

void MainWindow::setupFooterSection()
{
    footerFrame = new QFrame();
    footerFrame->setObjectName("footerFrame");
    footerFrame->setFixedHeight(50);
    
    QHBoxLayout *footerLayout = new QHBoxLayout(footerFrame);
    footerLayout->setAlignment(Qt::AlignCenter);
    
    footerLabel = new QLabel("⚡ Powered by Qt + C++");
    footerLabel->setObjectName("footerLabel");
    
    footerLayout->addWidget(footerLabel);
    
    mainLayout->addWidget(footerFrame);
}

void MainWindow::selectFiles()
{
    QStringList files = QFileDialog::getOpenFileNames(
        this,
        "メディアファイルを選択",
        QStandardPaths::writableLocation(QStandardPaths::PicturesLocation),
        "メディアファイル (*.jpg *.jpeg *.png *.gif *.mp4 *.mov *.avi *.mkv *.wmv);;すべてのファイル (*)"
    );
    
    if (!files.isEmpty()) {
        selectedFiles = files;
        fileListWidget->setFiles(files);
        updateFileCount();
        processButton->setEnabled(true);
    }
}

void MainWindow::startProcessing()
{
    if (selectedFiles.isEmpty()) {
        QMessageBox::warning(this, "警告", "処理するファイルが選択されていません。");
        return;
    }
    
    isProcessing = true;
    processButton->setEnabled(false);
    processButton->setText("⏳ 処理中...");
    progressBar->setVisible(true);
    progressLabel->setVisible(true);
    progressBar->setValue(0);
    
    // 処理スレッドの開始
    processingThread = new ProcessingThread(selectedFiles, this);
    connect(processingThread, &ProcessingThread::progressChanged, this, &MainWindow::updateProgress);
    connect(processingThread, &ProcessingThread::processingFinished, this, &MainWindow::processingFinished);
    processingThread->start();
}

void MainWindow::updateProgress(int percentage)
{
    progressBar->setValue(percentage);
    progressLabel->setText(QString("%1% 完了").arg(percentage));
}

void MainWindow::processingFinished()
{
    isProcessing = false;
    processButton->setEnabled(true);
    processButton->setText("🚀 処理を開始");
    progressBar->setVisible(false);
    progressLabel->setVisible(false);
    
    QMessageBox::information(this, "完了", "ファイル処理が完了しました！");
    
    // スレッドのクリーンアップ
    if (processingThread) {
        processingThread->deleteLater();
        processingThread = nullptr;
    }
}

void MainWindow::onFilesChanged(const QStringList &files)
{
    selectedFiles = files;
    updateFileCount();
    processButton->setEnabled(!files.isEmpty());
}

void MainWindow::updateFileCount()
{
    if (selectedFiles.isEmpty()) {
        fileCountLabel->setText("ファイルが選択されていません");
        fileCountLabel->setStyleSheet("color: #bdc3c7;");
    } else {
        fileCountLabel->setText(QString("%1 件のファイルが選択されています").arg(selectedFiles.size()));
        fileCountLabel->setStyleSheet("color: #27ae60; font-weight: bold;");
    }
}

void MainWindow::dragEnterEvent(QDragEnterEvent *event)
{
    if (event->mimeData()->hasUrls()) {
        event->acceptProposedAction();
    }
}

void MainWindow::dropEvent(QDropEvent *event)
{
    QStringList files;
    foreach (const QUrl &url, event->mimeData()->urls()) {
        if (url.isLocalFile()) {
            files << url.toLocalFile();
        }
    }
    
    if (!files.isEmpty()) {
        selectedFiles = files;
        fileListWidget->setFiles(files);
        updateFileCount();
        processButton->setEnabled(true);
    }
}

// ProcessingThread Implementation
ProcessingThread::ProcessingThread(const QStringList &files, QObject *parent)
    : QThread(parent), filesToProcess(files)
{
}

void ProcessingThread::run()
{
    int totalFiles = filesToProcess.size();
    
    for (int i = 0; i < totalFiles; ++i) {
        // ファイル処理のシミュレーション
        QThread::msleep(500);
        
        int percentage = ((i + 1) * 100) / totalFiles;
        emit progressChanged(percentage);
    }
    
    emit processingFinished();
}

#include "MainWindow.moc"