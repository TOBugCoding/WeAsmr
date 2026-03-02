#pragma once
#include <QString>
class webAddr {
public:
    enum webType {
        moon,  // 对应 asmrmoon.com
        gay    // 对应 asmr.party
    };

    static webAddr& GetInstance() {
        static webAddr instance;
        return instance;
    }
    void initWebAddr(webType type) {
        if (type == moon) {
            mainwebUrl = "https://asmrmoon.com";
            donwloadUrl = "https://mooncdn.asmrmoon.com";
            targetAddr = moon;
        } else if (type == gay) {
            mainwebUrl = "https://www.asmrgay.com";
            donwloadUrl = "https://asmr.121231234.xyz";
            targetAddr = gay;
        }
    }

    QString getMainweb() const {
        return mainwebUrl;
    }

    QString getDonload() const {
        return donwloadUrl;
    }

    webType getTargetAddr() const {
        return targetAddr;
    }

    // 禁止拷贝和赋值（单例必须保证唯一，禁用这两个操作）
    webAddr(const webAddr&) = delete;
    webAddr& operator=(const webAddr&) = delete;

private:
    webAddr() {
        mainwebUrl = "https://asmrmoon.com";
        donwloadUrl = "https://mooncdn.asmrmoon.com";
        targetAddr = moon;
    }

    ~webAddr() = default;

    webType targetAddr;  // 当前访问的网站类型
    QString mainwebUrl;  // 主站地址
    QString donwloadUrl; // 下载地址
};
