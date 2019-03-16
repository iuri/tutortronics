# $Id: makefile,v 1.3 2015/12/04 14:02:54 cvs Exp $

TARGET=index
SOURCES=attachments.apt

$(TARGET):	html

html:
	aptconvert -toc -pi html strict yes ../$(TARGET).html $(SOURCES)

htmlclean:
	rm -rf ../$(TARGET)*.html ../apt_*.gif ../*.css

clean:	htmlclean

distclean:	clean
