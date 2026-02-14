# **🎬 Video-Tools v3.4**

A high-performance, multi-threaded Bash utility suite designed for professional video management. Clean, sort, and analyze M3U playlists and video directories with ease.

## **✨ Key Features**

* **⚡ Ultra-Fast Parallel Processing:** Leverages xargs \-P and nproc to utilize all available CPU cores for hashing and metadata extraction.  
* **🧹 Intelligent M3U Cleaning:**  
  * Removes duplicates using MD5 checksums (not just filenames).  
  * Automatically repairs broken file paths using fuzzy directory matching.  
* **📊 Advanced Playlist Sorting:** Reorder lists by resolution (height), file size, duration, or modification date.  
* **🔍 Deep Metadata Scanning:** Detects internal title tags and technical specs (bitrate, codec, dimensions) without manual inspection.  
* **🏆 Quality Comparison:** Compare two files side-by-side to determine which version is the high-quality master.  
* **📦 JSON Export:** Generate machine-readable reports for integration with other web tools or databases.

## **🚀 Installation**

### **1\. Prerequisites**

Ensure you have the necessary dependencies installed on your Linux/macOS system:

sudo apt update && sudo apt install ffmpeg coreutils file

### **2\. Setup**

Download the script and grant execution permissions:

chmod \+x video-tools.sh

## **🛠 Usage Guide**

### **Clean & Annotate Playlists**

Remove invalid paths and add technical metadata as comments to your M3U:

./video-tools.sh clean-m3u input.m3u output.m3u \--annotate \-v

### **Sort by Technical Specs**

Sort your playlist by resolution in descending order:

./video-tools.sh sort-m3u playlist.m3u \--by=res \--desc

### **Find & Manage Duplicates**

Scan a directory for identical videos and decide which ones to keep interactively:

./video-tools.sh find-dupes /path/to/videos

### **Export to JSON**

./video-tools.sh export-json playlist.m3u report.json

## **📋 Commands Overview**

| Command | Description |
| :---- | :---- |
| clean-m3u | Removes dead links and MD5 duplicates from playlists. |
| annotate-m3u | Adds resolution, duration, and codec info to M3U lines. |
| sort-m3u | Sorts by size, res, duration, or date. |
| scan-tags | Scans folders for internal metadata titles. |
| compare-quality | Side-by-side technical comparison of two files. |
| find-dupes | Interactive duplicate finder for local directories. |

## **⚙️ Requirements**

* **Bash:** 4.0+  
* **FFmpeg:** ffprobe must be in your PATH.  
* **Coreutils:** md5sum, nproc, stat.

## **📄 License**

This project is licensed under the **MIT License**.

*Optimized for efficiency. Built for creators.*
