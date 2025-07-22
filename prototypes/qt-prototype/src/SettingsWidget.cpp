#include "SettingsWidget.h"

SettingsWidget::SettingsWidget(QWidget *parent)
    : QWidget(parent)
{
    setupUI();
}

void SettingsWidget::setupUI()
{
    mainLayout = new QVBoxLayout(this);
    mainLayout->setSpacing(15);
    mainLayout->setContentsMargins(15, 15, 15, 15);
    
    setupDestinationGroup();
    setupRulesGroup();
    
    // 情報表示ラベル
    infoLabel = new QLabel("設定を選択してください");
    infoLabel->setObjectName("infoLabel");
    infoLabel->setWordWrap(true);
    infoLabel->setStyleSheet(
        "color: #7f8c8d; "
        "font-size: 12px; "
        "padding: 10px; "
        "background-color: #f8f9fa; "
        "border: 1px solid #dee2e6; "
        "border-radius: 4px;"
    );
    
    mainLayout->addWidget(infoLabel);
    mainLayout->addStretch();
    
    // 初期設定
    localRadio->setChecked(true);
    dateFolderCheck->setChecked(true);
    duplicateCheck->setChecked(true);
    
    // 全体のスタイル設定
    setStyleSheet(
        "SettingsWidget {"
        "    background-color: rgba(255, 255, 255, 0.9);"
        "    border: 1px solid #bdc3c7;"
        "    border-radius: 8px;"
        "}"
        "QGroupBox {"
        "    font-weight: bold;"
        "    color: #2c3e50;"
        "    margin-top: 10px;"
        "    padding-top: 10px;"
        "}"
        "QGroupBox::title {"
        "    subcontrol-origin: margin;"
        "    left: 10px;"
        "    padding: 0 5px 0 5px;"
        "}"
        "QRadioButton, QCheckBox {"
        "    color: #34495e;"
        "    spacing: 8px;"
        "}"
        "QRadioButton:hover, QCheckBox:hover {"
        "    color: #2c3e50;"
        "}"
    );
}

void SettingsWidget::setupDestinationGroup()
{
    destinationGroup = new QGroupBox("🎯 出力先設定");
    destinationGroup->setObjectName("destinationGroup");
    
    QVBoxLayout *destLayout = new QVBoxLayout(destinationGroup);
    destLayout->setSpacing(8);
    
    localRadio = new QRadioButton("💻 ローカルストレージ");
    dropboxRadio = new QRadioButton("☁️ Dropbox");
    onedriveRadio = new QRadioButton("☁️ OneDrive");
    s3Radio = new QRadioButton("🪣 Amazon S3");
    
    destLayout->addWidget(localRadio);
    destLayout->addWidget(dropboxRadio);
    destLayout->addWidget(onedriveRadio);
    destLayout->addWidget(s3Radio);
    
    // シグナル接続
    connect(localRadio, &QRadioButton::toggled, this, &SettingsWidget::onDestinationChanged);
    connect(dropboxRadio, &QRadioButton::toggled, this, &SettingsWidget::onDestinationChanged);
    connect(onedriveRadio, &QRadioButton::toggled, this, &SettingsWidget::onDestinationChanged);
    connect(s3Radio, &QRadioButton::toggled, this, &SettingsWidget::onDestinationChanged);
    
    mainLayout->addWidget(destinationGroup);
}

void SettingsWidget::setupRulesGroup()
{
    rulesGroup = new QGroupBox("⚙️ 整理ルール");
    rulesGroup->setObjectName("rulesGroup");
    
    QVBoxLayout *rulesLayout = new QVBoxLayout(rulesGroup);
    rulesLayout->setSpacing(8);
    
    dateFolderCheck = new QCheckBox("📅 日付別フォルダ作成");
    deviceFolderCheck = new QCheckBox("📱 デバイス別フォルダ作成");
    duplicateCheck = new QCheckBox("🔍 重複ファイル検出");
    
    rulesLayout->addWidget(dateFolderCheck);
    rulesLayout->addWidget(deviceFolderCheck);
    rulesLayout->addWidget(duplicateCheck);
    
    // シグナル接続
    connect(dateFolderCheck, &QCheckBox::toggled, this, &SettingsWidget::onRuleChanged);
    connect(deviceFolderCheck, &QCheckBox::toggled, this, &SettingsWidget::onRuleChanged);
    connect(duplicateCheck, &QCheckBox::toggled, this, &SettingsWidget::onRuleChanged);
    
    mainLayout->addWidget(rulesGroup);
}

QString SettingsWidget::getDestination() const
{
    if (localRadio->isChecked()) return "local";
    if (dropboxRadio->isChecked()) return "dropbox";
    if (onedriveRadio->isChecked()) return "onedrive";
    if (s3Radio->isChecked()) return "s3";
    return "local";
}

bool SettingsWidget::getDateFolderEnabled() const
{
    return dateFolderCheck->isChecked();
}

bool SettingsWidget::getDeviceFolderEnabled() const
{
    return deviceFolderCheck->isChecked();
}

bool SettingsWidget::getDuplicateCheckEnabled() const
{
    return duplicateCheck->isChecked();
}

void SettingsWidget::onDestinationChanged()
{
    QString destination = getDestination();
    QString info = "出力先: ";
    
    if (destination == "local") {
        info += "ローカルストレージ";
    } else if (destination == "dropbox") {
        info += "Dropbox クラウド";
    } else if (destination == "onedrive") {
        info += "OneDrive クラウド";
    } else if (destination == "s3") {
        info += "Amazon S3";
    }
    
    infoLabel->setText(info);
    emit settingsChanged();
}

void SettingsWidget::onRuleChanged()
{
    QStringList rules;
    
    if (getDateFolderEnabled()) rules << "日付別フォルダ";
    if (getDeviceFolderEnabled()) rules << "デバイス別フォルダ";
    if (getDuplicateCheckEnabled()) rules << "重複検出";
    
    QString info = "出力先: " + getDestination();
    if (!rules.isEmpty()) {
        info += "\n適用ルール: " + rules.join(", ");
    }
    
    infoLabel->setText(info);
    emit settingsChanged();
}

#include "SettingsWidget.moc"