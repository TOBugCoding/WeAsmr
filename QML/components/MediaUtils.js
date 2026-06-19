// MediaUtils.js — 共享的媒体格式检查工具
// 被 PlaybackControl / Asmr_list / Collect / SearchShowPage / Bottomplayer 共用

.pragma library

var mediaExts = [
    ".mp3", ".flac", ".wav", ".m4a", ".aac", ".ogg", ".wma", ".ape",
    ".mp4", ".mkv", ".avi", ".mov", ".rmvb", ".webm", ".flv", ".m3u8", ".ts"
];

var videoExts = [
    ".mp4", ".mkv", ".avi", ".mov", ".rmvb", ".webm", ".flv", ".m3u8", ".ts"
];

/**
 * 判断文件是否为音视频媒体文件
 * @param {string} pathOrName — 文件路径或文件名
 * @returns {bool}
 */
function isMediaFile(pathOrName) {
    var lowerName = pathOrName.split("?")[0].split("/").pop().toLowerCase();
    for (var i = 0; i < mediaExts.length; i++) {
        if (lowerName.endsWith(mediaExts[i]))
            return true;
    }
    return false;
}

/**
 * 判断文件是否为视频文件
 * @param {string} pathOrName — 文件路径或文件名
 * @returns {bool}
 */
function isVideoFile(pathOrName) {
    var lowerName = pathOrName.split("?")[0].split("/").pop().toLowerCase();
    for (var i = 0; i < videoExts.length; i++) {
        if (lowerName.endsWith(videoExts[i]))
            return true;
    }
    return false;
}
