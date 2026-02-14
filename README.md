# **🎬 Video-Tools v3.2**

A reliable and efficient Bash utility suite for managing video playlists (M3U) and analyzing video directories. Version 3.2 focuses on stability and robust metadata annotation.

## **✨ Key Features**

* **⚡ Parallel Annotation:** Uses multi-threading (xargs) to fetch metadata for playlists, significantly speeding up the annotation process.  
* **🧹 Robust M3U Cleaning:** \* Removes duplicate entries based on MD5 checksums.  
  * Deep-scan path recovery: Automatically finds moved or renamed files within the project root.  
* **📊 Advanced Playlist Sorting:** Organize your media by resolution, file size, duration, or date.  
* **🔍 Metadata Insights:** Extract technical specifications like codecs, bitrates, and internal title tags.  
* **🏆 Side-by-Side Comparison:** Compare two video files to identify the best quality version.  
* **📦 JSON Export:** Convert M3U playlists into structured JSON for external use.

## **🚀 Installation**

### **1\. Prerequisites**

Ensure you have the necessary dependencies installed:

sudo apt update && sudo apt install ffmpeg coreutils file

### **2\. Setup**

Download the script and make it executable:

chmod \+x video-tools.sh

## **🛠 Usage Guide**

### **Clean & Annotate Playlists**

The core feature of v3.2. Removes duplicates and adds technical info:

./video-tools.sh clean-m3u input.m3u output.m3u \--annotate \-v

### **Sort Playlists**

Sort your M3U by resolution in descending order:

./video-tools.sh sort-m3u playlist.m3u \--by=res \--desc

### **Find Duplicates**

Scan a directory for identical video files:

./video-tools.sh find-dupes /path/to/videos

## **📋 Commands Overview**

| Command | Description |
| :---- | :---- |
| clean-m3u | Removes dead links and MD5 duplicates. |
| annotate-m3u | Adds resolution, duration, and codec info to lines. |
| sort-m3u | Sorts by size, res, duration, or date. |
| scan-tags | Scans folders for internal metadata titles. |
| compare-quality | Technical comparison of two files. |
| find-dupes | Interactive duplicate finder. |

## **⚙️ Requirements**

* **Bash:** 4.0+  
* **FFmpeg:** ffprobe required for metadata.  
* **Coreutils:** md5sum, stat.

## **📄 License**

This project is licensed under the **MIT License**.

*Stability first. Optimized for reliability.*
