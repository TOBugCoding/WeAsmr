#include "NumberToChinese.h"

QString NumberToChinese::GetNumber(double a) {
	const QString chineseNumbers[] = { "零", "壹", "贰", "叁", "肆", "伍", "陆", "柒", "捌", "玖" };
	const QString chineseUnits[] = { "", "拾", "佰", "仟" };
	const QString chineseDecimalUnits[] = { "角", "分" };

    QString sign;
    if (a < 0) {
        sign = "负";
        a = -a;
    }

    // 分离整数和小数部分（精确到分）
    long long integerPart = static_cast<long long>(a);
    int decimalPart = static_cast<int>(std::round((a - integerPart) * 100));

    // 处理整数部分
    QString integerStr;
    if (integerPart == 0) {
        integerStr = "零元";
    }
    else {
        QString temp;
        int zeroFlag = 0;
        int pos = 0;

        while (integerPart > 0) {
            int digit = integerPart % 10;
            if (digit == 0) {
                if (!zeroFlag && pos > 0) {
                    temp += chineseNumbers[0];
                    zeroFlag = 1;
                }
            }
            else {
                zeroFlag = 0;
                temp += chineseNumbers[digit] + chineseUnits[pos % 4];
            }
            integerPart /= 10;
            pos++;
        }

        // 反转字符串（因为是从低位开始处理的）
        std::reverse(temp.begin(), temp.end());
        integerStr = temp + "元";
    }

    // 处理小数部分
    QString decimalStr;
    if (decimalPart == 0) {
        decimalStr = "整";
    }
    else {
        int jiao = decimalPart / 10;
        int fen = decimalPart % 10;

        if (jiao > 0) {
            decimalStr += chineseNumbers[jiao] + chineseDecimalUnits[0];
        }
        if (fen > 0) {
            decimalStr += chineseNumbers[fen] + chineseDecimalUnits[1];
        }
    }

    // 组合结果（包含符号）
    return sign + integerStr + decimalStr;
}
