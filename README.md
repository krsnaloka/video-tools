# **🎬 Video Tools**

**A highly optimized Bash toolkit for managing, sorting, and organizing video collections.**

This script is a "Swiss Army Knife" for video power users. It leverages modern Unix pipelines and parallel processing to handle even massive media libraries at lightning speed. Whether you want to create playlists, clean up downloads, or find duplicates – Video Tools gets it done with maximum performance.

## **🚀 Key Features**

* **Parallel Processing:** Automatically utilizes all available CPU cores (xargs \-P) to accelerate metadata scans and validations.  
* **Speed Pipeline:** Uses filetype \-f instead of slower standard methods to identify video files in fractions of a second.  
* **Intelligent Grouping (sort-by-words):** Sorts videos based on word similarities in the filename – ideal for TV shows or related clips.  
* **Download Organizer (move-videos):** Scans directories (e.g., your Downloads folder), lists found videos, and moves them collectively to a destination directory.  
* **Playlist Tuning:** Creates M3U files, cleans up dead paths, and can add technical comments (resolution, codec, bitrate) upon request.  
* **Quality Check:** Finds MD5 duplicates and provides a direct comparison of technical data to help you delete the lower-quality version.

## **🛠 Installation & Requirements**

Ensure the following tools are installed on your system:

\# Required dependencies  
sudo apt update  
sudo apt install ffmpeg filetype coreutils

### **Download**

Simply download the script and make it executable:

chmod \+x video-tools.sh

## **📖 Usage & Examples**

### **1\. Create a Playlist**

Creates an M3U file from all videos in a folder:

./video-tools.sh make-m3u /path/to/videos my\_list.m3u

### **2\. Clean Up Downloads**

Searches for all videos in Downloads and moves them (with preview and confirmation):

./video-tools.sh move-videos \~/Downloads /path/to/series

### **3\. Intelligent Sorting**

Groups videos in a playlist by name similarity:

./video-tools.sh sort-by-words my\_list.m3u sorted.m3u

### **4\. Sort Playlist by Quality**

Sorts a playlist by resolution (descending) and adds metadata info:

./video-tools.sh sort-m3u list.m3u \--by=res \--desc \--annotate

### **5\. Find Duplicates**

Searches for identical files via MD5 hash and compares their quality:

./video-tools.sh find-dupes /path/to/videos

## **📋 Command Overview**

| Command | Description |
| :---- | :---- |
| make-m3u | Blazing fast M3U playlist creation. |
| move-videos | Moves videos from A to B (with preview). |
| sort-by-words | Groups thematically related videos together. |
| clean-m3u | Removes dead links and duplicates from playlists. |
| sort-m3u | Sorts by resolution, size, date, or duration. |
| scan-tags | Reads internal title metadata. |
| find-dupes | Interactive duplicate search with quality comparison. |

## **💡 Technical Details**

The script is built for efficiency:

* **Language:** Bash (Shell Script)  
* **Parallelization:** xargs with dynamic core detection.  
* **Engine:** ffprobe for metadata, filetype for MIME checks, md5sum for integrity.

*Built for efficiency and order in large video libraries.* 😎
