#ifndef SETTINGSWIDGET_H
#define SETTINGSWIDGET_H

#include <QWidget>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QGroupBox>
#include <QRadioButton>
#include <QCheckBox>
#include <QLabel>
#include <QFrame>

class SettingsWidget : public QWidget
{
    Q_OBJECT

public:
    explicit SettingsWidget(QWidget *parent = nullptr);
    
    // 設定値の取得
    QString getDestination() const;
    bool getDateFolderEnabled() const;
    bool getDeviceFolderEnabled() const;
    bool getDuplicateCheckEnabled() const;

signals:
    void settingsChanged();

private slots:
    void onDestinationChanged();
    void onRuleChanged();

private:
    void setupUI();
    void setupDestinationGroup();
    void setupRulesGroup();
    
    QVBoxLayout *mainLayout;
    
    // 出力先設定
    QGroupBox *destinationGroup;
    QRadioButton *localRadio;
    QRadioButton *dropboxRadio;
    QRadioButton *onedriveRadio;
    QRadioButton *s3Radio;
    
    // 整理ルール設定
    QGroupBox *rulesGroup;
    QCheckBox *dateFolderCheck;
    QCheckBox *deviceFolderCheck;
    QCheckBox *duplicateCheck;
    
    // 情報表示
    QLabel *infoLabel;
};

#endif // SETTINGSWIDGET_H