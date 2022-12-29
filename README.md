---
created: 2022-12-25T17:13:13-08:00
updated: 2023-01-02T10:56:16-08:00
---

Audionook — your very own little nook for rendering to read your own [audiobook](https://en.wikipedia.org/wiki/Audiobook).

# Background
I wrote this so I can render audiobooks from things I enjoy listening to; audio I've downloaded from YouTube or other sources.  This package is an orchestration of events that are designed to automate turning arbitrary audio tracks into M4B audiobooks.

## Orchestration Pipeline
The orchestration pipelines, with your help, transcodes, transmutes, and transforms audio from any form, into the final M4B audiobook, along with any cover art that you may want to use as a finishing touch.  It's a branchless linear pipeline that can is broken up into 4 distinct stages:

1. ***Audio/Video** (e.g., YouTube)* ⏩  `${WORKBENCH}/Incoming/` ⏩ (to stage 2)
2. ***DAW** (e.g., Ableton Live!)* ⏩  `/tmp/Staging` ⏩ (to stage 3)
3. **`make book`**:  `${WORKBENCH}/Outgoing/` ⏩  `${WORKBENCH}/Books/` ⏩  (to stage 4)
4. **`make publish`** ⏩  `${BOOKSHELF}/` (complete)

### Stage 1 — Audio Collection
The first stage is the act of collecting all the various sources of audio, from which you intend to create your audiobook.  These are here denoted as having been placed in `${WORKBENCH}/Incoming/`, but they can be anywhere you want.  My main source of material is YouTube, for which I use [`youtube-dl`](https://github.com/ytdl-org/youtube-dl).

### Stage 2 — Audio Tinkering
In this stage, you will tinker with and doctor the audio files in any way you wish—.  When done, export the 
2. Next I doctor the audio; this is an optional step which may be skipped.  Note that *Ableton Live!* is an overkill for this; if you don't already have it, don't get it.
3. Export your MP3 stems (chapters) into `/tmp/Staging`
4. Run `make book` which will first transcode the chapters, moving them to `Outgoing/`, and then merge and annotate them as an M4B and drop the book into `Books/`
5. Finally, run `make publish` to move the product to your audiobook folder.

## Tools
- For audio work, I use [*Ableton Live!*](https://ableton.com), something not designed for audiobook production, but for music.  There's no hard requirement on *Ableton Live!*, just provide the MP3 files to the pipeline here and the rest will work as it normally would.
- For any audio work/transcoding/transformation, I use `ffmpeg` and for reading audio data I use `ffprobe`.  This is a requirement, so `brew install ffmpeg`.  Yes, I've only used this on a Mac.
- `make` provides the automation pipeline
- `bash` provides the configuration parser (via `bin/mkcfg`)
- `python` provides the audiobook cover art work (via `bin/mkcov`

# Setup
Pick an audiobook `id`, and find a place for your workbench; my first audiobook which I'll use for demonstration, used the following setup:
```bash
export BOOKS=shorts
export WORKBENCH="${HOME}/pCloud Drive/YouTube"
export BOOKSHELF="${HOME}/pCloud Drive/Audiobooks"
```

## Ableton Live!

### Exporting
> [!WARNING] Note
> It is assumed that your *Ableton Live!* project is called `YouTube`, and your export prefix is named the same.

> [!WARNING]
> Take care to export as follows:
> 1. Make sure solo is not selected on any track,
> 2. make sure all tracks have been enabled,
> 3. select everyting in the track view with `<command>+a`,
> 4. finally `<command>+<click>` and select the tracks/stems you want to export, and
> 5. hit `<command>+<shift>+r`.
>
> In the export dialogue:
> 1. Select _Selected Track Only_ for _Rendered Tracks_   
> 2. Set all options to `off`, with the exception of **_MP3 encoding_** and ***Normalize***.
> 3. When prompted, select the `Staging/` directory, and leave the filename (prefix) as `YouTube`; we will deal with this later.

## Steps
### Download
Download the material for putting your audiobook together from anywhere you like.  I get mine mostly from YouTube, and use `youtube-dl` for that.  Place these into the `Incoming/` folder.

> [!TIP] Tip
> Don't try too hard maintaining healthy filenames here since some downloads may have multiple narrations and multiple narrators, or authors.  That work begins when we get to `/tmp/Staging`, which itself will get it's name from *Ableton Live!*.

```bash
brew install youtube-dl
youtube-dl -u "${GOOGLE_USERNAME}" -p "${GOOGLE_PASSWORD}" -x https://youtu.be/Gl1Rao271SU -o "<title>+<poet>@<collection>+<narrator>+<youtube-id>.%(ext)s"
for opus in *.opus; do ffmpeg -i ${opus} ${opus//.opus/.mp4}; done
rm *.opus
```


> [!TIP] Amendments
> The most expensive step in this entire process may well be the extraction and normalization of stems out of *Ableton Live!* after you've made changes to it.  When you change your *Ableton Live!* project and want to recreate your audiobook, there's a way to prevent having to laboriously re-export from *Live!*;  Once you've made changes in your *Live!* project, inserted new stems and reordered the audiobook, many track numbers would have shifted about.  In that case, simply edit and update `Books/<book-id>.cfg` to match up with your *Live!* project, and then run this script in `/tmp/Staging/`
> 
> ```bash
>while read line; do
>    IFS=- read num file <<< "${line}";
 >    matched=$(compgen -G "*-${file}.mp3") && [ ! -z "${matched}" ] && [ "${matched}" != "${num}-${file}.mp3" ] && mv "${matched}" "$num-${file}.mp3";
 >done < <(tail -n +2 ~/pCloud\ Drive/YouTube/Books/shorts.cfg|awk -F '|' '{print$1}')
 >rm *.len
 >```
 >When complete, export the new tracks only from Ableton and continue as per usual from there (from here actually).
 
 
> [!NOTE] Backup
> The `Staging` folder in the project can be used to back up the exports from `/tmp/Staging`.  It's not used otherwise. From the project directory, run:
> 
>```bash
>rsync -Pa /tmp/Staging/ Staging/
>```

### Audio Work
Edit the source material, and when complete, export them into the `Staging/` folder as  `mp3`s; I use Ableton for this part.**

> [!HELP] Ableton Live! *Export*
> To make things easier, name your tracks as follows:
> 	`##-<title>-<author>@<collection>-<narrator>`
> 
> To export from *Ableton Live!* see above.

> [!WARNING] Ableton Live! *Export*
> Ableton exports every stems with a length equal to that of the longest stem in the export group.
> ```bash
> ╰─○ cd /tmp/Staging/
> ╰─○ for mp3 in YouTube*; do mv "${mp3}" ${mp3//YouTube /}; done
> ╰─○ ls -l
total 3392040
-rw-r--r-- 1 ntd 142079999 Dec 26 22:48 01-alone+eap@wn+tom-o-bedlam.mp3
-rw-r--r-- 1 ntd 142079999 Dec 26 22:50 02-the-raven+eap@ad-hoc+scl.mp3
-rw-r--r-- 1 ntd 142079999 Dec 26 22:51 03-intro@extraordinary-tales.mp3
-rw-r--r-- 1 ntd 142079999 Dec 26 22:53 04-the-fall-of-the-house-of-usher+eap@extraordinary-tales+scl.mp3
-rw-r--r-- 1 ntd 142079999 Dec 26 22:57 05-the-fall-of-the-house-of-usher+eap@tales-of-mystery-and-horror+scl.mp3
-rw-r--r-- 1 ntd 142079999 Dec 26 22:58 06-interlude-i@extraordinary-tales.mp3
-rw-r--r-- 1 ntd 142079999 Dec 26 23:00 07-the-black-cat+scl@tales-of-mystery-and-horror+scl.mp3
-rw-r--r-- 1 ntd 142079999 Dec 26 23:03 08-the-cask-of-amontillado+eap@tales-of-mystery-and-horror+scl.mp3
-rw-r--r-- 1 ntd 142079999 Dec 26 23:04 09-interlude-iii@extraordinary-tales.mp3
-rw-r--r-- 1 ntd 142079999 Dec 26 23:05 10-the-tell-tale-heart+eap@extraordinary-tales+bela-lugosi.mp3
-rw-r--r-- 1 ntd 142079999 Dec 26 23:07 11-the-tell-tale-heart+eap@tales-of-mystery-and-horror+scl.mp3
-rw-r--r-- 1 ntd 142079999 Dec 26 23:08 12-interlude-iv@extraordinary-tales.mp3
-rw-r--r-- 1 ntd 142079999 Dec 26 23:10 13-the-mask-of-the-red-death@eap+tales-of-mystery-and-horror+scl.mp3
-rw-r--r-- 1 ntd 142079999 Dec 26 23:15 14-william-wilson+eap@hbp+dave-luukkonen.mp3
-rw-r--r-- 1 ntd 142079999 Dec 26 23:17 15-the-facts-in-the-case-of-m-valdemar+eap@extraordinary-tales+julian-sands.mp3
-rw-r--r-- 1 ntd 142079999 Dec 26 23:18 16-interlude-v@extraordinary-tales.mp3
-rw-r--r-- 1 ntd 142079999 Dec 26 23:20 17-the-pit-and-the-pendulum@eap@extraordinary-tales+guillermo-del-toro.mp3
-rw-r--r-- 1 ntd 142079999 Dec 26 23:21 18-outerlude@extraordinary-tales.mp3
-rw-r--r-- 1 ntd 142079999 Dec 26 23:23 19-hop-frog+eap@tales-of-mystery-and-horror+scl.mp3
-rw-r--r-- 1 ntd 142079999 Dec 26 23:26 20-the-murders-in-the-rue-morgue+eap@tales-of-mystery-and-horror+scl.mp3
-rw-r--r-- 1 ntd 142079999 Dec 26 23:30 21-the-strange-case-of-dr-jekyll-and-mr-hyde+r-l-stevenson@ad-hoc+scl.mp3
-rw-r--r-- 1 ntd 142079999 Dec 26 23:32 22-the-raven+eap@tales-of-mystery-and-horror+scl.mp3
-rw-r--r-- 1 ntd 142079999 Dec 26 23:34 23-outro@extraordinary-tales.mp3

To trim the silence from each stem exported in `Staging/`, run the following command.  This will populate the `Outgoing/` directory with shortened/trimmed versions of the bloated stems produced in the previous command.
```bash
# rm book.lst rm Books/shorts.chapters
make prepare
```

### Publish Book
Next, generate the audiobook.  This next command will also place you into an editor where you will modify the contents of `Books/${BOOK}.cfg`, which will dictate the audiobook title, chapters names and order.
```bash
make book
```

This will generate (and immediately edit) the config (2-column pipe-separated table) file `Books/${BOOK}.cfg` of the form `<id>|<title>`; the first line concerns the book itself (`<book-id>|<book-title>`), and every other line the chapters of the book.  Once complete, you should have something like this:
```config
title=Poetry & Prose
artist=Written by Edgar Allan Poe, and R. L. Stevenson.  Narrated by Christopher Lee, Bela Lugosi, Tom O'Bedlam, Shane Morris, Guillermo del Toro, Sascha Ende, Julian Sands, and Dave Luukkonen.
01-alone+eap@wn+tom-o-bedlam|Alone (Symphonic) — E. A. Poe — Tom O'Bedlam
02-eap+annabel-lee@bsm+sascha-ende|Annabel — E. A. Poe — Sascha Ende
03-eap+annabel-lee@wow+shane-morris|Annabel — E. A. Poe — Shane Morris
04-the-raven+eap@ad-hoc+scl|The Raven (Symphonic) — E. A. Poe — Christopher Lee
05-intro@extraordinary-tales|Intro
06-the-fall-of-the-house-of-usher+eap@extraordinary-tales+scl|The Fall of the House of Usher (Enacted) — E. A. Poe — Christopher Lee
07-the-fall-of-the-house-of-usher+eap@tales-of-mystery-and-horror+scl|The Fall of the House of Usher — E. A. Poe — Christopher Lee
08-interlude-i@extraordinary-tales|Interlude I
09-the-black-cat+scl@tales-of-mystery-and-horror+scl|The Black Cat — E. A. Poe — Christopher Lee
10-the-cask-of-amontillado+eap@tales-of-mystery-and-horror+scl|The Cask of Amontillado — Christopher Lee
11-interlude-ii@extraordinary-tales|Interlude II
12-the-tell-tale-heart+eap@extraordinary-tales+bela-lugosi|The Tell-Tale Heart (Enacted) — E. A. Poe — Bela Lugosi
13-the-tell-tale-heart+eap@tales-of-mystery-and-horror+scl|The Tell-Tale Heart — E. A. Poe — Christopher Lee
14-hop-frog+eap@tales-of-mystery-and-horror+scl|Hop-Frog — E. A. Poe — Christopher Lee
15-interlude-iii@extraordinary-tales|Interlude III
16-the-mask-of-the-red-death@eap+tales-of-mystery-and-horror+scl|The Mask of the Red Death — E. A. Poe — Christopher Lee
17-william-wilson+eap@hbp+dave-luukkonen|William Wilson — E. A. Poe — Dave Luukkonen
18-the-facts-in-the-case-of-m-valdemar+eap@extraordinary-tales+julian-sands|The Facts in the Case of M Valdemar — E. A. Poe — Julian Sands
19-interlude-iv@extraordinary-tales|Interlude IV
20-the-pit-and-the-pendulum@eap@extraordinary-tales+guillermo-del-toro|The Pit and the Pendulum — E. A. Poe — Guillermo del Toro
21-the-conqueror-worm+eap@ad-hoc+tom-o-bedlam|The Conqueror Worm — E. A. Poe — Tom O'Bedlam
22-outerlude@extraordinary-tales|Outerlude
23-the-murders-in-the-rue-morgue+eap@tales-of-mystery-and-horror+scl|The Murders in the Rue Morgue — E. A. Poe — Christopher Lee
24-the-raven+eap@tales-of-mystery-and-horror+scl|The Raven — E. A. Poe — Christopher Lee
25-a-dream-within-a-dream+eap@rfm+shane-morris|A Dream Within a Dream — E. A. Poe — Shane Morris
26-outro@extraordinary-tales|Outro
27-the-strange-case-of-dr-jekyll-and-mr-hyde+r-l-stevenson@ad-hoc+scl|The Strange Case of Dr. Jekyll and Mr. Hyde — R. L. Stevenson — Christopher Lee
```

The produced audiobook is ready to move into your audiobook directory for use.
```bash
mv "Books/${BOOK?}.m4b" "${HOME?}/pCloud Drive/AudioBooks/${BOOK?}.m4b"
```

## TODO
- How to change the `m4b` album art?
- DRM
	- https://audible-converter.ml/ for de-RM-ing Audible books.
	- `ffmpeg -hide_banner -activation_bytes <ActivationBytes> -i <Input>.aax -c copy <Output>.m4b`

```
title=Poetry & Prose
artist=Written by Edgar Allan Poe, and R. L. Stevenson.  Narrated by Sir Christopher Lee, Bela Lugosi, Tom O'Bedlam, Sascha Ende, Shane Morris, Guillermo del Toro, Julian Sands, and Dave Luukkonen.
```

# Misc

## Helpful A/V Discoveries

### Merge Audio & Video
https://superuser.com/questions/851977/ffmpeg-merging-mp3-mp4-no-sound-with-copy-codec
```bash
% ffmpeg -i video.mp4 -i audio.mp3 -map 0:v -map 1:a -c:v copy -c:a aac ExtraordinaryTales.mp4 -y
% ffmpeg -i video.mp4 -i audio.mp3 -map 0:v -map 1:a -c:v copy -c:a copy ExtraordinaryTales.mp4 -y
```
