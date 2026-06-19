## 📖 项目简介
  WeAsmr是一款GUI工具，基于qt进行开发，提供音声、视频的在线播放和下载，支持播放列表的自定义。
  音频、视频源来自ASMRMOON ASMRGAY，感谢站长的分享
  
## 📸 截图
| 下载 | 在线播放 |
|:---:|:---:|
| ![下载](https://github.com/TOBugCoding/gitTest/blob/main/show4.png) | ![在线播放](https://github.com/TOBugCoding/gitTest/blob/main/show5.png) |

## 🌐 AsmrSiteServer (远程站点管理服务)
`server/` 目录下包含一个独立的 HTTP 服务端项目 **AsmrSiteServer**，用于集中管理音声站点数据。

### 功能说明
- **远程管理站点列表**: 通过 REST API 动态添加、删除、查询音声资源站点
- **多客户端共享**: 多个播放器客户端可连接同一服务器，共享站点配置
- **Token 鉴权**: 写操作（添加/删除站点）需要 Bearer Token 认证

### API 接口
| 方法 | 路径 | 说明 | 鉴权 |
|:---:|:---|:---|:---:|
| GET | `/api/sites` | 获取已启用的站点列表 | ❌ |
| POST | `/api/sites` | 添加新站点 | ✅ |
| DELETE | `/api/sites/:id` | 删除指定站点 | ✅ |

### 配置文件 (`server.json`)
```json
{
  "port": 8080,
  "internalToken": "your-secret-token",
  "sitesDataPath": "data/sites.json"
}
```

### 编译运行
```bash
cd server
cmake -B build
cmake --build build
./build/AsmrSiteServer
```

## 🙏 致谢
- 感谢开源项目[MediaGun]https://github.com/MediaGun/QuickVLC/releases
- 感谢所有用户的反馈和建议
---
