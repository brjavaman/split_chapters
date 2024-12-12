# split_chapters
bash script to split chapters from a MP4 video, based on a text description.

# Running

on the directory of your `VIDEO_FILE.mp4` file, make sure you have a `VIDEO_FILE.txt` file as describe bellow and run:

```
split_chapters.sh VIDEO_FILE.mp4
```

# Workflow
The best strategy is to use an AI tool to generate chapters for your video. I use Taja.ai for that. ChatGPT works well too.

You can also do it by hand.

Just generate the text file with the timestamp and title for each chapter and run the command to break the .mp4 video into multiple chapters.

# Chapter File
The chapter file has the same name of the video file, with a .txt extension. It contains a timestamp and the title, in this format:

```
00:00 - Title 1
10:05 - Title 2
01:10:00 - Title 3
02:00:10 - Title 4
```

The chapters need to be in chronological order. The script will remove special characters and accented characters from the titles, and use the title to create a filename for the exported chapter. Any lne with no title will be skipped, so, you could use that to not export parts of the video.

# The script
The `split_chapters.sh` script will interate over the chapter file and run ffmpeg to export each chapter to the output_chapters directory.




