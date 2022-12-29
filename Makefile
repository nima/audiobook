ifeq ($(wildcard workbench),)
$(error symlink your workbench to `workbench')
endif

ifeq ($(wildcard bookshelf),)
$(error symlink your bookshelf to `workbench')
endif

ifeq (${BOOK},)
$(error export BOOK to some book id)
endif

STAGING := /tmp/Staging
IDS := $(patsubst ${STAGING}/%.mp3,%,$(filter-out YouTube,$(wildcard ${STAGING}/*.mp3)))

workbench/Outgoing/%.mp3: ${STAGING}/%.mp3
	@mkdir -p $(@D)
	ffmpeg -hide_banner -i "$<" -af\
	  silenceremove=start_periods=1:start_duration=40:start_threshold=-220dB:window=60.0,silenceremove=stop_periods=1:stop_duration=30:stop_threshold=-40dB:window=10.0\
	  ${STAGING}/_transcoding_.mp3
	mv ${STAGING}/_transcoding_.mp3 $@

${STAGING}/%.len: workbench/Outgoing/%.mp3
	ffprobe -hide_banner -i "$<" -show_entries format=duration -v quiet -of csv="p=0" > $@                               # .mp3 -> .len

staging:
	mkdir -p workbench/Backup/
	mkdir -p workbench/Incoming/
	mkdir -p workbench/Staging/
	mkdir -p workbench/Outgoing/
	mkdir -p workbench/Books/
	@cd ${STAGING} && touch "YouTube .staging"
	@cd ${STAGING} && for mp3 in YouTube*; do mv "$${mp3}" $${mp3//YouTube /}; done
	@rm ${STAGING}/.staging
	@rm -f ${STAGING}/_transcoding_.mp3
.PHONY: staging

chapters: workbench/Books/${BOOK}.cfg
	@vim workbench/Books/${BOOK}.cfg                                                                                     # USER |-> .cfg
	@tail -n +2 workbench/Books/${BOOK}.cfg|awk -F '|' '{print$$1}'\
	|while read line; do\
	   IFS=- read num file <<< "$${line}";\
	   matched=$$(compgen -G "${STAGING}/*-$${file}.mp3");\
	   [ ! -z "$${matched}" ]\
	   && [ "$${matched}" != "${STAGING}/$${num}-$${file}.mp3" ]\
	   && mv "$${matched}" "${STAGING}/$$num-$${file}.mp3";\
	done || exit 0;
workbench/Books/${BOOK}.cfg:                                                                                             # IDS -> .cfg
	@echo "<book-id>|<book-title>" > $@
	@$(foreach chapter,$(IDS),echo "${chapter}|${chapter}" >> $@;)
.PHONY: chapters

book: staging $(IDS:%=workbench/Outgoing/%.mp3) $(IDS:%=${STAGING}/%.len) chapters workbench/Books/${BOOK}.m4b
	@echo "Book Published: ${BOOK}: workbench/Books/${BOOK}.m4b"
.PHONY: book

workbench/Books/${BOOK}.m4b:
	rm -f /tmp/_${BOOK}.*
	bin/mkcfg ${BOOK}                                                                                                    # .len, .cfg -> .lst, .chp
	ln -sf workbench/Books/${BOOK}.lst
	ffmpeg -hide_banner -f concat -safe 0 -i "${BOOK}.lst" -c copy "/tmp/_${BOOK}.mp3"                                   # .lst, .mp3 -> .mp3 (merge)
	rm -f ${BOOK}.lst
	ffmpeg -hide_banner -i "/tmp/_${BOOK}.mp3" "/tmp/_${BOOK}.m4b"                                                       # .mp3 -> .m4b
	{\
	    ffmpeg -hide_banner -i "/tmp/_${BOOK}.m4b" -f ffmetadata -;\
	    cat /tmp/_${BOOK}.chp;\
	} > workbench/Books/${BOOK}.chp                                                                                      # .m4b, .chp -> .chp
	ffmpeg -hide_banner\
	    -i "/tmp/_${BOOK}.m4b"\
	    -i workbench/Books/${BOOK}.chp\
	    -map_metadata 1 -codec copy workbench/Books/${BOOK}.m4b                                                          # .chp, .m4b -> .m4b
	rm -f /tmp/_${BOOK}.*
	bin/mkcov ${BOOK}
.PHONY: book

publish: workbench/Books/${BOOK}.m4b workbench/Books/${BOOK}.cfg
	cp $< "bookshelf/$(shell sed -nE 's/^title=(.*)/\1/p' workbench/Books/${BOOK}.cfg).m4b"

backup:
	cp -i workbench/Books/${BOOK}.cfg workbench/Books/${BOOK}.cfg.bak
	rsync -a ${STAGING}/ Staging/
clean:
	-rm -f ${STAGING}/*.len
	-rm -f workbench/Books/${BOOK}.m4b workbench/Books/${BOOK}.lst workbench/Books/${BOOK}.chp
	-rm -f workbench/Books/_${BOOK}.*
purge: clean
	-rm workbench/Outgoing/*
.PHONY: clean purge
